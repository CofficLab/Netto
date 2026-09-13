import Foundation

// MARK: - Plugin Registry and Lifecycle

extension KernelCoreContainer {
    /// 仅注册插件实例并执行 `onRegister`，不执行 Boot/Ready。
    ///
    /// 一般宿主应使用 `start(plugins:)` / `startAsync(plugins:)`。
    /// `onRegister` 失败时撤回该插件的贡献并移除注册，保持容器干净。
    public func registerPlugin(_ plugin: any SuperPlugin) throws {
        guard plugins[plugin.id] == nil else {
            throw KernelCoreError.pluginAlreadyRegistered(id: plugin.id)
        }
        plugins[plugin.id] = plugin
        pluginEnabledStates[plugin.id] = effectiveEnabledState(for: plugin)
        do {
            try plugin.onRegister(kernel: self)
        } catch {
            cancelContributions(ownedBy: plugin.id)
            plugins.removeValue(forKey: plugin.id)
            pluginEnabledStates.removeValue(forKey: plugin.id)
            throw error
        }
    }

    // MARK: - Enable-state computation

    /// 计算插件的有效启用状态：不可配置策略由策略本身决定，
    /// 可配置插件优先读取用户持久化覆盖。
    func effectiveEnabledState(for plugin: any SuperPlugin) -> Bool {
        switch plugin.metadata.policy {
        case .required, .alwaysOn:
            return true
        case .disabled:
            return false
        case .enabledByDefault, .disabledByDefault:
            return storedEnabledState(for: plugin.id) ?? plugin.metadata.policy.enabledByDefault
        }
    }

    /// 读取用户覆盖；优先新 ID，其次旧 ID 别名（迁移兼容）。
    func storedEnabledState(for pluginID: String) -> Bool? {
        guard let enableStateStore else { return nil }
        if let value = enableStateStore.enabledState(pluginID: pluginID) {
            return value
        }
        if let legacyID = legacyPluginIDAliases[pluginID] {
            return enableStateStore.enabledState(pluginID: legacyID)
        }
        return nil
    }

    /// 写入用户覆盖；同步写入旧 ID 别名，保证回滚版本兼容。
    func persistEnabledState(_ enabled: Bool, pluginID: String) {
        guard let enableStateStore else { return }
        enableStateStore.setEnabled(enabled, pluginID: pluginID)
        if let legacyID = legacyPluginIDAliases[pluginID], legacyID != pluginID {
            enableStateStore.setEnabled(enabled, pluginID: legacyID)
        }
    }

    // MARK: - Sync Startup

    /// 原子启动一批同步插件。
    ///
    /// 启动前校验重复 ID、缺失依赖和依赖环；随后按依赖及 `order` 稳定执行
    /// 全部 Boot，再执行全部 Ready。任一失败时逆序 Shutdown 本批已 Boot 插件、
    /// 撤回贡献并移除其 Provider，避免留下半启动内核。
    ///
    /// - Throws: 校验错误、`asyncLifecycleRequired`（含 AsyncSuperPlugin）、
    ///   或第一个 Boot/Ready 错误。
    public func start(plugins incomingPlugins: [any SuperPlugin]) throws {
        guard lifecycleState == .stopped || lifecycleState == .running else {
            throw KernelCoreError.invalidLifecycleOperation(
                operation: "start plugins",
                state: lifecycleStateDescription
            )
        }
        if let asyncPlugin = incomingPlugins.first(where: { $0 is any AsyncSuperPlugin }) {
            throw KernelCoreError.asyncLifecycleRequired(pluginID: asyncPlugin.id)
        }

        // 策略为 .disabled 的插件彻底排除：不注册、不启动、不展示。
        let activePlugins = incomingPlugins.filter { $0.metadata.policy != .disabled }

        let sorted = try sortedForStartup(activePlugins)
        guard !sorted.isEmpty else {
            if lifecycleState == .stopped { setLifecycleState(.running) }
            return
        }

        setLifecycleState(.starting)
        var bootedIDs: [String] = []

        do {
            for plugin in sorted {
                try registerPlugin(plugin)
                // 即使 onBoot 中途失败，也必须给插件一次 Shutdown 清理机会。
                bootedIDs.append(plugin.id)

                // 用户已禁用的插件仅注册、不 Boot，等待运行时 enablePlugin。
                guard isPluginEnabled(id: plugin.id) else { continue }

                try plugin.onBoot(kernel: self)
                pluginStartOrder.append(plugin.id)
            }

            for plugin in sorted {
                guard isPluginEnabled(id: plugin.id) else { continue }
                try plugin.onReady(kernel: self)
            }
            setLifecycleState(.running)
        } catch {
            rollbackStartup(bootedIDs: bootedIDs, attemptedIDs: sorted.map(\.id))
            setLifecycleState(.failed)
            throw error
        }
    }

    // MARK: - Async Startup

    /// 原子启动一批插件（支持 AsyncSuperPlugin）。
    ///
    /// 与 `start(plugins:)` 相同的校验与回滚语义；异步阶段运行在**调用方 Task
    /// 的取消边界内**，并受 `asyncPhaseTimeout` 约束：超时或取消都会触发
    /// 逆序回滚，不会在启动后遗留后台任务。
    public func startAsync(plugins incomingPlugins: [any SuperPlugin]) async throws {
        guard lifecycleState == .stopped || lifecycleState == .running else {
            throw KernelCoreError.invalidLifecycleOperation(
                operation: "startAsync plugins",
                state: lifecycleStateDescription
            )
        }

        let activePlugins = incomingPlugins.filter { $0.metadata.policy != .disabled }
        let sorted = try sortedForStartup(activePlugins)
        guard !sorted.isEmpty else {
            if lifecycleState == .stopped { setLifecycleState(.running) }
            return
        }

        setLifecycleState(.starting)
        var bootedIDs: [String] = []

        do {
            for plugin in sorted {
                try registerPlugin(plugin)
                bootedIDs.append(plugin.id)

                guard isPluginEnabled(id: plugin.id) else { continue }

                try await runAsyncPhase(.boot, pluginID: plugin.id) {
                    try await plugin.runBoot(kernel: self)
                }
                pluginStartOrder.append(plugin.id)
            }

            for plugin in sorted {
                guard isPluginEnabled(id: plugin.id) else { continue }
                try await runAsyncPhase(.ready, pluginID: plugin.id) {
                    try await plugin.runReady(kernel: self)
                }
            }
            setLifecycleState(.running)
        } catch {
            rollbackStartup(bootedIDs: bootedIDs, attemptedIDs: sorted.map(\.id))
            setLifecycleState(.failed)
            throw error
        }
    }

    // MARK: - Stop

    /// 逆启动顺序停止全部插件（同步）。
    ///
    /// 每个插件的 Shutdown 失败不阻断其他插件清理；全部完成后抛出第一个错误。
    public func stop() throws {
        guard lifecycleState == .running || lifecycleState == .failed else {
            if lifecycleState == .stopped { return }
            throw KernelCoreError.invalidLifecycleOperation(operation: "stop", state: lifecycleStateDescription)
        }
        if let asyncPlugin = allPlugins.first(where: { $0 is any AsyncSuperPlugin }) {
            throw KernelCoreError.asyncLifecycleRequired(pluginID: asyncPlugin.id)
        }

        setLifecycleState(.stopping)
        var firstError: Error?
        for id in pluginStartOrder.reversed() {
            guard let plugin = plugins[id] else { continue }
            do {
                try plugin.onShutdown(kernel: self)
            } catch {
                if firstError == nil { firstError = error }
            }
            cancelContributions(ownedBy: id)
            removeProviders(ownedByPlugin: id)
        }
        for plugin in allPlugins.reversed() {
            do {
                try plugin.onUnregister(kernel: self)
            } catch {
                if firstError == nil { firstError = error }
            }
            cancelContributions(ownedBy: plugin.id)
            removeProviders(ownedByPlugin: plugin.id)
            plugins.removeValue(forKey: plugin.id)
            pluginEnabledStates.removeValue(forKey: plugin.id)
        }
        pluginStartOrder.removeAll()
        setLifecycleState(.stopped)
        if let firstError { throw firstError }
    }

    /// 逆启动顺序停止全部插件（异步，支持 AsyncSuperPlugin）。
    public func stopAsync() async throws {
        guard lifecycleState == .running || lifecycleState == .failed else {
            if lifecycleState == .stopped { return }
            throw KernelCoreError.invalidLifecycleOperation(operation: "stopAsync", state: lifecycleStateDescription)
        }

        setLifecycleState(.stopping)
        var firstError: Error?
        for id in pluginStartOrder.reversed() {
            guard let plugin = plugins[id] else { continue }
            do {
                try await runAsyncPhase(.shutdown, pluginID: id) {
                    try await plugin.runShutdown(kernel: self)
                }
            } catch {
                if firstError == nil { firstError = error }
            }
            cancelContributions(ownedBy: id)
            removeProviders(ownedByPlugin: id)
        }
        for plugin in allPlugins.reversed() {
            do {
                try plugin.onUnregister(kernel: self)
            } catch {
                if firstError == nil { firstError = error }
            }
            cancelContributions(ownedBy: plugin.id)
            removeProviders(ownedByPlugin: plugin.id)
            plugins.removeValue(forKey: plugin.id)
            pluginEnabledStates.removeValue(forKey: plugin.id)
        }
        pluginStartOrder.removeAll()
        setLifecycleState(.stopped)
        if let firstError { throw firstError }
    }

    // MARK: - Unload / Enable / Disable

    /// 卸载单个插件；仍被其他插件依赖时拒绝卸载。
    public func unloadPlugin(id: String) throws {
        guard lifecycleState == .running else {
            throw KernelCoreError.invalidLifecycleOperation(operation: "unload plugin", state: lifecycleStateDescription)
        }
        guard let plugin = plugins[id] else {
            throw KernelCoreError.pluginNotFound(id: id)
        }
        if let dependent = plugins.values.first(where: { $0.dependencies.contains(id) }) {
            throw KernelCoreError.invalidLifecycleOperation(
                operation: "unload plugin '\(id)' required by '\(dependent.id)'",
                state: lifecycleStateDescription
            )
        }

        var shutdownError: Error?
        if pluginStartOrder.contains(id) {
            if plugin is any AsyncSuperPlugin {
                // unloadPlugin 是同步入口；异步插件卸载走 unloadPluginAsync。
                throw KernelCoreError.asyncLifecycleRequired(pluginID: id)
            }
            do {
                try plugin.onShutdown(kernel: self)
            } catch {
                shutdownError = error
            }
        }
        do {
            try plugin.onUnregister(kernel: self)
        } catch {
            if shutdownError == nil { shutdownError = error }
        }
        cancelContributions(ownedBy: id)
        removeProviders(ownedByPlugin: id)
        plugins.removeValue(forKey: id)
        pluginEnabledStates.removeValue(forKey: id)
        pluginStartOrder.removeAll { $0 == id }
        if let shutdownError { throw shutdownError }
    }

    /// 异步卸载单个插件（支持 AsyncSuperPlugin）。
    public func unloadPluginAsync(id: String) async throws {
        guard lifecycleState == .running else {
            throw KernelCoreError.invalidLifecycleOperation(operation: "unloadPluginAsync", state: lifecycleStateDescription)
        }
        guard let plugin = plugins[id] else {
            throw KernelCoreError.pluginNotFound(id: id)
        }
        if let dependent = plugins.values.first(where: { $0.dependencies.contains(id) }) {
            throw KernelCoreError.invalidLifecycleOperation(
                operation: "unload plugin '\(id)' required by '\(dependent.id)'",
                state: lifecycleStateDescription
            )
        }

        var firstError: Error?
        if pluginStartOrder.contains(id) {
            do {
                try await runAsyncPhase(.shutdown, pluginID: id) {
                    try await plugin.runShutdown(kernel: self)
                }
            } catch {
                firstError = error
            }
        }
        do {
            try plugin.onUnregister(kernel: self)
        } catch {
            if firstError == nil { firstError = error }
        }
        cancelContributions(ownedBy: id)
        removeProviders(ownedByPlugin: id)
        plugins.removeValue(forKey: id)
        pluginEnabledStates.removeValue(forKey: id)
        pluginStartOrder.removeAll { $0 == id }
        if let firstError { throw firstError }
    }

    /// 运行时启用插件：调用 `onEnable` 并恢复贡献能力。
    public func enablePlugin(id: String) async throws {
        guard lifecycleState == .running else {
            throw KernelCoreError.invalidLifecycleOperation(operation: "enable plugin", state: lifecycleStateDescription)
        }
        guard let plugin = plugins[id] else {
            throw KernelCoreError.pluginNotFound(id: id)
        }
        guard !isPluginEnabled(id: id) else { return }
        try await plugin.onEnable(kernel: self)
        pluginEnabledStates[id] = true
        persistEnabledState(true, pluginID: id)
    }

    /// 运行时禁用插件：调用 `onDisable`，成功后撤回该插件全部贡献并注销其 Provider。
    public func disablePlugin(id: String) async throws {
        guard lifecycleState == .running else {
            throw KernelCoreError.invalidLifecycleOperation(operation: "disable plugin", state: lifecycleStateDescription)
        }
        guard let plugin = plugins[id] else {
            throw KernelCoreError.pluginNotFound(id: id)
        }
        guard isPluginEnabled(id: id) else { return }
        try await plugin.onDisable(kernel: self)
        pluginEnabledStates[id] = false
        cancelContributions(ownedBy: id)
        removeProviders(ownedByPlugin: id)
        persistEnabledState(false, pluginID: id)
    }

    // MARK: - Queries

    /// 按 ID 解析已注册插件。
    public func resolvePlugin(id: String) -> (any SuperPlugin)? { plugins[id] }

    /// 插件是否已注册。
    public func isPluginRegistered(id: String) -> Bool { plugins[id] != nil }

    /// 插件当前是否启用（已注册且启用）。
    public func isPluginEnabled(id: String) -> Bool {
        pluginEnabledStates[id] == true
    }

    /// 已注册插件数量。
    public var registeredPluginCount: Int { plugins.count }

    /// 按实际启动顺序返回插件，保证诊断输出确定性。
    public var allPlugins: [any SuperPlugin] {
        pluginStartOrder.compactMap { plugins[$0] }
            + plugins.values.filter { !pluginStartOrder.contains($0.id) }.sorted { $0.id < $1.id }
    }

    /// 低层注册表操作，不执行 Shutdown。运行中的插件优先使用 `unloadPlugin`。
    public func unregisterPlugin(id: String) {
        if let plugin = plugins[id] {
            try? plugin.onUnregister(kernel: self)
        }
        cancelContributions(ownedBy: id)
        plugins.removeValue(forKey: id)
        pluginStartOrder.removeAll { $0 == id }
        pluginEnabledStates.removeValue(forKey: id)
        removeProviders(ownedByPlugin: id)
    }
}

// MARK: - Private Helpers

private enum AsyncPhase: String {
    case boot = "boot"
    case ready = "ready"
    case shutdown = "shutdown"
}

extension KernelCoreContainer {
    /// 对一批插件做依赖拓扑排序（稳定）。
    ///
    /// 规则：依赖满足者按 `order` 升序、同 order 按原数组索引升序，逐轮取出。
    /// 校验重复 ID、缺失依赖和依赖环。
    func sortedForStartup(_ incoming: [any SuperPlugin]) throws -> [any SuperPlugin] {
        var byID: [String: any SuperPlugin] = [:]
        var originalIndex: [String: Int] = [:]
        for (index, plugin) in incoming.enumerated() {
            guard plugins[plugin.id] == nil, byID[plugin.id] == nil else {
                throw KernelCoreError.pluginAlreadyRegistered(id: plugin.id)
            }
            byID[plugin.id] = plugin
            originalIndex[plugin.id] = index
        }

        for plugin in incoming {
            for dependency in plugin.dependencies where plugins[dependency] == nil && byID[dependency] == nil {
                throw KernelCoreError.pluginDependencyMissing(
                    pluginID: plugin.id,
                    dependencyID: dependency
                )
            }
        }

        var remaining = Set(byID.keys)
        var resolved = Set(plugins.keys)
        var result: [any SuperPlugin] = []

        while !remaining.isEmpty {
            let ready = remaining.compactMap { byID[$0] }.filter { plugin in
                plugin.dependencies.allSatisfy { resolved.contains($0) }
            }.sorted { lhs, rhs in
                if lhs.order != rhs.order { return lhs.order < rhs.order }
                return originalIndex[lhs.id, default: 0] < originalIndex[rhs.id, default: 0]
            }

            guard !ready.isEmpty else {
                throw KernelCoreError.pluginDependencyCycle(ids: remaining.sorted())
            }
            for plugin in ready {
                remaining.remove(plugin.id)
                resolved.insert(plugin.id)
                result.append(plugin)
            }
        }
        return result
    }

    /// 启动失败回滚：逆序 Shutdown 已 Boot 插件，再对所有尝试过的插件执行
    /// Unregister、撤回贡献、移除 Provider，最后清空注册。
    func rollbackStartup(bootedIDs: [String], attemptedIDs: [String]) {
        for id in bootedIDs.reversed() {
            guard let plugin = plugins[id] else { continue }
            if plugin is any AsyncSuperPlugin {
                // 回滚路径不等待异步 Shutdown；能做的清理（贡献/Provider/注销）立即执行。
            } else {
                try? plugin.onShutdown(kernel: self)
            }
        }
        for id in attemptedIDs {
            if let plugin = plugins[id] {
                try? plugin.onUnregister(kernel: self)
            }
            cancelContributions(ownedBy: id)
            removeProviders(ownedByPlugin: id)
            plugins.removeValue(forKey: id)
            pluginEnabledStates.removeValue(forKey: id)
            pluginStartOrder.removeAll { $0 == id }
        }
    }

    /// 执行单个异步阶段，带超时与取消。
    ///
    /// 结构：`withThrowingTaskGroup` 内同时调度阶段体与超时体；任一先完成即
    /// 取消另一条。阶段体运行在调用方 Task 的取消边界内（结构化并发），
    /// 宿主取消会通过 `Task.checkCancellation` 转换为 `asyncPhaseCancelled`。
    ///
    /// 线程/actor：`body` 是 `@MainActor` 隔离闭包，运行在继承自调用方的
    /// MainActor 任务中，可安全捕获 MainActor 插件实例，无需 `@unchecked Sendable`。
    fileprivate func runAsyncPhase(
        _ phase: AsyncPhase,
        pluginID: String,
        body: @escaping @MainActor @Sendable () async throws -> Void
    ) async throws {
        try Task.checkCancellation()
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await body()
            }
            group.addTask {
                try await Task.sleep(for: self.asyncPhaseTimeout)
                throw KernelCoreError.asyncPhaseTimeout(pluginID: pluginID, phase: phase.rawValue)
            }
            // 任一任务先完成即取结果并取消另一条，避免遗留睡眠任务。
            guard let result = await group.nextResult() else {
                throw KernelCoreError.asyncPhaseCancelled(pluginID: pluginID, phase: phase.rawValue)
            }
            group.cancelAll()
            switch result {
            case .success:
                return
            case .failure(let error):
                if Task.isCancelled, error is CancellationError {
                    throw KernelCoreError.asyncPhaseCancelled(pluginID: pluginID, phase: phase.rawValue)
                }
                throw error
            }
        }
    }

    /// 生命周期状态描述（诊断用）。
    var lifecycleStateDescription: String {
        switch lifecycleState {
        case .stopped: return "stopped"
        case .starting: return "starting"
        case .running: return "running"
        case .stopping: return "stopping"
        case .failed: return "failed"
        }
    }

    func setLifecycleState(_ state: KernelLifecycleState) {
        lifecycleState = state
    }
}

// MARK: - AsyncSuperPlugin dispatch

private extension SuperPlugin {
    /// 分派到 AsyncSuperPlugin.onBootAsync，或同步 onBoot。
    func runBoot(kernel: KernelCoreContainer) async throws {
        if let asyncPlugin = self as? any AsyncSuperPlugin {
            try await asyncPlugin.onBootAsync(kernel: kernel)
        } else {
            try onBoot(kernel: kernel)
        }
    }

    /// 分派到 AsyncSuperPlugin.onReadyAsync，或同步 onReady。
    func runReady(kernel: KernelCoreContainer) async throws {
        if let asyncPlugin = self as? any AsyncSuperPlugin {
            try await asyncPlugin.onReadyAsync(kernel: kernel)
        } else {
            try onReady(kernel: kernel)
        }
    }

    /// 分派到 AsyncSuperPlugin.onShutdownAsync，或同步 onShutdown。
    func runShutdown(kernel: KernelCoreContainer) async throws {
        if let asyncPlugin = self as? any AsyncSuperPlugin {
            try await asyncPlugin.onShutdownAsync(kernel: kernel)
        } else {
            try onShutdown(kernel: kernel)
        }
    }
}

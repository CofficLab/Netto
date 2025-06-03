import Foundation
import MagicCore
import OSLog
import SwiftData
import SwiftUI
import Combine

@MainActor
class MessageProvider: ObservableObject, SuperLog, SuperThread, SuperEvent {
    static let shared = MessageProvider()
    nonisolated static let emoji = "📪"
    let maxMessageCount = 100

    @Published var messages: [SmartMessage] = []
    @Published var alert: String?
    @Published var error: Error?
    @Published var toast: String?
    @Published var doneMessage: String?
    @Published var alerts: [String] = []
    @Published var message: String = ""
    @Published var showDone = false
    @Published var showError = false
    @Published var showToast = false
    @Published var showAlert = false
    
    private var cancellables = Set<AnyCancellable>()

    private init() {
        os_log("\(Self.onInit)")
        setupNotificationListeners()
    }

    func alert(_ message: String, info: String) {
        // 显示错误提示
        let errorAlert = NSAlert()
        errorAlert.messageText = message
        errorAlert.informativeText = info
        errorAlert.alertStyle = .critical
        errorAlert.addButton(withTitle: "好的")
        errorAlert.runModal()
    }

    func setError(_ e: Error) {
        self.alert("发生错误", info: e.localizedDescription)
    }
    
    func append(_ message: String, channel: String = "default", isError: Bool = false) {
        if !Thread.isMainThread {
            assertionFailure("append called from background thread")
        }

        self.messages.insert(SmartMessage(description: message, channel: channel, isError: isError), at: 0)
        if self.messages.count > self.maxMessageCount {
            self.messages.removeLast()
        }
    }

    func alert(_ message: String, verbose: Bool = true) {
        if !Thread.isMainThread {
            assertionFailure("alert called from background thread")
        }

        if verbose {
            os_log("\(self.t)Alert: \(message)")
        }

        self.alert = message
        self.showAlert = true
    }

    func done(_ message: String) {
        if !Thread.isMainThread {
            assertionFailure("done called from background thread")
        }

        self.doneMessage = message
        self.showDone = true
    }

    func clearAlert() {
        if !Thread.isMainThread {
            assertionFailure("clearAlert called from background thread")
        }

        self.alert = nil
        self.showAlert = false
    }

    func clearDoneMessage() {
        if !Thread.isMainThread {
            assertionFailure("clearDoneMessage called from background thread")
        }

        self.doneMessage = nil
        self.showDone = false
    }

    func clearError() {
        if !Thread.isMainThread {
            assertionFailure("clearError called from background thread")
        }

        self.error = nil
        self.showError = false
    }

    func clearToast() {
        if !Thread.isMainThread {
            assertionFailure("clearToast called from background thread")
        }

        self.toast = nil
        self.showToast = false
    }

    func clearMessages() {
        if !Thread.isMainThread {
            assertionFailure("clearMessages called from background thread")
        }

        self.messages = []
    }

    func error(_ error: Error) {
        if !Thread.isMainThread {
            assertionFailure("error called from background thread")
        }

        self.error = error
        self.showError = true
    }
    
    func getAllChannels() -> [String] {
        let channels = Set(messages.map { $0.channel })
        return Array(channels).sorted()
    }

    func toast(_ toast: String) {
        if !Thread.isMainThread {
            assertionFailure("toast called from background thread")
        }

        self.toast = toast
        self.showToast = true
    }
    
    /// 设置通知监听器
    private func setupNotificationListeners() {
        // 监听系统扩展安装相关事件
        nc.publisher(for: .willInstall)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.append("安装系统扩展")
            }
            .store(in: &cancellables)
            
        nc.publisher(for: .didInstall)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.append("安装系统扩展成功")
            }
            .store(in: &cancellables)
            
        nc.publisher(for: .didFailWithError)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleDidFailWithError(notification)
            }
            .store(in: &cancellables)
            
        // 监听系统扩展启动/停止相关事件
        nc.publisher(for: .willStart)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.append("开始监控")
            }
            .store(in: &cancellables)
            
        nc.publisher(for: .didStart)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.append("开始监控成功")
            }
            .store(in: &cancellables)
            
        nc.publisher(for: .willStop)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.append("停止监控")
            }
            .store(in: &cancellables)
            
        nc.publisher(for: .didStop)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.append("停止监控成功")
            }
            .store(in: &cancellables)
            
        // 监听配置和注册相关事件
        nc.publisher(for: .configurationChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.append("配置发生变化")
            }
            .store(in: &cancellables)
            
        nc.publisher(for: .needApproval)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.append("需要用户批准")
            }
            .store(in: &cancellables)
            
        nc.publisher(for: .willRegisterWithProvider)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.append("将要注册系统扩展")
            }
            .store(in: &cancellables)
            
        nc.publisher(for: .didRegisterWithProvider)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.append("注册系统扩展成功")
            }
            .store(in: &cancellables)
    }
    
    /// 处理系统扩展安装失败事件
    /// - Parameter notification: 包含错误信息的通知
    private func handleDidFailWithError(_ notification: Notification) {
        guard let error = notification.userInfo?["error"] as? Error else {
            self.append("安装系统扩展失败: 未知错误")
            return
        }
        
        self.append("安装系统扩展失败: \(error.localizedDescription)")
    }
}

import MagicCore
import OSLog
import SwiftUI

/// Agent 规则按钮 —— 点击后显示 popover，展示 .agent/rules 目录中的规则文件。
struct BtnAgentRules: View, SuperLog, SuperThread {
    @State private var hovered = false
    @State private var isPresented = false
    @State private var rules: [AgentRule] = []

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text")
            if !rules.isEmpty {
                Text("\(rules.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxHeight: .infinity)
        .onHover { hovered = $0 }
        .onTapGesture {
            isPresented.toggle()
            if isPresented {
                loadRules()
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .popover(isPresented: $isPresented, content: {
            RulesPopoverContent(rules: rules)
                .frame(width: 400, height: 500)
        })
        .onAppear {
            loadRules()
        }
    }

    private func loadRules() {
        rules = AgentRuleLoader.loadRules()
    }
}

/// 规则数据模型
struct AgentRule: Identifiable {
    let id: String
    let filename: String
    let title: String
    let description: String?
    let content: String
    let fileSize: Int
    let modifiedDate: Date
}

/// 规则加载器
enum AgentRuleLoader {
    static func loadRules() -> [AgentRule] {
        guard let projectPath = findProjectPath() else {
            return []
        }

        let rulesPath = "\(projectPath)/.agent/rules"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: rulesPath) else {
            return []
        }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: rulesPath)
            let markdownFiles = contents.filter { $0.hasSuffix(".md") }

            return markdownFiles.compactMap { filename -> AgentRule? in
                let fullPath = "\(rulesPath)/\(filename)"
                guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else {
                    return nil
                }

                let attributes = try? fileManager.attributesOfItem(atPath: fullPath)
                let fileSize = (attributes?[.size] as? Int) ?? 0
                let modifiedDate = (attributes?[.modificationDate] as? Date) ?? Date()

                // 解析标题和描述
                let (title, description) = parseMetadata(from: content, filename: filename)

                return AgentRule(
                    id: filename,
                    filename: filename,
                    title: title,
                    description: description,
                    content: content,
                    fileSize: fileSize,
                    modifiedDate: modifiedDate
                )
            }.sorted { $0.filename < $1.filename }
        } catch {
            return []
        }
    }

    private static func findProjectPath() -> String? {
        // 尝试从当前工作目录向上查找 .agent/rules 目录
        let fileManager = FileManager.default
        var currentPath = fileManager.currentDirectoryPath

        for _ in 0..<10 {
            let rulesPath = "\(currentPath)/.agent/rules"
            if fileManager.fileExists(atPath: rulesPath) {
                return currentPath
            }

            // 向上一级
            if let parentPath = URL(string: currentPath)?.deletingLastPathComponent().path {
                if parentPath == currentPath {
                    break
                }
                currentPath = parentPath
            } else {
                break
            }
        }

        return nil
    }

    private static func parseMetadata(from content: String, filename: String) -> (String, String?) {
        let lines = content.components(separatedBy: .newlines)
        var title = filename.replacingOccurrences(of: ".md", with: "")
        var description: String? = nil

        // 查找第一个 # 标题
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                title = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // 查找引用块作为描述
        var inQuoteBlock = false
        var quoteLines: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("> ") {
                inQuoteBlock = true
                quoteLines.append(String(trimmed.dropFirst(2)))
            } else if inQuoteBlock && trimmed.isEmpty {
                continue
            } else if inQuoteBlock {
                break
            }
        }

        if !quoteLines.isEmpty {
            description = quoteLines.joined(separator: " ")
        }

        return (title, description)
    }
}

/// 规则 Popover 内容视图
struct RulesPopoverContent: View {
    let rules: [AgentRule]
    @State private var selectedRule: AgentRule?

    var body: some View {
        HStack(spacing: 0) {
            // 左侧列表
            VStack(alignment: .leading, spacing: 0) {
                Text("Agent Rules")
                    .font(.headline)
                    .padding()

                Divider()

                if rules.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("暂无规则文件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(rules) { rule in
                                RuleRow(rule: rule, isSelected: selectedRule?.id == rule.id)
                                    .onTapGesture {
                                        selectedRule = rule
                                    }
                            }
                        }
                    }
                }
            }
            .frame(width: 180)
            .background(Color(.windowBackgroundColor))

            Divider()

            // 右侧详情
            VStack(alignment: .leading, spacing: 0) {
                if let rule = selectedRule {
                    RuleDetailView(rule: rule)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "text.alignleft")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("选择规则查看详情")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// 规则行视图
struct RuleRow: View {
    let rule: AgentRule
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rule.title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .lineLimit(2)

            if let description = rule.description {
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color(.controlAccentColor).opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
    }
}

/// 规则详情视图
struct RuleDetailView: View {
    let rule: AgentRule

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.title)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label(rule.filename, systemImage: "doc")
                    Label(formatFileSize(rule.fileSize), systemImage: "internaldrive")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // 内容
            ScrollView {
                Text(rule.content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

// MARK: - Preview

#Preview("Agent Rules Button") {
    VStack {
        Text("Agent Rules 按钮测试")
        HStack {
            BtnAgentRules()
        }
    }
    .padding()
    .frame(width: 500, height: 300)
}

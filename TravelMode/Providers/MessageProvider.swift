import Foundation
import MagicKit
import OSLog
import SwiftData
import SwiftUI

class MessageProvider: ObservableObject, SuperLog, SuperThread, SuperEvent {
    let emoji = "📪"
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

    init() {
        let verbose = false
        if verbose {
            os_log("\(Logger.initLog) MessageProvider")
        }
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
}

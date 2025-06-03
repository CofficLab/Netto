import Foundation
import Network
import NetworkExtension
import SwiftUI

extension NEFilterFlow {
    /// 获取本地端口号
    /// - Returns: 本地端口号字符串，如果无法获取则返回空字符串
    func getLocalPort() -> String {
        guard let socketFlow = self as? NEFilterSocketFlow else {
            return ""
        }

        guard let endpoint = socketFlow.localFlowEndpoint else { return "" }
        switch endpoint {
        case let .hostPort(_, port):
            return String(describing: port)
        default:
            return ""
        }
    }

    /// 获取主机名
    /// - Returns: 主机名字符串，如果无法获取则返回空字符串
    func getHostname() -> String {
        guard let socketFlow = self as? NEFilterSocketFlow else {
            return ""
        }

        guard let endpoint = socketFlow.localFlowEndpoint else { return "" }
        switch endpoint {
        case let .hostPort(host, _):
            return String(describing: host)
        default:
            return ""
        }
    }

    /// 获取应用程序标识符
    /// - Returns: 应用程序标识符字符串，如果无法获取则返回空字符串
    func getAppId() -> String {
        return self.value(forKey: "sourceAppIdentifier") as? String ?? ""
    }

    /// 获取应用程序唯一标识符
    /// - Returns: 应用程序唯一标识符字符串，当前实现返回空字符串
    func getAppUniqueId() -> String {
        return ""
    }
}

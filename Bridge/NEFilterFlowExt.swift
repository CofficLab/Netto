import Foundation
import Network
import NetworkExtension
import SwiftUI

extension NEFilterFlow {
    /// 获取对端端口号（事件与决策里的 `port` 描述的是对端）。
    /// - Returns: 对端端口号字符串，如果无法获取则返回空字符串
    func getRemotePort() -> String {
        guard let socketFlow = self as? NEFilterSocketFlow else {
            return ""
        }

        guard let endpoint = socketFlow.remoteFlowEndpoint else { return "" }
        switch endpoint {
        case let .hostPort(_, port):
            return String(describing: port)
        default:
            return ""
        }
    }

    /// 获取对端主机名（localFlowEndpoint 是本机地址，不能作为连接目标记录）。
    /// - Returns: 对端主机字符串，如果无法获取则返回空字符串
    func getHostname() -> String {
        guard let socketFlow = self as? NEFilterSocketFlow else {
            return ""
        }

        guard let endpoint = socketFlow.remoteFlowEndpoint else { return "" }
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

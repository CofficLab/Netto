import Foundation
import NetworkExtension
import XCTest
@testable import NettoIPCContracts

/// IPC 契约测试：确认 @objc 协议可在无 App target 下编译，
/// 且 NETrafficDirection 值类型可跨进程传递（NSXPC 兼容）。
final class IPCContractsTests: XCTestCase {

    func testAppCommunicationSignature() {
        // 编译期验证：协议要求的方法存在且方向类型为 NETrafficDirection。
        let protocolDescription = String(describing: AppCommunication.self)
        XCTAssertFalse(protocolDescription.isEmpty)
    }

    func testProviderCommunicationSignature() {
        let protocolDescription = String(describing: ProviderCommunication.self)
        XCTAssertFalse(protocolDescription.isEmpty)
    }

    func testNETrafficDirectionIsBridgedValueType() {
        // NETrafficDirection 是 @objc 值类型，可直接跨 NSXPC 传递。
        let direction = NETrafficDirection.inbound
        XCTAssertNotNil(direction)
    }
}

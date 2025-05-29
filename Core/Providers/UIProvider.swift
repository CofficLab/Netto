import Foundation
import Combine
import SwiftUI

class UIProvider: ObservableObject {
    static let shared = UIProvider()
    private init() {
        setupNotificationListeners()
    }
    
    @Published var status: FilterStatus = .indeterminate
    @Published var dbVisible: Bool = false
    @Published var displayType: DisplayType = .All

    private var cancellables = Set<AnyCancellable>()
    
    func start() {
        self.status = .running
    }
    
    func stop() {
        self.status = .stopped
    }
    
    func setFilterStatus(_ status: FilterStatus) {
        self.status = status
    }

    /// 设置通知监听器
    private func setupNotificationListeners() {
        NotificationCenter.default.publisher(for: .FilterStatusChanged)
            .compactMap { $0.object as? FilterStatus }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.setFilterStatus(status)
            }
            .store(in: &cancellables)
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}

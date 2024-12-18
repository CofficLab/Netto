import SwiftUI
import MagicKit

struct Toolbar: View, SuperLog {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var channel: ChannelProvider
    
    private var shouldShowLogButton: Bool {
        switch app.status {
        case .stopped:
            true
        case .indeterminate:
            false
        case .running:
            true
        case .notInstalled:
            false
        case .needApproval:
            false
        case .waitingForApproval:
            false
        case .error:
            false
        case .disabled, .extensionNotReady:
            false
        }
    }
    
    private var shouldShowStatusIcon: Bool {
        switch app.status {
        case .stopped:
            true
        case .indeterminate:
            false
        case .running:
            true
        case .notInstalled:
            false
        case .needApproval:
            false
        case .waitingForApproval:
            false
        case .error:
            false
        case .disabled, .extensionNotReady:
            false
        }
    }
    
    var iconName: String {
        switch app.status {
        case .stopped:
            "dot_red"
        case .indeterminate:
            "dot_yellow"
        case .running:
            "dot_green"
        case .notInstalled:
            "dot_yellow"
        case .needApproval:
            "dot_yellow"
        case .waitingForApproval:
            "dot_yellow"
        case .error:
            "dot_red"
        case .disabled, .extensionNotReady:
            "dot_red"
        }
    }

    var body: some View {
        
        HStack {
//            Button("数据库") {
//                app.databaseVisible.toggle()
//            }
//            .popover(isPresented: $app.databaseVisible, arrowEdge: .bottom) {
//                DatabaseView()
//                    .frame(width: 500, height: 500)
//                    .background(BackgroundView.type1)
//                    .cornerRadius(10)
//            }

            if shouldShowLogButton {
                if app.logVisible {
                    Button("隐藏日志") {
                        app.logVisible = false
                    }
                } else {
                    Button("显示日志") {
                        app.logVisible = true
                    }
                }
            }

            ZStack {
                switch app.status {
                case .stopped:
                    BtnStart()
                case .indeterminate:
                    Button("状态未知") {}
                case .running:
                    BtnStop()
                case .notInstalled:
                    EmptyView()
                case .needApproval:
                    EmptyView()
                case .waitingForApproval:
                    EmptyView()
                case .error:
                    EmptyView()
                case .disabled, .extensionNotReady:
                    EmptyView()
                }
            }

            if shouldShowStatusIcon {
                ZStack {
                    Image(iconName)
                        .scaleEffect(0.7)
                }
            }
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
}

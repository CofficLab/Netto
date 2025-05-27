import MagicCore
import SwiftUI

struct ExtensionNotReady: View {
    var body: some View {
        Popview(
            iconName: "exclamationmark.shield",
            title: "需要配置系统扩展"
        ) {
            HStack {
                BtnSetting()
                BtnInstall()

//                MagicButton(title: "学习如何设置")
//                    .magicSize(.auto)
//                    .magicIcon(.iconStar)
//                    .magicPopover(content: {
//                        ExtGuide()
//                    })
//                    .frame(width: 150)
//                    .frame(height: 50)
            }
        }
    }
}

#Preview {
    RootView {
        ExtensionNotReady()
    }
    .frame(height: 500)
}

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}

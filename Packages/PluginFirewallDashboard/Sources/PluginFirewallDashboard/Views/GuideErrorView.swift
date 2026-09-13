import SwiftUI
import MagicUI
import MagicBackground
import MagicCore

/// 错误显示视图
/// 显示错误信息并提供复制到剪贴板的功能
struct ErrorView: View {
    let error: Error
    @State private var showCopiedMessage = false
    
    var body: some View {
        VStack(spacing: 16) {
            InstallView()
            
            VStack(spacing: 12) {
                Text("Error: \(error.localizedDescription)")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                ZStack {
                    Button(action: copyErrorToClipboard) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.clipboard")
                            Text("复制错误信息")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(showCopiedMessage ? 0 : 1)
                    
                    if showCopiedMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("已复制")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(20)
            .background(MagicBackground.cherry)
            .cornerRadius(12)
        }

    }
    
    /// 复制错误信息到剪贴板
    /// 将完整的错误描述复制到系统剪贴板
    private func copyErrorToClipboard() {
        let errorText = "Error: \(error.localizedDescription)"
        
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(errorText, forType: .string)
        #else
        UIPasteboard.general.string = errorText
        #endif
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showCopiedMessage = true
        }
        
        // 2秒后隐藏提示信息
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCopiedMessage = false
            }
        }
    }
}

#Preview {
    ErrorView(error: NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "This is a test error message"]))
        .frame(width: 400, height: 500)
}

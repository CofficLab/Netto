import Foundation
import SwiftUI

/// 图标辅助工具类
public struct IconHelper {
    
    /// 创建系统应用图标的通用函数
    /// - Parameters:
    ///   - iconName: 图标名称（SF Symbol名称或自定义图片名称）
    ///   - gradientColors: 渐变色数组，第一个为起始色，第二个为结束色
    ///   - isSystemIcon: 是否为SF Symbol图标（默认为true）
    /// - Returns: 配置好的图标视图
    public static func createSystemIcon(
        iconName: String,
        gradientColors: [Color],
        isSystemIcon: Bool = true
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            if isSystemIcon {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(6)
                    .foregroundColor(.white)
            } else {
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(6)
            }
        }
        .frame(width: 34, height: 34)
        .clipped()
    }
}
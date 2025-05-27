//
//  TileLog.swift
//  TravelMode
//
//  Created by Colorfy on 2025/5/27.
//  Copyright © 2025 Apple. All rights reserved.
//


import MagicCore
import OSLog
import SwiftUI

struct TileSwitcher: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var app: AppManager

    @State var hovered = false
    @State var isPresented = false
    @State var live = false
    @State private var selection: Set<SmartMessage.ID> = []
    @State private var selectedChannel: String = "all"
    @State private var messages: [SmartMessage] = []
    
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

    var firstFlashMessage: SmartMessage? { m.messages.first(where: { $0.shouldFlash }) }

    var body: some View {
        HStack {
            ZStack {
                switch app.status {
                case .stopped:
                    BtnStart(asToolbarItem: true).labelStyle(.iconOnly)
                case .indeterminate:
                    Button("Status Unknown") {}
                case .running:
                    BtnStop(asToolbarItem: true).labelStyle(.iconOnly)
                case .notInstalled, .disabled, .extensionNotReady, .needApproval, .waitingForApproval, .error:
                    EmptyView()
                }
            }
        }
        .onChange(of: firstFlashMessage, {
            if firstFlashMessage != nil {
                self.live = true
            }
        })
        .onHover(perform: { hovering in
            hovered = hovering
        })
        .onTapGesture {
            self.isPresented.toggle()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }.frame(width: 700)
}

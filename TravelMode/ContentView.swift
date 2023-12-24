//
//  ContentView.swift
//  TravelMode
//
//  Created by Angel on 2023/12/24.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    private var angel = Angel()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button("开始") {
                angel.startFilter2()
            }
            
            Button("停止") {
                angel.stopFilter2()
            }
        }
        .padding()
        .onAppear {
            angel.viewWillAppear()
        }
    }
}

#Preview {
    ContentView()
}

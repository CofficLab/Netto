//
//  ContentView.swift
//  TravelMode
//
//  Created by Angel on 2023/12/24.
//  Copyright © 2023 Apple. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            Angel().viewWillAppear()
        }
    }
}

#Preview {
    ContentView()
}

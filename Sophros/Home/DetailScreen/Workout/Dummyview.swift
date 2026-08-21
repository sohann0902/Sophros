//
//  ContentView.swift
//  Sophros
//
//  Created by Sohan Maurya on 20/08/26.
//

import SwiftUI


struct DummyView: View {
    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                Button("Jump to #50") {
                    
                    withAnimation(.easeInOut(duration: 4)) {
                        proxy.scrollTo(50)
                    }
                    
                }

                List(0..<100, id: \.self) { i in
                    Text("Example \(i)")
                    .id(i)
                }
            }
        }
    }
}

#Preview {
    DummyView()
}

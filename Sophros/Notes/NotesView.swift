//
//  NotesView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI

struct NotesView: View {
    var body: some View {
        ZStack {
            Colormanager.baseBackground
                .ignoresSafeArea()
            
            Text("NotesView")
                .font(.system(size: 32, weight: .heavy))
        }
    }
}

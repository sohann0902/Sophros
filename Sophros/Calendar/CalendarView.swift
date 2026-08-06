//
//  CalendarView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//



import SwiftUI

struct CalendarView: View {
    var body: some View {
        ZStack {
            Colormanager.baseBackground
                .ignoresSafeArea()
            
            Text("CalendarView")
                .font(.system(size: 32, weight: .heavy))
        }
    }
}


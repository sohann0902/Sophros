//
//  HomeView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import CoreData

struct HomeView : View {

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.createdAt, ascending: true)],
        animation: nil
    ) private var profiles: FetchedResults<UserProfile>

    private var greetingName: String {
        let name = profiles.first?.name ?? ""
        return name.isEmpty ? "there" : name
    }

	var body: some View {
		NavigationStack {
			ZStack(alignment: .topLeading) {
				Color.surface
					.ignoresSafeArea()
				
				//titleView
				VStack(alignment: .leading, spacing: 0) {
					
					// dashboard
					CardsView()
						.ignoresSafeArea(edges: .bottom)
					
				}
			}
			.navigationTitle("Hey, \(greetingName)")
		}
	}
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

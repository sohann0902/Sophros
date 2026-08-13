//
//  WaterDetailView.swift
//  Sophros
//
//  Created by Sohan Maurya on 04/08/26.
//

import SwiftUI
import CoreData

struct WaterDetailView: View {
    let card : DashboardCard
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest private var entries: FetchedResults<WaterEntry>
    @FetchRequest private var goal: FetchedResults<WaterGoal>
    
    init(card: DashboardCard) {
        self.card = card
        
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        _entries = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \WaterEntry.createdAt, ascending: false)
            ],
            predicate: NSPredicate(
                format: "createdAt >= %@ AND createdAt < %@",
                startOfToday as NSDate,
                endOfToday as NSDate
            ),
            animation: .default
        )
        
        _goal = FetchRequest(
            sortDescriptors: [],
            animation: .default
        )
    }
    
    private var dailyGoalML: Int {
        Int(goal.first?.amountML ?? 2500)
    }
    
    private var totalML: Int {
        Int(entries.reduce(0) { $0 + $1.amountML })
    }
    
    private var progress: Double {
        guard dailyGoalML > 0 else { return 0 }
        
        return (Double(totalML) / Double(dailyGoalML))
    }
    
    private var lastDrinkML: Int {
        Int(entries.first?.amountML ?? 0)
    }
    
    @State private var entryBeingEdited: WaterEntry?
    @State private var updateWaterEntry = false
    
    @State private var presentCustomEntryForm = false
    @State private var customWaterEntry : String = "250"
    
    private let waterAmounts = Array(stride(from: 0, through: 1000, by: 50))
    
    var body: some View {
            ZStack(alignment: .bottomTrailing) {
                Colormanager.baseBackground
                    .ignoresSafeArea()
                
                List {
                    
                    Section {
                        VStack(spacing: 28) {
                            waterProgress
                            
                            HStack(spacing: 0) {
                                statistic(value: "\(lastDrinkML) ml", title: "Last Drink")
                                
                                Divider().frame(height: 80)
                                
                                statistic(value: "\(totalML / 250)", title: "Cups")
                                
                                Divider().frame(height: 80)
                                
                                statistic(
                                    value: "\(Int(progress * 100))%",
                                    title: "Goal"
                                )
                            }
                            
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Quick Add")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Colormanager.Typography.primaryText)
                                
                                    HStack(spacing: 12) {
                                        quickAddButton("+250 ml", amount: 250)
                                        quickAddButton("+500 ml", amount: 500)
                                        quickAddButton("+1 L", amount: 1000)
                                        customAddButton()
                                    }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    Section {
                        ForEach(entries) { entry in
                            waterLogRow(entry)
                                .listRowInsets(
                                    EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16)
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(entry)
                                    } label: {
                                        Label("", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                                                    Button(role: .confirm) {
                                                                        update(entry)
                                                                    } label: {
                                                                        Label("", systemImage: "square.and.pencil")
                                                                    }
                                }
                        }
                    } header: {
                        Text("Today's Log")
                            .foregroundStyle(Colormanager.Typography.primaryText)
                            .font(.title3.weight(.bold))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Water")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Add Water", isPresented: $presentCustomEntryForm) {
                TextField("Amount in ml", text: $customWaterEntry)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {
                    customWaterEntry = "250"
                }
                
                Button("Save") {
                    guard let customWaterEntry = Int(customWaterEntry), customWaterEntry > 0 else {
                        return
                    }
                    
                    addWater(customWaterEntry)
                    self.customWaterEntry = "250"
                }
            } message: {
                Text("Enter the amount of water in milliliters.")
            }
            .alert("Upate Quantity", isPresented: $updateWaterEntry) {
                TextField("Amount in ml", text: $customWaterEntry)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {
                    customWaterEntry = "250"
                }
                
                Button("Save") {
                    guard let customWaterEntry = Int(customWaterEntry), customWaterEntry > 0 else {
                        return
                    }
                    
                    update()
                    self.customWaterEntry = "250"
                }
            } message: {
                Text("Enter the amount of water in milliliters.")
            }
    }
    
    private var waterProgress: some View {
        ZStack {
            ActivityRingView(progress: progress)
            VStack(spacing: 8) {
                
                Text(litersText(totalML))
                    .font(.system(size: 46, weight: .black))
                    .foregroundStyle(Colormanager.Typography.primaryText)
                
                Text("of \(litersText(dailyGoalML))")
                    .font(.title3)
                    .foregroundStyle(Colormanager.Typography.secondaryText)
            }
        }
        .padding()
    }
    
    private func statistic(value: String, title: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2.weight(.bold))
            
            Text(title)
                .font(.subheadline)
        }
        .foregroundStyle(Colormanager.Typography.primaryText)
        .frame(maxWidth: .infinity)
    }
    
    private func quickAddButton(_ title: String, amount: Int) -> some View {
        Button {
            addWater(amount)
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Colormanager.baseBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
                .foregroundStyle(Colormanager.Typography.primaryText)
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    private func customAddButton() -> some View {
        Button {
            addCustomWater()
        } label:  {
            Text("Custom")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Colormanager.baseBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
                .foregroundStyle(Colormanager.Typography.primaryText)
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    private func waterLogRow(_ entry: WaterEntry) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "drop.circle")
                .foregroundStyle(.blue)
            
            Text("\(Int(entry.amountML)) ml")
                .font(.headline)
                .foregroundStyle(Colormanager.Typography.primaryText)
            
            Spacer()
            
            Text(entry.createdAt ?? .now, format: .dateTime.hour().minute())
                .foregroundStyle(Colormanager.Typography.secondaryText)
            
            Image(systemName: "ellipsis")
                .foregroundStyle(Colormanager.Typography.secondaryText)
        }
        .padding()
        .background(Colormanager.baseBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.16), radius: 6, y: 2)
    }
    
    private func addWater(_ amount: Int) {
        let entry = WaterEntry(context: context)
        entry.id = UUID()
        entry.note = "q"
        entry.source = .preset
        entry.amountML = Int64(amount)
        entry.createdAt = .now
        entry.updatedAt = .now
        
        do {
            try context.save()
        } catch {
            print("Could not save water entry: \(error.localizedDescription)")
        }
    }
    
    private func addCustomWater() {
        presentCustomEntryForm = true
    }
    
    private func delete(_ entry: WaterEntry) {
        context.delete(entry)
        
        do {
            try context.save()
        } catch {
            print("Could not delete water entry: \(error.localizedDescription)")
        }
    }
    
    private func update() {
        guard let entry = entryBeingEdited else { return }
        
        entry.amountML = Int64(customWaterEntry) ?? entry.amountML
        entry.updatedAt = .now
        
        do {
            try context.save()
        } catch {
            print("Could not update water entry: \(error.localizedDescription)")
        }
    }
    
    private func update(_ entry: WaterEntry) {
        entryBeingEdited = entry
        customWaterEntry = String(entry.amountML)
        updateWaterEntry = true
    }
    
    private func litersText(_ milliliters: Int) -> String {
        String(format: "%.1f L", Double(milliliters) / 1000)
    }
}

#Preview {
    WaterDetailView(card: DashboardCard.cards[0])
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

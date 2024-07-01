//
//  ScenarioThree.swift
//  Navi
//
//  Created by Jamie Chu on 6/30/24.
//

import SwiftUI

struct ScenarioThree: View {
    
    @ObservedObject var viewModel: ScenarioThreeViewModel
    
    var body: some View {
        VStack {
            Text("scenario one")
            
            List(viewModel.state.items) { item in
                HStack {
                    Text(item.name)
                    Text(item.id.uuidString)
                }
                .onTapGesture {
                    viewModel.onItemTapped(item)
                }
            }
        }
        .sheet(item: $viewModel.state.displayedItem) { item in
            ModifiableItemDetailView(
                item: item,
                onSaveTapped: {
                    viewModel.onSaveTapped(item)
                },
                onSaveAndExitTapped: {
                    viewModel.onSaveAndExitTapped(item)
                },
                text: Binding(
                    get: { item.scratch },
                    set: {
                        viewModel.state.displayedItem?.scratch = $0
                    }
                )
            )
        }
    }
}

#Preview {
    ScenarioThree(viewModel: .init(state: .mock))
}

final class ScenarioThreeViewModel: ObservableObject {
        struct ParentState {
            var items: [ViewItem]
            
            var displayedItem: ModifiableViewItem?
            
            static let mock = ParentState(
                items: randomNames.map {
                    ViewItem.init(id: .init(), name: $0)
                }
            )
        }
        
        @Published var state: ParentState
        
        init(state: ParentState = .mock) {
            self.state = state
        }
        
        func onItemTapped(_ item: ViewItem) {
            print("-=- \(#function) \(item)")
            
            state.displayedItem = .init(
                id: item.id,
                scratch: item.name
            )
        }
        
        
        func onSaveTapped(_ item: ModifiableViewItem) {
            save(item: item)
        }
        
        func onSaveAndExitTapped(_ item: ModifiableViewItem) {
            save(item: item)
            state.displayedItem = nil
        }
        
        private func save(item: ModifiableViewItem) {
            if let index = state.items.firstIndex(where: {
                $0.id == item.id
            }) {
                state.items[index].name = item.scratch
            }
        }
        
    }

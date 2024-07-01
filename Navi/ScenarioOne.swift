//
//  ScenarioOne.swift
//  Navi
//
//  Created by Jamie Chu on 6/28/24.
//

import SwiftUI

/*
 
 ScenarioOne
 A B?
 
 when something happens in B, i can udpate A.
  
 */

struct ViewItem: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
}

struct ModifiableViewItem: Identifiable {
    let id: ViewItem.ID
    var scratch: String
}

final class ScenarioOneViewModel: ObservableObject {
    // TODO: - dynamic memeber lookup
    struct ParentState {
        var items: [ViewItem]
        
        var displayedItem: ModifiableViewItem?
        
        static let mock = ParentState(
            items: randomNames.map {
                ViewItem(id: .init(), name: $0)
            }
        )
    }
    
    @Published var state: ParentState
    
    init(state: ParentState = .mock) {
        self.state = state
    }
    
    func onItemTapped(_ item: ViewItem) {
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

struct ScenarioOne: View {
    @ObservedObject var viewModel: ScenarioOneViewModel
    
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
    ScenarioOne(viewModel: .init(state: .mock))
}


let randomNames = [
    "Charlie",
    "Max",
    "Milo",
    "Oscar",
    "Toby",
    "Bella",
    "Daisy",
    "Lola",
    "Lucy",
    "Molly"
]


struct ModifiableItemDetailView: View {
    let item: ModifiableViewItem
    let onSaveTapped: () -> Void
    let onSaveAndExitTapped: () -> Void

    @Binding var text: String

    var body: some View {
        VStack {
            Text("detiail view")
            Text(item.scratch)
            Text(item.id.uuidString)
            
            Button {
                onSaveTapped()
            } label: {
                Text("only save")
            }
            
            Button {
                onSaveAndExitTapped()
            } label: {
                Text("save and exit")
            }

            TextField("some textfield", text: $text)
        }

    }
}

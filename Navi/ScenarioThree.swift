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
            Text("scenario three")
            
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
            ModifiableItemDetailView2(
                item: item,
                onSaveTapped: {
                    viewModel.onSaveTapped(item)
                },
                onSaveAndExitTapped: {
                    viewModel.onSaveAndExitTapped(item)
                }, 
                onShowConfirmationTapped: {
                    viewModel.onShowConfirmationTapped(item)
                },
                onCommitTapped: { confirm in
                    viewModel.onCommitTapped(confirm)
                },
                onAbortTapped: { confirm in
                    viewModel.onAbortTapped(confirm)
                },
                onCancelConfirmTapped: {
                    viewModel.onCancelConfirmTapped()
                },
                text: Binding(
                    get: { item.scratch },
                    set: {
                        viewModel.state.displayedItem?.scratch = $0
                    }
                ), 
                confirmation: Binding(
                    get: { item.confirmation },
                    set: {
                        
                        viewModel.onConfirmationChanged($0)
                    }
                )
            )
        }
    }
}

#Preview {
    ScenarioThree(viewModel: .init(state: .mock))
}

struct ModifiableViewItem2: Identifiable {
    let id: ViewItem.ID
    var scratch: String
    
    struct Confirmation: Identifiable {
        let id: ViewItem.ID
        let before: String
        let after: String
        
    }
 
    var confirmation: Confirmation?
}

final class ScenarioThreeViewModel: ObservableObject {
    struct ParentState {
        var items: [ViewItem]
        
        var displayedItem: ModifiableViewItem2?
        
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
        
    func onSaveTapped(_ item: ModifiableViewItem2) {
        save(item: item)
    }
    
    func onSaveAndExitTapped(_ item: ModifiableViewItem2) {
        save(item: item)
        state.displayedItem = nil
    }
    
    func onShowConfirmationTapped(_ item: ModifiableViewItem2) {
        
        if let before = state.items.first(where: { $0.id == item.id }),
            let after = state.displayedItem?.scratch {
            
            // show the confirmation screen.
            
            state.displayedItem?.confirmation = .init(
                id: item.id,
                before: before.name,
                after: after
            )            
        }
    }

    func onConfirmationChanged(_ newValue: ModifiableViewItem2.Confirmation?) {
        state.displayedItem?.confirmation = newValue
    }
    
    func onCommitTapped(_ confirm: ModifiableViewItem2.Confirmation) {
        // save it.
        if let index = state.items.firstIndex(where: {
            $0.id == confirm.id
        }) {
            state.items[index].name = confirm.after
        }
        
        // dismiss all the way back to the first
        state.displayedItem = nil
    }
    
    func onAbortTapped(_ confirm: ModifiableViewItem2.Confirmation) {
        state.displayedItem = nil
    }

    func onCancelConfirmTapped() {
        state.displayedItem?.confirmation = nil
    }

    private func save(item: ModifiableViewItem2) {
        if let index = state.items.firstIndex(where: {
            $0.id == item.id
        }) {
            state.items[index].name = item.scratch
        }
    }
}


struct ModifiableItemDetailView2: View {
    let item: ModifiableViewItem2
    let onSaveTapped: () -> Void
    let onSaveAndExitTapped: () -> Void
    let onShowConfirmationTapped: () -> Void
    let onCommitTapped: (ModifiableViewItem2.Confirmation) -> Void
    let onAbortTapped: (ModifiableViewItem2.Confirmation) -> Void
    let onCancelConfirmTapped: () -> Void

    @Binding var text: String
    @Binding var confirmation: ModifiableViewItem2.Confirmation?
    
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
            
            Button {
                onShowConfirmationTapped()
            } label: {
                Text("confirmation screen")
            }
                        
            TextField("some textfield", text: $text)
        }
        .sheet(item: $confirmation) { confirm in
            VStack {
                Text("before: \(confirm.before)")
                Text("after: \(confirm.after)")
                            
                Button {
                    onCommitTapped(confirm)
                } label: {
                    Text("commit")
                }
                
                
                Button {
                    onAbortTapped(confirm)
                } label: {
                    Text("abort")
                }

                Button {
                    onCancelConfirmTapped()
                } label: {
                    Text("cancel")
                }
            }
        }
    }
}

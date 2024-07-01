//
//  ScenarioTwo.swift
//  Navi
//
//  Created by Jamie Chu on 6/28/24.
//

import SwiftUI



/*
 
 There are a few screens presented on top of each other A, B, C
 
 an event happened on C, and we want to update A
 
 navigationPath can be represented as:
 
 [
    A.State,
    B.State,
    C.State,
 ]
 
 
 //
 
 */
import Combine

final class ScenarioTwoViewModel: ObservableObject {
    
    // this needs to have a getter and setter, to be a binding, but we won't know when the path changes.
    @Published var path: NavigationPath
    @Published private var rawPath: [Product]
    
    private var cancellables: Set<AnyCancellable> = []

    init(rawPath: [Product] = []) {
        self.rawPath = rawPath
        self.path = .init()
        
        $path
            .removeDuplicates()
            .sink { [weak self] newPath in
                guard let self, !newPath.isEmpty else { return }
                print("-=- path changed \(newPath.count)")
                // this is horribly broken, unless we can recover types from the codable representation.

                self.rawPath = Array(self.rawPath.prefix(newPath.count))
            }.store(in: &cancellables)

        // try to make sure that this is the final source of truth.
        $rawPath
            .removeDuplicates()
            .sink { [weak self] newProducts in
                // this can have an out of date representation of
                guard let self else { return }
                print("-=- rawPath changed \(rawPath) \(newProducts)")
                
                if newProducts.isEmpty && rawPath.isEmpty {
                    
                }

                self.path = NavigationPath(newProducts)
            }.store(in: &cancellables)
    }

    func onStackEverythingOnPathTapped() {
        rawPath = Product.mocks
    }

    func onFirstTapped() {
        rawPath.append(Product.first(randomNames.map { ViewItem(id: .init(), name: $0)}))
    }
    
    func onModifyOneTapped() {
        if let first = rawPath.first,
           case .first(var items) = first {

            items[0].name = items[0].name + " Changed"
            rawPath[0] = .first(items)

        } else {
            print("-=- failed to match")
        }
    }
    func onAddTwoTapped() {
        print("-=- before \(rawPath)")
        rawPath.append(.second(Person.people))
        print("-=- after \(rawPath)")
    }

    func onSecondTapped() {
        rawPath.append(.second(Person.people))

    }
    
    func onAddThreeTapped() {
        rawPath.append(.third(.init(
            id: UUID(),
            name: "random person added"
        )))
//        rawPath.append(.second(Person.people))
    }
}

// maybe we need to find by ID, so we can mutate it more earily.
enum Product: Hashable {
    case first([ViewItem])
    case second([Person])
    case third(ViewItem)
    
    static let mocks: [Product] = {
        let items = randomNames.map { ViewItem(id: .init(), name: $0)}

        
        return [
            .first(items),
            .second(Person.people),
            .third(items.randomElement()!)
        ]
    }()
}

struct ScenarioTwo: View {
    @ObservedObject var viewModel: ScenarioTwoViewModel
    
    var body: some View {
        NavigationStack(
            path: .init(
                get: {
                    viewModel.path
                },
                set: {
                    viewModel.path = $0
                    print("-=- new Path \($0)")
                }
            )
        ) {
            
            //        NavigationStack(path: $viewModel.path) {
            Text("scenario two state: ")
            
            Button("stack everything", action: {
                viewModel.onStackEverythingOnPathTapped()
            })
                        
            List(Product.mocks, id: \.self) { product in
                switch product { // this is where you make the CTA for the next view.
                case .first:
                    Button {
                        viewModel.onFirstTapped()
                    } label: {
                        Text("using a callback instead of a navigation link for firstItem")
                    }
                case .second:
                    
                    Button {
                        viewModel.onSecondTapped()
                    } label: {
                        Text("using a callback instead of a navigation link for second item")
                    }

                    // don't use navigationLink, since we lose the ability to keep the data in sync.
//                    NavigationLink("second item ", value: product)
                case .third:
                    NavigationLink("third item ", value: product)
                }
            }
            .navigationDestination(for: Product.self) { product in
                VStack {
                    Text("view \(viewModel.path)")

                    switch product {
                    case .first(let items):
                        ScenarioOne(viewModel: .init(state: .init( // the issue is this creates its owns source of truth
                            items: items,
                            displayedItem: nil
                        )))
                        
                    case .second(let people):
                        Text("second item destination")
                        PeopleView(people: people)

                    case .third(let item):
                        ModifiableItemDetailView(
                            item: .init(
                                id: item.id,
                                scratch: "some scratch"
                            ),
                            onSaveTapped: { print("-=- onSaveTapped ") },
                            onSaveAndExitTapped: { print("-=- onSaveAndExitTapped") },
                            text: .constant("fake")
                        )
                        
                        Text("third item destination")
                    }

                    Button(action: {
                        viewModel.onModifyOneTapped()
                    }, label: {
                        Text("modify one. ")
                    })
                    
                    Button(action: {
                        viewModel.onAddTwoTapped()
                    }, label: {
                        Text("add two")
                    })

                    Button(action: {
                        viewModel.onAddThreeTapped()
                    }, label: {
                        Text("add three")
                    })

                }
            }
        }
    }
}

#Preview {
    ScenarioTwo(viewModel: .init())
}

func process(_ newPath: NavigationPath) {
    do {
        _ = try newPath
            .codable
            .map(JSONEncoder().encode)
            .map(tryCurry(JSONDecoder().decode)(NavigationPath.CodableRepresentation.self))
            .map(NavigationPath.init)
    } catch {
        print("-=- failed to create navigation path: \(error.localizedDescription)")
    }
}

func tryCurry<A, B, C>(
    _ f: @escaping (A, B) throws -> C
) -> (A) -> (B) throws -> C {
    { a in { b in try f(a, b) } }
}

struct Person: Equatable, Hashable {
    let id: Int
    let name: String
    let age: Int
    
    static let people: [Person] = [
        Person(id: 1, name: "Alice", age: 25),
        Person(id: 2, name: "Bob", age: 30),
        Person(id: 3, name: "Charlie", age: 35)
    ]
}

struct PeopleView: View {
    let people: [Person]
    
    var body: some View {
        List(people, id: \.id) { person in
            VStack(alignment: .leading) {
                Text(person.name)
                    .font(.headline)
                Text("Age: \(person.age)")
                    .font(.subheadline)
            }
        }
    }
}

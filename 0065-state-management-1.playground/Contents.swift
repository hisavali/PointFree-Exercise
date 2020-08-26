import UIKit
import SwiftUI

public let wolframAlphaApiKey = "6H69Q3-828TKQJ4EP"


final class Store<Value, Action>: ObservableObject {
    @Published var value: Value
    let reducer: (inout Value, Action) -> Void
    init(_ initialValue: Value, reducer: @escaping (inout Value, Action) -> Void) {
        self.value = initialValue
        self.reducer = reducer
    }

    func send(_ action: Action) {
        self.reducer(&self.value, action)
    }
}

struct AppState {
   var count: Int = 0
   var favorites: [Int] = []
   var activityFeed: [ActivityFeed] = []

    struct ActivityFeed {
        enum ActivityFeedType {
            case addedFaviourite(Int)
            case removedFaviourite(Int)
        }

        let timestamp: Date
        let type: ActivityFeedType
    }
}

extension AppState {
    mutating func addFaviourite() {
        self.favorites.append(self.count)
        self.activityFeed.append(.init(timestamp: Date(), type: .addedFaviourite(self.count)))
    }

    mutating func removeFaviourite(_ prime: Int) {
        self.favorites.removeAll { $0 == prime }
        self.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(prime)))
    }

    mutating func removeFaviourite() {
        self.removeFaviourite(self.count)
    }

    mutating func removeFaviouritePrimes(at indexSet: IndexSet) {
        for index in indexSet {
            self.removeFaviourite(self.favorites[index])
        }
    }
}

// Mark: - Action
enum CounterAction {
    case incrTapped
    case decrTapped
}

enum PrimeModalAction {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}

enum FavoritePrimeAction {
    case deleteFavoritePrimes(IndexSet)
}

enum AppAction {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
    case favoritePrime(FavoritePrimeAction)
}


// Mark: - Reducers
func appReducer(_ state: inout AppState, _ action: AppAction) {
    switch action {
    case .counter(.incrTapped):
        state.count += 1
    case .counter(.decrTapped):
        state.count -= 1
    case .primeModal(.saveFavoritePrimeTapped):
        state.favorites.append(state.count)
        state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(state.count)))
    case .primeModal(.removeFavoritePrimeTapped):
        state.favorites.removeAll { $0 == state.count }
        state.activityFeed.append(.init(timestamp: Date(), type: .addedFaviourite(state.count)))
    case let .favoritePrime(.deleteFavoritePrimes(indexSet)):
        for index in indexSet {
            let prime = state.favorites[index]
            state.favorites.remove(at: index)
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(prime)))
        }

    }
}

//var state = AppState()
//counterReducer(&state, .incrTapped)
//print(state.count)
//counterReducer(&state, .incrTapped)
//print(state.count)
//counterReducer(&state, .decrTapped)
//print(state.count)

struct ContentView: View {
    //@ObservedObject var state: AppState
    @ObservedObject var store: Store<AppState, AppAction>
    var body: some View { //some introudced swift5.1
        NavigationView {
            List {
                NavigationLink(destination: CounterView(store: self.store)) {
                    Text("Counter")
                }
                NavigationLink(destination: FaviouritePrimeView(store: self.store)) {
                    Text("Favourite")
                }
            }.navigationBarTitle("State Management")
        }
    }
}

func oridinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}

struct CounterView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    @State var isModal: Bool = false
    @State var alertNthPrime: Int?
    @State var showAlert: Bool = false
    @State var nthPrimeButtonDisabled: Bool = false

    var body: some View {
        VStack {
            HStack {
                Button("-") {
                    self.store.send(.counter(.decrTapped))
                }
                Text("\(self.store.value.count)")
                Button("+") {
                    self.store.send(.counter(.incrTapped))
                }
            }
            Button("Is this prime?") { self.isModal = true }
            Button("What's the \(oridinal(self.store.value.count)) Prime?"){
                self.nthPrimeButtonDisabled = true
                nthPrime(self.store.value.count) { prime in
                    self.alertNthPrime = prime
                    self.showAlert = prime != nil
                    self.nthPrimeButtonDisabled = false
                }
            }.disabled(self.nthPrimeButtonDisabled)
        }
        .font(.title)
        .navigationBarTitle("Counter")
        .popover(isPresented: $isModal) {
            IsPrimeView(store: self.store)
            Button.init("Dismiss") {
                self.isModal = false
            }
        }
        .alert(isPresented: self.$showAlert) { () -> Alert in
            Alert(title: Text("The \(oridinal(self.store.value.count)) is \(self.alertNthPrime ?? 0)"),
                dismissButton: .default(Text("Ok")))
        }
    }
}

struct IsPrimeView: View {
    @ObservedObject var store: Store<AppState, AppAction>

    private func isPrime (_ p: Int) -> Bool {
      if p <= 1 { return false }
      if p <= 3 { return true }
      for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
      }
      return true
    }

    var body: some View {
        VStack {
            if isPrime(self.store.value.count) {
                Text("Number \(self.store.value.count) is prime")
                if self.store.value.favorites.contains(self.store.value.count) {
                    Button("Remove from faviroute") {
                        self.store.send(.primeModal(.removeFavoritePrimeTapped))
                    }
                } else {
                    Button("Save to faviroute") {
                        self.store.send(.primeModal(.saveFavoritePrimeTapped))
                    }
                }
            } else {
                Text("Number \(self.store.value.count) is NOT prime")
            }
        }
    }

}


struct FaviouritePrimeView: View {
    @ObservedObject var store: Store<AppState, AppAction>
    var body: some View {
        List {
            ForEach(self.store.value.favorites, id: \.self) { p in
                Text("\(p)")
            }.onDelete {
                self.store.send(.favoritePrime(.deleteFavoritePrimes($0)))
            }
        }.navigationBarTitle(Text("Favorite primes"))
    }
}

import PlaygroundSupport
PlaygroundPage.current.liveView = UIHostingController(
    rootView: ContentView(store: .init(AppState(), reducer: appReducer))
)

struct WolframAlphaResult: Decodable {
  let queryresult: QueryResult

  struct QueryResult: Decodable {
    let pods: [Pod]

    struct Pod: Decodable {
      let primary: Bool?
      let subpods: [SubPod]

      struct SubPod: Decodable {
        let plaintext: String
      }
    }
  }
}

func wolframAlpha(query: String, callback: @escaping (WolframAlphaResult?) -> Void) -> Void {
    var components = URLComponents(string: "https://api.wolframalpha.com/v2/query")!
    components.queryItems = [
        URLQueryItem(name: "input", value: query),
        URLQueryItem(name: "format", value: "plaintext"),
        URLQueryItem(name: "output", value: "JSON"),
        URLQueryItem(name: "appid", value: wolframAlphaApiKey),
    ]

    URLSession.shared.dataTask(with: components.url(relativeTo: nil)!) { data, response, error in
        callback(
            data
                .flatMap { try? JSONDecoder().decode(WolframAlphaResult.self, from: $0) }
        )
    }
    .resume()
}

func nthPrime(_ n: Int, callback: @escaping (Int?) -> Void) -> Void {
  wolframAlpha(query: "prime \(n)") { result in
    callback(
      result
        .flatMap {
          $0.queryresult
            .pods
            .first(where: { $0.primary == .some(true) })?
            .subpods
            .first?
            .plaintext
        }
        .flatMap(Int.init)
    )
  }
}



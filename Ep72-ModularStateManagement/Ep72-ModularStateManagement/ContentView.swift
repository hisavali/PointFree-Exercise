import Counter
import ComposableArchitecture
import FavoritePrimes
import SwiftUI

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

struct FavoritePrimeState {
    var favorites: [Int] = []
    var activityFeed: [AppState.ActivityFeed] = []
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

extension AppState {
//    var primeModalState: PrimeModalState {
//        get {
//            return (count: count, favorites: favorites)
//        }
//
//        set {
//            count = newValue.count
//            favorites = newValue.favorites
//        }
//    }

    var counterView: CounterViewState {
        get {
            return (count: count, favorites: favorites)
        }

        set {
            count = newValue.count
            favorites = newValue.favorites
        }
    }
}

// Mark: - Action
enum AppAction {
//    case counter(CounterAction)
//    case primeModal(PrimeModalAction)
    case counterView(CounterViewAction)
    case favoritePrime(FavoritePrimeAction)

//    var counter: CounterAction? {
//      get {
//        guard case let .counter(value) = self else { return nil }
//        return value
//      }
//      set {
//        guard case .counter = self, let newValue = newValue else { return }
//        self = .counter(newValue)
//      }
//    }
//
//    var primeModal: PrimeModalAction? {
//        get {
//            guard case let .primeModal(value) = self else { return nil }
//            return value
//        }
//        set {
//            guard case .primeModal = self, let newValue = newValue else { return }
//            self = .primeModal(newValue)
//        }
//    }

    var favoritePrime: FavoritePrimeAction? {
        get {
            guard case let .favoritePrime(value) = self  else { return nil }
            return value
        }
        set {
            guard case .favoritePrime = self, let newValue = newValue else { return }
            self = .favoritePrime(newValue)
        }
    }

    var counterView: CounterViewAction? {
        get {
            guard case let .counterView(value) = self  else { return nil }
            return value
        }
        set {
            guard case .counterView = self, let newValue = newValue else { return }
            self = .counterView(newValue)
        }
    }
}

let _appReducer: (inout AppState, AppAction) -> Void  = combine(
    //pullback(counterReducer, { $0.count }),
    //pullback(counterReducer, get: { $0.count }, set:  { $0.count = $1 }),
//    pullback(counterReducer, value:\.count, action: \.counter),
//    pullback(primeModalReducer, value: \.primeModalState, action: \.primeModal),
    pullback(counterViewReducer, value: \.counterView, action: \.counterView),
    pullback(favoritePrimeReducer, value: \.favorites, action: \.favoritePrime)
)

let appReducer = pullback(_appReducer, value: \.self, action: \.self)
struct ContentView: View {
    //@ObservedObject var state: AppState
    @ObservedObject var store: Store<AppState, AppAction>
    var body: some View { //some introudced swift5.1
        NavigationView {
            List {
                NavigationLink("Counter Demo",
                               destination: CounterView(
                                store: self.store
                                    .view(
                                        value: { ($0.count, $0.favorites) },
                                        action: { localAction in
                                            switch localAction {
                                            case let .left(action):
                                                return .counterView(.left(action))
                                            case let .right(action):
                                                return .counterView(.right(action))
                                            }
                                    }
                                )
                    )
                )
                NavigationLink("Favourite",
                               destination: FaviouritePrimeView(
                                store: self.store
                                    .view (
                                        value: { $0.favorites },
                                        action: { .favoritePrime($0) }
                                )
                    )
                )
            }.navigationBarTitle("State Management")
        }
    }
}

//struct IsPrimeModalView1: View {
//    @ObservedObject var store: Store<PrimeModalState, AppAction>
//
//    private func isPrime (_ p: Int) -> Bool {
//      if p <= 1 { return false }
//      if p <= 3 { return true }
//      for i in 2...Int(sqrtf(Float(p))) {
//        if p % i == 0 { return false }
//      }
//      return true
//    }
//
//    var body: some View {
//        VStack {
//            if isPrime(self.store.value.count) {
//                Text("Number \(self.store.value.count) is prime")
//                if self.store.value.favorites.contains(self.store.value.count) {
//                    Button("Remove from faviroute") {
//                        self.store.send(.primeModal(.removeFavoritePrimeTapped))
//                    }
//                } else {
//                    Button("Save to faviroute") {
//                        self.store.send(.primeModal(.saveFavoritePrimeTapped))
//                    }
//                }
//            } else {
//                Text("Number \(self.store.value.count) is NOT prime")
//            }
//        }
//    }
//
//}


struct FaviouritePrimeView1: View {
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

struct FaviouritePrimeView2: View {
    @ObservedObject var store: Store<[Int], AppAction>
    var body: some View {
        List {
            ForEach(self.store.value, id: \.self) { p in
                Text("\(p)")
            }.onDelete {
                self.store.send(.favoritePrime(.deleteFavoritePrimes($0)))
            }
        }.navigationBarTitle(Text("Favorite primes"))
    }
}

// EP 70 - Exericse
func activityFeed(
  _ reducer: @escaping (inout AppState, AppAction) -> Void
) -> (inout AppState, AppAction) -> Void {
    return { state, action in
        activityFeedReducer(&state, action)
        reducer(&state, action)
    }
}

func activityFeedReducer(_ state: inout AppState, _ action: AppAction) {
    switch action {
    case .counterView(.right(.saveFavoritePrimeTapped)):
        state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(state.count)))
    case .counterView(.right(.removeFavoritePrimeTapped)):
        state.activityFeed.append(.init(timestamp: Date(), type: .addedFaviourite(state.count)))
    case let .favoritePrime(.deleteFavoritePrimes(indexSet)):
        for index in indexSet {
            let prime = state.favorites[index]
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(prime)))
        }
    default:
        break
    }
}

let appReducerWithActivityFeed = activityFeed(appReducer)
let appReducerWithActivityFeedAndLoggin = loggingReducer(activityFeed(appReducer))

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: .init(AppState(), reducer: appReducerWithActivityFeedAndLoggin))
    }
}

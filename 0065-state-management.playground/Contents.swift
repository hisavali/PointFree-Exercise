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

    var counter: CounterAction? {
      get {
        guard case let .counter(value) = self else { return nil }
        return value
      }
      set {
        guard case .counter = self, let newValue = newValue else { return }
        self = .counter(newValue)
      }
    }

    var primeModal: PrimeModalAction? {
        get {
            guard case let .primeModal(value) = self else { return nil }
            return value
        }
        set {
            guard case .primeModal = self, let newValue = newValue else { return }
            self = .primeModal(newValue)
        }
    }

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
}

var action = AppAction.counter(.incrTapped)
action.counter
action.counter = CounterAction.decrTapped
action.favoritePrime


// Mark: - Reducers
func counterReducer1(_ state: inout AppState, _ action: AppAction) {
    switch action {
    case .counter(.incrTapped):
        state.count += 1
    case .counter(.decrTapped):
        state.count -= 1
    default:
        break
    }
}

func counterReducer2(_ state: inout Int, _ action: AppAction) {
    switch action {
    case .counter(.incrTapped):
        state += 1
    case .counter(.decrTapped):
        state -= 1
    default:
        break
    }
}

func counterReducer(_ state: inout Int, _ action: CounterAction) {
    switch action {
    case .incrTapped:
        state += 1
    case .decrTapped:
        state -= 1
    }
}

func primeModalReducer1(_ state: inout AppState, _ action: AppAction) {
    switch action {
    case .primeModal(.saveFavoritePrimeTapped):
        state.favorites.append(state.count)
        state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(state.count)))
    case .primeModal(.removeFavoritePrimeTapped):
        state.favorites.removeAll { $0 == state.count }
        state.activityFeed.append(.init(timestamp: Date(), type: .addedFaviourite(state.count)))
    default:
        break
    }
}

func primeModalReducer2(_ state: inout AppState, _ action: PrimeModalAction) {
    switch action {
    case .saveFavoritePrimeTapped:
        state.favorites.append(state.count)
        state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(state.count)))
    case .removeFavoritePrimeTapped:
        state.favorites.removeAll { $0 == state.count }
        state.activityFeed.append(.init(timestamp: Date(), type: .addedFaviourite(state.count)))
    }
}

func primeModalReducer(_ state: inout AppState, _ action: PrimeModalAction) {
    switch action {
    case .saveFavoritePrimeTapped:
        state.favorites.append(state.count)
    case .removeFavoritePrimeTapped:
        state.favorites.removeAll { $0 == state.count }
    }
}

func favoritePrimeReducer1(_ state: inout AppState, _ action: AppAction) {
    switch action {
    case let .favoritePrime(.deleteFavoritePrimes(indexSet)):
        for index in indexSet {
            let prime = state.favorites[index]
            state.favorites.remove(at: index)
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(prime)))
        }
    default:
        break
    }
}

func favoritePrimeReducer1(_ state: inout FavoritePrimeState,
                          _ action: AppAction) {
    switch action {
    case let .favoritePrime(.deleteFavoritePrimes(indexSet)):
        for index in indexSet {
            let prime = state.favorites[index]
            state.favorites.remove(at: index)
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(prime)))
        }
    default:
        break
    }
}

func favoritePrimeReducer2(_ state: inout FavoritePrimeState, _ action: FavoritePrimeAction) {
    switch action {
    case .deleteFavoritePrimes(let indexSet):
        for index in indexSet {
            let prime = state.favorites[index]
            state.favorites.remove(at: index)
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(prime)))
        }
    }
}

func favoritePrimeReducer(_ state: inout [Int], _ action: FavoritePrimeAction) {
    switch action {
    case .deleteFavoritePrimes(let indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
    }
}

//extension AppState {
//    var favoritePrimeState: FavoritePrimeState {
//        get {
//            FavoritePrimeState(
//                favorites: self.favorites,
//                activityFeed: self.activityFeed
//            )
//        }
//        set {
//            self.favorites = newValue.favorites
//            self.activityFeed = newValue.activityFeed
//        }
//    }
//}

func combine<Value, Action>(
    _ first: @escaping (inout Value, Action) -> Void,
    _ second: @escaping (inout Value, Action) -> Void
) -> (inout Value, Action) -> Void {
    return { value, action in
        first(&value, action)
        second(&value, action)
    }
}

func combine<Value, Action>(
    _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    return { value, action in
        reducers.forEach { reducer in
            reducer(&value, action)
        }
    }
}

func pullback1<GlobalValue, LocalValue, Action> (
    _ reducer: @escaping (inout LocalValue, Action) -> Void,
    _ f:@escaping (GlobalValue) -> LocalValue
    ) -> (inout GlobalValue, Action) -> Void {
    return { globalValue, action in
        var localValue = f(globalValue)
        reducer(&localValue, action)
    }
}

func pullback2<GlobalValue, LocalValue, Action>(
    _ reducer: @escaping (inout LocalValue, Action) -> Void,
    get: @escaping (GlobalValue) -> LocalValue,
    set: @escaping (inout GlobalValue, LocalValue) -> Void
) -> (inout GlobalValue, Action) -> Void {
    return { globalValue, action in
        var localValue = get(globalValue)
        reducer(&localValue, action)
        set(&globalValue, localValue)
    }
}

func pullback3<GlobalValue, LocalValue, Action>(
    _ reducer: @escaping (inout LocalValue, Action) -> Void,
    _ keypath: WritableKeyPath<GlobalValue, LocalValue>
) -> (inout GlobalValue, Action) -> Void {
    return { globalValue, action in
        reducer(&globalValue[keyPath: keypath], action)
    }
}

func pullback<GlobalValue, LocalValue, GlobalAction, LocalAction>(
    _ reducer: @escaping (inout LocalValue, LocalAction) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> (inout GlobalValue, GlobalAction) -> Void {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return }
        reducer(&globalValue[keyPath: value], localAction)
    }
}

let _appReducer: (inout AppState, AppAction) -> Void  = combine(
    //counterReducer1,
    //pullback(counterReducer, { $0.count }),
    //pullback(counterReducer, get: { $0.count }, set:  { $0.count = $1 }),
    pullback(counterReducer, value:\.count, action: \.counter),
    pullback(primeModalReducer, value: \.self, action: \.primeModal),
    pullback(favoritePrimeReducer, value: \.favorites, action: \.favoritePrime)
)

let appReducer = pullback(_appReducer, value: \.self, action: \.self)

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
    case .primeModal(.saveFavoritePrimeTapped):
        state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(state.count)))
    case .primeModal(.removeFavoritePrimeTapped):
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

func loggingReducer<Value, Action>(
    _ reducer: @escaping (inout Value, Action) -> Void
) -> (inout Value, Action) -> Void {
    return { state, action in
        reducer(&state, action)
        print("Action : \(action)")
        print("Value : ")
        dump(state)
        print("-----")
    }
}

let appReducerWithActivityFeed = activityFeed(appReducer)
let appReducerWithActivityFeedAndLoggin = loggingReducer(activityFeed(appReducer))

import PlaygroundSupport
PlaygroundPage.current.liveView = UIHostingController(
    rootView: ContentView(store: .init(AppState(), reducer: appReducerWithActivityFeedAndLoggin))
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



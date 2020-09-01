import SwiftUI
import UIKit

print("0068- Exercise")

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
    var favoritePrimeState: FavoritePrimeState {
        get {
            FavoritePrimeState(
                favorites: self.favorites,
                activityFeed: self.activityFeed
            )
        }
        set {
            self.favorites = newValue.favorites
            self.activityFeed = newValue.activityFeed
        }
    }
}

/*
1. In this episode we mentioned that pullbacks along key paths satisfy a
 simple property:
 if you pullback along the identity key path you do not change the reducer,
 i.e. reducer.pullback(\.self) == reducer.

 Pullbacks also satisfy a property with respect to composition,
 which is very similar to that of map: map(f >>> g) == map(f) >>> map(g).
 Formulate what this property would be for pullbacks and key paths.
 */

func combine<Value, Action>(
    _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    return { value, action  in
        reducers.forEach {
            $0(&value, action)
        }
    }
}

func pullback<GlobalValue, LocalValue, Action>(
    _ reducer: @escaping (inout LocalValue, Action) -> Void,
    _ keypath: WritableKeyPath<GlobalValue, LocalValue>
    ) -> (inout GlobalValue, Action) -> Void {
    return { globalValue, action in
        reducer(&globalValue[keyPath: keypath], action)
    }
}


// First Reducer
func counterReducer1(_ state: inout Int, _ action: AppAction) {
    switch action {
    case .counter(.incrTapped):
        state += 1
    case .counter(.decrTapped):
        state -= 1
    default:
        break
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

// Second Reducer
func favoritePrimeReducer(_ state: inout FavoritePrimeState,
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

// pullback(f) >>> pullback(g)
let counterPulledReducer = pullback(counterReducer1,\AppState.count)
let favoritePrimePulledReducer = pullback(favoritePrimeReducer, \AppState.favoritePrimeState)

let pulledbackCombinedReducer = combine(counterPulledReducer, favoritePrimePulledReducer)

// pullback(combine(f,g))
//let combinedReducers = combine(counterReducer, favoritePrimeReducer)


func localcounterReducer(_ state: inout Int, _ action: CounterAction) {
    switch action {
    case .incrTapped:
        state += 1
    case .decrTapped:
        state -= 1
    }
}

// Identity
let globalReducer = pullback(localcounterReducer, \.self)

//[1,2,3].map(<#T##transform: (Int) throws -> T##(Int) throws -> T#>)
//func map<GlobalValue, LocalValue, Action>(
//    _ localReducer: (inout LocalValue, Action) -> (inout GlobalValue, Action) -> Void ) {
//    return { globalValue, action in
//        localReducer(&globalValue, action)
//    }
//}


/*
2. We had to create a struct, FavoritePrimeState, to hold just the data that
 the favorite primes screen needed, which was the activity feed and the
 array of favorite primes. Is it possible to instead use a typelias of a
 tuple with named fields instead of the struct?

 Does anything need to change to get the application compiling again?
 Do you like this approach over the struct?
 */



/*
 3. By the end of this episode we showed how to make reducers work on local state by using the pullback operation. However, the reducers still operate on the full AppAction enum, even if it doesn’t care about all of the cases in that enum. Try to repeat what we did in this episode for action enums, i.e. define a pullback operation that is capable of transforming reducers that work with local actions to ones that work on global actions.

 For the state pullback we needed a key path to implement this function. What kind of information do you need to implement the action pullback?
 */

func pullback<GlobalValue, LocalValue, GlobalAction, LocalAction>(
    _ reducer: @escaping (inout LocalValue, LocalAction) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
    ) -> (inout GlobalValue, GlobalAction) -> Void {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else  { return }
        reducer(&globalValue[keyPath: value], localAction)
    }
}

/*
4. By the end of this episode we showed how to make reducers work on local state
 by using the pullback operation.

 However, all of the views still take the full global store,
 Store<AppState, AppAction>, even if they only need a small part of the state.

 Explore how one might transform a Store<GlobalValue, Action> into a
 Store<LocalValue, Action>.

 Such an operation would help simplify views by allowing them to focus on only
 the data they care about.
 */

class Store<Value, Action>: ObservableObject {
    @Published var value: Value
    let reducer: (inout Value, Action) -> Void

    init(_ initialValue: Value, _ reducer: @escaping (inout Value, Action) -> Void) {
        self.value = initialValue
        self.reducer = reducer
    }

    func send(_ action: Action) {
        reducer(&value, action)
    }
}

func viewMap<GlobalValue, LocalValue, Action>(
    _ reducer: @escaping (inout LocalValue, Action) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    store: Store<GlobalValue, Action>
) -> Store<LocalValue, Action> {
    return Store.init(store.value[keyPath:value], reducer)
}

let appReducer = combine(
    pullback(counterReducer1, \AppState.count),
    pullback(primeModalReducer1, \.self),
    pullback(favoritePrimeReducer1, \AppState.favoritePrimeState)
)

let counterViewTransformer: Store<Int, AppAction> = viewMap(
    counterReducer1,
    value: \AppState.count,
    store: .init(AppState(), appReducer)
)

counterViewTransformer.value
counterViewTransformer.reducer

/*
 We’ve seen that it is possible to pullback reducers along state key paths, but could we have also gone the other direction? That is, can we define a map with key paths too? If this were possible, then we could implement the following signature:

 func map<Value, OtherValue, Action>(
   _ reducer: @escaping (inout Value, Action) -> Void,
   value: WritableKeyPath<Value, OtherValue>
 ) -> (inout OtherValue, Action) -> Void {
   fatalError("Unimplemented")
 }
 Can this function be implemented? If not, what goes wrong?
 */

func map<GlobalValue, LocalValue, Action>(
  _ reducer: @escaping (inout GlobalValue, Action) -> Void,
  value: WritableKeyPath<GlobalValue, LocalValue>
) -> (inout LocalValue, Action) -> Void {
    return { localValue, action in

        // Answer: There is no relationship b/t Value & OtherValue via keypath

        // let globalValue = localValue[keyPath: value] // Can not be done

        // No way to call `reducer(&globalValue, action)
    }
}

/*
 6.
 The previous exercise leads us to realize that there is something specific
 happening between the interplay of key paths and pullbacks when it comes to
 reducers.

 What do you think the underlying reason is that we can pullback reducers
 with key paths but we cannot map reducers with key paths?
 */

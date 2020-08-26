import UIKit

/*
 1. In this episode we remarked that there is an equivalence between functions of the form (A) -> A and functions (inout A) -> Void, which is something we covered in our episode on side effects. Prove this to yourself by implementing the following two functions which demonstrate how to transform from one type of function to the other:
 */

print("***************** Exercise 1 **********************")
func toInout<A>(_ f: @escaping (A) -> A) -> (inout A) -> Void {
    return { a in
        a = f(a)
    }
}

func foo(_ a: Int) -> Int {
    return a * 3
}

var a = 5
toInout(foo)(&a)
print(a)

func fromInout<A>(_ f: @escaping (inout A) -> Void) -> (A) -> A {
    return { a in
        var newA = a
        f(&newA)
        return newA
    }
}

func bar(_ a: inout Int) {
    a *= 3
}
let b = fromInout(bar)(4)
print(b)


/*
 2. Our appReducer is starting to get pretty big. Right now we are switching over an enum that has 5 cases, but for a much larger application you may have dozen or even hundreds of cases to consider. This clearly is not going to scale well.

 It’s possible to break up a reducer into smaller reducers by implementing the following function:
 */

print("***************** Exercise 2 **********************")

func combine<Value, Action>(
  _ first: @escaping (inout Value, Action) -> Void,
  _ second: @escaping (inout Value, Action) -> Void
) -> (inout Value, Action) -> Void {
    return { inoutState, action in
        first(&inoutState, action)
        second(&inoutState, action)
    }
}

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

func counterReducer(_ state: inout AppState, _ action: AppAction) {
    switch action {
    case .counter(.incrTapped):
        state.count += 1
    case .counter(.decrTapped):
        state.count -= 1
    default:
        break
    }
}

func primeReducer(_ state: inout AppState, _ action: AppAction) {
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

func favoritePrimeReducer(_ state: inout AppState, _ action: AppAction) {
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

var state = AppState()
let appReducer = combine(counterReducer, primeReducer)
appReducer(&state, .counter(.incrTapped))
print(state.count)
appReducer(&state, .primeModal(.saveFavoritePrimeTapped))
print(state.favorites)

/*
 3. Generalize the function in the previous exercise by implementing the following variadic version:
 */
print("***************** Exercise 3 **********************")

func combine<Value, Action>(
  _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    return { inoutValue, action in
        reducers.forEach { reducer in
            reducer(&inoutValue, action)
        }
    }
}

var anotherState = AppState()
let anotherAppReducer = combine(counterReducer, primeReducer)
anotherAppReducer(&anotherState, .counter(.incrTapped))
anotherAppReducer(&anotherState, .counter(.incrTapped))
anotherAppReducer(&anotherState, .counter(.incrTapped))

print(anotherState.count)
anotherAppReducer(&anotherState, .primeModal(.saveFavoritePrimeTapped))
print(anotherState.favorites)

/*
 4. Break up the appReducer into 3 reducers:
 one for the counter view,
 one for the prime modal, and
 one for the favorites prime view.

 Reconstitute the appReducer by using the combine function on each of the 3 reducers you create.

 What do you lose in breaking the reducer up?
 */
print("***************** Exercise 4 **********************")
let mainAppReducer = combine(counterReducer, primeReducer, favoritePrimeReducer)

/*
 5. Although it is nice that the previous exercise allowed us to break up the appReducer into 3 smaller ones,
 each of those smaller reducers still operate on the entirety of AppState,
 even if they only want a small piece of sub-state.

 Explore ways in which we can transform reducers that work on sub-state into
 reducers that work on global AppState.

 To get your feet wet, start by trying to implement the following function to
 lift a reducer on just the count field up to global state:
 */

print("***************** Exercise 5 **********************")
func counterReducer(_ count: inout Int, _ action: AppAction) {
    switch action {
    case .counter(.incrTapped):
        count += 1
    case .counter(.decrTapped):
        count -= 1
    default:
        break
    }
}

func transform(
    _ localReducer: @escaping (inout Int, AppAction) -> Void
    ) -> (inout AppState, AppAction) -> Void {
    return { appState, action in
        localReducer(&appState.count, action)
    }
}

var state5 = AppState()
let counterEvent = transform(counterReducer)
counterEvent(&state5, .counter(.incrTapped))
print(state5.count)
counterEvent(&state5, .counter(.incrTapped))
print(state5.count)
counterEvent(&state5, .counter(.incrTapped))
print(state5.count)
counterEvent(&state5, .counter(.decrTapped))
print(state5.count)


/*
 6. Can you generalize the solution to the previous exercise to work for any generic LocalValue and GlobalValue instead of being specific to Int and AppState? And can you generalize the action to a single shared Action among global and local state?

 Hint: this solution requires you to both extract a local value from a global one to send it through the reducer, and take the updated local value and set it on the global one. Swift provides an excellent way of handling this: writable key paths!
 */

print("***************** Exercise 6 **********************")

func transform<GlobalValue, LocalValue, Action>(
    _ localReducer: @escaping (inout LocalValue, Action) -> Void,
    _ localValueKeyPath: WritableKeyPath<GlobalValue, LocalValue>
    ) -> (inout GlobalValue, Action) -> Void {
    return { globalValue, action in
        localReducer(&globalValue[keyPath: localValueKeyPath], action)
    }
}

let newGlobalCounterReducer = transform(counterReducer, \AppState.count)

var state6 = AppState()
newGlobalCounterReducer(&state6, .counter(.incrTapped))
print(state6)

func primeReducer(_ favorites: inout [Int], _ action: AppAction) {
    switch action {
    case .primeModal(.saveFavoritePrimeTapped):
        favorites.append(state.count)
    case .primeModal(.removeFavoritePrimeTapped):
        favorites.removeAll { $0 == state.count }
    default:
        break
    }
}

let newGlobalPrimeReducer = transform(primeReducer,\AppState.favorites)
newGlobalPrimeReducer(&state6, .primeModal(.saveFavoritePrimeTapped))
print(state6)

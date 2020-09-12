import Foundation
import ComposableArchitecture
import Counter
import PrimeModal

let store = Store<Int,()>(0) { (state, _) in
    state += 1
}

store.send(())
store.send(())
store.value


let localStore = store.view(value: { $0 }, action: { $0 })
localStore.value

localStore.send(())
localStore.value
store.value

//store.send(())
//localStore.value
//store.value

/*
 Episode 73: Exercise 2
 In this episode we discussed how it was not appropriate to give the name map to the transformation we defined on Store due to the trickiness of reference types. Let’s explore defining map on another type with reference semantics.

 Previously on Point-Free, we defined a Lazy type as a struct around a function that returns a value:

 struct Lazy<A> {
   let run: () -> A
 }
 Upgrade this struct to a class so that we can introduce memoization. A call to run should perform the given closure and cache the return value so that any repeat calls to run can immediately return this cached value. It should behave as follows:

 import Foundation

 let slow = Lazy<Int> {
   sleep(1)
   return 1
 }
 slow.run() // Returns `1` after a second
 slow.run() // Returns `1` immediately
 From here, define map on Lazy:

 extension Lazy {
   func map<B>(_ f: @escaping (A) -> B) -> Lazy<B> {
     fatalError("Unimplemented")
   }
 }
 Given our discussion around map on the Store type, is it appropriate to call this function map?
 */

enum LazyValue<A> {
    case notAvailable(()-> A)
    case available(A)
}

class Lazy<A> {
    private var _value: LazyValue<A>

    init(_ run: @escaping (() -> A)) {
        _value = .notAvailable(run)
    }

    var value: A {
        switch _value {
        case .notAvailable(let run):
            let value = run()
            _value = .available(value)
            return value
        case .available(let value):
            return value
        }
    }
}

let slow = Lazy<Int> {
    sleep(3)
    return 1
}

print("========")
//print(slow.value)

extension Lazy {
    func map<B>(_ f: @escaping (A) -> B) -> Lazy<B> {
        return .init {
            f(self.value)
        }
    }
}


let slowString = slow.map { "New Value: \(String($0))" }

print("*********")
print(slowString.value)

//print(">>>>>>>>>>")
//print(slow.value)
//print(slowString.value)

enum Never {}

let store2 = Store<Int, Never>.init(0) { value, action in

}

//store2.send(Never())


let counterViewAction = Either<CounterAction, PrimeModalAction>.right(.saveFavoritePrimeTapped)


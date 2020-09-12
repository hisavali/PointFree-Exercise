//
//  Counter.swift
//  Counter
//
//  Created by HITESH SAVALIYA on 04/09/2020.
//  Copyright © 2020 Hitesh Savaliya. All rights reserved.
//

import ComposableArchitecture
import Foundation
import PrimeModal
import SwiftUI

public let wolframAlphaApiKey = "6H69Q3-828TKQJ4EP"

public typealias CounterViewState = (count: Int, favorites: [Int])

public enum CounterAction {
    case incrTapped
    case decrTapped
}

//public enum CounterViewAction {
//    case counter(CounterAction)
//    case primeModal(PrimeModalAction)
//}

public typealias CounterViewAction = Either<CounterAction, PrimeModalAction>

// extension CounterViewAction {
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
//}

public func counterReducer(_ state: inout Int, _ action: CounterAction) {
    switch action {
    case .incrTapped:
        state += 1
    case .decrTapped:
        state -= 1
    }
}

public let counterViewReducer: (inout CounterViewState, CounterViewAction) -> Void = combine(
    pullback(counterReducer, value:\CounterViewState.count, action: \.leftValue),
    pullback(primeModalReducer, value: \.self, action: \.rightValue)
)

func oridinal(_ n: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    return formatter.string(for: n) ?? ""
}

public struct CounterView: View {
    @ObservedObject var store: Store<CounterViewState, CounterViewAction>
    @State var isModal: Bool = false
    @State var alertNthPrime: Int?
    @State var showAlert: Bool = false
    @State var nthPrimeButtonDisabled: Bool = false

    public init(store: Store<CounterViewState, CounterViewAction>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            HStack {
                Button("-") {
                    self.store.send(.left(.decrTapped))
                }
                Text("\(self.store.value.count)")
                Button("+") {
                    self.store.send(.left(.incrTapped))
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
            IsPrimeModalView(
                store: self.store
                    .view(
                        value: { $0 },
                        action: { .right($0) } //.primeModal($0)
            )
            )
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


//// Mark: - Reducers
//func counterReducer1(_ state: inout AppState, _ action: AppAction) {
//    switch action {
//    case .counter(.incrTapped):
//        state.count += 1
//    case .counter(.decrTapped):
//        state.count -= 1
//    default:
//        break
//    }
//}
//
//func counterReducer2(_ state: inout Int, _ action: AppAction) {
//    switch action {
//    case .counter(.incrTapped):
//        state += 1
//    case .counter(.decrTapped):
//        state -= 1
//    default:
//        break
//    }
//}


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


/*
 In our first episode on algebraic data types, we introduced the Either type, which is the most generic, non-trivial enum one could make:

 enum Either<A, B> {
   case left(A)
   case right(B)
 }
 In this episode we create a wrapper enum called CounterViewAction
 to limit the counter view’s ability to send any app action.

 Instead of introducing an ad hoc enum, refactor things to utilize the Either type.

 How does this compare to utilizing structs and tuples for intermediate state?
 */

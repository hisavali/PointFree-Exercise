//
//  PrimeModal.swift
//  PrimeModal
//
//  Created by HITESH SAVALIYA on 05/09/2020.
//  Copyright © 2020 Hitesh Savaliya. All rights reserved.
//

import ComposableArchitecture
import Foundation
import SwiftUI

public typealias PrimeModalState = (count: Int, favorites: [Int])

//public struct PrimeModalState {
//    public var count: Int
//    public var favorites: [Int]
//
//    public init(count: Int,favorites: [Int]) {
//        self.count = count
//        self.favorites = favorites
//    }
//}

public enum PrimeModalAction {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}

public func primeModalReducer(_ state: inout PrimeModalState, _ action: PrimeModalAction) {
    switch action {
    case .saveFavoritePrimeTapped:
        state.favorites.append(state.count)
    case .removeFavoritePrimeTapped:
        state.favorites.removeAll { $0 == state.count }
    }
}


public struct IsPrimeModalView: View {
    @ObservedObject var store: Store<PrimeModalState, PrimeModalAction>

    public init(store: Store<PrimeModalState, PrimeModalAction>) {
        self.store = store
    }

    private func isPrime (_ p: Int) -> Bool {
      if p <= 1 { return false }
      if p <= 3 { return true }
      for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
      }
      return true
    }

    public var body: some View {
        VStack {
            if isPrime(self.store.value.count) {
                Text("Number \(self.store.value.count) is prime")
                if self.store.value.favorites.contains(self.store.value.count) {
                    Button("Remove from faviroute") {
                        self.store.send(.removeFavoritePrimeTapped)
                    }
                } else {
                    Button("Save to faviroute") {
                        self.store.send(.saveFavoritePrimeTapped)
                    }
                }
            } else {
                Text("Number \(self.store.value.count) is NOT prime")
            }
        }
    }

}

//func primeModalReducer1(_ state: inout AppState, _ action: AppAction) {
//    switch action {
//    case .primeModal(.saveFavoritePrimeTapped):
//        state.favorites.append(state.count)
//        state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(state.count)))
//    case .primeModal(.removeFavoritePrimeTapped):
//        state.favorites.removeAll { $0 == state.count }
//        state.activityFeed.append(.init(timestamp: Date(), type: .addedFaviourite(state.count)))
//    default:
//        break
//    }
//}
//
//func primeModalReducer2(_ state: inout AppState, _ action: PrimeModalAction) {
//    switch action {
//    case .saveFavoritePrimeTapped:
//        state.favorites.append(state.count)
//        state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(state.count)))
//    case .removeFavoritePrimeTapped:
//        state.favorites.removeAll { $0 == state.count }
//        state.activityFeed.append(.init(timestamp: Date(), type: .addedFaviourite(state.count)))
//    }
//}

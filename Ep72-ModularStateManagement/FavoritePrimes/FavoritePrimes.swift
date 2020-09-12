//
//  FavoritePrimes.swift
//  FavoritePrimes
//
//  Created by HITESH SAVALIYA on 04/09/2020.
//  Copyright © 2020 Hitesh Savaliya. All rights reserved.
//

import ComposableArchitecture
import SwiftUI

public enum FavoritePrimeAction {
    case deleteFavoritePrimes(IndexSet)
}

public func favoritePrimeReducer(_ state: inout [Int], _ action: FavoritePrimeAction) {
    switch action {
    case .deleteFavoritePrimes(let indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
    }
}

public struct FaviouritePrimeView: View {
    @ObservedObject var store: Store<[Int], FavoritePrimeAction>
    public init(store: Store<[Int], FavoritePrimeAction>) {
        self.store = store
    }

    public var body: some View {
        List {
            ForEach(self.store.value, id: \.self) { p in
                Text("\(p)")
            }.onDelete {
                self.store.send(.deleteFavoritePrimes($0))
            }
        }.navigationBarTitle(Text("Favorite primes"))
    }
}

//func favoritePrimeReducer1(_ state: inout AppState, _ action: AppAction) {
//    switch action {
//    case let .favoritePrime(.deleteFavoritePrimes(indexSet)):
//        for index in indexSet {
//            let prime = state.favorites[index]
//            state.favorites.remove(at: index)
//            state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(prime)))
//        }
//    default:
//        break
//    }
//}

//func favoritePrimeReducer1(_ state: inout FavoritePrimeState,
//                          _ action: AppAction) {
//    switch action {
//    case let .favoritePrime(.deleteFavoritePrimes(indexSet)):
//        for index in indexSet {
//            let prime = state.favorites[index]
//            state.favorites.remove(at: index)
//            state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(prime)))
//        }
//    default:
//        break
//    }
//}
//
//func favoritePrimeReducer2(_ state: inout FavoritePrimeState, _ action: FavoritePrimeAction) {
//    switch action {
//    case .deleteFavoritePrimes(let indexSet):
//        for index in indexSet {
//            let prime = state.favorites[index]
//            state.favorites.remove(at: index)
//            state.activityFeed.append(.init(timestamp: Date(), type: .removedFaviourite(prime)))
//        }
//    }
//}
//

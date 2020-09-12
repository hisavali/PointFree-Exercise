import SwiftUI
import ComposableArchitecture
import FavoritePrimes
import PrimeModal
import PlaygroundSupport
import Counter

let favoriteView = FaviouritePrimeView(store: .init(
    [2,3],
    reducer: favoritePrimeReducer))

let primeModalView = IsPrimeModalView(store: .init(
    PrimeModalState(count: 0, favorites: []),
    reducer: primeModalReducer))

let counterView = CounterView(store: Store<CounterViewState, CounterViewAction>(
    (count: 0, favorites:[]),
    reducer: counterViewReducer)
)

PlaygroundPage.current.liveView = UIHostingController(rootView: counterView)

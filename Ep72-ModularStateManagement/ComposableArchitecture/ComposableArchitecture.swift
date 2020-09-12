//
//  ComposableArchitecture.swift
//  ComposableArchitecture
//
//  Created by HITESH SAVALIYA on 04/09/2020.
//  Copyright © 2020 Hitesh Savaliya. All rights reserved.
//

import Combine
import SwiftUI

public final class Store<Value, Action>: ObservableObject {
    @Published public private(set) var value: Value
    let reducer: (inout Value, Action) -> Void
    var cancellable: Cancellable?

    public init(_ initialValue: Value, reducer: @escaping (inout Value, Action) -> Void) {
        self.value = initialValue
        self.reducer = reducer
    }

    public func send(_ action: Action) {
        self.reducer(&self.value, action)
    }
}

func combine<Value, Action>(
    _ first: @escaping (inout Value, Action) -> Void,
    _ second: @escaping (inout Value, Action) -> Void
) -> (inout Value, Action) -> Void {
    return { value, action in
        first(&value, action)
        second(&value, action)
    }
}

public func combine<Value, Action>(
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

public func pullback<GlobalValue, LocalValue, GlobalAction, LocalAction>(
    _ reducer: @escaping (inout LocalValue, LocalAction) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> (inout GlobalValue, GlobalAction) -> Void {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return }
        reducer(&globalValue[keyPath: value], localAction)
    }
}


public func loggingReducer<Value, Action>(
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


/* Exercise 72 */

/*
 1. Explore the possibilities of transforming a store that works on global
 values to one that works with local values.
 That is, a function with the following shape of signature:
 */
extension Store {
    public func view1<LocalValue>(
        value toLocalValue: @escaping (Value) -> LocalValue
    ) -> Store<LocalValue, Action> {
        let initialLocalValue = toLocalValue(self.value)
        let localStore: Store<LocalValue, Action> = .init(initialLocalValue) { (localValue, action) in
            self.send(action)
            localValue = toLocalValue(self.value)
        }

        localStore.cancellable = self.$value.sink { [weak localStore] globalValue in
            localStore?.value = toLocalValue(globalValue)
        }
        return localStore
    }

    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        let initialLocalValue = toLocalValue(self.value)
        let localStore: Store<LocalValue, LocalAction> = .init(initialLocalValue) { (localValue, localAction) in
            self.send(toGlobalAction(localAction))
            localValue = toLocalValue(self.value)
        }

        localStore.cancellable = self.$value.sink { [weak localStore] globalValue in
            localStore?.value = toLocalValue(globalValue)
        }
        return localStore
    }
}

extension Store {
    public func view<LocalAction>(
        _ f: @escaping (LocalAction) -> Action
    ) -> Store<Value, LocalAction> {
        let store = Store<Value, LocalAction>.init(self.value) { value, localAction in
            self.send(f(localAction))
            value = self.value
        }
        return store
    }
}

public enum Either<A,B> {
    case left(A)
    case right(B)
}

extension Either {
    public var leftValue: A? {
        get {
            guard case let .left(value) = self else { return nil }
            return value
        }

        set {
            guard case .left = self, let newValue = newValue else { return }
            self = .left(newValue)
        }
    }

    public var rightValue: B? {
        get {
            guard case let .right(value) = self else { return nil }
            return value
        }

        set {
            guard case .right = self, let newValue = newValue else { return }
            self = .right(newValue)
        }
    }
}


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

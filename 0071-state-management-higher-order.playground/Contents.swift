import UIKit

var str = "Episode 71 - State management - Higher order"
print(str)

/*
 1. Create a higher-order reducer with the following signature:

 func filterActions<Value, Action>(_ predicate: @escaping (Action) -> Bool)
   -> (@escaping (inout Value, Action) -> Void)
   -> (inout Value, Action) -> Void {
   fatalError("Unimplemented")
 }

 This allows you to transform any reducer into one that only listens to certain actions.
 */

print("********** Exercise 1 **********")

struct AppState {
    var userName: String = ""
    var password: String = ""
    var loggedIn: Bool = false
    var forgotPassword: Bool = false
}

enum AppAction: Equatable {
    case enterUserName(String)
    case login
    case forgotpassoword
    case logout
}


func filterActions<Value, Action>(
    _ predicate: @escaping (Action) -> Bool
) -> (@escaping (inout Value, Action) -> Void)
    -> (inout Value, Action) -> Void {
        return { reducer in
            return { state, action in
                if predicate(action) {
                    reducer(&state, action)
                }
            }
        }
}

func appReducer(_ state: inout AppState, _ action: AppAction) {
    switch action {
    case .login:
        state.loggedIn = true
        state.forgotPassword = false
    case .forgotpassoword:
        state.forgotPassword = true
    case .logout:
        state.loggedIn = false
    case .enterUserName(let username):
        state.userName = username
    }
}

//filterActions { $0 == AppAction.forgotpassoword }
let forgotPassword: (@escaping (inout AppState, AppAction) -> Void) -> (inout AppState, AppAction) -> Void = filterActions { $0 == AppAction.forgotpassoword }

var appState = AppState()
forgotPassword(appReducer)(&appState, .login)
appState.loggedIn
appState.forgotPassword

forgotPassword(appReducer)(&appState, .forgotpassoword)
appState.loggedIn
appState.forgotPassword

//
filterActions({ $0 == AppAction.login })(appReducer)(&appState, .forgotpassoword)
appState.loggedIn
appState.forgotPassword


filterActions({ $0 == AppAction.login })(appReducer)(&appState, .login)
appState.loggedIn
appState.forgotPassword

filterActions({ $0 == AppAction.logout })(appReducer)(&appState, .logout)
appState.loggedIn
appState.forgotPassword


/*
 2. Create a higher-order reducer that adds the functionality of undo to any reducer. You can start by providing new types to augment the existing state and actions of a reducer:
 */
print("********** Exercise 2 **********")

struct UndoState<Value> {
    var value: Value
    var history: [Value]
    var redo: [Value]

    var canUndo: Bool { !history.isEmpty }
    let capacity: Int = 3
}

enum UndoAction<Action> {
    case action(Action)
    case undo
    case redo

    var action: Action? {
        guard case let .action(actionValue) = self else { return nil }
        return actionValue
    }
}

func undo1<Value, Action>(
    _ reducer: @escaping (inout Value, Action) -> Void
    ) -> (inout UndoState<Value>, UndoAction<Action>) -> Void {
    return { undoState, undoAction in
        switch undoAction {
        case .action(let action):
            reducer(&undoState.value, action)
            undoState.history.append(undoState.value)
        case .undo:
            undoState.value = undoState.history.removeLast()
        default:
            break
        }
    }
}

let initialAppState: AppState = .init(
    userName: "",
    password: "",
    loggedIn: false,
    forgotPassword: false)

var undoState = UndoState<AppState>(
    value: initialAppState,
    history: [],
    redo: []
)

undo1(appReducer)(&undoState, .action(.login))
undoState.value.loggedIn
undoState.value.forgotPassword
undoState.history

undo1(appReducer)(&undoState, .action(.logout))
undo1(appReducer)(&undoState, .action(.forgotpassoword))
undoState.value.loggedIn
undoState.value.forgotPassword
undoState.history

undo1(appReducer)(&undoState, .undo)
undoState.history

undo1(appReducer)(&undoState, .undo)
undoState.history
undo1(appReducer)(&undoState, .undo)
undoState.history

/*
 3. Enhance the undo higher-order reducer so that it limits the size of the undo history.
 */
print("********** Exercise 3 **********")

func undo2<Value, Action>(
    _ reducer: @escaping (inout Value, Action) -> Void
    ) -> (inout UndoState<Value>, UndoAction<Action>) -> Void {
    return { undoState, undoAction in
        switch undoAction {
        case .action(let action):
            reducer(&undoState.value, action)
            undoState.history.append(undoState.value)
            if undoState.history.count > undoState.capacity {
                undoState.history.removeFirst()
            }
        case .undo:
            undoState.value = undoState.history.removeLast()
        case .redo:
            break
        }
    }
}

undo2(appReducer)(&undoState, .action(.login))
undoState.history
undo2(appReducer)(&undoState, .action(.logout))
undoState.history
undo2(appReducer)(&undoState, .action(.forgotpassoword))
undoState.history

undo2(appReducer)(&undoState, .action(.enterUserName("Hello")))
undoState.history


/*
 4. Enhance the undo higher-order reducer to also allow redoing.
 */
print("********** Exercise 4 **********")

func undo<Value, Action>(
    _ reducer: @escaping (inout Value, Action) -> Void
    ) -> (inout UndoState<Value>, UndoAction<Action>) -> Void {
    return { undoState, undoAction in
        switch undoAction {
        case .action(let action):
            reducer(&undoState.value, action)
            undoState.history.append(undoState.value)
            if undoState.history.count > undoState.capacity {
                undoState.history.removeFirst()
            }
        case .undo:
            if !undoState.history.isEmpty {
                undoState.value = undoState.history.removeLast()
                undoState.redo.append(undoState.value)
            }
        case .redo:
            if !undoState.redo.isEmpty {
                let value = undoState.redo.removeLast()
                undoState.history.append(value)
            }
        }
    }
}

var undoState4 = UndoState<AppState>(
    value: initialAppState,
    history: [],
    redo: []
)

undo(appReducer)(&undoState4, .action(AppAction.enterUserName("Hello 1")))
undo(appReducer)(&undoState4, .action(AppAction.enterUserName("Hello 12")))
undo(appReducer)(&undoState4, .action(AppAction.enterUserName("Hello 123" )))
undoState4.history

undo(appReducer)(&undoState4, .undo)
undo(appReducer)(&undoState4, .undo)
undoState4.history
undoState4.redo
undo(appReducer)(&undoState4, .redo)
undoState4.history
undoState4.redo


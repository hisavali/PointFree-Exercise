import UIKit
import SwiftUI

struct Tagged<Tag, RawValue> {
    var rawValue: RawValue
}

struct User {
    typealias ID = Tagged<User, Int>
    typealias Email = Tagged<User, String>
    let id: ID
    let email: Email
}

let user = User.init(id: User.ID.init(rawValue: 1),
                     email: User.Email.init(rawValue: "who@example.com"))

func foo(_ id: User.ID) {
    print("Something with id")
}

foo(user.id)
//foo(1)

extension Tagged: ExpressibleByIntegerLiteral where RawValue: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = RawValue.IntegerLiteralType
    init(integerLiteral value: RawValue.IntegerLiteralType) {
        self.rawValue = RawValue.init(integerLiteral: value)
    }
}

let user2 = User.init(id: 2,
                      email: User.Email.init(rawValue: "who2@example.com"))
user.id.rawValue

/*
 1. Conditionally conform Tagged to ExpressibleByStringLiteral in order to
 restore the ergonomics of initializing our User’s email property.
 Note that ExpressibleByStringLiteral requires a couple other prerequisite conformances.
 */

print("****************** Exercise: 1 ******************")
extension Tagged: ExpressibleByUnicodeScalarLiteral where RawValue: ExpressibleByUnicodeScalarLiteral {
    typealias UnicodeScalarLiteralType = RawValue.UnicodeScalarLiteralType
    init(unicodeScalarLiteral value: RawValue.UnicodeScalarLiteralType) {
        self.rawValue = RawValue.init(unicodeScalarLiteral: value)
    }
}

extension Tagged: ExpressibleByExtendedGraphemeClusterLiteral where RawValue: ExpressibleByExtendedGraphemeClusterLiteral {
    typealias ExtendedGraphemeClusterLiteralType = RawValue.ExtendedGraphemeClusterLiteralType
    init(extendedGraphemeClusterLiteral value: RawValue.ExtendedGraphemeClusterLiteralType) {
        self.rawValue = RawValue.init(extendedGraphemeClusterLiteral: value)
    }
}

extension Tagged: ExpressibleByStringLiteral where RawValue: ExpressibleByStringLiteral {
    typealias StringLiteralType = RawValue.StringLiteralType

    init(stringLiteral value: RawValue.StringLiteralType) {
        self.rawValue = RawValue.init(stringLiteral: value)
    }
}

let user3 = User.init(id: 3, email: "Who3@example.com")

func sendEmail(email: User.Email) {
    print("SEND email to \(email)")
}

sendEmail(email: user2.email)
sendEmail(email: user3.email)
sendEmail(email: "spam") // This should NOT compile!


/*
 2. Conditionally conform Tagged to Comparable and sort users by their id in descending order.
 */
print("****************** Exercise: 2 ******************")
extension Tagged: Equatable where RawValue: Equatable {
  static func == (lhs: Tagged, rhs: Tagged) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}

extension Tagged: Comparable where RawValue: Comparable {
    static func < (lhs: Tagged, rhs: Tagged) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

var users: [User] = [.init(id: 1, email: "who1@example.com"),
                     .init(id: 2, email: "who2@example.com"),
                     .init(id: 3, email: "who3@example.com")]

let sortedUsers = users.sorted(by: { !($0.id < $1.id) })
dump(sortedUsers.map { $0.id })

/*
 3.
 Let’s explore what happens when you have multiple fields in a struct that you want to strengthen at the type level. Add an age property to User that is tagged to wrap an Int value. Ensure that it doesn’t collide with User.Id. (Consider how we tagged Email.)
 */

print("****************** Exercise: 3 ******************")
struct User2 {
    enum UserId {}
    typealias ID = Tagged<UserId, Int> // Tagged<User, Int>
    typealias Age = Tagged<User2, Int>
    typealias Email = Tagged<User2, String>
    let id: ID
    let email: Email
    let age: Age
}

struct Describing<A> {
    let print: (A) -> String
}

extension Describing where A == User2 {
    static let pretty = Describing.init {
        return  """
        {
            Id: \($0.id.rawValue),
            email: \($0.email.rawValue),
            age: \($0.age.rawValue)
        }
        """
    }
}

func increaseAge(_ age: User2.Age) {
    print(Describing.pretty.print(User2.init(id: 1, email: "sample@example.com", age: age)))
}

let user22 = User2.init(id: 100,
                        email: "some",
                        age: 25)

increaseAge(user22.age)
//increaseAge(user22.id) // Can't compile as
//increaseAge(42)
//sendEmail(email: user22.email)


typealias DeviceActionType = Tagged<DeviceAction, String>
enum DeviceAction: DeviceActionType  {
    case location = "requestState"
    case startLiveTracking = "locationLiveTrackingStart"
    case stopLiveTracking = "locationLiveTrackingStop"
    case findMyDevice = "findMy"
}

let da = DeviceAction.init(rawValue: "findMy")

func fire(_ action: DeviceActionType) {
    print("\(action.rawValue)")
}

fire("finMy")
fire((da?.rawValue)!)
//fire(user2.email) // <== This prevents String tagged to other type being passed

/*
4. Conditionally conform Tagged to Numeric and alias a tagged type to Int representing Cents. Explore the ergonomics of using mathematical operators and literals to manipulate these values.
 */

print("****************** Exercise: 4 ******************")
extension Tagged: AdditiveArithmetic where RawValue: AdditiveArithmetic {
    static func - (lhs: Tagged<Tag, RawValue>, rhs: Tagged<Tag, RawValue>) -> Tagged<Tag, RawValue> {
        return Tagged.init(rawValue: lhs.rawValue - rhs.rawValue)
    }

    static func + (lhs: Tagged<Tag, RawValue>, rhs: Tagged<Tag, RawValue>) -> Tagged<Tag, RawValue> {
        return Tagged.init(rawValue: lhs.rawValue + rhs.rawValue)
    }

    static var zero: Tagged<Tag, RawValue> {
        return Tagged.init(rawValue: .zero)
    }


}

extension Tagged: Numeric where RawValue: Numeric {
    init?<T>(exactly source: T) where T : BinaryInteger {
        guard let rawValue = RawValue(exactly: source) else { return nil }
        self.init(rawValue: rawValue)
    }

    var magnitude: RawValue.Magnitude {
      return self.rawValue.magnitude
    }

    static func * (lhs: Tagged, rhs: Tagged) -> Tagged {
      return self.init(rawValue: lhs.rawValue * rhs.rawValue)
    }

    static func *= (lhs: inout Tagged, rhs: Tagged) {
      lhs.rawValue *= rhs.rawValue
    }
}

struct Currency {
    let cents: Tagged<Currency, Int>
}

let c1 = Currency(cents: 10)
let c2 = Currency(cents: 100)

c1.cents + c2.cents
c1.cents * c2.cents


/*
5. Create a tagged type, Light<A> = Tagged<A, Color>, where A can represent
 whether the light is on or off.
 Write turnOn and turnOff functions to toggle this state.
 */
print("****************** Exercise: 5 ******************")
typealias Light<A> = Tagged<A, Color>

enum LightState {
    case on
    case off
}

func turnOn(_ light: inout Light<LightState>) {
    light.rawValue = .white
}

func turnOff(_ light: inout Light<LightState>) {
    light.rawValue = .black
}

var on = Light<LightState>(rawValue: .white)

turnOff(&on)
turnOn(&on)

// ************************************

func turnOn(_ light: inout Light<Bool>) {
    light.rawValue = .black
}

func turnOff(_ light: inout Light<Bool>) {
    light.rawValue = .white
}

var onFlag = Light<Bool>(rawValue: .white)

turnOff(&onFlag)
turnOn(&onFlag)

//struct LightState2 {
//    typealias ON = Tagged<LightState2, Bool>
//    typealias OFF = Tagged<LightState2, Bool>
//}
//
//struct LightState3<Value> {
//    typealias ON = Tagged<LightState3, Value>
//    typealias OFF = Tagged<LightState3, Value>
//}
//
//var on2 = Light<LightState2.ON>(rawValue: .white)
//var off2 = Light<LightState2.OFF>(rawValue: .black)
//
//func changeColor(_ light: inout Light<LightState2.ON>, color: Color) {
//    light.rawValue = color
//}
//
//changeColor(&off2, color: .pink)


/*
 6. Write a function, changeColor, that changes a Light’s color when the light is on. This function should produce a compiler error when passed a Light that is off.
 */
print("****************** Exercise: 6 ******************")

protocol LightState3 {}
enum ON: LightState3 {}
enum OFF: LightState3 {}

typealias Light3<A: LightState3> = Tagged<A, Color>

func turnOn<A>(light: Light3<A>) -> Light3<ON> {
    return Light3<ON>(rawValue: .white)
}

func changeColor(_ light: inout Light3<ON>, color: Color) {
    light.rawValue = color
}

var off = Light3<OFF>(rawValue: .black)
// changeColor(&off, color: .pink)

/*
 7. Create two tagged types with Double raw values to represent Celsius and Fahrenheit temperatures.
 Write functions celsiusToFahrenheit and fahrenheitToCelsius that convert between these units.
 */
print("****************** Exercise: 7 ******************")
enum Celsius {}
enum Fahrenheit {}
typealias CelsiusType = Tagged<Celsius, Double>
typealias FahrenheitType = Tagged<Fahrenheit, Double>

func celsiusToFahrenheit(_ celsius:CelsiusType) -> FahrenheitType {
    return FahrenheitType(rawValue: celsius.rawValue * 1.8 + 32)
}

func fahrenheitToCelsius(_ fahrenheit:FahrenheitType) -> CelsiusType {
    return CelsiusType(rawValue: (fahrenheit.rawValue - 32) / 1.8 )
}

let c = CelsiusType(rawValue: 10.0)
print(celsiusToFahrenheit(c).rawValue)

let d = FahrenheitType(rawValue: 50.0)
print(fahrenheitToCelsius(d).rawValue)

/*
 8. Create Unvalidated and Validated tagged types so that you can create a
 function that takes an Unvalidated<User> and
 returns an Optional<Validated<User>> given a valid user.
 A valid user may be one with a non-empty name and an email that contains an @.
 */
print("****************** Exercise: 8 ******************")
extension User {
    func isValid() -> Bool {
        self.email.rawValue.contains("@")
    }
}

typealias Unvalidated<Void, B> = Tagged<Void, B>
typealias Validated<Void, B> = Tagged<Void, B>

func validUser(_ user: Unvalidated<Void, User>) -> Optional<Validated<Void, User>> {
    guard user.rawValue.isValid() else { return nil }
    return Validated<Void,User>(rawValue: user.rawValue)
}

let userWithWrongEmail = User(id: 1, email: "dsa")
validUser(Unvalidated.init(rawValue: userWithWrongEmail))

let userWithValidEmail = User(id: 1, email: "dsa@g.com")
validUser(Unvalidated.init(rawValue: userWithValidEmail))?.rawValue


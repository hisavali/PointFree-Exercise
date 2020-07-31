import UIKit

struct Tagged<Tag, RawValue> {
    let rawValue: RawValue
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

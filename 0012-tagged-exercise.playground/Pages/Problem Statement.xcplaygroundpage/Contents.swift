//: [Previous](@previous)

import Foundation

struct User {
    let id: Int
    let name: String
    let devices: [Device]
}

struct Device {
    let id: Int
    let name: String
}

let user = User.init(id: 1, name: "Crvsh", devices:[])
let devices = [Device(id: 2, name: "Tracker"),
               Device(id: 3, name: "Bike")]

func sendCommand(_ id: Int) {
    print ("Send command to: \(id)")
}

sendCommand(devices.first!.id)
// sendCommand(user.id)


let f: (String) -> Int? = {
    return Int($0)
}

Optional("8").map(f)













//////////
struct Tagged<Tag, RawValue> {
    var rawValue: RawValue
}

struct User2 {
    let id: Int
    let name: String
    let devices: [Device]
}

struct Device2 {
    let id: Tagged<Device2, Int>
    let name: String
}

let user2 = User2.init(id: 1, name: "Crvsh", devices:[])
let devices2 = [Device2(id: .init(rawValue: 2), name: "Tracker"),
               Device2(id: .init(rawValue: 3), name: "Bike")]

func sendAnotherCommand(_ id: Tagged<Device2, Int>) {
    print ("Send command to: \(id.rawValue)")
}

sendAnotherCommand(devices2.first!.id)
//sendAnotherCommand(user2.id)


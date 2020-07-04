//
//  YZJSON.swift
//  YZJSON
//
//  Created by Q YiZhong on 2020/7/4.
//  Copyright © 2020 YiZhong Qi. All rights reserved.
//

import Foundation

enum JSONType: Int {
    case null
    case `false`
    case `true`
    case number
    case string
    case array
    case object
}

enum ReturnType: Int {
    case ok
    case expectValue
    case invalidValue
    case rootNotSingular
}

struct JSONValue {
    var type: JSONType
}

struct JSONContext {
    var JSON: [Character]
    var index: Int = 0
    
    var current: Character? {
        guard index < JSON.count else {
            return nil
        }
        return JSON[index]
    }
    
    mutating func next() {
        index += 1
    }
    
    func canMove(_ count: Int) -> Bool {
        return index + count <= JSON.count
    }
    
    mutating func move(_ count: Int) {
        index += count
    }
}

func parse(JSON: String, value: inout JSONValue) -> ReturnType {
    var context = JSONContext(JSON: Array(JSON))
    value.type = .null
    parseWhitespace(context: &context)
    var ret = parseValue(context: &context, value: &value)
    if ret == .ok {
        parseWhitespace(context: &context)
        if let _ = context.current {
            ret = .rootNotSingular
        }
    }
    return ret
}

func parseWhitespace(context: inout JSONContext) {
    while let c = context.current {
        if c == "\t" || c == "\n" || c == "r" || c == " " {
            context.next()
        } else {
            break
        }
    }
}

func parseValue(context: inout JSONContext, value: inout JSONValue) -> ReturnType {
    guard let c = context.current else { return .expectValue }
    switch c {
    case "n":
        return parseNull(context: &context, value: &value)
    case "f":
        return parseFalse(context: &context, value: &value)
    case "t":
        return parseTrue(context: &context, value: &value)
    default:
        return .invalidValue
    }
}

func parseNull(context: inout JSONContext, value: inout JSONValue) -> ReturnType {
    expect(context: &context, char: "n")
    let index = context.index
    guard context.canMove(3) else {
        return .invalidValue
    }
    if context.JSON[index] != "u" || context.JSON[index + 1] != "l" || context.JSON[index + 2] != "l" {
        return .invalidValue
    }
    context.move(3)
    value.type = .null
    return .ok
}

func parseFalse(context: inout JSONContext, value: inout JSONValue) -> ReturnType {
    expect(context: &context, char: "f")
    let index = context.index
    guard context.canMove(4) else {
        return .expectValue
    }
    if context.JSON[index] != "a" || context.JSON[index + 1] != "l" || context.JSON[index + 2] != "s" || context.JSON[index + 3] != "e" {
        return .invalidValue
    }
    context.move(4)
    value.type = .false
    return .ok
}

func parseTrue(context: inout JSONContext, value: inout JSONValue) -> ReturnType {
    expect(context: &context, char: "t")
    let index = context.index
    guard context.canMove(3) else {
        return .expectValue
    }
    if context.JSON[index] != "r" || context.JSON[index + 1] != "u" || context.JSON[index + 2] != "e" {
        return .invalidValue
    }
    context.move(3)
    value.type = .true
    return .ok
}

func expect(context: inout JSONContext, char: Character) {
    guard let c = context.current else {
        assert(false, "expect a character but input nil.")
    }
    assert(c == char, "expect value: \(c)")
    context.next()
}

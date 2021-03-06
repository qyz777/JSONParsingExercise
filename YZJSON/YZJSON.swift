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
    case numberTooBig
    case missQuotationMark
    case invalidStringEscape
    case invalidUnicodeHex
    case invalidUnicodeSurrogate
    case parseMissCommaOrSquareBracket
    case parseMissKey
    case parseMissColon
    case parseMissCommaOrCuryBracket
}

struct JSONValue {
    
    /// 当type为number类型时n为JSON数字的数值
    var n: Double = 0
    var isInteger = false
    
    /// 当type为string类型时s为JSON的字符串
    var s: String = ""
    
    /// 当type为array类型时array为JSON数组
    var array: [JSONValue] = []
    
    /// 当type为Object类型时member为JSON的kv键值对
    var members: [JSONMember] = []
    
    var type: JSONType
}

/// 在Object中使用
struct JSONMember {
    var key: String
    var value: JSONValue
}

struct JSONContext {
    var JSON: [Character]
    var index: Int = 0
    
    var queue: [Character] = []
    
    var arrayQueue: [JSONValue] = []
    
    var objectQueue: [JSONMember] = []
    
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
        return parseLiteral(context: &context, value: &value, literal: "null", type: .null)
    case "f":
        return parseLiteral(context: &context, value: &value, literal: "false", type: .false)
    case "t":
        return parseLiteral(context: &context, value: &value, literal: "true", type: .true)
    case "\"":
        return parseString(context: &context, value: &value)
    case "[":
        return parseArray(context: &context, value: &value)
    case "{":
        return parseObject(context: &context, value: &value)
    default:
        return parseNumber(context: &context, value: &value)
    }
}

func parseString(context: inout JSONContext, value: inout JSONValue) -> ReturnType {
    let r = parseString(context: &context)
    guard r == .ok else { return r }
    value.s = String(context.queue)
    value.type = .string
    context.queue.removeAll()
    return r
}

func parseString(context: inout JSONContext) -> ReturnType {
    expect(context: &context, char: "\"")
    while true {
        guard let c = context.current else { return .missQuotationMark }
        switch c {
        case "\"":
            context.next()
            return .ok
        case "\\":
            context.next()
            guard let nc = context.current else { return .invalidStringEscape }
            switch nc {
            case "\"":
                context.queue.append("\"")
                context.next()
            case "\\":
                context.queue.append("\\")
                context.next()
            case "/":
                context.queue.append("/")
                context.next()
            case "n":
                context.queue.append("\n")
                context.next()
            case "r":
                context.queue.append("\r")
                context.next()
            case "t":
                context.queue.append("\t")
                context.next()
            case "u":
                context.next()
                guard var u = parseHex4(context: &context) else { return .invalidValue }
                if 0xD000 <= u && u <= 0xDBFF {
                    //是高代理项
                    if let c = context.current, c != "\\" {
                        return .invalidUnicodeSurrogate
                    }
                    context.next()
                    if let c = context.current, c != "u" {
                        return .invalidUnicodeSurrogate
                    }
                    context.next()
                    //解析低代理项
                    guard let u2 = parseHex4(context: &context) else { return .invalidUnicodeHex }
                    if u2 < 0xDC00 || u2 > 0xDFFF {
                        return .invalidUnicodeSurrogate
                    }
                    //计算出码点
                    u = (((u - 0xD800) << 10) | (u2 - 0xDC00)) + 0x10000
                }
                context.queue.append(Character(Unicode.Scalar(u)!))
            default:
                return .invalidStringEscape
            }
        default:
            if c.asciiValue ?? 0 < 20 {
                return .invalidStringEscape
            }
            context.queue.append(c)
            context.next()
        }
    }
}

func parseHex4(context: inout JSONContext) -> Int? {
    var n = 0
    for i in 1...4 {
        if let c = context.current, c.isHexDigit {
            n += c.hexDigitValue! * Int(powf(16, 4 - Float(i)))
            context.next()
        } else {
            return nil
        }
    }
    return n
}

/*
 
 array = %x5B ws [ value *( ws %x2C ws value ) ] ws %x5D
 
 */
func parseArray(context: inout JSONContext, value: inout JSONValue) -> ReturnType {
    expect(context: &context, char: "[")
    parseWhitespace(context: &context)
    if let c = context.current, c == "]" {
        //空数组
        context.next()
        value.type = .array
        return .ok
    }
    var length = 0
    while true {
        var e = JSONValue(type: .null)
        let r = parseValue(context: &context, value: &e)
        guard r == .ok else { return r }
        context.arrayQueue.append(e)
        length += 1
        parseWhitespace(context: &context)
        if let c = context.current, c == "," {
            context.next()
            parseWhitespace(context: &context)
        } else if let c = context.current, c == "]" {
            context.next()
            value.type = .array
            let count = context.arrayQueue.count
            value.array.append(contentsOf: context.arrayQueue.suffix(length))
            context.arrayQueue.removeSubrange(count - length..<count)
            return .ok
        } else {
            return .parseMissCommaOrSquareBracket
        }
    }
}

/*
 
 member = string ws %x3A ws value
 object = %x7B ws [ member *( ws %x2C ws member ) ] ws %x7D
 
 */

func parseObject(context: inout JSONContext, value: inout JSONValue) -> ReturnType {
    expect(context: &context, char: "{")
    parseWhitespace(context: &context)
    if let c = context.current, c == "}" {
        //空object
        context.next()
        value.type = .object
        return .ok
    }
    var length = 0
    while true {
        var m = JSONMember(key: "", value: JSONValue(type: .null))
        parseWhitespace(context: &context)
        //解析key
        guard let c = context.current, c == "\"" else { return .parseMissKey }
        let keyR = parseString(context: &context)
        guard keyR == .ok else { return keyR }
        m.key = String(context.queue)
        context.queue.removeAll()
        parseWhitespace(context: &context)
        //解析`:`
        guard let colon = context.current, colon == ":" else { return .parseMissColon }
        context.next()
        parseWhitespace(context: &context)
        //解析value
        let r = parseValue(context: &context, value: &m.value)
        guard r == .ok else { return r }
        context.objectQueue.append(m)
        length += 1
        parseWhitespace(context: &context)
        if let comma = context.current, comma == "," {
            //解析`,`
            context.next()
        } else if let rcb = context.current, rcb == "}" {
            //解析`}`
            context.next()
            value.type = .object
            let count = context.objectQueue.count
            value.members.append(contentsOf: context.objectQueue.suffix(length))
            context.objectQueue.removeSubrange(count - length..<count)
            return .ok
        } else {
            //缺失报错
            return .parseMissCommaOrCuryBracket
        }
    }
}

/*
 number = [ "-" ] int [ frac ] [ exp ]
 int = "0" / digit1-9 *digit
 frac = "." 1*digit
 exp = ("e" / "E") ["-" / "+"] 1*digit
 */
func parseNumber(context: inout JSONContext, value: inout JSONValue) -> ReturnType {
    let start = context.index
    var c = context.current
    guard c != nil else { return .expectValue }
    if c == "-" {
        //解析负号
        context.next()
    }
    c = context.current
    guard c != nil else { return .expectValue }
    if c == "0" {
        //0后面不能再直接跟数字了
        context.next()
    } else {
        //解析数字
        guard c!.isNumber else { return .invalidValue }
        while context.current != nil && context.current!.isNumber {
            context.next()
        }
    }
    var isInteger = true
    if context.current == "." {
        //解析小数
        isInteger = false
        context.next()
        guard context.current?.isNumber ?? false else { return .invalidValue }
        while context.current != nil && context.current!.isNumber {
            context.next()
        }
    }
    
    if context.current == "e" || context.current == "E" {
        //解析科学计数法
        isInteger = false
        context.next()
        if context.current == "+" || context.current == "-" {
            context.next()
        }
        guard context.current?.isNumber ?? false else { return .invalidValue }
        while context.current != nil && context.current!.isNumber {
            context.next()
        }
    }
    let end = context.index
    let string = String(context.JSON[start..<end])
    //如果number是nil说明数字大到超过Double范围
    guard let number = Double(string) else { return .numberTooBig }
    value.n = number
    value.type = .number
    value.isInteger = isInteger
    return .ok
}

func parseLiteral(context: inout JSONContext, value: inout JSONValue, literal: String, type: JSONType) -> ReturnType {
    expect(context: &context, char: literal.first!)
    let index = context.index
    guard context.canMove(literal.count - 1) else {
        return .invalidValue
    }
    let array = Array(literal)
    var j = 1
    for i in index..<(index + array.count - 1) {
        if context.JSON[i] != array[j] {
            return .invalidValue
        }
        j += 1
    }
    context.move(literal.count - 1)
    value.type = type
    return .ok
}

func expect(context: inout JSONContext, char: Character) {
    guard let c = context.current else {
        assert(false, "expect a character but input nil.")
    }
    assert(c == char, "expect value: \(c)")
    context.next()
}

//MARK: Stringify

func stringify(value: inout JSONValue) -> String {
    var context = JSONContext(JSON: [])
    stringifyValue(context: &context, value: value)
    return String(context.JSON)
}

func stringifyValue(context: inout JSONContext, value: JSONValue) {
    switch value.type {
    case .null:
        context.JSON.append(contentsOf: "null")
    case .false:
        context.JSON.append(contentsOf: "false")
    case .true:
        context.JSON.append(contentsOf: "true")
    case .number:
        if value.isInteger && Double(Int.min) <= value.n && value.n <= Double(Int.max) {
            context.JSON.append(contentsOf: "\(Int(value.n))")
        } else {
            context.JSON.append(contentsOf: "\(value.n)")
        }
    case .array:
        stringifyArray(context: &context, value: value)
    case .string:
        stringifyString(context: &context, value: value)
    case .object:
        stringifyObject(context: &context, value: value)
    }
}

func stringifyString(context: inout JSONContext, value: JSONValue) {
    context.JSON.append("\"")
    value.s.forEach {
        switch $0 {
        case "\"":
            context.JSON.append(contentsOf: "\\\"")
        case "\n":
            context.JSON.append(contentsOf: "\\n")
        case "\t":
            context.JSON.append(contentsOf: "\\t")
        case "\r":
            context.JSON.append(contentsOf: "\\r")
        case "\\":
            context.JSON.append(contentsOf: "\\\\")
        default:
            context.JSON.append($0)
        }
    }
    context.JSON.append("\"")
}

func stringifyArray(context: inout JSONContext, value: JSONValue) {
    context.JSON.append("[")
    for i in 0..<value.array.count {
        let v = value.array[i]
        stringifyValue(context: &context, value: v)
        if i != value.array.count - 1 {
            context.JSON.append(",")
        }
    }
    context.JSON.append("]")
}

func stringifyObject(context: inout JSONContext, value: JSONValue) {
    context.JSON.append("{")
    for i in 0..<value.members.count {
        let m = value.members[i]
        context.JSON.append(contentsOf: "\"\(m.key)\":")
        stringifyValue(context: &context, value:m.value)
        if i != value.members.count - 1 {
            context.JSON.append(",")
        }
    }
    context.JSON.append("}")
}

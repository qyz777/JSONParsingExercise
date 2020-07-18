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
}

struct JSONValue {
    
    /// 当type为number类型时n为JSON数字的数值
    var n: Double = 0
    
    /// 当type为string类型时s为JSON的字符串
    var s: String = ""
    
    var type: JSONType
}

struct JSONContext {
    var JSON: [Character]
    var index: Int = 0
    
    var queue: [Character] = []
    
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
    default:
        return parseNumber(context: &context, value: &value)
    }
}

func parseString(context: inout JSONContext, value: inout JSONValue) -> ReturnType {
    expect(context: &context, char: "\"")
    while true {
        guard let c = context.current else { return .missQuotationMark }
        switch c {
        case "\"":
            value.s = String(context.queue)
            value.type = .string
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
    if context.current == "." {
        //解析小数
        context.next()
        guard context.current?.isNumber ?? false else { return .invalidValue }
        while context.current != nil && context.current!.isNumber {
            context.next()
        }
    }
    
    if context.current == "e" || context.current == "E" {
        //解析科学计数法
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

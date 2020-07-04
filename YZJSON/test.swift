//
//  test.swift
//  YZJSON
//
//  Created by Q YiZhong on 2020/7/4.
//  Copyright © 2020 YiZhong Qi. All rights reserved.
//

import Foundation

var mainRet = 0
var testCount = 0
var testPass = 0

func EXPECT_BASE(_ equality: Bool, _ expect: Int, _ actual: Int) {
    testCount += 1
    if equality {
        testPass += 1
    } else {
        print("expect: \(expect) actual: \(actual)")
        mainRet += 1
    }
}

func EXPECT_INT(_ expect: Int, _ actual: Int) {
    EXPECT_BASE(expect == actual, expect, actual)
}

// MARK: Test

func test() {
    test_parse()
    print("\(testPass)/\(testCount) \(Float(testPass) * 100.0 / Float(testCount))% passed.")
}

func test_parse() {
    test_parseNull()
    test_parseExpectValue()
    test_parseInvalidValue()
    test_parseRootNotSingular()
}

func test_parseNull() {
    var v = JSONValue(type: .false)
    EXPECT_INT(ReturnType.ok.rawValue, parse(JSON: "null", value: &v).rawValue)
    EXPECT_INT(JSONType.null.rawValue, v.type.rawValue)
}

func test_parseExpectValue() {
    var v = JSONValue(type: .false)
    EXPECT_INT(ReturnType.expectValue.rawValue, parse(JSON: "", value: &v).rawValue)
    EXPECT_INT(JSONType.null.rawValue, v.type.rawValue)
    
    v.type = .false
    EXPECT_INT(ReturnType.expectValue.rawValue, parse(JSON: " ", value: &v).rawValue)
    EXPECT_INT(JSONType.null.rawValue, v.type.rawValue)
}

func test_parseInvalidValue() {
    var v = JSONValue(type: .false)
    EXPECT_INT(ReturnType.invalidValue.rawValue, parse(JSON: "nul", value: &v).rawValue)
    EXPECT_INT(JSONType.null.rawValue, v.type.rawValue)
    
    v.type = .false
    EXPECT_INT(ReturnType.invalidValue.rawValue, parse(JSON: "?", value: &v).rawValue)
    EXPECT_INT(JSONType.null.rawValue, v.type.rawValue)
}

func test_parseRootNotSingular() {
    var v = JSONValue(type: .false)
    EXPECT_INT(ReturnType.rootNotSingular.rawValue, parse(JSON: "null x", value: &v).rawValue)
    EXPECT_INT(JSONType.null.rawValue, v.type.rawValue)
}

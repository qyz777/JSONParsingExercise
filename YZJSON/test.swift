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

func EXPECT_BASE(_ equality: Bool, _ expect: Any, _ actual: Any) {
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

func EXPECT_DOUBLE(_ expect: Double, _ actual: Double) {
    EXPECT_BASE(expect == actual, expect, actual)
}

func EXPECT_STRING(_ expect: String, _ actual: String) {
    EXPECT_BASE(expect == actual, expect, actual)
}

func TEST_ERROR(_ error: Int, _ JSON: String) {
    var v = JSONValue(type: .null)
    EXPECT_INT(error, parse(JSON: JSON, value: &v).rawValue)
    EXPECT_INT(JSONType.null.rawValue, v.type.rawValue)
}

func TEST_NUMBER(_ expect: Double, _ JSON: String) {
    var v = JSONValue(type: .null)
    EXPECT_INT(ReturnType.ok.rawValue, parse(JSON: JSON, value: &v).rawValue)
    EXPECT_INT(JSONType.number.rawValue, v.type.rawValue)
    EXPECT_DOUBLE(expect, v.n)
}

func TEST_STRING(_ expect: String, _ JSON: String) {
    var v = JSONValue(type: .null)
    EXPECT_INT(ReturnType.ok.rawValue, parse(JSON: JSON, value: &v).rawValue)
    EXPECT_INT(JSONType.string.rawValue, v.type.rawValue)
    EXPECT_STRING(expect, v.s)
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
    
    test_parseNumber()
    test_parseInvalidValue()
    
    test_string()
}

func test_string() {
    TEST_ERROR(ReturnType.missQuotationMark.rawValue, "\"")
    TEST_ERROR(ReturnType.missQuotationMark.rawValue, "\"123")
    TEST_ERROR(ReturnType.invalidStringEscape.rawValue, "\"\\v\"")
    TEST_ERROR(ReturnType.invalidStringEscape.rawValue, "\"\\'\"")
    TEST_ERROR(ReturnType.invalidStringEscape.rawValue, "\"\\0\"")
    TEST_ERROR(ReturnType.invalidStringEscape.rawValue, "\"\\x12\"")
    
    TEST_STRING("123", "\"123\"")
    TEST_STRING("", "\"\"")
    TEST_STRING("Hello", "\"Hello\"")
    TEST_STRING("Hello\nWorld", "\"Hello\\nWorld\"")
    TEST_STRING("\" \\ / \n \r \t", "\"\\\" \\\\ \\/ \\n \\r \\t\"")
}

func test_parseNumber() {
    TEST_NUMBER(0.0, "0")
    TEST_NUMBER(0.0, "-0")
    TEST_NUMBER(0.0, "-0.0")
    TEST_NUMBER(1.0, "1")
    TEST_NUMBER(-1.0, "-1")
    TEST_NUMBER(1.5, "1.5")
    TEST_NUMBER(-1.5, "-1.5")
    TEST_NUMBER(3.1416, "3.1416")
    TEST_NUMBER(1E10, "1E10")
    TEST_NUMBER(1e10, "1e10")
    TEST_NUMBER(1E+10, "1E+10")
    TEST_NUMBER(1E-10, "1E-10")
    TEST_NUMBER(-1E10, "-1E10")
    TEST_NUMBER(-1e10, "-1e10")
    TEST_NUMBER(-1E+10, "-1E+10")
    TEST_NUMBER(-1E-10, "-1E-10")
    TEST_NUMBER(1.234E+10, "1.234E+10")
    TEST_NUMBER(1.234E-10, "1.234E-10")
}

func test_parseNull() {
    TEST_ERROR(ReturnType.ok.rawValue, "null")
}

func test_parseExpectValue() {
    TEST_ERROR(ReturnType.expectValue.rawValue, "")
    TEST_ERROR(ReturnType.expectValue.rawValue, " ")
}

func test_parseInvalidValue() {
    TEST_ERROR(ReturnType.invalidValue.rawValue, "nul")
    TEST_ERROR(ReturnType.invalidValue.rawValue, "?")
    
    // invalid number
    TEST_ERROR(ReturnType.invalidValue.rawValue, "+0")
    TEST_ERROR(ReturnType.invalidValue.rawValue, "+1")
    TEST_ERROR(ReturnType.invalidValue.rawValue, ".123") /* at least one digit before '.' */
    TEST_ERROR(ReturnType.invalidValue.rawValue, "1.")   /* at least one digit after '.' */
    TEST_ERROR(ReturnType.invalidValue.rawValue, "INF")
    TEST_ERROR(ReturnType.invalidValue.rawValue, "inf")
    TEST_ERROR(ReturnType.invalidValue.rawValue, "NAN")
    TEST_ERROR(ReturnType.invalidValue.rawValue, "nan")
    TEST_ERROR(ReturnType.numberTooBig.rawValue, "1e-10000")
}

func test_parseRootNotSingular() {
    TEST_ERROR(ReturnType.rootNotSingular.rawValue, "null x")
}

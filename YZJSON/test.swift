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

func TEST_ROUNDTRIP(_ json: String) {
    var v = JSONValue(type: .null)
    EXPECT_INT(ReturnType.ok.rawValue, parse(JSON: json, value: &v).rawValue)
    let json2 = stringify(value: &v)
    EXPECT_STRING(json, json2)
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
    test_parseArray()
    test_object()
    test_stringify()
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
    
    TEST_STRING("Hello\0World", "\"Hello\\u0000World\"")
    TEST_STRING("$", "\"\\u0024\"")         /* Dollar sign U+0024 */
    TEST_STRING("¢", "\"\\u00A2\"")     /* Cents sign U+00A2 */
    TEST_STRING("€", "\"\\u20AC\"") /* Euro sign U+20AC */
    TEST_STRING("𝄞", "\"\\uD834\\uDD1E\"")  /* G clef sign U+1D11E */
    TEST_STRING("𝄞", "\"\\ud834\\udd1e\"")  /* G clef sign U+1D11E */
}

func test_object() {
    var v = JSONValue(type: .null)
    EXPECT_INT(ReturnType.ok.rawValue, parse(JSON: "{ }", value: &v).rawValue)
    EXPECT_INT(JSONType.object.rawValue, v.type.rawValue)
    
    v = JSONValue(type: .null)
    EXPECT_INT(ReturnType.ok.rawValue, parse(JSON: "{ \"n\" : null , \"f\": false , \"t\": true , \"i\": 123 , \"s\": \"abc\" , \"a\": [ 1 , 2 , 3] , \"o\": { \"1\" : 1 , \"2\" : 2 , \"3\" : 3 } }", value: &v).rawValue)
    EXPECT_INT(JSONType.object.rawValue, v.type.rawValue)
    EXPECT_STRING("n", v.members[0].key)
    EXPECT_INT(JSONType.null.rawValue, v.members[0].value.type.rawValue)
    EXPECT_STRING("f", v.members[1].key)
    EXPECT_INT(JSONType.false.rawValue, v.members[1].value.type.rawValue)
    EXPECT_STRING("t", v.members[2].key)
    EXPECT_INT(JSONType.true.rawValue, v.members[2].value.type.rawValue)
    EXPECT_STRING("i", v.members[3].key)
    EXPECT_INT(JSONType.number.rawValue, v.members[3].value.type.rawValue)
    EXPECT_STRING("s", v.members[4].key)
    EXPECT_INT(JSONType.string.rawValue, v.members[4].value.type.rawValue)
    EXPECT_STRING("a", v.members[5].key)
    EXPECT_INT(JSONType.array.rawValue, v.members[5].value.type.rawValue)
    for i in 0..<3 {
        EXPECT_INT(JSONType.number.rawValue, v.members[5].value.array[i].type.rawValue)
        EXPECT_DOUBLE(Double(i + 1), v.members[5].value.array[i].n)
    }
    EXPECT_STRING("o", v.members[6].key)
    EXPECT_INT(JSONType.object.rawValue, v.members[6].value.type.rawValue)
    let o = v.members[6].value
    for i in 0..<3 {
        EXPECT_INT(JSONType.number.rawValue, o.members[i].value.type.rawValue)
        EXPECT_DOUBLE(Double(i + 1), o.members[i].value.n)
    }
}

func test_parseArray() {
    var v1 = JSONValue(type: .null)
    EXPECT_INT(ReturnType.ok.rawValue, parse(JSON: "[ null , false , true , 123 , \"abc\" ]", value: &v1).rawValue)
    EXPECT_INT(JSONType.array.rawValue, v1.type.rawValue)
    EXPECT_INT(JSONType.null.rawValue, v1.array[0].type.rawValue)
    EXPECT_INT(JSONType.false.rawValue, v1.array[1].type.rawValue)
    EXPECT_INT(JSONType.true.rawValue, v1.array[2].type.rawValue)
    EXPECT_INT(JSONType.number.rawValue, v1.array[3].type.rawValue)
    EXPECT_INT(JSONType.string.rawValue, v1.array[4].type.rawValue)
    EXPECT_DOUBLE(123, v1.array[3].n)
    EXPECT_STRING("abc", v1.array[4].s)
    
    var v2 = JSONValue(type: .null)
    EXPECT_INT(ReturnType.ok.rawValue, parse(JSON: "[ [ ] , [ 0 ] , [ 0 , 1 ] , [ 0 , 1 , 2 ] ]", value: &v2).rawValue)
    EXPECT_INT(JSONType.array.rawValue, v2.type.rawValue)
    for i in 0..<4 {
        let a = v2.array[i]
        EXPECT_INT(JSONType.array.rawValue, a.type.rawValue)
        for j in 0..<i {
            let e = a.array[j]
            EXPECT_INT(JSONType.number.rawValue, e.type.rawValue)
        }
    }
    
    var v3 = JSONValue(type: .null)
    EXPECT_INT(ReturnType.parseMissCommaOrSquareBracket.rawValue, parse(JSON: "[ [ ] , [ 0 ] , [ 0 , 1 ] , [ 0 , 1 , 2 ] ", value: &v3).rawValue)
    EXPECT_INT(JSONType.null.rawValue, v3.type.rawValue)
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


func test_stringifyNumber() {
    TEST_ROUNDTRIP("0.0")
    TEST_ROUNDTRIP("-0.0")
    TEST_ROUNDTRIP("1.0")
    TEST_ROUNDTRIP("-1.0")
    TEST_ROUNDTRIP("1.5")
    TEST_ROUNDTRIP("-1.5")
    TEST_ROUNDTRIP("3.25")
    TEST_ROUNDTRIP("1e+20")
    TEST_ROUNDTRIP("1.234e+20")
    TEST_ROUNDTRIP("1.234e-20")
    
    TEST_ROUNDTRIP("1.0000000000000002") /* the smallest number > 1 */
    TEST_ROUNDTRIP("5e-324") /* minimum denormal */
    TEST_ROUNDTRIP("-5e-324")
    TEST_ROUNDTRIP("2.225073858507201e-308")  /* Max subnormal double */
    TEST_ROUNDTRIP("-2.225073858507201e-308")
    TEST_ROUNDTRIP("2.2250738585072014e-308")  /* Min normal positive double */
    TEST_ROUNDTRIP("-2.2250738585072014e-308")
    TEST_ROUNDTRIP("1.7976931348623157e+308")  /* Max double */
    TEST_ROUNDTRIP("-1.7976931348623157e+308")
}

func test_stringifyString() {
    TEST_ROUNDTRIP("\"\"")
    TEST_ROUNDTRIP("\"Hello\"")
    TEST_ROUNDTRIP("\"Hello\\nWorld\"")
    TEST_ROUNDTRIP("\"\\\" \\\\ / \\n \\r \\t\"")
    //特殊处理，由于JSON解析是\uxxxx被直接解析，因此这个test不能成功
//    TEST_ROUNDTRIP("\"Hello\\u2333World\"")
}

func test_stringifyArray() {
    TEST_ROUNDTRIP("[]")
    TEST_ROUNDTRIP("[null,false,true,123,\"abc\",[1,2,3]]")
}

func test_stringifyObject() {
    TEST_ROUNDTRIP("{}")
    TEST_ROUNDTRIP("{\"n\":null,\"f\":false,\"t\":true,\"i\":123,\"s\":\"abc\",\"a\":[1,2,3],\"o\":{\"1\":1,\"2\":2,\"3\":3}}")
}

func test_stringify() {
    TEST_ROUNDTRIP("null")
    TEST_ROUNDTRIP("false")
    TEST_ROUNDTRIP("true")
    test_stringifyNumber()
    test_stringifyString()
    test_stringifyArray()
    test_stringifyObject()
}

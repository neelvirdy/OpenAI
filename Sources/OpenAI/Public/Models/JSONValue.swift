//
//  JSONValue.swift
//  OpenAI
//
//  Created by Neel Virdy on 3/26/25.
//

// 1️⃣ Protocol that “knows how” to convert itself into JSONValue
public protocol JSONEnumRepresentable {
    var jsonValue: JSONValue { get }
}

// 2️⃣ Conform the types you want (and JSONValue itself)
extension JSONValue: JSONEnumRepresentable { public var jsonValue: JSONValue { self } }
extension Int: JSONEnumRepresentable    { public var jsonValue: JSONValue { .integer(self) } }
extension String: JSONEnumRepresentable { public var jsonValue: JSONValue { .string(self) } }
extension Bool: JSONEnumRepresentable   { public var jsonValue: JSONValue { .bool(self) } }
// (add Double, etc. if needed)


public enum JSONValue: Codable, Equatable {
    case string(String)
    case integer(Int)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let int = try? container.decode(Int.self) {
            self = .integer(int)
        } else if let dbl = try? container.decode(Double.self) {
            self = .number(dbl)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let arr = try? container.decode([JSONValue].self) {
            self = .array(arr)
        } else if let obj = try? container.decode([String: JSONValue].self) {
            self = .object(obj)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .integer(let i): try container.encode(i)
        case .number(let n): try container.encode(n)
        case .bool(let b): try container.encode(b)
        case .array(let a): try container.encode(a)
        case .object(let o): try container.encode(o)
        case .null: try container.encodeNil()
        }
    }
}

extension JSONValue:
    ExpressibleByStringLiteral,
    ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral,
    ExpressibleByBooleanLiteral,
    ExpressibleByArrayLiteral,
    ExpressibleByDictionaryLiteral,
    ExpressibleByNilLiteral {

    public init(stringLiteral value: String) {
        self = .string(value)
    }

    public init(integerLiteral value: Int) {
        self = .integer(value)
    }

    public init(floatLiteral value: Double) {
        self = .number(value)
    }

    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }

    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }

    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }

    public init(nilLiteral: ()) {
        self = .null
    }
}

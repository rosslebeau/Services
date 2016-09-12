//
// These are internal helpers used to convert between Vapor types and Swift standard types
//

import Common
import HTTP
import Node
import JSON
import URI
import struct Foundation.Data
import struct Foundation.URL

//MARK: - Headers
extension Sequence where Iterator.Element == (key: HeaderKey, value: String) {
    func makeDictionary() -> [String: String] {
        return Dictionary<String, String>(self.map({ ($0.key, $1) }))
    }
}
extension Dictionary where Key: StringType, Value: StringType {
    func makeHeaders() -> [HeaderKey: String] {
        return Dictionary<HeaderKey, String>(self.map({ (HeaderKey($0.string), $1.string) }))
    }
}

//MARK: - Node 
extension Node {
    var any: Any? {
        switch self {
        case .null: return nil
        case .string(let value): return value
        case .bool(let value): return value
        case .number(let number):
            switch number {
            case .int(let value): return value
            case .double(let value): return value
            case .uint(let value): return Int(value)
            }
        case .array(let value):
            return value.flatMap { $0.any }
        case .object(let dict):
            var result = [String: Any]()
            for (key, value) in dict {
                guard let value = value.any else { continue }
                result[key] = value
            }
            return result
        case .bytes(let value): return value
        }
    }
}

//MARK: - JSON
extension JSON {
    func makeDictionary() -> [String: Any]? {
        guard let value = self.node.any as? [String: Any] else { return nil }
        return value
    }
}
extension Dictionary where Key: StringType, Value: Any {
    func makeObject() throws -> JSON {
        let input: [(String, Node)] = try self.flatMap { key, value in
            guard let value = value as? NodeConvertible else { return nil }
            return (key.string, try value.makeNode())
        }
        return try JSON(node: Node(Dictionary<String, Node>(input)))
    }
    func makeURLEncodedObject() throws -> Body {
        let input: [(String, Node)] = self.flatMap { key, value in
            guard
                let value = value as? StringRepresentable,
                let string = value.makeString()
                else { return nil }
            
            return (key.string, Node(string))
        }
        
        let dict = Dictionary<String, Node>(input)
        return Body(try dict.makeNode().formURLEncoded())
    }
}

//MARK: - HTTP Method
extension HTTPRequestMethod {
    var method: Method {
        switch self {
        case .get: return .get
        case .put: return .put
        case .patch: return .patch
        case .post: return .post
        case .delete: return .delete
        }
    }
}

//MARK: - Response
extension HTTPServerResponse {
    func makeResponse() throws -> Response {
        let headers = self.headers?.makeHeaders() ?? [:]
        let body = try self.body?.makeObject().makeBody() ?? .data([])
        
        return Response(
            status: Status(statusCode: self.code),
            headers: headers,
            body: body
        )
    }
}

//MARK: - URI
extension URI {
    func makeURL() -> URL {
        var string = "\(scheme)://\(self.host)"
        if let port = self.port {
            string += ":\(port)"
        }
        string += self.path
        
        if let query = self.query {
            string += "?\(query)"
        }
        if let fragment = self.fragment {
            string += "#\(fragment)"
        }
        
        guard let url = URL(string: string)
            else { fatalError("Invalid URL: \(string)") }
        
        return url
    }
}


import Foundation

//MARK: - Mode
public enum HTTPServerMode {
    case currentThread
    case newThread
}

//MARK: Typealiases
public typealias RouteHandler = (
    URL,
    [String: String], //headers
    [String: Any]? //json/data
    ) throws -> HTTPServerResponse?

//MARK: - HTTPServer
public protocol HTTPServer {
    func start(mode: HTTPServerMode)
    
    func respond(
        to method: HTTPRequestMethod,
        at path: [String],
        with handler: @escaping RouteHandler
    )
    
    func respond<T: AnyObject>(
        to method: HTTPRequestMethod,
        at path: [String],
        with object: T,
        _ function: @escaping (T) -> RouteHandler
    )
}

//MARK: - Responses
public protocol HTTPServerResponse {
    var code: Int { get }
    var headers: [String: String]? { get }
    var body: [String: Any]? { get }
}

extension URL: HTTPServerResponse {
    public var code: Int { return 307 }
    public var headers: [String : String]? {
        let url: String? = self.absoluteString
        guard let urlString = url else { fatalError("Invalid URL: \(self)") }
        
        return ["Location": urlString]
    }
    public var body: [String : Any]? { return nil }
}

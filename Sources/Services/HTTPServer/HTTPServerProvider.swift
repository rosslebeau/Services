import Common
import Vapor
import HTTP
import Routing
import struct Foundation.URL

final public class HTTPServerProvider: HTTPServer {
    //MARK: - Private
    private let server: Droplet
    
    //MARK: - Lifecycle
    public init(server: Droplet) {
        self.server = server
    }
    public convenience init() {
        self.init(server: Droplet())
    }
    
    //MARK: - Public
    public func start(mode: HTTPServerMode) {
        switch mode {
        case .currentThread:
            self.server.serve()
        
        case .newThread:
            _ = inBackground {
                self.server.serve()
            }
        }
    }
    public func respond(to method: HTTPRequestMethod, at path: [String], with handler: @escaping RouteHandler) {
        self.server.addResponder(method.method, path) { request in
            let headers = request.headers
            
            do {
                guard let response = try handler(
                    request.uri.makeURL(),
                    headers.makeDictionary(),
                    request.responseJson.makeDictionary()
                    )
                    else { return Response(status: .ok) }
                
                return try response.makeResponse()
                
            } catch {
                return Response(status: .internalServerError)
            }
        }
    }
    public func respond<T: AnyObject>(to method: HTTPRequestMethod, at path: [String], with object: T, _ function: @escaping (T) -> RouteHandler) {
        self.server.addResponder(method.method, path) { [weak object] request in
            guard let object = object else { return Response(status: .internalServerError) }
            
            let headers = request.headers
            
            do {
                guard let response = try function(object)(
                    request.uri.makeURL(),
                    headers.makeDictionary(),
                    request.responseJson.makeDictionary()
                    )
                    else { return Response(status: .ok) }
                
                return try response.makeResponse()
                
            } catch {
                return Response(status: .internalServerError)
            }
        }
    }
}

extension Request {
    var responseJson: JSON {
        if let json = self.json {
            return json
            
        } else if let formData = self.formURLEncoded, let json = try? JSON(node: formData) {
            return json
        }
        
        return JSON(.null)
    }
}

extension Routing.RouteBuilder where Value == Responder {
    public func addResponder(
        _ method: Method,
        _ path: [String],
        _ value: @escaping (Request) throws -> ResponseRepresentable
        ) {
        add(
            path: ["*", method.description] + path,
            value: Request.Handler({ request in
                return try value(request).makeResponse()
            })
        )
    }
}

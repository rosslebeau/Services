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
        let config = try! Vapor.Config(arguments: ["--port=$PORT"])
        self.init(server: Droplet(config: config))
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
    public func respond(to method: HTTPRequestMethod, at path: [String], with handler: RouteHandler) {
        self.server.addResponder(method.method, path) { request in
            let headers = request.headers
            let json = request.json ?? (try? JSON(node: request.formURLEncoded)) ?? .null
            
            do {
                guard let response = try handler(url: request.uri.makeURL(), headers: headers.makeDictionary(), json: json.makeDictionary())
                    else { return Response(status: .ok) }
                
                return try response.makeResponse()
                
            } catch {
                return Response(status: .internalServerError)
            }
        }
    }
    public func respond<T: AnyObject>(to method: HTTPRequestMethod, at path: [String], with object: T, _ function: (T) -> RouteHandler) {
        self.server.addResponder(method.method, path) { [weak object] request in
            guard let object = object else { return Response(status: .internalServerError) }
            
            let headers = request.headers
            let json = request.json ?? (try? JSON(node: request.formURLEncoded)) ?? .null
            
            do {
                guard let response = try function(object)(url: request.uri.makeURL(), headers: headers.makeDictionary(), json: json.makeDictionary())
                    else { return Response(status: .ok) }
                
                return try response.makeResponse()
                
            } catch {
                return Response(status: .internalServerError)
            }
        }
    }
}

extension Routing.RouteBuilder where Value == Responder {
    public func addResponder(
        _ method: Method,
        _ path: [String],
        _ value: (Request) throws -> ResponseRepresentable
        ) {
        add(
            path: ["*", method.description] + path,
            value: Request.Handler({ request in
                return try value(request).makeResponse()
            })
        )
    }
}

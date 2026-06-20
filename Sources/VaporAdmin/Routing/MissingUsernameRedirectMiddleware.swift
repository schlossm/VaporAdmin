import Vapor

enum AdminControllerError : Error
{
    case missingUsername
}

struct MissingUsernameRedirectMiddleware : AsyncMiddleware
{
    let adminSiteBasePath : String
    
    func respond(to request: Vapor.Request, chainingTo next: any Vapor.AsyncResponder) async throws -> Vapor.Response
    {
        do
        {
            return try await next.respond(to: request)
        }
        catch is AdminControllerError
        {
            return request.redirect(to: "/\(adminSiteBasePath)/login?loginRequired=true")
        }
    }
}

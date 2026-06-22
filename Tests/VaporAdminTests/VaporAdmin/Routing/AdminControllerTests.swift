#if Passage
import PassageOnlyForTest
import Passage
#endif

@testable import VaporAdmin
import VaporTesting
import XCTFluent
import Testing
import JWTKit
import Fluent

@Suite("AdminController.swift Tests")
struct AdminControllerTests
{
    static let defaultDatabase = CallbackTestDatabase
    {
        Issue.record("Unexpected database call, received: \($0)")
        return []
    }
    
    @Test("Root redirects to login if no user")
    func rootNotLoggedIn() async throws
    {
        try await withTestApp { app, _, _ in
            try await app.test(.GET, "admin") { response in
                #expect(response.status == .seeOther)
                #expect(response.headers.first(name: "location") == "/admin/login?loginRequired=true")
            }
        }
    }
    
    @Test("Root returns contents if logged in")
    func rootLoggedIn() async throws
    {
        try await withAuthenticatedTestApp { app, token, renderer in
            app.admin.register(TestModel.self)
            
            try await app.test(.GET, "admin", headers: ["Authorization": "\(token.tokenType) \(token.accessToken)"]) { response in
                #expect(response.status == .ok)
                #expect(renderer.templatePath == "admin-root")

                // Verify context was passed
                let ctx = try #require(renderer.capturedContext as? AdminContext.Root)
                #expect(ctx.header.breadcrumbs == [.init(text: "Admin Panel", relativeHREF: "", isActive: true)])
                #expect(ctx.header.username == "Test")
                #expect(ctx.modelNames == ["TestModel"])
            }
        }
    }
    
    @Test("Entry List returns contents if logged in")
    func entryList() async throws
    {
        let database = CallbackTestDatabase { _ in
            return [
                TestOutput(TestModelCustomAdminDisplayable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "Test", bar: 1))
            ]
        }
        try await withAuthenticatedTestApp(database: database) { app, token, renderer in
            app.admin.register(TestModelCustomAdminDisplayable.self)
            
            try await app.test(.GET, "admin/models/TestModelCustomAdminDisplayable", headers: ["Authorization": "\(token.tokenType) \(token.accessToken)"]) { response in
                #expect(response.status == .ok)
                #expect(renderer.templatePath == "admin-entryList")

                // Verify context was passed
                let ctx = try #require(renderer.capturedContext as? AdminContext.List)
                #expect(ctx.header.breadcrumbs == [.init(text: "Admin Panel", relativeHREF: "/admin", isActive: false),
                                                   .init(text: "TestModelCustomAdminDisplayable", relativeHREF: "", isActive: true)])
                #expect(ctx.header.username == "Test")
                #expect(ctx.entries == [.init(id: "00010203-0405-0607-0809-0A0B0C0D0E0F", text: "Test")])
            }
        }
    }
    
    @Test("Create returns contents if logged in")
    func createGet() async throws
    {
        try await withAuthenticatedTestApp() { app, token, renderer in
            app.admin.register(TestModelCustomAdminDisplayable.self)
            
            try await app.test(.GET, "admin/models/TestModelCustomAdminDisplayable/create", headers: ["Authorization": "\(token.tokenType) \(token.accessToken)"]) { response in
                #expect(response.status == .ok)
                #expect(renderer.templatePath == "admin-entryCreate")

                // Verify context was passed
                let ctx = try #require(renderer.capturedContext as? AdminContext.Detail.Create)
                #expect(ctx.header.breadcrumbs == [.init(text: "Admin Panel", relativeHREF: "/admin", isActive: false),
                                                   .init(text: "TestModelCustomAdminDisplayable", relativeHREF: "/admin/models/TestModelCustomAdminDisplayable", isActive: false),
                                                   .init(text: "Create New", relativeHREF: "", isActive: true)])
                #expect(ctx.header.username == "Test")
                #expect(ctx.fields == [.init(key: "name", value: "", fieldType: .text, optional: false, isMultiSelect: false), .init(key: "bar_blah", value: "", fieldType: .number, optional: false, isMultiSelect: false)])
            }
        }
    }
    
    @Test("Create creates the model if logged in")
    func createPost() async throws
    {
        let database = CallbackTestDatabase { query in
            guard case .create = query.action else
            {
                Issue.record("Received unexpected query: \(query)")
                return []
            }
            #expect(query.fields.map(\.description) == ["test_models[id]", "test_models[name]", "test_models[bar_blah]"])
            switch query.input[0] {
            case .dictionary(let dictionary):
                #expect(dictionary["name"]?.bind() == "test2")
                #expect(dictionary["bar_blah"]?.bind() == 2)
                #expect(dictionary["id"] != nil)
                
            default:
                Issue.record("Unexpected query input: \(query.input)")
            }
            return [
                TestOutput(TestModelCustomAdminDisplayable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "Test", bar: 1))
            ]
        }
        
        var buffer = ByteBuffer()
        let encoder = FormDataEncoder()
        try encoder.encode(["name": "test2", "bar_blah": "2"], boundary: "---Test", into: &buffer)
        
        try await withAuthenticatedTestApp(database: database) { app, token, _ in
            app.admin.register(TestModelCustomAdminDisplayable.self)
            
            try await app.test(.POST,
                               "admin/models/TestModelCustomAdminDisplayable/create",
                               headers: ["Authorization": "\(token.tokenType) \(token.accessToken)", "Content-Type": "multipart/form-data; boundary=---Test"],
                               body: buffer) { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "{\"redirect\":\"\\/admin\\/models\\/TestModelCustomAdminDisplayable\\/\"}")
            }
        }
    }
    
    @Test("Entry Details returns contents if logged in")
    func entryDetailsGet() async throws
    {
        let database = CallbackTestDatabase { _ in
            return [
                TestOutput(TestModelCustomAdminDisplayable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "Test", bar: 1))
            ]
        }
        try await withAuthenticatedTestApp(database: database) { app, token, renderer in
            app.admin.register(TestModelCustomAdminDisplayable.self)
            
            try await app.test(.GET, "admin/models/TestModelCustomAdminDisplayable/details/00010203-0405-0607-0809-0A0B0C0D0E0F", headers: ["Authorization": "\(token.tokenType) \(token.accessToken)"]) { response in
                #expect(response.status == .ok)
                #expect(renderer.templatePath == "admin-entryDetail")

                // Verify context was passed
                let ctx = try #require(renderer.capturedContext as? AdminContext.Detail)
                #expect(ctx.header.breadcrumbs == [.init(text: "Admin Panel", relativeHREF: "/admin", isActive: false),
                                                   .init(text: "TestModelCustomAdminDisplayable", relativeHREF: "/admin/models/TestModelCustomAdminDisplayable", isActive: false),
                                                   .init(text: "00010203-0405-0607-0809-0A0B0C0D0E0F", relativeHREF: "", isActive: true)])
                #expect(ctx.header.username == "Test")
                #expect(ctx.fields == [
                    .init(key: "name", value: "Test", fieldType: .text, optional: false, isMultiSelect: false),
                    .init(key: "bar_blah", value: "1", fieldType: .number, optional: false, isMultiSelect: false)
                ])
            }
        }
    }
    
    @Test("Details saves the model if logged in")
    func detailsPost() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action {
            case .read:
                return [
                    TestOutput(TestModelCustomAdminDisplayable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "Test", bar: 1))
                ]
                
            case .update:
                #expect(query.fields.map(\.description) == ["test_models[id]", "test_models[name]", "test_models[bar_blah]"])
                #expect(query.filters.map(\.description) == ["test_models[id] = 00010203-0405-0607-0809-0A0B0C0D0E0F"])
                switch query.input[0] {
                case .dictionary(let dictionary):
                    #expect(dictionary["name"]?.bind() == "test2")
                    #expect(dictionary["bar_blah"]?.bind() == 2)
                    
                default:
                    Issue.record("Unexpected query input: \(query.input)")
                }
                return []
                
            default: Issue.record("Received unexpected query: \(query)")
            }
            return []
        }
        
        var buffer = ByteBuffer()
        let encoder = FormDataEncoder()
        try encoder.encode(["name": "test2", "bar_blah": "2"], boundary: "---Test", into: &buffer)
        
        try await withAuthenticatedTestApp(database: database) { app, token, _ in
            app.admin.register(TestModelCustomAdminDisplayable.self)
            
            try await app.test(.POST,
                               "admin/models/TestModelCustomAdminDisplayable/details/00010203-0405-0607-0809-0A0B0C0D0E0F",
                               headers: ["Authorization": "\(token.tokenType) \(token.accessToken)", "Content-Type": "multipart/form-data; boundary=---Test"],
                               body: buffer) { response in
                #expect(response.status == .ok)
            }
        }
    }
    
    @Test("Details deletes the model if logged in")
    func detailsDelete() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action {
            case .read:
                return [
                    TestOutput(TestModelCustomAdminDisplayable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "Test", bar: 1))
                ]
                
            case .delete:
                #expect(query.fields.map(\.description) == ["test_models[id]", "test_models[name]", "test_models[bar_blah]"])
                #expect(query.filters.map(\.description) == ["test_models[id] = 00010203-0405-0607-0809-0A0B0C0D0E0F"])
                return []
                
            default: Issue.record("Received unexpected query: \(query)")
            }
            return []
        }
        
        try await withAuthenticatedTestApp(database: database) { app, token, _ in
            app.admin.register(TestModelCustomAdminDisplayable.self)
            
            try await app.test(.DELETE,
                               "admin/models/TestModelCustomAdminDisplayable/details/00010203-0405-0607-0809-0A0B0C0D0E0F",
                               headers: ["Authorization": "\(token.tokenType) \(token.accessToken)"]) { response in
                #expect(response.status == .ok)
            }
        }
    }
    
    @Test("JS files")
    func jsFiles() async throws
    {
        try await withTestApp { app, _, _ in
            try await app.test(.GET, "/admin/static/adminTheme.js") { response in
                #expect(response.status == .ok)
                #expect(!response.body.string.isEmpty)
            }
            
            try await app.test(.GET, "/admin/static/adminCreate.js") { response in
                #expect(response.status == .ok)
                #expect(!response.body.string.isEmpty)
            }
            
            try await app.test(.GET, "/admin/static/adminDetail.js") { response in
                #expect(response.status == .ok)
                #expect(!response.body.string.isEmpty)
            }
            
            try await app.test(.GET, "/admin/static/adminList.js") { response in
                #expect(response.status == .ok)
                #expect(!response.body.string.isEmpty)
            }
        }
    }
    
    @discardableResult
    private func withAuthenticatedTestApp<T>(database: CallbackTestDatabase = defaultDatabase,
                                             _ run: (Application, TestTokenResponse, CapturingViewRenderer) async throws -> T) async throws -> T
    {
        try await withTestApp(database: database) { app, store, renderer in
            try await createTestUser(app: app, store: store, username: "Test", password: "password123")
            var accessToken : TestTokenResponse?
            
            // Attempt login via HTTP
            try await app.testing().test(.POST, "admin/login", beforeRequest: { req in
                try req.content.encode(["username": "Test", "password": "password123"])
            }, afterResponse: { res async throws in
                try #require(res.status == .ok)
                let response = try JSONDecoder().decode(TestTokenResponse.self, from: res.body)
                accessToken = response
            })
            
            let token = try #require(accessToken)
            return try await run(app, token, renderer)
        }
    }
    
    #if Passage
    @discardableResult
    private func withTestApp<T>(database: CallbackTestDatabase = defaultDatabase,
                                _ run: (Application, Passage.OnlyForTest.InMemoryStore, CapturingViewRenderer) async throws -> T) async throws -> T
    {
        // Configure Passage with test services
        let store = Passage.OnlyForTest.InMemoryStore()
        let emailDelivery = Passage.OnlyForTest.MockEmailDelivery()
        let phoneDelivery = Passage.OnlyForTest.MockPhoneDelivery()
        
        let services = Passage.Services(
            store: store,
            random: DefaultRandomGenerator(),
            emailDelivery: emailDelivery,
            phoneDelivery: phoneDelivery,
            federatedLogin: nil
        )
        
        let emptyJwks = """
        {"keys":[]}
        """
        return try await withApp { app in
            let renderer = CapturingViewRenderer(eventLoop: app.eventLoopGroup.any())
            app.views.use { req in
                renderer
            }
            
            await app.jwt.keys.add(
                hmac: HMACKey(from: "test-secret-key-for-jwt-signing"),
                digestAlgorithm: .sha256,
                kid: JWKIdentifier(string: "test-key")
            )
            
            app.databases.use(database.configuration, as: .test)
            app.middleware.use(app.sessions.middleware)
            try await app.admin.configure(app: app,
                                          configuration: .init(authentication: .init(passageCustomServices: services,
                                                                                     configuration: .init(origin: URL(string: "https://www.example.com")!,
                                                                                                          routes: .init(group: "admin"),
                                                                                                          sessions: .init(enabled: true),
                                                                                                          jwt: .init(jwks: .init(json: emptyJwks)),
                                                                                                          views: .init(login: .init(
                                                                                                            style: .minimalism,
                                                                                                            theme: .init(colors: .mintDark),
                                                                                                            redirect: .init(onSuccess: "/admin/"),
                                                                                                            identifier: .username))),
                                                                                     userModelType: Passage.OnlyForTest.InMemoryUser.self)))
            return try await run(app, store, renderer)
        }
    }
    
    private func createTestUser(app: Application, store: Passage.Store, username: String, password: String) async throws
    {
        // Hash the password
        let passwordHash = try await app.password.async.hash(password)

        // Create user
        let credential = Credential.password(passwordHash)
        _ = try await store.users.create(identifier: .username(username), with: credential)
    }
    #else
    @discardableResult
    private func withTestApp<T>(database: CallbackTestDatabase = defaultDatabase,
                                _ run: (Application, PassageUnavailable, CapturingViewRenderer) async throws -> T) async throws -> T
    {
        return try await withApp { app in
            let renderer = CapturingViewRenderer(eventLoop: app.eventLoopGroup.any())
            app.views.use { req in
                renderer
            }
            
            app.routes.post("admin", "login") { req async throws in
                let data = TestTokenResponse(accessToken: "123456", tokenType: "Bearer")
                return Response(status: .ok, body: .init(data: try! JSONEncoder().encode(data)))
            }
            
            app.databases.use(database.configuration, as: .test)
            app.middleware.use(app.sessions.middleware)
            try await app.admin.configure(app: app,
                                          configuration: .init(authentication: .init(customAuthenticators: [PassageUnavailableSessionBearerAuthenticator()],
                                                                                     userModelType: PassageUnavailableUser.self,
                                                                                     guard: PassageUnavailableGuard(),
                                                                                     usernameFromRequest: { _ in "Test" })))
            return try await run(app, PassageUnavailable(), renderer)
        }
    }
    
    private func createTestUser(app: Application, store: PassageUnavailable, username: String, password: String) async throws { }
    #endif
}

extension DatabaseID
{
    static var test : Self
    {
        .init(string: "test")
    }
}

#if Passage
struct DefaultRandomGenerator : Passage.RandomGenerator
{
    
    func generateRandomString(count: Int) -> String
    {
        Data([UInt8].random(count: count)).base64EncodedString()
    }
    
    func generateOpaqueToken() -> String
    {
        generateRandomString(count: 32)
    }
    
    func hashOpaqueToken(token: String) -> String
    {
        SHA256.hash(data: Data(token.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
    
    func generateVerificationCode(length: Int) -> String
    {
        // Alphanumeric characters excluding confusing ones (0/O, 1/I/L)
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}
#endif

/// Mock ViewRenderer for testing that captures template names and context data
/// without requiring Leaf template rendering
final class CapturingViewRenderer: ViewRenderer, @unchecked Sendable
{
    var shouldCache = false
    var eventLoop: EventLoop

    private(set) var capturedContext: Encodable?
    private(set) var templatePath: String?

    init(eventLoop: EventLoop)
    {
        self.eventLoop = eventLoop
    }

    func `for`(_ request: Request) -> ViewRenderer
    {
        return self
    }

    func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View> where E: Encodable
    {
        self.capturedContext = context
        self.templatePath = name

        // Return a dummy view with the template name
        var byteBuffer = ByteBufferAllocator().buffer(capacity: name.count)
        byteBuffer.writeString("Rendered: \(name)")
        let view = View(data: byteBuffer)
        return eventLoop.future(view)
    }
}

private struct TestTokenResponse : Codable
{
    let accessToken : String
    let tokenType : String
}

// MARK: - No Passage Traits Support

#if !Passage

private struct PassageUnavailableUser : Authenticatable, Sendable {}

private struct PassageUnavailableGuard : AsyncMiddleware
{
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response
    {
        try await next.respond(to: request)
    }
}

private struct PassageUnavailableSessionBearerAuthenticator : AsyncBearerAuthenticator
{
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws
    {
        request.auth.login(PassageUnavailableUser())
    }
}

private struct PassageUnavailable : JWTPayload
{
    func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {}
}

#endif

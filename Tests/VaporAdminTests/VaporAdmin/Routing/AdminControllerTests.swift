//
//  AdminControllerTests.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/5/26.
//

@testable import VaporAdmin
import PassageOnlyForTest
import VaporTesting
import XCTFluent
import Passage
import Testing
import JWTKit
import Fluent

@Suite("AdminController.swift Tests")
struct AdminControllerTests
{
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
    
    @discardableResult
    private func withAuthenticatedTestApp<T>(database: CallbackTestDatabase = CallbackTestDatabase { _ in [] },
                                             _ run: (Application, TestTokenResponse, CapturingViewRenderer) async throws -> T) async throws -> T
    {
        try await withTestApp(database: database) { app, store, renderer in
            try await createTestUser(
                app: app,
                store: store,
                username: "Test",
                password: "password123",
                isEmailVerified: true
            )

            
            var accessToken : TestTokenResponse?
            
            // Attempt login via HTTP
            try await app.testing().test(.POST, "admin/login", beforeRequest: { req in
                try req.content.encode([
                    "username": "Test",
                    "password": "password123"
                ])
            }, afterResponse: { res async throws in
                try #require(res.status == .ok)
                let response = try JSONDecoder().decode(TestTokenResponse.self, from: res.body)
                accessToken = response
            })
            
            let token = try #require(accessToken)
            
            return try await run(app, token, renderer)
        }
    }
    
    @discardableResult
    private func withTestApp<T>(database: CallbackTestDatabase = CallbackTestDatabase { _ in [] },
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
                                          origin: URL(string: "https://www.example.com")!,
                                          jwks: emptyJwks,
                                          services: services,
                                          userModelType: Passage.OnlyForTest.InMemoryUser.self)
            
            return try await run(app, store, renderer)
        }
    }
    
    private func createTestUser(
        app: Application,
        store: Passage.Store,
        email: String? = nil,
        phone: String? = nil,
        username: String? = nil,
        password: String = "password123",
        isEmailVerified: Bool = false,
        isPhoneVerified: Bool = false
    ) async throws {
        // Hash the password
        let passwordHash = try await app.password.async.hash(password)

        // Create identifier based on type
        let identifier: Identifier
        if let email = email {
            identifier = .email(email)
        } else if let phone = phone {
            identifier = .phone(phone)
        } else if let username = username {
            identifier = .username(username)
        } else {
            throw PassageError.unexpected(message: "At least one identifier must be provided")
        }

        // Create user
        let credential = Credential.password(passwordHash)
        let user = try await store.users.create(identifier: identifier, with: credential)

        // Update verification status if needed
        if isEmailVerified {
            try await store.users.markEmailVerified(for: user)
        }
        if isPhoneVerified {
            try await store.users.markPhoneVerified(for: user)
        }
    }
}

extension DatabaseID
{
    static var test : Self
    {
        .init(string: "test")
    }
}

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

/// Mock ViewRenderer for testing that captures template names and context data
/// without requiring Leaf template rendering
final class CapturingViewRenderer: ViewRenderer, @unchecked Sendable {
    var shouldCache = false
    var eventLoop: EventLoop

    private(set) var capturedContext: Encodable?
    private(set) var templatePath: String?

    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }

    func `for`(_ request: Request) -> ViewRenderer {
        return self
    }

    func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View> where E: Encodable {
        self.capturedContext = context
        self.templatePath = name

        // Return a dummy view with the template name
        var byteBuffer = ByteBufferAllocator().buffer(capacity: name.count)
        byteBuffer.writeString("Rendered: \(name)")
        let view = View(data: byteBuffer)
        return eventLoop.future(view)
    }
}

private struct TestTokenResponse : Decodable
{
    let accessToken : String
    let tokenType : String
}

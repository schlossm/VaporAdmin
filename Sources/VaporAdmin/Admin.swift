import Vapor
import Leaf
import Fluent
import LeafKit
import Passage
import PassageFluent

/// Add this macro to any `Model` to enable admin portal management.
///
/// Models managed by the admin portal will be eligible for CRUD operations through `<HOST_URL>/admin`
/// - Note: The admin portal will attempt to use the `description` property for display.
///         If this doesn't make sense for your use case, conform your `Model` to ``CustomAdminDisplayable`` to provide the Admin portal a custom description
@attached(member, names: named(adminMetadata)) @attached(extension, conformances: FluentAdminDisplay)
public macro AdminDisplayable() = #externalMacro(module: "VaporAdminMacros", type: "AdminDisplayableMacro")

/// A type with a customized textual representation for the admin portal
public protocol CustomAdminDisplayable
{
    /// A textual representation of this instance suitable for the admin portal
    var displayString : String { get }
}

/// To conform a Model to `FluentAdminDisplay`, add the ``AdminDisplayable()``.
public typealias AdminModel = FluentAdminDisplay & Model

extension Admin
{
    /// The `VaporAdmin` configuration interface
    ///
    /// Currently, you can configure the following items:
    /// * The authentication model to be used
    /// * The base group for routes.  Defaults to "admin"
    public struct Configuration : Sendable
    {
        /// The authentication model
        ///
        /// Unless `.custom` is used, VaporAdmin uses `Passage` for authentication.  If you already use Passage in your site, pass `.passagePreConfigured` to skip Vapor trying to configure
        public enum Authentication : Sendable
        {
            /// Configure Passage with a basic configuration
            ///
            /// This configuration option does not support HTML-based registration
            /// - Note: This configuration is insecure and meant for small, single-purpose sites.  **Do not use this option if sensitive information is stored!**  This configuration does not support MFA or 2FA and only supports username/password login
            case passage(origin: URL)
            
            /// Configure passage with your own services and configuration
            ///
            /// By default, `VaporAdmin` uses `PassageFluent` to manage users.  Specify a custom `userModelType` to alter this behavior
            case passageCustom(services: Passage.Services, configuration: Passage.Configuration, userModelType: any (Authenticatable & Sendable).Type = PassageFluent.UserModel.self)
            
            /// Specify this option if Passage is already configured for your application
            case passagePreConfigured
            
            /// Configure authentication to use your own Middleware and `Authenticatable` user model type
            ///
            /// Authentication guarding on requests in `VaporAdmin` works as follows:
            /// 1. Run Middleware to validate and resolve authentication strategies such as Session or Access Token
            /// 2. Check for the existence of the expected `Authenticatable` model type, or redirect to login if it's incorrect or missing
            /// 3. Perform a final, last-chance check that the request has an attached user object, else fail the request
            ///
            /// - Note: You are responsible for ensuring the Middleware properly guards against malicious attempts
            ///
            /// - Parameter authenticators: Middleware such as a Session Authenticator and/or Access Token Authenticator.  Do not include a Model-type check, instead set the `userModelType` to your expected model type
            /// - Parameter userModelType: The `Authenticatable` model to validate authentication against
            /// - Parameter guard: The last-chance check to ensure a user object exists on a request
            case custom(authenticators: [AsyncAuthenticator], userModelType: any (Authenticatable & Sendable).Type, guard: AsyncMiddleware)
            
            func configure(app: Application, base: String) async throws
            {
                switch self
                {
                case .passage(let origin):
                    let store = DatabaseStore(app: app, db: app.db)
                    try await app.passage.configure(
                        services: .init(store: store, emailDelivery: nil, phoneDelivery: nil),
                        configuration: .init(
                            origin: origin,
                            routes: .init(group: "\(base)"),
                            sessions: .init(enabled: true),
                            throttle: .init(login: .init(
                                perIdentifier: .init(maxFailures: 5, window: 15 * 60),   // 5 failures / 15 min per account
                                perSource: .init(maxFailures: 5, window: 15 * 60),       // 5 failures / 15 min per IP
                                enabled: true)),
                            views: .init(login: .init(
                                style: .minimalism,
                                theme: .init(colors: .mintDark),
                                redirect: .init(onSuccess: "/\(base)/"),
                                identifier: .username)))
                    )
                    
                case .passageCustom(let services, let configuration, _):
                    try await app.passage.configure(services: services, configuration: configuration)
                    
                case .custom, .passagePreConfigured:
                    break
                }
            }
        }
        
        public let authentication : Authentication
        public let base : String = "admin"
    }
}

/// Entry point into the Admin Portal
public struct Admin : Sendable
{
    let databaseManager : ModelCoordinator
    
    init(database: Database)
    {
        databaseManager = .init(database: database) { modelType in
            func makeModelBox<ModelType: AdminModel>(_ model: ModelType.Type) -> any ModelBox
            {
                _ModelBox<ModelType>(database: database)
            }
            return makeModelBox(modelType)
        }
    }
    
    /// Configures the admin portal
    ///
    /// * Registers leaf templates
    /// * Adds admin routes to the app's router
    /// * Configures, if necessary, any authentication (`Passage` unless a custom authentication is provided)
    ///
    /// - Parameters:
    ///    - app: The `Vapor` application
    ///    - configuration: The ``Configuration`` for `VaporAdmin`
    public func configure(app: Application, configuration: Configuration) async throws
    {
        try registerLeafTemplates(on: app)
        try await configuration.authentication.configure(app: app, base: configuration.base)
        try app.register(collection: AdminController(app: app, configuration: configuration))
    }
    
    private func registerLeafTemplates(on app: Application) throws
    {
        let resourcePath = Bundle.module.resourcePath!
        let sources = app.leaf.sources
        try sources.register(
            source: "leaf",
            using: NIOLeafFiles(
                fileio: app.fileio,
                limits: .default,
                sandboxDirectory: "\(resourcePath)/Views",
                viewDirectory: "\(resourcePath)/Views"
            )
        )
        app.leaf.sources = sources
    }
    
    /// Register a `Model` for management through the admin portal
    ///
    /// To register a compatible model, add the ``AdminDisplayable()`` macro to the `Model`.
    public func register<T: AdminModel>(_ model: T.Type)
    {
        databaseManager.register(model)
    }
}

private struct VaporAdminStorageKey : StorageKey
{
    typealias Value = Admin
}

extension Application
{
    /// Entry point into the Admin Portal
    public var admin : Admin
    {
        self.storage[VaporAdminStorageKey.self, default: Admin(database: self.db)]
    }
}

import Vapor
import Leaf
import Fluent
import LeafKit

/// Add this macro to any `Model` to enable Admin Site management.
///
/// Models managed by the Admin Site will be eligible for CRUD operations
/// - Note: The Admin Site will attempt to use the `description` property for display.
///         If this doesn't make sense for your use case, conform your `Model` to ``CustomAdminDisplayable`` to provide the Admin Site a custom description
@attached(member, names: named(adminMetadata)) @attached(extension, conformances: FluentAdminDisplay)
public macro AdminDisplayable() = #externalMacro(module: "VaporAdminMacros", type: "AdminDisplayableMacro")

/// A type with a customized textual representation for the Admin Site
public protocol CustomAdminDisplayable
{
    /// A textual representation of this instance suitable for the Admin Site
    var displayString : String { get }
}

/// To conform a Model to `FluentAdminDisplay`, add the ``@AdminDisplayable`` macro.
public typealias AdminModel = FluentAdminDisplay & Model

/// Entry point into the Admin Site.  Call ``configure(app:configuration:)`` to configure the Admin Site and ``register(_:)`` to register a model for CRUD management
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
    
    /// Configures the Admin Site
    ///
    /// * Registers leaf templates
    /// * Adds admin routes to your app's router
    /// * Configures, if necessary, any authentication (`Passage` unless a custom authentication is provided)
    ///
    /// - Parameters:
    ///    - app: The `Vapor` application
    ///    - configuration: The ``Configuration`` for the Admin Site
    public func configure(app: Application, configuration: Configuration) async throws
    {
        try registerLeafTemplates(on: app)
        try await configuration.authentication.configureIfNeeded(app: app, adminSiteBasePath: configuration.base)
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
    
    /// Register a `Model` for management through the Admin Site
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
    /// Entry point into the Admin Site
    public var admin : Admin
    {
        self.storage[VaporAdminStorageKey.self, default: Admin(database: self.db)]
    }
}

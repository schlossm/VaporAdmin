import Vapor
import Leaf
import Fluent
import LeafKit

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

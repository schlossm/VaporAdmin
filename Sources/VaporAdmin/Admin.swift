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

/// Entry point into the Admin Portal
public struct Admin : Sendable
{
    package let databaseManager : AdminDatabaseManager
    
    package init(database: Database)
    {
        databaseManager = .init(database: database)
    }
    
    /// Configures the admin portal
    ///
    /// `VaporAdmin` uses `Passage` to manage admin users
    /// * Registers leaf templates
    /// * Adds admin routes to the app's router
    /// * Configures `Passage` for user authentication
    public func configure(app: Application, origin: URL) async throws
    {
        try registerLeafTemplates(on: app)
        try app.register(collection: AdminController(app: app))
        
        // Set up your database store
        let store = DatabaseStore(app: app, db: app.db)
        
        // Configure Passage
        try await app.passage.configure(
            services: .init(store: store, emailDelivery: nil, phoneDelivery: nil),
            configuration: .init(
                origin: origin,
                routes: .init(group: "admin"),
                sessions: .init(enabled: true),
                views: .init(
                    login: .init(
                        style: .minimalism,
                        theme: .init(
                            colors: .mintDark
                        ),
                        redirect: .init(onSuccess: "/admin/"),
                        identifier: .username
                    )
                )
            )
        )
    }
    
    private func registerLeafTemplates(on app: Application) throws
    {
        guard let resourcePath = Bundle.module.resourcePath else {
            throw AdminError.unexpected(message: "Could not locate resource path for VaporAdmin module.")
        }
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
    /// - Warning: Due to interop with HTML + JS, the `Model`'s `IDValue` must also conform to ``LosslessStringConvertible``.  Most common `IDValue` types already do
    public func register<T: FluentAdminDisplay & Model>(_ model: T.Type) where T.IDValue : LosslessStringConvertible
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

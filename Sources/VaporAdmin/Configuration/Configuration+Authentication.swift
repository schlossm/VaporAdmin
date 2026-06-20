import Foundation
#if Passage
import Passage
#if PassageFluent
import PassageFluent
#endif
#endif
import Vapor

public extension Admin.Configuration
{
    /// Configuration for VaporAdmin's authentication strategy.
    ///
    /// VaporAdmin supports both Passage-based authentication and fully custom authentication strategies, split into initializers:
    /// 1. Fully custom client authentication management through ``Authentication.init(customAuthenticators:userModelType:guard:usernameFromRequest:)``
    /// 2. Providing custom configuration options for Passage through ``Authentication.init(passageCustomServices:contracts:configuration:hooks:userModelType:)``
    ///     * If the "PassageFluent" trait is enabled, and you want to use PassageFluent's models, use ``Authentication.init(passageCustomServices:contracts:configuration:hooks:)`` intead
    /// 3. Directing VaporAdmin to use a client-configured Passage instance with ``Authentication.init(userModelType:)``
    ///     * If the "PassageFluent" trait is enabled, and you want to use PassageFluent's models, use ``Authentication.init()`` intead
    /// 4. Directing VaporAdmin to configure Passage for its own use with ``Authentication.init(passageOriginURL:userModelType:store:)``
    ///     * If the "PassageFluent" trait is enabled, and you want to use PassageFluent's models, use ``Authentication.init(passageOriginURL:)`` intead
    ///
    /// - Warning: If you custom configure Passage or a fully custom authentication strategy, you are responsible for also registering Login [and Register] paths BEFORE configuring VaporAdmin
    struct Authentication : Sendable
    {
        enum State
        {
            #if Passage || PassageFluent
            case passageClientConfigured(userModelType: any (Authenticatable & Sendable).Type)
            case passageUseVaporAdminConfiguration(origin: URL, userModelType: any (Authenticatable & Sendable).Type, store: Passage.Store?)
            case passageUseCustomConfiguration(services: Passage.Services, contracts: Passage.Contracts, configuration: Passage.Configuration, hooks: Passage.Hooks, userModelType: any (Authenticatable & Sendable).Type)
            #endif
            
            case customConfiguration(authenticators: [AsyncAuthenticator], userModelType: any (Authenticatable & Sendable).Type, guard: AsyncMiddleware, usernameFromRequest: @Sendable (Request) throws -> String?)
        }
        
        let state : State
        
        #if Passage
        /// VaporAdmin will use the pre-configured Passage instance from the client's `Application` instance.
        ///
        /// If you enable the "PassageFluent" trait, use ``Authentication.init()`` instead to have VaporAdmin use `PassageFluent`'s user model type
        ///
        /// - Parameter userModelType: The user model `Type` to query with Passage authentication
        public init(userModelType: any (Authenticatable & Sendable).Type)
        {
            state = .passageClientConfigured(userModelType: userModelType)
        }
        
        /// VaporAdmin will configure Passage with suitable defaults for using the Admin Site
        ///
        /// If you enable the "PassageFluent" trait, use ``Authentication.init(passageOriginURL:)`` instead to have VaporAdmin use `PassageFluent`'s user model type
        ///
        /// - Parameter passageOriginURL: The base URL of the server
        /// - Parameter userModelType: The user model `Type` to query with Passage authentication
        /// - Parameter store: A custom Passage `Store` implementation
        public init(passageOriginURL: URL, userModelType: any (Authenticatable & Sendable).Type, store: Passage.Store)
        {
            state = .passageUseVaporAdminConfiguration(origin: passageOriginURL, userModelType: userModelType, store: store)
        }
        
        /// VaporAdmin will configure Passage with the configuration you provide.
        ///
        /// If you enable the "PassageFluent" trait, use ``Authentication.init(passageCustomServices:contacts:configuration:hooks:)`` instead to have VaporAdmin use `PassageFluent`'s user model type
        ///
        /// - Parameter passageCustomServices: A Passage `Services` object.  The minimum required Service is a `Store`
        /// - Parameter contracts: A Passage `Contracts` object.  Defaults to no contracts
        /// - Parameter configuration: A Passage `Configuration` object.  A suitable Configuration sends the logged-in user to `/<Admin.Configuration.base>/` on login, and the login page is expected at `/<Admin.Configuration.base>/login`
        /// - Parameter hooks: A Passage `Hooks` object.  Defaults to no hooks
        /// - Parameter userModelType: The user model `Type` to query with Passage authentication
        public init(passageCustomServices: Passage.Services,
                    contracts: Passage.Contracts = .init(),
                    configuration: Passage.Configuration,
                    hooks: Passage.Hooks = .init(),
                    userModelType: any (Authenticatable & Sendable).Type)
        {
            state = .passageUseCustomConfiguration(services: passageCustomServices, contracts: contracts, configuration: configuration, hooks: hooks, userModelType: userModelType)
        }
        
        #if PassageFluent
        /// VaporAdmin will use the pre-configured Passage instance from the client's `Application` instance.
        ///
        /// If you enable the "PassageFluent" trait, use ``Authentication.init()`` instead to have VaporAdmin use `PassageFluent`'s user model type
        public init()
        {
            state = .passageClientConfigured(userModelType: PassageFluent.UserModel.self)
        }
        
        /// VaporAdmin will configure Passage with suitable defaults for using the Admin Site.
        ///
        /// This option will use `PassageFluent`'s user model type
        ///
        /// - Parameter passageOriginURL: The base URL of the server
        public init(passageOriginURL: URL)
        {
            state = .passageUseVaporAdminConfiguration(origin: passageOriginURL, userModelType: PassageFluent.UserModel.self, store: nil)
        }
        
        /// VaporAdmin will configure Passage with the configuration you provide for the Admin Site.
        ///
        /// This option will use `PassageFluent`'s user model type
        ///
        /// - Parameter passageCustomServices: A Passage `Services` object.  The minimum required Service is a `Store`
        /// - Parameter contracts: A Passage `Contracts` object.  Defaults to no contracts
        /// - Parameter configuration: A Passage `Configuration` object.  A suitable Configuration sends the logged-in user to `/<Admin.Configuration.base>/` on login, and the login page is expected at `/<Admin.Configuration.base>/login`
        /// - Parameter hooks: A Passage `Hooks` object.  Defaults to no hooks
        public init(passageCustomServices: Passage.Services,
                    contracts: Passage.Contracts = .init(),
                    configuration: Passage.Configuration,
                    hooks: Passage.Hooks = .init())
        {
            state = .passageUseCustomConfiguration(services: passageCustomServices, contracts: contracts, configuration: configuration, hooks: hooks, userModelType: PassageFluent.UserModel.self)
        }
        
        #endif
        #endif
        
        /// VaporAdmin will use your own Middleware and `Authenticatable` user model type for the Admin Site.
        ///
        /// - Warning: With this initializer, you are responsible for logging a user in and/or registering new accounts.  VaporAdmin expects login to be at "`/<Admin.Configuration.base>/login`"
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
        /// - Parameter usernameFromRequest: A closure that returns the username for the active user from the provided `Request` object
        public init(customAuthenticators authenticators: [AsyncAuthenticator],
                    userModelType: any (Authenticatable & Sendable).Type,
                    guard: AsyncMiddleware,
                    usernameFromRequest: @escaping @Sendable (Request) throws -> String?)
        {
            state = .customConfiguration(authenticators: authenticators, userModelType: userModelType, guard: `guard`, usernameFromRequest: usernameFromRequest)
        }
        
        func configureIfNeeded(app: Application, adminSiteBasePath: String) async throws
        {
            switch state {
            #if Passage || PassageFluent
            case .passageClientConfigured:
                break
                
            case .passageUseCustomConfiguration(let services, let contracts, let configuration, let hooks, _):
                try await app.passage.configure(services: services, contracts: contracts, configuration: configuration, hooks: hooks)
            
                
            case .passageUseVaporAdminConfiguration(let origin, _, let store):
                #if PassageFluent
                let store = DatabaseStore(app: app, db: app.db)
                #else
                guard let store else { throw AdminError.missingAuthenticationStore }
                #endif
                try await app.passage.configure(
                    services: .init(store: store, emailDelivery: nil, phoneDelivery: nil),
                    configuration: .init(
                        origin: origin,
                        routes: .init(group: "\(adminSiteBasePath)"),
                        sessions: .init(enabled: true),
                        throttle: .init(login: .init(
                            perIdentifier: .init(maxFailures: 5, window: 15 * 60),   // 5 failures / 15 min per account
                            perSource: .init(maxFailures: 5, window: 15 * 60),       // 5 failures / 15 min per IP
                            enabled: true)),
                        views: .init(login: .init(
                            style: .minimalism,
                            theme: .init(colors: .mintDark),
                            redirect: .init(onSuccess: "/\(adminSiteBasePath)/"),
                            identifier: .username)))
                )
            #endif

            case .customConfiguration:
                break
            }
        }
    }
}

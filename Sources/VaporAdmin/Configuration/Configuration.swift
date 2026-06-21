import Foundation
#if Passage
import Passage
#if PassageFluent
import PassageFluent
#endif
#endif
import Vapor

public extension Admin
{
    /// The Admin Site configuration interface
    ///
    /// Currently, you can configure the following items:
    /// * The authentication model to be used
    /// * The base group for routes.  Defaults to "admin"
    struct Configuration : Sendable
    {
        public let authentication : Authentication
        public let base : String
        
        /// Creates an Admin Site configuration with the provided authentication strategy and base path
        ///
        /// - Parameters:
        ///   - authentication: The authentication strategy for the Admin Site to use
        ///   - base: The base path to register the Admin Site urls against.  Defaults to "admin"
        public init(authentication: Authentication, base: String = "admin")
        {
            self.authentication = authentication
            self.base = base
        }
        
        #if PassageFluent
        /// Creates an Admin Site configuration using `Passage` and `PassageFluent` as the authentication strategy
        ///
        /// This initializer configures `Passage` on your app's behalf.  To customize `Passage` configuration, or to use your
        /// own authentication strategy, use ``init(authentication:base:)`` instead
        /// - Parameters:
        ///   - originURL: The host URL of your app
        ///   - base: The base path to register the Admin Site urls against.  Defaults to "admin"
        public init(originURL: URL, base: String = "admin")
        {
            self.authentication = .init(passageOriginURL: originURL)
            self.base = base
        }
        #endif
    }
}

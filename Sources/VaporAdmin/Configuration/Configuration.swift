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
    /// The `VaporAdmin` configuration interface
    ///
    /// Currently, you can configure the following items:
    /// * The authentication model to be used
    /// * The base group for routes.  Defaults to "admin".  Ignored if the authentcation strategy is provided custom implementiation / custom passage configuration
    struct Configuration : Sendable
    {
        public let authentication : Authentication
        public let base : String = "admin"
    }
}

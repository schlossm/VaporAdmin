public enum AdminError : Error, Equatable
{
    case couldNotFindModel
    case couldNotFindInstance
    case invalidInput
    case unexpected(message: String)
    case missingAuthenticationStore
}

import Fluent

extension DatabaseQuery.Value
{
    func bind<T>() -> T?
    {
        switch self {
        case .bind(let bind):
            return bind as? T
        default: return nil
        }
    }
}

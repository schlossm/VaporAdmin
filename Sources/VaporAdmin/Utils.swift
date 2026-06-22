protocol OptionalProtocol
{
    static func wrappedType() -> Any.Type
    
    func getValue<T>() -> T?
}

extension Optional : OptionalProtocol
{
    static func wrappedType() -> Any.Type
    {
        return Wrapped.self
    }
    
    func getValue<T>() -> T?
    {
        switch self
        {
        case .none:
            return nil
            
        case .some(let wrapped):
            if let wrapped = wrapped as? OptionalProtocol
            {
                return wrapped.getValue()
            }
            return (wrapped as! T)
        }
    }
}

enum DiffOperation {
    case equal
    case delete
    case insert

    var isChange: Bool {
        switch self {
        case .equal:
            return false
        case .delete, .insert:
            return true
        }
    }
}

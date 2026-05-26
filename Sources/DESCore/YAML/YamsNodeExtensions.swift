import Yams

extension Node {
    var mappingKey: String? {
        if case .scalar(let scalar) = self {
            return scalar.string
        }
        return nil
    }

    var string: String? {
        if case .scalar(let scalar) = self, scalar.tag.rawValue == Tag.Name.str.rawValue {
            return scalar.string
        }
        return nil
    }

    var sequence: Node.Sequence? {
        if case .sequence(let sequence) = self {
            return sequence
        }
        return nil
    }
}

extension Node.Mapping {
    var pairs: [(String, Node)] {
        map { key, value in
            (key.mappingKey ?? "", value)
        }
    }

    subscript(_ key: String) -> Node? {
        first { item, _ in item.mappingKey == key }?.1
    }
}

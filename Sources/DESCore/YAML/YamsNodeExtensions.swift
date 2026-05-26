import Yams

extension Node {
    var string: String? {
        if case .scalar(let scalar) = self, scalar.tag.rawValue == Tag.Name.str.rawValue {
            return scalar.string
        }
        return nil
    }
}

extension Node.Mapping {
    var pairs: [(String, Node)] {
        map { key, value in
            (key.string ?? "", value)
        }
    }

    subscript(_ key: String) -> Node? {
        first { item, _ in item.string == key }?.1
    }
}

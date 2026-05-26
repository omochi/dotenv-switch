final class TemplateResolver {
    private let rawVariables: [String: String]
    private var resolved: [String: String] = [:]
    private var resolving: Set<String> = []

    init(rawVariables: [KeyValue]) {
        self.rawVariables = Dictionary(uniqueKeysWithValues: rawVariables.map { ($0.key, $0.value) })
    }

    init(rawVariables: [String: String]) {
        self.rawVariables = rawVariables
    }

    func resolveAll() throws -> [String: String] {
        for name in rawVariables.keys {
            _ = try resolve(name)
        }
        return resolved
    }

    func render(_ template: String) throws -> String {
        var output = ""
        var index = template.startIndex
        while index < template.endIndex {
            if template[index...].hasPrefix("${{") {
                guard let end = template[index...].range(of: "}}") else {
                    throw DotEnvSwitchError.unterminatedExpression
                }
                let expressionStart = template.index(index, offsetBy: 3)
                let name = template[expressionStart..<end.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                output += try resolve(name)
                index = end.upperBound
            } else {
                output.append(template[index])
                index = template.index(after: index)
            }
        }
        return output
    }

    private func resolve(_ name: String) throws -> String {
        if let value = resolved[name] {
            return value
        }
        guard let raw = rawVariables[name] else {
            throw DotEnvSwitchError.undefinedVariable(name)
        }
        if resolving.contains(name) {
            throw DotEnvSwitchError.cyclicVariable(name)
        }
        resolving.insert(name)
        let value = try render(raw)
        resolving.remove(name)
        resolved[name] = value
        return value
    }
}

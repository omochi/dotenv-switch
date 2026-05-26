import Foundation
import Yams

public struct DotEnvSwitch {
    private var config: DotEnvSwitchConfig

    public init(config: DotEnvSwitchConfig) {
        self.config = config
    }

    public func list() throws -> [String] {
        let document = try loadDocument()
        return collectOutPaths(in: document, prefix: [])
    }

    public func show(path: String) throws -> String {
        let values = try resolvedOut(path: path)
        return values.map { "\($0.key)=\(DotEnvFileValueFormatter.format($0.value))" }
            .joined(separator: "\n")
    }

    public func render(path: String) throws -> String {
        try render(paths: [path])
    }

    public func render(paths: [String]) throws -> String {
        let document = try loadDocument()
        var target = try readFile(config.targetURL)
        for path in paths {
            let values = try resolvedOut(path: path, document: document)
            target = DotEnvFileEditor.update(target, values: values)
        }
        return target
    }

    public func apply(path: String) throws -> String {
        try apply(paths: [path])
    }

    public func apply(paths: [String]) throws -> String {
        let rendered = try render(paths: paths)
        try rendered.write(to: config.targetURL, atomically: true, encoding: .utf8)
        if config.quiet {
            return ""
        }
        return "Updated \(config.target) with \(paths.joined(separator: ", "))."
    }

    public func diff(path: String) throws -> String {
        try diff(paths: [path])
    }

    public func diff(paths: [String]) throws -> String {
        let original = try readFile(config.targetURL)
        let rendered = try render(paths: paths)
        return UnifiedDiff.make(
            old: original,
            new: rendered,
            oldName: config.target,
            newName: "\(config.target) (\(paths.joined(separator: ", ")))"
        )
    }

    private func resolvedOut(path: String) throws -> [KeyValue] {
        let document = try loadDocument()
        return try resolvedOut(path: path, document: document)
    }

    private func resolvedOut(path: String, document: Node) throws -> [KeyValue] {
        let node = try node(at: path, in: document)
        guard let outNode = node.mapping?["out"] else {
            throw DotEnvSwitchError.missingOut(path)
        }

        let topVariables = try stringMapping(document.mapping?["var"], name: "var") ?? []
        let localVariables = try stringMapping(node.mapping?["var"], name: "var") ?? []
        let rawOut = try requiredStringMapping(outNode, name: "out")
        let variables = mergeVariables(topVariables, localVariables)
        let resolver = TemplateResolver(rawVariables: variables)
        let resolvedVars = try resolver.resolveAll()
        let outResolver = TemplateResolver(rawVariables: resolvedVars)
        return try rawOut.map { item in
            KeyValue(key: item.key, value: try outResolver.render(item.value))
        }
    }

    private func loadDocument() throws -> Node {
        let source = try readFile(config.sourceURL)
        do {
            return try Yams.compose(yaml: source) ?? Node.mapping([:])
        } catch let error as DotEnvSwitchError {
            throw error
        } catch {
            throw DotEnvSwitchError.invalidYAML(String(describing: error))
        }
    }

    private func readFile(_ url: URL) throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DotEnvSwitchError.fileNotFound(url.path)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func node(at path: String, in document: Node) throws -> Node {
        let components = path.split(separator: ".").map(String.init)
        var current = document
        for component in components {
            guard let next = current.mapping?[component] else {
                throw DotEnvSwitchError.pathNotFound(path)
            }
            current = next
        }
        return current
    }

    private func collectOutPaths(in node: Node, prefix: [String]) -> [String] {
        guard let mapping = node.mapping else {
            return []
        }

        var result: [String] = []
        if mapping["out"] != nil, !prefix.isEmpty {
            result.append(prefix.joined(separator: "."))
        }

        for (key, child) in mapping.pairs {
            guard key != "var", key != "out" else {
                continue
            }
            result.append(contentsOf: collectOutPaths(in: child, prefix: prefix + [key]))
        }
        return result
    }

    private func stringMapping(_ node: Node?, name: String) throws -> [KeyValue]? {
        guard let node else {
            return nil
        }
        return try requiredStringMapping(node, name: name)
    }

    private func requiredStringMapping(_ node: Node, name: String) throws -> [KeyValue] {
        guard let mapping = node.mapping else {
            throw DotEnvSwitchError.invalidMapping(name)
        }
        return try mapping.pairs.map { key, value in
            guard let string = value.string else {
                throw DotEnvSwitchError.invalidStringValue(name + "." + key)
            }
            return KeyValue(key: key, value: string)
        }
    }

    private func mergeVariables(_ top: [KeyValue], _ local: [KeyValue]) -> [KeyValue] {
        var result = top
        for item in local {
            if let index = result.firstIndex(where: { $0.key == item.key }) {
                result[index] = item
            } else {
                result.append(item)
            }
        }
        return result
    }
}

import Foundation

public struct DotEnvSwitchConfig: Equatable {
    public var project: URL
    public var source: String
    public var target: String
    public var quiet: Bool

    public init(
        project: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
        source: String = "envs.yml",
        target: String = ".env",
        quiet: Bool = false
    ) {
        self.project = project
        self.source = source
        self.target = target
        self.quiet = quiet
    }

    public var sourceURL: URL {
        resolve(source)
    }

    public var targetURL: URL {
        resolve(target)
    }

    private func resolve(_ path: String) -> URL {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }
        return project.appendingPathComponent(path)
    }
}

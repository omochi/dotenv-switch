import ArgumentParser
import DESCore

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List paths that have an out mapping."
    )

    @OptionGroup
    var options: CommonOptions

    mutating func run() throws {
        let output = try DotEnvSwitch(config: options.config).list().joined(separator: "\n")
        printIfNeeded(output)
    }
}

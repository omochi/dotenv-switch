import ArgumentParser
import DESCore

struct Show: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Print resolved changes for a path."
    )

    @Argument(help: "The dot-separated path to show, such as network.home.")
    var path: String

    @OptionGroup
    var options: CommonOptions

    mutating func run() throws {
        let output = try DotEnvSwitch(config: options.config).show(path: path)
        printIfNeeded(output)
    }
}

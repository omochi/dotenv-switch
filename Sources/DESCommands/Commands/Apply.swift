import ArgumentParser
import DESCore

struct Apply: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apply",
        abstract: "Apply resolved out values to the target dotenv file.",
        shouldDisplay: false
    )

    @Argument(
        help: "The dot-separated paths to apply, such as network.home network.office."
    )
    var paths: [String]

    @Flag(help: "Print diff instead of writing the target dotenv file.")
    var dryRun = false

    @OptionGroup
    var options: CommonOptions

    func validate() throws {
        if paths.isEmpty {
            throw ValidationError("At least one path is required.")
        }
    }

    mutating func run() throws {
        let tool = DotEnvSwitch(config: options.config)
        let output =
            try dryRun
            ? tool.diff(paths: paths)
            : tool.apply(paths: paths)
        printIfNeeded(output)
    }
}

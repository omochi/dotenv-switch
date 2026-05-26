import ArgumentParser
import DESCore

struct Diff: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Print the diff that would be applied to the target dotenv file."
    )

    @Argument(help: "The dot-separated path to diff, such as network.home.")
    var path: String

    @OptionGroup
    var options: CommonOptions

    mutating func run() throws {
        let output = try DotEnvSwitch(config: options.config).diff(path: path)
        printIfNeeded(output)
    }
}

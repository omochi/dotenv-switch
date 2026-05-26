import ArgumentParser
import DESCore
import Foundation

struct CommonOptions: ParsableArguments {
    @Option(help: "Source YAML path.")
    var source = "envs.yml"

    @Option(help: "Target dotenv path.")
    var target = ".env"

    @Option(help: "Project directory.")
    var project = "."

    @Flag(help: "Suppress success messages.")
    var quiet = false

    var config: DotEnvSwitchConfig {
        DotEnvSwitchConfig(
            project: URL(fileURLWithPath: project),
            source: source,
            target: target,
            quiet: quiet
        )
    }
}

import ArgumentParser

public struct DotEnvSwitchCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "dotenv-switch",
        abstract: "Apply changes from envs.yml to an existing .env file.",
        usage: """
            dotenv-switch <paths> ... [--dry-run] [--source <source>] [--target <target>] [--project <project>] [--quiet]
            dotenv-switch <subcommand>
            """,
        version: "0.1.0",
        subcommands: [
            Apply.self,
            List.self,
            Show.self,
            Diff.self,
        ],
        defaultSubcommand: Apply.self
    )

    public init() {}
}

import DESCore
import Foundation
import Testing

@Suite
struct DotEnvSwitchTests {
    @Test func listReturnsOnlyOutNodesInYamlOrder() throws {
        let fixture = try Fixture(
            envs: """
                var:
                  host: "192.168.1.2"
                network:
                  home:
                    out:
                      API_URL: "http://${{ host }}"
                  group:
                    office:
                      out:
                        API_URL: "http://192.168.10.23"
                """
        )

        let paths = try fixture.tool.list()

        #expect(paths == ["network.home", "network.group.office"])
    }

    @Test func showResolvesTopLevelAndLocalVariables() throws {
        let fixture = try Fixture(
            envs: """
                var:
                  scheme: "http"
                  host: "192.168.1.2"
                  baseURL: "${{ scheme }}://${{ host }}"
                network:
                  office:
                    var:
                      host: "192.168.10.23"
                      baseURL: "${{ scheme }}://${{ host }}"
                    out:
                      API_URL: "${{ baseURL }}"
                """
        )

        let output = try fixture.tool.show(path: "network.office")

        #expect(output == "API_URL=http://192.168.10.23")
    }

    @Test func applyUpdatesLastExistingDefinition() throws {
        let fixture = try Fixture(
            envs: """
                network:
                  home:
                    out:
                      API_URL: "http://192.168.1.2"
                """,
            dotEnv: """
                API_URL=http://old-1
                TOKEN=abc
                API_URL=http://old-2
                """
        )

        _ = try fixture.tool.apply(path: "network.home")

        #expect(
            try fixture.readDotEnv() == """
                API_URL=http://old-1
                TOKEN=abc
                API_URL=http://192.168.1.2
                """
        )
    }

    @Test func applyInsertsAfterLastCommentedDefinition() throws {
        let fixture = try Fixture(
            envs: """
                network:
                  home:
                    out:
                      API_URL: "http://192.168.1.2"
                """,
            dotEnv: """
                # API_URL=http://example-1
                TOKEN=abc
                # API_URL=http://example-2
                OTHER=value
                """
        )

        _ = try fixture.tool.apply(path: "network.home")

        #expect(
            try fixture.readDotEnv() == """
                # API_URL=http://example-1
                TOKEN=abc
                # API_URL=http://example-2
                API_URL=http://192.168.1.2
                OTHER=value
                """
        )
    }

    @Test func applyMultiplePathsInOrder() throws {
        let fixture = try Fixture(
            envs: """
                network:
                  home:
                    out:
                      API_URL: "http://192.168.1.2"
                      TOKEN: "home-token"
                  office:
                    out:
                      API_URL: "http://192.168.10.23"
                """,
            dotEnv: """
                API_URL=http://localhost:3000
                TOKEN=abc
                """
        )

        _ = try fixture.tool.apply(paths: ["network.home", "network.office"])

        #expect(
            try fixture.readDotEnv() == """
                API_URL=http://192.168.10.23
                TOKEN=home-token
                """
        )
    }

    @Test func showFormatsHashNewlineAndBackslashValues() throws {
        let fixture = try Fixture(
            envs: """
                network:
                  home:
                    out:
                      HASH: "abc#def"
                      MULTILINE: "line1\\nline2"
                      PATH: "C:\\\\Users\\\\omochi#home"
                """
        )

        let output = try fixture.tool.show(path: "network.home")

        #expect(
            output == """
                HASH="abc#def"
                MULTILINE="line1\\nline2"
                PATH="C:\\\\Users\\\\omochi#home"
                """
        )
    }

    @Test func diffShowsUnifiedDiffWithoutChangingTarget() throws {
        let fixture = try Fixture(
            envs: """
                network:
                  home:
                    out:
                      API_URL: "http://192.168.1.2"
                """,
            dotEnv: """
                # API endpoint
                API_URL=http://localhost:3000
                """
        )

        let output = try fixture.tool.diff(path: "network.home")

        #expect(
            output == """
                --- .env
                +++ .env (network.home)
                @@ -1,2 +1,2 @@
                 # API endpoint
                -API_URL=http://localhost:3000
                +API_URL=http://192.168.1.2

                """
        )
        #expect(
            try fixture.readDotEnv() == """
                # API endpoint
                API_URL=http://localhost:3000
                """
        )
    }

    @Test func nonStringOutValueFails() throws {
        let fixture = try Fixture(
            envs: """
                network:
                  home:
                    out:
                      PORT: 8080
                """
        )

        #expect(throws: DotEnvSwitchError.invalidStringValue("out.PORT")) {
            _ = try fixture.tool.show(path: "network.home")
        }
    }

    private struct Fixture {
        var directory: URL
        var config: DotEnvSwitchConfig
        var tool: DotEnvSwitch {
            DotEnvSwitch(config: config)
        }

        init(envs: String, dotEnv: String = "") throws {
            directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("dotenv-switch-tests")
                .appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try envs.write(
                to: directory.appendingPathComponent("envs.yml"),
                atomically: true,
                encoding: .utf8
            )
            try dotEnv.write(
                to: directory.appendingPathComponent(".env"),
                atomically: true,
                encoding: .utf8
            )
            config = DotEnvSwitchConfig(project: directory)
        }

        func readDotEnv() throws -> String {
            try String(contentsOf: directory.appendingPathComponent(".env"), encoding: .utf8)
        }
    }
}

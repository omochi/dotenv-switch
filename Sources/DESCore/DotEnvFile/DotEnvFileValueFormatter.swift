enum DotEnvFileValueFormatter {
    static func format(_ value: String) -> String {
        let needsQuotes = value.contains("#") || value.contains("\n")
        guard needsQuotes else {
            return value
        }

        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}

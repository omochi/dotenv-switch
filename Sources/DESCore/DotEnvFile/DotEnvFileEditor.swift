import Foundation

enum DotEnvFileEditor {
    static func update(_ content: String, change: DotEnvChange) -> String {
        var lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let hadTrailingNewline = content.hasSuffix("\n")
        if hadTrailingNewline {
            lines.removeLast()
        }

        for key in change.deletions {
            if lines.contains(where: { commentedDefinitionKey(in: $0) == key }) {
                lines.removeAll { line in
                    definitionKey(in: line) == key
                }
            } else {
                for index in lines.indices where definitionKey(in: lines[index]) == key {
                    lines[index] = "# " + lines[index]
                }
            }
        }

        for value in change.values {
            let newLine = "\(value.key)=\(DotEnvFileValueFormatter.format(value.value))"
            if let index = lines.indices.reversed().first(where: { definitionKey(in: lines[$0]) == value.key }) {
                lines[index] = newLine
                continue
            }

            if let index = lines.indices.reversed().first(where: { commentedDefinitionKey(in: lines[$0]) == value.key }) {
                lines.insert(newLine, at: lines.index(after: index))
            } else {
                lines.append(newLine)
            }
        }

        let result = lines.joined(separator: "\n")
        if hadTrailingNewline || content.isEmpty {
            return result + "\n"
        }
        return result
    }

    private static func definitionKey(in line: String) -> String? {
        guard let equals = line.firstIndex(of: "=") else {
            return nil
        }
        let key = String(line[..<equals])
        guard isDotEnvKey(key) else {
            return nil
        }
        return key
    }

    private static func commentedDefinitionKey(in line: String) -> String? {
        guard line.hasPrefix("#") else {
            return nil
        }
        let start = line.index(after: line.startIndex)
        let rest = String(line[start...]).trimmingCharacters(in: .whitespaces)
        return definitionKey(in: rest)
    }

    private static func isDotEnvKey(_ key: String) -> Bool {
        guard let first = key.unicodeScalars.first else {
            return false
        }
        guard first == "_" || CharacterSet.letters.contains(first) else {
            return false
        }
        return key.unicodeScalars.allSatisfy {
            $0 == "_" || CharacterSet.alphanumerics.contains($0)
        }
    }
}

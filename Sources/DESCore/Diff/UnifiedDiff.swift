struct UnifiedDiff {
    static func make(old: String, new: String, oldName: String, newName: String) -> String {
        guard old != new else {
            return ""
        }
        let oldLines = splitLines(old)
        let newLines = splitLines(new)
        let operations = diff(oldLines, newLines)

        var output: [String] = [
            "--- \(oldName)",
            "+++ \(newName)",
            "@@ -1,\(oldLines.count) +1,\(newLines.count) @@",
        ]

        for operation in operations {
            switch operation {
            case .equal(let line):
                output.append(" \(line)")
            case .delete(let line):
                output.append("-\(line)")
            case .insert(let line):
                output.append("+\(line)")
            }
        }
        return output.joined(separator: "\n") + "\n"
    }

    private static func splitLines(_ string: String) -> [String] {
        var lines = string.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if string.hasSuffix("\n") {
            lines.removeLast()
        }
        return lines
    }

    private static func diff(_ old: [String], _ new: [String]) -> [Operation] {
        var table = Array(
            repeating: Array(repeating: 0, count: new.count + 1),
            count: old.count + 1
        )
        for i in stride(from: old.count - 1, through: 0, by: -1) where old.count > 0 {
            for j in stride(from: new.count - 1, through: 0, by: -1) where new.count > 0 {
                if old[i] == new[j] {
                    table[i][j] = table[i + 1][j + 1] + 1
                } else {
                    table[i][j] = max(table[i + 1][j], table[i][j + 1])
                }
            }
        }

        var result: [Operation] = []
        var i = 0
        var j = 0
        while i < old.count, j < new.count {
            if old[i] == new[j] {
                result.append(.equal(old[i]))
                i += 1
                j += 1
            } else if table[i + 1][j] >= table[i][j + 1] {
                result.append(.delete(old[i]))
                i += 1
            } else {
                result.append(.insert(new[j]))
                j += 1
            }
        }
        while i < old.count {
            result.append(.delete(old[i]))
            i += 1
        }
        while j < new.count {
            result.append(.insert(new[j]))
            j += 1
        }
        return result
    }

    private enum Operation {
        case equal(String)
        case delete(String)
        case insert(String)
    }
}

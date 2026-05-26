struct UnifiedDiff {
    private static let contextLineCount = 3

    static func make(old: String, new: String, oldName: String, newName: String) -> String {
        guard old != new else {
            return ""
        }
        let oldLines = splitLines(old)
        let newLines = splitLines(new)
        let operations = numbered(diff(oldLines, newLines))
        let hunks = makeHunks(operations)

        var output: [String] = [
            "--- \(oldName)",
            "+++ \(newName)",
        ]

        for hunk in hunks {
            output.append(hunk.header)
            for operation in hunk.operations {
                output.append(operation.line)
            }
        }
        return output.joined(separator: "\n") + "\n"
    }

    private static func makeHunks(_ operations: [NumberedOperation]) -> [Hunk] {
        let changeIndices = operations.indices.filter { operations[$0].operation.isChange }
        guard !changeIndices.isEmpty else {
            return []
        }

        var ranges: [ClosedRange<Int>] = []
        for index in changeIndices {
            let start = max(operations.startIndex, index - contextLineCount)
            let end = min(operations.index(before: operations.endIndex), index + contextLineCount)
            if let last = ranges.last, start <= last.upperBound + 1 {
                ranges[ranges.index(before: ranges.endIndex)] = last.lowerBound...max(last.upperBound, end)
            } else {
                ranges.append(start...end)
            }
        }

        return ranges.map { range in
            Hunk(operations: Array(operations[range]))
        }
    }

    private static func numbered(_ operations: [Operation]) -> [NumberedOperation] {
        var oldLine = 1
        var newLine = 1
        return operations.map { operation in
            let result: NumberedOperation
            switch operation {
            case .equal(let line):
                result = NumberedOperation(
                    operation: operation,
                    oldLine: oldLine,
                    newLine: newLine,
                    oldAnchor: oldLine,
                    newAnchor: newLine,
                    line: " \(line)"
                )
                oldLine += 1
                newLine += 1
            case .delete(let line):
                result = NumberedOperation(
                    operation: operation,
                    oldLine: oldLine,
                    newLine: nil,
                    oldAnchor: oldLine,
                    newAnchor: newLine,
                    line: "-\(line)"
                )
                oldLine += 1
            case .insert(let line):
                result = NumberedOperation(
                    operation: operation,
                    oldLine: nil,
                    newLine: newLine,
                    oldAnchor: oldLine,
                    newAnchor: newLine,
                    line: "+\(line)"
                )
                newLine += 1
            }
            return result
        }
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

        var isChange: Bool {
            switch self {
            case .equal:
                return false
            case .delete, .insert:
                return true
            }
        }
    }

    private struct NumberedOperation {
        var operation: Operation
        var oldLine: Int?
        var newLine: Int?
        var oldAnchor: Int
        var newAnchor: Int
        var line: String
    }

    private struct Hunk {
        var operations: [NumberedOperation]

        var header: String {
            let oldLines = operations.compactMap(\.oldLine)
            let newLines = operations.compactMap(\.newLine)
            let oldStart = oldLines.first ?? operations.first?.oldAnchor ?? 0
            let newStart = newLines.first ?? operations.first?.newAnchor ?? 0
            return "@@ -\(oldStart),\(oldLines.count) +\(newStart),\(newLines.count) @@"
        }
    }
}

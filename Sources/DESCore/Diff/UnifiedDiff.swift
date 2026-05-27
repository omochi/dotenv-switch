struct UnifiedDiff {
    private static let contextLineCount = 3

    static func make(old: String, new: String, oldName: String, newName: String) -> String {
        guard old != new else {
            return ""
        }
        let oldLines = splitLines(old)
        let newLines = splitLines(new)
        let lines = numbered(diff(oldLines, newLines))
        let hunks = makeHunks(lines)

        var output: [String] = [
            "--- \(oldName)",
            "+++ \(newName)",
        ]

        for hunk in hunks {
            output.append(hunk.header)
            for line in hunk.lines {
                output.append(line.content)
            }
        }
        return output.joined(separator: "\n") + "\n"
    }

    private static func makeHunks(_ lines: [NumberedDiffLine]) -> [DiffHunk] {
        let changeIndices = lines.indices.filter { lines[$0].line.operation.isChange }
        guard !changeIndices.isEmpty else {
            return []
        }

        var ranges: [ClosedRange<Int>] = []
        for index in changeIndices {
            let start = max(lines.startIndex, index - contextLineCount)
            let end = min(lines.index(before: lines.endIndex), index + contextLineCount)
            if let last = ranges.last, start <= last.upperBound + 1 {
                ranges[ranges.index(before: ranges.endIndex)] = last.lowerBound...max(last.upperBound, end)
            } else {
                ranges.append(start...end)
            }
        }

        return ranges.map { range in
            DiffHunk(lines: Array(lines[range]))
        }
    }

    private static func numbered(_ lines: [DiffLine]) -> [NumberedDiffLine] {
        var oldLine = 1
        var newLine = 1
        return lines.map { line in
            let result: NumberedDiffLine
            switch line.operation {
            case .equal:
                result = NumberedDiffLine(
                    line: line,
                    oldLine: oldLine,
                    newLine: newLine,
                    oldAnchor: oldLine,
                    newAnchor: newLine,
                    content: " \(line.content)"
                )
                oldLine += 1
                newLine += 1
            case .delete:
                result = NumberedDiffLine(
                    line: line,
                    oldLine: oldLine,
                    newLine: nil,
                    oldAnchor: oldLine,
                    newAnchor: newLine,
                    content: "-\(line.content)"
                )
                oldLine += 1
            case .insert:
                result = NumberedDiffLine(
                    line: line,
                    oldLine: nil,
                    newLine: newLine,
                    oldAnchor: oldLine,
                    newAnchor: newLine,
                    content: "+\(line.content)"
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

    private static func diff(_ old: [String], _ new: [String]) -> [DiffLine] {
        let difference = new.difference(from: old)
        var removals: [Int: [String]] = [:]
        var insertions: [Int: [String]] = [:]

        for change in difference {
            switch change {
            case .remove(let offset, let element, _):
                removals[offset, default: []].append(element)
            case .insert(let offset, let element, _):
                insertions[offset, default: []].append(element)
            }
        }

        var result: [DiffLine] = []
        var i = 0
        var j = 0
        while i < old.count || j < new.count {
            if let lines = removals[i] {
                result += lines.map { DiffLine(operation: .delete, content: $0) }
                i += lines.count
            } else if let lines = insertions[j] {
                result += lines.map { DiffLine(operation: .insert, content: $0) }
                j += lines.count
            } else if i < old.count, j < new.count {
                result.append(DiffLine(operation: .equal, content: old[i]))
                i += 1
                j += 1
            } else {
                break
            }
        }
        return result
    }

}

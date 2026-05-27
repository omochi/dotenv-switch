struct DiffHunk {
    var lines: [NumberedDiffLine]

    var header: String {
        let oldLines = lines.compactMap(\.oldLine)
        let newLines = lines.compactMap(\.newLine)
        let oldStart = oldLines.first ?? lines.first?.oldAnchor ?? 0
        let newStart = newLines.first ?? lines.first?.newAnchor ?? 0
        return "@@ -\(oldStart),\(oldLines.count) +\(newStart),\(newLines.count) @@"
    }
}

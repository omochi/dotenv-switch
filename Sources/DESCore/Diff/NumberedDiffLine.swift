struct NumberedDiffLine {
    var line: DiffLine
    var oldLine: Int?
    var newLine: Int?
    var oldAnchor: Int
    var newAnchor: Int
    var content: String
}

import Foundation

public enum DotEnvSwitchError: Error, CustomStringConvertible, Equatable {
    case invalidArguments(String)
    case fileNotFound(String)
    case invalidYAML(String)
    case pathNotFound(String)
    case missingOperation(String)
    case invalidMapping(String)
    case invalidSequence(String)
    case invalidStringValue(String)
    case undefinedVariable(String)
    case cyclicVariable(String)
    case unterminatedExpression

    public var description: String {
        switch self {
        case .invalidArguments(let message):
            return message
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidYAML(let message):
            return "Invalid YAML: \(message)"
        case .pathNotFound(let path):
            return "Path not found: \(path)"
        case .missingOperation(let path):
            return "Missing out or del for path: \(path)"
        case .invalidMapping(let key):
            return "\(key) must be a mapping"
        case .invalidSequence(let key):
            return "\(key) must be a sequence"
        case .invalidStringValue(let key):
            return "\(key) must contain only scalar values"
        case .undefinedVariable(let name):
            return "Undefined variable: \(name)"
        case .cyclicVariable(let name):
            return "Cyclic variable reference: \(name)"
        case .unterminatedExpression:
            return "Unterminated expression"
        }
    }
}

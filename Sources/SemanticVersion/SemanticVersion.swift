//
//  SemanticVersion.swift
//  SemanticVersion
//
//  Created by Serhii Mumriak on 01.07.2023
//

import RegexBuilder

public struct SemanticVersion: RawRepresentable, Codable, Hashable, Comparable, LosslessStringConvertible {
    public enum PreReleaseIdentifier: RawRepresentable, Codable, Comparable, Hashable {
        case numeric(value: UInt)
        case alphaNumeric(value: String)

        public var rawValue: String {
            switch self {
                case .numeric(let value):
                    return String(value)

                case .alphaNumeric(let value):
                    return value
            }
        }

        @_transparent
        public init(rawValue: String) {
            self.init(rawValue)
        }

        public init(_ string: some StringProtocol) {
            if let uIntValue = UInt(string) {
                self = .numeric(value: uIntValue)
            } else {
                self = .alphaNumeric(value: String(string))
            }
        }

        public static func < (lhs: PreReleaseIdentifier, rhs: PreReleaseIdentifier) -> Bool {
            switch (lhs, rhs) {
                case (.numeric(let lhsValue), .numeric(let rhsValue)):
                    return lhsValue < rhsValue

                case (.alphaNumeric(let lhsValue), .alphaNumeric(let rhsValue)):
                    return lhsValue < rhsValue

                case (.numeric, .alphaNumeric):
                    return true

                default:
                    return false
            }
        }

        public static func == (lhs: PreReleaseIdentifier, rhs: PreReleaseIdentifier) -> Bool {
            switch (lhs, rhs) {
                case (.numeric(let lhsValue), .numeric(let rhsValue)):
                    return lhsValue == rhsValue

                case (.alphaNumeric(let lhsValue), .alphaNumeric(let rhsValue)):
                    return lhsValue == rhsValue

                default:
                    return false
            }
        }
    }

    // if your major version does not fit 64bit unsigned integer you are an advanced futuristic AI and I hope crash here will help humans fighting you
    public var major: UInt
    public var minor: UInt?
    public var minorStrict: UInt { minor ?? 0 }
    public var patch: UInt?
    public var patchStrict: UInt { patch ?? 0 }
    public var preReleaseIdentifiers: [PreReleaseIdentifier]
    public var preRelease: String {
        get {
            preReleaseIdentifiers
                .map { $0.rawValue }
                .joined(separator: ".")
        }
        set {
            preReleaseIdentifiers = newValue
                .split(separator: ".")
                .map { PreReleaseIdentifier($0) }
        }
    }

    public var buildMetadata: String

    public var rawValue: String {
        var result = "\(major)"

        if let minor {
            result += ".\(minor)"

            if let patch {
                result += ".\(patch)"
            }
        }

        if preRelease.isEmpty == false {
            result += "-" + preRelease
        }
        
        if buildMetadata.isEmpty == false {
            result += "+" + buildMetadata
        }

        return result
    }
    
    public var description: String { rawValue }

    @_transparent
    public init(
        _ major: UInt,
        _ preRelease: String = "",
        _ buildMetadata: String = ""
    ) {
        self.init(major: major, minor: nil, patch: nil, preRelease: preRelease, buildMetadata: buildMetadata)
    }

    @_transparent
    public init(
        _ major: UInt,
        _ minor: UInt,
        _ preRelease: String = "",
        _ buildMetadata: String = ""
    ) {
        self.init(major: major, minor: minor, patch: nil, preRelease: preRelease, buildMetadata: buildMetadata)
    }

    @_transparent
    public init(
        _ major: UInt,
        _ minor: UInt,
        _ patch: UInt,
        _ preRelease: String = "",
        _ buildMetadata: String = ""
    ) {
        self.init(major: major, minor: minor, patch: patch, preRelease: preRelease, buildMetadata: buildMetadata)
    }

    @usableFromInline
    internal init(major: UInt,
                  minor: UInt?,
                  patch: UInt?,
                  preRelease: String,
                  buildMetadata: String) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.preReleaseIdentifiers = preRelease.split(separator: ".")
            .map { PreReleaseIdentifier($0) }
        self.buildMetadata = buildMetadata
    }

    public init?(rawValue: String) {
        self.init(rawValue)
    }

    public init?(_ string: String) {
        guard let match = string.wholeMatch(of: Self.regex) else {
            return nil
        }

        let (_, major, minor, patch, preReleaseIdentifiers, buildMetadata) = match.output
        
        self.major = major
        self.minor = minor
        self.patch = patch ?? nil
        self.preReleaseIdentifiers = preReleaseIdentifiers ?? []
        self.buildMetadata = buildMetadata ?? ""
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(RawValue.self)
        do {
            self.init(rawValue: rawValue)!
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }

        if lhs.minorStrict != rhs.minorStrict {
            return lhs.minorStrict < rhs.minorStrict
        }

        if lhs.patchStrict != rhs.patchStrict {
            return lhs.patchStrict < rhs.patchStrict
        }

        // empty pre-release identifiers are always "newer" than non-empty
        if lhs.preReleaseIdentifiers.isEmpty != rhs.preReleaseIdentifiers.isEmpty {
            return rhs.preReleaseIdentifiers.isEmpty
        }

        // find first difference and return it's comparison. if elements are the same - compare number of elements
        return zip(lhs.preReleaseIdentifiers, rhs.preReleaseIdentifiers)
            .first {
                $0.0 != $0.1
            }
            .map {
                $0.0 < $0.1
            }
            ?? (lhs.preReleaseIdentifiers.count < rhs.preReleaseIdentifiers.count)
    }

    public static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        lhs.major == rhs.major
            && lhs.minorStrict == rhs.minorStrict
            && lhs.patchStrict == rhs.patchStrict
            && lhs.preRelease == rhs.preRelease
    }

    public func hash(into hasher: inout Hasher) {
        major.hash(into: &hasher)
        minorStrict.hash(into: &hasher)
        patchStrict.hash(into: &hasher)
        preRelease.hash(into: &hasher)
        buildMetadata.hash(into: &hasher)
    }
    
    static let regex = Regex {
        // Swift compiler has troubles type checking this builder. 5.8.1 takes 30 seconds to do it on my PC. 5.9 errors out with "failed to type check in reasonable type"
        // One could think this is a problem of the past, but actually no. With proper type annotation made by hand build takes only 3 seconds. 10 times better
        let nonDigit: Regex<Substring> = #/[a-zA-Z-]/#
        let identifierCharacter: Regex<Substring> = #/[0-9a-zA-Z-]/#
        let nonZeroDigit: Regex<Substring> = #/[1-9]/# // positive digit
        let positiveNumber = Regex {
            nonZeroDigit
            ZeroOrMore(.digit)
        }

        let preReleaseIdentifier: ChoiceOf<Substring> = ChoiceOf {
            "0"
            positiveNumber
            Regex {
                ZeroOrMore(.digit)
                nonDigit
                ZeroOrMore(identifierCharacter)
            }
        }
        
        let buildIdentifier: OneOrMore<Substring> = OneOrMore {
            identifierCharacter
        }

        let version: Capture<(Substring, UInt)> = Capture {
            ChoiceOf {
                "0"
                positiveNumber
            }
        } transform: { UInt($0)! }

        let preReleaseRegexPart: Optionally<(Substring, [PreReleaseIdentifier]?)> = Optionally(.possessive) {
            "-"
            Capture {
                preReleaseIdentifier
                ZeroOrMore {
                    "."
                    preReleaseIdentifier
                }
            } transform: {
                $0.split(separator: ".")
                    .map { SemanticVersion.PreReleaseIdentifier($0) }
            }
        }

        let buildRegexPart: Optionally<(Substring, String?)> = Optionally(.possessive) {
            "+"
            Capture {
                buildIdentifier
                ZeroOrMore {
                    "."
                    buildIdentifier
                }
            } transform: { String($0) }
        }

        // actual result regex
        Anchor.startOfLine
        Optionally(.possessive) {
            "v"
            Optionally(".")
        }
        version
        Optionally(.possessive) {
            "."
            version
        }
        Optionally(.possessive) {
            "."
            version
        }
        preReleaseRegexPart
        buildRegexPart
        Anchor.endOfLine
    }
}

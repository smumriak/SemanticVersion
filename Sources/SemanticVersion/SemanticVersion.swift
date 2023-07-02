//
//  SemanticVersion.swift
//  SemanticVersion
//
//  Created by Serhii Mumriak on 01.07.2023
//

import RegexBuilder

public struct SemanticVersion: RawRepresentable, Codable, Hashable, Comparable, LosslessStringConvertible {
    // if your major version does not fit 64bit unsigned integer you are an advanced futuristic AI and I hope crash here will help humans fighting you
    public var major: UInt
    public var minor: UInt?
    public var minorStrict: UInt { minor ?? 0 }
    public var patch: UInt?
    public var patchStrict: UInt { patch ?? 0 }
    public var preRelease: String
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
        self.preRelease = preRelease
        self.buildMetadata = buildMetadata
    }

    public init?(rawValue: String) {
        self.init(rawValue)
    }

    public init?(_ string: String) {
        guard let match = string.wholeMatch(of: Self.regex) else {
            return nil
        }
        
        let (_, major, minor, patch, preRelease, buildMetadata) = match.output
        
        self.major = major
        self.minor = minor
        self.patch = patch ?? nil
        self.preRelease = preRelease ?? ""
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

        if lhs.preRelease != rhs.preRelease {
            // FIXME: This code assumes preRelease identifier are alphanumerical. Check spec
            if lhs.preRelease.isEmpty {
                return false
            }

            if rhs.preRelease.isEmpty {
                return true
            }

            return lhs.preRelease < rhs.preRelease
        }

        return false
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
        let nonDigit = #/[a-zA-Z-]/#
        let identifierCharacter = #/[0-9a-zA-Z-]/#
        let nonZeroDigit = #/[1-9]/# // positive digit
        let positiveNumber = Regex {
            nonZeroDigit
            ZeroOrMore(.digit)
        }
        let preReleaseIdentifier = ChoiceOf {
            "0"
            positiveNumber
            Regex {
                ZeroOrMore(.digit)
                nonDigit
                ZeroOrMore(identifierCharacter)
            }
        }
        
        let buildIdentifier = OneOrMore {
            identifierCharacter
        }

        let version = Capture {
            ChoiceOf {
                "0"
                positiveNumber
            }
        } transform: { UInt($0)! }

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
        Optionally(.possessive) {
            "-"
            Capture {
                preReleaseIdentifier
                ZeroOrMore {
                    "."
                    preReleaseIdentifier
                }
            } transform: { String($0) }
        }
        Optionally(.possessive) {
            "+"
            Capture {
                buildIdentifier
                ZeroOrMore {
                    "."
                    buildIdentifier
                }
            } transform: { String($0) }
        }
        Anchor.endOfLine
    }
}

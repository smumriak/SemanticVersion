# SemanticVersion

SemanticVersion is a sligtlhy off-spec (but better!) implementation of [Semantic Version 2.0.0](https://semver.org/) in Swift. It supports Codable, Comparable, Equatable and Hashable protocols.
Key features: 
  - Support for ommited patch or patch+minor versions in string representation! You can feed SemanticVersion Swift's docker tag with version "5.8" and it will correctly represent it as "5.8.0", just like Apple does with almost all it's product versions!
  - SemanticVersion is encoded to string and decoded from string. I.e. in your JSON you will see `"version": "1.2.3-alpha+aarch64"` instead of blown-up dictionary
  - Regular Expression to parse string representation is written via Swift's RegexBuilder ans is evaluated in compile time. Much safer!

```swift
import SemanticVersion

let v1 = SemanticVersion(1)
let v12 = SemanticVersion(1, 2)
let v123 = SemanticVersion(1, 2, 3)
let v123β = SemanticVersion(1, 2, 3, "beta")
let v123β_localBuild = SemanticVersion(1, 2, 3, "beta", "local-202307081341")

let v2 = SemanticVersion("2")!
let v20 = SemanticVersion("2.0")!
let v201 = SemanticVersion("2.0.1")!

if v2 == v20 {
    print("They ARE equal")
}

print("Is v2.0.1 newer than v2.0? " + v201 > v20 ? "Yes!" : "No!")

let v3_local = SemanticVersion("3-beta+local")
let v3_test = SemanticVersion("3-beta+test")

if v3_local == v3_test {
    print("Local version 3.0.0-beta is indeed the same as test version 3.0.0-beta (according to spec)")
}

//
//  SemanticVersionTests.swift
//  SemanticVersion
//
//  Created by Serhii Mumriak on 01.07.2023
//

import XCTest
@testable import SemanticVersion

final class SemanticVersionTests: XCTestCase {
    func testValidVersions() throws {
        [
            "0.0.4",
            "1.2.3",
            "10.20.30",
            "1.1.2-prerelease+meta",
            "1.1.2+meta",
            "1.1.2+meta-valid",
            "1.0.0-alpha",
            "1.0.0-beta",
            "1.0.0-alpha.beta",
            "1.0.0-alpha.beta.1",
            "1.0.0-alpha.1",
            "1.0.0-alpha0.valid",
            "1.0.0-alpha.0valid",
            "1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay",
            "1.0.0-rc.1+build.1",
            "2.0.0-rc.1+build.123",
            "1.2.3-beta",
            "10.2.3-DEV-SNAPSHOT",
            "1.2.3-SNAPSHOT-123",
            "1.0.0",
            "2.0.0",
            "1.1.7",
            "2.0.0+build.1848",
            "2.0.1-alpha.1227",
            "1.0.0-alpha+beta",
            "1.2.3----RC-SNAPSHOT.12.9.1--.12+788",
            "1.2.3----R-S.12.9.1--.12+meta",
            "1.2.3----RC-SNAPSHOT.12.9.1--.12",
            "1.0.0+0.build.1-rc.10000aaa-kk-0.1",
            "1.0.0-0A.is.legal",
            "9999999999.9999999999.9999999999",
        ].forEach {
            let version = SemanticVersion($0)!
            XCTAssertEqual(version.rawValue, $0)
        }

        let version = SemanticVersion("1.2.3")!
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minorStrict, 2)
        XCTAssertEqual(version.patchStrict, 3)
    }

    func testInvalidButFlexibleVersions() throws {
        [
            "1",
            "1.2",
            "1.2",
            "1.2-SNAPSHOT",
            "1.2-RC-SNAPSHOT",
            "2+local",
            "3-beta-SNAPSHOT",
        ].forEach {
            let version = SemanticVersion($0)!
            XCTAssertEqual(version.rawValue, $0)
        }

        var version = SemanticVersion("1")!
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minorStrict, 0)
        XCTAssertEqual(version.patchStrict, 0)

        version = SemanticVersion("1.2")!
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minorStrict, 2)
        XCTAssertEqual(version.patchStrict, 0)
    }

    func testInvalidVersions() throws {
        [
            "1..",
            "1..0",
            "1.2.3-0123",
            "1.2.3-0123.0123",
            "1.1.2+.123",
            "+invalid",
            "-invalid",
            "-invalid+invalid",
            "-invalid.01",
            "alpha",
            "alpha.beta",
            "alpha.beta.1",
            "alpha.1",
            "alpha+beta",
            "alpha_beta",
            "alpha.",
            "alpha..",
            "beta",
            "1.0.0-alpha_beta",
            "-alpha.",
            "1.0.0-alpha..",
            "1.0.0-alpha..1",
            "1.0.0-alpha...1",
            "1.0.0-alpha....1",
            "1.0.0-alpha.....1",
            "1.0.0-alpha......1",
            "1.0.0-alpha.......1",
            "01.1.1",
            "1.01.1",
            "1.1.01",
            "1.2.3.DEV",
            "1.2.31.2.3----RC-SNAPSHOT.12.09.1--..12+788",
            "-1.0.3-gamma+b7718",
            "+justmeta",
            "9.8.7+meta+meta",
            "9.8.7-whatever+meta+meta",
            "9999999999.9999999999.9999999999----RC-SNAPSHOT.12.09.1--------------------------------..12",
        ].forEach {
            XCTAssertNil(SemanticVersion($0))
        }
    }

    func testComparable() throws {
        XCTAssertEqual(SemanticVersion(1), SemanticVersion(1, 0, 0))
        XCTAssertEqual(SemanticVersion(1, 1), SemanticVersion(1, 1, 0))
        XCTAssertEqual(SemanticVersion(1, 1, 1), SemanticVersion(1, 1, 1))
        XCTAssertGreaterThan(SemanticVersion(1, 1), SemanticVersion(1))
        XCTAssertGreaterThan(SemanticVersion(1, 1, 0), SemanticVersion(1))
        XCTAssertGreaterThan(SemanticVersion(1, 0, 1), SemanticVersion(1))
        XCTAssertLessThan(SemanticVersion(1), SemanticVersion(1, 1))
        XCTAssertLessThan(SemanticVersion(1), SemanticVersion(1, 1, 0))
        XCTAssertLessThan(SemanticVersion(1), SemanticVersion(1, 0, 1))
        
        XCTAssertLessThan(SemanticVersion(1, "beta"), SemanticVersion(1, 0, 0))
        XCTAssertLessThan(SemanticVersion(1, 0, "beta"), SemanticVersion(1, 0, 0))
        XCTAssertLessThan(SemanticVersion(1, 0, 0, "beta"), SemanticVersion(1, 0, 0))

        XCTAssertLessThan(SemanticVersion(1, "beta"), SemanticVersion(1, "beta.12345"))

        XCTAssertLessThan(SemanticVersion(1, "beta", "aarch64"), SemanticVersion(1, 0, 0))
        XCTAssertLessThan(SemanticVersion(1, 0, "beta", "aarch64"), SemanticVersion(1, 0, 0))
        XCTAssertLessThan(SemanticVersion(1, 0, 0, "beta", "aarch64"), SemanticVersion(1, 0, 0))
        
        XCTAssertEqual(SemanticVersion(1, "", "aarch64"), SemanticVersion(1, 0, 0))
        XCTAssertEqual(SemanticVersion(1, 0, "", "aarch64"), SemanticVersion(1, 0, 0))
        XCTAssertEqual(SemanticVersion(1, 0, 0, "", "aarch64"), SemanticVersion(1, 0, 0))
    }
}

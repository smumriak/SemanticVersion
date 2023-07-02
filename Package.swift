// swift-tools-version: 5.7
//
//  Package.swift
//  SemanticVersion
//
//  Created by Serhii Mumriak on 01.07.2023
//

import PackageDescription

let package = Package(
    name: "SemanticVersion",
    products: [
        .library(
            name: "SemanticVersion",
            targets: ["SemanticVersion"]),
    ],
    targets: [
        .target(
            name: "SemanticVersion"),
        .testTarget(
            name: "SemanticVersionTests",
            dependencies: ["SemanticVersion"]),
    ]
)

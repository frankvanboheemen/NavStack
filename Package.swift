// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NavStack",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "NavStack", targets: ["NavStack"]),
    ],
    targets: [
        .target(name: "NavStack"),
    ]
)

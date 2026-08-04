// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NewMyDictate",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "NewMyDictate", targets: ["NewMyDictate"]),
    ],
    targets: [
        .executableTarget(
            name: "NewMyDictate",
            path: "Sources/NewMyDictate"
        ),
        .testTarget(
            name: "NewMyDictateTests",
            dependencies: ["NewMyDictate"],
            path: "Tests/NewMyDictateTests"
        ),
    ]
)

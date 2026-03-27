// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "iPhoneMediaImporter",
    defaultLocalization: "tr",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "iPhoneMediaImporter",
            targets: ["iPhoneMediaImporterApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "iPhoneMediaImporterApp",
            path: "Sources/iPhoneMediaImporterApp"
        ),
        .testTarget(
            name: "iPhoneMediaImporterAppTests",
            dependencies: ["iPhoneMediaImporterApp"],
            path: "Tests/iPhoneMediaImporterAppTests"
        )
    ]
)

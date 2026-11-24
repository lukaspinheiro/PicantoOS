// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PicantoOBDKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PicantoOBDKit",
            targets: ["PicantoOBDKit"]
        )
    ],
    targets: [
        .target(
            name: "PicantoOBDKit"
        ),
        .testTarget(
            name: "PicantoOBDKitTests",
            dependencies: ["PicantoOBDKit"]
        )
    ]
)

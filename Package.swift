// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PasswordStrengthKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "PasswordStrengthKit",
            targets: ["PasswordStrengthKit"]
        )
    ],
    targets: [
        .target(
            name: "PasswordStrengthKit",
            path: "Sources/PasswordStrengthKit"
        ),
        .testTarget(
            name: "PasswordStrengthKitTests",
            dependencies: ["PasswordStrengthKit"]
        )
    ]
)

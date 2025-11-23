// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NudgeApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "NudgeApp",
            targets: ["NudgeApp"]
        )
    ],
    dependencies: [
        // Supabase Swift Client
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "NudgeApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ]
        )
    ]
)

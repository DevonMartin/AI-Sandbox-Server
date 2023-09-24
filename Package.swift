// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "ChatGPT Server",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.77.1"),
		.package(url: "https://github.com/apple/app-store-server-library-swift.git", .upToNextMinor(from: "0.1.0-b")),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
				.product(name: "Vapor", package: "vapor"),
				.product(name: "AppStoreServerLibrary", package: "app-store-server-library-swift")
            ],
			resources: [
				.copy("Resources/Certificates")
			]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)

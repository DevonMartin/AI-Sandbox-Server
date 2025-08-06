// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "A.I. Sandbox Server",
    platforms: [
       .macOS(.v14)
    ],
    dependencies: [
		// 💧 A server-side Swift web framework.
		.package(url: "https://github.com/vapor/vapor.git", from: "4.83.1"),
		// 🗄 An ORM for SQL and NoSQL databases.
		.package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
		// 🐘 Fluent driver for Postgres.
		.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.7.2"),
		.package(url: "https://github.com/vapor/postgres-nio.git", exact: "1.25.0"),
		.package(url: "https://github.com/DevonMartin/Swift-ChatGPT.git", branch: "main"),
		// 🗄 SQLite driver for in-memory tests
		.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
				.product(name: "Vapor",                package: "vapor"),
				.product(name: "Fluent",               package: "fluent"),
				.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
				.product(name: "ChatGPT",              package: "Swift-ChatGPT"),
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor",             package: "vapor"),
			.product(name: "VaporTesting",         package: "vapor"),
			.product(name: "FluentSQLiteDriver",   package: "fluent-sqlite-driver"),
			
			// Workaround for https://github.com/apple/swift-package-manager/issues/6940
			.product(name: "Vapor",                package: "vapor"),
			.product(name: "Fluent",               package: "Fluent"),
			.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        ])
    ]
)

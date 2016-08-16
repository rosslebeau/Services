import PackageDescription

let package = Package(
    name: "Services",
    targets: [
        Target(
            name: "Services",
            dependencies: []
        )
    ],
    dependencies: [
        .Package(url: "https://github.com/qutheory/engine.git", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/qutheory/vapor-tls", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/ChameleonBot/Common.git", majorVersion: 0, minor: 1)
    ],
    exclude: [
        "XcodeProject"
    ]
)

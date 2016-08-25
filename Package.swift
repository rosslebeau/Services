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
        .Package(url: "https://github.com/vapor/tls-provider.git", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/ChameleonBot/Common.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/czechboy0/Redbird.git", majorVersion: 0, minor: 9)
    ],
    exclude: [
        "XcodeProject"
    ]
)

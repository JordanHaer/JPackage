#!/usr/bin/env swift

import Foundation

enum Platform: String, CaseIterable {

    case iOS = "iOS"
    case iOSSimulator = "iOS Simulator"

    var archivePath: String {
        switch self {
        case .iOS:
            "Release-iphoneos"
        case .iOSSimulator:
            "Release-iphonesimulator"
        }
    }
}

func run(command: String, arguments: [String] = []) {
    let process = Process()
    process.launchPath = "/usr/bin/\(command)"
    process.arguments = arguments
    process.launch()
    process.waitUntilExit()
    if process.terminationStatus != 0 {
        print("Command failed: \(command) \(arguments.joined(separator: " "))")
        exit(1)
    }
}

let packages = ["JPackage", "JDependency"]

let fileManager = FileManager.default

for package in packages {

    try? fileManager.removeItem(atPath: "\(package).xcframework")

    for platform in Platform.allCases {

        let archivePath = platform.archivePath

        run(
            command: "xcodebuild",
            arguments: [
                "archive", "-workspace", ".", "-scheme", "JPackage",
                "-destination", "generic/platform=\(platform.rawValue)",
                "-archivePath", archivePath,
                "-derivedDataPath", ".build",
                "SKIP_INSTALL=NO",
                "BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
            ]
        )

        let frameworkPath = "\(archivePath).xcarchive/Products/usr/local/lib/\(package).framework"
        let modulesPath = "\(frameworkPath)/Modules"

        try? fileManager.createDirectory(atPath: modulesPath, withIntermediateDirectories: true, attributes: nil)

        let buildProductsPath = ".build/Build/Intermediates.noindex/ArchiveIntermediates/\(package)/BuildProductsPath"
        let releasePath = "\(buildProductsPath)/\(archivePath)"
        let swiftModulePath = "\(releasePath)/\(package).swiftmodule"

        if fileManager.fileExists(atPath: swiftModulePath) {
            try? fileManager.copyItem(atPath: swiftModulePath, toPath: "\(modulesPath)/\(package).swiftmodule")
        } else {
            let moduleMapContent = "module \(package) { export * }"
            let moduleMapPath = "\(modulesPath)/module.modulemap"
            try? moduleMapContent.write(toFile: moduleMapPath, atomically: true, encoding: .utf8)
        }

        let resourcesBundlePath = "\(releasePath)/\(package)_\(package).bundle"

        if fileManager.fileExists(atPath: resourcesBundlePath) {
            try? fileManager.copyItem(atPath: resourcesBundlePath, toPath: frameworkPath)
        }
    }

    run(
        command: "xcodebuild",
        arguments: [
            "-create-xcframework",
            "-framework", "Release-iphoneos.xcarchive/Products/usr/local/lib/\(package).framework",
            "-framework", "Release-iphonesimulator.xcarchive/Products/usr/local/lib/\(package).framework",
            "-output", "\(package).xcframework"
        ]
    )

    try? fileManager.removeItem(atPath: "Release-iphoneos.xcarchive")
    try? fileManager.removeItem(atPath: "Release-iphonesimulator.xcarchive")
}

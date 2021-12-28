#!/usr/bin/env swift

import Foundation

func main() {
    do {
        let line = try shell("xcrun simctl listapps booted | grep CFBundleIdentifier")
        let lines = line.components(separatedBy: "\n")
        let allLinesExceptAppleApps = lines.filter { !$0.contains("com.apple") }
        let identifiers = allLinesExceptAppleApps.compactMap {
            matches(for: "\"\\S*\"", in: $0).first
        }
        try identifiers.forEach {
            try shell("xcrun simctl uninstall booted \($0)")
        }
        print("✅ Deleted all apps, except ones from apple.")
    } catch {
        print("Failed: \(error)")
        return
    }
}

// Runs the command in the shell
@discardableResult
func shell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    try task.run()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!

    task.terminate()
    return output
}

func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

// Entry point
main()

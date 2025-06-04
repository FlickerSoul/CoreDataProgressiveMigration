import Foundation

class TempFileManager {
    deinit {
        Self.clearTempDirectoryContents()
        NSLog("Temp files cleared")
    }

    // MARK: - Temp

    static func clearTempDirectoryContents() {
        let tmpDirectoryContents = try! FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
        for tmpDirectoryContent in tmpDirectoryContents {
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(tmpDirectoryContent)
            try? FileManager.default.removeItem(atPath: fileURL.path)
        }
    }

    static func moveFileFromBundleToTempDirectory(filename: String, subdir: String) throws -> URL {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destinationURL)
        let bundleURL = Bundle(for: TempFileManager.self).resourceURL!.appendingPathComponent(subdir)
            .appendingPathComponent(filename)
        try FileManager.default.copyItem(at: bundleURL, to: destinationURL)

        return destinationURL
    }
}

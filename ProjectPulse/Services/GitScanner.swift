import Foundation

enum GitScanner {
    static func scan(directory: String, maxDepth: Int = 2) -> [String] {
        let fm = FileManager.default
        let baseURL = URL(fileURLWithPath: directory)
        var results: [String] = []
        var foundRepoPaths: Set<String> = []

        func walk(_ url: URL, depth: Int) {
            guard depth <= maxDepth else { return }

            for repoPath in foundRepoPaths {
                if url.path.hasPrefix(repoPath + "/") { return }
            }

            let gitDir = url.appendingPathComponent(".git")
            if fm.fileExists(atPath: gitDir.path) {
                results.append(url.path)
                foundRepoPaths.insert(url.path)
                return
            }

            guard let contents = try? fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { return }

            for item in contents {
                let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                if isDir {
                    walk(item, depth: depth + 1)
                }
            }
        }

        walk(baseURL, depth: 0)
        return results.sorted()
    }
}

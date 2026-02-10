//
//  FileCollector.swift
//  DuplicateFinder
//
//  Created by da fuq on 11.02.2026.
//

import Foundation

enum FileCollectorError: Error {
  case cantEnumerate
}

final class FileCollector {
  func collectFiles(in folder: URL) throws -> [FileEntry] {
    var result: [FileEntry] = []
    let fm = FileManager.default
    let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey]
    guard let enumerator = fm.enumerator(at: folder, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles, .skipsPackageDescendants], errorHandler: { (_, _) -> Bool in true }) else {
      throw FileCollectorError.cantEnumerate
    }
    for case let url as URL in enumerator {
      do {
        let rv = try url.resourceValues(forKeys: Set(keys))
        if rv.isRegularFile == true {
          let size = UInt64(rv.fileSize ?? 0)
          result.append(FileEntry(url: url, size: size, hash: nil))
        }
      } catch {
        continue
      }
    }
    return result
  }
}



//
//  HasherService.swift
//  DuplicateFinder
//
//  Created by da fuq on 11.02.2026.
//

import Foundation
import CryptoKit

import Foundation
import CryptoKit

final class HasherService {
  static let shared = HasherService()
  private init() {}
  
  func hashFile(at url: URL) async throws -> String {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    var hasher = SHA256()
    let chunkSize = 1024 * 1024 // 1 MB
    while true {
      try Task.checkCancellation()
      let data: Data
      if #available(macOS 12.3, *) {
        data = try handle.read(upToCount: chunkSize) ?? Data()
      } else {
        data = handle.readData(ofLength: chunkSize)
      }
      if data.isEmpty { break }
      hasher.update(data: data)
    }
    let digest = hasher.finalize()
    return digest.map { String(format: "%02x", $0) }.joined()
  }
  
  func computeHashes(for files: [FileEntry], concurrency: Int = 4) async throws -> [(FileEntry, String)] {
    var results: [(FileEntry, String)] = []
    let concurrencyClamped = max(1, min(concurrency, ProcessInfo.processInfo.activeProcessorCount))
    let chunks = files.chunked(into: concurrencyClamped)
    for chunk in chunks {
      try await withThrowingTaskGroup(of: (FileEntry, String).self) { group in
        for entry in chunk {
          group.addTask {
            let h = try await self.hashFile(at: entry.url)
            return (entry, h)
          }
        }
        for try await pair in group {
          results.append(pair)
        }
      }
    }
    return results
  }
}


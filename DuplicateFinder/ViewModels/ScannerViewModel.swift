//
//  ScannerViewModel.swift
//  DuplicateFinder
//
//  Created by da fuq on 11.02.2026.
//

import Foundation
import SwiftUI

@MainActor
final class ScannerViewModel: ObservableObject {
  @Published var groups: [DuplicateGroup] = []
  @Published var isScanning = false
  @Published var progressText: String = ""
  @Published var fileCount: Int = 0
  
  private let collector = FileCollector()
  private let hasher = HasherService.shared
  private var currentTask: Task<Void, Never>?
  
  func cancel() {
    currentTask?.cancel()
  }
  
  func removeLocally(file: FileEntry, from group: DuplicateGroup) {
    if let gi = groups.firstIndex(where: { $0.id == group.id }) {
      var g = groups[gi]
      g.files.removeAll { $0.id == file.id }
      if g.files.count <= 1 {
        groups.remove(at: gi)
      } else {
        groups[gi] = g
      }
    }
  }
  
  func scan(folder: URL, concurrency: Int = 6) {
    currentTask?.cancel()
    groups = []
    isScanning = true
    progressText = NSLocalizedString("scanning", comment: "Scanning")
    currentTask = Task { [weak self] in
      guard let self = self else { return }
      do {
        let files = try self.collector.collectFiles(in: folder)
        await MainActor.run {
          self.fileCount = files.count
          self.progressText = String(format: NSLocalizedString("collected_files", comment: ""), files.count)
        }
        if files.isEmpty {
          await MainActor.run {
            self.progressText = NSLocalizedString("no_files_found", comment: "")
            self.isScanning = false
          }
          return
        }
        
        let bySize = Dictionary(grouping: files, by: { $0.size })
        var candidates: [FileEntry] = []
        for (_, arr) in bySize where arr.count > 1 {
          candidates.append(contentsOf: arr)
        }
        await MainActor.run { self.progressText = String(format: NSLocalizedString("hashing_candidates", comment: ""), candidates.count) }
        
        let hashed = try await self.hasher.computeHashes(for: candidates, concurrency: concurrency)
        
        var groupsDict = Dictionary<String, [FileEntry]>(minimumCapacity: hashed.count)
        for (entry, hash) in hashed {
          var e = entry
          e.hash = hash
          groupsDict[hash, default: []].append(e)
        }
        
        let duplicateGroups = groupsDict.values.filter { $0.count > 1 }.map { arr -> DuplicateGroup in
          DuplicateGroup(hash: arr.first!.hash ?? "", files: arr)
        }.sorted { $0.files.count > $1.files.count }
        
        await MainActor.run {
          self.groups = duplicateGroups
          self.progressText = String(format: NSLocalizedString("done_found_groups", comment: ""), duplicateGroups.count)
          self.isScanning = false
        }
      } catch {
        if Task.isCancelled {
          await MainActor.run {
            self.progressText = NSLocalizedString("cancelled", comment: "")
            self.isScanning = false
          }
        } else {
          await MainActor.run {
            self.progressText = String(format: NSLocalizedString("error_occurred", comment: ""), error.localizedDescription)
            self.isScanning = false
          }
        }
      }
    }
  }
  
  func moveToTrash(_ url: URL) -> Bool {
    do {
      try FileManager.default.trashItem(at: url, resultingItemURL: nil)
      return true
    } catch {
      print("Trash error:", error)
      return false
    }
  }
}

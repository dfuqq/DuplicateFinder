//
//  FileEntry.swift
//  DuplicateFinder
//
//  Created by da fuq on 11.02.2026.
//

import Foundation

struct FileEntry: Identifiable, Hashable {
  let id = UUID()
  let url: URL
  let size: UInt64
  var hash: String?
}


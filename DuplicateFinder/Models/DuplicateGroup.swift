//
//  DuplicateGroup.swift
//  DuplicateFinder
//
//  Created by da fuq on 11.02.2026.
//

import Foundation

struct DuplicateGroup: Identifiable {
  let id = UUID()
  let hash: String
  var files: [FileEntry]
}


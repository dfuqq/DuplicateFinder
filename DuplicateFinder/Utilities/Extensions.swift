//
//  Extensions.swift
//  DuplicateFinder
//
//  Created by da fuq on 11.02.2026.
//

extension Array {
  func chunked(into n: Int) -> [[Element]] {
    guard n > 0, !isEmpty else { return [self] }
    var chunks: [[Element]] = Array(repeating: [], count: n)
    for (i, el) in self.enumerated() {
      chunks[i % n].append(el)
    }
    return chunks.filter { !$0.isEmpty }
  }
}

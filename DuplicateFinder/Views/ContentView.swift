//
//  ContentView.swift
//  DuplicateFinder
//
//  Created by da fuq on 11.02.2026.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var vm = ScannerViewModel()
  @State private var folderURL: URL? = nil
  
  var body: some View {
    VStack {
      HStack {
        Button(NSLocalizedString("choose_folder", comment: "")) { chooseFolder() }
          .disabled(vm.isScanning)
        if let url = folderURL {
          Text(url.path).lineLimit(1)
        }
        Spacer()
        Text(vm.progressText).foregroundColor(.secondary)
        Button(vm.isScanning ? NSLocalizedString("cancel", comment: "") : NSLocalizedString("scan", comment: "")) {
          if vm.isScanning {
            vm.cancel()
          } else {
            guard let folder = folderURL else {
              vm.progressText = NSLocalizedString("select_folder_first", comment: "")
              return
            }
            vm.scan(folder: folder)
          }
        }
        .keyboardShortcut("s", modifiers: [.command])
      }
      .padding()
      
      List {
        ForEach(vm.groups) { group in
          Section(header: Text(String(format: NSLocalizedString("group_files", comment: ""), group.files.count))) {
            ForEach(group.files) { file in
              HStack {
                VStack(alignment: .leading) {
                  Text(file.url.lastPathComponent).font(.system(size: 12, weight: .semibold))
                  Text(file.url.path).font(.system(size: 10)).foregroundColor(.secondary)
                }
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file))
                  .font(.system(size: 11))
                Button(NSLocalizedString("reveal", comment: "")) {
                  NSWorkspace.shared.activateFileViewerSelecting([file.url])
                }
                .buttonStyle(BorderlessButtonStyle())
                Button(NSLocalizedString("trash", comment: "")) {
                  if vm.moveToTrash(file.url) {
                    vm.removeLocally(file: file, from: group)
                  }
                }
                .buttonStyle(BorderlessButtonStyle())
              }
            }
          }
        }
      }
      .listStyle(SidebarListStyle())
    }
    .frame(minWidth: 800, minHeight: 480)
  }
  
  private func chooseFolder() {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.prompt = NSLocalizedString("choose_folder", comment: "")
    panel.begin { resp in
      if resp == .OK { folderURL = panel.url }
    }
  }
}


#Preview {
    ContentView()
}

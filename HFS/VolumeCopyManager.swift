//
//  VolumeCopyProcess.swift
//  HFS
//
//  Created by Kevin Brewster on 4/10/21.
//

import Foundation
import HFSKit
import SwiftUI


class VolumeCopyManager : ObservableObject {
    @Published var processes = [VolumeCopyOperation]()
    var errors = [String]()
    @Published var showError = false
    
    
    private var preQueue = [(VolumeCopyOperation, NSWindow, URL)]() // we need to prompt for write folder
    private var openFolderPanelIsDisplayed = false
    private let queue = OperationQueue()
    
    init() {
        queue.maxConcurrentOperationCount = 1
    }
    func createNewProcesses(_ urls: [URL], _ window: NSWindow) {
        DispatchQueue.main.async {
            self.errors = []

            for diskUrl in urls {
                
                if self.processes.contains(where: { $0.source == diskUrl }) {
                    self.errors.append("Duplicate HFS file: '\(diskUrl.lastPathComponent)'")
                    
                } else if let disk = Disk(diskUrl), disk.volumes.count > 0 {
                    for volume in disk.volumes {
                        let operation = VolumeCopyOperation(diskUrl, volume)
                        self.processes.append(operation)
                        self.preQueue.append((operation, window, diskUrl.deletingLastPathComponent()))
                    }
                } else {
                    NSLog("Invalid HFS")
                    self.errors.append("Invalid HFS file: '\(diskUrl.lastPathComponent)'")
                }
            }
            self.showError = self.errors.count > 0
            
            if !self.openFolderPanelIsDisplayed {
                self.checkPreQueue()
            }
        }
    }
    func openFolderSelection(defaultDir: URL, title: String, window: NSWindow, completion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.directoryURL = defaultDir
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.message = title
        openPanel.prompt = "Extract Here"
                    
        // openPanel.begin { result in
        openPanel.beginSheetModal(for: window) { result in
            guard let url = openPanel.url, result == .OK else {
                completion(nil)
                return
            }
            completion(url)
        }
    }
    func checkPreQueue() {
        guard preQueue.count > 0 else {
            openFolderPanelIsDisplayed = false
            return
        }
        let (operation, window, defaultDir) = preQueue.removeFirst()
        let title = "Choose write destination for '\(operation.volume.name)'"
        openFolderPanelIsDisplayed = true
        openFolderSelection(defaultDir: defaultDir, title: title, window: window) { destination in
            DispatchQueue.main.async {
                if let destination = destination {
                    operation.destination = destination
                    self.queue.addOperation(operation)
                } else {
                    // if cancelled, then remove operation
                    self.processes = self.processes.filter { $0 !== operation }
                }
                self.checkPreQueue()
            }
        }
    }
}

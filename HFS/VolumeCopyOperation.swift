//
//  VolumeCopyOperation.swift
//  HFS
//
//  Created by Kevin Brewster on 4/10/21.
//

import Foundation
import HFSKit
import SwiftUI

class VolumeCopyOperation : Operation, Identifiable, ObservableObject, VolumeWriteDelegate {
    
    
    let source: URL
    let volume: Volume
    var destination: URL?
    
    enum State {
        case queued
        case copying(String, Double)
        case finished(Int64)
    }
    
    @Published var state = State.queued
    @Published var title = "Open HFS Volume.."
    @Published var errors = [String]()
    
    init(_ source: URL, _ volume: Volume, _ destination: URL? = nil) {
        self.source = source
        self.volume = volume
        self.destination = destination
        super.init()
        volume.writeDelegate = self
    }
    override func main() {
        DispatchQueue.main.async {
            self.state = .copying("", 0)
        }
        guard let destination = destination else {
            return
        }
        do {
            try self.volume.write(to: destination)
                        
        } catch let error {
            DispatchQueue.main.async {
                self.errors.append(error.localizedDescription)
            }
        }
        DispatchQueue.main.async {
            self.state = .finished(Int64(self.totalBytesWritten))
        }
    }
    
    var totalBytesWritten = 0.0
    var totalBytesExpectedToWrite = 0.0
    
    func volume(_ volume: Volume, willWriteToURL url: URL, totalBytesExpectedToWrite: UInt64) {
        self.totalBytesWritten = 0
        self.totalBytesExpectedToWrite = Double(totalBytesExpectedToWrite)
    }
    func volume(_ volume: Volume, willWriteFileToURL url: URL) {
        DispatchQueue.main.async {
            self.state = .copying(url.relativePath, self.totalBytesWritten / self.totalBytesExpectedToWrite)
        }
    }
    func volume(_ volume: Volume, didWriteFileToURL url: URL, bytesWritten: UInt64) {
        DispatchQueue.main.async {
            self.totalBytesWritten += Double(bytesWritten)
            self.state = .copying(url.relativePath, self.totalBytesWritten / self.totalBytesExpectedToWrite)
        }
    }

}

//
//  HFSApp.swift
//  HFS
//
//  Created by Kevin Brewster on 4/9/21.
//

import SwiftUI
import Foundation
import AppKit
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}


struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window   // << right after inserted in window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}


@main
struct HFSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var processManager = VolumeCopyManager()
    @State private var window: NSWindow?
    
    
    var body: some Scene {
        WindowGroup {
            
                
            List(processManager.processes, id: \.source) {
                VolumeCopyOperationView(operation: $0)
            }.overlay(
                Group {
                    if processManager.processes.isEmpty {
                        Image(systemName: "square.and.arrow.down").font(.system(size: 56.0, weight: .bold)).padding(10)
                        Text("Drop ISO").font(.system(size: 18.0, weight: .bold))
                    }
                }.foregroundColor(Color(white: 0.75))
            )
           
            .background(WindowAccessor(window: $window))            
            .handlesExternalEvents(preferring: Set(arrayLiteral: "{path of URL?}"), allowing: Set(arrayLiteral: "*")) // prevents new window during onOpenURL - no idea why this works
            .onOpenURL(perform: { url in
                processManager.createNewProcesses([url], window!)
            })
            .onDrop(of: ["public.file-url"], isTargeted: nil) { itemProviders in
                print("onDrop")
                for itemProvider in itemProviders {
                    _ = itemProvider.loadObject(ofClass: URL.self) { url, error in
                        guard let url = url else { return }
                        processManager.createNewProcesses([url], window!)
                    }
                }
                return true
            }
            .alert(isPresented: $processManager.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(processManager.errors.joined(separator: "\n"))
                )
            }
        }.commands {
            CommandGroup(before: CommandGroupPlacement.newItem) {
                Button("Open") {
                    openFileSelection { urls in
                        processManager.createNewProcesses(urls, window!)
                    }
                }.keyboardShortcut("o")
            }
        }        
    }
    func openFileSelection(completion: @escaping ([URL]) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.message = "Select HFS Volume"
        openPanel.prompt = "Open HFS Volume"        
        openPanel.allowedContentTypes = [UTType(filenameExtension: "toast"), UTType(filenameExtension: "iso")].compactMap { $0 }
        openPanel.allowsOtherFileTypes = true
        openPanel.begin { result in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                completion(openPanel.urls)
            } else {
                completion([])
            }
        }
    }
    
}
extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
}

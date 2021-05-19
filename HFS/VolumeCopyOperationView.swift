//
//  ContentView.swift
//  HFS
//
//  Created by Kevin Brewster on 4/9/21.
//

import SwiftUI

struct VolumeCopyOperationView: View {
    @ObservedObject var operation: VolumeCopyOperation
    let byteFormatter = ByteCountFormatter()
    
    var body: some View {
        HStack {
            switch operation.state {
            case .queued:
                Image(systemName: "externaldrive.badge.timemachine").font(.system(size: 44.0)).padding(.leading, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                VStack {
                    ProgressView(operation.volume.name, value: 0, total: 1.0)
                    Text("Queued..").frame(maxWidth: .infinity, alignment: .leading).foregroundColor(.gray)
                }.padding()
            
            case .copying(let file, let progress):
                Image(systemName: "externaldrive.badge.timemachine").font(.system(size: 44.0)).padding(.leading, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                VStack {
                    ProgressView(operation.volume.name, value: progress, total: 1.0)
                    Text(file).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1).foregroundColor(.gray)
                }.padding()
                
            case .finished(let totalBytesWritten):
                Image(systemName: "externaldrive.badge.checkmark").font(.system(size: 44.0)).padding(.leading, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                VStack {
                    ProgressView(operation.volume.name, value: 1.0, total: 1.0).progressViewStyle(LinearProgressViewStyle(tint: .green))
                    Text("Finished \(byteFormatter.string(fromByteCount: totalBytesWritten))").frame(maxWidth: .infinity, alignment: .leading).foregroundColor(.gray)
                }.padding()
            }
                
            
        }.overlay(Rectangle().frame(width: nil, height: 1, alignment: .bottom).foregroundColor(Color(white: 0.95)), alignment: .bottom)
        .contextMenu {
            Button(action: {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: operation.destination?.path ?? "")
            }) {
                Text("Show in Finder")
            }
        }
    }
}

/*
struct VolumeCopyOperationView_Previews: PreviewProvider {
    
    let operation = VolumeCopyOperation(URL(), nil, URL())
    static var previews: some View {
        VolumeCopyOperationView(operation: operation)
    }
}
*/

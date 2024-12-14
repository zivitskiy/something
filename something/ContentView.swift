//
//  ContentView.swift
//  something
//
//  Created by dev on 12.12.2024 16:10.
//

import SwiftUI
import Foundation

var date = NSDate()
let info = ProcessInfo.processInfo
let sys = info.operatingSystemVersionString

func neofetch() -> String {
    let task = Process()
    task.launchPath = "/usr/local/bin/neofetch"
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    var output = ""
    
    do {
        try task.run()
        
        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            
            if !data.isEmpty {
                if let str = String(data: data, encoding: .utf8) {
                    output += str
                    print(str)
                    
                    if str.isEmpty {
                        fileHandle.readabilityHandler = nil
                    }
                }
            }
        }
        
        task.waitUntilExit()
        
        return output
    } catch {
        let err = error.localizedDescription
        
        let fm = FileManager.default
        let path = "/usr/local/bin/neofetch"
        if !fm.fileExists(atPath: path) {
            return "Neofetch not found at \(path). Please ensure it's installed correctly."
        }
        
        let result = shell("which neofetch")
        if result.isEmpty {
            return "Neofetch not found in PATH. Please ensure it's installed correctly."
        }
        
        let manualrun = shell("/usr/local/bin/neofetch")
        if !manualrun.isEmpty {
            return "Failed to run neofetch: \(err)\nManual execution result:\n\(manualrun)"
        }
        
        return "An error occurred: \(err)"
    }
}

func shell(_ command: String) -> String {
    let task = Process()
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c", command]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
              let data = pipe.fileHandleForReading.readDataToEndOfFile()
              guard let output = String(data: data, encoding: .utf8) else {
            return ""
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        return "Error executing command: \(error.localizedDescription)"
    }
}

func directory() -> String {
    let fm = FileManager.default
    let currpath = fm.currentDirectoryPath
    let home = fm.homeDirectoryForCurrentUser.path
    
    if currpath == home {
        return "~"
    }
    else if currpath.hasPrefix(home) {
        let rel = currpath.replacingOccurrences(of: home, with: "~")
        return rel
    } else {
        return currpath
    }
}


// absoulte nonsence
struct OutputView: View {
    @State private var output: [String] = []
    @State private var input: String = ""
    @State private var dir = directory()
    
    let start = neofetch()
    let lefcw: CGFloat? = 400
    let lefhw: CGFloat? = 250
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Text(start)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: lefcw, maxHeight: lefhw, alignment: .center)
                    .background(Color.gray.opacity(0.1))
                    .padding()
                ScrollView {
                    Text("\(dir)\n\n\(shell("ls"))")
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(
                            maxWidth: lefcw,
                            minHeight: lefhw,
                            maxHeight: .infinity,
                            alignment: .leading
                        )
                        .background(Color.gray.opacity(0.1))
                        .padding()
                }
            }
            ScrollView {
                VStack(spacing: 10) {
                    if output.isEmpty {
                        Text("")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 75, maxHeight: 250)
                            .frame(idealHeight: 75)
                            .frame(alignment: .top)
                    } else {
                        ForEach(output, id: \.self) { stdout in
                            Text(stdout)
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 75, maxHeight: 250)
                                .frame(idealHeight: 75)
                                .frame(alignment: .top)
                                .background(Color.gray.opacity(0.1))
                        }
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .padding(.top)
            .frame(minHeight: 500)
        }
        .frame(maxHeight: .infinity)
        
        HStack {
            TextField("Enter command", text: $input)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.plain)
                .padding()
                .frame(maxWidth: .infinity)
                .frame(maxWidth: .infinity)
                .onSubmit {
                    dir = directory()
                    Show(input)
                }
        }
        .padding()
    }
    func Show(_ cmd: String) {
        output.append("\n  \(date.description.prefix(20))\n   % \(cmd)\n")
        output.append(shell(cmd))
        input = ""
    }
}

struct ContentView: View {
    var body: some View {
        OutputView()
    }
}

#Preview {
    ContentView()
}

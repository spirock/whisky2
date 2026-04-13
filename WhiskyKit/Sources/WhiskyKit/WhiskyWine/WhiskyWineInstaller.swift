//
//  WhiskyWineInstaller.swift
//  WhiskyKit
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import Foundation
import SemanticVersion

public class WhiskyWineInstaller {
    /// The Whisky application folder
    public static let applicationFolder = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
        )[0].appending(path: Bundle.whiskyBundleIdentifier)

    /// The folder of all the libfrary files
    public static let libraryFolder = applicationFolder.appending(path: "Libraries")

    /// URL to the installed `wine` `bin` directory
    public static let binFolder: URL = libraryFolder.appending(path: "Wine").appending(path: "bin")

    public static func isWhiskyWineInstalled() -> Bool {
        return whiskyWineVersion() != nil
    }

    public static func install(from: URL) {
        do {
            if !FileManager.default.fileExists(atPath: applicationFolder.path) {
                try FileManager.default.createDirectory(at: applicationFolder, withIntermediateDirectories: true)
            } else {
                try FileManager.default.removeItem(at: applicationFolder)
                try FileManager.default.createDirectory(at: applicationFolder, withIntermediateDirectories: true)
            }

            try Tar.untar(tarBall: from, toURL: applicationFolder)
            try FileManager.default.removeItem(at: from)
            
            createWineSymlinks()
            patchWithWhisky2()
        } catch {
            print("Failed to install WhiskyWine: \(error)")
        }
    }

    private static func patchWithWhisky2() {
        print("Starting Whisky2 Wine download...")
        let apiURL = URL(string: "https://api.github.com/repos/spirock/wine-macos-automated/releases/latest")!
        var whisky2URLStr = "https://github.com/spirock/wine-macos-automated/releases/latest/download/wine-proton-x86_64.tar.xz"
        
        let apiSemaphore = DispatchSemaphore(value: 0)
        let apiTask = URLSession.shared.dataTask(with: apiURL) { data, _, _ in
            defer { apiSemaphore.signal() }
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let name = asset["name"] as? String,
                       let downloadUrl = asset["browser_download_url"] as? String,
                       name.contains("wine-proton") && name.hasSuffix("x86_64.tar.xz") {
                          whisky2URLStr = downloadUrl
                          break
                    }
                }
            }
        }
        apiTask.resume()
        apiSemaphore.wait()

        guard let url = URL(string: whisky2URLStr) else { return }
        
        let tempDir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let destTar = tempDir.appending(path: "whisky2-wine.tar.xz")
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
            defer { semaphore.signal() }
            if let localURL = localURL {
                try? FileManager.default.moveItem(at: localURL, to: destTar)
            }
        }
        task.resume()
        semaphore.wait()
        
        guard FileManager.default.fileExists(atPath: destTar.path) else {
            print("Failed to download Whisky2 Wine, creating symlinks from existing wine binary...")
            createWineSymlinks()
            return
        }
        
        print("Extracting Whisky2 Wine...")
        try? Tar.untar(tarBall: destTar, toURL: libraryFolder)
        
        try? FileManager.default.removeItem(at: tempDir)
        
        print("Ensuring Wine symlinks are correct...")
        createWineSymlinks()
    }
    
    private static func createWineSymlinks() {
        let binPath = binFolder.path
        let wineBinary = "wine"
        
        let symlinksToCreate = [
            "wine64", "winecfg", "wineboot", "wineconsole", "winedbg",
            "winefile", "winemine", "winepath", "msidb", "msiexec",
            "notepad", "regedit", "regsvr32"
        ]
        
        for symlink in symlinksToCreate {
            let symlinkPath = (binPath as NSString).appendingPathComponent(symlink)
            let symlinkURL = URL(fileURLWithPath: symlinkPath)
            
            if FileManager.default.fileExists(atPath: symlinkPath) {
                var isDirectory: ObjCBool = false
                let exists = FileManager.default.fileExists(atPath: symlinkPath, isDirectory: &isDirectory)
                
                if exists && !isDirectory.boolValue {
                    if let target = try? FileManager.default.destinationOfSymbolicLink(atPath: symlinkPath) {
                        if target == wineBinary {
                            continue
                        }
                    }
                    try? FileManager.default.removeItem(at: symlinkURL)
                }
            }
            
            if !FileManager.default.fileExists(atPath: symlinkPath) {
                try? FileManager.default.createSymbolicLink(at: symlinkURL, withDestinationURL: URL(fileURLWithPath: wineBinary))
                print("Created symlink: \(symlink) -> \(wineBinary)")
            }
        }
    }

    public static func uninstall() {
        do {
            try FileManager.default.removeItem(at: libraryFolder)
        } catch {
            print("Failed to uninstall WhiskyWine: \(error)")
        }
    }

    public static func shouldUpdateWhiskyWine() async -> (Bool, SemanticVersion) {
        let versionPlistURL = "https://data.getwhisky.app/Wine/WhiskyWineVersion.plist"
        let localVersion = whiskyWineVersion()

        var remoteVersion: SemanticVersion?

        if let remoteUrl = URL(string: versionPlistURL) {
            remoteVersion = await withCheckedContinuation { continuation in
                URLSession(configuration: .ephemeral).dataTask(with: URLRequest(url: remoteUrl)) { data, _, error in
                    do {
                        if error == nil, let data = data {
                            let decoder = PropertyListDecoder()
                            let remoteInfo = try decoder.decode(WhiskyWineVersion.self, from: data)
                            let remoteVersion = remoteInfo.version

                            continuation.resume(returning: remoteVersion)
                            return
                        }
                        if let error = error {
                            print(error)
                        }
                    } catch {
                        print(error)
                    }

                    continuation.resume(returning: nil)
                }.resume()
            }
        }

        if let localVersion = localVersion, let remoteVersion = remoteVersion {
            if localVersion < remoteVersion {
                return (true, remoteVersion)
            }
        }

        return (false, SemanticVersion(0, 0, 0))
    }

    public static func whiskyWineVersion() -> SemanticVersion? {
        do {
            let versionPlist = libraryFolder
                .appending(path: "WhiskyWineVersion")
                .appendingPathExtension("plist")

            let decoder = PropertyListDecoder()
            let data = try Data(contentsOf: versionPlist)
            let info = try decoder.decode(WhiskyWineVersion.self, from: data)
            return info.version
        } catch {
            print(error)
            return nil
        }
    }
}

struct WhiskyWineVersion: Codable {
    var version: SemanticVersion = SemanticVersion(1, 0, 0)
}

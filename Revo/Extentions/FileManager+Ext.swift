//
//  FileManager+Ext.swift
//  Revo
//
//  Created by Waylan Sands on 7/12/20.
//

import UIKit


extension FileManager {
    
    static func fileExistsWith(path: String) -> Bool {
        if FileManager.default.fileExists(atPath: path) {
            return true
        } else {
            return false
        }
    }
    
    static func documentsDirectoryURL() -> URL {
         let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
         let documentsDirectory = paths[0]
         return documentsDirectory
     }
    
    
    static func clearDocumentsDirectory() {
        do {
            let contentURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectoryURL(), includingPropertiesForKeys: nil)
            for eachFile in contentURLs {
                try FileManager.default.removeItem(at: eachFile)
            }
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    static func printContentsOfDocumentsDirectory() {
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsDirectoryURL(), includingPropertiesForKeys: nil)
            if directoryContents.count == 0 {
                // The documents directory is empty
                return
            }
            for each in directoryContents {
                print("""
                    ****************************************
                    Content in documents folder
                    \(each.lastPathComponent)
                    """)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func lastFileAddedToDirectory() -> URL? {
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsDirectoryURL(), includingPropertiesForKeys: nil)
            if directoryContents.count == 0 {
                // The documents directory is empty
                return nil
            } else {
                var fileNames = [String]()
                for each in directoryContents {
                    let date = each.lastPathComponent
                    fileNames.append(date)
                }
                let sortedFiles = fileNames.sorted()
                let lastFile = sortedFiles.last!
                let docURL = documentsDirectoryURL()
                return docURL.appendingPathComponent(lastFile)
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    static func getFileURLsFromDocumentsDirectory() -> [URL]? {
        let docDirectory = documentsDirectoryURL()
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: docDirectory, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    static func removeItemWith(url: URL) {
        if fileExistsWith(path: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    //MARK: - Could use if adding photo capture capabilities
    
    static func getImageFromDocumentDirectoryWith(url: URL) -> UIImage? {
        if fileExistsWith(path: url.path) {
            let data = FileManager.default.contents(atPath: url.path)!
            return UIImage(data: data)
        } else {
            print("File not in directory")
            return nil
        }
    }
    
    static func saveImageToDocuments(image: UIImage, completion: @escaping (Bool) -> ()) {
        guard let data = image.jpegData(compressionQuality: 1) else {
            completion(false)
            return
        }

        let documentsURL = documentsDirectoryURL()
        let fileName = String(Date().timeIntervalSince1970)
        let filePath = documentsURL.appendingPathComponent("\(fileName).jpg")

        do {
            try data.write(to: filePath)
            completion(true)
        }
        catch {
            print("Unable to Write Data to Disk (\(error))")
            completion(false)
        }
    }
    
}

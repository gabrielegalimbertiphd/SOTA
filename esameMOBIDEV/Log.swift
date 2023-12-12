//
//  Log.swift
//  STTN
//
//  Created by OS Programming on 22/06/23.
//

import Foundation

class Log {
    public var file : String? = nil
    private var timer = Timer()
    public var logs = [String]()
    
    func logAsync(logDescription: String){
        
        self.logs.append("\(logDescription)\n")
        /*var text = ""
        for log in self.logs {
            text.append(log)
        }
        if self.file != nil {
            self.append(text: text, toFile: self.file!)
    
        }*/
        //self.logs.removeAll()
    }
    
    func destinationReached(exit_from_app: Bool){
        ///2 secondi in più per vedere quando si ferma dopo il ping
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.timer.invalidate()
            var text = ""
            for log in self.logs {
                text.append(log)
            }
            if self.file != nil {self.append(text: text, toFile: self.file!)}
            self.logs.removeAll()
            
            /*if !exit_from_app==true{
                Synth.shared.volume = 0
                exit(0)
            }*/
        }
    }
    
    func createDirectory(_ FolderName: String){
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryURL = documentDirectoryURL.appendingPathComponent(FolderName, isDirectory: true)
                
        /*if FileManager.default.fileExists(atPath: directoryURL.path) {
             print(directoryURL.path)
        } else {
            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                print(directoryURL.path)
            } catch {
                print(error.localizedDescription)
            }
        }*/
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            print(directoryURL.path)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func documentDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    }
    
    private func appendPath(toPath path: String, withPathComponent pathComponent: String) -> String? {
        if var pathURL = URL(string: path) {
            pathURL.appendPathComponent(pathComponent)
            return pathURL.absoluteString
        }
        return nil
    }
    
    func read(fromDocumentsWithFileName fileName: String) -> String? {
        guard let filePath = self.appendPath(toPath: self.documentDirectory(), withPathComponent: fileName) else {return nil}
        do {
            let savedString = try String(contentsOfFile: filePath)
            return savedString
        } catch {
            print("Error reading saved file")
            return nil
        }
    }
    
    func save(text: String, withFileName fileName: String) -> Bool {
        guard let path = self.appendPath(toPath: self.documentDirectory(), withPathComponent: fileName) else {return false}
        do {
            try text.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            print("Error", error)
            return false
        }
        print("Save successful")
        return true
    }
    
    func append(text: String, toFile fileName: String) -> Bool {
        guard let fileText = read(fromDocumentsWithFileName: fileName) else {
            return save(text: text, withFileName: fileName)
        }
        return save(text: "\(fileText)\(text)", withFileName: fileName)
    }
}

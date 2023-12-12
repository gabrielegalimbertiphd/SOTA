//
//  Logger.swift
//  esameMOBIDEV
//
//  Created by Marco on 12/09/21.
//

import Foundation


class Logger{
    
    private let navigator : Navigator
    private let audioController : AudioController
    private var file : String? = nil
    private var timer = Timer()
    var userName : String = "UserName"
    var position : (Float, Float, Float) = (0.0, 0.0, 0.0)
    var orientation : (Float, Float, Float) = (0.0, 0.0, 0.0)
    var distanceFromNextPoint : Float? = nil
    var stretchLength : Float? = nil
    var anchoredImage : String? = nil
    var sonificationName = "Ping"
    var actualIndicationSonified : String? = nil
    private var logs = [String]()
    
    init(navigator: Navigator, audioController: AudioController){
        self.navigator = navigator
        self.audioController = audioController
        self.audioController.register(logger: self)
    }
    
    func startedNavigation(pathName: String, sonification: Int){
        switch sonification {
        case 0:
            self.sonificationName = "BASE"
        case 1:
            self.sonificationName = "IS"
        case 2:
            self.sonificationName = "MS"
        default:
            break
        }
        file = "\(NSDate().timeIntervalSince1970)_\(userName)_\(pathName)_\(self.sonificationName).txt"
//        fileUserPos = "UserPos_\(userName)_\(pathName)_\(self.sonificationName).txt"
        
//        self.timerUserPos = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {_ in
//            let text = "\(NSDate().timeIntervalSince1970), \(self.navigator.position!.row), \(self.navigator.position!.col), \(self.anchoredImage ?? "")"
//            self.userPosLogs.append("\(text)\n")
//        }
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) {_ in
            //            var sonificatingText = "\(self.actualIndicationSonified ?? "")"
            //            if self.actualIndicationSonified != nil && self.actualIndicationSonified != "Prosegui dritto" {
            //                sonificatingText = "\(self.actualIndicationSonified!), \(self.previousRotationSideRight)"
            //            }
            self.logAsync()
            //            let diffAngle = abs(self.navigator.orientationAngle!-self.previousRotationAngle)
            //            if self.actualIndicationSonified == nil || self.actualIndicationSonified == "Prosegui dritto" {
            //                self.stopLogging()
            //            }
            
            //            self.previousRotationSideRight = self.navigator.orientationAngle! < self.previousRotationAngle
            //            self.previousRotationAngle = self.navigator.orientationAngle
        }
    }
    
    func logAsync(logDescription: String? = nil){
        let text = "\(NSDate().timeIntervalSince1970),\(self.position.0),\(self.position.1),\(self.position.2),\(self.orientation.0),\(self.orientation.1),\(self.orientation.2),\(self.anchoredImage ?? ""),\(self.navigator.actualTurn),\(self.audioController.angleLength ?? -1),\(self.navigator.orientationAngle ?? -1),\(self.stretchLength ?? -1),\(self.distanceFromNextPoint ?? -1),\(self.navigator.position?.row ?? -1),\(self.navigator.position?.col ?? -1),\(self.actualIndicationSonified ?? ""),\(self.navigator.distanceFromPath ?? -1),\(logDescription ?? "")"
        ///Colonne: timestamp, X, Y, Z, rotX, rotY, rotZ,, immagine ancorata, numero svolta in corso, indicazioni attualmente sonificate, girando a destra (true) o a sinistra (false) DA AGGIORNARE
        self.logs.append("\(text)\n")
        if logDescription != nil {
            var text = ""
            for log in self.logs {
                text.append(log)
            }
            if self.file != nil {self.append(text: text, toFile: self.file!)}
            self.logs.removeAll()
        }
    }
    
    func destinationReached(){
//        self.timerUserPos.invalidate()
//        var text = ""
//        for log in self.userPosLogs {
//            text.append(log)
//        }
//        if self.fileUserPos != nil {self.append(text: text, toFile: self.fileUserPos!)}
//        self.userPosLogs.removeAll()
        ///2 secondi in più per vedere quando si ferma dopo il ping
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.timer.invalidate()
            var text = ""
            for log in self.logs {
                text.append(log)
            }
            if self.file != nil {self.append(text: text, toFile: self.file!)}
            self.logs.removeAll()
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
    
    func notify(label: String?){
        self.logAsync(logDescription: label)
    }
}

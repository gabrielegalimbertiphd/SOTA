//
//  SoundSynth.swift
//  esameMOBIDEV
//
//  Created by Marco on 17/07/21.
//

import Foundation
import AVFoundation

class AudioController {
    
    private var tickPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "Tick", ofType: "mp3")!))
    private var dingPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "ShortDing", ofType: "mp3")!))
    private var notePlayer = AVAudioPlayer()
    private let voice = AVSpeechSynthesisVoice(language: "en-US")!// "it-IT")!
    private var synthesizer = AVSpeechSynthesizer()
    var lastText = ""
    private var beeping = false
    private var lastAngleSector = 1
    var selectedSonification = 0 ///0: Ping     1: Tick     2: Notes
    var stretchLength : Float? = nil
    var angleLength : Float? = nil
    private weak var logger : Logger? = nil
    private var timeLastThingSaid = NSDate().timeIntervalSince1970-7
    private var timeLastDing = NSDate().timeIntervalSince1970-7
    public var lastThingSaid = ""
    public var previousThingSaid = ""
    var translate_text:String = ""
    
    public var readInstruction : Bool = false
    
    public var num_turn : Int = 0
    public var num_lateral : Int = 0
    public var num_walk : Int = 0
    
    public var startSonification : Bool = false
    
    func speak(text: String, rotation: Float? = nil, distanceFromTurn: Float? = nil) -> String {
        
        guard self.lastText != text else {
            readInstruction = false
            var output: String = ""
            if self.startSonification{
                output=self.sonificate(text: text, rotation: rotation, distanceFromTurn: distanceFromTurn)
            }
            return output
        }
        
        self.synthesizer.stopSpeaking(at: .immediate)
        let actualText = text == "Prosegui dritto" ? "\(text) per \(distanceFromTurn!<2 ? "circa un metro":"\(Int(distanceFromTurn!).description) metri")":text
        
        if text.contains("Prosegui"){
            num_turn=num_turn+1
        } else if text.contains("Gira"){
            num_walk=num_walk+1
        } else if text.contains("Spostati"){
            num_lateral=num_lateral+1
        }
        
        // # translate from italian to english
        if actualText == "Destinazione raggiunta" {
            translate_text = "Destination reached"
        } else if actualText.contains("spostati a")  {
            if actualText=="Spostati a destra"{
                translate_text = "Move on Right"
            } else if actualText=="Spostati a sinistra"{
                translate_text = "Move on Left"
            }
        } else if actualText.contains("Gira a")  {
            if actualText=="Gira a destra"{
                translate_text = "Turn Right"
            } else if actualText=="Gira a sinistra"{
                translate_text = "Turn Left"
            }
        } else if actualText.contains("Prosegui") {
            if actualText.contains("circa") {
                translate_text = "Go ahead for one meter"
            } else {
                translate_text = "Go ahead for \(Int(distanceFromTurn!).description) meters"
            }
        } else {
            translate_text = ""
        }
        
        let utterance = AVSpeechUtterance(string: translate_text)
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0
        utterance.preUtteranceDelay = 0
        utterance.voice = self.voice
        
        if text == "Prosegui dritto" {
            self.playGoalReachedSound(description: "1")
            self.stretchLength = distanceFromTurn!
            self.angleLength = nil
            self.timeLastDing = NSDate().timeIntervalSince1970
        }else if text == "Gira a sinistra" || text == "Gira a destra" {
            if logger != nil && self.lastText == "Prosegui dritto" {
                self.logger!.notify(label: "0")
            }
            self.angleLength = 180-abs((rotation!-180).truncatingRemainder(dividingBy: 180))
            self.stretchLength = nil
        }
        previousThingSaid = self.lastText
        self.lastText = text
        synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        readInstruction = true
        self.startSonification=false
        Synth.shared.volume = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {//+ 1.2){
            self.startSonification=true
            do {
                if text.contains("Prosegui"){
                    Synth.shared.setWaveformTo(Oscillator.square)
                } else if text.contains("Gira"){
                    Synth.shared.setWaveformTo(Oscillator.square)
                } else if text.contains("Spostati"){
                    Synth.shared.setWaveformTo(Oscillator.square)
                } else{
                    self.startSonification=false
                }
                Synth.shared.volume = 0.8
            } catch {
                print("Could not start engine: \(error.localizedDescription)")
            }
        }
        return self.sonificate(text: text, rotation: rotation, distanceFromTurn: distanceFromTurn)
    }
    
    private func sonificate(text: String, rotation: Float? = nil, distanceFromTurn: Float? = nil) -> String {
        guard !beeping else {return text}
        if text == self.lastText && (text == "Gira a destra" || text == "Gira a sinistra") && angleLength != nil{
            let normRotation : Float = 180-abs((rotation!-180).truncatingRemainder(dividingBy: 180))
            switch selectedSonification{
                case 1:
                    if normRotation > self.angleLength! {
                        self.startTicking(duration: 1)
                    }else{
//                        let duration : Double = 1.065-Double(pow(1-min(abs(normRotation/self.angleLength!),1),4))
//                        self.startTicking(duration: duration)
                        let duration = 1 + 14 * pow(1-min(abs(normRotation/self.angleLength!),1),4)
                        self.startTicking(duration: duration)
                    }
                default:
                    let duration = 1 + 14 * pow(1-min(abs(normRotation/self.angleLength!),1),4)
                    self.startTicking(duration: duration)
            }
        }else if text == "Prosegui dritto" && self.lastText == "Prosegui dritto" && stretchLength != nil{
            switch selectedSonification{
                case 1:
                    let duration = 1+14*pow(1-min(abs((distanceFromTurn!/stretchLength!)),1),4)
                    self.startTicking(duration: duration)
                default:
                    let duration = 1+14*pow(1-min(abs((distanceFromTurn!/stretchLength!)),1),4)
                    self.startTicking(duration: duration)
            }
        }
        return text
    }
    
    private func startTicking(duration: Float){
        if self.synthesizer.isSpeaking && Synth.shared.volume != 0{
            Synth.shared.volume = 0
        } else if !self.synthesizer.isSpeaking && Synth.shared.volume == 0{
            Synth.shared.volume = 0.8
        }
//        tickPlayer.currentTime = 0
//        tickPlayer.play()
//        self.beeping = true
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1/7) {
//            self.tickPlayer.stop()
//            self.beeping = false
//        }
        let frequency = Float(round(1000*duration)/1000)
        if Synth.shared.frequency != frequency {
            Synth.shared.frequency = frequency

        }
    }
    
    func say(_ text: String, important: Bool = false){
        guard ((lastThingSaid != text || NSDate().timeIntervalSince1970 - self.timeLastThingSaid > 7) && NSDate().timeIntervalSince1970 - self.timeLastDing > 7) || important else {return}
        
        if important {
            self.synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0
        utterance.preUtteranceDelay = 0
        utterance.voice = self.voice
        synthesizer.speak(utterance)
        
        self.timeLastThingSaid = NSDate().timeIntervalSince1970
        self.lastThingSaid = text
        self.notifyLogger(text: text)
    }
    
    func notifyLogger(text: String){
        guard self.logger != nil else {return}
        switch text{
        case "Destinazione raggiunta":
            self.logger!.notify(label: "5")
        case "Spostati a Destra":
            self.logger!.notify(label: "3")
        case "Spostati a Sinistra":
            self.logger!.notify(label: "4")
        default:
            return
        }
    }
    
    func playGoalReachedSound(description: String? = nil){
        if logger != nil {
            self.logger!.notify(label: description)
        }
        dingPlayer.play()
        if selectedSonification == 2 {
            notePlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "C5", ofType: "wav")!))
            notePlayer.play()
        }
    }
    
    func register(logger: Logger){
        self.logger = logger
    }
    
    func changeSonification(_ imageName: String) -> Bool{
        switch imageName {
            case "Son0Ping":
                if self.selectedSonification != 0 {
                    self.selectedSonification = 0
                    //self.say("Sonificazione ping attiva")
                    Synth.shared.audioEngine.stop()
                }
                return true
            case "Son1Tick":
                if self.selectedSonification != 1 {
                    self.selectedSonification = 1
                    // self.say("Sonificazione intermittente attiva")
                    do {
                        try Synth.shared.audioEngine.start()
                        Synth.shared.setWaveformTo(Oscillator.square)
                    } catch {
                        print("Could not start engine: \(error.localizedDescription)")
                    }
                }
                return true
            default:
                self.selectedSonification = 1
                return true
        }
    }
    
    func getDirection(rotation: Float, distanceFromTurn: Float? = nil) -> String {
        if (self.lastText == "Gira a destra" && 1..<180 ~= rotation) || (self.lastText != "Gira a destra" && 30..<180 ~= rotation){
            return self.speak(text: "Gira a destra", rotation: rotation)
        }else if (self.lastText == "Gira a sinistra" && 180...359 ~= rotation) || (self.lastText != "Gira a sinistra" && 180...330 ~= rotation){
            return self.speak(text: "Gira a sinistra", rotation: rotation)
        }else{
            return self.speak(text: "Prosegui dritto", distanceFromTurn: distanceFromTurn)
        }
    }
    
}

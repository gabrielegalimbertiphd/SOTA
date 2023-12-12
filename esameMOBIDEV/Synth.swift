//
//  Synth.swift
//  esameMOBIDEV
//
//  Created by Marco on 15/10/21.
//

import AVFoundation
import Foundation

import AVFoundation

class Synth {
    
//    // MARK: Properties
//
//    public static let shared = Synth()
//    public var volume: Float {
//        set {
//            audioEngine.mainMixerNode.outputVolume = newValue
//        }
//        get {
//            return audioEngine.mainMixerNode.outputVolume
//        }
//    }
//    var audioEngine: AVAudioEngine
//    private var time: Float = 0
//    private let sampleRate: Double
//    private let deltaTime: Float
//
//    private lazy var sourceNode = AVAudioSourceNode { (_, _, frameCount, audioBufferList) -> OSStatus in
//        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
//        for frame in 0..<Int(frameCount) {
//            let sampleVal = self.signal(self.time)
//            self.time += self.deltaTime
//            for buffer in ablPointer {
//                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
//                buf[frame] = sampleVal
//            }
//        }
//        return noErr
//    }
//
//    private var signal: Signal
//
//    init(signal: @escaping Signal = Oscillator.sine) {
//        audioEngine = AVAudioEngine()
//
//
//        let mainMixer = audioEngine.mainMixerNode
//        let outputNode = audioEngine.outputNode
//        let format = outputNode.inputFormat(forBus: 0)
//
//
//        sampleRate = format.sampleRate
//        deltaTime = 1 / Float(sampleRate)
//
//            self.signal = signal
//
//
//        let inputFormat = AVAudioFormat(commonFormat: format.commonFormat, sampleRate: sampleRate, channels: 1, interleaved: format.isInterleaved)
//        audioEngine.attach(sourceNode)
//        audioEngine.connect(sourceNode, to: mainMixer, format: inputFormat)
//        audioEngine.connect(mainMixer, to: outputNode, format: nil)
//        mainMixer.outputVolume = 0
//    }
//
//    // MARK: Public Functions
//
//    public func setWaveformTo(_ signal: @escaping Signal) {
//        self.signal = signal
//    }
    
    // MARK: Properties
    
    public static let shared = Synth()
    
    public var volume: Float {
        set {
            audioEngine.mainMixerNode.outputVolume = newValue
        }
        get {
            audioEngine.mainMixerNode.outputVolume
        }
    }
    
    public var frequencyRampValue: Float = 0
    
    public var frequency: Float = 1 {
        didSet {
            if oldValue != 0 {
                frequencyRampValue = frequency - oldValue
            } else {
                frequencyRampValue = 0
            }
        }
    }
    
    var audioEngine: AVAudioEngine
    private lazy var sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList in
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        
        let localRampValue = self.frequencyRampValue
        let localFrequency = self.frequency - localRampValue
        
        let period = 1 / localFrequency
        
        for frame in 0..<Int(frameCount) {
            let percentComplete = self.time / period
            let sampleVal = self.signal(localFrequency + localRampValue * percentComplete, self.time)
            self.time += self.deltaTime
            self.time = fmod(self.time, period)
            
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = sampleVal
            }
        }
        
        self.frequencyRampValue = 0
        
        return noErr
    }
    
    private var time: Float = 0
    private let sampleRate: Double
    private let deltaTime: Float
    
    private var signal: Signal
    
    // MARK: Init
    
    init(signal: @escaping Signal = Oscillator.sine) {
        audioEngine = AVAudioEngine()
        
        let mainMixer = audioEngine.mainMixerNode
        let outputNode = audioEngine.outputNode
        let format = outputNode.inputFormat(forBus: 0)
        
        sampleRate = format.sampleRate
        deltaTime = 1 / Float(sampleRate)
        
        self.signal = signal
        
        let inputFormat = AVAudioFormat(commonFormat: format.commonFormat,
                                        sampleRate: format.sampleRate,
                                        channels: 1,
                                        interleaved: format.isInterleaved)
        
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: mainMixer, format: inputFormat)
        audioEngine.connect(mainMixer, to: outputNode, format: nil)
        mainMixer.outputVolume = 0
        
    }
    
    // MARK: Public Functions
    
    public func setWaveformTo(_ signal: @escaping Signal) {
        self.signal = signal
    }
    
}

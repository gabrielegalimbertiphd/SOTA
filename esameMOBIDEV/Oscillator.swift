//
//  Oscillator.swift
//  esameMOBIDEV
//
//  Created by Marco on 15/10/21.
//

import Foundation

typealias Signal = (_ frequency: Float, _ time: Float) -> Float

enum Waveform: Int {
    case sine, sawtooth, square
}

struct Oscillator {
    
//    static var amplitude: Float = 1
//
//    static var frequency: Float = 1
//
//    static let sine = { (time: Float) -> Float in
//        return Oscillator.amplitude * sin(2.0 * Float.pi * Oscillator.frequency * time)
//    }
//
//    static let sawtooth = { (time: Float) -> Float in
//        let period = 1.0 / Oscillator.frequency
//        let currentTime = fmod(Double(time), Double(period))
//        return Oscillator.amplitude * ((Float(currentTime) / period) * 2 - 1.0)
//    }
//
//    static let square = { (time: Float) -> Float in
//        let period = 1.0 / Double(Oscillator.frequency)
//        let currentTime = fmod(Double(time), period)
//        return ((currentTime / period) < 0.5) ? Oscillator.amplitude : -1.0 * Oscillator.amplitude
//    }
    
    static var amplitude: Float = 1
    
    static let sine: Signal = { frequency, time in
        return Oscillator.amplitude * sin(2.0 * Float.pi * frequency * time)
    }
    
    static let sawtooth: Signal = { frequency, time in
        let period = 1.0 / frequency
        let currentTime = fmod(Double(time), Double(period))
        return Oscillator.amplitude * ((Float(currentTime) / period) * 2 - 1.0)
    }
    
    static let square: Signal = { frequency, time in
        let period = 1.0 / Double(frequency)
        let currentTime = fmod(Double(time), period)
        return ((currentTime / period) < 0.5) ? Oscillator.amplitude : -1.0 * Oscillator.amplitude
    }
}

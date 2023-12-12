//
//  Navigator.swift
//  esameMOBIDEV
//
//  Created by Marco on 04/10/21.
//

import Foundation

class Navigator{
    var position : MatrixCoord? = nil
    var orientationAngle : Float? = nil
    var nextDestination : MatrixCoord? = nil
    var path : [MatrixCoord]? = nil
    var actualTurn : Int = 1
    var distanceFromPath : Float? = nil
    
    func destinationReached(){
        self.orientationAngle = nil
        self.nextDestination = nil
        self.path = nil
        self.distanceFromPath = nil
        self.actualTurn = 1
    }
}

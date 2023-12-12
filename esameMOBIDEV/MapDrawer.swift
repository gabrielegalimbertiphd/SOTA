//
//  MapDrawer.swift
//  esameMOBIDEV
//
//  Created by Marco on 12/07/21.
//

import Foundation
import UIKit

struct MapDrawer{
    private let canvasSize = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
    private let mapImage : UIImageView
    private let renderer : UIGraphicsImageRenderer
    private let mapMatrix : MapMatrix
    
    init(map: MapMatrix, imageView : UIImageView){
        self.mapMatrix = map
        self.mapImage = imageView
        self.mapImage.contentMode = .scaleAspectFit
        self.renderer = UIGraphicsImageRenderer(size: CGSize(width: map.matrixSize, height: map.matrixSize))
    }
    
    func drawPathOnMap(path: [MatrixCoord]){
        let img = self.renderer.image { ctx in
            if path.count != 0 {
                ctx.cgContext.setLineWidth(CGFloat(4))
                ctx.cgContext.setFillColor(UIColor.blue.cgColor)
                for point in path {
                    ctx.cgContext.addArc(center: CGPoint(x: point.row, y: point.col), radius: 10, startAngle: 0, endAngle: .pi*2, clockwise: true)
                    ctx.cgContext.fillPath()
                }
            }
        }
        
        let pathView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        pathView.image = img
        self.mapImage.subviews[1].removeFromSuperview()
        self.mapImage.insertSubview(pathView, at: 1)
    }
    
    func drawUserOnMap(row: Int, col: Int){
        let img = self.renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.green.cgColor)
            ctx.cgContext.addArc(center: CGPoint(x: row, y: col), radius: 8, startAngle: 0, endAngle: .pi*2, clockwise: true)
            ctx.cgContext.fillPath()
        }
        
        let userView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        userView.image = img
        self.mapImage.subviews[4].removeFromSuperview()
        self.mapImage.insertSubview(userView, at: 4)
    }
    
    func drawWorkOnMap(row: Int, col: Int){
        let img = self.renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.magenta.cgColor)
            ctx.cgContext.addArc(center: CGPoint(x: row, y: col), radius: 8, startAngle: 0, endAngle: .pi*2, clockwise: true)
            ctx.cgContext.fillPath()
        }
        
        let workView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        workView.image = img
        self.mapImage.subviews[2].removeFromSuperview()
        self.mapImage.insertSubview(workView, at: 2)
    }
    
    func drawObstacle(row: Int, col: Int){
        let img = self.renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.red.cgColor)
            ctx.cgContext.addRect(CGRect(x: row-10, y: col-10, width: 20, height: 20))
            ctx.cgContext.fillPath()
        }
        
        let workView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        workView.image = img
        self.mapImage.subviews[3].removeFromSuperview()
        self.mapImage.insertSubview(workView, at: 3)
    }
    
    func drawMap(_ map: MapMatrix) {
        let img = self.renderer.image { ctx in
            ctx.cgContext.setStrokeColor(UIColor.orange.cgColor)
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.setLineWidth(CGFloat(5))
            for polyLine in map.wallsVertex {
                ctx.cgContext.move(to: CGPoint(x: polyLine.first!.row, y: polyLine.first!.col))
                for i in (1..<polyLine.count){
                    let nextVertex = polyLine[i]
                    ctx.cgContext.addLine(to: CGPoint(x: nextVertex.row, y: nextVertex.col))
                }
                ///Se è un perimetro lo riempie anche altrimenti disegna solo il muro
                if polyLine.first! == polyLine.last! {
                    ctx.cgContext.drawPath(using: CGPathDrawingMode.fillStroke)
                }else{
                    ctx.cgContext.drawPath(using: CGPathDrawingMode.stroke)
                }
            }
//            for row in (0..<self.mapMatrix.tiles.count){
//                for col in (0..<self.mapMatrix.tiles[0].count) {
//                    if self.mapMatrix.tiles[row][col].type == .WALL{
//                        ctx.cgContext.addArc(center: CGPoint(x: row, y: col), radius: 2, startAngle: 0, endAngle: .pi*2, clockwise: true)
//                        ctx.cgContext.setFillColor(UIColor.red.cgColor)
//                        ctx.cgContext.fillPath()
//                    }else if self.mapMatrix.tiles[row][col].type == .NEXT_TO_WALL{
//                        ctx.cgContext.addArc(center: CGPoint(x: row, y: col), radius: 2, startAngle: 0, endAngle: .pi*2, clockwise: true)
//                        ctx.cgContext.setFillColor(UIColor.blue.cgColor)
//                        ctx.cgContext.fillPath()
//                    }else{
//                        ctx.cgContext.addArc(center: CGPoint(x: row, y: col), radius: 2, startAngle: 0, endAngle: .pi*2, clockwise: true)
//                        ctx.cgContext.setFillColor(UIColor.white.cgColor)
//                        ctx.cgContext.fillPath()
//                    }
//                }
//            }
        }

        let wallsView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        wallsView.image = img
        self.mapImage.insertSubview(wallsView, at: 0)
        let invisiblePathView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        self.mapImage.insertSubview(invisiblePathView, at: 1)
        let invisibleWorkView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        self.mapImage.insertSubview(invisibleWorkView, at: 2)
        let invisibleObstacleView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        self.mapImage.insertSubview(invisibleObstacleView, at: 3)
        let invisibleUserView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        self.mapImage.insertSubview(invisibleUserView, at: 4)
        let invisibleUserProjectionView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        self.mapImage.insertSubview(invisibleUserProjectionView, at: 5)
    }
    
    func drawUserProjection(row: Int, col: Int){
        let img = self.renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.gray.cgColor)
            ctx.cgContext.addArc(center: CGPoint(x: row, y: col), radius: 12, startAngle: 0, endAngle: .pi*2, clockwise: true)
            ctx.cgContext.fillPath()
        }
        
        let workView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        workView.image = img
        self.mapImage.subviews[5].removeFromSuperview()
        self.mapImage.insertSubview(workView, at: 5)
    }
    
    func drawTemp(row: Int, col: Int){
        let img = self.renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.orange.cgColor)
            ctx.cgContext.addArc(center: CGPoint(x: row, y: col), radius: 12, startAngle: 0, endAngle: .pi*2, clockwise: true)
            ctx.cgContext.fillPath()
        }
        
        let workView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        workView.image = img
        self.mapImage.subviews[1].removeFromSuperview()
        self.mapImage.insertSubview(workView, at: 1)
    }
    
    func drawNewPath(path: [MatrixCoord]){
        let img = self.renderer.image { ctx in
            if path.count != 0 {
                ctx.cgContext.setLineWidth(CGFloat(6))
                ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
                ctx.cgContext.move(to: CGPoint(x: path.first!.row, y: path.first!.col))
                for i in (1..<path.count){
                    let nextVertex = path[i]
                    ctx.cgContext.addLine(to: CGPoint(x: nextVertex.row, y: nextVertex.col))
                }
                ctx.cgContext.drawPath(using: CGPathDrawingMode.stroke)
            }
        }
        
        let pathView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        pathView.image = img
        self.mapImage.subviews[5].removeFromSuperview()
        self.mapImage.insertSubview(pathView, at: 5)
    }
    
    func destinationReached(){
        let invisiblePathView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        self.mapImage.subviews[1].removeFromSuperview()
        self.mapImage.insertSubview(invisiblePathView, at: 1)
        let invisibleLinePathView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        self.mapImage.subviews[5].removeFromSuperview()
        self.mapImage.insertSubview(invisibleLinePathView, at: 5)
    }
    
//    func drawUols(_ points: [MatrixCoord]){
//        let img = self.renderer.image { ctx in
//            for point in points{
//                ctx.cgContext.setFillColor(UIColor.black.cgColor)
//                ctx.cgContext.addArc(center: CGPoint(x: point.row, y: point.col), radius: 2, startAngle: 0, endAngle: .pi*2, clockwise: true)
//                ctx.cgContext.fillPath()
//            }
//        }
//
//        let pathView = UIImageView(frame: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
//        pathView.image = img
//        self.mapImage.subviews[5].removeFromSuperview()
//        self.mapImage.insertSubview(pathView, at: 5)
//    }
    
}

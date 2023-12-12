//
//  PathFinder.swift
//  esameMOBIDEV
//
//  Created by Marco on 23/06/21.
//

import Foundation
import GameplayKit

class PathFinder {
    var graph: GKGridGraph<GKGridGraphNode>
    let graphScale : Int32 = 10
    let pathStep = 6
    ///Variabili per percorsi harcoded dei test
    private let paths : [PathOnMatrix]
    var currentPath : String? = nil
    
    
    init(mapGrid: [[MapTile]], paths: [PathOnMatrix]){
        ///La griglia del grafo è in scala 1:10 per questioni di performance
        self.graph = GKGridGraph(
            fromGridStartingAt: [0,0],
            width: Int32(mapGrid[0].count)/graphScale,
            height: Int32(mapGrid.count)/graphScale,
            diagonalsAllowed: false,
            nodeClass: GraphNodeType.self)
        ///Rimuove direttamente tutte le connessioni dai nodi che rappresentano muri così che non possano essere attraversati e aggiunge peso di 10 ai vicini dei muri
        for (i, row) in mapGrid.enumerated(){
            for (j, tile) in row.enumerated(){
                if tile.type == NodeType.WALL {
                    let node = self.graph.node(atGridPosition: [Int32(i)/graphScale,Int32(j)/graphScale]) as! GraphNodeType
                    for nearWall in node.connectedNodes as! [GraphNodeType]{
                        if nearWall.type == NodeType.EMPTY {
                            nearWall.type = NodeType.NEXT_TO_WALL
//                            nearWall.removeConnections(to: nearWall.connectedNodes, bidirectional: true)
                        }
                    }
                    node.type = NodeType.WALL
                    node.removeConnections(to: node.connectedNodes, bidirectional: true)
                }
            }
        }
        
        self.paths = paths
    }
    
    func findPath(from_x: Int32, from_y: Int32, to_x: Int32, to_y: Int32, workPosition: MatrixCoord? = nil) -> [MatrixCoord]{
        var path = [MatrixCoord]()
        let nodePath = self.graph.findPath(
            from: self.graph.node(atGridPosition: [from_x/graphScale, from_y/graphScale])!,
            to: self.graph.node(atGridPosition: [to_x/graphScale, to_y/graphScale])!) as! [GKGridGraphNode]
        ///Restituisce solo un punto ogni 6 e aggiunge sempre l'ultimo in caso sia troppo distante l'ultimo disegnato/6
        for i in stride(from: 0, to: nodePath.count, by: pathStep) {
            path.append((Int(nodePath[i].gridPosition.x*graphScale), Int(nodePath[i].gridPosition.y*graphScale)))
        }
        ///Aggiunge ultimo puntino se l'ultimo puntino in caso fosse troppo lontano l'ultimo puntino effettivo
        if nodePath.count%pathStep>=4 {
            path.append((Int(nodePath.last!.gridPosition.x*graphScale), Int(nodePath.last!.gridPosition.y*graphScale)))
        }
//        if workPosition != nil {
//            path.append(workPosition!)
//        }
        return path
    }
    
    ///Restituisce [] per far terminare navigazione
    func getPath(markerName: String) -> ([MatrixCoord]?, String) {
        if markerName == "56v1" && currentPath == nil {
            self.currentPath = "Percorso1"
            return (self.paths.first(where: {$0.name == "Percorso1"})!.coordinate, "Percorso1")
        } else if markerName == "58v1" && currentPath == nil {
            self.currentPath = "Percorso2"
            return (self.paths.first(where: {$0.name == "Percorso2"})!.coordinate, "Percorso2")
        } else if markerName == "60v1" && currentPath == nil {
            self.currentPath = "Percorso3"
            return (self.paths.first(where: {$0.name == "Percorso3"})!.coordinate, "Percorso3")
        } else if markerName == "62v1" && currentPath == nil {
            self.currentPath = "Percorso4"
            return (self.paths.first(where: {$0.name == "Percorso4"})!.coordinate, "Percorso4")
        } else if (markerName == "57v1" && currentPath == "Percorso1") || (markerName == "59v1" && currentPath == "Percorso2") || (markerName == "61v1" && currentPath == "Percorso3") ||  (markerName == "87v1" && currentPath == "Percorso4") || markerName == "Stop"{
            self.currentPath = nil
            return ([], "Stop")
        } else if (markerName == "0v1" && currentPath == nil){
            currentPath = "Prova"
            return ([], "Prova")
        }
        return (nil, "")
    }
}

enum NodeType {
    case EMPTY
    case NEXT_TO_WALL
    case WALL
}

class GraphNodeType : GKGridGraphNode {
    var type = NodeType.EMPTY
    
    override func cost(to node: GKGraphNode) -> Float {
        let destinationNode = node as! GraphNodeType
        switch destinationNode.type {
        case NodeType.EMPTY:
            return 1.0
        case NodeType.NEXT_TO_WALL:
            return 20.0
        case NodeType.WALL:
            return 1000.0
        }
    }
}

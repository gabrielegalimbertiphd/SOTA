//
//  Model.swift
//  esameMOBIDEV
//
//  Created by Marco on 12/06/21.
//

import Foundation

typealias MatrixCoord = (row: Int, col: Int)

struct Coordinate {
    let lat : Double
    let lng : Double
    
    func distanceInMeters(to target: Coordinate) -> Double{
        let R = 6378.137
        let dLat = target.lat * .pi / 180 - lat * .pi / 180
        let dLon = target.lng * .pi / 180 - lng * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat * .pi / 180) * cos(target.lat * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let d = R * c
        return d * 1000
    }
}

struct MapTile{
    var type : NodeType = NodeType.EMPTY
}

struct Obstacle{
    let id : Int
    let floorId : Int
    let description : String
    let lat : Double
    let lng : Double
}

struct ObstacleOnMatrix{
    let id : Int
    let floorId : Int
    let description : String
    let row : Int
    let col : Int
}

struct InterestPoint{
    let id : Int
    let floorId : Int
    let type : String
    let lat : Double
    let lng : Double
}

struct InterestPointOnMatrix{
    let id : Int
    let floorId : Int
    let type : String
    let row : Int
    let col : Int
}

struct Connector {
    let id : Int
    let floorId : Int
    let type : String
    let lat : Double
    let lng : Double
    let connectedToID : Int
}

struct ConnectorOnMatrix {
    let id : Int
    let floorId : Int
    let type : String
    let row : Int
    let col : Int
    let connectedToID : Int
}

struct Wall {
    let type : String
    let coordinate : [Coordinate]
}

struct Path {
    let name : String
    let coordinate : [Coordinate]
}

struct PathOnMatrix {
    let name : String
    let coordinate : [MatrixCoord]
}

struct Work {
    let id : Int
    let floorId : Int
    let name : String
    var imagesrc : String
    let version: Int
    let lat: Double
    let lng: Double
    let width: Double
    let rotation: Int
}

struct WorkOnMatrix{
    let id : Int
    let floorId : Int
    let version: Int
    let title: String
    let row: Int
    let col: Int
    let rotation: Int
    let pathRow: Int
    let pathCol: Int
}

struct MapMatrix {
    let matrixSize = 1000
    var tiles = Array(repeating: Array(repeating: MapTile(), count: 1000), count: 1000)
    var cellInMeter : Double
    var wallsVertex = [[MatrixCoord]]()
    var works = [WorkOnMatrix]()
    var interests = [InterestPointOnMatrix]()
    var connectors = [ConnectorOnMatrix]()
    var obstacles = [ObstacleOnMatrix]()
    var paths = [PathOnMatrix]()
    
    private var minLat : Double
    private var minLng : Double
    private var maxLat : Double
    private var maxLng : Double
    
    init(walls: [Wall], works: [Work], connectors: [Connector], interests: [InterestPoint], obstacles: [Obstacle], paths: [Path]){
        minLat = walls[0].coordinate[0].lat
        minLng = walls[0].coordinate[0].lng
        maxLat = walls[0].coordinate[0].lat
        maxLng = walls[0].coordinate[0].lng
        
        ///Trova estremi di lat e lng
        for w in walls{
            for v in w.coordinate {
                if v.lat < minLat {minLat = v.lat}
                if v.lng < minLng {minLng = v.lng}
                if v.lat > maxLat {maxLat = v.lat}
                if v.lng > maxLng {maxLng = v.lng}
            }
        }
        
        ///Trova qual'è la distanza maggiore se quella degli estremi lat o lng per calcolare a quanti metri corrisponde una cella
        let maxLatDistance = Coordinate(lat: maxLat, lng: maxLng).distanceInMeters(to: Coordinate(lat: minLat, lng: maxLng))
        let maxLngDistance = Coordinate(lat: minLat, lng: maxLng).distanceInMeters(to: Coordinate(lat: minLat, lng: minLng))
        let maxDistance = max(maxLatDistance, maxLngDistance)
        self.cellInMeter = maxDistance/Double(matrixSize)
        
        ///Crea matrice di muri con coordinate sulla matrice
        for w in walls {
            var polyLine = [MatrixCoord]()
            for vertex in w.coordinate {
                polyLine.append(self.coordToGridIndex(vertex))
            }
            ///Se è perimetro deve tracciare anche la linea dall'ultimo vertice al primo per chiudere il poligono
            if w.type == "perimetro" {
                polyLine.append(self.coordToGridIndex(w.coordinate[0]))
            }
            self.wallsVertex.append(polyLine)
        }
        
        ///Crea muri nella matrice
        for polyLine in self.wallsVertex {
            for i in (0..<polyLine.count-1){
                let (row1, col1) = polyLine[i]
                let (row2, col2) = polyLine[i+1]
                let maxLinearDistance = max(abs(row1-row2), abs(col1-col2))+1
                for step in (0..<maxLinearDistance) {
                    let t = maxLinearDistance == 1 ? 0.0 : Double(step)/Double(maxLinearDistance)
                    let row = Int(Double(row1)+t*Double(row2-row1))
                    let col = Int(Double(col1)+t*Double(col2-col1))
                    tiles[row][col].type = NodeType.WALL
                    if row+1<matrixSize && tiles[row+1][col].type != .WALL{
                        tiles[row+1][col].type = .NEXT_TO_WALL
                    }
                    if col+1<matrixSize && tiles[row][col+1].type != .WALL{
                        tiles[row][col+1].type = .NEXT_TO_WALL
                    }
                    if row-1>=0 && tiles[row-1][col].type != .WALL{
                        tiles[row-1][col].type = .NEXT_TO_WALL
                    }
                    if col-1>=0 && tiles[row][col-1].type != .WALL{
                        tiles[row][col-1].type = .NEXT_TO_WALL
                    }
                }
            }
        }
        
        ///Inserisce opere
        for work in works {
            let (row, col) = self.coordToGridIndex(Coordinate(lat: work.lat, lng: work.lng))
            ///I campi pathRow e pathCol risolvono il problema del quadro se si trova dove c'è un muro e calcolano il percorso per un punto di fronte al quadro distante 30cm
            self.works.append(WorkOnMatrix(
                                id: work.id,
                                floorId: work.floorId,
                                version: work.version,
                                title: work.name,
                                row: row,
                                col: col,
                                rotation: work.rotation,
                                pathRow: row+Int(0.3/cellInMeter*cos(Double(work.rotation+90)*Double.pi/180)),
                                pathCol: col+Int(0.3/cellInMeter*sin(Double(work.rotation+90)*Double.pi/180))))
        }
        ///Per la prova
        self.works.append(WorkOnMatrix(
                            id: 0,
                            floorId: 107,
                            version: 1,
                            title: "Prova",
                            row: 500,
                            col: 500,
                            rotation: 0,
                            pathRow: 500,
                            pathCol: 500))
        
        ///Inserisce scale
        for c in connectors {
            let (row, col) = self.coordToGridIndex(Coordinate(lat: c.lat, lng: c.lng))
            self.connectors.append(ConnectorOnMatrix(id: c.id, floorId: c.floorId, type: c.type, row: row, col: col, connectedToID: c.connectedToID))
        }

        ///Inserisce punti di interesse
        for interest in interests {
            let (row, col) = self.coordToGridIndex(Coordinate(lat: interest.lat, lng: interest.lng))
            self.interests.append(InterestPointOnMatrix(id: interest.id, floorId: interest.floorId, type: interest.type, row: row, col: col))
        }
        
        ///Inserisce ostacoli
        for obstacle in obstacles {
            let (row, col) = self.coordToGridIndex(Coordinate(lat: obstacle.lat, lng: obstacle.lng))
            self.obstacles.append(ObstacleOnMatrix(id: obstacle.id, floorId: obstacle.floorId, description: obstacle.description, row: row, col: col))
        }
        
        ///Inserisce percorsi predefiniti
        for p in paths {
            var polyLine = [MatrixCoord]()
            for vertex in p.coordinate {
                polyLine.append(self.coordToGridIndex(vertex))
            }
            self.paths.append(PathOnMatrix(name: p.name, coordinate: polyLine))
        }
    }
    
//    private func printa(){
//        print(self.paths)
//        for path in self.paths {
//            print("[")
//            for c in path.coordinate{
//                print("{\n\"x\":\(Double(c.row)*self.cellInMeter),\n\"y\":\(Double(c.col)*self.cellInMeter)\n},")
//            }
//            print("]\n\n")
//        }
//        for work in self.works {
//            let coordinateAR = "{\n\"x\":\(Double(work.row)*self.cellInMeter),\n\"y\":\(Double(work.col)*self.cellInMeter)\n}"
//            let coordinateGriglia = "{\n\"x\":\(work.row),\n\"y\":\(work.col)\n}"
//            print("{\n\"id\":\"\(work.id)v\(work.version)\",\n\"title\":\"\(work.title)\",\n\"coordinateAR\":\(coordinateAR),\n\"coordinateAR\":\(coordinateGriglia)\n},")
//        }
//    }
    
    private func coordToGridIndex(_ v: Coordinate) -> MatrixCoord{
        var latIndex = Int(v.distanceInMeters(to: Coordinate(lat: minLat, lng: v.lng))/cellInMeter)
        var lngIndex = Int(v.distanceInMeters(to: Coordinate(lat: v.lat, lng: minLng))/cellInMeter)
        if latIndex >= self.matrixSize { latIndex = self.matrixSize-1}
        if lngIndex >= self.matrixSize { lngIndex = self.matrixSize-1}
        latIndex = self.matrixSize-1-latIndex
        return (lngIndex, latIndex)
    }
    
    func isVisible(user_x: Int, user_y: Int, point_x: Int, point_y: Int) -> Bool{
        ///Trova la distanza massima se è sulle x o sulle y
        let maxLinearDistance = max(abs(user_x-point_x), abs(user_y-point_y))+1
        for step in (0..<maxLinearDistance) {
            ///Percentuale di avanzamento ovvero lo step a cui si trova diviso gli step totali
            let t = maxLinearDistance == 1 ? 0.0 : Double(step)/Double(maxLinearDistance)
            let row = Int(Double(user_x)+t*Double(point_x-user_x))
            let col = Int(Double(user_y)+t*Double(point_y-user_y))
//            temp.append((row, col))
            if tiles[row][col].type == .WALL || tiles[row][col].type == .NEXT_TO_WALL {
                return false
            }
        }
        return true
    }
}

//var temp : [MatrixCoord] = []

struct HardcodedMap{
    var wall = [Wall]()
    var work = [Work]()
    var connector = [Connector]()
    var interest = [InterestPoint]()
    var obstacles = [Obstacle]()
    var paths = [Path]()
    
    init(){
        if let path = Bundle.main.path(forResource: "UNImapCortile7", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let json = jsonResult as? Dictionary<String, Any>,
                   let walls = json["walls"] as? [Dictionary<String, Any>],
                   let works = json["works"] as? [Dictionary<String, Any>],
                   let connectors = json["connectors"] as? [Dictionary<String, Any>],
                   let interests = json["interests"] as? [Dictionary<String, Any>],
                   let obstacles = json["obstacles"] as? [Dictionary<String, Any>],
                   let paths = json["paths"] as? [Dictionary<String, Any>] {
                    
                    for w in walls {
                        let type : String = w["type"] as! String
                        var coordinate : [Coordinate] = []
                        for c in w["coordinate"] as! [Dictionary<String, Double>]{ //TODO: In caso sia perimetro il tipo è [[Dictionary<String, Double]]
                            coordinate.append(Coordinate(lat: c["lat"]!, lng: c["lng"]!))
                        }
                        self.wall.append(Wall(type: type, coordinate: coordinate))
                    }
                    
                    for w in works {
                        let id = w["id"] as! Int
                        let floorId = w["floorid"] as! Int
                        let name = w["title"] as! String
                        let version = w["imageversion"] as! Int
                        let lat = w["lat"] as! Double
                        let lng = w["lng"] as! Double
                        let width = w["width"] as! Double
                        let rotation = w["rotation"] as! Int
                        let imagesrc : String = "DEFAULT"
                        self.work.append(Work(id: id, floorId: floorId, name: name, imagesrc: imagesrc, version: version, lat: lat, lng: lng, width: width, rotation: rotation))
                    }
                    
                    for c in connectors {
                        let id = c["id"] as! Int
                        let floorId = c["floorid"] as! Int
                        let type = c["type"] as! String
                        let lat = c["lat"] as! Double
                        let lng = c["lng"] as! Double
                        let connectedTo = c["connectedfloor"] as! Int
                        self.connector.append(Connector(id: id, floorId: floorId, type: type, lat: lat, lng: lng, connectedToID: connectedTo))
                    }
                    
                    for i in interests {
                        let id = i["id"] as! Int
                        let floorId = i["floorid"] as! Int
                        let type = i["type"] as! String
                        let lat = i["lat"] as! Double
                        let lng = i["lng"] as! Double
                        self.interest.append(InterestPoint(id: id, floorId: floorId, type: type, lat: lat, lng: lng))
                    }
                    
                    for o in obstacles {
                        let id = o["id"] as! Int
                        let floorId = o["floorid"] as! Int
                        let description = o["description"] as! String
                        let lat = o["lat"] as! Double
                        let lng = o["lng"] as! Double
                        self.obstacles.append(Obstacle(id: id, floorId: floorId, description: description, lat: lat, lng: lng))
                    }
                    
                    for p in paths {
                        let name : String = p["name"] as! String
                        var coordinate : [Coordinate] = []
                        for c in p["coordinate"] as! [Dictionary<String, Double>]{ //TODO: In caso sia perimetro il tipo è [[Dictionary<String, Double]]
                            coordinate.append(Coordinate(lat: c["lat"]!, lng: c["lng"]!))
                        }
                        self.paths.append(Path(name: name, coordinate: coordinate))
                    }
                }
            } catch {
                print("ERRORE NEL JSON")
            }
        }
    }
}

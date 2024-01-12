//
//  ARViewController.swift
//  esameMOBIDEV
//
//  Created by Marco on 11/06/21.
//

import UIKit
import RealityKit
import ARKit

struct Link : Equatable {
    var node_u : String
    var node_v : String
    var radiusOfNavigationArea : Float
    
    mutating func changeRadius(_ new_radius: Float){
        radiusOfNavigationArea = new_radius
    }
}

class ARViewController: UIViewController, ARSessionDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var arView : ARView!
    @IBOutlet weak var mapImage : UIImageView!
    @IBOutlet weak var navArrowImage: UIImageView!
    @IBAction func swipeDownGesture(_ sender: UISwipeGestureRecognizer) {hideMap()}
    @IBAction func swipeUpGesture(_ sender: UISwipeGestureRecognizer) {showMap()}
    
    @IBOutlet weak var debugText: UILabel!
    @IBOutlet weak var textInput: UITextField!
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.logger.userName = textField.text!
        self.showMap()
        return true
    }
    
    private var log : Log = Log()
    
    private var mapDrawer : MapDrawer!
    private var map : MapMatrix?
    private var count = 0
    private var anchorTracked = true
    private var pathFinder : PathFinder!
    private let audioController = AudioController()
    private let navigator = Navigator()
    private var logger : Logger!
    private var canFixHappen : Bool = true
    
    
    public var lastMarkerSeen : String = ""
    public var angle_fix : Float = 0.0
    public var x_fixing_gap_map : Float = 0.0
    public var y_fixing_gap_map : Float = 0.0
    public var rototraslFix : simd_float4x4 = matrix_identity_float4x4
    public var dxPath : Float = 0.0
    public var dyPath : Float = 0.0
    public var anglePath : Float = 0.0
    public var angle : Float = 0.0
    public var range : Int = 30
    public var angularDifference : Float = 0.0
    public var direction : String = ""
    public var radiusOfNavigationArea : Float = 1.0
    public var distanceFromNextPoint : Float = 0.0
    public var lateralDistance : Float = 0.0
    public var dxFromCurrentEdge : Float = 0.0
    public var dyFromCurrentEdge : Float = 0.0
    
    public var startLog : Bool = false
    public var state : String = ""
    public var message : String = ""
    
    public var version_setup : String = "basic"
    
    var links: [Link] = [
        Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1.5),
        Link( node_u :"1", node_v :"2", radiusOfNavigationArea :2),
        Link( node_u :"2", node_v :"3", radiusOfNavigationArea :1),
        Link( node_u :"3", node_v :"4", radiusOfNavigationArea :2),
        Link( node_u :"4", node_v :"5", radiusOfNavigationArea :1.5),
        Link( node_u :"5", node_v :"6", radiusOfNavigationArea :1),
        Link( node_u :"6", node_v :"7", radiusOfNavigationArea :1)
    ]
    
    var linksOfPaths:[String:[Link]] = [
        "Percorso1":[
            Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1.5),
            Link( node_u :"1", node_v :"2", radiusOfNavigationArea :2),
            Link( node_u :"2", node_v :"3", radiusOfNavigationArea :1),
            Link( node_u :"3", node_v :"4", radiusOfNavigationArea :2),
            Link( node_u :"4", node_v :"5", radiusOfNavigationArea :1.5),
            Link( node_u :"5", node_v :"6", radiusOfNavigationArea :1),
            Link( node_u :"6", node_v :"7", radiusOfNavigationArea :1)
        ],
        "Percorso2":[
            Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1),
            Link( node_u :"1", node_v :"2", radiusOfNavigationArea :1.5),
            Link( node_u :"2", node_v :"3", radiusOfNavigationArea :2),
            Link( node_u :"3", node_v :"4", radiusOfNavigationArea :2),
            Link( node_u :"4", node_v :"5", radiusOfNavigationArea :1),
            Link( node_u :"5", node_v :"6", radiusOfNavigationArea :1.5),
            Link( node_u :"6", node_v :"7", radiusOfNavigationArea :1)
        ],
        "Percorso3":[
            Link( node_u :"0", node_v :"1", radiusOfNavigationArea :2),
            Link( node_u :"1", node_v :"2", radiusOfNavigationArea :1.5),
            Link( node_u :"2", node_v :"3", radiusOfNavigationArea :1),
            Link( node_u :"3", node_v :"4", radiusOfNavigationArea :1.5),
            Link( node_u :"4", node_v :"5", radiusOfNavigationArea :2),
            Link( node_u :"5", node_v :"6", radiusOfNavigationArea :1),
            Link( node_u :"6", node_v :"7", radiusOfNavigationArea :1)
        ],
        "Percorso4":[
            Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1),
            Link( node_u :"1", node_v :"2", radiusOfNavigationArea :2),
            Link( node_u :"2", node_v :"3", radiusOfNavigationArea :2),
            Link( node_u :"3", node_v :"4", radiusOfNavigationArea :1.5),
            Link( node_u :"4", node_v :"5", radiusOfNavigationArea :1.5),
            Link( node_u :"5", node_v :"6", radiusOfNavigationArea :1),
            Link( node_u :"6", node_v :"7", radiusOfNavigationArea :1)
        ]
    ]
    
    lazy var x_user = UILabel()
    lazy var y_user = UILabel()
    lazy var yaw_user = UILabel()
    lazy var angular_error_label = UILabel()
    lazy var distance_from_next_target_label = UILabel()
    lazy var message_label = UILabel()
    lazy var directionLabel = UILabel()
    lazy var lateralDistanceLabel = UILabel()
    lazy var targetNodeLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        debugText.text = ""
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = ARReferenceImage.referenceImages(inGroupNamed: "Default", bundle: nil)!
        configuration.maximumNumberOfTrackedImages = 1
        
        let semantics : ARConfiguration.FrameSemantics = .smoothedSceneDepth
        if type(of: configuration).supportsFrameSemantics(semantics){
            configuration.frameSemantics = semantics
        }
        
        self.textInput.delegate = self
        
//        configuration.worldAlignment = .camera
        
        self.arView.session.run(configuration)
        self.arView.session.delegate = self
//        self.arView.debugOptions = [.showWorldOrigin, .showAnchorOrigins]
        
        let myMap = HardcodedMap()
        self.map = MapMatrix(walls: myMap.wall, works: myMap.work, connectors: myMap.connector, interests: myMap.interest, obstacles: myMap.obstacles, paths: myMap.paths)
        self.pathFinder = PathFinder(mapGrid: self.map!.tiles, paths: self.map!.paths)
        self.mapDrawer = MapDrawer(map: self.map!, imageView: self.mapImage)
        self.mapDrawer.drawMap(self.map!)
        self.logger = Logger(navigator: self.navigator, audioController: self.audioController)
        Synth.shared.setWaveformTo(Oscillator.square)
        
        self.audioController.changeSonification("Son1Tick")
        
        x_user.frame = CGRect(x: 240, y: 0, width: 300, height: 400)
        x_user.text = "X: 0"
        x_user.textColor = UIColor.black
        view.addSubview(x_user)
        
        y_user.frame = CGRect(x: 240, y: 0, width: 300, height: 450)
        y_user.text = "Y: 0"
        y_user.textColor = UIColor.black
        view.addSubview(y_user)
        
        yaw_user.frame = CGRect(x: 240, y: 0, width: 300, height: 500)
        yaw_user.text = "Yaw: 0"
        yaw_user.textColor = UIColor.black
        view.addSubview(yaw_user)
        
        targetNodeLabel.frame = CGRect(x: 240, y: 0, width: 300, height: 550)
        targetNodeLabel.text = "T: "
        targetNodeLabel.textColor = UIColor.black
        view.addSubview(targetNodeLabel)
        
        angular_error_label.frame = CGRect(x: 10, y: 0, width: 300, height: 400)
        angular_error_label.text = "Ang Err: 0"
        angular_error_label.textColor = UIColor.black
        view.addSubview(angular_error_label)
        
        distance_from_next_target_label.frame = CGRect(x: 10, y: 0, width: 300, height: 450)
        distance_from_next_target_label.text = "dist T: 0"
        distance_from_next_target_label.textColor = UIColor.black
        view.addSubview(distance_from_next_target_label)
        
        directionLabel.frame = CGRect(x: 10, y: 0, width: 300, height: 500)
        directionLabel.text = "direction: "
        directionLabel.textColor = UIColor.black
        view.addSubview(directionLabel)
        
        lateralDistanceLabel.frame = CGRect(x: 10, y: 0, width: 300, height: 550)
        lateralDistanceLabel.text = "lat dist: 0"
        lateralDistanceLabel.textColor = UIColor.black
        view.addSubview(lateralDistanceLabel)

    }
    
    func reduceResolution(value: Float , _ resolution: Float) -> Float {
        return round(resolution * value)/resolution
    }
    
    //MARK: - AR SESSION CALLBACKS
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let imgAnchor = anchors.first as? ARImageAnchor else {return}
        print("imgAnchor",imgAnchor)
        //guard !self.audioController.changeSonification(imgAnchor.name!) else {return}
        guard imgAnchor.name! != "Stop" else {destinationReached(); return}
        guard let work = getWork(name: imgAnchor.name!) else {return}
        self.logger.anchoredImage = imgAnchor.name!
        
        print("canFixHappen", self.canFixHappen)
        
        if imgAnchor.name! != "0v1"{
            self.changeWorldOrigin(work: work, anchor: imgAnchor)
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in
                self.canFixHappen = true
            }
            lastMarkerSeen = imgAnchor.name!
            startLog=true
        }else{
            self.canFixHappen = false
            lastMarkerSeen = ""
        }
        
        self.anchorTracked = true
        self.navigationController(path: pathFinder.getPath(markerName: imgAnchor.name!))
        links = linksOfPaths[self.pathFinder.currentPath ?? "Percorso1"] ?? links
        self.mapDrawer.drawWorkOnMap(row: work.row, col: work.col)
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let imgAnchor = anchors.first as? ARImageAnchor else {return}
        guard imgAnchor.isTracked else {session.remove(anchor: imgAnchor); return}
        guard count == 4 else { count = (count+1)%5; return}
        guard let work = getWork(name: imgAnchor.name!) else {return}
        
        if canFixHappen {self.changeWorldOrigin(work: work, anchor: imgAnchor)}

        let cameraTrans = session.currentFrame!.camera.transform
        let anchorTrans = imgAnchor.transform
        let cameraPos = SCNVector3Make(cameraTrans.columns.3.x, cameraTrans.columns.3.y, cameraTrans.columns.3.z)
        
        let anchorPos = SCNVector3Make(anchorTrans.columns.3.x, anchorTrans.columns.3.y, anchorTrans.columns.3.z)
        let row = work.row + Int(Double(cameraPos.x-anchorPos.x)/self.map!.cellInMeter)
        let col = work.col + Int(Double(cameraPos.z-anchorPos.z)/self.map!.cellInMeter)
        self.mapDrawer.drawUserOnMap(row: row, col: col)
        self.navigator.position = (row, col)
        
        self.drawOrientationArrow(camera: session.currentFrame!.camera.eulerAngles)
        self.logger.orientation = (session.currentFrame!.camera.eulerAngles.x, session.currentFrame!.camera.eulerAngles.y, session.currentFrame!.camera.eulerAngles.z)
        self.logger.position = (cameraTrans.columns.3.x, cameraTrans.columns.3.y, cameraTrans.columns.3.z)
        self.count = 0
    }
    
    
    private func changeWorldOrigin(work: WorkOnMatrix, anchor: ARAnchor){
        ///Ogni volta che vede un'ancora crea punto di origine nella cella della griglia [0,0] (in alto a sinistra) ruotato in modo tale che le x e le z corrispondano direttamente alle x e y della griglia. In altre parole è come se il mio punto di origine nella griglia sia sempre in alto a sinistra e ogni immagine che inquadro mi fixi solo la posizione nella sessione AR

        ///Matrice per ruotare la matrice dell'ancora in modo tale che le x e le z corrispondano direttamente alle x e y della griglia
        angle_fix = -Float(work.rotation) * Float.pi / 180.0
        let rotationZMatrix = simd_float4x4([cos(angle_fix),sin(angle_fix),0,0],
                                            [-sin(angle_fix),cos(angle_fix),0,0],
                                            [0,0,1,0],
                                            [0,0,0,1])
        var finalTransform = simd_mul(anchor.transform, rotationZMatrix)
        ///Matrice per spostare la matrice dell'ancora in modo tale che sia sempre nella cella [0,0] della griglia
        let x = -Float(Double(work.row)*self.map!.cellInMeter)
        let y = -Float(Double(work.col)*self.map!.cellInMeter)
        let positionMatrix = simd_float4x4([1,0,0,0],
                                           [0,1,0,0],
                                           [0,0,1,0],
                                           [x,y,0,1])
        finalTransform = simd_mul(finalTransform, positionMatrix)
        x_fixing_gap_map = x
        y_fixing_gap_map = y
        ///Matrice per ruotare la matrice dell'ancora di 90° in modo tale che abbia y verso l'alto, x verso destra e z verso l'utente
        let rotationXMatrix = simd_float4x4([1,0,0,0],
                                            [0,cos(Float.pi/2),-sin(Float.pi/2),0],
                                            [0,sin(Float.pi/2),cos(Float.pi/2),0],
                                            [0,0,0,1])
        ///N.B. Si suppone che il quadro sia perpendicolare al terreno. TODO: Bisognerebbe controllare che la matrice risultante sia con le x e z parallele al suolo. Questo potrebbe accadere in caso un quadro sia esposto leggermente inclinato o se la sessione AR non riconsca correttamente la rotazione di un quadro (ancora inclinata erroneamente).
        finalTransform = simd_mul(finalTransform, rotationXMatrix)

        self.arView.session.setWorldOrigin(relativeTransform: finalTransform)
        rototraslFix = finalTransform
        self.canFixHappen = false
        self.logger.logAsync(logDescription: "2")
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let _ = anchors.first as? ARImageAnchor else { return }
        
        self.logger.anchoredImage = nil
        self.anchorTracked = false
        self.canFixHappen = true
        self.count = 3
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard !anchorTracked else { return }
        guard count == 4 else { count = (count+1)%5; return }
        
        let row = Int(Double(frame.camera.transform.columns.3.x)/self.map!.cellInMeter)
        let col = Int(Double(frame.camera.transform.columns.3.z)/self.map!.cellInMeter)
        self.mapDrawer.drawUserOnMap(row: row, col: col)
        self.navigator.position = (row, col)
        
        self.drawOrientationArrow(camera: frame.camera.eulerAngles)
        self.logger.orientation = (frame.camera.eulerAngles.x, frame.camera.eulerAngles.y, frame.camera.eulerAngles.z)
        self.logger.position = (frame.camera.transform.columns.3.x, frame.camera.transform.columns.3.y, frame.camera.transform.columns.3.z)
        self.count = 0
        
        if startLog {
                    
            var timestamp = NSDate().timeIntervalSince1970
            var currentX_map=frame.camera.transform.columns.3.x
            var currentY_map=frame.camera.transform.columns.3.z
            var currentZ_map=frame.camera.transform.columns.3.y
            var currentROLL=frame.camera.eulerAngles.x
            var currentPITCH=frame.camera.eulerAngles.z
            var currentYAW=frame.camera.eulerAngles.y
            //lastMarkerSeen = self.lastMarkerSeen
            //locationProvider.fixPosition = canFixHappen
            //x_fixing_gap_map=
            //y_fixing_gap_map=
            //var yaw_fixing_gap_map=angle_fix
            if canFixHappen {
                rototraslFix=matrix_identity_float4x4
            }
                    
            
            //var angleTarget = goalAngle
            // (rad2degree(currentY_map)); = angle
            //var angular_difference = difference
            // direction=
                    
            var nextNode = self.currentPoint
            
            var target_x_map = self.navigator.path![currentPoint].row
            var target_y_map = self.navigator.path![currentPoint].col
            //var distance = distanceFromNextPoint
            var node_v = self.currentPoint
            var node_u = self.currentPoint+1
            var length_closest_edge = distanceInMeters(row1: self.navigator.path![currentPoint].row, row2: self.navigator.path![currentPoint-1].row, col1: self.navigator.path![currentPoint].col, col2: self.navigator.path![currentPoint-1].col)
            var distanceFromCurrentEdge = lateralDistance
            // var dxFromCurrentEdge =
            // var dyFromCurrentEdge =
            // state=
            // message=audioController.lastText
            // previous_message_label.text= audioController.previousThingSaid
            // startLog=
            // level4.startSonification=audioController.startSonification
            // level4.readInstruction=audioController.readInstruction
            // version_setup=
            //var percorso=self.pathFinder.currentPath
            
            var num_turn=audioController.num_turn
            var num_walk=audioController.num_walk
            var num_lateral=audioController.num_lateral
                    
            let text="\(timestamp);\(currentX_map);\(currentY_map);\(currentZ_map);\(currentROLL);\(currentPITCH);\(currentYAW);\(lastMarkerSeen);\(canFixHappen);\(x_fixing_gap_map);\(y_fixing_gap_map);\(angle_fix);\(rototraslFix);\(anglePath);\(angle);\(angularDifference);\(direction);\(range);\(nextNode);\(target_x_map);\(target_y_map);\(distanceFromNextPoint);\(node_v);\(node_u);\(radiusOfNavigationArea);\(length_closest_edge);\(distanceFromCurrentEdge);\(dxFromCurrentEdge);\(dyFromCurrentEdge);\(state);\(audioController.lastText);\(audioController.previousThingSaid);\(startLog);\(audioController.startSonification);\(audioController.readInstruction);\(version_setup);\(self.pathFinder.currentPath);\(num_turn);\(num_walk);\(num_lateral)"
            
            log.logAsync(logDescription: text)
            
            x_user.text="X: \(reduceResolution(value: currentX_map, 100))"
            y_user.text="Y: \(reduceResolution(value: currentY_map, 100))"
            yaw_user.text="Yaw: \(reduceResolution(value: currentYAW*180/Float.pi, 100))"
            targetNodeLabel.text="T: \(currentPoint)"
            angular_error_label.text="Ang Err: \(reduceResolution(value: angularDifference, 100))"
            distance_from_next_target_label.text="Dist: \(reduceResolution(value: distanceFromNextPoint, 100))"
            directionLabel.text="Dir: \(direction)"
            lateralDistanceLabel.text="lat dist: \(reduceResolution(value: distanceFromCurrentEdge, 100))"
            
        }
        
    }
    
    //MARK: - UTILS
    
    private func getWork(name: String) -> WorkOnMatrix?{
        if name.count > 2 && name.prefix(upTo: name.index(name.startIndex, offsetBy: 3)) == "Fix" && self.pathFinder.currentPath != nil {
            let workName : String = name.prefix(upTo: name.index(name.startIndex, offsetBy: 4)) + self.pathFinder.currentPath!
            for work in self.map!.works {
                if work.title == workName {
                    return work
                }
            }
        }else if let id = Int(name.split(separator: "v")[0]){
            let version = Int(name.split(separator: "v")[1])!
            for work in self.map!.works {
                if work.id == id && work.version == version{
                    return work
                }
            }
        }
        return nil
    }
    
    private func destinationReached(){
        self.mapDrawer.destinationReached()
        self.navigator.destinationReached()
        self.arView.scene.anchors.removeAll()
        self.navArrowImage.image = nil
        state="arrived"
        self.currentPoint=1
        self.logger.destinationReached()
        self.pathFinder.currentPath = nil
        self.audioController.lastText = "Destinazione raggiunta"
        self.audioController.say("Destinazione raggiunta", important: true)
        Synth.shared.volume = 0
        startLog=false
    }
    
    private func distanceInMeters(row1: Int, row2: Int, col1: Int, col2: Int) -> Float {
        let dx = Float(row1-row2)
        let dy = Float(col1-col2)
        return sqrt(pow(dx, 2)+pow(dy, 2))*Float(self.map!.cellInMeter)
    }
    
    func showMap(){
        UIView.animate(withDuration: 0.3) {
            if self.textInput.center == CGPoint(x: self.view.center.x, y: self.view.center.y) {
                self.textInput.center = CGPoint(x: self.view.center.x, y: self.view.center.y-1000)
            }else{
                self.mapImage.center = CGPoint(x: self.view.bounds.width/2, y: self.view.bounds.height/2)
            }
        }
    }
    
    func hideMap(){
        UIView.animate(withDuration: 0.3) {
            if self.mapImage.center == CGPoint(x: self.view.bounds.width/2, y: self.view.bounds.height/2) {
                self.mapImage.center = CGPoint(x: self.view.center.x, y: self.view.center.y+1000)
            }else{
                self.textInput.center = CGPoint(x: self.view.center.x, y: self.view.center.y)
            }
        }
    }
    
    
    private func drawPathAR(path: [MatrixCoord]){
        let meshSphere = MeshResource.generateSphere(radius: 0.08)
        let material = UnlitMaterial(color: .blue)
        self.arView.scene.anchors.removeAll()
        for point in path {
            let pathSphere = point
            let x = Float(Double(pathSphere.row)*self.map!.cellInMeter)
            let z = Float(Double(pathSphere.col)*self.map!.cellInMeter)
            let position = simd_float4x4([1,0,0,0],
                                         [0,1,0,0],
                                         [0,0,1,0],
                                         [x,-0.8,z,1]) ///TODO: Mettere le y rispetto all'altezza del telefono
            let entitySphere = ModelEntity(mesh: meshSphere, materials: [material])
            let anchor = AnchorEntity(world: position)
            anchor.addChild(entitySphere)
            self.arView.scene.anchors.append(anchor)
        }
    }
    
    //MARK: - AUDIO FUNCTIONS
    private var currentPoint = 1 // TODO: CHECK 0 or 1.
    
    private func drawOrientationArrow(camera: simd_float3){
        guard self.navigator.path != nil else {return}
        let path = self.navigator.path!
        let distanceNextTurn = distanceInMeters(row1: path[currentPoint].row, row2: navigator.position!.row, col1: path[currentPoint].col, col2: navigator.position!.col)
        if distanceNextTurn < radiusOfNavigationArea {
            if self.audioController.lastText != "Prosegui dritto" || distanceNextTurn < radiusOfNavigationArea {
                print("current point", self.currentPoint, "radiusOfNavigationArea",radiusOfNavigationArea,"before")
                radiusOfNavigationArea = links[self.currentPoint].radiusOfNavigationArea ?? 1.0
                currentPoint = currentPoint+1
                
                print("current point", self.currentPoint, "radiusOfNavigationArea",radiusOfNavigationArea,"after")
                
                
                self.audioController.lastText = ""
                if currentPoint == path.count {
                    state="arrived"
                    self.destinationReached()
                    saveData()
                    return
                }
                self.audioController.playGoalReachedSound()
                self.navigator.actualTurn = currentPoint
                self.logger.stretchLength = distanceInMeters(row1: path[currentPoint].row, row2: path[currentPoint-1].row, col1: path[currentPoint].col, col2: path[currentPoint-1].col)
                for i in (0..<path.count){
                    self.arView.scene.anchors[i].isEnabled = i == currentPoint ? true:false
                }
            }
        } // per percorsi rettilinei
        let dx = Double(path[currentPoint].row-self.navigator.position!.row)
        let dy = -Double(path[currentPoint].col-self.navigator.position!.col) ///Cambio segno perchè le y aumentano dall'alto verso il basso, cambiando segno lo riporto in un sistema di assi cartesiano normale come se fossi nel quarto quadrante
        let goalAngle = atan2(dy, dx)-Double.pi/2 ///Meno 90° per essere uniforme al sistema di assi della sessione AR
        let rotationAngle = CGFloat(camera.y-Float(goalAngle))
        self.navArrowImage.transform = CGAffineTransform(rotationAngle: rotationAngle)
        
        let rotation = (Float(rotationAngle)*180/Float.pi)
        let distance = self.distanceInMeters(row1: path[currentPoint].row, row2: navigator.position!.row, col1: path[currentPoint].col, col2: navigator.position!.col)
        self.navigator.orientationAngle = rotation
        self.logger.actualIndicationSonified = self.audioController.getDirection(rotation: (rotation+360).truncatingRemainder(dividingBy: 360), distanceFromTurn: distance)
        self.logger.distanceFromNextPoint = distance
        distanceFromNextPoint = distance
        let userPathDistanceInfo = self.distanceFromPathInMeters()
        if !self.isUserInPath(distance: userPathDistanceInfo.distance) && self.audioController.lastText == "Prosegui dritto" {
            //self.audioController.say("Spostati leggermente a \(userPathDistanceInfo.direction)")
            self.audioController.say("Spostati a \(userPathDistanceInfo.direction)")
        }
    }
    
    private func distanceFromPathInMeters() -> (distance: Float, direction: String) {
        guard currentPoint > 0 && self.navigator.path != nil else {return (0, "")}
        let previousPoint = self.navigator.path![currentPoint-1]
        let nextPoint = self.navigator.path![currentPoint]
        
        let dx = Float(nextPoint.row-self.navigator.position!.row)
        let dy = -Float(nextPoint.col-self.navigator.position!.col)
        angle = (atan2(dy, dx)+(Float.pi*2)).truncatingRemainder(dividingBy: Float.pi*2)
        
        dxPath = Float(nextPoint.row-previousPoint.row)
        dyPath = -Float(nextPoint.col-previousPoint.col)
        anglePath = (atan2(dyPath, dxPath)+(Float.pi*2)).truncatingRemainder(dividingBy: Float.pi*2)
        
        lateralDistance = distanceInMeters(row1: nextPoint.row, row2: navigator.position!.row, col1: nextPoint.col, col2: navigator.position!.col)*sin(angle-anglePath)
        // ADDED
        //var data = getClosestPointOnEdge(position: (px:navigator.position!.row,py:navigator.position!.col), p1X: self.navigator.path![currentPoint-1].row, p1Y: self.navigator.path![currentPoint-1].col, p2X: self.navigator.path![currentPoint-1].row, p2Y: self.navigator.path![currentPoint].col) // (d, x_point, y_point , dx, dy, _)
        var data = getClosestPointOnEdge(position: (px:Float(navigator.position!.row),py:Float(navigator.position!.col)), p1X: Float(self.navigator.path![currentPoint-1].row), p1Y: Float(self.navigator.path![currentPoint-1].col), p2X: Float(self.navigator.path![currentPoint-1].row), p2Y: Float(self.navigator.path![currentPoint].col)) // (d, x_point, y_point , dx, dy, _)
        
        dxFromCurrentEdge=data!.dx ?? 0.0
        dyFromCurrentEdge=data!.dy ?? 0.0
        //------------
        angularDifference = angle-anglePath
        direction = angularDifference>0 && angularDifference < Float.pi ? "Sinistra":"Destra" ///Indica direzione in cui far spostare l'utente (e.g. se utente è a destra del percorso allora direction = "Sinistra")
        self.navigator.distanceFromPath = direction == "Sinistra" ? lateralDistance:-lateralDistance
        self.navigator.distanceFromPath = lateralDistance
        return (lateralDistance, direction)
    }
    
    // QUESTO DEFINISCE LA NAVIGATION AREA
    private func isUserInPath(distance: Float) -> Bool{
        guard abs(distance) > radiusOfNavigationArea/2 else {
            state = "inside"
            return true
        }
        let userDistance = distanceInMeters(row1: self.navigator.path![currentPoint].row, row2: navigator.position!.row, col1: self.navigator.path![currentPoint].col, col2: navigator.position!.col)
        // lateral distance
        let distanceProjection = sqrt(pow(userDistance, 2)-pow(distance, 2))
        let stretchLength = distanceInMeters(row1: self.navigator.path![currentPoint].row, row2: self.navigator.path![currentPoint-1].row, col1: self.navigator.path![currentPoint].col, col2: self.navigator.path![currentPoint-1].col)
        var userInPath = abs(distance) < radiusOfNavigationArea //1 + (0.5*min(distanceProjection/stretchLength, 1))
        state = userInPath ? "inside" : "outside"
        return userInPath
    }       
    
    //MARK: - NAVIGATION
    
    private func navigationController(path: ([MatrixCoord]?, String)){
        guard var p = path.0 else {return}
        guard path.1 != "Stop" else {destinationReached(); return}
        
        switch path.1 {
        case "Prova":
            //self.navigator.position = (500,500)
            getTestPosition(camera: self.arView.session.currentFrame!.camera.transform)
            p = getTestPath(camera: self.arView.session.currentFrame!.camera.eulerAngles)
            //self.audioController.lastText = "Prosegui dritto"
            //self.audioController.say("Prosegui dritto per 2 metri")
        default:
            break
        }
        
        // Synth.shared.volume = 0.8 // TODO: COMMENTATO... PENSO SIA QUESTO CHE CAUSA PROBLEMI A LIVELLO SONORO. DOPO LA PROVA INFATTI IL SYNTH PERSISTE...
        
        self.navArrowImage.image = UIImage(named: "nav_arrow")
        self.navigator.path = p
        self.mapDrawer.drawNewPath(path: p)
        self.mapDrawer.drawPathOnMap(path: p)
        self.drawPathAR(path: p)
        self.logger.startedNavigation(pathName: path.1, sonification: 1) //self.audioController.selectedSonification)
        self.logger.stretchLength = distanceInMeters(row1: p[0].row, row2: p[1].row, col1: p[0].col, col2: p[1].col)
    }
    
    private func getTestPath(camera: simd_float3) -> [MatrixCoord]{
        var path = [MatrixCoord]()
        path.append(self.navigator.position!)
        let straightDistance = 4.0
        let dx = straightDistance*sin(Double(camera.y))
        let dy = straightDistance*cos(Double(camera.y))
        let firstRow = self.navigator.position!.row-Int(dx/self.map!.cellInMeter)
        let firstCol = self.navigator.position!.col-Int(dy/self.map!.cellInMeter)
        path.append((firstRow, firstCol))
        let dx2 = straightDistance*sin(Double(camera.y) + (90 * .pi/180))
        let dy2 = straightDistance*cos(Double(camera.y) + (90 * .pi/180))
        let secondRow = firstRow-Int(dx2/self.map!.cellInMeter)
        let secondCol = firstCol-Int(dy2/self.map!.cellInMeter)
        path.append((secondRow, secondCol))
        return path
    }
    
    private func getTestPosition(camera: simd_float4x4) {
        let offset = 500*Float(self.map!.cellInMeter)
        let origin = simd_float4x4([1,0,0,0],
                                   [0,1,0,0],
                                   [0,0,1,0],
                                   [camera.columns.3.x-offset,0,camera.columns.3.z-offset,1])
        
        self.arView.session.setWorldOrigin(relativeTransform: origin)
        self.navigator.position = (500,500)
    }
    
    func getClosestPointOnEdge(position: (px:Float,py:Float), p1X: Float, p1Y: Float, p2X: Float, p2Y: Float) -> (distance: Float, x_point: Float, y_point: Float, dx: Float, dy: Float, t: Float)? {
        
        let p_uX:Float=position.px
        let p_uY:Float=position.py
        
        /*let vertex_u = position_vertexes["\(edge.u)"]!
        let vertex_v = position_vertexes["\(edge.v)"]!
        let p1X:Float = vertex_u["x"] ?? 0
        let p1Y:Float = vertex_u["y"] ?? 0
        let p2X:Float = vertex_v["x"] ?? 0
        let p2Y:Float = vertex_v["y"] ?? 0*/
        
        var dx : Float = p2X - p1X
        var dy : Float = p2Y - p1Y
        
        let t : Float = ((p_uX - p1X) * dx + (p_uY - p1Y) * dy)/(dx * dx + dy * dy)
        var closestX : Float = 0.0
        var closestY : Float = 0.0
        
        if (t < 0) { // See if this represents one of the segment's end points or a point in the middle. // DIVIDERE IN getClosestPoint e getClosestPointDistance.
            closestX=p1X
            closestY=p1Y
            dx = p1X - p_uX
            dy = p1Y - p_uY
        } else if (t > 1) {
            closestX=p2X
            closestY=p2Y
            dx = p2X - p_uX
            dy = p2Y - p_uY
        } else {
            closestX = p1X + t * dx
            closestY = p1Y + t * dy      // SISTEMARE PERCHÈ RITORNO UNA DISTANZA E NON UN PUNTO … SISTEMA SLIDE 25
            dx = closestX - p_uX
            dy = closestY - p_uY
        }
        let d = sqrt(dx * dx + dy * dy)
        
        return (d, closestX, closestY, dx, dy, t)
    }
    
    func saveData(){
        log.file = "prova_\(NSDate().timeIntervalSince1970).txt"
        log.destinationReached(exit_from_app: false)
    }
}

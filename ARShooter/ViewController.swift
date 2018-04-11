import UIKit
import ARKit
import Each
import AVFoundation

enum BitMaskCategory: Int {
    case bullet = 2
    case target = 3
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var killAmount: UILabel!
    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var exist: UILabel!
    @IBOutlet weak var playbtn: UIButton!
    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var stopbtn: UIButton!
    let configuration = ARWorldTrackingConfiguration()
    var power: Float = 100
    var Target: SCNNode?
    var Bullet: SCNNode?
    var shootScore : Int = 0
    var killedAircraft : Int = 0
    var killedEgg : Int = 0
    var aliveAircraft : Int = 0
    var createNode :Int = 0
    var aliveEgg : Int = 0
    let timer = Each(1).seconds
    var duration : Float = 0
    var textNode = SCNNode()
    var playerBoeing : AVAudioPlayer!
    var playerPlane : AVAudioPlayer!
    var playerExplosion : AVAudioPlayer!
    var playerbullet : AVAudioPlayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(gestureRecognizer)
        self.sceneView.scene.physicsWorld.contactDelegate = self
//        soundBoeing()
//        soundPlane()
//        soundExplosion()
//        soundBullet()
        stopbtn.isHidden = true
        resetBtn.isHidden = true
        
    }
    
    //MARK: ------------------Setup button----------------------------
    @IBAction func addTargets(_ sender: UIButton) {
        
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.isPaused = false
        }
        
        addAnimation()
        updateText()
        setTimer()
        
        playbtn.isHidden = true
        stopbtn.isHidden = false
        resetBtn.isHidden = true
    }
    
    @IBAction func stopAction(_ sender: UIButton) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.isPaused = true
        }
        playbtn.isHidden = false
        stopbtn.isHidden = true
        resetBtn.isHidden = true
    }
    
    @IBAction func resetAction(_ sender: UIButton) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        playbtn.isHidden = false
        stopbtn.isHidden = true
        resetBtn.isHidden = true
        shootScore = 0
        killedAircraft = 0
        killedEgg = 0
        aliveAircraft = 0
        createNode = 0
        aliveEgg = 0
        duration = 0
    }
    
    //MARK: - --------------Sound function------------------------------------------
    func soundBoeing () {
        let path = Bundle.main.path(forResource: "Plane_Ef-Gionex_--8128_hifi", ofType: "mp3")!
        let url = URL(fileURLWithPath: path)
        do {
            playerBoeing = try AVAudioPlayer(contentsOf: url)
            playerBoeing.play()
        } catch let error as NSError {
            print("co loi \(error.description)")
        }
    }
    
    func soundPlane () {
        let path = Bundle.main.path(forResource: "Biplane-LadyIT-2272_hifi", ofType: "mp3")!
        let url = URL(fileURLWithPath: path)
        do {
            playerPlane = try AVAudioPlayer(contentsOf: url)
            playerPlane.play()
        } catch let error as NSError {
            print("co loi \(error.description)")
        }
    }
    
    func soundExplosion () {
        let path = Bundle.main.path(forResource: "Nuklear_-Staberxp-8147_hifi", ofType: "mp3")!
        let url = URL(fileURLWithPath: path)
        do {
            playerExplosion = try AVAudioPlayer(contentsOf: url)
            playerExplosion.play()
        } catch let error as NSError {
            print("co loi \(error.description)")
        }
    }
    
    func soundBullet () {
        let path = Bundle.main.path(forResource: "376060__morganpurkis__mouth-gun", ofType: "wav")!
        let url = URL(fileURLWithPath: path)
        do {
            playerbullet = try AVAudioPlayer(contentsOf: url)
            playerbullet.play()
        } catch let error as NSError {
            print("co loi \(error.description)")
        }
    }
    //MARK: ----------Tap Gesture Recognization----------------------------
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let position = orientation + location
        
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.1))
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        //        let bull = SCNScene(named: "Media.scnassets/missile.scn")
        //        let bullet = (bull?.rootNode.childNode(withName: "missile", recursively: false))!
        bullet.position = SCNVector3(position.x - 0.2, position.y - 0.1, position.z)
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: bullet, options: nil))
        body.isAffectedByGravity = false
        bullet.physicsBody = body
        bullet.physicsBody?.applyForce(SCNVector3(orientation.x*power, orientation.y*power, orientation.z*power), asImpulse: true)
        bullet.physicsBody?.categoryBitMask = BitMaskCategory.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
        self.sceneView.scene.rootNode.addChildNode(bullet)
        bullet.runAction(
            SCNAction.sequence([SCNAction.wait(duration: 6.0),
                                SCNAction.removeFromParentNode()])
        )
        updateText()
       // playerbullet.stop()
      //  playerbullet.play()
        soundBullet()
        
    }
    
    //MARK: --------------Add Node-----------------------------
    func addAnimation () {
        
        let ramdomElement = arc4random_uniform(4)
        if ramdomElement == 1 {
            self.addBoeing(x: randomNumbers(firstNum: 30, secondNum: -30), y: -2, z: -300)
        }
        else {
            self.addPlane( x: randomNumbers(firstNum: 20, secondNum: -20), y:0, z:randomNumbers(firstNum: -80, secondNum: -60))
        }
    }
    
    func addBoeing(x: Float, y: Float, z: Float) {
        let boeingScene = SCNScene(named: "Media.scnassets/B_787_8.scn")
        let boeingNode = (boeingScene?.rootNode.childNode(withName: "fuselage", recursively: false))!
        boeingNode.position = SCNVector3(x,y,z)
        boeingNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: boeingNode, options: nil))
        boeingNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        boeingNode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
        animateNode(node: boeingNode, endPoind: SCNVector3(x: randomNumbers(firstNum: 30, secondNum: -30), y: 40, z: 200), speed : Float(duration + 18), autorevers : true)
        self.sceneView.scene.rootNode.addChildNode(boeingNode)
        soundBoeing()
        aliveAircraft += 1
        boeingNode.name = "Aircraft"
        
    }
    
    func addPlane(x: Float, y: Float, z: Float) {
        let planeScene = SCNScene(named: "Media.scnassets/piper_pa18.scn")
        let planeNode = (planeScene?.rootNode.childNode(withName: "fuselage01", recursively: false))!
        planeNode.position = SCNVector3(x,y,z)
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: planeNode, options: nil))
        planeNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        planeNode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
        animateNode(node: planeNode, endPoind: SCNVector3(x: randomNumbers(firstNum: 30, secondNum: -30), y: randomNumbers(firstNum: 30, secondNum: 0), z: randomNumbers(firstNum: 40, secondNum: 80)), speed: Float(duration + 10), autorevers: true)
        self.sceneView.scene.rootNode.addChildNode(planeNode)
        soundPlane()
        aliveEgg += 1
        planeNode.name = "Egg"
        
    }
    
    func animateNode(node: SCNNode, endPoind : SCNVector3, speed : Float, autorevers : Bool) {
        let spin = CABasicAnimation(keyPath: "position")
        spin.fromValue = node.position
        spin.toValue = endPoind
        spin.duration = CFTimeInterval(speed)
        spin.autoreverses = autorevers
        // spin.repeatCount = 5
        node.addAnimation(spin, forKey: "position")
    }
    
    
    func updateText()
    {
        DispatchQueue.main.async {
            self.killAmount.text = " Plane : \(self.killedAircraft) \n Egg: \(self.killedEgg) "
            self.score.text = " Score \n \(self.shootScore)"
            self.exist.text = " Plane : \(self.aliveAircraft) \n Egg: \(self.aliveEgg)"
            if self.aliveAircraft == 3 || self.aliveEgg == 3 {
                
                
                let textGeometry = SCNText(string: "You Lose", extrusionDepth: 1.0)
                
                textGeometry.firstMaterial?.diffuse.contents = UIColor.red
                
                self.textNode = SCNNode(geometry: textGeometry)
                
                self.textNode.position = SCNVector3(-0.5 , 0, -1)
                
                self.textNode.scale = SCNVector3(0.02, 0.02, 0.02)
                
                self.sceneView.scene.rootNode.addChildNode(self.textNode)
                
                //------stop and resest---------
                self.timer.stop()
                self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
                    node.isPaused = true
                }
                self.playbtn.isHidden = true
                self.stopbtn.isHidden = true
                self.resetBtn.isHidden = false
                
            }
        }
    }
    
    //MARK: -------------Interaction----------------------------
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if nodeA.name == "Egg" && nodeB.name == "Egg" && aliveEgg >= 2 {
            killedEgg += 2
            aliveEgg = aliveEgg - 2
        }
        else if nodeA.name == "Aircraft" && nodeB.name == "Aircraft" && aliveAircraft >= 2 {
            killedAircraft += 2
            aliveAircraft = aliveAircraft - 2
        }
        else if (nodeA.name == "Aircraft" || nodeB.name == "Aircraft") && aliveAircraft >= 1  {
            killedAircraft += 1
            aliveAircraft = aliveAircraft - 1
        }
        else if (nodeA.name == "Egg" || nodeB.name == "Egg") && aliveEgg >= 1 {
            killedEgg += 1
            aliveEgg = aliveEgg - 1
        }
        
        
        
        Target = nodeA
        Bullet = nodeB
        //        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue {
        //            self.Target = nodeA
        //        } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue {
        //            self.Target = nodeB
        //        }
        let confetti = SCNParticleSystem(named: "Media.scnassets/Fire.scnp", inDirectory: nil)
        confetti?.loops = false
        confetti?.particleLifeSpan = 4
        confetti?.emitterShape = Target?.geometry
        let confetti1 = SCNParticleSystem(named: "Media.scnassets/Fire.scnp", inDirectory: nil)
        confetti1?.loops = false
        confetti1?.particleLifeSpan = 4
        confetti1?.emitterShape = Bullet?.geometry
        let confettiNode = SCNNode()
        confettiNode.addParticleSystem(confetti!)
        confettiNode.addParticleSystem(confetti1!)
        confettiNode.position = contact.contactPoint
        self.sceneView.scene.rootNode.addChildNode(confettiNode)
        Target?.removeFromParentNode()
        Bullet?.removeFromParentNode()
        shootScore += 1
        soundExplosion()
        updateText()
        
    }
    //MARK: ------------Set time-----------------------
    func setTimer() {
        self.timer.perform { () -> NextStep in
            self.createNode += 1
            
            if self.createNode == 8 {
                self.duration -= 0.5
                self.createNode = 0
                self.addAnimation()
                self.updateText()
            }
            return .continue
        }
    }
    
    
    //MARK: -----------------Another function----------------
    func randomNumbers(firstNum: Float, secondNum: Float) -> Float {
        return Float(arc4random()) / Float(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    

    
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

//
//  ViewController.swift
//  ARShooter
//
//  Created by Rayan Slim on 2017-09-02.
//  Copyright © 2017 Rayan Slim. All rights reserved.
//

import UIKit
import ARKit

enum BitMaskCategory: Int {
    case bullet = 2
    case target = 3
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var power: Float = 100
    var Target: SCNNode?
    var Bullet: SCNNode?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(gestureRecognizer)
        self.sceneView.scene.physicsWorld.contactDelegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let position = orientation + location
//        let bullet = SCNNode(geometry: SCNSphere(radius: 0.1))
//        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        let bull = SCNScene(named: "Media.scnassets/missile.scn")
        let bullet = (bull?.rootNode.childNode(withName: "missile", recursively: false))!
        bullet.position = position
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
    }

    @IBAction func addTargets(_ sender: Any) {
        //self.addEgg(x: 5, y: 0, z: -40)
        self.addPlane(x: 40, y: 50, z: -200)
        self.addPlane(x: 0, y: 50, z: -180)
        self.addPlane(x: -40, y: 50, z: -200)
//        self.addEgg(x: -5, y: 0, z: -40)
        
    }
    
    func addPlane(x: Float, y: Float, z: Float) {
        let eggScene = SCNScene(named: "Media.scnassets/B_787_8.scn")
        let eggNode = (eggScene?.rootNode.childNode(withName: "fuselage", recursively: false))!
        eggNode.position = SCNVector3(x,y,z)
        eggNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: eggNode, options: nil))
        eggNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        eggNode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
        animateNode(node: eggNode, endPoind: SCNVector3(x: x, y: 100, z: 50), speed : 14, autorevers : false)
        self.sceneView.scene.rootNode.addChildNode(eggNode)
        
    }
    
    func addEgg(x: Float, y: Float, z: Float) {
        let eggScene = SCNScene(named: "Media.scnassets/egg.scn")
        let eggNode = (eggScene?.rootNode.childNode(withName: "egg", recursively: false))!
        eggNode.position = SCNVector3(x,y,z)
        eggNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: eggNode, options: nil))
        eggNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        eggNode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
        animateNode(node: eggNode, endPoind: SCNVector3(x: randomNumbers(firstNum: 30, secondNum: -30), y: randomNumbers(firstNum: 30, secondNum: 0), z: randomNumbers(firstNum: -10, secondNum: -60)), speed: 5, autorevers: true)
        self.sceneView.scene.rootNode.addChildNode(eggNode)
        
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
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
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
        
    }
    func randomNumbers(firstNum: Float, secondNum: Float) -> Float {
        return Float(arc4random()) / Float(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

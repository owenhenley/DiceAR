//
//  ViewController.swift
//  FirstAR
//
//  Created by Owen Henley on 17/03/2019.
//  Copyright © 2019 Owen Henley. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    private var trackerNode: SCNNode!
    private var trackingPosition = SCNVector3Make(0.0, 0.0, 0.0) // Meters
    private var sessionStarted = false
    private var foundSurface = false
    private var diceNode1: SCNNode!
    private var diceNode2: SCNNode!

    private let diceModel = "dice"

    @IBOutlet var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    private func setupScene() {
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Scene.scn")!

        // Set the scene to the view
        sceneView.scene = scene

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }

    private func configureSession() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }

    // MARK: - Methods
    private func handleVisualIndicator() {
        guard !sessionStarted else { return }

        guard let hitTest = sceneView.hitTest(CGPoint(x: view.frame.midX, y: view.frame.midY),
                                              types: [.existingPlane, .featurePoint, .estimatedHorizontalPlane]).first else {
                                                return
        }

        let translation = SCNMatrix4(hitTest.worldTransform)
        trackingPosition = SCNVector3Make(translation.m41, translation.m42, translation.m43)

        if !foundSurface {
            let trackerPlane = SCNPlane(width: 0.2, height: 0.2)
            trackerPlane.firstMaterial?.diffuse.contents = UIImage(named: "tracker")
            trackerPlane.firstMaterial?.isDoubleSided = true

           trackerNode = SCNNode(geometry: trackerPlane)
           trackerNode.eulerAngles.x = -.pi * 0.5
           sceneView.scene.rootNode.addChildNode(self.trackerNode)

           foundSurface = true
        }
        trackerNode.position = self.trackingPosition
    }

    private func rollDice(dice: SCNNode) {
        if dice.physicsBody == nil {
            dice.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        }

        // apply movement
        dice.physicsBody?.applyForce(SCNVector3Make(0.0, 3.0, 0.0), asImpulse: true)

        // spring loaded
        dice.physicsBody?.applyTorque(SCNVector4Make(1.0, 1.0, 1.0, 0.1), asImpulse: true)

    }

    private func handleDiceInteraction() {
        if sessionStarted {
            // Roll dice
            rollDice(dice: diceNode1)
            rollDice(dice: diceNode2)
        } else {
            // Create dice and environment
            trackerNode.removeFromParentNode()
            sessionStarted = true

            let surfacePlane = SCNPlane(width: 50, height: 50)
            surfacePlane.firstMaterial?.diffuse.contents = UIColor.clear

            let surfaceNode = SCNNode(geometry: surfacePlane)
            surfaceNode.position = trackingPosition
            surfaceNode.eulerAngles.x = -.pi * 0.5
            sceneView.scene.rootNode.addChildNode(surfaceNode)
            surfaceNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)

            guard let dice = sceneView.scene.rootNode.childNode(withName: diceModel, recursively: false) else {
                return
            }

            diceNode1 = dice
            diceNode1.position = SCNVector3Make(trackingPosition.x, trackingPosition.y + 0.5, trackingPosition.z)
            diceNode1.isHidden = false

            diceNode2 = diceNode1.clone()
            diceNode2.position.x = trackingPosition.x + 0.2
            sceneView.scene.rootNode.addChildNode(diceNode2)
        }
    }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.handleVisualIndicator()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        DispatchQueue.main.async {
            self.handleDiceInteraction()
        }
    }
}

//
//  CameraAppView.swift
//  _Project
//
//  Created by Shashwath Dinesh on 4/5/25.
//

import SwiftUI
import UIKit
import Combine
import AVFoundation
import Vision
import ARKit
import RealityKit

class CameraViewModel: ObservableObject {
    @Published var detectedObject: String = ""
    @Published var confidence: Float = 0.0
    @Published var boundingBox: CGRect = .zero
    @Published var selectedInfo: String? = nil
    @Published var selectedInfo1: String = ""
    @Published var showPopup: Bool = false
    @Published var savedGuides: [Guide] = []

    func saveGuide(content: String) {
        let newTitle = "New Guide \(savedGuides.count + 1)"
        let guide = Guide(title: newTitle, content: content)
        savedGuides.append(guide)
    }
}

struct CameraAppView: View {
    @ObservedObject var viewModel: CameraViewModel
    var problemDesc: String

    var body: some View {
        ZStack {
            ARCameraView(viewModel: viewModel, problemDesc: problemDesc)

            VStack {
                Spacer()
                Text(viewModel.detectedObject)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            if let info = viewModel.selectedInfo {
                VStack {
                    Spacer()
                    Text(info)
                        .padding()
                        .frame(maxWidth: 250)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .onTapGesture {
                            viewModel.selectedInfo = nil
                        }
                    Spacer().frame(height: 80)
                }
            }
            
            if viewModel.showPopup {
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {

                            Text(viewModel.selectedInfo1)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .background(Color(red: 220/255, green: 245/255, blue: 230/255))
                                    .ignoresSafeArea()

                        }
                        .padding()
                    }
                    .frame(maxHeight: 400)

                    Button(action: {
                        viewModel.saveGuide(content: viewModel.selectedInfo1) 
                        viewModel.showPopup = false
                    }) {
                        Text("Close")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 50/255, green: 140/255, blue: 90/255))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding(.horizontal, 30)
                .transition(.scale)
                .animation(.spring(), value: viewModel.showPopup)
            }

        }
    }
}

struct ARCameraView: UIViewRepresentable {
    @ObservedObject var viewModel: CameraViewModel
    var problemDesc: String

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.viewModel = viewModel
        context.coordinator.arView = arView
        context.coordinator.setupARSession()
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.problemDesc = problemDesc
        return coordinator
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var arView: ARView!
        var viewModel: CameraViewModel!
        let mlQueue = DispatchQueue(label: "mlQueue")
        var placedObjectTypes: Set<String> = []
        var tapSubscriptions: [Cancellable]? = []
        var problemDesc: String = ""


        func setupARSession() {
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            arView.session.delegate = self
            arView.session.run(config)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            arView.addGestureRecognizer(tapGesture)
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            mlQueue.async {
                self.detectObject(pixelBuffer: frame.capturedImage)
            }
        }

        func detectObject(pixelBuffer: CVPixelBuffer) {
            let config = MLModelConfiguration()
            guard let model = try? VNCoreMLModel(for: HardwareClassification(configuration: config).model) else { return }

            let request = VNCoreMLRequest(model: model) { request, error in
                guard let results = request.results as? [VNClassificationObservation], let result = results.first, result.confidence > 0.5 else { return }

                DispatchQueue.main.async {
                    self.viewModel.detectedObject = result.identifier
                    self.viewModel.confidence = result.confidence

                    let partName: String
                    let label: String
                    let color: UIColor

                    switch result.identifier.lowercased() {
                        case let id where id.contains("monitor"):
                            color = .blue
                            partName = "display screen"
                            label = "This is the display"
                        case let id where id.contains("headset"):
                            color = .red
                            partName = "left speaker"
                            label = "This is the left speaker"
                        case let id where id.contains("keyboard"):
                            color = .green
                            partName = "keyboard circuit board"
                            label = "This is the keyboard"
                        default:
                            return
                    }


                    self.placeARSquare(color: color, label: label, partName: partName)
                }
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }

        func placeARSquare(color: UIColor, label: String, partName: String) {
            if placedObjectTypes.contains(label) { return }
            placedObjectTypes.insert(label)

            guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return }

            var transform = cameraTransform
            transform.columns.3.z -= 0.3

            let anchor = AnchorEntity(world: transform)

            let box = ModelEntity(
                mesh: .generateBox(width: 0.06, height: 0.06, depth: 0.02),
                materials: [SimpleMaterial(color: color, isMetallic: false)]
            )
            box.name = label
            box.generateCollisionShapes(recursive: true)

            anchor.addChild(box)
            arView.scene.addAnchor(anchor)

            let tapCancellable = arView.scene.subscribe(to: CollisionEvents.Began.self, on: box) { [weak self] event in
                guard let self = self else { return }

                GeminiManager.shared.getDetailedExplanation(
                    originalProblem: self.viewModel.detectedObject,
                    part: partName
                ) { explanation in
                    DispatchQueue.main.async {
                        self.viewModel.selectedInfo = label
                        self.viewModel.selectedInfo1 = explanation ?? "No details available."
                        self.viewModel.showPopup = true
                    }
                }
            }
        }


        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            let location = sender.location(in: arView)
            if let entity = arView.entity(at: location) {
                let part = entity.name
                print("Entity tapped: \(part)")
                
                GeminiManager.shared.getDetailedExplanation(originalProblem: problemDesc, part: part) { [weak self] explanation in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.viewModel.selectedInfo = part
                        self.viewModel.selectedInfo1 = explanation ?? "No explanation found."
                        self.viewModel.showPopup = true
                    }
                }
            } else {
                print("No entity at tap location")
            }
        }
 
    }
}

class EntityGestureRecognizer {
    let entity: Entity
    let action: () -> Void

    init(entity: Entity, action: @escaping () -> Void) {
        self.entity = entity
        self.action = action
    }

    func register(in arView: ARView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let arView = sender.view as? ARView else { return }

        let location = sender.location(in: arView)
        if let tappedEntity = arView.entity(at: location), tappedEntity == entity {
            action()
        }
    }
}

struct Guide: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
}



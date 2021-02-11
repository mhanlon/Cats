//
//  ViewController.swift
//  Cats
//
//  Created by Matthew Hanlon on 09/02/2021.
//  Copyright © 2021 Teaching Develop in Swift. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var hintLabel: UILabel!
    @IBOutlet var imageButton: UIButton!
    @IBOutlet var descriptionLabel: UILabel!

    var imagePicker = UIImagePickerController()
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            guard let modelURL = Bundle.main.url(forResource: "MyCatEmotionClassifier", withExtension: "mlmodelc") else {
                fatalError("We could not load our model")
            }
            let model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
                })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load our model! Error: \(error)")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.descriptionLabel.font = UIFont(name: "Helvetica", size: 48)
    }
    
    @IBAction func selectImage(_ sender: Any) {
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true, completion: nil)
    }

    func updateUI() {
        if self.imageView.image != nil {
            // Get rid of our hint label
            self.hintLabel.isHidden = true
        } else {
            self.hintLabel.isHidden = false
        }
    }

    func classify(image: UIImage) {
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else {
            fatalError("Unable to create \(CIImage.self) from \(image).")
        }
        self.descriptionLabel.text = "🧭"
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to classify.\n\(error.localizedDescription)")
            }
        }

    }
    
    // MARK: - Classification
    /// Here we read our results from the ml request and figure out what
    /// emotion the cat is showing us...
    func processClassifications(for request: VNRequest, error: Error?) {
        // We're updating the UI, so we need to jump back
        // onto the main thread
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.descriptionLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
        
            if classifications.isEmpty {
                self.descriptionLabel.text = "🤷‍♂️"
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    return (classification.confidence > 0.6) ? self.sign(for: classification.identifier) : ""
                }
                self.descriptionLabel.text = descriptions.joined(separator: "\n")
            }
        }
    }
    
    /// This returns our super scientific notation for what mood a cat is in, based on an identifier
    func sign(for identifier: String) -> String {
        switch identifier {
        case "happy":
            return "😺"
        case "sad":
            return "😿"
        case "mad":
            return "😾"
        case "surprised":
            return "🙀"
        default:
            return "😸"
        }
    }

    // MARK: ImagePickerDelegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true)
        let image = info[.originalImage] as! UIImage
        self.imageView.image = image
        self.updateUI()
        self.classify(image: image)
    }
}

// To convert our UIImage orientation to the CGImagePropertyOrientation, since their rawValues don't match.
// See https://developer.apple.com/documentation/imageio/cgimagepropertyorientation
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        @unknown default:
            fatalError("We had an image orientation hitherto unknown!")
        }
    }
}

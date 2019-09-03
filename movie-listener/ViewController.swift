//
//  ViewController.swift
//  movie-listener
//
//  Created by Kamaal Farah on 03/09/2019.
//  Copyright © 2019 Kamaal. All rights reserved.
//

import Foundation
import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    @IBOutlet weak var spokenTextLabel: UILabel!
    @IBOutlet weak var plotLabel: UILabel!
    @IBOutlet weak var tapToSpeakButton: UIButton!
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? =  SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording = false
    var titleLength = 1

    let baseUrl = "http://localhost:5000"

    
    func requestSpeechAutherization() -> Void {
        SFSpeechRecognizer.requestAuthorization {
            authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.tapToSpeakButton.isEnabled = true
                case .denied:
                    self.tapToSpeakButton.isEnabled = false
                    self.spokenTextLabel.text = "User denied access to speech recognition"
                case .restricted:
                    self.tapToSpeakButton.isEnabled = false
                    self.spokenTextLabel.text = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.tapToSpeakButton.isEnabled = false
                    self.spokenTextLabel.text = "Speech recognition not yet autherized"
                default:
                    self.tapToSpeakButton.isEnabled = false
                    self.spokenTextLabel.text = "Something went wrong!!!"
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.requestSpeechAutherization()
        
    }
    
    func apiRequest(at url: String, for title: String, completion: @escaping (_ res: [String: Any]) -> Void) {
        guard let url = URL(string: "\(url)/movies/search/\(title)") else { return }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let dataResponse = data, error == nil else {
                print(error?.localizedDescription ?? "Response Error")
                return
            }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: [])
                completion(jsonResponse as! [String : Any])
            } catch let parsingError { print("Error", parsingError) }
        }
        task.resume()
    }
    
    func getMovies(from url: String, for title: String?) -> Void {
        self.apiRequest(at: "http://localhost:5000", for: "batman", completion: {
            (res: Any) in if let dictionary = res as? [String: Any] {
                print(dictionary)
            }
        })
    }
    
    
    func sendAlert(message: String) {
        let alert = UIAlertController(title: "Speech Recognizer Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func recordAndRecognizeSpeech() -> Void {
        let node: AVAudioInputNode = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            buffer, _ in self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.sendAlert(message: "There has been an audio engine error.")
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            self.sendAlert(message: "Speech recognition is not currently available. Check back at a later time.")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: {
            result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self.spokenTextLabel.text = bestString
                
                let splittenString = bestString.split(separator: " ")
                if splittenString.count > self.titleLength {
                    let range = splittenString
                        .index(splittenString.endIndex, offsetBy: -self.titleLength) ..< splittenString.endIndex
                    let arraySlice = splittenString[range]
                    self.plotLabel.text = (arraySlice.joined(separator:" "))
                    
                    // CALL API HERE
                }
                
                if splittenString.count >= self.titleLength {
                    let range = splittenString.index(splittenString.endIndex, offsetBy: -self.titleLength) ..< splittenString.endIndex
                    let slicedArray = splittenString[range]
                    self.plotLabel.text = (slicedArray.joined(separator:" "))
                }
            } else if let error = error {
                print(error)
            }
        })
    }
    
    func cancelRecording() {
        audioEngine.stop()
        let node  = audioEngine.inputNode
        node.removeTap(onBus: 0)
        
        recognitionTask?.cancel()
    }
    
    func getMovies(at url: String, for title: String?) -> Void {
        if let title = title {
            apiRequest(at: url, for: title, completion: {
                (res: Any) in if let dictionary = res as? [String: Any] {
                    print(dictionary)
                }
            })
        }
    }

    @IBAction func tapToSpeak(_ sender: UIButton) {
        if isRecording == true {
            self.cancelRecording()
            self.getMovies(at: self.baseUrl, for: self.plotLabel.text)
            isRecording = false
            tapToSpeakButton.setTitle("START", for: .normal)
            tapToSpeakButton.setTitleColor(.gray, for: .normal)
//            print(self.plotLabel.text ?? String.self)
            self.getMovies(from: "http://localhost:5000", for: self.plotLabel.text)
        } else {
            self.recordAndRecognizeSpeech()
            isRecording = true
            tapToSpeakButton.setTitle("STOP", for: .normal)
            tapToSpeakButton.setTitleColor(.red, for: .normal)
        }
    }
}


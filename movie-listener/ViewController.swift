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
    @IBOutlet weak var tapToSpeakButton: UIButton!
    
    @IBOutlet var MovieList: [UILabel]!
    
    var titleLength = 1
    let baseUrl = "http://localhost:5000"
//    let baseUrl = "https://pure-gorge-27494.herokuapp.com"

    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? =  SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording = false
    
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
        
        self.spokenTextLabel.text = ""
        for movie in self.MovieList {
            movie.text = ""
        }
        
        self.requestSpeechAutherization()
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
                
                let splittenString = bestString.split(separator: " ")
                
                if splittenString.count >= self.titleLength {
                    let range = splittenString.index(splittenString.endIndex, offsetBy: -self.titleLength) ..< splittenString.endIndex
                    let slicedArray = splittenString[range]
                    self.spokenTextLabel.text = (slicedArray.joined(separator:" "))
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
    
    var model = [MovieMap]()
    
    
    func getMovies(at url: String, for title: String?) -> Void {
        if let title = title {
            
            apiRequest(at: url, for: title, completion: {
                
                (res: Any) in if let dictionary = res as? [String: Any],
                    let data = dictionary["data"] as? [String: Any] {
                    
                    self.model.append(MovieMap(data))
                    print("start", self.model[0].results.count)

                        for (index, result) in self.model[0].results.enumerated() {
                            //  release_date
                            if let originalTitle = result["original_title"] as? String {
                                DispatchQueue.main.async {
                                    self.MovieList[index].text = originalTitle
                                }
                            }
                        }
                    }
            })
        }
    }

    @IBAction func tapToSpeak(_ sender: UIButton) {
        if isRecording == true {
            self.cancelRecording()
//            self.getMovies(at: self.baseUrl, for: self.spokenTextLabel.text)
            self.getMovies(at: self.baseUrl, for: "Batman")
            if (self.model.count >= 1) {
                 print("End", self.model[0].results.count)
            }
           
            isRecording = false
            tapToSpeakButton.setTitle("START", for: .normal)
            tapToSpeakButton.setTitleColor(.gray, for: .normal)
        } else {
            self.recordAndRecognizeSpeech()
            isRecording = true
            tapToSpeakButton.setTitle("STOP", for: .normal)
            tapToSpeakButton.setTitleColor(.red, for: .normal)
        }
    }
}


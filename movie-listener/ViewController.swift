//
//  ViewController.swift
//  movie-listener
//
//  Created by Kamaal Farah on 03/09/2019.
//  Copyright © 2019 Kamaal. All rights reserved.
//

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
                
                let splitten = bestString.split(separator: " ")
                    let range = splitten.index(splitten.endIndex, offsetBy: -1) ..< splitten.endIndex
                    let arraySlice = splitten[range]
                    self.plotLabel.text = (arraySlice.joined(separator:" "))
                    
                    // CALL API HERE
            } else if let error = error {
//                self.sendAlert(message: "Please wait")
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

    @IBAction func tapToSpeak(_ sender: UIButton) {
        if isRecording == true {
            self.cancelRecording()
            isRecording = false
            tapToSpeakButton.setTitleColor(.gray, for: .normal)
        } else {
            self.recordAndRecognizeSpeech()
            isRecording = true
//            tapToSpeakButton.isHidden = true
            tapToSpeakButton.setTitle("STOP", for: .normal)
            tapToSpeakButton.setTitleColor(.red, for: .normal)
        }
    }
}


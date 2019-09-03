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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? =  SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    func recordAndRecognizeSpeech() -> Void {
        let node: AVAudioNode = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            buffer, _ in self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            print("recognizer is not supported on current locale")
            return
        }
        if !myRecognizer.isAvailable {
            print("recognizer is not available")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: {
            result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                
                self.spokenTextLabel.text = bestString
            } else if let error = error {
                print(error)
            }
        })
    }

    @IBAction func tapToSpeak(_ sender: UIButton) {
        self.recordAndRecognizeSpeech()
        print("HALLO")
    }
    
}


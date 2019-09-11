//
//  ViewController.swift
//  movie-listener
//
//  Created by Kamaal Farah on 03/09/2019.
//  Copyright © 2019 Kamaal. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var spokenTextLabel: UILabel!
    @IBOutlet weak var tapToSpeakButton: UIButton!
    @IBOutlet weak var titleLengthLable: UILabel!
    @IBOutlet weak var titleLengthStepperValue: UIStepper!
    
    @IBOutlet weak var languageSegment: UISegmentedControl!
    
    @IBOutlet weak var innerView: UIView!
    @IBOutlet var MovieList: [UILabel]!
    @IBOutlet var yearList: [UILabel]!
    
    
//    let baseUrl = "http://localhost:5000"
    let baseUrl = "https://pure-gorge-27494.herokuapp.com"

    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? =  SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    let request = SFSpeechAudioBufferRecognitionRequest()
    let synthesizer = AVSpeechSynthesizer()
    
    var model: [MovieMap] = [MovieMap]()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording = false
    
    
    enum Theme {
        case
        start,
        startColor,
        stop,
        stopColor,
        backgroundColor,
        spokenTextColor,
        resultsColor
    }
    
    var theme: [Theme: Any] = [
        Theme.start: "START",
        Theme.startColor: UIColor.gray,
        Theme.stop: "STOP",
        Theme.stopColor : UIColor.red,
        Theme.backgroundColor: UIColor.white,
        Theme.spokenTextColor: UIColor.black,
        Theme.resultsColor: #colorLiteral(red: 0.4573462605, green: 0.04310884327, blue: 0, alpha: 1)
    ]
    
    var outputLanguage = "en-AU"
    
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
        self.tapToSpeakButton.setTitleColor(self.theme[Theme.startColor] as? UIColor, for: .normal)
        self.titleLengthStepperValue.autorepeat = true
        self.titleLengthStepperValue.minimumValue = 1.0
        self.titleLengthStepperValue.maximumValue = 4.0
        self.titleLengthLable.text = "\(1)"
        for (index, movie) in self.MovieList.enumerated() {
            self.yearList[index].text = ""
            movie.isUserInteractionEnabled = false
            movie.text = ""
            movie.textColor = self.theme[Theme.resultsColor] as? UIColor
        }
        
        self.requestSpeechAutherization()
    }
    
    func sendAlert(message: String) {
        let alert = UIAlertController(title: "Speech Recognizer Error", message: message,
                                      preferredStyle: UIAlertController.Style.alert)
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
                
                if let string = self.titleLengthLable.text, let myInt = Int(string){
                    if splittenString.count >= myInt {
                        let range = splittenString.index(splittenString.endIndex,
                                                         offsetBy: -myInt) ..< splittenString.endIndex
                        let slicedArray = splittenString[range]
                        self.spokenTextLabel.text = (slicedArray.joined(separator:" "))
                    }
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
    
    @objc func tapMovie(sender: UITapGestureRecognizer) {
        let currentIndex = self.model.count - 1
        let movie = self.model[currentIndex]
            .results[Int.random(in: 0..<self.model[currentIndex].results.count)]
        if let overview = movie["overview"] as? String {
            let utterance = AVSpeechUtterance(string: overview)
            utterance.voice = AVSpeechSynthesisVoice(language: self.outputLanguage)
            utterance.rate = 0.4
            
            self.synthesizer.speak(utterance)
            
            print("location", sender.location(in: self.innerView))
        }
    }
    
    
    func getMovies(at url: String, for title: String?, on page: String) -> Void {
        if let title = title {
            
            apiRequest(at: url, for: title, on: page, completion: {
                
                (res: Any) in if let dictionary = res as? [String: Any],
                    let data = dictionary["data"] as? [String: Any] {
                    
                    self.model.append(MovieMap(data))
                    print("start", self.model[self.model.count - 1].results.count)

                        for (index, result) in self.model[self.model.count - 1].results.enumerated() {
                            if let originalTitle = result["original_title"] as? String,
                                let _ = result["release_date"] as? String {
                                
                                DispatchQueue.main.async {
//                                    let splittenReleaseDate = releaseDate.split(separator: "-")[0]
                                    self.MovieList[index].text = originalTitle
//                                    self.yearList[index].text = String(splittenReleaseDate)
                                    let tap = UITapGestureRecognizer(
                                        target: self, action: #selector(
                                            self.tapMovie(sender:)))
                                    self.MovieList[index].isUserInteractionEnabled = true
                                    self.MovieList[index].addGestureRecognizer(tap)
                                }
                            }
                        }
                    }
            })
        }
    }
    
    @IBAction func titleLengthCounterButton(_ sender: UIStepper) {
        self.titleLengthLable.text = "\(Int(self.titleLengthStepperValue.value))"
    }
    
    func japanTheme() {
        self.outputLanguage = "ja-JA"
        
        self.theme[Theme.startColor] = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
        self.theme[Theme.start] = "スタート"
        self.theme[Theme.stop] = "やめる"
        self.theme[Theme.backgroundColor] = UIColor.black
        self.theme[Theme.resultsColor] = UIColor.cyan
        self.theme[Theme.spokenTextColor] = UIColor.white
        
        if let tapToSpeak = self.tapToSpeakButton.title(for: .normal) {
            if tapToSpeak == "START" {
                self.tapToSpeakButton.setTitleColor(self.theme[Theme.startColor] as? UIColor, for: .normal)
                self.tapToSpeakButton.setTitle(self.theme[Theme.start] as? String, for: .normal)
            } else {
                self.tapToSpeakButton.setTitle(self.theme[Theme.stop] as? String, for: .normal)
            }
        }

        self.titleLengthLable.textColor = self.theme[Theme.spokenTextColor] as? UIColor
        self.innerView.backgroundColor = self.theme[Theme.backgroundColor] as? UIColor
        self.spokenTextLabel.textColor = self.theme[Theme.spokenTextColor] as? UIColor
        view.backgroundColor = self.theme[Theme.backgroundColor] as? UIColor
        
        for (index, movie) in self.MovieList.enumerated() {
            self.yearList[index].textColor = self.theme[Theme.resultsColor] as? UIColor
            movie.textColor = self.theme[Theme.resultsColor] as? UIColor
        }
    }
    
    func englishTheme() {
        self.outputLanguage = "en-AU"
        
        self.theme[Theme.startColor] = UIColor.gray
        self.theme[Theme.start] = "START"
        self.theme[Theme.stop] = "STOP"
        self.theme[Theme.backgroundColor] = UIColor.white
        self.theme[Theme.resultsColor] = #colorLiteral(red: 0.4573462605, green: 0.04310884327, blue: 0, alpha: 1)
        self.theme[Theme.spokenTextColor] = UIColor.black
        
        if let tapToSpeak = self.tapToSpeakButton.title(for: .normal) {
            if tapToSpeak == "スタート" {
                self.tapToSpeakButton.setTitleColor(self.theme[Theme.startColor] as? UIColor, for: .normal)
                self.tapToSpeakButton.setTitle(self.theme[Theme.start] as? String, for: .normal)
            } else {
                self.tapToSpeakButton.setTitle(self.theme[Theme.stop] as? String, for: .normal)
            }
        }
        
        self.titleLengthLable.textColor = self.theme[Theme.spokenTextColor] as? UIColor
        self.innerView.backgroundColor = self.theme[Theme.backgroundColor] as? UIColor
        self.spokenTextLabel.textColor = self.theme[Theme.spokenTextColor] as? UIColor
        view.backgroundColor = self.theme[Theme.backgroundColor] as? UIColor
        
        for (index, movie) in self.MovieList.enumerated() {
            self.yearList[index].textColor = self.theme[Theme.resultsColor] as? UIColor
            movie.textColor = self.theme[Theme.resultsColor] as? UIColor
        }
    }
    
    @IBAction func langSegmentChanged(_ sender: UISegmentedControl) {
        if let segmentLang = self.languageSegment.titleForSegment(at: sender.selectedSegmentIndex) {
            switch segmentLang {
            case "JP": return self.japanTheme()
            case "EN": return self.englishTheme()
            default: return self.outputLanguage = "en-US"
            }
        }
    }
    

    @IBAction func tapToSpeak(_ sender: UIButton) {
        if isRecording == true {
            self.cancelRecording()
            let modifiedMovie = self.spokenTextLabel.text?.split(separator: " ").joined(separator: "%20")
            self.getMovies(at: self.baseUrl, for: modifiedMovie, on: "1")

////          testing without speaking
//            self.getMovies(at: self.baseUrl, for: "batman")

            if (self.model.count >= 1) {
                 print("End", self.model[self.model.count - 1].results.count)
            }
           
            isRecording = false
            tapToSpeakButton.setTitle(self.theme[Theme.start] as? String, for: .normal)
            tapToSpeakButton.setTitleColor(self.theme[Theme.startColor] as? UIColor, for: .normal)
        } else {
            for (index, movie) in self.MovieList.enumerated() {
                self.yearList[index].text = ""
                movie.isUserInteractionEnabled = false
                movie.text = ""
            }
            
            self.recordAndRecognizeSpeech()
            isRecording = true
            tapToSpeakButton.setTitle(self.theme[Theme.stop] as? String, for: .normal)
            tapToSpeakButton.setTitleColor(self.theme[Theme.stopColor] as? UIColor, for: .normal)
        }
    }
}


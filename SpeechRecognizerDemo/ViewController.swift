//
//  ViewController.swift
//  SpeechRecognizerDemo
//
//  Created by dhara.patel on 24/02/17.
//  Copyright © 2017 SASA. All rights reserved.
//

import UIKit
import Speech
import CocoaLumberjack

//import CocoaLumberjackSwift

//SFSpeechRecognizerDelegate - A protocol that helps you track the availability of a speech recognizer.
class ViewController: UIViewController , SFSpeechRecognizerDelegate{

    //let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    let speechRecognizer = SFSpeechRecognizer()!
    var recognizeRequest : SFSpeechAudioBufferRecognitionRequest?
    var recognizeURLRequest : SFSpeechURLRecognitionRequest?
    let audioEngine = AVAudioEngine()
    var recognitionTask: SFSpeechRecognitionTask?


    @IBOutlet weak var IBtxtViewText: UITextView!
    @IBOutlet weak var IBbtnRecord: UIButton!
    @IBOutlet weak var IBbtnTextToSpeech: UIButton!
  
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        IBbtnRecord.setTitleColor(UIColor.blue, for: .normal)
        speechRecognizer.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /* The callback may not be called on the main thread. Add an\
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.IBbtnRecord.isEnabled = true
                case .denied:
                    self.IBbtnRecord.isEnabled = false
                    self.IBbtnRecord.setTitle("User denied access to speech recognition", for: .disabled)
                case .restricted:
                    self.IBbtnRecord.isEnabled = false
                    self.IBbtnRecord.setTitle("Speech recognition restricted on this device", for: .disabled)
                case .notDetermined:
                    self.IBbtnRecord.isEnabled = false
                    self.IBbtnRecord.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    @IBAction func btnRecordTapped(_ sender: Any) {
        
        if audioEngine.isRunning{
            audioEngine.stop()
            recognizeRequest?.endAudio()
            IBbtnRecord.isEnabled = false
            IBbtnRecord.setTitle("Start Recording", for: .normal)
            IBbtnRecord.setTitleColor(UIColor.blue, for: .normal)
            
        } else{
             startRecording()
            IBbtnRecord.setTitle("Stop Recording", for: .normal)
            IBbtnRecord.setTitleColor(UIColor.red, for: .normal)
        }
    }
    func startRecording() {
        // Cancel the previous task if it's running.
        
        if recognitionTask != nil{
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognizeRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let inputNode = audioEngine.inputNode else {
                fatalError("Audio engine has no input node")
        }
        guard let recognizeRequest = recognizeRequest else {
                fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object")
        }
        recognizeRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with : recognizeRequest) { result , error in
        var isFinal = false
            if let result = result{
                self.IBtxtViewText.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 8)
                
                self.recognizeRequest = nil
                self.recognitionTask = nil
                self.IBbtnRecord.isEnabled = true
                self.IBbtnRecord.setTitle("Start Recording", for: .normal )
                
            }
        }
        let recordingFormat = inputNode.outputFormat(forBus: 10)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognizeRequest?.append(buffer)
        })
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        IBtxtViewText.text = "hey,,,I am Listening!!!!"
        
    }
    @IBAction func btnTextToSpeech(_ sender: Any) {
        let formatter = Formatter()
        DDTTYLogger.sharedInstance().logFormatter = formatter
        DDLog.add(DDTTYLogger.sharedInstance())
        if recognitionTask != nil{
            recognitionTask?.cancel()
            recognitionTask = nil
        }
       
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "ST MixDemo Reportage Dokus", ofType: ".mp3")!)
     //  let request = SFSpeechURLRecognitionRequest(url: fileURL)
     // let url = URL(string: "file://localhost/Users/dhara.patel/Music/iTunes/iTunes Media/Music/Unknown Artist/Unknown Album/ST MixDemo Reportage Dokus.mp3")
        guard let speechRecognize = SFSpeechRecognizer() else{
           fatalError("A recognizer is not supported for the current locale")
        }
        if speechRecognize.isAvailable{
            IBbtnTextToSpeech.isEnabled = true
        }else {
            IBbtnTextToSpeech.isEnabled = false
        }
        recognizeURLRequest?.shouldReportPartialResults = true
        recognizeURLRequest = SFSpeechURLRecognitionRequest(url: url as URL)
        recognitionTask = speechRecognizer.recognitionTask(with: recognizeURLRequest!, resultHandler: {(results , error) in
        
            if let err = error{
                DDLogError("There was an problem: \(err)")
            }else {
                 DDLogVerbose("speech in the file is \(results!.bestTranscription.formattedString)")
                 self.IBtxtViewText.text = results?.bestTranscription.formattedString
            }
            //DDLogVerbose("speech in the file is \(results?.bestTranscription.formattedString)")
          // print("speech in the file is \(results?.bestTranscription.formattedString)")
           // guard let result = results else {
//                fatalError("Recognition failed, so check error for details and handle it")
//            }
//            if result.isFinal {
//                
//
//            //print("speech in the file is \(result.bestTranscription.formattedString)")
//            }
//        if error != nil  {
//            self.recognizeRequest = nil
//            self.recognitionTask = nil
//            self.IBbtnTextToSpeech.isEnabled = true
//        }else {
//
//            }
          
        })
    }
    //Tells the delegate when the availability of the speech recognizer has changed.
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
        if available{
            IBbtnRecord.isEnabled = true
            IBbtnTextToSpeech.isEnabled = true
        } else{
            IBbtnRecord.isEnabled = false
            IBbtnTextToSpeech.isEnabled = false
        }
        
    }
    
}


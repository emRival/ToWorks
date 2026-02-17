//
//  SpeechManager.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Supported Languages

// VoiceLanguage struct moved to Models/VoiceLanguage.swift

class SpeechManager: ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var error: String?
    @Published var activeLanguage: VoiceLanguage = .auto
    
    private var resolvedLocale: Locale {
        if activeLanguage.id == "Auto" {
            return Locale.current
        }
        return Locale(identifier: activeLanguage.id)
    }
    
    init() {
        // Load saved language
        let saved = UserDefaults.standard.string(forKey: "voiceLanguage") ?? "Auto"
        activeLanguage = VoiceLanguage.from(id: saved)
    }
    
    func setLanguage(_ lang: VoiceLanguage) {
        activeLanguage = lang
        UserDefaults.standard.set(lang.id, forKey: "voiceLanguage")
        
        // If currently recording, restart with new language
        if isRecording {
            stopRecording()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.startRecording()
            }
        }
    }
    
    func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    break
                case .denied:
                    self.error = "Speech recognition authorization denied"
                case .restricted:
                    self.error = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.error = "Speech recognition not yet authorized"
                @unknown default:
                    self.error = "Unknown speech recognition status"
                }
            }
        }
    }
    
    func startRecording() {
        // 1. Check if language is supported on this device
        let locale = resolvedLocale
        if !SFSpeechRecognizer.supportedLocales().contains(locale) {
            self.error = "Language \(locale.identifier) is not supported on this device."
            return
        }
        
        // 2. Initialize Recognizer
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            self.error = "Voice language not supported on this device"
            return
        }
        
        if !recognizer.isAvailable {
            self.error = "Speech recognizer is not available right now"
            return
        }
        
        speechRecognizer = recognizer
        
        // 3. Clean up previous task if any
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 4. Configure Audio Session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "Audio session properties weren't set because of an error."
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            self.error = "Unable to create an SFSpeechAudioBufferRecognitionRequest object"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 5. Keep reference to task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
        
        // 6. Install Tap on Audio Engine
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Safety check: remove tap if it already exists (prevents crash)
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
            recognizedText = activeLanguage.listeningText
            self.error = nil // Clear previous errors
        } catch {
            self.error = "audioEngine couldn't start because of an error."
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0) // Critical for avoiding overload
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
    }
}

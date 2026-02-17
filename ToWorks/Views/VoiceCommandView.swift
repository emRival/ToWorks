//
//  VoiceCommandView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData
import Combine

struct VoiceCommandView: View {
    @StateObject private var speechManager = SpeechManager()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var isPulsing = false
    @State private var parsedTitle = ""
    @State private var parsedNotes = ""
    @State private var parsedLocation = ""
    @State private var parsedDate: Date? = nil
    @State private var parsedPriority = "Medium"
    @State private var showResult = false
    @State private var waveHeights: [CGFloat] = Array(repeating: 20, count: 7)
    @State private var showLanguagePicker = false
    
    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.08, green: 0.06, blue: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(speechManager.isRecording ? Color.red : Color.green)
                            .frame(width: 6, height: 6)
                        Text(LocalizationManager.shared.localized("VOICE COMMAND"))
                            .font(.system(size: 11, weight: .heavy))
                            .kerning(1.5)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Language picker button
                    Button { showLanguagePicker = true } label: {
                        Text(speechManager.activeLanguage.flag)
                            .font(.system(size: 20))
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Current language indicator
                Text("\(speechManager.activeLanguage.flag) \(speechManager.activeLanguage.name)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.06))
                    .cornerRadius(12)
                    .padding(.top, 10)
                
                Spacer()
                
                // Status text
                Text(statusText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 24)
                
                // Visualizer
                ZStack {
                    // Pulse rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                            .frame(width: CGFloat(160 + i * 50), height: CGFloat(160 + i * 50))
                            .scaleEffect(isPulsing && speechManager.isRecording ? 1.2 : 1.0)
                            .opacity(isPulsing && speechManager.isRecording ? 0.0 : 0.3)
                            .animation(
                                speechManager.isRecording
                                    ? .easeOut(duration: 2.0).repeatForever(autoreverses: false).delay(Double(i) * 0.4)
                                    : .default,
                                value: isPulsing && speechManager.isRecording
                            )
                    }
                    
                    // Main circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(speechManager.isRecording ? 0.3 : 0.1),
                                    Color.purple.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 150, height: 150)
                    
                    // Waveform bars
                    HStack(spacing: 5) {
                        ForEach(0..<7, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 4, height: waveHeights[i])
                                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: waveHeights[i])
                        }
                    }
                    .opacity(speechManager.isRecording ? 1 : 0.2)
                }
                .frame(height: 200)
                .onReceive(timer) { _ in
                    if speechManager.isRecording {
                        waveHeights = (0..<7).map { _ in CGFloat.random(in: 15...55) }
                    } else {
                        waveHeights = Array(repeating: 20, count: 7)
                    }
                }
                .onAppear {
                    isPulsing = true
                    speechManager.checkPermissions()
                }
                
                // Transcription & Parsed Result
                VStack(spacing: 12) {
                    if speechManager.isRecording {
                        Text(speechManager.recognizedText.isEmpty ? LocalizationManager.shared.localized("Listening...") : speechManager.recognizedText)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 24)
                    } else if showResult && !parsedTitle.isEmpty {
                        // Show parsed result
                        VStack(spacing: 14) {
                            Text(LocalizationManager.shared.localized("Parsed Task"))
                                .font(.system(size: 11, weight: .heavy))
                                .kerning(1)
                                .foregroundColor(.blue.opacity(0.7))
                            
                            Text(parsedTitle)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            // Location badge
                            if !parsedLocation.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 10))
                                    Text(parsedLocation)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                }
                                .foregroundColor(.pink.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.pink.opacity(0.12))
                                .cornerRadius(10)
                            }
                            
                            // Notes preview
                            if !parsedNotes.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 10))
                                    Text(parsedNotes)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(2)
                                }
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.08))
                                .cornerRadius(10)
                            }
                            
                            HStack(spacing: 16) {
                                // Date badge
                                HStack(spacing: 5) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 11))
                                    Text(parsedDate ?? Date(), format: .dateTime.day().month(.abbreviated).hour().minute())
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.cyan.opacity(0.12))
                                .cornerRadius(10)
                                
                                // Priority badge
                                HStack(spacing: 5) {
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 11))
                                    Text(parsedPriority)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(priorityColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(priorityColor.opacity(0.12))
                                .cornerRadius(10)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.06))
                        .cornerRadius(20)
                        .padding(.horizontal, 24)
                    } else if !speechManager.recognizedText.isEmpty {
                        Text(speechManager.recognizedText)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    } else {
                        Text(LocalizationManager.shared.localized("Tap the mic to start"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .frame(minHeight: 120)
                .padding(.top, 20)
                
                Spacer()
                
                // Action buttons
                if showResult && !parsedTitle.isEmpty {
                    Button {
                        createTask()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text(LocalizationManager.shared.localized("Create Task"))
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    
                    Button {
                        resetState()
                    } label: {
                        Text(speechManager.activeLanguage.retryText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.bottom, 16)
                }
                
                // Mic Controls
                HStack(spacing: 32) {
                    Button {
                        resetState()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 52, height: 52)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    
                    // Main mic button
                    Button {
                        if speechManager.isRecording {
                            speechManager.stopRecording()
                            // analyzeCommand is handled by .onChange(of: isRecording)
                        } else {
                            resetState()
                            speechManager.startRecording()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(speechManager.isRecording ? Color.red : Color.blue)
                                .frame(width: 72, height: 72)
                                .shadow(color: (speechManager.isRecording ? Color.red : Color.blue).opacity(0.4), radius: 16, y: 4)
                            
                            Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 52, height: 52)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        // Auto-analyze when recording stops
        .onChange(of: speechManager.isRecording) { _, isRecording in
            if !isRecording && !speechManager.recognizedText.isEmpty && !speechManager.recognizedText.starts(with: "Listening") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    analyzeCommand()
                }
            }
        }
        .sheet(isPresented: $showLanguagePicker) {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(VoiceLanguage.allLanguages) { lang in
                            Button {
                                speechManager.setLanguage(lang)
                                LocalizationManager.shared.languageDidChange() // Trigger Propagation
                                showLanguagePicker = false
                            } label: {
                                HStack(spacing: 10) {
                                    Text(lang.flag)
                                        .font(.system(size: 24))
                                    Text(lang.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Spacer()
                                    if lang.id == speechManager.activeLanguage.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(14)
                                .background(
                                    lang.id == speechManager.activeLanguage.id
                                    ? Color.blue.opacity(0.1)
                                    : Color(.secondarySystemGroupedBackground)
                                )
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            lang.id == speechManager.activeLanguage.id ? Color.blue : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(LocalizationManager.shared.localized("Voice Language"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(LocalizationManager.shared.localized("Done")) { showLanguagePicker = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Status Text
    
    private var statusText: String {
        if speechManager.isRecording {
            return speechManager.activeLanguage.listeningText
        } else if showResult {
            return speechManager.activeLanguage.readyText
        } else if let error = speechManager.error {
            return "⚠️ \(error)"
        } else {
            return speechManager.activeLanguage.helpText
        }
    }
    
    private var priorityColor: Color {
        switch parsedPriority {
        case "High": return .red
        case "Low": return .green
        default: return .orange
        }
    }
    
    // MARK: - Smart Command Analysis
    
    private func analyzeCommand() {
        let raw = speechManager.recognizedText
        guard !raw.isEmpty, raw != "Listening...", raw != speechManager.activeLanguage.listeningText else { return }
        
        var workingText = raw
        var title = ""
        var notes = ""
        var location = ""
        var date = Date()
        var priority = "Medium"
        
        let lowText = raw.lowercased()
        
        // --- Priority Detection ---
        if lowText.contains("urgent") || lowText.contains("important") || lowText.contains("penting") || lowText.contains("high priority") || lowText.contains("緊急") || lowText.contains("긴급") {
            priority = "High"
        }
        
        // =============================================
        // STEP 1: Extract Date (besok, lusa, etc.)
        // =============================================
        if let relativeDate = parseRelativeTime(from: lowText) {
            date = relativeDate
        } else {
            date = parseManualDate(from: lowText) ?? Date()
        }
        
        // =============================================
        // STEP 2: Extract Time (jam 07.15 pagi, jam 3 sore, at 3pm)
        // =============================================
        date = parseTime(from: lowText, baseDate: date)
        
        // =============================================
        // STEP 3: Extract Location ("di [place]")
        // =============================================
        // Pattern: "di [place]" — capture word(s) after "di" up to a comma, time phrase, or note keyword
        let locationPattern = #"\bdi\s+([A-Za-z\u00C0-\u024F]+(?:\s+[A-Za-z\u00C0-\u024F]+)*)"#
        if let regex = try? NSRegularExpression(pattern: locationPattern, options: .caseInsensitive) {
            let nsText = workingText as NSString
            let nsRange = NSRange(location: 0, length: nsText.length)
            // Find all "di X" matches
            let matches = regex.matches(in: workingText, options: [], range: nsRange)
            
            // Exclude common words that follow "di" but are NOT locations
            let nonLocationWords = ["dalam", "atas", "bawah", "sini", "situ", "sana", "mana", "antara", "rumah"]
            
            for match in matches {
                if let captureRange = Range(match.range(at: 1), in: workingText) {
                    let captured = String(workingText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let firstWord = captured.lowercased().split(separator: " ").first.map(String.init) ?? captured.lowercased()
                    
                    if !nonLocationWords.contains(firstWord) && captured.count > 2 {
                        // Clean up: remove trailing time/note keywords from location
                        var cleanLocation = captured
                        let stopWords = ["jam", "pukul", "jangan", "catatan", "notes", "besok", "lusa"]
                        for stop in stopWords {
                            if let stopRange = cleanLocation.lowercased().range(of: stop) {
                                cleanLocation = String(cleanLocation[cleanLocation.startIndex..<stopRange.lowerBound])
                            }
                        }
                        cleanLocation = cleanLocation.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
                        
                        if !cleanLocation.isEmpty {
                            // Capitalize each word for proper location name
                            location = cleanLocation.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }.joined(separator: " ")
                        }
                        break
                    }
                }
            }
        }
        
        // =============================================
        // STEP 4: Extract Notes
        // =============================================
        // Pattern 1: "jangan lupa ...", "don't forget ..."
        let notesTriggers = [
            "jangan lupa", "jgn lupa", "ingat untuk",
            "don't forget", "dont forget", "remember to"
        ]
        for trigger in notesTriggers {
            if let range = lowText.range(of: trigger) {
                let startIdx = workingText.index(workingText.startIndex, offsetBy: lowText.distance(from: lowText.startIndex, to: range.lowerBound))
                let afterTriggerIdx = workingText.index(workingText.startIndex, offsetBy: lowText.distance(from: lowText.startIndex, to: range.upperBound))
                let afterText = String(workingText[afterTriggerIdx...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !afterText.isEmpty {
                    notes = afterText
                    workingText = String(workingText[workingText.startIndex..<startIdx]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                break
            }
        }
        
        // Pattern 2: Explicit separator keywords ("catatan", "notes", "keterangan")
        if notes.isEmpty {
            let noteSeparators = ["dengan catatan", "catatan", "keterangan", "notes", "note"]
            for separator in noteSeparators {
                if let range = workingText.lowercased().range(of: separator) {
                    let startIdx = workingText.index(workingText.startIndex, offsetBy: workingText.lowercased().distance(from: workingText.lowercased().startIndex, to: range.lowerBound))
                    let endIdx = workingText.index(workingText.startIndex, offsetBy: workingText.lowercased().distance(from: workingText.lowercased().startIndex, to: range.upperBound))
                    let afterSeparator = String(workingText[endIdx...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !afterSeparator.isEmpty {
                        notes = afterSeparator
                        workingText = String(workingText[workingText.startIndex..<startIdx]).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    break
                }
            }
        }
        
        // Pattern 3: Comma-separated fallback (first part = title context, after comma = notes)
        if notes.isEmpty && workingText.contains(",") {
            let parts = workingText.split(separator: ",", maxSplits: 1)
            if parts.count == 2 {
                let potentialNotes = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if potentialNotes.count > 3 {
                    workingText = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                    notes = potentialNotes
                }
            }
        }
        
        title = workingText
        
        // =============================================
        // STEP 5: Clean Title
        // =============================================
        // Remove command prefixes
        let prefixes = [
            "create task", "add task", "remind me to", "remind me",
            "tambah tugas", "buat tugas", "ingatkan saya untuk", "ingatkan saya", "ingatkan",
            "besok saya ada", "besok ada", "besok saya punya",
            "saya ada", "saya punya", "ada",
            "タスクを作成", "リマインド",
            "nova tarea", "nova tarefa"
        ]
        
        let lowerTitle = title.lowercased()
        for prefix in prefixes {
            if lowerTitle.hasPrefix(prefix) {
                title = String(title.dropFirst(prefix.count))
                break
            }
        }
        
        // Remove date/time phrases from title
        let cleanPatterns = [
            #"\s*(\d+)\s*menit\s*lagi"#,
            #"\s*(\d+)\s*jam\s*lagi"#,
            #"\s*setengah\s*jam\s*lagi"#,
            #"\s*in\s+\d+\s*minutes?"#,
            #"\s*in\s+\d+\s*hours?"#,
            #"\s*in\s+half\s+an?\s*hour"#,
            #"\s*besok"#,
            #"\s*lusa"#,
            #"\s*jam\s*\d{1,2}[.:]+\d{2}\s*(?:pagi|siang|sore|malam)?"#,
            #"\s*jam\s*\d{1,2}\s*(?:pagi|siang|sore|malam)"#,
            #"\s*pukul\s*\d{1,2}[.:]?\d{0,2}"#,
            #"\s*at\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?"#
        ]
        for pattern in cleanPatterns {
            title = title.replacingOccurrences(of: pattern, with: "", options: .regularExpression, range: title.startIndex..<title.endIndex)
        }
        
        // Remove "di [location]" from title if we extracted a location
        if !location.isEmpty {
            let diPattern = #"\s*di\s+"# + NSRegularExpression.escapedPattern(for: location)
            title = title.replacingOccurrences(of: diPattern, with: "", options: [.regularExpression, .caseInsensitive])
            // Also remove from notes if it leaked there
            notes = notes.replacingOccurrences(of: diPattern, with: "", options: [.regularExpression, .caseInsensitive]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Remove trailing "pagi", "siang", "sore", "malam" if they ended up in the title
        let trailingTimeOfDay = #"\s+(pagi|siang|sore|malam)$"#
        title = title.replacingOccurrences(of: trailingTimeOfDay, with: "", options: .regularExpression)
        
        title = title.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        
        // Capitalize first letter of title
        if let first = title.first {
            title = first.uppercased() + title.dropFirst()
        }
        
        // Capitalize first letter of notes  
        if let first = notes.first {
            notes = first.uppercased() + notes.dropFirst()
        }
        
        parsedTitle = title
        parsedNotes = notes
        parsedLocation = location
        parsedDate = date
        parsedPriority = priority
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showResult = true
        }
    }
    
    // MARK: - Relative Time Parsing
    
    private func parseRelativeTime(from text: String) -> Date? {
        let now = Date()
        
        // "setengah jam lagi" / "half an hour"
        if text.contains("setengah jam lagi") || text.contains("half an hour") || text.contains("half hour") {
            return Calendar.current.date(byAdding: .minute, value: 30, to: now)
        }
        
        // "X menit lagi" (Indonesian: X minutes from now)
        let menitPattern = #"(\d+)\s*menit\s*lagi"#
        if let match = text.range(of: menitPattern, options: .regularExpression) {
            let matchStr = String(text[match])
            if let numMatch = matchStr.range(of: #"\d+"#, options: .regularExpression) {
                if let minutes = Int(matchStr[numMatch]) {
                    return Calendar.current.date(byAdding: .minute, value: minutes, to: now)
                }
            }
        }
        
        // "X jam lagi" (Indonesian: X hours from now)
        let jamPattern = #"(\d+)\s*jam\s*lagi"#
        if let match = text.range(of: jamPattern, options: .regularExpression) {
            let matchStr = String(text[match])
            if let numMatch = matchStr.range(of: #"\d+"#, options: .regularExpression) {
                if let hours = Int(matchStr[numMatch]) {
                    return Calendar.current.date(byAdding: .hour, value: hours, to: now)
                }
            }
        }
        
        // "in X minutes" (English)
        let inMinPattern = #"in\s+(\d+)\s*minutes?"#
        if let match = text.range(of: inMinPattern, options: .regularExpression) {
            let matchStr = String(text[match])
            if let numMatch = matchStr.range(of: #"\d+"#, options: .regularExpression) {
                if let minutes = Int(matchStr[numMatch]) {
                    return Calendar.current.date(byAdding: .minute, value: minutes, to: now)
                }
            }
        }
        
        // "in X hours" (English)
        let inHrPattern = #"in\s+(\d+)\s*hours?"#
        if let match = text.range(of: inHrPattern, options: .regularExpression) {
            let matchStr = String(text[match])
            if let numMatch = matchStr.range(of: #"\d+"#, options: .regularExpression) {
                if let hours = Int(matchStr[numMatch]) {
                    return Calendar.current.date(byAdding: .hour, value: hours, to: now)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - NSDataDetector Date Detection
    
    private func detectDateWithNSDataDetector(from text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        
        // Return the first detected date
        return matches.first?.date
    }
    
    // MARK: - Manual Date Parsing
    
    private func parseManualDate(from text: String) -> Date? {
        let cal = Calendar.current
        let now = Date()
        
        // Indonesian + English keywords
        if text.contains("besok") || text.contains("tomorrow") {
            return cal.date(byAdding: .day, value: 1, to: now)
        }
        if text.contains("lusa") || text.contains("day after tomorrow") {
            return cal.date(byAdding: .day, value: 2, to: now)
        }
        if text.contains("minggu depan") || text.contains("next week") {
            return cal.date(byAdding: .weekOfYear, value: 1, to: now)
        }
        
        // CJK keywords
        if text.contains("明日") || text.contains("明天") {
            return cal.date(byAdding: .day, value: 1, to: now)
        }
        if text.contains("明後日") || text.contains("后天") {
            return cal.date(byAdding: .day, value: 2, to: now)
        }
        if text.contains("来週") || text.contains("下周") {
            return cal.date(byAdding: .weekOfYear, value: 1, to: now)
        }
        
        // Next [day of week]
        let dayMap: [(String, Int)] = [
            ("monday", 2), ("senin", 2),
            ("tuesday", 3), ("selasa", 3),
            ("wednesday", 4), ("rabu", 4),
            ("thursday", 5), ("kamis", 5),
            ("friday", 6), ("jumat", 6),
            ("saturday", 7), ("sabtu", 7),
            ("sunday", 1), ("minggu", 1)
        ]
        for (name, weekday) in dayMap {
            if text.contains("next \(name)") || text.contains("\(name) depan") {
                return nextWeekday(weekday, from: now)
            }
        }
        
        // "tanggal X" (Indonesian for "date X")
        if let match = text.range(of: #"tanggal (\d{1,2})"#, options: .regularExpression) {
            let numStr = text[match].replacingOccurrences(of: "tanggal ", with: "")
            if let day = Int(numStr) {
                var comps = cal.dateComponents([.year, .month], from: now)
                comps.day = day
                if let result = cal.date(from: comps), result > now {
                    return result
                } else {
                    comps.month = (comps.month ?? 1) + 1
                    return cal.date(from: comps)
                }
            }
        }
        // "XX日" (CJK for "Date XX")
        if let match = text.range(of: #"(\d{1,2})日"#, options: .regularExpression) {
            let timeStr = String(text[match])
            if let range = timeStr.range(of: #"\d+"#, options: .regularExpression), let day = Int(timeStr[range]) {
                var comps = cal.dateComponents([.year, .month], from: now)
                comps.day = day
                if let result = cal.date(from: comps), result > now {
                    return result
                } else {
                    comps.month = (comps.month ?? 1) + 1
                    return cal.date(from: comps)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Time Parsing
    
    private func parseTime(from text: String, baseDate: Date) -> Date {
        _ = Calendar.current
        
        // Match "at X:XX am/pm" or "at X am/pm"
        let enPattern = #"at (\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#
        if let match = text.range(of: enPattern, options: .regularExpression) {
            let timeStr = String(text[match])
            return extractTime(from: timeStr, pattern: enPattern, baseDate: baseDate) ?? baseDate
        }
        
        // Match "jam X:XX" or "jam X.XX" or "jam X pagi/siang/sore/malam"
        let idPattern = #"jam (\d{1,2})(?:[.:](\d{2}))?(?:\s*(pagi|siang|sore|malam))?"#
        if let match = text.range(of: idPattern, options: .regularExpression) {
            let timeStr = String(text[match])
            return extractIndonesianTime(from: timeStr, baseDate: baseDate) ?? baseDate
        }
        
        // Match "pukul X:XX"
        let pukulPattern = #"pukul (\d{1,2})(?:[.:](\d{2}))?"#
        if let match = text.range(of: pukulPattern, options: .regularExpression) {
            let timeStr = String(text[match])
            return extractIndonesianTime(from: timeStr, baseDate: baseDate) ?? baseDate
        }
        
        // Match Japanese/Chinese Time: "X時" (Hour), "X時Y分" (Hour Minute), "午後X時" (PM Hour)
        // Pattern: (Optional: Gozen/Gogo/Shangwu/Xiawu) + Number + Ji/Dian + (Optional: Number + Fun/Fen)
        let cjkPattern = #"(午前|午後|上午|下午)?\s*(\d{1,2})\s*(?:時|点|點)(?:\s*(\d{1,2})\s*(?:分))?"#
        if let match = text.range(of: cjkPattern, options: .regularExpression) {
            let timeStr = String(text[match])
            return extractCJKTime(from: timeStr, pattern: cjkPattern, baseDate: baseDate) ?? baseDate
        }
        
        // Match standalone "X pm" or "X am"
        let simplePattern = #"(\d{1,2})\s*(am|pm)"#
        if let match = text.range(of: simplePattern, options: .regularExpression) {
            let timeStr = String(text[match])
            return extractTime(from: timeStr, pattern: simplePattern, baseDate: baseDate) ?? baseDate
        }
        
        return baseDate
    }
    
    private func extractTime(from text: String, pattern: String, baseDate: Date) -> Date? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let nsrange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: nsrange) else { return nil }
        
        let hourRange = Range(match.range(at: 1), in: text)
        guard let hourStr = hourRange.map({ String(text[$0]) }), var hour = Int(hourStr) else { return nil }
        
        var minute = 0
        if match.range(at: 2).location != NSNotFound, let minRange = Range(match.range(at: 2), in: text) {
            minute = Int(text[minRange]) ?? 0
        }
        
        // AM/PM check
        // Check standard capture group index for AM/PM if pattern supports it
        // The pattern passed might vary, but usually AM/PM is the last group if present
        if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound, let ampmRange = Range(match.range(at: 3), in: text) {
            let ampm = text[ampmRange].lowercased()
            if ampm == "pm" && hour < 12 { hour += 12 }
            if ampm == "am" && hour == 12 { hour = 0 }
        }
        
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps)
    }
    
    private func extractIndonesianTime(from text: String, baseDate: Date) -> Date? {
        // Simple extraction for "jam 5 sore" or "jam 14.30"
        // Try to find digits
        let digitsPattern = #"(\d{1,2})(?:[.:](\d{2}))?"#
        guard let regex = try? NSRegularExpression(pattern: digitsPattern) else { return nil }
        let nsrange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: nsrange) else { return nil }
        
        let hourRange = Range(match.range(at: 1), in: text)
        guard let hourStr = hourRange.map({ String(text[$0]) }), var hour = Int(hourStr) else { return nil }
        
        var minute = 0
        if match.range(at: 2).location != NSNotFound, let minRange = Range(match.range(at: 2), in: text) {
            minute = Int(text[minRange]) ?? 0
        }
        
        // Check for PM keywords
        let lowerText = text.lowercased()
        if (lowerText.contains("sore") || lowerText.contains("malam") || lowerText.contains("siang")) && hour < 12 {
            // Special case for "siang": 11 siang is 11, 12 siang is 12, 1 siang is 13.
            if lowerText.contains("siang") && hour == 12 {
                // leave as 12
            } else if lowerText.contains("siang") && hour < 11 {
                // assume afternoon if it's like "2 siang" -> 14
                 hour += 12
            } else {
                 hour += 12 // sore/malam always PM
            }
        }
        
        // Check for AM keywords
        if lowerText.contains("pagi") && hour == 12 {
            hour = 0
        }
        
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps)
    }
    
    private func extractCJKTime(from text: String, pattern: String, baseDate: Date) -> Date? {
        // Group 1: Modifier (Optional) - Gozen/Gogo/Shangwu/Xiawu
        // Group 2: Hour
        // Group 3: Minute (Optional)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsrange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: nsrange) else { return nil }
        
        var isPM = false
        var isAM = false
        
        if match.range(at: 1).location != NSNotFound, let modRange = Range(match.range(at: 1), in: text) {
            let modifier = String(text[modRange])
            if ["午後", "下午"].contains(modifier) { isPM = true }
            if ["午前", "上午"].contains(modifier) { isAM = true }
        }
        
        let hourRange = Range(match.range(at: 2), in: text)
        guard let hourStr = hourRange.map({ String(text[$0]) }), var hour = Int(hourStr) else { return nil }
        
        var minute = 0
        if match.range(at: 3).location != NSNotFound, let minRange = Range(match.range(at: 3), in: text) {
            minute = Int(text[minRange]) ?? 0
        }
        
        if isPM && hour < 12 { hour += 12 }
        if isAM && hour == 12 { hour = 0 }
        
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps)
    }
    
    // MARK: - Helpers
    
    private func nextWeekday(_ weekday: Int, from date: Date) -> Date {
        let cal = Calendar.current
        let current = cal.component(.weekday, from: date)
        var daysToAdd = weekday - current
        if daysToAdd <= 0 { daysToAdd += 7 }
        return cal.date(byAdding: .day, value: daysToAdd, to: date) ?? date
    }
    
    private func removePatterns(from title: String, patterns: [String]) -> String {
        var result = title
        for pattern in patterns {
            result = result.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func resetState() {
        showResult = false
        parsedTitle = ""
        parsedNotes = ""
        parsedLocation = ""
        parsedDate = nil
        parsedPriority = "Medium"
        speechManager.recognizedText = ""
    }
    
    // MARK: - Create Task
    
    private func createTask() {
        guard !parsedTitle.isEmpty else { return }
        
        let taskDate = parsedDate ?? Date()
        let newItem = TodoItem(
            title: parsedTitle,
            notes: parsedNotes,
            timestamp: taskDate,
            priority: parsedPriority,
            hasReminder: true,
            location: parsedLocation.isEmpty ? nil : parsedLocation
        )
        modelContext.insert(newItem)
        
        // Schedule full notification set (before + at time + after)
        NotificationManager.shared.scheduleTaskNotifications(
            taskId: newItem.id.uuidString,
            title: parsedTitle,
            dueDate: taskDate
        )
        
        dismiss()
    }
}

#Preview {
    VoiceCommandView()
}

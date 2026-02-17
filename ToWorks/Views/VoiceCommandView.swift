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
                // Immediate analysis
                analyzeCommand()
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
        
        // Normalize: Convert Kanji/Hanzi/Full-width numbers to ASCII digits
        var workingText = normalizeVoiceInput(raw)
        
        var title = ""
        var notes = ""
        var location = ""
        var date = Date()
        var priority = "Medium"
        
        let lowText = workingText.lowercased()
        
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
        // =============================================
        // STEP 3: Extract Location
        // =============================================
        // Authentic Rules for each language group
        
        // 1. Prefix-based (Indonesian, English, Spanish, French, German, etc.)
        // Patterns: "di [Place]", "at [Place]", "in [Place]", "en [Place]", "à [Place]", "dans [Place]", "bei [Place]"
        let prefixLocationPattern = #"(?i)\b(?:di|at|in|en|à|dans|bei|ke)\s+([A-Za-z\u00C0-\u024F\u4e00-\u9fa5]+(?:\s+[A-Za-z\u00C0-\u024F\u4e00-\u9fa5]+)*)"#
        
        if let regex = try? NSRegularExpression(pattern: prefixLocationPattern, options: .caseInsensitive) {
            let nsText = workingText as NSString
            let matches = regex.matches(in: workingText, options: [], range: NSRange(location: 0, length: nsText.length))
            
            let nonLocationWords = ["swapping", "sini", "situ", "sana", "mana", "that", "this", "what", "which", "sin", "para", "pour", "avec", "mit", "rumah", "home", "besok", "lusa", "pagi", "siang", "sore", "malam", "the"]
            
            for match in matches {
                if let captureRange = Range(match.range(at: 1), in: workingText) {
                    var captured = String(workingText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Stop word cleanup
                    let stopWords = [" jam", " pukul", " besok", " lusa", " today", " tomorrow", " next", " at ", " in ", " on "]
                    for stop in stopWords {
                        if let range = captured.lowercased().range(of: stop) {
                            captured = String(captured[captured.startIndex..<range.lowerBound])
                        }
                    }
                    
                    let firstWord = captured.lowercased().split(separator: " ").first.map(String.init) ?? ""
                    
                    if !nonLocationWords.contains(firstWord) && captured.count > 2 {
                        location = captured.capitalized
                        break
                    }
                }
            }
        }
        
        // 2. Suffix-based (Japanese, Korean)
        // Patterns: "[Place]で", "[Place]に", "[Place]에서", "[Place]에"
        // Allow spaces before particle just in case: "[Place] で"
        if location.isEmpty {
            let suffixLocationPattern = #"([^\s\d\p{P}]+)\s*(?:で|に|에서|에)(?!\w)"#
             if let jpRegex = try? NSRegularExpression(pattern: suffixLocationPattern, options: []) {
                let nsText = workingText as NSString
                let matches = jpRegex.matches(in: workingText, options: [], range: NSRange(location: 0, length: nsText.length))
                
                for match in matches {
                    if let captureRange = Range(match.range(at: 1), in: workingText) {
                        let captured = String(workingText[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Sanity check: ensure it's not a common grammatical particle or time word acting up
                        let invalidSuffixes = ["明日", "昨日", "今日", "何", "誰", "私", "僕", "俺", "내일", "오늘", "지금"]
                        if !invalidSuffixes.contains(captured) && captured.count > 1 {
                            location = captured
                            break
                        }
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
            "aku mau", "aku ingin", "tolong", "tolong buatkan", "tolong ingatkan", "tolong catat",
            "saya mau", "saya ingin",
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
            // Unified Clean Patterns
            #"\s*(\d+)\s*menit\s*lagi"#,
            #"\s*(\d+)\s*jam\s*lagi"#,
            #"\s*setengah\s*jam\s*lagi"#,
            #"\s*in\s+\d+\s*minutes?"#,
            #"\s*in\s+\d+\s*hours?"#,
            // Global Date Keywords
            #"(?i)\s*\b(besok|tomorrow|내일|mañana|demain|morgen|amanhã|غدا|कल|พรุ่งนี้|ngày mai|esok|domani|завтра|yarın|明日|明天)\b"#,
            #"(?i)\s*\b(lusa|day after tomorrow|모레|pasado mañana|après-demain|übermorgen|depois de amanhã|dopodomani|послезавтра|öbür gün|明後日|后天)\b"#,
            // Global Time Patterns
            #"(?i)(?:at|jam|pukul|à|um|as|alle|в|saat|lúc)\s+(\d{1,2})(?:\s*[.:]\s*(\d{2}))?(?:\s*(am|pm|pagi|siang|sore|malam|du matin|de l'après-midi|domani|manhã|tarde|sabah|akşam|sáng|chiều))?"#,
            #"(?i)(\d{1,2})(?:\s*[.:]\s*(\d{2}))?\s*(am|pm|h|heures|uhr|horas|baje|โมง|giờ|시|点|點|時)"#,
            // CJK Clean patterns (Simplified to avoid complexity issues)
            #"\s*明日"#, #"\s*明天"#, #"\s*明後日"#, #"\s*后天"#, #"\s*来週"#, #"\s*下周"#,
            // Match time pattern with optional prefix/suffix but simplified groups
            #"(?:午前|午後|朝|夜|深夜|夕方|上午|下午|早上|晚上|中午|凌晨|오전|오후|아침|저녁|밤|새벽)?\s*\d{1,2}\s*(?:時|点|點|시)(?:\s*\d{1,2}\s*(?:分|분))?(?:에|に|へ|から|まで|부터)?"#
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
        
        // Remove trailing "pagi", "siang", "sore", "malam" if they ended up in the title (Global)
        let trailingTimeOfDay = #"(?i)\s+(pagi|siang|sore|malam|du matin|de l'après-midi|domani|as|alle|manhã|tarde|sabah|akşam|sáng|chiều)$"#
        title = title.replacingOccurrences(of: trailingTimeOfDay, with: "", options: .regularExpression)
        
        title = title.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        
        // FAILSAFE: If title is empty after cleaning (e.g. user just said "Tomorrow at 9"), fall back to original text
        if title.isEmpty {
            title = workingText.isEmpty ? raw : workingText
        }
        
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
    
    // MARK: - Voice Normalization
    
    // MARK: - Voice Normalization
    
    private func normalizeVoiceInput(_ text: String) -> String {
        var processed = text
        
        // 1. Full-width to Half-width numbers ((０-９) -> (0-9))
        let fullWidth = ["０","１","２","３","４","５","６","７","７","８","９"]
        for (i, char) in fullWidth.enumerated() {
            processed = processed.replacingOccurrences(of: char, with: "\(i)")
        }
        
        // 2. Normalize Time Separators: Replace . , 。 ． ： with :
        // This fixes "11.15" -> "11:15" ensuring generic regex catches it
        let separators = [".", ",", "。", "．", "：", " "]
        // Only replace if surrounded by digits to avoid breaking text
        // Actually, safer to just replace specific time-like patterns using regex
        // Pattern: (\d{1,2})[.,。．：](\d{2}) -> $1:$2
        let timeSepPattern = #"(\d{1,2})[.,。．：\s](\d{2})\b"#
        if let regex = try? NSRegularExpression(pattern: timeSepPattern, options: []) {
            let range = NSRange(processed.startIndex..., in: processed)
            processed = regex.stringByReplacingMatches(in: processed, options: [], range: range, withTemplate: "$1:$2")
        }
        
        // 3. Kanji/Hanzi Numerals (Simple 1-10, 20, 30...)
        let kanjiMap: [(String, String)] = [
            ("一", "1"), ("二", "2"), ("三", "3"), ("四", "4"), ("五", "5"),
            ("六", "6"), ("七", "7"), ("八", "8"), ("九", "9"), ("十", "10"),
            ("十一", "11"), ("十二", "12"), ("二十", "20"), ("三十", "30")
        ]
        
        for (kanji, digit) in kanjiMap {
            processed = processed.replacingOccurrences(of: kanji, with: digit)
        }
        
        return processed
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
        
        let tomorrowPattern = #"(?i)\b(besok|tomorrow|내일|mañana|demain|morgen|amanhã|غدا|कल|พรุ่งนี้|ngày mai|esok|domani|завтра|yarın|明日|明天)\b"#
        if text.range(of: tomorrowPattern, options: .regularExpression) != nil {
            return cal.date(byAdding: .day, value: 1, to: now)
        }
        
        let dayAfterPattern = #"(?i)\b(lusa|day after tomorrow|모레|pasado mañana|après-demain|übermorgen|depois de amanhã|dopodomani|послезавтра|öbür gün|明後日|后天)\b"#
        if text.range(of: dayAfterPattern, options: .regularExpression) != nil {
            return cal.date(byAdding: .day, value: 2, to: now)
        }
        
        let nextWeekPattern = #"(?i)\b(minggu depan|next week|다음 주|la próxima semana|la semaine prochaine|nächste woche|próxima semana|الأسبوع القادم|अगले सप्ताह|อาทิตย์หน้า|tuần tới|minggu depan|prossima settimana|следующая неделя|gelecek hafta|来週|下周)\b"#
        if text.range(of: nextWeekPattern, options: .regularExpression) != nil {
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
        
        // Unified Prefix Pattern: "at 5", "jam 5", "pukul 5", "à 5", "um 5", "saat 5"
        // Allow robust separator matching: "11.15", "11 . 15", "11:15"
        let prefixPattern = #"(?i)(?:at|jam|pukul|à|um|as|alle|в|saat|lúc)\s+(\d{1,2})(?:\s*[.:]\s*(\d{2}))?(?:\s*(am|pm|pagi|siang|sore|malam|du matin|de l'après-midi|domani|manhã|tarde|sabah|akşam|sáng|chiều))?"#
        if let match = text.range(of: prefixPattern, options: .regularExpression) {
            let timeStr = String(text[match])
            return extractGlobalTime(from: timeStr, pattern: prefixPattern, baseDate: baseDate)
        }
        
        // Unified Suffix Pattern: "5 pm", "5 h", "5 o'clock", "5 giờ", "5시", "5点"
        let suffixPattern = #"(?i)(\d{1,2})(?:\s*[.:]\s*(\d{2}))?\s*(am|pm|h|heures|uhr|horas|baje|โมง|giờ|시|点|點|時)"#
        if let match = text.range(of: suffixPattern, options: .regularExpression) {
            let timeStr = String(text[match])
            return extractGlobalTimeSuffix(from: timeStr, pattern: suffixPattern, baseDate: baseDate) // Suffix logic works for bare numbers too (0 suffix)
        }
        
        // CJK / Korean Contextual Time
        let cjkPattern = #"(?:午前|午後|朝|夜|深夜|夕方|上午|下午|早上|晚上|中午|凌晨|오전|오후|아침|저녁|밤|새벽)?\s*(\d{1,2})\s*(?:時|点|點|시)(?:\s*(\d{1,2})\s*(?:分|분))?(?:에|に|へ|から|まで|부터)?"#
        if let match = text.range(of: cjkPattern, options: .regularExpression) {
            let timeStr = String(text[match])
            return extractCJKTime(from: timeStr, pattern: cjkPattern, baseDate: baseDate) ?? baseDate
        }

        // Generic Fallback: "11:15", "11.15" (Standalone)
        // Only if it looks strictly like time (at start of line or space before)
        // \b(\d{1,2})[.:](\d{2})\b
        let genericPattern = #"\b(\d{1,2})[.:](\d{2})\b"#
        if let match = text.range(of: genericPattern, options: .regularExpression) {
            let timeStr = String(text[match])
            return extractGlobalTimeSuffix(from: timeStr, pattern: genericPattern, baseDate: baseDate) // Suffix logic works for bare numbers too (0 suffix)
        }

        return baseDate
    }
    
    private func extractGlobalTime(from text: String, pattern: String, baseDate: Date) -> Date {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return baseDate }
        let nsrange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: nsrange) else { return baseDate }
        
        let hourRange = Range(match.range(at: 1), in: text)
        guard let hourStr = hourRange.map({ String(text[$0]) }), var hour = Int(hourStr) else { return baseDate }
        
        var minute = 0
        if match.range(at: 2).location != NSNotFound, let minRange = Range(match.range(at: 2), in: text) {
            // Remove whitespace from minute string logic if needed, but Int() usually handles clean digits from captured group
            // Wait, if regex captures "15" into group 2, it is clean.
            minute = Int(text[minRange]) ?? 0
        }
        
        // AM/PM/Keywords check
        if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound, let kwRange = Range(match.range(at: 3), in: text) {
            let kw = text[kwRange].lowercased()
            
            // 1. Explicit PM (12 PM -> 12, 1 PM -> 13)
            if ["pm", "sore", "de l'après-midi", "tarde", "akşam", "chiều"].contains(where: { kw.contains($0) }) {
                if hour < 12 { hour += 12 }
            }
            // 2. "Malam" (Night) logic
            else if kw.contains("malam") || kw.contains("night") {
                if hour == 12 { hour = 0 } // 12 Malam -> 00:00 (Midnight)
                else if hour < 12 { hour += 12 } // 9 Malam -> 21:00
            }
            // 3. "Siang" (Day/Noon) logic (11:00 - 14:00)
            else if kw.contains("siang") {
                // 12 Siang -> 12:00
                // 1 Siang -> 13:00
                // 2 Siang -> 14:00
                // 11 Siang -> 11:00
                if hour < 11 { hour += 12 } // 1, 2, 3... -> 13, 14, 15...
            }
            // 4. Explicit AM (12 AM -> 0)
            else if ["am", "pagi", "du matin", "manhã", "sabah", "sáng"].contains(where: { kw.contains($0) }) {
                if hour == 12 { hour = 0 }
            }
        }
        
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? baseDate
    }
    
    private func extractGlobalTimeSuffix(from text: String, pattern: String, baseDate: Date) -> Date {
         guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return baseDate }
        let nsrange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: nsrange) else { return baseDate }
        
        let hourRange = Range(match.range(at: 1), in: text)
        guard let hourStr = hourRange.map({ String(text[$0]) }), var hour = Int(hourStr) else { return baseDate }
        
        var minute = 0
        if match.range(at: 2).location != NSNotFound, let minRange = Range(match.range(at: 2), in: text) {
            minute = Int(text[minRange]) ?? 0
        }
        
        if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound, let kwRange = Range(match.range(at: 3), in: text) {
             let kw = text[kwRange].lowercased()
             if ["pm", "tarde", "akşam", "chiều"].contains(where: { kw.contains($0) }) {
                  if hour < 12 { hour += 12 }
             }
             if ["am", "manhã", "sabah", "sáng"].contains(where: { kw.contains($0) }) {
                  if hour == 12 { hour = 0 }
             }
        }
        
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? baseDate
    }
    
    // Legacy functions replaced by universal ones, keeping CJK
    
    private func extractCJKTime(from text: String, pattern: String, baseDate: Date) -> Date? {
        // Group 1: Modifier (Optional)
        // Group 2: Hour
        // Group 3: Minute (Optional)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsrange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: nsrange) else { return nil }
        
        var isPM = false
        var isAM = false
        
        if match.range(at: 1).location != NSNotFound, let modRange = Range(match.range(at: 1), in: text) {
            let modifier = String(text[modRange])
            
            // PM Keywords
            if ["午後", "下午", "오후", "夜", "夕方", "晚上", "中午", "저녁", "밤"].contains(modifier) {
                isPM = true
            }
            // AM Keywords (Explicit)
            if ["午前", "上午", "오전", "朝", "早上", "凌晨", "아침", "새벽"].contains(modifier) {
                isAM = true
            }
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

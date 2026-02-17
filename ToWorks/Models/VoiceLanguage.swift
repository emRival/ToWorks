//
//  VoiceLanguage.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import Foundation

struct VoiceLanguage: Identifiable, Hashable {
    let id: String       // locale identifier e.g. "id-ID"
    let flag: String
    let name: String
    
    // Localized UI Strings for Voice Command
    let listeningText: String
    let processingText: String
    let readyText: String
    let retryText: String
    let helpText: String
    
    // Factory methods for simpler initialization
    static func create(id: String, flag: String, name: String, listening: String, processing: String, ready: String, retry: String, help: String) -> VoiceLanguage {
        VoiceLanguage(id: id, flag: flag, name: name, listeningText: listening, processingText: processing, readyText: ready, retryText: retry, helpText: help)
    }
    
    static let auto   = VoiceLanguage.create(id: "Auto",  flag: "🌐", name: "Auto (Device)", listening: "Listening...", processing: "Thinking...", ready: "Task Ready", retry: "Try Again", help: "Say \"Meeting tomorrow at 3pm\"")
    static let idID   = VoiceLanguage.create(id: "id-ID", flag: "🇮🇩", name: "Indonesia", listening: "Mendengarkan...", processing: "Memproses...", ready: "Tugas Siap", retry: "Coba Lagi", help: "Katakan \"Rapat besok jam 3 sore\"")
    static let enUS   = VoiceLanguage.create(id: "en-US", flag: "🇺🇸", name: "English (US)", listening: "Listening...", processing: "Thinking...", ready: "Task Ready", retry: "Try Again", help: "Say \"Meeting tomorrow at 3pm\"")
    static let enGB   = VoiceLanguage.create(id: "en-GB", flag: "🇬🇧", name: "English (UK)", listening: "Listening...", processing: "Thinking...", ready: "Task Ready", retry: "Try Again", help: "Say \"Meeting tomorrow at 15:00\"")
    static let jaJP   = VoiceLanguage.create(id: "ja-JP", flag: "🇯🇵", name: "日本語", listening: "聞いています...", processing: "考え中...", ready: "タスク準備完了", retry: "もう一度", help: "「明日午後3時に会議」と言ってください")
    static let koKR   = VoiceLanguage.create(id: "ko-KR", flag: "🇰🇷", name: "한국어", listening: "듣고 있어요...", processing: "처리 중...", ready: "할 일 준비됨", retry: "다시 시도", help: "「내일 오후 3시 회의」라고 말해보세요")
    static let zhCN   = VoiceLanguage.create(id: "zh-CN", flag: "🇨🇳", name: "中文 (简体)", listening: "正在聆听...", processing: "正在思考...", ready: "任务就绪", retry: "重试", help: "说“明天下午3点开会”")
    static let zhTW   = VoiceLanguage.create(id: "zh-TW", flag: "🇹🇼", name: "中文 (繁體)", listening: "正在聆聽...", processing: "正在思考...", ready: "任務就緒", retry: "重試", help: "說「明天下午3點開會」")
    static let esES   = VoiceLanguage.create(id: "es-ES", flag: "🇪🇸", name: "Español", listening: "Escuchando...", processing: "Pensando...", ready: "Tarea lista", retry: "Reintentar", help: "Di \"Reunión mañana a las 3pm\"")
    static let frFR   = VoiceLanguage.create(id: "fr-FR", flag: "🇫🇷", name: "Français", listening: "Écoute...", processing: "Réflexion...", ready: "Tâche prête", retry: "Réessayer", help: "Dites \"Réunion demain à 15h\"")
    static let deDE   = VoiceLanguage.create(id: "de-DE", flag: "🇩🇪", name: "Deutsch", listening: "Zuhören...", processing: "Nachdenken...", ready: "Aufgabe bereit", retry: "Wiederholen", help: "Sag \"Meeting morgen um 15 Uhr\"")
    static let ptBR   = VoiceLanguage.create(id: "pt-BR", flag: "🇧🇷", name: "Português", listening: "Ouvindo...", processing: "Pensando...", ready: "Tarefa pronta", retry: "Tentar novamente", help: "Diga \"Reunião amanhã às 15h\"")
    static let arSA   = VoiceLanguage.create(id: "ar-SA", flag: "🇸🇦", name: "العربية", listening: "جاري الاستماع...", processing: "جاري المعالجة...", ready: "المهمة جاهزة", retry: "حاول مرة أخرى", help: "قل \"اجتماع غداً الساعة 3 عصراً\"")
    static let hiIN   = VoiceLanguage.create(id: "hi-IN", flag: "🇮🇳", name: "हिन्दी", listening: "सुन रहा हूँ...", processing: "सोच रहा हूँ...", ready: "कार्य तैयार", retry: "पुनः प्रयास करें", help: "कहें \"कल दोपहर 3 बजे बैठक\"")
    static let thTH   = VoiceLanguage.create(id: "th-TH", flag: "🇹🇭", name: "ไทย", listening: "กำลังฟัง...", processing: "กำลังประมวลผล...", ready: "งานพร้อมแล้ว", retry: "ลองอีกครั้ง", help: "พูดว่า \"ประชุมพรุ่งนี้ตอนบ่าย 3 โมง\"")
    static let viVN   = VoiceLanguage.create(id: "vi-VN", flag: "🇻🇳", name: "Tiếng Việt", listening: "Đang nghe...", processing: "Đang xử lý...", ready: "Nhiệm vụ sẵn sàng", retry: "Thử lại", help: "Nói \"Cuộc họp ngày mai lúc 3 giờ chiều\"")
    static let msMY   = VoiceLanguage.create(id: "ms-MY", flag: "🇲🇾", name: "Bahasa Melayu", listening: "Mendengar...", processing: "Memproses...", ready: "Tugas Sedia", retry: "Cuba Lagi", help: "Katakan \"Mesyuarat esok pukul 3 petang\"")
    static let itIT   = VoiceLanguage.create(id: "it-IT", flag: "🇮🇹", name: "Italiano", listening: "Ascolto...", processing: "Elaborazione...", ready: "Attività pronta", retry: "Riprova", help: "Dì \"Riunione domani alle 15\"")
    static let ruRU   = VoiceLanguage.create(id: "ru-RU", flag: "🇷🇺", name: "Русский", listening: "Слушаю...", processing: "Думаю...", ready: "Задача готова", retry: "Повторить", help: "Скажите \"Встреча завтра в 15:00\"")
    static let trTR   = VoiceLanguage.create(id: "tr-TR", flag: "🇹🇷", name: "Türkçe", listening: "Dinliyorum...", processing: "İşleniyor...", ready: "Görev Hazır", retry: "Tekrar Dene", help: "\"Yarın saat 15'te toplantı\" deyin")
    
    static let allLanguages: [VoiceLanguage] = [
        .auto, .idID, .enUS, .enGB, .jaJP, .koKR,
        .zhCN, .zhTW, .esES, .frFR, .deDE, .ptBR,
        .arSA, .hiIN, .thTH, .viVN, .msMY, .itIT,
        .ruRU, .trTR
    ]
    
    static func from(id: String) -> VoiceLanguage {
        allLanguages.first(where: { $0.id == id }) ?? .auto
    }
}

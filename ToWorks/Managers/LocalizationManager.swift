//
//  LocalizationManager.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @AppStorage("voiceLanguage") private var voiceLanguageID = "Auto"
    
    // Published property to trigger UI updates
    @Published var currentLanguage: String = "Auto"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe AppStorage changes
        // Hack: AppStorage doesn't easily publish to non-View observers, so we use a timer or manual check in standard implementations.
        // Or we can just rely on views observing this object if we update `currentLanguage` when accessed.
        
        // However, for Simplicity in SwiftUI, we can expose a function that views can call, or use a binding.
        // But to make it "reactive" globally, let's just use the `localized` function which will be reactive if called inside a View that observes an object ensuring updates.
        // Actually, the simplest way is to have Views observe this manager.
        
        currentLanguage = voiceLanguageID
    }
    
    func languageDidChange() {
        currentLanguage = voiceLanguageID
        objectWillChange.send()
    }
    
    // Dictionary: [LanguageCode: [Key: Value]]
    private let translations: [String: [String: String]] = [
        "id-ID": [
            "Home": "Beranda",
            "Calendar": "Kalender",
            "Stats": "Statistik",
            "Settings": "Pengaturan",
            "Voice": "Suara",
            "New Task": "Tugas Baru",
            
            // Dashboard
            "Welcome back": "Selamat Datang",
            "Upcoming Tasks": "Tugas Mendatang",
            "Total": "Total",
            "All caught up!": "Semua selesai!",
            "Enjoy your free time or add a new task to get started.": "Nikmati waktu luang atau tambah tugas baru.",
            "UP NEXT": "BERIKUTNYA",
            
            // Settings
            "PREFERENCES": "PREFERENSI",
            "Appearance": "Tampilan",
            "Notifications": "Notifikasi",
            "Task Defaults": "Default Tugas",
            "Data Management": "Manajemen Data",
            "About": "Tentang",
            "Enable Notifications": "Aktifkan Notifikasi",
            "Remind Before": "Ingatkan Sebelum",
            "Sound": "Suara",
            "Voice Language": "Bahasa Suara",
            "Theme": "Tema",
            "Accent Color": "Warna Aksen",
            "Default Category": "Kategori Default",
            "Default Priority": "Prioritas Default",
            "Tasks Summary": "Ringkasan Tugas",
            "Delete Completed Tasks": "Hapus Tugas Selesai",
            "Delete All Tasks": "Hapus Semua Tugas",
            "About ToWorks": "Tentang ToWorks",
            "Version, Author & Info": "Versi, Penulis & Info",
            
            // New Task
            "Create New Task": "Buat Tugas Baru",
            "CATEGORY": "KATEGORI",
            "What needs to be done?": "Apa yang perlu dilakukan?",
            "Location": "Lokasi",
            "Add address or place...": "Tambah alamat atau tempat...",
            "Due Date": "Tenggat Waktu",
            "Priority": "Prioritas",
            "Set Reminder": "Atur Pengingat",
            "ATTACHMENTS": "LAMPIRAN",
            "Image": "Gambar",
            "File": "Berkas",
            "NOTES": "CATATAN",
            "Create Task": "Buat Tugas",
            "Inbox": "Kotak Masuk",
            "Work": "Kerja",
            "Personal": "Pribadi",
            "Admin": "Admin",
            "Health": "Kesehatan",
            "Study": "Belajar",
            "Low": "Rendah",
            "Medium": "Sedang",
            "High": "Tinggi"
        ],
        "ja-JP": [
            "Home": "ホーム",
            "Calendar": "カレンダー",
            "Stats": "統計",
            "Settings": "設定",
            "Voice": "音声",
            "New Task": "新規タスク",
            
            "Welcome back": "お帰りなさい",
            "Upcoming Tasks": "今後のタスク",
            "Total": "合計",
            "All caught up!": "すべて完了！",
            "Enjoy your free time or add a new task to get started.": "自由な時間を楽しむか、新しいタスクを追加してください。",
            "UP NEXT": "次は",
            
            "PREFERENCES": "環境設定",
            "Appearance": "外観",
            "Notifications": "通知",
            "Task Defaults": "タスク既定値",
            "Data Management": "データ管理",
            "About": "アプリについて",
            "Enable Notifications": "通知を有効化",
            "Remind Before": "リマインダー",
            "Sound": "サウンド",
            "Voice Language": "音声言語",
            "Theme": "テーマ",
            "Accent Color": "アクセントカラー",
            "Default Category": "既定カテゴリ",
            "Default Priority": "既定優先度",
            "Tasks Summary": "タスク概要",
            "Delete Completed Tasks": "完了タスクを削除",
            "Delete All Tasks": "全タスクを削除",
            "About ToWorks": "ToWorksについて",
            "Version, Author & Info": "バージョン、作者、情報",
            
            "Create New Task": "新規タスク作成",
            "CATEGORY": "カテゴリ",
            "What needs to be done?": "今のタスクは？",
            "Location": "場所",
            "Add address or place...": "住所や場所を追加...",
            "Due Date": "期限",
            "Priority": "優先度",
            "Set Reminder": "リマインダー設定",
            "ATTACHMENTS": "添付",
            "Image": "画像",
            "File": "ファイル",
            "NOTES": "メモ",
            "Create Task": "タスク作成",
            "Inbox": "受信箱",
            "Work": "仕事",
            "Personal": "個人",
            "Admin": "管理",
            "Health": "健康",
            "Study": "勉強",
            "Low": "低",
            "Medium": "中",
            "High": "高"
        ],
        "en-US": [:] // Default fallbacks to key itself
    ]
    
    func localized(_ key: String) -> String {
        let targetLang = currentLanguage == "Auto" ? "en-US" : currentLanguage
        
        if let table = translations[targetLang], let value = table[key] {
            return value
        }
        return key
    }
}

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
            "See All": "Lihat Semua",
            "Good Morning,": "Selamat Pagi,",
            "Search for task...": "Cari tugas...",
            
            // Stats
            "PERFORMANCE": "PERFORMA",
            "Insights": "Wawasan",
            "Great Job!": "Kerja Bagus!",
            "Completion": "Penyelesaian",
            "Total Done": "Selesai",
            "Pending": "Tunda",
            "Weekly Activity": "Aktivitas Mingguan",
            "Attention Needed": "Perhatian Diperlukan",
            "You have %d overdue tasks.": "Anda memiliki %d tugas terlambat.",
            "You have completed %d%% of your tasks this %@.": "Anda telah menyelesaikan %1$d%% tugas Anda %2$@ ini.",
            // Periods
            "Week": "Minggu",
            "Month": "Bulan",
            "All": "Semua",
            "week": "minggu",
            "month": "bulan",
            "all": "semua",
            
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
            "About ToWorks": "Tentang ToWorks - Focus & To-Do List",
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
            "High": "Tinggi",
            
            // Task Detail
            "Task Details": "Detail Tugas",
            "TASK TITLE": "JUDUL TUGAS",
            "Enter title...": "Masukkan judul...",
            "Completed": "Selesai",
            "STATUS": "STATUS",
            "PRIORITY": "PRIORITAS",
            "Remind Me": "Ingatkan Saya",
            "Reminder Time": "Waktu Pengingat",
            "At time of event": "Saat acara",
            "Add Location": "Tambah Lokasi",
            "Delete Task": "Hapus Tugas",
            "Add Attachment": "Tambah Lampiran",
            "Add notes here...": "Tambah catatan di sini...",
            "Add desciption...": "Tambah deskripsi...",
            
            // New Task Specific
            "Details": "Rincian",
            "Photo": "Foto",
            
            // Dashboard Greetings
            "Good Afternoon,": "Selamat Siang,",
            "Good Evening,": "Selamat Malam,",
            
            // Onboarding
            "Welcome to ToWorks": "Selamat Datang di ToWorks - Focus & To-Do List",
            "Let's get productive. First, what should we call you?": "Mari produktif. Pertama, siapa nama Anda?",
            "YOUR NAME": "NAMA ANDA",
            "Enter your first name": "Masukkan nama depan Anda",
            "Get Started": "Mulai",
            
            // Notifications
            "History": "Riwayat",
            "No notifications yet": "Belum ada notifikasi",
            "Test System Notification": "Uji Notifikasi Sistem",
            "Clear All History": "Hapus Semua Riwayat",
            "Done": "Selesai",
            
            // Voice Command
            "VOICE COMMAND": "PERINTAH SUARA",
            "Listening...": "Mendengarkan...",
            "Parsed Task": "Tugas Terurai",
            "Tap the mic to start": "Ketuk mikrofon untuk mulai"
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
            "See All": "すべて見る",
            "Good Morning,": "おはようございます、",
            "Search for task...": "タスクを検索...",
            
            "PERFORMANCE": "パフォーマンス",
            "Insights": "インサイト",
            "Great Job!": "よくできました！",
            "Completion": "完了率",
            "Total Done": "完了",
            "Pending": "保留",
            "Weekly Activity": "週間アクティビティ",
            "Attention Needed": "要注意",
            "You have %d overdue tasks.": "%d 件の期限切れタスクがあります。",
            "You have completed %d%% of your tasks this %@.": "今%2$@のタスクの%1$d%%を完了しました。",
            "Week": "週",
            "Month": "月",
            "All": "全期間",
            "week": "週",
            "month": "月",
            "all": "期間",
            
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
            "About ToWorks": "ToWorks - Focus & To-Do Listについて",
            "Version, Author & Info": "バージョン、作者、情報",
            
            "Create New Task": "新規タスク作成",
            "CATEGORY": "カテゴリ",
            "What needs to be done?": "今のタスクは？",
            "Location": "場所",
            "Add address or place...": "住所を追加...",
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
            "High": "高",
            
             // Task Detail
            "Task Details": "タスク詳細",
            "TASK TITLE": "タスク名",
            "Enter title...": "タイトルを入力...",
            "Completed": "完了",
            "STATUS": "ステータス",
            "Remind Me": "リマインダー",
            "Reminder Time": "通知時間",
            "At time of event": "イベント時",
            "Add Location": "場所を追加",
            "Delete Task": "タスクを削除",
            "Add Attachment": "添付を追加",
            "Add notes here...": "メモを追加...",
             "Add desciption...": "説明を追加...",
            
            // New Task Specific
            "Details": "詳細",
            "Photo": "写真",
            "PRIORITY": "優先度",
            
            // Dashboard Greetings
            "Good Afternoon,": "こんにちは、",
            "Good Evening,": "こんばんは、",
            
            // Onboarding
            "Welcome to ToWorks": "ToWorks - Focus & To-Do Listへようこそ",
            "Let's get productive. First, what should we call you?": "生産的になりましょう。まず、お名前は？",
            "YOUR NAME": "お名前",
            "Enter your first name": "名前を入力",
            "Get Started": "始める",
            
            // Notifications
            "History": "履歴",
            "No notifications yet": "通知はまだありません",
            "Test System Notification": "テスト通知を送信",
            "Clear All History": "履歴をすべて削除",
            "Done": "完了",
            
            // Voice Command
            "VOICE COMMAND": "音声コマンド",
            "Listening...": "聞いています...",
            "Parsed Task": "解析済みタスク",
            "Tap the mic to start": "マイクをタップして開始"
        ],
        "en-US": [
            "About ToWorks": "About ToWorks - Focus & To-Do List",
            "Welcome to ToWorks": "Welcome to ToWorks - Focus & To-Do List"
        ]
    ]
    
    func localized(_ key: String) -> String {
        let targetLang = currentLanguage == "Auto" ? "en-US" : currentLanguage
        
        if let table = translations[targetLang], let value = table[key] {
            return value
        }
        return key
    }
    
    func localizedWithFormat(_ key: String, _ args: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, arguments: args)
    }
}

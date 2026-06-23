<div align="center">

# 🎓 CampusQuest Academy

**A bright, gamified iOS word game that turns academic terminology into a daily learning habit.**

![Platform](https://img.shields.io/badge/platform-iOS%2017.5%2B-blue)
![Swift](https://img.shields.io/badge/Swift-SwiftUI%20%2B%20SwiftData-orange)
![Version](https://img.shields.io/badge/version-1.0-brightgreen)

**Choose your language · Dilini seç**

</div>

<details>
<summary><b>🇺🇸 Read in English</b></summary>

<br>

### Overview

CampusQuest Academy is an educational word game for iOS. Players pick a **major** — Computer Engineering or Medicine — then uncover its terms on a letter wheel, learn their definitions, earn XP, climb academic ranks (Freshman → Senior), unlock achievements, and keep a daily streak going. It's built entirely with **SwiftUI**, **SwiftData**, and **SpriteKit** — no backend, no accounts required.

### ✨ Features

- **Multiple majors** — Choose a major (Computer Engineering or Medicine) on first launch and switch any time; each major has its own levels and terminology.
- **Word puzzles** — Spin the letter wheel to spell out terms; each solved word reveals its definition.
- **Quiz mode** — Multiple-choice questions across the major's topics (e.g. Programming, Data Structures, Networks, Databases, Cybersecurity).
- **Daily Challenge** — A deterministic, date-seeded word set with bonus XP, refreshed every day.
- **Streak system** — A flame counter rewards you for playing on consecutive days.
- **Ranks & XP** — Progress through academic levels with a live XP bar and rank-up milestones.
- **Achievements** — Earn tiered badges (Bronze, Silver, Gold) for milestones.
- **Campus ID card** — A personal student-ID card with your name, major, rank, and stats.
- **Avatars** — Pick a photo from your library or choose one of 12 app-themed generated avatars.
- **Appearance** — Light, Dark, or follow the System setting, switchable any time from Settings (full dark-mode support across every screen).
- **Guided tutorial** — A first-launch welcome tour plus an in-level "how to play" coachmark walkthrough; replayable any time from Settings.
- **Local notifications** — An optional daily reminder at 7:00 PM to keep your streak.
- **5 languages** — Fully localized UI (100% coverage): English 🇺🇸, Turkish 🇹🇷, German 🇩🇪, French 🇫🇷, Spanish 🇪🇸 (UI only; the technical dictionary stays in English).
- **Sign in with Apple** or **Continue as Guest** — Guest mode is fully private: nothing is stored off-device and no statistics are collected.
- **Share** — Share a "Course Completed" card with your rank, terms learned, and XP earned.

### 🛠 Tech Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI (iOS 17.5+) |
| Persistence | SwiftData (`@Model`, lightweight migration) |
| Animations / scene | SpriteKit |
| Auth | Sign in with Apple (`AuthenticationServices`) |
| Content | Bundled JSON (`ComputerEngineering.json`, `Medicine.json`) |
| Localization | String Catalog (`Localizable.xcstrings`) |
| Notifications | `UNUserNotificationCenter` (local only) |

### 🚀 Getting Started

**Requirements:** Xcode 26+, iOS 17.5+ device or simulator.

```bash
git clone https://github.com/Aosll/CampusQuest.git
cd CampusQuest
open CampusQuest.xcodeproj
```

Then select the **CampusQuest** scheme and press **⌘R** to build and run.

> The build number is set automatically from the git commit count on every build, so no manual versioning is needed.

### 📁 Project Structure

```
CampusQuest/
├── CampusQuestApp.swift      # App entry point, environment wiring
├── AuthManager.swift         # Sign in with Apple / guest state
├── PlayerProgress.swift      # SwiftData model: XP, streak, levels
├── RankSystem.swift          # Academic ranks & XP thresholds
├── LetterWheelView.swift     # Core word-puzzle interaction
├── LevelView.swift           # Gameplay (normal + daily modes)
├── QuizView.swift            # Multiple-choice quiz
├── DailyChallengeGame.swift  # Date-seeded daily word set
├── AvatarView.swift          # Profile avatar rendering
├── ProfilePhotoManager.swift # Photo picker + themed presets
├── Localization.swift        # In-app language switching
├── ContentLoader.swift       # Loads majors from bundled JSON
├── MajorOnboardingView.swift # First-run "Choose Your Major" screen
├── MajorSelectView.swift     # Switch major any time
├── ComputerEngineering.json  # Computer Engineering word/definition content
├── Medicine.json             # Medicine word/definition content
└── ...
```

### 🧪 Tests

A `CampusQuestTests` unit-test target covers the security-sensitive auth/storage paths (sign-out PII clearing, per-account data isolation, one-time legacy migration) and the core scoring logic (XP, streaks, daily rewards). Run them with **⌘U**, or:

```bash
xcodebuild test -scheme CampusQuest -destination 'platform=iOS Simulator,name=iPhone 17'
```

### 🔒 Privacy

Guest mode never writes to disk, syncs to the cloud, or collects statistics. Sign-in is local only — there is no server. Each signed-in Apple account gets its own on-device store, so progress never leaks between users sharing a device, and the profile photo is cleared on sign-out. The Apple credential is re-validated on launch, signing the user out if access was revoked. Profile photos and other data stay on-device.

</details>

<details>
<summary><b>🇹🇷 Türkçe oku</b></summary>

<br>

### Genel Bakış

CampusQuest Academy, iOS için eğitici bir kelime oyunudur. Oyuncular bir **bölüm** seçer — Computer Engineering ya da Medicine — ardından o bölümün terimlerini harf çarkında bulur, tanımlarını öğrenir, XP kazanır, akademik rütbelerde yükselir (Freshman → Senior), başarımların kilidini açar ve günlük serilerini sürdürür. Tamamen **SwiftUI**, **SwiftData** ve **SpriteKit** ile geliştirilmiştir — sunucu yok, hesap zorunluluğu yok.

### ✨ Özellikler

- **Birden çok bölüm** — İlk açılışta bir bölüm seç (Computer Engineering ya da Medicine), istediğin zaman değiştir; her bölümün kendi seviyeleri ve terminolojisi vardır.
- **Kelime bulmacaları** — Harf çarkını çevirerek terimleri hecele; çözülen her kelime tanımını gösterir.
- **Quiz modu** — Bölümün konularına göre çoktan seçmeli sorular (örn. Programlama, Veri Yapıları, Ağlar, Veritabanları, Siber Güvenlik).
- **Günlük Görev** — Tarihe göre belirlenen, her gün yenilenen, bonus XP'li kelime seti.
- **Seri (streak) sistemi** — Arka arkaya oynadıkça artan alev sayacı.
- **Rütbe & XP** — Canlı XP çubuğu ve rütbe atlama kilometre taşlarıyla akademik seviyeler.
- **Başarımlar** — Kilometre taşları için kademeli rozetler (Bronz, Gümüş, Altın).
- **Kampüs Kimlik kartı** — İsim, bölüm, rütbe ve istatistiklerle kişisel öğrenci kimlik kartı.
- **Avatarlar** — Galeriden fotoğraf seç ya da uygulama temalı 12 hazır avatardan birini kullan.
- **Görünüm** — Açık, Koyu ya da Sistem ayarını izle; Ayarlar'dan istediğin zaman değiştirilebilir (her ekranda tam koyu mod desteği).
- **Rehberli öğretici** — İlk açılış karşılama turu ve seviye içi "nasıl oynanır" coachmark anlatımı; Ayarlar'dan istediğin zaman tekrar oynatılabilir.
- **Yerel bildirimler** — Seriyi sürdürmek için akşam 19:00'da isteğe bağlı günlük hatırlatma.
- **5 dil** — Tamamen yerelleştirilmiş arayüz (%100 kapsama): İngilizce 🇺🇸, Türkçe 🇹🇷, Almanca 🇩🇪, Fransızca 🇫🇷, İspanyolca 🇪🇸 (yalnızca arayüz; teknik sözlük İngilizce kalır).
- **Apple ile Giriş** veya **Misafir Olarak Devam** — Misafir modu tamamen gizlidir: cihaz dışına hiçbir şey kaydedilmez, istatistik toplanmaz.
- **Paylaşım** — Rütbe, öğrenilen terimler ve kazanılan XP içeren "Course Completed" kartını paylaş.

### 🛠 Teknolojiler

| Katman | Teknoloji |
|--------|-----------|
| Arayüz | SwiftUI (iOS 17.5+) |
| Kalıcılık | SwiftData (`@Model`, hafif geçiş) |
| Animasyon / sahne | SpriteKit |
| Kimlik | Apple ile Giriş (`AuthenticationServices`) |
| İçerik | Paketlenmiş JSON (`ComputerEngineering.json`, `Medicine.json`) |
| Yerelleştirme | String Catalog (`Localizable.xcstrings`) |
| Bildirimler | `UNUserNotificationCenter` (yalnızca yerel) |

### 🚀 Başlangıç

**Gereksinimler:** Xcode 26+, iOS 17.5+ cihaz veya simülatör.

```bash
git clone https://github.com/Aosll/CampusQuest.git
cd CampusQuest
open CampusQuest.xcodeproj
```

Ardından **CampusQuest** şemasını seçip **⌘R** ile derleyip çalıştır.

> Build numarası her derlemede git commit sayısından otomatik atanır; elle sürüm yönetimi gerekmez.

### 📁 Proje Yapısı

```
CampusQuest/
├── CampusQuestApp.swift      # Uygulama girişi, ortam bağlantıları
├── AuthManager.swift         # Apple ile Giriş / misafir durumu
├── PlayerProgress.swift      # SwiftData modeli: XP, seri, seviyeler
├── RankSystem.swift          # Akademik rütbeler & XP eşikleri
├── LetterWheelView.swift     # Temel kelime bulmaca etkileşimi
├── LevelView.swift           # Oynanış (normal + günlük mod)
├── QuizView.swift            # Çoktan seçmeli quiz
├── DailyChallengeGame.swift  # Tarihe dayalı günlük kelime seti
├── AvatarView.swift          # Profil avatarı render
├── ProfilePhotoManager.swift # Fotoğraf seçici + temalı hazır avatarlar
├── Localization.swift        # Uygulama içi dil değişimi
├── ContentLoader.swift       # Bölümleri paketli JSON'dan yükler
├── MajorOnboardingView.swift # İlk açılış "Bölümünü Seç" ekranı
├── MajorSelectView.swift     # Bölümü istediğin zaman değiştir
├── ComputerEngineering.json  # Computer Engineering kelime/tanım içeriği
├── Medicine.json             # Medicine kelime/tanım içeriği
└── ...
```

### 🧪 Testler

`CampusQuestTests` birim test hedefi, güvenlik açısından kritik kimlik/depolama yollarını (çıkışta PII temizliği, hesap başına veri izolasyonu, tek seferlik eski veri taşıması) ve çekirdek puanlama mantığını (XP, seriler, günlük ödüller) kapsar. **⌘U** ile ya da şununla çalıştır:

```bash
xcodebuild test -scheme CampusQuest -destination 'platform=iOS Simulator,name=iPhone 17'
```

### 🔒 Gizlilik

Misafir modu hiçbir zaman diske yazmaz, buluta senkronlamaz veya istatistik toplamaz. Giriş yalnızca yereldir — sunucu yoktur. Giriş yapan her Apple hesabı kendi cihaz içi deposunu kullanır; böylece bir cihazı paylaşan kullanıcılar arasında ilerleme sızmaz ve profil fotoğrafı çıkışta silinir. Apple kimliği açılışta yeniden doğrulanır; erişim iptal edilmişse kullanıcı otomatik olarak çıkış yapar. Profil fotoğrafları ve diğer veriler cihazda kalır.

</details>

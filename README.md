<div align="center">

# 🎓 CampusQuest Academy

**A bright, gamified iOS word game that turns computer-science terminology into a daily learning habit.**

![Platform](https://img.shields.io/badge/platform-iOS%2017.5%2B-blue)
![Swift](https://img.shields.io/badge/Swift-SwiftUI%20%2B%20SwiftData-orange)
![Version](https://img.shields.io/badge/version-1.0-brightgreen)

**Choose your language · Dilini seç**

</div>

<details>
<summary><b>🇺🇸 Read in English</b></summary>

<br>

### Overview

CampusQuest Academy is an educational word game for iOS. Players uncover computer-science terms on a letter wheel, learn their definitions, earn XP, climb academic ranks (Freshman → Senior), unlock achievements, and keep a daily streak going. It's built entirely with **SwiftUI**, **SwiftData**, and **SpriteKit** — no backend, no accounts required.

### ✨ Features

- **Word puzzles** — Spin the letter wheel to spell out CS terms; each solved word reveals its definition.
- **Quiz mode** — Multiple-choice questions across topics (Programming, Data Structures, Networks, Databases, Cybersecurity).
- **Daily Challenge** — A deterministic, date-seeded word set with bonus XP, refreshed every day.
- **Streak system** — A flame counter rewards you for playing on consecutive days.
- **Ranks & XP** — Progress through academic levels with a live XP bar and rank-up milestones.
- **Achievements** — Earn tiered badges (Bronze, Silver, Gold) for milestones.
- **Campus ID card** — A personal student-ID card with your name, major, rank, and stats.
- **Avatars** — Pick a photo from your library or choose one of 12 app-themed generated avatars.
- **Local notifications** — An optional daily reminder at 7:00 PM to keep your streak.
- **5 languages** — Full in-app localization: English 🇺🇸, Turkish 🇹🇷, German 🇩🇪, French 🇫🇷, Spanish 🇪🇸 (UI only; the technical dictionary stays in English).
- **Sign in with Apple** or **Continue as Guest** — Guest mode is fully private: nothing is stored off-device and no statistics are collected.
- **Share** — Share a "Course Completed" card with your rank, terms learned, and XP earned.

### 🛠 Tech Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI (iOS 17.5+) |
| Persistence | SwiftData (`@Model`, lightweight migration) |
| Animations / scene | SpriteKit |
| Auth | Sign in with Apple (`AuthenticationServices`) |
| Content | Bundled JSON (`ComputerEngineering.json`) |
| Localization | String Catalog (`Localizable.xcstrings`) |
| Notifications | `UNUserNotificationCenter` (local only) |

### 🚀 Getting Started

**Requirements:** Xcode 16+, iOS 17.5+ device or simulator.

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
├── ComputerEngineering.json  # The word/definition content
└── ...
```

### 🔒 Privacy

Guest mode never writes to disk, syncs to the cloud, or collects statistics. Sign-in is local only — there is no server. Profile photos are stored on-device.

</details>

<details>
<summary><b>🇹🇷 Türkçe oku</b></summary>

<br>

### Genel Bakış

CampusQuest Academy, iOS için eğitici bir kelime oyunudur. Oyuncular harf çarkında bilgisayar bilimleri terimlerini bulur, tanımlarını öğrenir, XP kazanır, akademik rütbelerde yükselir (Freshman → Senior), başarımların kilidini açar ve günlük serilerini sürdürür. Tamamen **SwiftUI**, **SwiftData** ve **SpriteKit** ile geliştirilmiştir — sunucu yok, hesap zorunluluğu yok.

### ✨ Özellikler

- **Kelime bulmacaları** — Harf çarkını çevirerek BB terimlerini hecele; çözülen her kelime tanımını gösterir.
- **Quiz modu** — Konulara göre çoktan seçmeli sorular (Programlama, Veri Yapıları, Ağlar, Veritabanları, Siber Güvenlik).
- **Günlük Görev** — Tarihe göre belirlenen, her gün yenilenen, bonus XP'li kelime seti.
- **Seri (streak) sistemi** — Arka arkaya oynadıkça artan alev sayacı.
- **Rütbe & XP** — Canlı XP çubuğu ve rütbe atlama kilometre taşlarıyla akademik seviyeler.
- **Başarımlar** — Kilometre taşları için kademeli rozetler (Bronz, Gümüş, Altın).
- **Kampüs Kimlik kartı** — İsim, bölüm, rütbe ve istatistiklerle kişisel öğrenci kimlik kartı.
- **Avatarlar** — Galeriden fotoğraf seç ya da uygulama temalı 12 hazır avatardan birini kullan.
- **Yerel bildirimler** — Seriyi sürdürmek için akşam 19:00'da isteğe bağlı günlük hatırlatma.
- **5 dil** — Tam uygulama içi yerelleştirme: İngilizce 🇺🇸, Türkçe 🇹🇷, Almanca 🇩🇪, Fransızca 🇫🇷, İspanyolca 🇪🇸 (yalnızca arayüz; teknik sözlük İngilizce kalır).
- **Apple ile Giriş** veya **Misafir Olarak Devam** — Misafir modu tamamen gizlidir: cihaz dışına hiçbir şey kaydedilmez, istatistik toplanmaz.
- **Paylaşım** — Rütbe, öğrenilen terimler ve kazanılan XP içeren "Course Completed" kartını paylaş.

### 🛠 Teknolojiler

| Katman | Teknoloji |
|--------|-----------|
| Arayüz | SwiftUI (iOS 17.5+) |
| Kalıcılık | SwiftData (`@Model`, hafif geçiş) |
| Animasyon / sahne | SpriteKit |
| Kimlik | Apple ile Giriş (`AuthenticationServices`) |
| İçerik | Paketlenmiş JSON (`ComputerEngineering.json`) |
| Yerelleştirme | String Catalog (`Localizable.xcstrings`) |
| Bildirimler | `UNUserNotificationCenter` (yalnızca yerel) |

### 🚀 Başlangıç

**Gereksinimler:** Xcode 16+, iOS 17.5+ cihaz veya simülatör.

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
├── ComputerEngineering.json  # Kelime/tanım içeriği
└── ...
```

### 🔒 Gizlilik

Misafir modu hiçbir zaman diske yazmaz, buluta senkronlamaz veya istatistik toplamaz. Giriş yalnızca yereldir — sunucu yoktur. Profil fotoğrafları cihazda saklanır.

</details>

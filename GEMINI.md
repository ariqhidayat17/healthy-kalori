# Healthy Calories (Bodybuilder Calorie Control) - Project Guidance

Selamat datang di proyek **Healthy Calories**, sebuah aplikasi pelacak kalori dan makronutrisi yang dirancang khusus untuk binaragawan dengan elemen gamifikasi (RPG).

## 🚀 Misi Proyek
Meningkatkan UI/UX aplikasi agar lebih tertata, modern, dan profesional (lebih "polished") tanpa menghilangkan fitur yang sudah ada. Aplikasi harus tetap terasa seperti "RPG Fitness Coach" yang interaktif.

## 🏗️ Arsitektur & Teknologi
- **Framework:** Flutter (Material 3).
- **State Management:** `Provider` (Lihat `lib/models/calorie_provider.dart`).
- **Database:** `sqflite` (Lihat `lib/utils/database_helper.dart`).
- **AI Services:** 
  - `GeminiService` (`lib/services/gemini_service.dart`)
  - `GroqService` (`lib/services/groq_service.dart`)
- **Gamification:** `GamificationService` (`lib/services/gamification_service.dart`) menangani XP, level, dan rank.
- **Theme:** RPG-inspired (Orange/Amber) dengan mode cerah sebagai default.

## 📂 Peta Fitur & File Kunci
### 1. Inti Pelacakan (Tracking Core)
- **Calorie Tracker:** `lib/screens/calorie_tracker_screen.dart`
- **Weight Log:** `lib/screens/weight_log_screen.dart`
- **Workout Logger:** `lib/screens/workout_logger_screen.dart`
- **Food Database:** `lib/models/food_database.dart` & `lib/services/openfoodfacts_service.dart`

### 2. Gamifikasi & Progres
- **Mission Screen:** `lib/screens/mission_screen.dart`
- **Rank Progress:** `lib/screens/rank_progress_screen.dart`
- **XP/Rank Widget:** `lib/widgets/xp_progress_bar.dart` & `lib/widgets/rank_badge_widget.dart`

### 3. AI & Fitur Pintar
- **AI Coach Screen:** `lib/screens/ai_coach_screen.dart`
- **Fuzzy Logic:** `lib/models/fuzzy_logic.dart` (untuk perhitungan nutrisi pintar).

### 4. Visualisasi & UI
- **Charts:** `lib/screens/stats_screen.dart` (menggunakan `fl_chart`).
- **Dashboard:** `lib/screens/home_screen.dart` & `lib/screens/main_screen.dart`.
- **Custom Widgets:** Terletak di `lib/widgets/` (seperti `CircularCalorieRing`, `MacroProgressBar`, dll).

## 🎨 Panduan UI/UX (Masa Depan)
- **Consistency:** Gunakan `Theme.of(context)` dan hindari hardcoded colors.
- **Layout:** Gunakan padding yang konsisten (default 16.0). Prioritaskan `Sliver` untuk layar yang panjang agar scrolling terasa smooth.
- **Feedback:** Manfaatkan `flutter_animate` untuk transisi state atau kemunculan widget.
- **Clarity:** Pastikan hierarki informasi jelas. Elemen terpenting (sisa kalori, target makro) harus paling menonjol.

## ⚠️ Batasan Teknis (Constraints)
- **Jangan Menghapus Fitur:** UI baru harus mendukung semua input/output data yang sudah ada.
- **Keamanan Data:** Pastikan interaksi database tetap melalui `DatabaseHelper`.
- **Logic Integrity:** Jangan mengubah logika perhitungan di `CalorieProvider` atau `FuzzyLogic` kecuali diminta secara eksplisit.
- **API Keys:** API Keys dikelola melalui `.env`. Jangan memindahkan atau menghapus file ini.

## 📝 Catatan Penting untuk Agent
1. **Analisis Sebelum Beraksi:** Selalu baca `lib/main.dart` untuk memahami tema global sebelum membuat widget baru.
2. **Modularitas:** Jika membuat komponen UI baru yang kompleks, letakkan di `lib/widgets/`.
3. **Internasionalisasi:** Saat ini aplikasi menggunakan campuran Bahasa Indonesia dan Inggris. Tetap konsisten dengan preferensi user.

---
*Dokumen ini adalah panduan utama untuk pengembangan UI/UX yang terstruktur dan aman.*

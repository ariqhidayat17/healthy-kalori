# Unit Tests — Healthy Calories

## Setup

Tambahkan ke `pubspec.yaml` (bagian `dev_dependencies`):

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  sqflite_common_ffi: ^2.3.0   # untuk database_helper_test
```

Lalu jalankan:

```bash
flutter pub get
```

---

## Menjalankan Test

```bash
# Semua test sekaligus
flutter test

# Satu file saja
flutter test test/fuzzy_logic_test.dart
flutter test test/gamification_service_test.dart
flutter test test/database_helper_test.dart
flutter test test/streak_service_test.dart

# Dengan verbose output
flutter test --reporter expanded
```

---

## Struktur Test

| File | Class yang diuji | Jumlah test |
|---|---|---|
| `fuzzy_logic_test.dart` | `FuzzyLogic` | 15 test |
| `gamification_service_test.dart` | `GamificationService` | 22 test |
| `database_helper_test.dart` | DB schema & query SQL | 18 test |
| `streak_service_test.dart` | `StreakService` (pure logic) | 17 test |

**Total: 72 test**

---

## Catatan

- `database_helper_test.dart` menggunakan **in-memory SQLite** via `sqflite_common_ffi` — tidak butuh emulator atau device.
- `gamification_service_test.dart` hanya menguji **pure logic** (rank, level, rarity) yang tidak bergantung `PrefsService`. Method yang butuh storage (`addXP`, `getUserStats`) masuk integration test.
- `streak_service_test.dart` menguji logika tanggal, XP formula, dan `StreakResult`. `checkAndUpdate()` yang butuh `PrefsService` masuk integration test.

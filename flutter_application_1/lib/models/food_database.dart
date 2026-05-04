// Data makanan Indonesia dengan kalori & makronutrisi per porsi.
// Format: 'Nama (Porsi)': {'calories': int, 'protein': int, 'carbs': int, 'fats': int}

class FoodDatabase {
  // Legacy getter — masih dipakai untuk search filter, mengembalikan nama → kalori
  static Map<String, int> get indonesianFoods {
    return {
      for (final entry in foods.entries) entry.key: entry.value['calories']!
    };
  }

  // Database lengkap dengan makronutrisi (gram)
  static final Map<String, Map<String, int>> foods = {
    // ═══════════════════════════════ MAKANAN POKOK ══════════════════════════
    'Nasi Putih (1 porsi/100g)':      {'calories': 130, 'protein': 2,  'carbs': 28, 'fats': 0},
    'Nasi Merah (1 porsi/100g)':      {'calories': 110, 'protein': 3,  'carbs': 23, 'fats': 1},
    'Nasi Uduk (1 porsi/100g)':       {'calories': 185, 'protein': 4,  'carbs': 30, 'fats': 6},
    'Nasi Kuning (1 porsi/100g)':     {'calories': 180, 'protein': 4,  'carbs': 29, 'fats': 5},
    'Nasi Goreng (1 porsi/150g)':     {'calories': 267, 'protein': 7,  'carbs': 38, 'fats': 10},
    'Lontong (1 potong)':             {'calories': 38,  'protein': 1,  'carbs': 8,  'fats': 0},
    'Ketupat (1 buah)':               {'calories': 40,  'protein': 1,  'carbs': 9,  'fats': 0},
    'Bubur Ayam (1 mangkok)':         {'calories': 220, 'protein': 12, 'carbs': 28, 'fats': 6},

    // ═══════════════════════════════ LAUK PAUK ═══════════════════════════════
    'Ayam Goreng (1 potong paha)':    {'calories': 250, 'protein': 20, 'carbs': 5,  'fats': 16},
    'Ayam Bakar (1 potong dada)':     {'calories': 195, 'protein': 28, 'carbs': 2,  'fats': 8},
    'Rendang Daging (1 porsi/100g)':  {'calories': 285, 'protein': 24, 'carbs': 8,  'fats': 18},
    'Sate Ayam (5 tusuk)':            {'calories': 175, 'protein': 18, 'carbs': 4,  'fats': 9},
    'Sate Kambing (5 tusuk)':         {'calories': 210, 'protein': 20, 'carbs': 3,  'fats': 13},
    'Telur Dadar (1 butir)':          {'calories': 90,  'protein': 6,  'carbs': 1,  'fats': 7},
    'Telur Rebus (1 butir)':          {'calories': 70,  'protein': 6,  'carbs': 0,  'fats': 5},
    'Telur Balado (1 butir)':         {'calories': 95,  'protein': 6,  'carbs': 3,  'fats': 6},
    'Tempe Goreng (2 potong)':        {'calories': 160, 'protein': 11, 'carbs': 9,  'fats': 9},
    'Tahu Goreng (2 potong)':         {'calories': 115, 'protein': 8,  'carbs': 4,  'fats': 7},
    'Ikan Bakar (1 ekor sedang)':     {'calories': 150, 'protein': 24, 'carbs': 0,  'fats': 5},
    'Ikan Goreng (1 ekor sedang)':    {'calories': 200, 'protein': 22, 'carbs': 4,  'fats': 10},
    'Perkedel Kentang (1 buah)':      {'calories': 75,  'protein': 2,  'carbs': 9,  'fats': 4},
    'Bakwan Jagung (1 buah)':         {'calories': 80,  'protein': 2,  'carbs': 11, 'fats': 3},
    'Empal Daging (1 potong)':        {'calories': 195, 'protein': 18, 'carbs': 4,  'fats': 12},
    'Dendeng Balado (1 porsi)':       {'calories': 210, 'protein': 22, 'carbs': 5,  'fats': 11},
    'Ayam Penyet (1 porsi)':          {'calories': 272, 'protein': 24, 'carbs': 6,  'fats': 16},
    'Bebek Goreng (1 porsi)':         {'calories': 320, 'protein': 26, 'carbs': 5,  'fats': 22},
    'Daging Sapi Panggang (100g)':    {'calories': 215, 'protein': 26, 'carbs': 0,  'fats': 12},
    'Udang Goreng (6 ekor)':          {'calories': 180, 'protein': 18, 'carbs': 6,  'fats': 9},
    'Cumi Goreng (1 porsi)':          {'calories': 175, 'protein': 15, 'carbs': 8,  'fats': 9},

    // ═══════════════════════════════ PROTEIN TINGGI (GYM) ════════════════════
    'Dada Ayam Rebus (100g)':         {'calories': 165, 'protein': 31, 'carbs': 0,  'fats': 4},
    'Putih Telur (3 butir)':          {'calories': 51,  'protein': 11, 'carbs': 0,  'fats': 0},
    'Ikan Tuna Kaleng (1 kaleng)':    {'calories': 120, 'protein': 26, 'carbs': 0,  'fats': 1},
    'Ikan Salmon (100g)':             {'calories': 208, 'protein': 20, 'carbs': 0,  'fats': 13},
    'Tempe Kukus (100g)':             {'calories': 193, 'protein': 19, 'carbs': 9,  'fats': 11},
    'Tahu Sutera (100g)':             {'calories': 55,  'protein': 5,  'carbs': 2,  'fats': 3},
    'Edamame (100g)':                 {'calories': 122, 'protein': 11, 'carbs': 10, 'fats': 5},
    'Greek Yogurt (150g)':            {'calories': 100, 'protein': 17, 'carbs': 6,  'fats': 0},
    'Protein Shake (1 scoop/30g)':    {'calories': 120, 'protein': 24, 'carbs': 3,  'fats': 2},
    'Keju Cottage (100g)':            {'calories': 98,  'protein': 11, 'carbs': 3,  'fats': 4},
    'Susu Skim (1 gelas/250ml)':      {'calories': 85,  'protein': 8,  'carbs': 12, 'fats': 0},
    'Daging Sapi Giling (100g)':      {'calories': 217, 'protein': 26, 'carbs': 0,  'fats': 12},

    // ═══════════════════════════════ SAYURAN ═════════════════════════════════
    'Sayur Asem (1 mangkok)':         {'calories': 85,  'protein': 3,  'carbs': 14, 'fats': 2},
    'Sayur Lodeh (1 mangkok)':        {'calories': 125, 'protein': 4,  'carbs': 16, 'fats': 5},
    'Sayur Sop (1 mangkok)':          {'calories': 70,  'protein': 4,  'carbs': 10, 'fats': 2},
    'Sayur Bayam (1 mangkok)':        {'calories': 50,  'protein': 4,  'carbs': 7,  'fats': 1},
    'Sayur Kangkung (1 mangkok)':     {'calories': 45,  'protein': 3,  'carbs': 6,  'fats': 1},
    'Sayur Bening (1 mangkok)':       {'calories': 40,  'protein': 2,  'carbs': 7,  'fats': 0},
    'Gado-gado (1 porsi)':            {'calories': 230, 'protein': 10, 'carbs': 20, 'fats': 12},
    'Pecel (1 porsi)':                {'calories': 210, 'protein': 8,  'carbs': 22, 'fats': 10},
    'Urap (1 porsi)':                 {'calories': 150, 'protein': 5,  'carbs': 14, 'fats': 9},
    'Cap Cay (1 porsi)':              {'calories': 120, 'protein': 5,  'carbs': 14, 'fats': 5},
    'Tumis Kangkung (1 porsi)':       {'calories': 80,  'protein': 3,  'carbs': 8,  'fats': 4},
    'Tumis Tauge (1 porsi)':          {'calories': 65,  'protein': 3,  'carbs': 7,  'fats': 3},
    'Brokoli Kukus (100g)':           {'calories': 34,  'protein': 3,  'carbs': 7,  'fats': 0},
    'Wortel (1 buah sedang)':         {'calories': 25,  'protein': 1,  'carbs': 6,  'fats': 0},

    // ═══════════════════════════════ MAKANAN BERKUAH ══════════════════════════
    'Soto Ayam (1 mangkok)':          {'calories': 220, 'protein': 16, 'carbs': 18, 'fats': 9},
    'Soto Betawi (1 mangkok)':        {'calories': 330, 'protein': 16, 'carbs': 20, 'fats': 20},
    'Soto Madura (1 mangkok)':        {'calories': 245, 'protein': 16, 'carbs': 22, 'fats': 10},
    'Bakso (1 mangkok, 5 butir)':     {'calories': 300, 'protein': 18, 'carbs': 28, 'fats': 12},
    'Mie Ayam (1 mangkok)':           {'calories': 380, 'protein': 16, 'carbs': 50, 'fats': 12},
    'Mie Goreng (1 porsi)':           {'calories': 420, 'protein': 12, 'carbs': 60, 'fats': 15},
    'Mie Rebus (1 porsi)':            {'calories': 350, 'protein': 11, 'carbs': 54, 'fats': 9},
    'Rawon (1 mangkok)':              {'calories': 290, 'protein': 22, 'carbs': 14, 'fats': 16},
    'Gulai Kambing (1 mangkok)':      {'calories': 310, 'protein': 22, 'carbs': 10, 'fats': 20},
    'Tongseng (1 mangkok)':           {'calories': 285, 'protein': 18, 'carbs': 18, 'fats': 14},
    'Sup Buntut (1 mangkok)':         {'calories': 345, 'protein': 24, 'carbs': 12, 'fats': 22},
    'Ketoprak (1 porsi)':             {'calories': 265, 'protein': 9,  'carbs': 36, 'fats': 10},
    'Laksa (1 mangkok)':              {'calories': 320, 'protein': 12, 'carbs': 38, 'fats': 14},

    // ═══════════════════════════════ MAKANAN RINGAN ═══════════════════════════
    'Pisang Goreng (1 buah)':         {'calories': 120, 'protein': 1,  'carbs': 20, 'fats': 4},
    'Tape Goreng (1 buah)':           {'calories': 115, 'protein': 1,  'carbs': 22, 'fats': 3},
    'Martabak Manis (1 potong)':      {'calories': 270, 'protein': 5,  'carbs': 42, 'fats': 9},
    'Martabak Telur (1 potong)':      {'calories': 250, 'protein': 9,  'carbs': 28, 'fats': 12},
    'Batagor (1 porsi)':              {'calories': 230, 'protein': 10, 'carbs': 22, 'fats': 12},
    'Siomay (1 porsi)':               {'calories': 210, 'protein': 9,  'carbs': 24, 'fats': 9},
    'Pempek (1 porsi)':               {'calories': 265, 'protein': 10, 'carbs': 36, 'fats': 9},
    'Cireng (5 buah)':                {'calories': 200, 'protein': 2,  'carbs': 36, 'fats': 5},
    'Bakwan (1 buah)':                {'calories': 70,  'protein': 2,  'carbs': 9,  'fats': 3},
    'Tahu Isi (1 buah)':              {'calories': 80,  'protein': 4,  'carbs': 7,  'fats': 4},
    'Risoles (1 buah)':               {'calories': 140, 'protein': 5,  'carbs': 16, 'fats': 6},
    'Pastel (1 buah)':                {'calories': 155, 'protein': 4,  'carbs': 18, 'fats': 7},
    'Klepon (3 buah)':                {'calories': 105, 'protein': 1,  'carbs': 22, 'fats': 2},
    'Onde-onde (1 buah)':             {'calories': 80,  'protein': 2,  'carbs': 14, 'fats': 2},
    'Lemper (1 buah)':                {'calories': 110, 'protein': 4,  'carbs': 18, 'fats': 3},

    // ═══════════════════════════════ BUAH-BUAHAN ══════════════════════════════
    'Pisang (1 buah sedang)':         {'calories': 105, 'protein': 1,  'carbs': 27, 'fats': 0},
    'Apel (1 buah sedang)':           {'calories': 80,  'protein': 0,  'carbs': 21, 'fats': 0},
    'Jeruk (1 buah sedang)':          {'calories': 45,  'protein': 1,  'carbs': 11, 'fats': 0},
    'Mangga (1 buah sedang)':         {'calories': 135, 'protein': 1,  'carbs': 35, 'fats': 1},
    'Pepaya (1 potong sedang)':       {'calories': 55,  'protein': 1,  'carbs': 14, 'fats': 0},
    'Semangka (1 potong sedang)':     {'calories': 50,  'protein': 1,  'carbs': 12, 'fats': 0},
    'Melon (1 potong sedang)':        {'calories': 45,  'protein': 1,  'carbs': 11, 'fats': 0},
    'Alpukat (1/2 buah)':             {'calories': 160, 'protein': 2,  'carbs': 9,  'fats': 15},
    'Durian (3 biji)':                {'calories': 270, 'protein': 3,  'carbs': 60, 'fats': 5},
    'Rambutan (10 buah)':             {'calories': 65,  'protein': 1,  'carbs': 16, 'fats': 0},
    'Salak (3 buah)':                 {'calories': 75,  'protein': 1,  'carbs': 19, 'fats': 0},
    'Jambu Biji (1 buah sedang)':     {'calories': 45,  'protein': 1,  'carbs': 10, 'fats': 1},

    // ═══════════════════════════════ MINUMAN ══════════════════════════════════
    'Es Teh Manis (1 gelas)':         {'calories': 90,  'protein': 0,  'carbs': 22, 'fats': 0},
    'Teh Tawar (1 gelas)':            {'calories': 2,   'protein': 0,  'carbs': 0,  'fats': 0},
    'Kopi Hitam (1 gelas)':           {'calories': 5,   'protein': 0,  'carbs': 1,  'fats': 0},
    'Kopi Susu (1 gelas)':            {'calories': 70,  'protein': 2,  'carbs': 10, 'fats': 3},
    'Es Jeruk (1 gelas)':             {'calories': 110, 'protein': 1,  'carbs': 27, 'fats': 0},
    'Es Kelapa Muda (1 gelas)':       {'calories': 130, 'protein': 1,  'carbs': 30, 'fats': 1},
    'Jus Alpukat (1 gelas)':          {'calories': 190, 'protein': 2,  'carbs': 20, 'fats': 12},
    'Jus Mangga (1 gelas)':           {'calories': 135, 'protein': 1,  'carbs': 33, 'fats': 1},
    'Susu Full Cream (1 gelas/250ml)':{'calories': 150, 'protein': 8,  'carbs': 12, 'fats': 8},
    'Wedang Jahe (1 gelas)':          {'calories': 50,  'protein': 0,  'carbs': 12, 'fats': 0},

    // ═══════════════════════════════ MAKANAN PENUTUP ══════════════════════════
    'Es Krim (1 scoop)':              {'calories': 140, 'protein': 2,  'carbs': 20, 'fats': 6},
    'Pudding (1 cup)':                {'calories': 120, 'protein': 2,  'carbs': 22, 'fats': 3},
    'Kolak Pisang (1 mangkok)':       {'calories': 190, 'protein': 2,  'carbs': 40, 'fats': 4},
    'Bubur Kacang Hijau (1 mangkok)': {'calories': 200, 'protein': 8,  'carbs': 36, 'fats': 3},
    'Es Buah (1 mangkok)':            {'calories': 170, 'protein': 2,  'carbs': 38, 'fats': 2},
    'Kue Lapis (1 potong)':           {'calories': 115, 'protein': 2,  'carbs': 22, 'fats': 3},
    'Bika Ambon (1 potong)':          {'calories': 160, 'protein': 3,  'carbs': 28, 'fats': 5},
    'Kue Serabi (1 buah)':            {'calories': 95,  'protein': 2,  'carbs': 18, 'fats': 2},
  };

  // Helper: ambil makro lengkap dari nama makanan
  static Map<String, int>? getMacros(String foodName) {
    return foods[foodName];
  }
}
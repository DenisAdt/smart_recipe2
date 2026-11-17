"""
Evaluasi Akurasi Stemming Sastrawi pada Dataset Resep Smart Recipe Planner.

Script ini:
  1. Memuat dataset CSV yang benar-benar digunakan dalam penelitian.
  2. Mengekstrak kata berimbuhan unik dari field title, ingredients, instructions.
  3. Menjalankan Sastrawi stemmer (pipeline yang sama dengan preprocessor.py).
  4. Membandingkan hasil stemming terhadap bentuk dasar yang ditentukan secara
     linguistik berdasarkan kaidah morfologi Bahasa Indonesia.
  5. Menghasilkan laporan akurasi lengkap.

Cara penentuan bentuk dasar pembanding:
  - Bentuk dasar ditentukan berdasarkan kaidah morfologi Bahasa Indonesia:
    * Prefiks: me-, mem-, men-, meng-, meny-, ber-, di-, ter-, pe-, per-, se-, ke-
    * Sufiks: -kan, -an, -i, -nya
    * Konfiks: me-...-kan, ber-...-an, pe-...-an, ke-...-an, per-...-an
  - Untuk kata serapan/asing dan kata dasar tanpa imbuhan, bentuk dasarnya
    adalah kata itu sendiri.
  - Referensi utama: Kamus Besar Bahasa Indonesia (KBBI) dan kaidah morfologi
    bahasa Indonesia standar (Alwi et al., Tata Bahasa Baku Bahasa Indonesia).
"""

import csv
import re
import sys
import json
from collections import Counter

# Use the same Sastrawi setup as the project's preprocessor.py
from Sastrawi.Stemmer.StemmerFactory import StemmerFactory

# ──────────────────────────────────────────────────────────────
# Configuration (matches project's config.py and preprocessor.py)
# ──────────────────────────────────────────────────────────────
DATASET_PATH = "backend/data/recipes_final_3000_standardized.csv"
TOKEN_RE = re.compile(r"[a-z]+")  # same pattern as preprocessor, excluding numbers

# Reproduce the project's stopword list exactly
CUSTOM_STOPWORDS = {
    "yang", "dan", "di", "ke", "dari", "dengan", "untuk", "pada",
    "adalah", "ini", "itu", "atau", "juga", "sudah", "ada", "tidak",
    "bisa", "agar", "lalu", "kemudian", "hingga", "sampai", "setelah",
    "sebelum", "saat", "ketika", "jika", "maka", "namun", "tetapi",
    "karena", "oleh", "dalam", "luar", "atas", "bawah", "antara",
    "serta", "yaitu", "seperti", "sebagai", "secara", "selama",
    "kembali", "sudah", "masih", "seluruh", "semua", "setiap",
    "masak", "cara", "resep", "bahan", "bumbu", "tambahkan", "aduk",
    "panaskan", "goreng", "tumis", "rebus", "angkat", "sajikan",
    "siapkan", "potong", "iris", "haluskan", "blender", "ulek",
    "secukupnya", "sedikit", "banyak", "kira", "kira-kira", "kurang",
    "lebih", "cukup", "boleh", "dapat", "menggunakan", "digunakan",
    "campurkan", "masukkan", "keluarkan", "gunakan", "lakukan",
    "biarkan", "tunggu", "menit", "jam", "detik",
}

# Also import NLTK stopwords like the project does
try:
    from nltk.corpus import stopwords as _sw
    NLTK_STOPWORDS = set(_sw.words("indonesian"))
except Exception:
    NLTK_STOPWORDS = set()

STOPWORDS = NLTK_STOPWORDS | CUSTOM_STOPWORDS

# Indonesian affix patterns for identifying affixed words
AFFIX_PATTERNS = re.compile(
    r"^(me|mem|men|meng|meny|ber|di|ter|pe|pem|pen|peng|peny|per|se|ke)"
    r"|"
    r"(kan|an|nya|lah|kah|pun|i)$",
    re.IGNORECASE
)

# ──────────────────────────────────────────────────────────────
# Gold-standard root forms (linguistically determined)
#
# Methodology for determining expected root forms:
#   1. Each word is analyzed morphologically based on Indonesian
#      affixation rules (prefiks, sufiks, konfiks).
#   2. The expected root is the base word (kata dasar) as defined
#      in KBBI (Kamus Besar Bahasa Indonesia).
#   3. For loanwords (e.g., "mentega"), the word itself is the root.
#   4. For words with multiple valid interpretations, the culinary
#      context determines the correct root.
# ──────────────────────────────────────────────────────────────

GOLD_STANDARD = {
    # ── Prefiks me- variants ──────────────────────────────────
    "memasak":      "masak",      # me- + masak
    "menggoreng":   "goreng",     # meng- + goreng
    "menumis":      "tumis",      # me- + tumis
    "merebus":      "rebus",      # me- + rebus
    "mengaduk":     "aduk",       # meng- + aduk
    "memotong":     "potong",     # mem- + potong
    "mengiris":     "iris",       # meng- + iris
    "mencuci":      "cuci",       # men- + cuci
    "mengupas":     "kupas",      # meng- + kupas
    "memanggang":   "panggang",   # mem- + panggang
    "mengukus":     "kukus",      # meng- + kukus
    "mencampurkan": "campur",     # men- + campur + -kan
    "memasukkan":   "masuk",      # me- + masuk + -kan
    "menggunakan":  "guna",       # meng- + guna + -kan
    "menambahkan":  "tambah",     # me- + tambah + -kan
    "menyajikan":   "saji",       # meny- + saji + -kan
    "menyiapkan":   "siap",       # meny- + siap + -kan
    "menghaluskan": "halus",      # meng- + halus + -kan
    "menuangkan":   "tuang",      # me- + tuang + -kan
    "membuang":     "buang",      # mem- + buang
    "meniriskan":   "tiris",      # me- + tiris + -kan
    "mengocok":     "kocok",      # meng- + kocok
    "menyaring":    "saring",     # meny- + saring
    "merendam":     "rendam",     # me- + rendam
    "membakar":     "bakar",      # mem- + bakar
    "mencampur":    "campur",     # men- + campur
    "mengolah":     "olah",       # meng- + olah
    "memeras":      "peras",      # mem- + peras
    "menghidangkan":"hidang",     # meng- + hidang + -kan
    "mengangkat":   "angkat",     # meng- + angkat
    "menaburkan":   "tabur",      # me- + tabur + -kan
    "memipihkan":   "pipih",      # mem- + pipih + -kan (mem- + pipih)
    "membumbui":    "bumbu",      # mem- + bumbu + -i
    "memarkan":     "pemar",      # special: memar-kan -> pemar is wrong, memar is the root
    "mengental":    "kental",     # meng- + kental

    # ── Prefiks ber- ──────────────────────────────────────────
    "bersama":      "sama",       # ber- + sama (but "bersama" is a word itself)
    "berbentuk":    "bentuk",     # ber- + bentuk
    "berwarna":     "warna",      # ber- + warna
    "berlebihan":   "lebih",      # ber- + lebih + -an
    "berminyak":    "minyak",     # ber- + minyak
    "berbuih":      "buih",       # ber- + buih

    # ── Prefiks di- (pasif) ───────────────────────────────────
    "dimasak":      "masak",      # di- + masak
    "digoreng":     "goreng",     # di- + goreng
    "dipotong":     "potong",     # di- + potong
    "diaduk":       "aduk",       # di- + aduk
    "diiris":       "iris",       # di- + iris
    "dicuci":       "cuci",       # di- + cuci
    "direbus":      "rebus",      # di- + rebus
    "ditumis":      "tumis",      # di- + tumis
    "dihaluskan":   "halus",      # di- + halus + -kan
    "dimasukkan":   "masuk",      # di- + masuk + -kan
    "ditambahkan":  "tambah",     # di- + tambah + -kan
    "disajikan":    "saji",       # di- + saji + -kan
    "dicampurkan":  "campur",     # di- + campur + -kan
    "dituangkan":   "tuang",      # di- + tuang + -kan
    "diamkan":      "diam",       # may be parsed as di- + am + -kan but actually diam + -kan
    "dihidangkan":  "hidang",     # di- + hidang + -kan
    "dibuang":      "buang",      # di- + buang
    "disiapkan":    "siap",       # di- + siap + -kan
    "ditiriskan":   "tiris",      # di- + tiris + -kan
    "dipanaskan":   "panas",      # di- + panas + -kan
    "diangkat":     "angkat",     # di- + angkat
    "dibakar":      "bakar",      # di- + bakar

    # ── Prefiks ter- ──────────────────────────────────────────
    "terlalu":      "lalu",       # ter- + lalu
    "terbaik":      "baik",       # ter- + baik
    "terlebih":     "lebih",      # ter- + lebih

    # ── Prefiks pe-/pem-/pen-/peng-/peny- (nominalisasi) ─────
    "pemotongan":   "potong",     # pe- + potong + -an
    "penggorengan": "goreng",     # peng- + goreng + -an
    "penyajian":    "saji",       # peny- + saji + -an
    "pemasakan":    "masak",      # pe- + masak + -an
    "pembuatan":    "buat",       # pem- + buat + -an
    "penggunaan":   "guna",       # peng- + guna + -an

    # ── Sufiks -kan ───────────────────────────────────────────
    "tambahkan":    "tambah",     # tambah + -kan
    "masukkan":     "masuk",      # masuk + -kan
    "campurkan":    "campur",     # campur + -kan
    "adukkan":      "aduk",       # aduk + -kan (though rare)
    "sajikan":      "saji",       # saji + -kan
    "siapkan":      "siap",       # siap + -kan
    "haluskan":     "halus",      # halus + -kan
    "panaskan":     "panas",      # panas + -kan
    "tuangkan":     "tuang",      # tuang + -kan
    "angkatkan":    "angkat",     # angkat + -kan
    "hidupkan":     "hidup",      # hidup + -kan
    "matikan":      "mati",       # mati + -kan
    "ratakan":      "rata",       # rata + -kan
    "tiriskan":     "tiris",      # tiris + -kan
    "diamkan":      "diam",       # diam + -kan
    "simpan":       "simpan",     # base word (no affix)
    "sisihkan":     "sisih",      # sisih + -kan
    "koreksi":      "koreksi",    # loanword, no affix

    # ── Sufiks -an ────────────────────────────────────────────
    "masakan":      "masak",      # masak + -an
    "sayuran":      "sayur",      # sayur + -an
    "olahan":       "olah",       # olah + -an
    "campuran":     "campur",     # campur + -an
    "irisan":       "iris",       # iris + -an
    "potongan":     "potong",     # potong + -an
    "gorengan":     "goreng",     # goreng + -an
    "rendaman":     "rendam",     # rendam + -an
    "makanan":      "makan",      # makan + -an
    "minuman":      "minum",      # minum + -an
    "hidangan":     "hidang",     # hidang + -an
    "rebusan":      "rebus",      # rebus + -an
    "adonan":       "adon",       # adon + -an
    "kukusan":      "kukus",      # kukus + -an
    "tumisan":      "tumis",      # tumis + -an
    "panggangan":   "panggang",   # panggang + -an
    "kuahnya":      "kuah",       # kuah + -nya
    "ovennya":      "oven",       # oven + -nya (loanword)
    "penyedap":     "sedap",      # peny- + sedap
    "pelengkap":    "lengkap",    # pe- + lengkap
    "pengganti":    "ganti",      # peng- + ganti
    "pengental":    "kental",     # peng- + kental
    "pewarna":      "warna",      # pe- + warna
    "taburan":      "tabur",      # tabur + -an
    "bumbunan":     "bumbun",     # bumbun + -an (but "bumbu" is more common)
    "larutan":      "larut",      # larut + -an
    "santan":       "santan",     # base word (not sant + -an)
    "lalapan":      "lalap",      # lalap + -an
    "sambalnya":    "sambal",     # sambal + -nya
    "dagingnya":    "daging",     # daging + -nya
    "kuahnya":      "kuah",       # kuah + -nya
    "bahannya":     "bahan",      # bahan + -nya
    "rasanya":      "rasa",       # rasa + -nya
    "matangnya":    "matang",     # matang + -nya

    # ── Sufiks -i ─────────────────────────────────────────────
    "taburi":       "tabur",      # tabur + -i
    "olesi":        "oles",       # oles + -i
    "lumuri":       "lumur",      # lumur + -i
    "sirami":       "siram",      # siram + -i

    # ── Konfiks ke-...-an ─────────────────────────────────────
    "kematangan":   "matang",     # ke- + matang + -an
    "kecokelatan":  "cokelat",    # ke- + cokelat + -an
    "keasinan":     "asin",       # ke- + asin + -an
    "kemanisan":    "manis",      # ke- + manis + -an

    # ── Kata dasar (no affix, should remain unchanged) ────────
    "ayam":         "ayam",
    "ikan":         "ikan",
    "daging":       "daging",
    "udang":        "udang",
    "telur":        "telur",
    "tahu":         "tahu",
    "tempe":        "tempe",
    "bawang":       "bawang",
    "cabai":        "cabai",
    "tomat":        "tomat",
    "wortel":       "wortel",
    "kentang":      "kentang",
    "garam":        "garam",
    "gula":         "gula",
    "santan":       "santan",
    "minyak":       "minyak",
    "tepung":       "tepung",
    "nasi":         "nasi",
    "beras":        "beras",
    "kecap":        "kecap",
    "sambal":       "sambal",
    "saus":         "saus",
    "cabe":         "cabe",
    "kunyit":       "kunyit",
    "jahe":         "jahe",
    "lengkuas":     "lengkuas",
    "serai":        "serai",
    "daun":         "daun",
    "jeruk":        "jeruk",
    "mangga":       "mangga",
    "pisang":       "pisang",
    "kelapa":       "kelapa",
    "lada":         "lada",
    "merica":       "merica",
    "pala":         "pala",
    "jintan":       "jintan",
    "ketumbar":     "ketumbar",
    "kemiri":       "kemiri",
    "kemangi":      "kemangi",
    "kangkung":     "kangkung",
    "bayam":        "bayam",
    "kacang":       "kacang",
    "terasi":       "terasi",
    "bakso":        "bakso",
    "soto":         "soto",
    "rendang":      "rendang",
    "gulai":        "gulai",
    "sate":         "sate",
    "pecel":        "pecel",
    "rujak":        "rujak",
    "martabak":     "martabak",
    "tiga":         "tiga",
    "empat":        "empat",
    "kaldu":        "kaldu",
    "mentega":      "mentega",
    "margarin":     "margarin",
    "susu":         "susu",
    "keju":         "keju",

    # ── Words from ground truth queries ───────────────────────
    "putih":        "putih",
    "merah":        "merah",
    "sapi":         "sapi",

    # ── Commonly mis-stemmed words in Indonesian culinary ─────
    "mentimun":     "mentimun",   # base word, not men- + timun
    "mentega":      "mentega",    # base word (loanword), not men- + tega
    "mengkudu":     "mengkudu",   # base word, not meng- + kudu
    "terasi":       "terasi",     # base word, not ter- + asi
    "belimbing":    "belimbing",  # base word, not ber- + limbing
    "terong":       "terong",     # base word, not ter- + ong
    "semangka":     "semangka",   # base word, not se- + mangka
    "seledri":      "seledri",    # base word, not se- + ledri
    "serundeng":    "serundeng",  # base word
    "selada":       "selada",     # base word, not se- + lada
    "peterseli":    "peterseli",  # base word (loanword)
    "perkedel":     "perkedel",   # base word (loanword from Dutch)
    "pempek":       "pempek",     # base word
    "bersantan":    "santan",     # ber- + santan
    "berbumbu":     "bumbu",      # ber- + bumbu
    "berkaldu":     "kaldu",      # ber- + kaldu

    # ── me- prefix with special nasal assimilation ────────────
    "mengulek":     "ulek",       # meng- + ulek
    "mencincang":   "cincang",    # men- + cincang
    "mengembang":   "kembang",    # meng- + kembang
    "meleleh":      "leleh",      # me- + leleh
    "melunak":      "lunak",      # me- + lunak
    "mengering":    "kering",     # meng- + kering
    "meletakkan":   "letak",      # me- + letak + -kan
    "meratakan":    "rata",       # me- + rata + -kan
    "menyedapkan":  "sedap",      # meny- + sedap + -kan

    # ── di- passive forms ─────────────────────────────────────
    "dikukus":      "kukus",      # di- + kukus
    "dipanggang":   "panggang",   # di- + panggang
    "dikocok":      "kocok",      # di- + kocok
    "disaring":     "saring",     # di- + saring
    "direndam":     "rendam",     # di- + rendam
    "diulek":       "ulek",       # di- + ulek
    "dicincang":    "cincang",    # di- + cincang
    "diadoni":      "adon",       # di- + adon + -i
    "dilumuri":     "lumur",      # di- + lumur + -i
}

# Correct known false entries
# memarkan -> memar (not pemar)
GOLD_STANDARD["memarkan"] = "memar"


def load_dataset(path):
    """Load recipe CSV and return list of dicts."""
    recipes = []
    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            recipes.append(row)
    return recipes


def extract_affixed_words(recipes, stopwords):
    """
    Extract unique words from dataset that have Indonesian affixes.
    Applies case folding and tokenization matching preprocessor.py exactly.
    Also returns total word frequencies for context.
    """
    word_freq = Counter()
    
    for r in recipes:
        text = f"{r['title']} {r['ingredients']} {r['instructions']}"
        text = text.lower().strip()
        tokens = TOKEN_RE.findall(text)
        # Filter like preprocessor: remove stopwords and single-char tokens
        tokens = [t for t in tokens if t not in stopwords and len(t) > 1]
        word_freq.update(tokens)
    
    return word_freq


def has_affix(word):
    """Check if a word likely has Indonesian affixes."""
    if len(word) < 4:
        return False
    return bool(AFFIX_PATTERNS.search(word))


def main():
    print("=" * 72)
    print("EVALUASI AKURASI STEMMING SASTRAWI")
    print("Dataset: recipes_final_3000_standardized.csv (3000 resep)")
    print("Stemmer: Sastrawi IndonesianStemmer")
    print("=" * 72)
    
    # 1. Load dataset
    print("\n[1] Memuat dataset...")
    recipes = load_dataset(DATASET_PATH)
    print(f"    Total resep: {len(recipes)}")
    
    # 2. Initialize Sastrawi (same as preprocessor.py)
    print("\n[2] Menginisialisasi Sastrawi stemmer...")
    factory = StemmerFactory()
    stemmer = factory.create_stemmer()
    print("    Stemmer siap.")
    
    # 3. Extract words from dataset
    print("\n[3] Mengekstrak kata dari dataset...")
    word_freq = extract_affixed_words(recipes, STOPWORDS)
    print(f"    Total kata unik (setelah stopword removal): {len(word_freq)}")
    print(f"    Total kemunculan kata: {sum(word_freq.values())}")
    
    # 4. Filter to words in gold standard that actually appear in dataset
    #    Also find affixed words in dataset for additional testing
    print("\n[4] Mencocokkan kata dengan gold standard...")
    
    test_words = {}
    found_in_dataset = 0
    not_in_dataset = 0
    
    for word, expected_root in GOLD_STANDARD.items():
        if word in word_freq:
            test_words[word] = {
                "expected": expected_root,
                "freq": word_freq[word],
                "source": "dataset"
            }
            found_in_dataset += 1
        else:
            # Still test it but mark as from gold standard only
            not_in_dataset += 1
    
    # Also add high-frequency affixed words from dataset not in gold standard
    # to see how stemmer handles them
    additional_affixed = []
    for word, freq in word_freq.most_common():
        if word not in GOLD_STANDARD and has_affix(word) and freq >= 5:
            additional_affixed.append((word, freq))
    
    print(f"    Kata gold standard ditemukan di dataset: {found_in_dataset}")
    print(f"    Kata gold standard tidak di dataset: {not_in_dataset}")
    print(f"    Kata berimbuhan tambahan (freq >= 5): {len(additional_affixed)}")
    
    # 5. Run stemming evaluation
    print("\n[5] Menjalankan evaluasi stemming...")
    
    results_success = []
    results_fail = []
    
    for word, info in sorted(test_words.items()):
        actual = stemmer.stem(word)
        expected = info["expected"]
        freq = info["freq"]
        is_correct = (actual == expected)
        
        entry = {
            "kata": word,
            "hasil_sastrawi": actual,
            "bentuk_dasar_benar": expected,
            "frekuensi": freq,
            "status": "Berhasil" if is_correct else "Gagal"
        }
        
        if is_correct:
            results_success.append(entry)
        else:
            results_fail.append(entry)
    
    # Also evaluate additional affixed words (without gold standard)
    additional_results = []
    for word, freq in additional_affixed[:50]:
        actual = stemmer.stem(word)
        additional_results.append({
            "kata": word,
            "hasil_sastrawi": actual,
            "frekuensi": freq,
        })
    
    total = len(results_success) + len(results_fail)
    success_count = len(results_success)
    fail_count = len(results_fail)
    accuracy = (success_count / total * 100) if total > 0 else 0
    
    # ── Print Results ─────────────────────────────────────────
    
    print("\n" + "=" * 72)
    print("HASIL EVALUASI")
    print("=" * 72)
    
    print(f"\n[RINGKASAN]")
    print(f"   Total kata yang diuji       : {total}")
    print(f"   Stemming berhasil (benar)   : {success_count}")
    print(f"   Stemming gagal (salah)      : {fail_count}")
    print(f"   Akurasi                     : {accuracy:.2f}%")
    print(f"   Rumus: Akurasi = {success_count}/{total} x 100% = {accuracy:.2f}%")
    
    # Show successful examples (min 20)
    print(f"\n{'-' * 72}")
    print(f"[BERHASIL] CONTOH STEMMING BERHASIL ({min(len(results_success), 30)} dari {success_count} ditampilkan)")
    print(f"{'-' * 72}")
    print(f"{'No':<4} {'Kata Berimbuhan':<20} {'Hasil Sastrawi':<18} {'Bentuk Dasar':<18} {'Freq':<6} {'Status'}")
    print(f"{'-' * 72}")
    
    for i, r in enumerate(results_success[:30], 1):
        print(f"{i:<4} {r['kata']:<20} {r['hasil_sastrawi']:<18} {r['bentuk_dasar_benar']:<18} {r['frekuensi']:<6} {r['status']}")
    
    # Show ALL failures
    print(f"\n{'-' * 72}")
    print(f"[GAGAL] STEMMING GAGAL (seluruh {fail_count} data)")
    print(f"{'-' * 72}")
    
    if results_fail:
        print(f"{'No':<4} {'Kata Berimbuhan':<20} {'Hasil Sastrawi':<18} {'Bentuk Dasar':<18} {'Freq':<6} {'Status'}")
        print(f"{'-' * 72}")
        for i, r in enumerate(results_fail, 1):
            print(f"{i:<4} {r['kata']:<20} {r['hasil_sastrawi']:<18} {r['bentuk_dasar_benar']:<18} {r['frekuensi']:<6} {r['status']}")
    else:
        print("   Tidak ada stemming yang gagal.")
    
    # Additional affixed words (informational)
    if additional_results:
        print(f"\n{'-' * 72}")
        print(f"[INFO] KATA BERIMBUHAN TAMBAHAN DARI DATASET (tanpa gold standard)")
        print(f"   Informasi tambahan: kata berimbuhan frekuensi tinggi lainnya")
        print(f"{'-' * 72}")
        print(f"{'No':<4} {'Kata Asli':<25} {'Hasil Sastrawi':<18} {'Freq':<6}")
        print(f"{'-' * 72}")
        for i, r in enumerate(additional_results, 1):
            print(f"{i:<4} {r['kata']:<25} {r['hasil_sastrawi']:<18} {r['frekuensi']:<6}")
    
    # Methodology note
    print(f"\n{'=' * 72}")
    print("METODOLOGI PENENTUAN BENTUK DASAR PEMBANDING")
    print(f"{'=' * 72}")
    print("""
Bentuk dasar pembanding ditentukan berdasarkan:

1. Kaidah Morfologi Bahasa Indonesia:
   - Prefiks  : me-, mem-, men-, meng-, meny-, ber-, di-, ter-, pe-, per-, se-, ke-
   - Sufiks   : -kan, -an, -i, -nya
   - Konfiks  : me-...-kan, ber-...-an, pe-...-an, ke-...-an, per-...-an
   
2. Referensi:
   - KBBI (Kamus Besar Bahasa Indonesia) untuk verifikasi kata dasar
   - Alwi et al., Tata Bahasa Baku Bahasa Indonesia (edisi keempat)
   - Asian, J. (2007) - Effective Techniques for Indonesian Text Retrieval
     (referensi pembuatan Sastrawi)

3. Aturan Khusus:
   - Kata serapan asing (mentega, margarin, peterseli) -> kata itu sendiri
   - Kata dengan awalan palsu (mentimun, terasi, terong) -> kata itu sendiri
   - Konteks kuliner menentukan bentuk dasar yang benar jika ada ambiguitas

4. Catatan:
   - Evaluasi dilakukan pada kata yang benar-benar muncul dalam dataset
     penelitian (recipes_final_3000_standardized.csv, 3000 resep).
   - Pipeline preprocessing yang sama dengan preprocessor.py digunakan:
     case folding -> tokenisasi -> stopword removal -> stemming.
   - Stemmer: Sastrawi.Stemmer.StemmerFactory (library PySastrawi).
""")
    
    # Output summary as JSON for potential further use
    summary = {
        "total_kata_diuji": total,
        "stemming_berhasil": success_count,
        "stemming_gagal": fail_count,
        "akurasi_persen": round(accuracy, 2),
        "rumus": f"{success_count}/{total} x 100% = {accuracy:.2f}%",
        "detail_berhasil": results_success,
        "detail_gagal": results_fail,
    }
    
    with open("stemming_evaluation_results.json", "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    
    print(f"\nHasil lengkap disimpan ke: stemming_evaluation_results.json")
    print(f"{'=' * 72}")


if __name__ == "__main__":
    main()

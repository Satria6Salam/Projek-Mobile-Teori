# SmartReceipt

**Aplikasi Pencatatan Keuangan Pribadi Berbasis OCR On-Device dengan Klasifikasi Kategori Pengeluaran Otomatis Menggunakan Algoritma TF-IDF dan Naive Bayes**

Aplikasi Android (Flutter) yang memindai foto struk belanja, membaca teksnya secara offline, mengekstrak nama toko, tanggal, total, dan setiap barang, lalu mengelompokkan barang ke kategori pengeluaran secara otomatis. Pengguna dapat memeriksa dan mengoreksi hasilnya sebelum disimpan, kemudian melihat rekap, tren, dan analisis perilaku pengeluaran di Dasbor.

> **Status:** hasil proyek sementara (versi pengembangan). Panduan ini ditujukan agar aplikasi dapat dijalankan di laptop lain.

---

## Daftar Isi
1. [Fitur Utama](#1-fitur-utama)
2. [Yang Perlu Disiapkan](#2-yang-perlu-disiapkan)
3. [Langkah Menjalankan (Ringkas)](#3-langkah-menjalankan-ringkas)
4. [Langkah Menjalankan (Rinci)](#4-langkah-menjalankan-rinci)
5. [Cara Mencoba Aplikasi](#5-cara-mencoba-aplikasi)
6. [Menjalankan Pengujian Otomatis](#6-menjalankan-pengujian-otomatis)
7. [Memasang Lewat File APK (Tanpa Flutter)](#7-memasang-lewat-file-apk-tanpa-flutter)
8. [Membuat File APK](#8-membuat-file-apk)
9. [Pemecahan Masalah](#9-pemecahan-masalah)
10. [Struktur Folder](#10-struktur-folder)
11. [Teknologi](#11-teknologi)
12. [Keterbatasan](#12-keterbatasan)
13. [Tim Pengembang](#13-tim-pengembang)

---

## 1. Fitur Utama
- **Scan struk** dari Kamera, Galeri, atau File (JPG, PNG, WEBP, BMP, GIF, HEIC).
- **OCR on-device** (Google ML Kit), berjalan tanpa internet.
- **Klasifikasi per barang** dengan TF-IDF dan Multinomial Naive Bayes (ditulis murni Dart). Satu struk dapat berisi beberapa kategori.
- **Validasi hasil scan:** ubah nama toko, tanggal (ketik atau kalender), total, serta nama, jumlah, harga, dan kategori setiap barang.
- **Dasbor:** ringkasan, rekap per kategori, tren harian/bulanan/tahunan, analisis perilaku, toko favorit, dan pencarian periode (tanggal, bulan, tahun).
- **Akun lokal:** registrasi dan login dengan validasi ketat serta pembatasan percobaan login.
- **6 kategori:** Konsumsi, Transportasi, Kesehatan, Belanja, Elektronik, Lainnya.

## 2. Yang Perlu Disiapkan

### Perangkat keras
- Laptop Windows 10/11 (64-bit), macOS, atau Linux. Panduan ini memakai contoh perintah **Windows (PowerShell)**.
- RAM minimal 8 GB (disarankan 16 GB bila memakai emulator Android).
- Ruang disk kosong sekitar 15 GB (Flutter, Android SDK, dan emulator).
- Koneksi internet untuk instalasi pertama dan build pertama.

### Perangkat lunak

| Perangkat lunak | Keterangan |
|---|---|
| **Git** | Untuk mengunduh kode dari repositori. Bila kode diterima sebagai file ZIP, Git tidak wajib. |
| **Flutter SDK** | Versi **3.27 atau lebih baru** (Dart 3.5 atau lebih baru). Versi yang dipakai pengembang: **[isi hasil `flutter --version`]**. |
| **Android Studio** | Sumber Android SDK, emulator, dan JDK. |
| **VS Code** (opsional) | Editor dengan ekstensi *Flutter* dan *Dart*. |
| **Perangkat uji** | Emulator Android (API 24 atau lebih baru) **atau** HP Android asli dengan kabel USB. |

> **Android:** aplikasi memerlukan `minSdk` 21 atau lebih tinggi (syarat Google ML Kit). Sebaiknya uji pada Android 7.0 (API 24) atau lebih baru.

## 3. Langkah Menjalankan (Ringkas)

Bagi yang sudah memiliki Flutter dan perangkat Android siap pakai:

```powershell
git clone [isi-tautan-repositori] smart_receipt
cd smart_receipt
flutter pub get
flutter devices
flutter run
```

Bila belum menyiapkan Flutter atau Android, ikuti langkah rinci di bawah.

## 4. Langkah Menjalankan (Rinci)

### Langkah 1 - Pasang Git (opsional)
Unduh dari <https://git-scm.com/downloads> dan pasang dengan pengaturan bawaan. Periksa:
```powershell
git --version
```

### Langkah 2 - Pasang Flutter SDK
1. Ikuti panduan resmi: <https://docs.flutter.dev/get-started/install>
2. Ekstrak SDK ke folder **tanpa spasi dan tanpa izin khusus**, misalnya `C:\src\flutter` (jangan di `C:\Program Files`).
3. Tambahkan `C:\src\flutter\bin` ke **PATH**:
   - Cari "Edit the system environment variables", lalu *Environment Variables*.
   - Pilih `Path` pada *User variables*, klik *Edit*, *New*, lalu isi `C:\src\flutter\bin`.
4. **Tutup dan buka kembali** PowerShell, lalu periksa:
```powershell
flutter --version
```

### Langkah 3 - Pasang Android Studio dan Android SDK
1. Unduh dan pasang Android Studio: <https://developer.android.com/studio>
2. Buka Android Studio, lalu ikuti *Setup Wizard* hingga komponen Android SDK terpasang.
3. Buka **More Actions, SDK Manager, SDK Tools**, lalu centang dan pasang:
   - *Android SDK Command-line Tools (latest)*
   - *Android SDK Platform-Tools*
4. Terima semua lisensi:
```powershell
flutter doctor --android-licenses
```
(ketik `y` setiap kali ditanya)

### Langkah 4 - Aktifkan Developer Mode (khusus Windows)
Flutter membutuhkan dukungan *symlink* untuk plugin. Jalankan:
```powershell
start ms-settings:developers
```
Lalu nyalakan **Developer Mode**.

### Langkah 5 - Periksa kesiapan
```powershell
flutter doctor
```
Pastikan bagian **Flutter**, **Android toolchain**, dan **Connected device** bertanda centang hijau. Tanda seru pada bagian *Visual Studio* atau *Chrome* **boleh diabaikan** karena aplikasi ini hanya untuk Android.

### Langkah 6 - Siapkan perangkat uji

**Pilihan A: Emulator Android**
1. Android Studio, lalu **More Actions, Virtual Device Manager, Create Device**.
2. Pilih perangkat (mis. *Pixel 6*), pilih citra sistem **API 34** (unduh bila belum ada), lalu *Finish*.
3. Klik tombol *Play* untuk menyalakan emulator.

**Pilihan B: HP Android asli** (lebih ringan dan lebih cepat)
1. Buka **Pengaturan, Tentang ponsel**, lalu ketuk **Nomor build** 7 kali untuk mengaktifkan *Opsi pengembang*.
2. Buka **Opsi pengembang** dan nyalakan **Debugging USB**.
3. Sambungkan HP ke laptop dengan kabel USB, lalu izinkan debugging USB pada pop-up di layar HP.

Periksa bahwa perangkat terdeteksi:
```powershell
flutter devices
```

### Langkah 7 - Dapatkan kode sumber
**Dari Git:**
```powershell
git clone [isi-tautan-repositori] smart_receipt
cd smart_receipt
```
**Dari file ZIP:** ekstrak, lalu buka PowerShell di dalam folder proyek (folder yang berisi `pubspec.yaml`).

> **Penting:** nama folder proyek harus **`smart_receipt`**, sama dengan baris `name: smart_receipt` di `pubspec.yaml`. Bila berbeda, kode tetap berjalan, tetapi berkas tes akan gagal mengimpor paket.

### Langkah 8 - Unduh dependensi
```powershell
flutter pub get
```
Pastikan berakhir dengan pesan `Got dependencies!`.

### Langkah 9 - Jalankan aplikasi
```powershell
flutter run
```
Bila ada lebih dari satu perangkat, pilih salah satu atau tentukan langsung:
```powershell
flutter run -d <id-perangkat>
```

> **Build pertama lama (3-10 menit)** karena Gradle mengunduh dependensi dan ML Kit. Pastikan internet aktif. Build berikutnya jauh lebih cepat.

Saat menjalankan mode debug, tombol berguna di terminal: `r` (hot reload), `R` (hot restart), `q` (keluar).

## 5. Cara Mencoba Aplikasi

Aplikasi **tidak memiliki akun bawaan**. Daftarkan akun baru terlebih dahulu.

1. **Registrasi:** pada layar Login tekan **Daftar Akun Baru**.
   - Nama: huruf saja, mis. `Budi Santoso`
   - Email: mis. `uji@mail.com`
   - Password: minimal 8 karakter, mengandung huruf dan angka, mis. `Uji12345`
2. **Login** dengan akun tersebut. Sesi login tersimpan, sehingga tidak perlu login ulang saat aplikasi dibuka kembali.
3. **Scan struk:** di Dasbor tekan **Scan Struk**, lalu pilih sumber:
   - **Kamera:** foto struk langsung.
   - **Galeri / File:** pilih foto struk yang tersimpan.
4. **Pratinjau:** periksa hasil bacaan. Ketuk sebuah barang untuk mengubah nama, jumlah, harga, atau kategorinya. Ubah nama toko, tanggal (ketik `dd/mm/yyyy`), atau total bila perlu.
5. **Simpan Transaksi.** Dasbor langsung menampilkan total, rekap kategori, dan analisis.
6. **Cari periode:** tekan ikon kaca pembesar di Dasbor, lalu pilih *Tanggal*, *Bulan*, atau *Tahun*, misalnya ketik tahun `2019`.
7. **Tren:** gulir Dasbor ke bawah untuk **Tren Bulanan** dan **Tren Tahunan**. Ketuk batang lalu **Lihat** untuk membuka periode itu.

### Tips menguji pemindaian
- Gunakan foto struk yang **terang, tajam, rata, dan seluruh struk masuk bingkai**.
- **Di emulator**, kamera hanya menampilkan pemandangan virtual. Cara termudah: **seret file foto struk dari laptop ke jendela emulator**, lalu pilih lewat **Galeri** atau **File**. Alternatifnya, atur gambar kamera virtual lewat *Extended controls, Camera*.
- Tanggal pada struk bisa tahun lampau (mis. 2019). Gunakan pencarian periode di Dasbor untuk melihatnya.
- Barang yang kategorinya kurang diyakini AI ditandai **"Perlu dicek"**. Koreksi kategorinya, dan model akan belajar dari koreksi tersebut pada scan berikutnya.

### Tanda aplikasi berjalan benar
Pada terminal (mode debug), setelah aplikasi terbuka akan muncul baris seperti:
```
[SmartReceipt] Database siap. Kategori awal: Konsumsi, Transportasi, Kesehatan, Belanja, Lainnya, Elektronik
```

## 6. Menjalankan Pengujian Otomatis
Tes tidak membutuhkan emulator atau HP.
```powershell
flutter analyze
flutter test
```
Hasil yang diharapkan: `flutter analyze` menampilkan `No issues found!` dan `flutter test` menampilkan `All tests passed!` (67 butir uji).

## 7. Memasang Lewat File APK (Tanpa Flutter)
Cara tercepat bila hanya ingin **mencoba aplikasi** tanpa memasang Flutter.

1. Dapatkan berkas `smart_receipt_release_candidate_v1.0.apk` dari tautan: **[isi tautan Google Drive]**.
2. Salin ke HP Android (kabel USB, Drive, atau pesan).
3. Buka berkas APK di HP. Bila diminta, izinkan **Instal aplikasi dari sumber ini / aplikasi tidak dikenal**.
4. Ketuk **Pasang**, lalu buka aplikasi **SmartReceipt**.
5. Saat pertama kali memakai kamera, ketuk **Izinkan** pada permintaan izin.

> Bila Play Protect menampilkan peringatan, itu normal untuk aplikasi di luar Play Store. Pilih **Tetap pasang**.

## 8. Membuat File APK
```powershell
flutter clean
flutter pub get
flutter build apk --release
```
Hasil: `build\app\outputs\flutter-apk\app-release.apk`. Ukuran lebih kecil per arsitektur:
```powershell
flutter build apk --release --split-per-abi
```
Bila muncul galat terkait *tree shaking* ikon, tambahkan `--no-tree-shake-icons`.

## 9. Pemecahan Masalah

| Gejala | Penyebab dan solusi |
|---|---|
| `flutter` tidak dikenali | Folder `flutter\bin` belum ada di PATH, atau terminal belum dibuka ulang. Ulangi Langkah 2. |
| `Building with plugins requires symlink support` | Developer Mode Windows belum aktif. Jalankan `start ms-settings:developers` dan nyalakan. |
| `cmdline-tools component is missing` | Pasang *Android SDK Command-line Tools* lewat SDK Manager, lalu `flutter doctor --android-licenses`. |
| `Unable to locate Android SDK` | Arahkan secara manual: `flutter config --android-sdk "C:\Users\<nama>\AppData\Local\Android\Sdk"` |
| `flutter devices` tidak menampilkan perangkat | Emulator belum menyala; atau USB debugging belum aktif / izin belum diberikan di HP; coba kabel atau port USB lain. |
| Build Gradle gagal atau lama | Pastikan internet aktif, lalu `flutter clean` dan `flutter run` lagi. Bila galat soal JDK: `flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"` |
| Galat `minSdkVersion` / ML Kit | Buka `android/app/build.gradle` (atau `build.gradle.kts`) dan pastikan `minSdk` bernilai **21 atau lebih**. |
| `The getter 'xxx' isn't defined for the class 'LucideIcons'` | Nama ikon tidak tersedia pada versi paket. Ubah satu baris terkait di `lib/core/theme/app_icons.dart`. |
| `Target of URI doesn't exist: package:smart_receipt/...` | Nama paket berbeda. Pastikan `name: smart_receipt` di `pubspec.yaml`, folder `test/` berada di folder utama (sejajar `lib/`), lalu `flutter pub get`. |
| `pub get` gagal | Periksa internet. Bila konflik versi: `flutter pub upgrade --major-versions`. |
| Aplikasi langsung tertutup setelah pembaruan skema | Hapus data lama: copot pasang aplikasi dari perangkat, lalu `flutter run` lagi. |
| Kamera tidak terbuka | Izinkan akses kamera di **Pengaturan, Aplikasi, SmartReceipt, Izin**. Di emulator, gunakan Galeri atau File. |
| Tampilan terasa patah-patah | Mode debug lebih lambat. Coba `flutter run --release` pada HP asli. |
| Font berbeda dari desain | Font diunduh dari internet saat pertama dijalankan. Tanpa internet, aplikasi memakai font cadangan, dan fungsi tetap normal. |
| Pesan "Gambar Tidak Jelas, Silakan Ulangi" | Foto terlalu buram atau gelap. Foto ulang dengan cahaya cukup dan posisi rata. |
| Format file ditolak | Gunakan JPG, PNG, WEBP, BMP, GIF, atau HEIC (maksimal 25 MB). PDF belum didukung. |

Bila masalah tetap ada, jalankan `flutter doctor -v` dan salin hasilnya bersama pesan galat lengkap untuk dianalisis.

## 10. Struktur Folder
```
smart_receipt/
├── pubspec.yaml            # dependensi dan konfigurasi proyek
├── README.md
├── android/                # konfigurasi Android
├── lib/
│   ├── main.dart           # titik masuk aplikasi dan pendaftaran Provider
│   ├── core/               # tema, rute (GoRouter), konstanta, formatter, periode Dasbor
│   ├── data/
│   │   ├── database/       # SQLite: skema dan migrasi (versi 3)
│   │   ├── models/         # model data (8 tabel)
│   │   └── repositories/   # akses data (CRUD dan agregasi)
│   ├── services/           # OCR, parsing, ML (TF-IDF + Naive Bayes), analisis, gambar
│   ├── viewmodels/         # Auth, Scan, Dashboard, Profile (MVVM)
│   └── views/              # layar dan widget antarmuka
└── test/                   # pengujian otomatis (67 butir)
```

Arsitektur: **MVVM**. View hanya menampilkan antarmuka, ViewModel mengelola status, dan Services menangani logika berat (OCR, Regex, ML).

## 11. Teknologi
Flutter (Dart); `sqflite`; `google_mlkit_text_recognition`; `image_picker`; `file_picker`; `provider`; `go_router`; `google_fonts`; `lucide_icons_flutter`; `intl`; `crypto`; `shared_preferences`.

Algoritma klasifikasi (TF-IDF dan Multinomial Naive Bayes), parsing struk, dan analisis perilaku ditulis sendiri dalam Dart tanpa pustaka eksternal.

## 12. Keterbatasan
- Format **PDF belum didukung**; HEIC bergantung pada dukungan versi Android.
- Transaksi yang **sudah tersimpan belum dapat diedit** dari antarmuka (koreksi dilakukan sebelum menyimpan, atau hapus lalu pindai ulang).
- Akurasi bergantung pada kualitas foto dan cakupan data latih; format struk yang sangat berbeda dapat meleset, sehingga validasi pengguna tetap diperlukan.
- Diuji pada Android; iOS belum diuji.
- Data tersimpan **lokal di perangkat**; belum ada pencadangan atau sinkronisasi.

## 13. Tim Pengembang
**Kelas D, Kelompok 5**
- Satria Badrus Salam (240605110201)
- Muh. Reza Zulfikar (240605110196)
- Dian Febrian Nur C. (240605110189)

Dosen Pengampu: **Supriyono, M.Kom**

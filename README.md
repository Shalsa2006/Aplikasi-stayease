# StayEase — Aplikasi Pemesanan Hotel

StayEase adalah aplikasi pemesanan hotel berbasis **Flutter** (frontend) yang berkomunikasi dengan **REST API Node.js + Express** (backend) dan menyimpan data di **MySQL (Laragon)**. Tidak memakai Supabase/Firebase — semua data lewat API buatan sendiri dengan autentikasi **JWT**.

**Permasalahan yang diangkat:** pemesanan hotel kecil/menengah di daerah masih banyak dilakukan manual (telepon/WhatsApp), sehingga sering terjadi *overbooking*, informasi ketersediaan kamar tidak real-time, dan riwayat pemesanan tidak tercatat. StayEase menyediakan pencarian hotel, cek ketersediaan kamar per tanggal secara real-time, pemesanan dengan pencegahan overbooking (transaksi database + row locking), simulasi pembayaran, serta ulasan tamu.

## Fitur

Pengguna dan admin login dari halaman yang sama, tetapi **tampilan & fiturnya berbeda** (ditentukan dari `role` akun).

| Pengguna (tema ungu–pink) | Admin (tema biru, label ADMIN) |
|---|---|
| Registrasi & login (JWT) | **Dashboard**: pendapatan, kamar terpesan hari ini, menunggu bayar, rating rata-rata, hotel per kota, pesanan terbaru |
| Cari hotel (36 hotel di 6 kota), filter kota, urutkan harga/rating | **Pesanan**: semua pesanan semua pengguna, filter status, cari kode/nama/email, detail kamar yang dipesan + ubah status |
| Lihat sisa kamar real-time, pesan beberapa kamar, total otomatis | **Kamar**: kamar yang terpesan per tanggal, per hotel & tipe kamar, lengkap dengan nama tamu |
| Bayar via Virtual Account / QRIS + bukti pembayaran | **Hotel**: tambah/ubah/hapus hotel & tipe kamar, pilih foto |
| Hotel **Disukai** (♡) | **Ulasan**: semua rating & ulasan, filter per bintang, hapus ulasan |
| **Beri rating & ulasan** setelah membayar (bintang + tag + komentar) | |
| Ringkasan rating per hotel (grafik per bintang), halaman **Ulasan Saya** | |

## Struktur Folder

```
stayease/
├── backend/                 # REST API
│   ├── database/schema.sql  # tabel + data contoh hotel & kamar
│   ├── database/seed.js     # akun admin & user contoh
│   ├── src/
│   │   ├── config/db.js     # koneksi MySQL Laragon
│   │   ├── controllers/     # auth, hotel, booking, admin
│   │   ├── middleware/      # JWT & error handler
│   │   ├── routes/index.js  # daftar endpoint
│   │   └── server.js
│   └── api-test.http        # contoh request untuk uji API
└── mobile/                  # Aplikasi Flutter
    ├── assets/images/       # foto hotel & kamar (dipakai lewat image_url "assets/images/...")
    └── lib/
        ├── config/          # URL API & tema (warna diatur di theme.dart)
        ├── models/          # User, Hotel, Room, Booking
        ├── services/        # pemanggilan API
        ├── providers/       # state login (Provider)
        ├── screens/         # halaman-halaman
        └── widgets/
```

---

## Cara Menjalankan

### 1. Siapkan Laragon
1. Install **Laragon Full** (sudah termasuk MySQL, HeidiSQL, dan Node.js).
2. Buka Laragon → klik **Start All**.
3. Pastikan Node.js tersedia: buka **Terminal** Laragon, ketik `node -v`. Jika versi < 18, install Node.js LTS dari nodejs.org.

### 2. Buat database
Pilih salah satu:
- **HeidiSQL:** Laragon → **Database** → buka koneksi → *File → Load SQL file…* → pilih `backend/database/schema.sql` → tekan **F9** (Run).
- **Terminal Laragon:** dari folder `backend`, jalankan `mysql -u root < database/schema.sql`

Database `stayease_db` akan berisi 36 hotel (6 hotel × 6 kota: Surabaya, Malang, Yogyakarta, Bali, Jakarta, Bandung) dan 93 tipe kamar. `npm run seed` juga membuat pesanan selesai + ulasan contoh supaya setiap hotel sudah punya rating.

> **Update dari versi sebelumnya?** Skema berubah (tabel `favorites`, kolom pembayaran & jumlah kamar). Import ulang `schema.sql` lalu jalankan `npm run seed` lagi. Data lama akan terhapus.

### 3. Jalankan backend
Di Terminal Laragon:
```bash
cd backend
copy .env.example .env     # (Linux/Mac: cp .env.example .env)
npm install
npm run seed               # membuat akun contoh
npm run dev                # server di http://localhost:3000
```
Akun contoh:
- Admin: `admin@stayease.id` / `admin123` → masuk ke tampilan admin
- User: `budi@mail.com` / `user123` (juga `siti@`, `andi@`, `rina@`, `dewi@mail.com`, password sama)

Cek di browser: `http://localhost:3000/api/hotels` harus menampilkan JSON daftar hotel.

> Default Laragon: user `root`, password kosong, port 3306. Jika kamu mengubahnya, sesuaikan di `.env`.

### 4. Jalankan aplikasi Flutter
```bash
cd mobile
flutter create . --project-name stayease --platforms android,web
flutter pub get
```
`flutter create .` hanya membuat folder platform (android/web) yang belum ada; kode di `lib/` tidak ditimpa.

**Wajib untuk Android** — izinkan koneksi HTTP lokal. Buka `mobile/android/app/src/main/AndroidManifest.xml`, lalu:
1. Tambahkan baris izin internet tepat di bawah tag `<manifest ...>`
2. Tambahkan atribut `android:usesCleartextTraffic="true"` pada tag `<application`

Hasilnya kira-kira:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="StayEase"
        android:usesCleartextTraffic="true"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ...isi bawaan biarkan seperti semula... -->
```

Jalankan:
```bash
# Emulator Android (default http://10.0.2.2:3000/api)
flutter run

# Chrome / Flutter Web
flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api

# HP fisik (satu WiFi dengan laptop; cek IP laptop dengan `ipconfig`)
flutter run --dart-define=API_URL=http://192.168.1.10:3000/api
```
Untuk HP fisik, izinkan port 3000 di Windows Firewall bila koneksi ditolak.

---

## Dokumentasi API

Base URL: `http://localhost:3000/api` · Format respons: `{ "success": true, "message": "...", "data": ... }`
Endpoint bertanda 🔒 butuh header `Authorization: Bearer <token>`.

| Method | Endpoint | Keterangan |
|---|---|---|
| POST | `/auth/register` | Daftar (`name, email, password, phone`) |
| POST | `/auth/login` | Login → `token`, `user` |
| GET 🔒 | `/auth/me` | Profil user login |
| PUT 🔒 | `/auth/me` | Ubah profil (`name, phone, password?`) |
| GET | `/hotels` | Daftar hotel. Query: `q, city, guests, min_price, max_price, sort=price_asc\|price_desc\|rating` |
| GET | `/hotels/cities` | Daftar kota |
| GET | `/hotels/:id` | Detail hotel + kamar + ulasan + `rating_breakdown`. Query `check_in, check_out` → sisa kamar |
| GET 🔒 | `/reviews/me` | Ulasan yang pernah ditulis user |
| GET | `/rooms/:id/availability` | Cek ketersediaan & total harga |
| POST 🔒 | `/hotels/:id/reviews` | Ulasan (`booking_id, rating 1-5, comment`) |
| POST 🔒 | `/bookings` | Buat pesanan (`room_id, check_in, check_out, guests, rooms, guest_name, guest_phone, notes`) — total = harga × malam × kamar |
| GET 🔒 | `/bookings` | Pesanan saya (`?status=`) |
| GET 🔒 | `/bookings/:id` | Detail pesanan |
| POST 🔒 | `/bookings/:id/payment` | Buat tagihan: `{method:"va", bank:"BCA"}` atau `{method:"qris"}` → nomor VA / kode QRIS, biaya layanan, jumlah bayar, batas waktu 24 jam |
| PATCH 🔒 | `/bookings/:id/pay` | Simulasi konfirmasi bayar → status `paid` + `receipt_number` (nomor bukti) |
| GET 🔒 | `/favorites` | Daftar hotel disukai |
| POST/DELETE 🔒 | `/hotels/:id/favorite` | Tambah / hapus hotel dari Disukai |
| PATCH 🔒 | `/bookings/:id/cancel` | Batalkan pesanan |
| GET 🔒👑 | `/admin/stats` | Statistik dashboard (pendapatan, kamar terpesan hari ini, rating, per kota, pesanan terbaru) |
| POST/PUT/DELETE 🔒👑 | `/admin/hotels[/:id]` | Kelola hotel |
| POST/PUT/DELETE 🔒👑 | `/admin/rooms[/:id]` | Kelola kamar |
| GET 🔒👑 | `/admin/bookings` | Semua booking + data pemesan & kamar. Query `status, q` |
| GET 🔒👑 | `/admin/rooms/booked?date=` | Kamar yang terpesan pada tanggal tertentu (per tipe kamar + daftar tamu) |
| GET 🔒👑 | `/admin/reviews` | Semua ulasan. Query `rating` |
| DELETE 🔒👑 | `/admin/reviews/:id` | Hapus ulasan |
| PATCH 🔒👑 | `/admin/bookings/:id/status` | Ubah status booking |

👑 = khusus role admin. Contoh request lengkap ada di `backend/api-test.http`.

**Pembayaran (simulasi):** biaya layanan VA Rp 4.000, QRIS 0,7% (dibulatkan ke atas). Nomor VA = kode bank + 4 digit akhir no. HP + 6 digit acak. Setelah dikonfirmasi, sistem menerbitkan nomor bukti `INV/YYYYMMDD/METODE/...`. Tidak ada uang sungguhan — untuk produksi, ganti dengan payment gateway (Midtrans/Xendit).

**Logika ketersediaan:** jumlah kamar terpakai = total kolom `rooms` dari booking berstatus `pending`/`paid` yang tanggalnya beririsan (`check_in < checkout_baru AND check_out > checkin_baru`). Saat membuat booking, baris kamar dikunci (`SELECT … FOR UPDATE`) di dalam transaksi supaya dua pemesanan bersamaan tidak melebihi stok.

---

## Teknologi
Flutter 3.27+ · Dart 3.6+ · Provider · http · barcode_widget · Node.js · Express · mysql2 · bcryptjs · jsonwebtoken · MySQL (Laragon)

## Mengganti Foto & Warna

**Foto hotel/kamar**
1. Simpan foto baru (JPG/PNG, lebar ±900 px agar ringan) di `mobile/assets/images/`, misalnya `hotel_7.jpg`.
2. Isi kolom `image_url` di tabel `hotels` atau `rooms` dengan `assets/images/hotel_7.jpg` (lewat HeidiSQL, atau endpoint admin `PUT /admin/hotels/:id`).
3. Foto baru di folder assets butuh **restart penuh** aplikasi (stop lalu `flutter run` lagi), hot reload tidak cukup.
4. Bisa juga memakai URL internet: isi `image_url` dengan `https://...` — tidak perlu restart.

**Warna aplikasi** — semua ada di `mobile/lib/config/theme.dart`:
- `primary`, `pink`, `orange`, `accent`, `sky`, `mint` → warna utama.
- `mainGradient` → gradasi header, tombol, dan kartu kode booking. Ubah daftar `colors` untuk mengganti gradasi.
- `rainbow` → warna-warni chip kota, fasilitas, dan kartu hotel.

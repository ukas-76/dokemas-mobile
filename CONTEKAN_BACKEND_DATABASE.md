# 🎯 CONTEKAN PRESENTASI: BACKEND & DATABASE DOKEMAS BANYUMAS
> **Panduan Ringkas & Jawaban Siap Pakai untuk Presentasi, Demo, dan Tanya-Jawab Penguji**  
> *Sistem Terdistribusi: Mobile (Flutter), Web Portal (Mitra & Wisatawan), Desktop Admin Panel*

---

## 📌 Ringkasan Eksekutif (Buka dengan 30 Detik Ini)
> *"Platform DOKEMAS Banyumas mengadopsi **Arsitektur Sistem Terdistribusi**. Backend Laravel 11 bertindak sebagai **Single Source of Truth (Pusat Data Tunggal)** yang melayani tiga klien sekaligus: aplikasi Android/iOS (Flutter), Web Portal Mitra, dan Web Admin Dinporabudpar melalui REST API berformat JSON. Untuk menjamin persistensi data tanpa risiko hilang saat server restart, seluruh basis data disimpan di **TiDB Cloud (Distributed SQL AWS Singapore)** yang terenkripsi SSL."*

---

## 1. Arsitektur Sistem Terdistribusi (Distributed Architecture)

### 🔹 Konsep Utama
* **Client-Server & Stateless:** Klien (Mobile, Web, Desktop) tidak berhubungan langsung dengan database. Semua pertukaran data melalui protokol **HTTP/HTTPS** dengan format payload standar **JSON**.
* **Single Source of Truth:** Jika seorang Mitra mendaftarkan tempat wisata baru melalui Web, seketika data tersebut masuk ke database pusat. Setelah diverifikasi oleh Admin melalui Desktop Panel, data tersebut langsung muncul secara *real-time* di aplikasi Mobile wisatawan tanpa perlu update aplikasi (*zero-client update*).

### 🔹 Diagram Alur Komunikasi
```
 [ Mobile App (Flutter) ]       [ Web Mitra / Wisatawan ]       [ Desktop Admin Web ]
            │                               │                             │
            └───────────────────────┬───────┴─────────────────────────────┘
                                    │ (JSON via HTTPS)
                                    ▼
                      [ Gateway / Reverse Proxy ]
               (Ngrok Static Tunnel / Cloud Load Balancer)
                                    │
                                    ▼
                     [ Docker Container Backend ]
               ┌────────────────────────────────────────┐
               │  • Nginx (Web Server Port 80)          │
               │  • PHP 8.2 FPM (FastCGI Engine)        │
               │  • Laravel 11 Framework (REST API)     │
               │  • Supervisor (Process Manager PID 1)  │
               └───────────────────┬────────────────────┘
                                   │ (MySQL Protocol via TLS/SSL)
                                   ▼
             [ TiDB Cloud Serverless (AWS Singapore) ]
             (High Availability, Multi-AZ, Permanent DB)
```

---

## 2. Perancangan API & Keamanan (API Design & Security)

### 🔹 Skema Autentikasi & RBAC (Role-Based Access Control)
* **Teknologi:** **Laravel Sanctum (Token-Based Authentication)**.
* **Tiga Level Peran (Role):**
  1. `user` (Wisatawan): Mencari destinasi, membuat ulasan, menyusun *itinerary*, menyimpan *wishlist*.
  2. `mitra` (Pengelola Destinasi): Mendaftar via form 4 langkah, mengelola 1 destinasi miliknya (`/api/mitra/*`).
  3. `admin` (Dinas Pariwisata): Dashboard analitik, verifikasi akun mitra, kurasi status publikasi destinasi, moderasi ulasan (`/api/admin/*`).
* **Proteksi Middleware:**
  * `auth:sanctum`: Menolak request tanpa Bearer Token yang valid (HTTP `401 Unauthorized`).
  * `admin`: Memastikan hanya token milik akun dengan `role === 'admin'` yang dapat mengakses endpoint sensitif dinas (HTTP `403 Forbidden`).

### 🔹 Struktur Endpoint Utama
| Kategori | Method & URL | Hak Akses | Fungsi & Validasi Utama |
| :--- | :--- | :--- | :--- |
| **Katalog Publik** | `GET /api/categories` | Publik | Daftar kategori wisata (Alam, Budaya, Kuliner, dll). |
| **Katalog Publik** | `GET /api/destinations` | Publik | Otomatis difilter hanya menampilkan destinasi `status = 'published'`. |
| **Autentikasi** | `POST /api/login` | Publik | Validasi email & password, mengembalikan `token` Sanctum. |
| **Kemitraan** | `POST /api/mitra/register`| Publik/User | Form 4 Langkah: Validasi NIK, NIB, berkas legalitas, info rekening, dan 1 profil destinasi baru (`status: pending`). |
| **Portal Mitra** | `GET /api/mitra/status` | Mitra | Memeriksa status verifikasi akun mitra & destinasi miliknya. |
| **Portal Mitra** | `POST /api/mitra/destinations`| Mitra | **Aturan Bisnis Ketat:** Ditolak jika mitra sudah punya 1 destinasi (*1 Mitra = 1 Destinasi*). |
| **Kurasi Admin** | `PATCH /api/admin/destinations/{id}/status` | Admin | Kurasi konten wisata: Mengubah status (`pending` ➔ `published` / `draft`). |
| **Verifikasi** | `POST /api/admin/mitra-applications/{id}/approve` | Admin | Memverifikasi legalitas akun mitra tanpa mempublikasikan destinasi secara membabi-buta (*decoupled approval*). |

### 🔹 Mekanisme Validasi & Sanitasi Data
* **Laravel Form Request / Controller Validation:** Setiap input dicek tipe data, panjang string, keunikan email (`unique:users,email`), dan format file.
* **Auto-Conversion Image Service:** File gambar yang diunggah dikonversi otomatis menjadi format **WebP** terkompresi untuk menghemat bandwidth mobile hingga 60%.
* **SQL Injection & XSS Protection:** Semua query menggunakan **PDO Prepared Statements** bawaan Eloquent ORM, sehingga terproteksi dari injeksi SQL.

---

## 3. Struktur Database & Persistensi Data (Cloud DB)

### 🔹 Mengapa Menggunakan Cloud Database (TiDB Cloud Serverless)?
1. **Masalah Container Ephemeral (Anti Data Hilang):**
   * Jika database ditaruh di dalam container Docker lokal, saat container di-restart, di-update, atau crash, seluruh data tiket, ulasan, dan mitra akan **terhapus permanen**.
   * Dengan **TiDB Cloud AWS Singapore**, database berjalan di cluster terpisah (*decoupled compute & storage*). Server backend bisa di-restart ratusan kali, data tetap aman 100%.
2. **Konektivitas Multi-Platform:**
   * Backend lokal, server cloud (SnapDeploy), pengembang web, dan tim mobile dapat mengakses database yang sama secara simultan tanpa konflik.
3. **Kompatibilitas MySQL & Skalabilitas:**
   * TiDB 100% kompatibel dengan protokol MySQL 8.0, mendukung ACID Transaction, dan memiliki fitur *auto-scaling* jika lonjakan pengunjung terjadi saat liburan.
4. **Keamanan Transport:**
   * Koneksi wajib menggunakan enkripsi TLS/SSL dengan sertifikat CA (`cacert.pem`).

### 🔹 Relasi Antar-Tabel Utama (ERD Ringkas)
* **`users` 1 : 1 `mitra_profiles`** (Satu akun mitra memiliki satu rekam identitas NIK, NIB, dan rekening pencairan).
* **`users` 1 : N `destinations`** (Di backend dibatasi 1:1 untuk akun mitra demi integritas pengelola).
* **`categories` 1 : N `destinations`** (Setiap destinasi terindeks di bawah 1 kategori utama).
* **`destinations` N : M `facilities`** (Tabel pivot `destination_facilities` menghubungkan fasilitas seperti toilet, musholla, parkir).
* **`destinations` 1 : N `destination_images`** (Menyimpan galeri foto destinasi).
* **`destinations` 1 : N `reviews`** (Ulasan dari wisatawan yang memiliki rating 1–5 bintang).

---

## 4. Deployment & Containerization (Docker, Nginx, PHP-FPM, Supervisor)

### 🔹 Arsitektur Multi-Process Container
Backend DOKEMAS dikemas menggunakan **Docker Multi-Stage Build** yang menggabungkan 3 komponen krusial dalam satu image yang ringkas:
1. **Nginx:** Bertindak sebagai *high-performance reverse proxy* dan melayani file statis / storage gambar.
2. **PHP-FPM 8.2:** Menjalankan eksekusi script PHP Laravel secara cepat menggunakan FastCGI socket.
3. **Supervisor (`supervisord`):** Bertindak sebagai **Process Manager (PID 1)** di dalam container. Jika PHP-FPM atau Nginx mengalami kendala, Supervisor akan langsung me-restart proses tersebut secara otomatis dalam hitungan milidetik (*auto-healing*).

### 🔹 Keunggulan Docker Multi-Stage Build
* **Ukuran Image Sangat Kecil:** Menggunakan base image **Alpine Linux**. Dependency build (Node.js, build tools) dibuang di stage pertama, hanya menyisakan binary runtime di stage akhir.
* **OPcache Enabled:** Seluruh kode Laravel di-precompile ke memori RAM, mempercepat *response time* API hingga 3x lipat dibanding Apache konvensional.

### 🔹 Strategi Dual-Hosting untuk Demo & Pengujian
* **Jalur Cloud Container:** Aplikasi dikemas dan siap dideploy ke platform cloud modern (SnapDeploy/Docker registry).
* **Jalur High-Availability Local Tunnel (Ngrok Static Domain):**
  * Disediakan script sekali klik [`start_server_ngrok.bat`](file:///c:/Users/sapta/Documents/dokemas-mobile/start_server_ngrok.bat).
  * Menjalankan backend lokal yang langsung terhubung ke **TiDB Cloud AWS** dan dibungkus oleh domain publik statis:  
    `https://nomadically-premethodical-bobbye.ngrok-free.dev`
  * Memberikan kestabilan maksimal saat demo tatap muka tanpa kendala lag server gratisan.

---

## 5. Tanya - Jawab Cepat (Cheat Sheet Menjawab Pertanyaan Dosen / Penguji)

### ❓ Q1: *"Kenapa memilih arsitektur terpisah (API Backend) bukannya Monolith (Laravel Blade saja)?"*
> **Jawaban:**  
> *"Karena DOKEMAS menargetkan ekosistem multi-platform: aplikasi Mobile (Flutter untuk wisatawan yang butuh GPS dan fluid animation), Web Portal (Mitra untuk kemudahan ketik data dan upload berkas di laptop), dan Web Desktop (Admin dinas). Dengan REST API, backend cukup dibuat satu kali dan bisa digunakan bersamaan oleh klien mana pun tanpa duplikasi logika bisnis."*

### ❓ Q2: *"Bagaimana sistem menjamin mitra tidak bisa curang membuat banyak destinasi?"*
> **Jawaban:**  
> *"Kami menerapkan validasi berlapis. Di level controller (`Api\Mitra\DestinationController@store`), sistem mengecek apakah `user_id` pengelola sudah memiliki data di tabel `destinations`. Jika sudah ada, sistem melempar HTTP 422 dengan pesan penolakan. Selain itu, destinasi yang baru didaftarkan statusnya wajib `pending`, sehingga tidak akan pernah tayang di aplikasi wisatawan sebelum diverifikasi manual oleh admin dinas."*

### ❓ Q3: *"Mengapa foto destinasi di mobile dan web admin bisa sinkron?"*
> **Jawaban:**  
> *"Model `Destination` di backend telah dilengkapi Eloquent Accessor ganda (`thumbnail`, `thumbnail_url`, `image`, `image_url`, `cover_image`). Baik aplikasi Flutter maupun Web React/Vue yang memanggil properti berbeda akan menerima URL foto yang sama secara konsisten."*

### ❓ Q4: *"Jika laptop server mati atau Docker di-restart, apakah data pendaftaran mitra akan hilang?"*
> **Jawaban:**  
> *"Tidak sama sekali. Karena database kami tidak disimpan di disk lokal container, melainkan di TiDB Cloud Serverless (AWS Singapore). Data tersimpan permanen di cloud storage independen dengan standar transaksi ACID."*

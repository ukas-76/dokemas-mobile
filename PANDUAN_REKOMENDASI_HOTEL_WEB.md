# 📌 Spesifikasi Integrasi: Penginapan & Hotel Terdekat (Web)

Dokumen ini berisi panduan teknis integrasi fitur rekomendasi **Penginapan & Hotel Terdekat** untuk pengembang Web Frontend DOKEMAS Banyumas.

---

## 1. Endpoint API

| Parameter | Keterangan |
| :--- | :--- |
| **URL** | `GET /api/destinations/{id}/nearby-accommodations` |
| **Base URL** | `https://nomadically-premethodical-bobbye.ngrok-free.dev/api` *(atau domain API backend lokal/server)* |
| **Method** | `GET` |
| **Auth** | Publik (Tidak memerlukan token login) |
| **Headers** | `Accept: application/json`<br>`ngrok-skip-browser-warning: true` *(wajib jika lewat tunnel ngrok)* |

### Query Parameter
| Param | Tipe | Default | Keterangan |
| :--- | :--- | :--- | :--- |
| `radius` | `float` | `2.0` | Radius maksimal dalam kilometer. Backend membatasi nilai maksimal tetap **2.0 km**. |

---

## 2. Struktur Payload Data (Response JSON)

### Contoh Response:
```json
{
  "destination_id": 60001,
  "radius_km": 2,
  "data": [
    {
      "id": 120002,
      "name": "Palawi Resort Baturraden",
      "slug": "palawi-resort-baturraden-V54ob",
      "thumbnail_url": "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600",
      "price": 400000,
      "rating_avg": 4.6,
      "rating_count": 88,
      "district": "Baturraden",
      "address": "Kawasan Wana Wisata, Karangmangu, Kec. Baturraden, Kabupaten Banyumas",
      "distance_km": 0.2,
      "distance_text": "200 m"
    }
  ]
}
```

### Kamus Data Field (`data[]`)
| Nama Field | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `id` | `integer` | ID destinasi penginapan/hotel. |
| `name` | `string` | Nama hotel / resort / homestay. |
| `slug` | `string` | Slug URL destinasi penginapan. |
| `thumbnail_url` | `string` | URL foto cover/thumbnail utama penginapan. |
| `price` | `number` | Harga sewa per malam (dalam Rupiah). `0` atau `null` berarti belum ada tarif tetap / gratis. |
| `rating_avg` | `float` | Rata-rata rating ulasan pengunjung (skala 1 - 5). |
| `rating_count` | `integer` | Total jumlah ulasan yang masuk. |
| `district` | `string` | Nama kecamatan (contoh: `Baturraden`). |
| `address` | `string` | Alamat lengkap penginapan. |
| `distance_km` | `float` | Nilai jarak numerik dalam kilometer (contoh: `0.23`). |
| `distance_text` | `string` | Label jarak siap tampil (contoh: `"200 m"` jika < 1 km, atau `"1.39 km"` jika $\ge$ 1 km). |

---

## 3. Ketentuan & Aturan Bisnis (Business Logic)

1. **Jarak Maksimal:** Dibatasi maksimal **$\le$ 2.0 km** dari titik koordinat destinasi utama.
2. **Pengurutan (Sorting):** Data dari backend sudah otomatis terurut dari yang **terdekat ke yang terjauh** (`distance_km` ASC).
3. **Filter Kategori:** Hanya mengambil destinasi dengan kategori penginapan/hotel (`slug` mengandung `hotel` atau `penginapan`).
4. **Pengecualian ID:** Destinasi acuan tidak akan merekomendasikan dirinya sendiri (`id != destination_id`).
5. **Kondisi Tanpa Data:** Jika `data` kosong (`data.length === 0`), sembunyikan section rekomendasi ini (*conditional render / hide*) agar tampilan halaman tetap bersih.

---

## 4. Panduan Tampilan UI (Web Frontend)

* **Penempatan Section:**
  * Letakkan pada halaman **Detail Destinasi**.
  * Posisi: **Setelah section Lokasi & Peta (Map)** dan **Sebelum section Ulasan Pengunjung (Reviews)**.
* **Header Section:**
  * Judul: `Penginapan Terdekat` (dengan ikon hotel / penginapan).
  * Badge keterangan di kanan judul: `Radius ≤ 2 km`.
* **Format Tampilan:**
  * Disarankan menggunakan **Horizontal Carousel / Slider** atau horizontal scroll flex row.
* **Elemen Kartu Hotel (Card Elements):**
  1. **Thumbnail Foto:** Foto cover penginapan (`thumbnail_url`) dengan rasio proporsional.
  2. **Badge Jarak:** Tampilkan di atas foto (contoh: `📍 200 m` menggunakan nilai `distance_text`).
  3. **Badge Rating:** Tampilkan di atas foto / samping nama (contoh: `⭐ 4.6`).
  4. **Nama Hotel:** Maksimal 1 baris (tambahkan text truncation / ellipsis).
  5. **Lokasi:** Tampilkan kecamatan (`district`).
  6. **Harga:** Format mata uang per malam (contoh: `Rp 400.000 / malam`).
  7. **Interaksi Klik:** Saat kartu diklik, arahkan pengguna ke halaman detail penginapan terkait (`/destinasi/{id}` atau `/destinasi/{slug}`).

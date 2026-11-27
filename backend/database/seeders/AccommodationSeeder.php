<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Destination;
use App\Models\Facility;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class AccommodationSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Dapatkan atau buat Kategori Hotel & Penginapan
        $category = Category::where('slug', 'like', '%hotel%')
            ->orWhere('slug', 'like', '%penginapan%')
            ->first();

        if (!$category) {
            $category = Category::create([
                'name' => 'Hotel & Penginapan',
                'slug' => 'hotel-penginapan',
                'icon' => 'hotel',
                'description' => 'Akomodasi, hotel berbintang, resort, dan villa di kawasan Banyumas.',
            ]);
        }

        // Ambil ID fasilitas untuk di-attach
        $facilityIds = Facility::pluck('id')->toArray();

        // 2. Daftar Hotel & Penginapan
        // Posisi Acuan Baturraden: Lat -7.3090, Lng 109.2230
        $hotels = [
            // ─── HOTEL DALAM RADIUS (<= 2.0 km dari Baturraden / Curug Jenggala) ───
            [
                'name' => 'Bobocabin Baturraden',
                'description' => 'Konsep glamping kabin modern berteknologi tinggi di tengah sejuknya pepohonan rimbun kaki Gunung Slamet Baturraden.',
                'address' => 'Jl. Ketenger Dusun II, Ketenger, Kec. Baturraden, Kabupaten Banyumas',
                'district' => 'Baturraden',
                'latitude' => -7.3095,
                'longitude' => 109.2210, // ~0.6 km
                'price' => 550000,
                'opening_hours' => '24 Jam',
                'is_24_hours' => true,
                'phone' => '081122334455',
                'cs_phone' => '081122334455',
                'thumbnail' => 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=600',
                'is_popular' => true,
                'rating_avg' => 4.8,
                'rating_count' => 124,
            ],
            [
                'name' => 'Palawi Resort Baturraden',
                'description' => 'Resort pegunungan bernuansa alami kayu dan batu alam di kawasan wisata Baturraden dengan pemandangan lembah hijau.',
                'address' => 'Kawasan Wana Wisata, Karangmangu, Kec. Baturraden, Kabupaten Banyumas',
                'district' => 'Baturraden',
                'latitude' => -7.3105,
                'longitude' => 109.2240, // ~0.3 km
                'price' => 400000,
                'opening_hours' => '24 Jam',
                'is_24_hours' => true,
                'phone' => '081234567891',
                'cs_phone' => '081234567891',
                'thumbnail' => 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
                'is_popular' => true,
                'rating_avg' => 4.6,
                'rating_count' => 88,
            ],
            [
                'name' => 'Grand Kanaya Hotel Baturraden',
                'description' => 'Hotel berkelas bintang 3 dengan fasilitas kolam renang outdoor, ballroom pertemuan, dan resto masakan Nusantara.',
                'address' => 'Jl. Raya Baturraden Barat No. 22, Karangmangu, Baturraden',
                'district' => 'Baturraden',
                'latitude' => -7.3140,
                'longitude' => 109.2245, // ~0.6 km
                'price' => 350000,
                'opening_hours' => '24 Jam',
                'is_24_hours' => true,
                'phone' => '081398765432',
                'cs_phone' => '081398765432',
                'thumbnail' => 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=600',
                'is_popular' => false,
                'rating_avg' => 4.5,
                'rating_count' => 65,
            ],
            [
                'name' => 'Queen Garden Hotel Resort',
                'description' => 'Hotel legendaris di puncak bukit Baturraden dengan view spektakuler Gunung Slamet dan gemerlap lampu kota Purwokerto.',
                'address' => 'Jl. Pariwisata Baturraden No. 1, Dusun II Karangmangu, Baturraden',
                'district' => 'Baturraden',
                'latitude' => -7.3135,
                'longitude' => 109.2260, // ~0.7 km
                'price' => 450000,
                'opening_hours' => '24 Jam',
                'is_24_hours' => true,
                'phone' => '081555667788',
                'cs_phone' => '081555667788',
                'thumbnail' => 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=600',
                'is_popular' => true,
                'rating_avg' => 4.7,
                'rating_count' => 95,
            ],
            [
                'name' => 'Green Valley Resort Baturraden',
                'description' => 'Resort rekreasi keluarga dengan taman air, cottage kayu, dan fasilitas outbound outbound di lereng Baturraden.',
                'address' => 'Jl. Raya Baturraden KM 8, Karangmangu, Kec. Baturraden, Kabupaten Banyumas',
                'district' => 'Baturraden',
                'latitude' => -7.3200,
                'longitude' => 109.2290, // ~1.4 km
                'price' => 380000,
                'opening_hours' => '24 Jam',
                'is_24_hours' => true,
                'phone' => '081777889900',
                'cs_phone' => '081777889900',
                'thumbnail' => 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=600',
                'is_popular' => false,
                'rating_avg' => 4.6,
                'rating_count' => 72,
            ],

            // ─── HOTEL DI LUAR RADIUS (> 2.0 km, Di Kota Purwokerto ~12-15 km) ───
            [
                'name' => 'Java Heritage Hotel Purwokerto',
                'description' => 'Hotel bintang 4 termewah di Purwokerto dengan kolam renang laguna terbesar, spa, convention center, dan lounge eksklusif.',
                'address' => 'Jl. Dr. Angka No. 71, Karangkobar, Sokanegara, Kec. Purwokerto Timur',
                'district' => 'Purwokerto Timur',
                'latitude' => -7.4172,
                'longitude' => 109.2395, // ~12.3 km (Luar Radius)
                'price' => 750000,
                'opening_hours' => '24 Jam',
                'is_24_hours' => true,
                'phone' => '0281634321',
                'cs_phone' => '0281634321',
                'thumbnail' => 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600',
                'is_popular' => true,
                'rating_avg' => 4.9,
                'rating_count' => 340,
            ],
            [
                'name' => 'Luminor Hotel Purwokerto',
                'description' => 'Hotel bintang 3 modern strategis di pusat kota Purwokerto dengan view langsung ke Alun-Alun dan akses mall.',
                'address' => 'Jl. Jend. Sudirman No. 324, Pereng, Kranji, Kec. Purwokerto Timur',
                'district' => 'Purwokerto Timur',
                'latitude' => -7.4245,
                'longitude' => 109.2312, // ~13.1 km (Luar Radius)
                'price' => 600000,
                'opening_hours' => '24 Jam',
                'is_24_hours' => true,
                'phone' => '0281777199',
                'cs_phone' => '0281777199',
                'thumbnail' => 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=600',
                'is_popular' => true,
                'rating_avg' => 4.7,
                'rating_count' => 210,
            ],
            [
                'name' => 'Hotel Santika Purwokerto',
                'description' => 'Hotel bintang 3 dengan keramahtamahan khas Indonesia, menu sarapan khas Banyumas mendoan hangat, dan kolam renang.',
                'address' => 'Jl. Gerilya Barat No. 30A, Gandasuli, Karangpucung, Kec. Purwokerto Selatan',
                'district' => 'Purwokerto Selatan',
                'latitude' => -7.4380,
                'longitude' => 109.2450, // ~15.2 km (Luar Radius)
                'price' => 650000,
                'opening_hours' => '24 Jam',
                'is_24_hours' => true,
                'phone' => '0281622789',
                'cs_phone' => '0281622789',
                'thumbnail' => 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600',
                'is_popular' => false,
                'rating_avg' => 4.8,
                'rating_count' => 180,
            ],
        ];

        foreach ($hotels as $h) {
            $existing = Destination::where('name', $h['name'])->first();
            if ($existing) {
                $existing->update([
                    'category_id' => $category->id,
                    'description' => $h['description'],
                    'address' => $h['address'],
                    'district' => $h['district'],
                    'latitude' => $h['latitude'],
                    'longitude' => $h['longitude'],
                    'price' => $h['price'],
                    'opening_hours' => $h['opening_hours'],
                    'is_24_hours' => $h['is_24_hours'],
                    'phone' => $h['phone'],
                    'cs_phone' => $h['cs_phone'],
                    'thumbnail' => $h['thumbnail'],
                    'status' => 'published',
                    'is_popular' => $h['is_popular'],
                    'rating_avg' => $h['rating_avg'],
                    'rating_count' => $h['rating_count'],
                ]);
            } else {
                $dest = Destination::create([
                    'category_id' => $category->id,
                    'name' => $h['name'],
                    'slug' => Str::slug($h['name']) . '-' . Str::random(5),
                    'description' => $h['description'],
                    'address' => $h['address'],
                    'district' => $h['district'],
                    'latitude' => $h['latitude'],
                    'longitude' => $h['longitude'],
                    'price' => $h['price'],
                    'opening_hours' => $h['opening_hours'],
                    'is_24_hours' => $h['is_24_hours'],
                    'phone' => $h['phone'],
                    'cs_phone' => $h['cs_phone'],
                    'thumbnail' => $h['thumbnail'],
                    'status' => 'published',
                    'is_popular' => $h['is_popular'],
                    'rating_avg' => $h['rating_avg'],
                    'rating_count' => $h['rating_count'],
                ]);

                if (!empty($facilityIds)) {
                    // Random 3-5 facilities
                    $dest->facilities()->sync(array_slice($facilityIds, 0, rand(3, 5)));
                }
            }
        }
    }
}

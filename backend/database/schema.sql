-- =========================================================
-- StayEase - Skema Database (MySQL / MariaDB di Laragon)
-- Jalankan lewat HeidiSQL (Laragon > Database) atau:
--   mysql -u root < database/schema.sql
-- =========================================================

DROP DATABASE IF EXISTS stayease_db;
CREATE DATABASE stayease_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE stayease_db;

-- ---------- USERS ----------
CREATE TABLE users (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  email       VARCHAR(120) NOT NULL UNIQUE,
  password    VARCHAR(255) NOT NULL,
  phone       VARCHAR(20)  NULL,
  role        ENUM('user','admin') NOT NULL DEFAULT 'user',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------- HOTELS ----------
CREATE TABLE hotels (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(150) NOT NULL,
  city         VARCHAR(80)  NOT NULL,
  address      VARCHAR(255) NOT NULL,
  description  TEXT,
  star         TINYINT NOT NULL DEFAULT 3,
  image_url    VARCHAR(255),
  facilities   VARCHAR(255) COMMENT 'dipisah koma, contoh: WiFi,Kolam Renang,Parkir',
  latitude     DECIMAL(10,7) NULL,
  longitude    DECIMAL(10,7) NULL,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_hotels_city (city)
) ENGINE=InnoDB;

-- ---------- ROOMS (tipe kamar) ----------
CREATE TABLE rooms (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  hotel_id         INT NOT NULL,
  type             VARCHAR(80) NOT NULL,
  description      TEXT,
  price_per_night  INT NOT NULL,
  capacity         TINYINT NOT NULL DEFAULT 2,
  total_rooms      INT NOT NULL DEFAULT 1 COMMENT 'jumlah unit kamar dengan tipe ini',
  image_url        VARCHAR(255),
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rooms_hotel FOREIGN KEY (hotel_id) REFERENCES hotels(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- BOOKINGS ----------
CREATE TABLE bookings (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  booking_code  VARCHAR(20) NOT NULL UNIQUE,
  user_id       INT NOT NULL,
  room_id       INT NOT NULL,
  check_in      DATE NOT NULL,
  check_out     DATE NOT NULL,
  guests        TINYINT NOT NULL DEFAULT 1,
  rooms         TINYINT NOT NULL DEFAULT 1 COMMENT 'jumlah kamar yang dipesan',
  nights        INT NOT NULL,
  total_price   INT NOT NULL,
  guest_name    VARCHAR(100) NOT NULL,
  guest_phone   VARCHAR(20)  NOT NULL,
  notes         VARCHAR(255),
  status        ENUM('pending','paid','cancelled','completed') NOT NULL DEFAULT 'pending',
  paid_at       DATETIME NULL,
  -- ---- pembayaran (simulasi Virtual Account / QRIS) ----
  payment_method      ENUM('va','qris') NULL,
  payment_bank        VARCHAR(20) NULL COMMENT 'BCA/BNI/BRI/MANDIRI untuk VA',
  va_number           VARCHAR(30) NULL,
  qris_ref            VARCHAR(40) NULL,
  service_fee         INT NOT NULL DEFAULT 0,
  payment_amount      INT NULL COMMENT 'total_price + service_fee',
  payment_expires_at  DATETIME NULL,
  receipt_number      VARCHAR(40) NULL UNIQUE COMMENT 'nomor bukti pembayaran',
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_bookings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_bookings_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
  INDEX idx_bookings_room_dates (room_id, check_in, check_out)
) ENGINE=InnoDB;

-- ---------- REVIEWS ----------
CREATE TABLE reviews (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  booking_id  INT NOT NULL UNIQUE,
  user_id     INT NOT NULL,
  hotel_id    INT NOT NULL,
  rating      TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     TEXT,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reviews_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_user    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
  CONSTRAINT fk_reviews_hotel   FOREIGN KEY (hotel_id)   REFERENCES hotels(id)   ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- FAVORITES (hotel disukai) ----------
CREATE TABLE favorites (
  user_id     INT NOT NULL,
  hotel_id    INT NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, hotel_id),
  CONSTRAINT fk_fav_user  FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE,
  CONSTRAINT fk_fav_hotel FOREIGN KEY (hotel_id) REFERENCES hotels(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- DATA CONTOH ----------
-- image_url yang diawali "assets/" diambil dari foto di dalam aplikasi Flutter (mobile/assets/images).
-- Boleh juga diisi URL internet (https://...).
-- 36 hotel di 6 kota (Surabaya, Malang, Yogyakarta, Bali, Jakarta, Bandung), masing-masing 6 hotel
INSERT INTO hotels (name, city, address, description, star, image_url, facilities, latitude, longitude) VALUES
('StayEase Tunjungan Suites', 'Surabaya', 'Jl. Tunjungan No. 45, Genteng', 'Hotel modern di jantung kota Surabaya, dekat Tunjungan Plaza dan kawasan heritage.', 4, 'assets/images/hotel_1.jpg', 'WiFi,Kolam Renang,Parkir,Restoran,AC', -7.2627, 112.7397),
('Griya Pakuwon Residence', 'Surabaya', 'Jl. Puncak Indah Lontar No. 2, Wiyung', 'Penginapan nyaman bernuansa keluarga di Surabaya Barat.', 3, 'assets/images/hotel_2.jpg', 'WiFi,Parkir,Sarapan,AC', -7.2905, 112.675),
('Batu Highland Resort', 'Malang', 'Jl. Raya Selecta No. 8, Batu', 'Resort sejuk dengan pemandangan pegunungan dan kebun apel.', 4, 'assets/images/room_galaxy_suite.jpg', 'WiFi,Kolam Air Hangat,Parkir,Restoran', -7.8231, 112.5246),
('Ijen Boutique Hotel', 'Malang', 'Jl. Ijen No. 21, Klojen', 'Boutique hotel bergaya kolonial di boulevard Ijen.', 3, 'assets/images/room_chandelier.jpg', 'WiFi,Sarapan,AC', -7.9719, 112.6227),
('Malioboro Heritage Inn', 'Yogyakarta', 'Jl. Malioboro No. 60', 'Jalan kaki 2 menit ke Malioboro, cocok untuk wisata budaya.', 3, 'assets/images/hotel_5.jpg', 'WiFi,Sarapan,AC,Laundry', -7.7926, 110.3658),
('Seminyak Bay Villa', 'Bali', 'Jl. Kayu Aya No. 12, Seminyak', 'Villa privat dekat pantai dengan kolam renang pribadi.', 5, 'assets/images/hotel_6.jpg', 'WiFi,Kolam Renang Pribadi,Spa,Sarapan,Antar-Jemput Bandara', -8.6913, 115.1682),
('Kenjeran Bay Hotel', 'Surabaya', 'Jl. Pantai Kenjeran No. 88, Bulak', 'Hotel tepi pantai dengan pemandangan Jembatan Suramadu.', 4, 'assets/images/hotel_1.jpg', 'WiFi,Kolam Renang,Restoran,Parkir,AC', -7.239, 112.796),
('Darmo Garden Inn', 'Surabaya', 'Jl. Raya Darmo No. 101, Wonokromo', 'Penginapan asri dengan taman tropis, dekat Kebun Binatang Surabaya.', 3, 'assets/images/hotel_2.jpg', 'WiFi,Sarapan,Parkir,AC', -7.2896, 112.7376),
('Alun-Alun Malang City Hotel', 'Malang', 'Jl. Merdeka Selatan No. 5, Klojen', 'Hotel praktis di pusat kota, dekat Alun-Alun dan kuliner Malang.', 3, 'assets/images/hotel_5.jpg', 'WiFi,Sarapan,AC,Laundry', -7.9826, 112.6308),
('Bromo Gate Lodge', 'Malang', 'Jl. Raya Tumpang No. 17, Tumpang', 'Basecamp nyaman untuk wisata sunrise Bromo dan Coban Pelangi.', 3, 'assets/images/hotel_6.jpg', 'WiFi,Parkir,Sarapan,Antar-Jemput Jeep', -8.0068, 112.7558),
('Prambanan Sunrise Resort', 'Yogyakarta', 'Jl. Raya Solo-Jogja Km 16, Prambanan', 'Resort dengan pemandangan Candi Prambanan saat matahari terbit.', 4, 'assets/images/room_galaxy_suite.jpg', 'WiFi,Kolam Renang,Restoran,Spa,Parkir', -7.752, 110.4915),
('Tugu Kota Residence', 'Yogyakarta', 'Jl. Margo Utomo No. 33, Jetis', 'Hotel modern dekat Tugu Jogja dan Stasiun Tugu.', 3, 'assets/images/room_chandelier.jpg', 'WiFi,Sarapan,AC,Parkir', -7.7829, 110.3671),
('Kaliurang Pine Villa', 'Yogyakarta', 'Jl. Kaliurang Km 23, Pakem', 'Villa sejuk di kaki Merapi dikelilingi hutan pinus.', 4, 'assets/images/room_marble_suite.jpg', 'WiFi,Parkir,Dapur,Api Unggun,Sarapan', -7.599, 110.424),
('Ubud Rice Terrace Retreat', 'Bali', 'Jl. Raya Tegallalang, Ubud', 'Retreat tenang menghadap sawah terasering Tegallalang.', 5, 'assets/images/room_mountain_view.jpg', 'WiFi,Kolam Renang,Spa,Yoga,Sarapan', -8.4312, 115.2793),
('Kuta Sunset Hotel', 'Bali', 'Jl. Pantai Kuta No. 9, Kuta', 'Hanya 3 menit ke Pantai Kuta, cocok untuk menikmati sunset.', 4, 'assets/images/hotel_1.jpg', 'WiFi,Kolam Renang,Restoran,Bar,AC', -8.718, 115.1686),
('Nusa Dua Lagoon Resort', 'Bali', 'Kawasan ITDC Lot N5, Nusa Dua', 'Resort keluarga dengan laguna pribadi dan kids club.', 5, 'assets/images/hotel_2.jpg', 'WiFi,Kolam Renang,Spa,Kids Club,Antar-Jemput Bandara', -8.8008, 115.232),
('Sudirman Skyline Hotel', 'Jakarta', 'Jl. Jend. Sudirman Kav. 52, Senayan', 'Hotel bisnis dengan rooftop bar dan pemandangan gedung pencakar langit.', 5, 'assets/images/hotel_5.jpg', 'WiFi,Kolam Renang,Gym,Restoran,Ruang Rapat', -6.2251, 106.809),
('Kemang Urban Suites', 'Jakarta', 'Jl. Kemang Raya No. 18, Mampang', 'Suite modern di kawasan kafe dan galeri Kemang.', 4, 'assets/images/hotel_6.jpg', 'WiFi,Gym,Parkir,Restoran,AC', -6.2607, 106.8135),
('Kota Tua Heritage Hotel', 'Jakarta', 'Jl. Kali Besar Timur No. 3, Taman Sari', 'Bangunan kolonial yang direstorasi, jalan kaki ke Museum Fatahillah.', 3, 'assets/images/room_galaxy_suite.jpg', 'WiFi,Sarapan,AC', -6.1352, 106.8133),
('Ancol Seaside Inn', 'Jakarta', 'Jl. Lodan Timur No. 7, Ancol', 'Penginapan keluarga dekat Dufan dan Pantai Ancol.', 3, 'assets/images/room_chandelier.jpg', 'WiFi,Kolam Renang,Parkir,Sarapan', -6.1225, 106.8337),
('Braga Art Deco Hotel', 'Bandung', 'Jl. Braga No. 40, Sumur Bandung', 'Hotel bergaya art deco di jalan legendaris Braga.', 4, 'assets/images/room_marble_suite.jpg', 'WiFi,Restoran,Sarapan,AC', -6.9175, 107.6091),
('Dago Hills Resort', 'Bandung', 'Jl. Ir. H. Juanda No. 300, Dago', 'Resort di perbukitan Dago dengan city light Bandung di malam hari.', 4, 'assets/images/room_mountain_view.jpg', 'WiFi,Kolam Air Hangat,Restoran,Parkir', -6.87, 107.62),
('Lembang Forest Cabin', 'Bandung', 'Jl. Grand Hotel No. 21, Lembang', 'Kabin kayu di tengah hutan, dekat Farmhouse dan Floating Market.', 3, 'assets/images/hotel_1.jpg', 'WiFi,Parkir,Api Unggun,Sarapan', -6.812, 107.618),
('Riau Street Boutique', 'Bandung', 'Jl. L.L.R.E. Martadinata No. 56, Citarum', 'Boutique hotel dekat factory outlet Jalan Riau.', 3, 'assets/images/hotel_2.jpg', 'WiFi,Sarapan,AC,Laundry', -6.905, 107.617),
('Jimbaran Cliff Resort', 'Bali', 'Jl. Uluwatu No. 88, Jimbaran', 'Resort mewah dengan kolam renang bertingkat dan cabana privat menghadap Teluk Jimbaran.', 5, 'assets/images/hotel_7.jpg', 'WiFi,Kolam Renang,Spa,Cabana,Restoran,Antar-Jemput Bandara', -8.79, 115.162),
('Menteng Royal Palace Hotel', 'Jakarta', 'Jl. HOS Cokroaminoto No. 12, Menteng', 'Hotel klasik bergaya istana dengan lobi berlampu kristal di kawasan elit Menteng.', 5, 'assets/images/hotel_8.jpg', 'WiFi,Restoran,Ballroom,Spa,Valet Parking', -6.196, 106.831),
('Embong Grand Tower', 'Surabaya', 'Jl. Embong Malang No. 21, Tegalsari', 'Menara kembar 30 lantai dengan pemandangan kota Surabaya, dekat pusat belanja.', 4, 'assets/images/hotel_9.jpg', 'WiFi,Kolam Renang,Gym,Restoran,Parkir', -7.261, 112.736),
('Parangtritis Ocean Resort', 'Yogyakarta', 'Jl. Parangtritis Km 27, Kretek', 'Resort tepi pantai selatan dengan kolam renang luas dan balkon di setiap kamar.', 4, 'assets/images/hotel_10.jpg', 'WiFi,Kolam Renang,Restoran,Parkir,Sarapan', -8.025, 110.33),
('Asia Afrika Classic Hotel', 'Bandung', 'Jl. Asia Afrika No. 77, Braga', 'Hotel bergaya klasik Eropa dengan fasad ukiran, berjalan kaki ke Gedung Merdeka.', 5, 'assets/images/hotel_11.jpg', 'WiFi,Restoran,Spa,Sarapan,Ruang Rapat', -6.921, 107.61),
('Kuningan Noir Tower', 'Jakarta', 'Jl. HR Rasuna Said Kav. 9, Kuningan', 'Menara kaca hitam-emas dengan sky pool dan lounge eksklusif di jantung bisnis Jakarta.', 5, 'assets/images/hotel_12.jpg', 'WiFi,Sky Pool,Gym,Bar,Valet Parking', -6.221, 106.832),
('Kayutangan Heritage Hotel', 'Malang', 'Jl. Basuki Rahmat No. 30, Kayutangan', 'Hotel butik bergaya kolonial dengan balkon besi tempa di koridor heritage Kayutangan.', 4, 'assets/images/hotel_13.jpg', 'WiFi,Sarapan,Restoran,AC', -7.979, 112.63),
('Galaxy Twin Tower', 'Surabaya', 'Jl. Dr. Ir. H. Soekarno No. 300, Mulyorejo', 'Menara kembar modern dengan sky bridge, rooftop garden, dan akses tol mudah.', 5, 'assets/images/hotel_14.jpg', 'WiFi,Kolam Renang,Gym,Sky Lounge,Parkir', -7.278, 112.782),
('Sanur Garden Pool Hotel', 'Bali', 'Jl. Danau Tamblingan No. 45, Sanur', 'Hotel tenang dengan kolam renang taman dan payung tropis, 5 menit ke Pantai Sanur.', 4, 'assets/images/hotel_15.jpg', 'WiFi,Kolam Renang,Restoran,Bar,Sarapan', -8.688, 115.262),
('Pasteur Sky Hotel', 'Bandung', 'Jl. Dr. Djunjunan No. 155, Pasteur', 'Hotel tinggi dengan pemandangan sunset kota Bandung, dekat pintu tol Pasteur.', 4, 'assets/images/hotel_16.jpg', 'WiFi,Kolam Renang,Gym,Restoran,Parkir', -6.893, 107.585),
('Batu Infinity Pool Suites', 'Malang', 'Jl. Abdul Gani Atas No. 9, Batu', 'Suite modern dengan kolam infinity dan balkon kaca menghadap kota Batu.', 4, 'assets/images/hotel_17.jpg', 'WiFi,Kolam Infinity,Restoran,Parkir,Sarapan', -7.88, 112.523),
('Adisucipto Grand Tower', 'Yogyakarta', 'Jl. Laksda Adisucipto No. 38, Depok', 'Menara modern dengan air mancur di depan lobi, 10 menit ke bandara Adisucipto.', 5, 'assets/images/hotel_18.jpg', 'WiFi,Kolam Renang,Spa,Restoran,Antar-Jemput Bandara', -7.783, 110.4);

INSERT INTO rooms (hotel_id, type, description, price_per_night, capacity, total_rooms, image_url) VALUES
(1, 'Superior', 'Kamar 24 m², kasur queen, city view.', 550000, 2, 10, 'assets/images/room_king_classic.jpg'),
(1, 'Deluxe', 'Kamar 32 m², kasur king, bathtub.', 780000, 2, 6, 'assets/images/room_marble_suite.jpg'),
(1, 'Family', 'Kamar 45 m², 2 kasur queen.', 1150000, 4, 3, 'assets/images/room_twin_blue.jpg'),
(2, 'Standard', 'Kamar 20 m², kasur double.', 350000, 2, 8, 'assets/images/room_twin_wood.jpg'),
(2, 'Family', 'Kamar 36 m², 1 king + 1 single.', 600000, 3, 4, 'assets/images/room_twin_bronze.jpg'),
(3, 'Deluxe Mountain View', 'Balkon menghadap gunung.', 850000, 2, 8, 'assets/images/room_mountain_view.jpg'),
(3, 'Cottage', 'Cottage kayu untuk keluarga.', 1400000, 5, 2, 'assets/images/room_galaxy_suite.jpg'),
(4, 'Superior', 'Kamar klasik dengan jendela besar.', 450000, 2, 6, 'assets/images/room_chandelier.jpg'),
(5, 'Standard', 'Kamar praktis untuk backpacker.', 300000, 2, 12, 'assets/images/room_twin_wood.jpg'),
(5, 'Deluxe', 'Kamar luas dengan sentuhan batik.', 520000, 3, 5, 'assets/images/room_twin_bronze.jpg'),
(6, 'One Bedroom Pool Villa', 'Villa 1 kamar dengan kolam pribadi.', 2500000, 2, 3, 'assets/images/room_marble_suite.jpg'),
(6, 'Two Bedroom Pool Villa', 'Villa 2 kamar untuk keluarga.', 4200000, 4, 2, 'assets/images/room_twin_blue.jpg'),
(7, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 840000, 2, 10, 'assets/images/room_king_classic.jpg'),
(7, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1180000, 2, 5, 'assets/images/room_marble_suite.jpg'),
(8, 'Standard', 'Kamar 20 m², kasur double, nyaman untuk berdua.', 380000, 2, 10, 'assets/images/room_twin_blue.jpg'),
(8, 'Superior Twin', 'Kamar 24 m², 2 kasur single.', 510000, 2, 6, 'assets/images/room_twin_wood.jpg'),
(8, 'Family', 'Kamar 34 m², 1 king + 1 single.', 720000, 3, 3, 'assets/images/room_twin_bronze.jpg'),
(9, 'Standard', 'Kamar 20 m², kasur double, nyaman untuk berdua.', 420000, 2, 10, 'assets/images/room_mountain_view.jpg'),
(9, 'Superior Twin', 'Kamar 24 m², 2 kasur single.', 570000, 2, 6, 'assets/images/room_galaxy_suite.jpg'),
(10, 'Standard', 'Kamar 20 m², kasur double, nyaman untuk berdua.', 460000, 2, 10, 'assets/images/room_chandelier.jpg'),
(10, 'Superior Twin', 'Kamar 24 m², 2 kasur single.', 620000, 2, 6, 'assets/images/room_king_classic.jpg'),
(10, 'Family', 'Kamar 34 m², 1 king + 1 single.', 870000, 3, 3, 'assets/images/room_marble_suite.jpg'),
(11, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 840000, 2, 10, 'assets/images/room_twin_blue.jpg'),
(11, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1180000, 2, 5, 'assets/images/room_twin_wood.jpg'),
(12, 'Standard', 'Kamar 20 m², kasur double, nyaman untuk berdua.', 380000, 2, 10, 'assets/images/room_twin_bronze.jpg'),
(12, 'Superior Twin', 'Kamar 24 m², 2 kasur single.', 510000, 2, 6, 'assets/images/room_mountain_view.jpg'),
(12, 'Family', 'Kamar 34 m², 1 king + 1 single.', 720000, 3, 3, 'assets/images/room_galaxy_suite.jpg'),
(13, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 760000, 2, 10, 'assets/images/room_chandelier.jpg'),
(13, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1060000, 2, 5, 'assets/images/room_king_classic.jpg'),
(14, 'Grand Deluxe', 'Kamar 42 m², balkon pribadi.', 1980000, 2, 8, 'assets/images/room_marble_suite.jpg'),
(14, 'Junior Suite', 'Suite 60 m² dengan ruang tamu.', 3170000, 3, 4, 'assets/images/room_twin_blue.jpg'),
(14, 'Presidential Villa', 'Villa 120 m² dengan kolam pribadi.', 5940000, 4, 1, 'assets/images/room_twin_wood.jpg'),
(15, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 840000, 2, 10, 'assets/images/room_twin_bronze.jpg'),
(15, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1180000, 2, 5, 'assets/images/room_mountain_view.jpg'),
(16, 'Grand Deluxe', 'Kamar 42 m², balkon pribadi.', 1900000, 2, 8, 'assets/images/room_galaxy_suite.jpg'),
(16, 'Junior Suite', 'Suite 60 m² dengan ruang tamu.', 3040000, 3, 4, 'assets/images/room_chandelier.jpg'),
(16, 'Presidential Villa', 'Villa 120 m² dengan kolam pribadi.', 5700000, 4, 1, 'assets/images/room_king_classic.jpg'),
(17, 'Grand Deluxe', 'Kamar 42 m², balkon pribadi.', 1940000, 2, 8, 'assets/images/room_marble_suite.jpg'),
(17, 'Junior Suite', 'Suite 60 m² dengan ruang tamu.', 3100000, 3, 4, 'assets/images/room_twin_blue.jpg'),
(18, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 800000, 2, 10, 'assets/images/room_twin_wood.jpg'),
(18, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1120000, 2, 5, 'assets/images/room_twin_bronze.jpg'),
(18, 'Family Suite', 'Suite 50 m², 2 kamar tidur.', 1680000, 4, 3, 'assets/images/room_mountain_view.jpg'),
(19, 'Standard', 'Kamar 20 m², kasur double, nyaman untuk berdua.', 500000, 2, 10, 'assets/images/room_galaxy_suite.jpg'),
(19, 'Superior Twin', 'Kamar 24 m², 2 kasur single.', 680000, 2, 6, 'assets/images/room_chandelier.jpg'),
(20, 'Standard', 'Kamar 20 m², kasur double, nyaman untuk berdua.', 380000, 2, 10, 'assets/images/room_king_classic.jpg'),
(20, 'Superior Twin', 'Kamar 24 m², 2 kasur single.', 510000, 2, 6, 'assets/images/room_marble_suite.jpg'),
(20, 'Family', 'Kamar 34 m², 1 king + 1 single.', 720000, 3, 3, 'assets/images/room_twin_blue.jpg'),
(21, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 760000, 2, 10, 'assets/images/room_twin_wood.jpg'),
(21, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1060000, 2, 5, 'assets/images/room_twin_bronze.jpg'),
(22, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 800000, 2, 10, 'assets/images/room_mountain_view.jpg'),
(22, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1120000, 2, 5, 'assets/images/room_galaxy_suite.jpg'),
(22, 'Family Suite', 'Suite 50 m², 2 kamar tidur.', 1680000, 4, 3, 'assets/images/room_chandelier.jpg'),
(23, 'Standard', 'Kamar 20 m², kasur double, nyaman untuk berdua.', 500000, 2, 10, 'assets/images/room_king_classic.jpg'),
(23, 'Superior Twin', 'Kamar 24 m², 2 kasur single.', 680000, 2, 6, 'assets/images/room_marble_suite.jpg'),
(24, 'Standard', 'Kamar 20 m², kasur double, nyaman untuk berdua.', 380000, 2, 10, 'assets/images/room_twin_blue.jpg'),
(24, 'Superior Twin', 'Kamar 24 m², 2 kasur single.', 510000, 2, 6, 'assets/images/room_twin_wood.jpg'),
(24, 'Family', 'Kamar 34 m², 1 king + 1 single.', 720000, 3, 3, 'assets/images/room_twin_bronze.jpg'),
(25, 'Grand Deluxe', 'Kamar 42 m², balkon pribadi.', 2050000, 2, 8, 'assets/images/room_king_classic.jpg'),
(25, 'Junior Suite', 'Suite 60 m² dengan ruang tamu.', 3280000, 3, 4, 'assets/images/room_marble_suite.jpg'),
(25, 'Presidential Suite', 'Suite 120 m² dengan pemandangan terbaik.', 6150000, 4, 1, 'assets/images/room_twin_blue.jpg'),
(26, 'Grand Deluxe', 'Kamar 42 m², balkon pribadi.', 2100000, 2, 8, 'assets/images/room_twin_wood.jpg'),
(26, 'Junior Suite', 'Suite 60 m² dengan ruang tamu.', 3360000, 3, 4, 'assets/images/room_twin_bronze.jpg'),
(26, 'Presidential Suite', 'Suite 120 m² dengan pemandangan terbaik.', 6300000, 4, 1, 'assets/images/room_mountain_view.jpg'),
(27, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 860000, 2, 10, 'assets/images/room_galaxy_suite.jpg'),
(27, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1200000, 2, 5, 'assets/images/room_chandelier.jpg'),
(27, 'Family Suite', 'Suite 50 m², 2 kamar tidur.', 1810000, 4, 3, 'assets/images/room_king_classic.jpg'),
(28, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 910000, 2, 10, 'assets/images/room_marble_suite.jpg'),
(28, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1270000, 2, 5, 'assets/images/room_twin_blue.jpg'),
(28, 'Family Suite', 'Suite 50 m², 2 kamar tidur.', 1910000, 4, 3, 'assets/images/room_twin_wood.jpg'),
(29, 'Grand Deluxe', 'Kamar 42 m², balkon pribadi.', 2050000, 2, 8, 'assets/images/room_twin_bronze.jpg'),
(29, 'Junior Suite', 'Suite 60 m² dengan ruang tamu.', 3280000, 3, 4, 'assets/images/room_mountain_view.jpg'),
(29, 'Presidential Suite', 'Suite 120 m² dengan pemandangan terbaik.', 6150000, 4, 1, 'assets/images/room_galaxy_suite.jpg'),
(30, 'Grand Deluxe', 'Kamar 42 m², balkon pribadi.', 2100000, 2, 8, 'assets/images/room_chandelier.jpg'),
(30, 'Junior Suite', 'Suite 60 m² dengan ruang tamu.', 3360000, 3, 4, 'assets/images/room_king_classic.jpg'),
(30, 'Presidential Suite', 'Suite 120 m² dengan pemandangan terbaik.', 6300000, 4, 1, 'assets/images/room_marble_suite.jpg'),
(31, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 860000, 2, 10, 'assets/images/room_twin_blue.jpg'),
(31, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1200000, 2, 5, 'assets/images/room_twin_wood.jpg'),
(31, 'Family Suite', 'Suite 50 m², 2 kamar tidur.', 1810000, 4, 3, 'assets/images/room_twin_bronze.jpg'),
(32, 'Grand Deluxe', 'Kamar 42 m², balkon pribadi.', 2200000, 2, 8, 'assets/images/room_mountain_view.jpg'),
(32, 'Junior Suite', 'Suite 60 m² dengan ruang tamu.', 3520000, 3, 4, 'assets/images/room_galaxy_suite.jpg'),
(32, 'Presidential Suite', 'Suite 120 m² dengan pemandangan terbaik.', 6600000, 4, 1, 'assets/images/room_chandelier.jpg'),
(33, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 760000, 2, 10, 'assets/images/room_king_classic.jpg'),
(33, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1060000, 2, 5, 'assets/images/room_marble_suite.jpg'),
(33, 'Family Suite', 'Suite 50 m², 2 kamar tidur.', 1600000, 4, 3, 'assets/images/room_twin_blue.jpg'),
(34, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 810000, 2, 10, 'assets/images/room_twin_wood.jpg'),
(34, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1130000, 2, 5, 'assets/images/room_twin_bronze.jpg'),
(34, 'Family Suite', 'Suite 50 m², 2 kamar tidur.', 1700000, 4, 3, 'assets/images/room_mountain_view.jpg'),
(35, 'Deluxe', 'Kamar 30 m², kasur king, city view.', 860000, 2, 10, 'assets/images/room_galaxy_suite.jpg'),
(35, 'Premier', 'Kamar 36 m², sofa & bathtub.', 1200000, 2, 5, 'assets/images/room_chandelier.jpg'),
(35, 'Family Suite', 'Suite 50 m², 2 kamar tidur.', 1810000, 4, 3, 'assets/images/room_king_classic.jpg'),
(36, 'Grand Deluxe', 'Kamar 42 m², balkon pribadi.', 2200000, 2, 8, 'assets/images/room_marble_suite.jpg'),
(36, 'Junior Suite', 'Suite 60 m² dengan ruang tamu.', 3520000, 3, 4, 'assets/images/room_twin_blue.jpg'),
(36, 'Presidential Suite', 'Suite 120 m² dengan pemandangan terbaik.', 6600000, 4, 1, 'assets/images/room_twin_wood.jpg');

-- Akun admin & user contoh + ulasan contoh dibuat oleh: npm run seed

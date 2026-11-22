SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET VERIFY OFF

-- ============================================================
-- 1. PURANI TABLES AUR SEQUENCES SAFELY DELETE KARNA
-- ============================================================
BEGIN
    FOR t IN (
        SELECT table_name FROM user_tables
        WHERE table_name IN (
            'PAYMENT', 'BOOKING_ATTRACTION', 'BOOKING',
            'CUSTOMER', 'TOUR_GUIDE', 'TRANSPORT',
            'HOTEL', 'ATTRACTION', 'CITY'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;

    FOR s IN (
        SELECT sequence_name FROM user_sequences
        WHERE sequence_name IN ('SEQ_CUSTOMER', 'SEQ_BOOKING', 'SEQ_PAYMENT')
    ) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- ============================================================
-- 2. TABLES BANANA (PRIMARY KEYS, FOREIGN KEYS & CONSTRAINTS)
-- ============================================================
CREATE TABLE city (
    city_id   NUMBER PRIMARY KEY,
    city_name VARCHAR2(50) NOT NULL UNIQUE
);

CREATE TABLE attraction (
    attraction_id   NUMBER PRIMARY KEY,
    city_id         NUMBER NOT NULL REFERENCES city(city_id),
    place_no        NUMBER NOT NULL,
    attraction_name VARCHAR2(80) NOT NULL,
    CONSTRAINT uq_city_place UNIQUE (city_id, place_no)
);

CREATE TABLE hotel (
    hotel_id        NUMBER PRIMARY KEY,
    city_id         NUMBER NOT NULL REFERENCES city(city_id),
    hotel_no        NUMBER NOT NULL,
    hotel_name      VARCHAR2(80) NOT NULL,
    price_per_night NUMBER(10) NOT NULL CHECK (price_per_night > 0),
    breakfast       VARCHAR2(5) NOT NULL CHECK (breakfast IN ('Yes', 'No')),
    lunch           VARCHAR2(5) NOT NULL CHECK (lunch IN ('Yes', 'No')),
    dinner          VARCHAR2(5) NOT NULL CHECK (dinner IN ('Yes', 'No')),
    CONSTRAINT uq_city_hotel UNIQUE (city_id, hotel_no)
);

CREATE TABLE transport (
    transport_id NUMBER PRIMARY KEY,
    category     VARCHAR2(15) NOT NULL CHECK (category IN ('Public', 'Private')),
    vehicle_name VARCHAR2(60) NOT NULL,
    car_rent     NUMBER(10) NOT NULL CHECK (car_rent >= 0),
    driver_fee   NUMBER(10) NOT NULL CHECK (driver_fee >= 0),
    service_tax  NUMBER(10) NOT NULL CHECK (service_tax >= 0),
    daily_total  NUMBER(10) NOT NULL CHECK (daily_total >= 0)
);

CREATE TABLE tour_guide (
    guide_id      NUMBER PRIMARY KEY,
    city_id       NUMBER NOT NULL REFERENCES city(city_id),
    guide_no      NUMBER NOT NULL,
    guide_name    VARCHAR2(60) NOT NULL,
    phone         VARCHAR2(20) NOT NULL,
    half_day_rate NUMBER(10) NOT NULL CHECK (half_day_rate > 0),
    full_day_rate NUMBER(10) NOT NULL CHECK (full_day_rate > 0),
    CONSTRAINT uq_city_guide UNIQUE (city_id, guide_no)
);

CREATE TABLE customer (
    customer_id NUMBER PRIMARY KEY,
    full_name   VARCHAR2(80) NOT NULL,
    phone       VARCHAR2(25) NOT NULL,
    email       VARCHAR2(80) NOT NULL
);

CREATE TABLE booking (
    booking_id     NUMBER PRIMARY KEY,
    customer_id    NUMBER NOT NULL REFERENCES customer(customer_id),
    city_id        NUMBER NOT NULL REFERENCES city(city_id),
    hotel_id       NUMBER NOT NULL REFERENCES hotel(hotel_id),
    rooms          NUMBER NOT NULL CHECK (rooms > 0),
    nights         NUMBER NOT NULL CHECK (nights > 0),
    persons        NUMBER NOT NULL CHECK (persons > 0),
    hotel_cost     NUMBER(12) NOT NULL,
    transport_id   NUMBER NOT NULL REFERENCES transport(transport_id),
    transport_cost NUMBER(12) NOT NULL,
    guide_id       NUMBER REFERENCES tour_guide(guide_id),
    guide_type     VARCHAR2(15) CHECK (guide_type IN ('None', 'Half Day', 'Full Day')),
    guide_days     NUMBER DEFAULT 0 CHECK (guide_days >= 0),
    guide_cost     NUMBER(12) DEFAULT 0,
    total_cost     NUMBER(12) NOT NULL,
    booking_status VARCHAR2(15) NOT NULL CHECK (booking_status IN ('Confirmed', 'Pending', 'Cancelled')),
    booking_date   DATE DEFAULT SYSDATE
);

CREATE TABLE booking_attraction (
    booking_id    NUMBER NOT NULL REFERENCES booking(booking_id) ON DELETE CASCADE,
    attraction_id NUMBER NOT NULL REFERENCES attraction(attraction_id),
    PRIMARY KEY (booking_id, attraction_id)
);

CREATE TABLE payment (
    payment_id NUMBER PRIMARY KEY,
    booking_id NUMBER NOT NULL REFERENCES booking(booking_id) ON DELETE CASCADE,
    pay_method VARCHAR2(20) NOT NULL CHECK (pay_method IN ('Card', 'Cash', 'Bank', 'Unpaid')),
    pay_status VARCHAR2(15) NOT NULL CHECK (pay_status IN ('Paid', 'Pending', 'Refunded', 'Cancelled')),
    amount     NUMBER(12) NOT NULL,
    pay_date   DATE DEFAULT SYSDATE
);

-- ============================================================
-- 3. SEQUENCES
-- ============================================================
CREATE SEQUENCE seq_customer START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_booking  START WITH 101 INCREMENT BY 1;
CREATE SEQUENCE seq_payment  START WITH 501 INCREMENT BY 1;

-- ============================================================
-- 4. DATA INSERT: 12 CITIES
-- ============================================================
INSERT INTO city VALUES (1,  'Islamabad');
INSERT INTO city VALUES (2,  'Lahore');
INSERT INTO city VALUES (3,  'Karachi');
INSERT INTO city VALUES (4,  'Murree');
INSERT INTO city VALUES (5,  'Skardu');
INSERT INTO city VALUES (6,  'Hunza');
INSERT INTO city VALUES (7,  'Swat');
INSERT INTO city VALUES (8,  'Naran');
INSERT INTO city VALUES (9,  'Multan');
INSERT INTO city VALUES (10, 'Peshawar');
INSERT INTO city VALUES (11, 'Quetta');
INSERT INTO city VALUES (12, 'Gilgit');

-- ============================================================
-- 5. DATA INSERT: 122 ATTRACTIONS (ISLAMABAD: 12, BAKI 11 CITIES: 10 EACH)
-- ============================================================
-- Islamabad (12)
INSERT INTO attraction VALUES (101, 1, 1,  'Shakarparian');
INSERT INTO attraction VALUES (102, 1, 2,  'Faisal Masjid');
INSERT INTO attraction VALUES (103, 1, 3,  'Pakistan Monument');
INSERT INTO attraction VALUES (104, 1, 4,  'Lok Virsa Museum');
INSERT INTO attraction VALUES (105, 1, 5,  'Daman-e-Koh');
INSERT INTO attraction VALUES (106, 1, 6,  'Margalla Hills Trail 3');
INSERT INTO attraction VALUES (107, 1, 7,  'Rawal Lake');
INSERT INTO attraction VALUES (108, 1, 8,  'Saidpur Village');
INSERT INTO attraction VALUES (109, 1, 9,  'Pir Sohawa');
INSERT INTO attraction VALUES (110, 1, 10, 'Centaurus Mall');
INSERT INTO attraction VALUES (111, 1, 11, 'Fatima Jinnah Park');
INSERT INTO attraction VALUES (112, 1, 12, 'Shah Allah Ditta Caves');

-- Lahore (10)
INSERT INTO attraction VALUES (201, 2, 1,  'Badshahi Mosque');
INSERT INTO attraction VALUES (202, 2, 2,  'Lahore Fort');
INSERT INTO attraction VALUES (203, 2, 3,  'Minar-e-Pakistan');
INSERT INTO attraction VALUES (204, 2, 4,  'Shalimar Gardens');
INSERT INTO attraction VALUES (205, 2, 5,  'Wagah Border');
INSERT INTO attraction VALUES (206, 2, 6,  'Wazir Khan Mosque');
INSERT INTO attraction VALUES (207, 2, 7,  'Lahore Museum');
INSERT INTO attraction VALUES (208, 2, 8,  'Anarkali Bazaar');
INSERT INTO attraction VALUES (209, 2, 9,  'Greater Iqbal Park');
INSERT INTO attraction VALUES (210, 2, 10, 'Food Street Fort Road');

-- Karachi (10)
INSERT INTO attraction VALUES (301, 3, 1,  'Clifton Beach');
INSERT INTO attraction VALUES (302, 3, 2,  'Mazar-e-Quaid');
INSERT INTO attraction VALUES (303, 3, 3,  'Mohatta Palace');
INSERT INTO attraction VALUES (304, 3, 4,  'Frere Hall');
INSERT INTO attraction VALUES (305, 3, 5,  'Port Grand');
INSERT INTO attraction VALUES (306, 3, 6,  'Hawksbay Beach');
INSERT INTO attraction VALUES (307, 3, 7,  'Manora Island');
INSERT INTO attraction VALUES (308, 3, 8,  'Pakistan Maritime Museum');
INSERT INTO attraction VALUES (309, 3, 9,  'Empress Market');
INSERT INTO attraction VALUES (310, 3, 10, 'Do Darya');

-- Murree (10)
INSERT INTO attraction VALUES (401, 4, 1,  'Mall Road');
INSERT INTO attraction VALUES (402, 4, 2,  'Patriata Chair Lift');
INSERT INTO attraction VALUES (403, 4, 3,  'Pindi Point');
INSERT INTO attraction VALUES (404, 4, 4,  'Kashmir Point');
INSERT INTO attraction VALUES (405, 4, 5,  'Bhurban');
INSERT INTO attraction VALUES (406, 4, 6,  'Ayubia National Park');
INSERT INTO attraction VALUES (407, 4, 7,  'Nathia Gali');
INSERT INTO attraction VALUES (408, 4, 8,  'Dunga Gali Pipeline Track');
INSERT INTO attraction VALUES (409, 4, 9,  'Changla Gali');
INSERT INTO attraction VALUES (410, 4, 10, 'Sozo Adventure Park');

-- Skardu (10)
INSERT INTO attraction VALUES (501, 5, 1,  'Shangrila Resort');
INSERT INTO attraction VALUES (502, 5, 2,  'Upper Kachura Lake');
INSERT INTO attraction VALUES (503, 5, 3,  'Deosai National Park');
INSERT INTO attraction VALUES (504, 5, 4,  'Shigar Fort');
INSERT INTO attraction VALUES (505, 5, 5,  'Katpana Cold Desert');
INSERT INTO attraction VALUES (506, 5, 6,  'Satpara Lake');
INSERT INTO attraction VALUES (507, 5, 7,  'Khaplu Palace');
INSERT INTO attraction VALUES (508, 5, 8,  'Manthoka Waterfall');
INSERT INTO attraction VALUES (509, 5, 9,  'Kharpocho Fort');
INSERT INTO attraction VALUES (510, 5, 10, 'Sarfaranga Cold Desert');

-- Hunza (10)
INSERT INTO attraction VALUES (601, 6, 1,  'Baltit Fort');
INSERT INTO attraction VALUES (602, 6, 2,  'Altit Fort');
INSERT INTO attraction VALUES (603, 6, 3,  'Attabad Lake');
INSERT INTO attraction VALUES (604, 6, 4,  'Passu Cones');
INSERT INTO attraction VALUES (605, 6, 5,  'Eagles Nest');
INSERT INTO attraction VALUES (606, 6, 6,  'Hussaini Suspension Bridge');
INSERT INTO attraction VALUES (607, 6, 7,  'Borith Lake');
INSERT INTO attraction VALUES (608, 6, 8,  'Khunjerab Pass');
INSERT INTO attraction VALUES (609, 6, 9,  'Hopper Glacier');
INSERT INTO attraction VALUES (610, 6, 10, 'Karimabad Bazaar');

-- Swat (10)
INSERT INTO attraction VALUES (701, 7, 1,  'Malam Jabba');
INSERT INTO attraction VALUES (702, 7, 2,  'Kalam Valley');
INSERT INTO attraction VALUES (703, 7, 3,  'Mahodand Lake');
INSERT INTO attraction VALUES (704, 7, 4,  'Mingora Bazaar');
INSERT INTO attraction VALUES (705, 7, 5,  'White Palace Marghazar');
INSERT INTO attraction VALUES (706, 7, 6,  'Fizagat Park');
INSERT INTO attraction VALUES (707, 7, 7,  'Ushu Forest');
INSERT INTO attraction VALUES (708, 7, 8,  'Bahrain Valley');
INSERT INTO attraction VALUES (709, 7, 9,  'Kundol Lake');
INSERT INTO attraction VALUES (710, 7, 10, 'Swat Museum');

-- Naran (10)
INSERT INTO attraction VALUES (801, 8, 1,  'Lake Saif-ul-Malook');
INSERT INTO attraction VALUES (802, 8, 2,  'Babusar Top');
INSERT INTO attraction VALUES (803, 8, 3,  'Lulusar Lake');
INSERT INTO attraction VALUES (804, 8, 4,  'Shogran');
INSERT INTO attraction VALUES (805, 8, 5,  'Siri Paye');
INSERT INTO attraction VALUES (806, 8, 6,  'Ansoo Lake');
INSERT INTO attraction VALUES (807, 8, 7,  'Lalazar Meadows');
INSERT INTO attraction VALUES (808, 8, 8,  'Kunhar River Rafting');
INSERT INTO attraction VALUES (809, 8, 9,  'Batakundi');
INSERT INTO attraction VALUES (810, 8, 10, 'Jalkhad');

-- Multan (10)
INSERT INTO attraction VALUES (901, 9, 1,  'Tomb of Shah Rukn-e-Alam');
INSERT INTO attraction VALUES (902, 9, 2,  'Ghanta Ghar');
INSERT INTO attraction VALUES (903, 9, 3,  'Shrine of Bahauddin Zakariya');
INSERT INTO attraction VALUES (904, 9, 4,  'Hussain Agahi Bazaar');
INSERT INTO attraction VALUES (905, 9, 5,  'Multan Fort');
INSERT INTO attraction VALUES (906, 9, 6,  'Shah Shams Tabriz Tomb');
INSERT INTO attraction VALUES (907, 9, 7,  'Multan Arts Council');
INSERT INTO attraction VALUES (908, 9, 8,  'Yadgar-e-Shuhada Park');
INSERT INTO attraction VALUES (909, 9, 9,  'Garrison Public Library');
INSERT INTO attraction VALUES (910, 9, 10, 'Chenab River Bridge Point');

-- Peshawar (10)
INSERT INTO attraction VALUES (1001, 10, 1,  'Qissa Khwani Bazaar');
INSERT INTO attraction VALUES (1002, 10, 2,  'Bala Hisar Fort');
INSERT INTO attraction VALUES (1003, 10, 3,  'Mahabat Khan Mosque');
INSERT INTO attraction VALUES (1004, 10, 4,  'Peshawar Museum');
INSERT INTO attraction VALUES (1005, 10, 5,  'Sethi House');
INSERT INTO attraction VALUES (1006, 10, 6,  'Islamia College Peshawar');
INSERT INTO attraction VALUES (1007, 10, 7,  'Namak Mandi');
INSERT INTO attraction VALUES (1008, 10, 8,  'Khyber Pass Gate');
INSERT INTO attraction VALUES (1009, 10, 9,  'Shahi Bagh');
INSERT INTO attraction VALUES (1010, 10, 10, 'Gorkhatri Heritage Complex');

-- Quetta (10)
INSERT INTO attraction VALUES (1101, 11, 1,  'Hanna Lake');
INSERT INTO attraction VALUES (1102, 11, 2,  'Ziarat Residency');
INSERT INTO attraction VALUES (1103, 11, 3,  'Urak Valley');
INSERT INTO attraction VALUES (1104, 11, 4,  'Hazarganji National Park');
INSERT INTO attraction VALUES (1105, 11, 5,  'Bolan Pass');
INSERT INTO attraction VALUES (1106, 11, 6,  'Wali Tangi Dam');
INSERT INTO attraction VALUES (1107, 11, 7,  'Quetta Geological Museum');
INSERT INTO attraction VALUES (1108, 11, 8,  'Pir Ghaib Waterfall');
INSERT INTO attraction VALUES (1109, 11, 9,  'Karkhasa Park');
INSERT INTO attraction VALUES (1110, 11, 10, 'Liaquat Bazaar');

-- Gilgit (10)
INSERT INTO attraction VALUES (1201, 12, 1,  'Naltar Valley');
INSERT INTO attraction VALUES (1202, 12, 2,  'Kargah Buddha');
INSERT INTO attraction VALUES (1203, 12, 3,  'Rakaposhi View Point');
INSERT INTO attraction VALUES (1204, 12, 4,  'Fairy Meadows');
INSERT INTO attraction VALUES (1205, 12, 5,  'Chinar Bagh');
INSERT INTO attraction VALUES (1206, 12, 6,  'Phander Valley');
INSERT INTO attraction VALUES (1207, 12, 7,  'Naltar Rainbow Lake');
INSERT INTO attraction VALUES (1208, 12, 8,  'Danyor Suspension Bridge');
INSERT INTO attraction VALUES (1209, 12, 9,  'Three Mountain Junction');
INSERT INTO attraction VALUES (1210, 12, 10, 'Gilgit River View');

-- ============================================================
-- 6. DATA INSERT: 125 HOTELS (ISLAMABAD: 15, BAKI 11 CITIES: 10 EACH)
--    (WITH BREAKFAST, LUNCH, DINNER)
-- ============================================================
-- Islamabad (15 Hotels)
INSERT INTO hotel VALUES (101, 1, 1,  'Serena Hotel Islamabad',     45000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (102, 1, 2,  'Marriott Hotel Islamabad',   42000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (103, 1, 3,  'Centaurus Suites',           35000, 'Yes', 'Yes', 'No');
INSERT INTO hotel VALUES (104, 1, 4,  'Ramada by Wyndham',          28000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (105, 1, 5,  'Islamabad Hotel',            22000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (106, 1, 6,  'Margalla Hotel',             18000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (107, 1, 7,  'Best Western Premier',       25000, 'Yes', 'Yes', 'No');
INSERT INTO hotel VALUES (108, 1, 8,  'Hotel One Super F-6',        16000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (109, 1, 9,  'Roomy Signature Hotel',      19000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (110, 1, 10, 'Envoy Continental Hotel',    14000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (111, 1, 11, 'Shelton Guest House F-7',    11000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (112, 1, 12, 'Hill View Hotel F-7',        12000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (113, 1, 13, 'Blue Area Executive Inn',     9000, 'No',  'No',  'No');
INSERT INTO hotel VALUES (114, 1, 14, 'G-9 Budget Lodge',            6500, 'No',  'No',  'No');
INSERT INTO hotel VALUES (115, 1, 15, 'Backpackers Inn F-8',         5000, 'No',  'No',  'No');

-- Lahore (10 Hotels)
INSERT INTO hotel VALUES (201, 2, 1,  'Pearl Continental Lahore',   32000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (202, 2, 2,  'Nishat Hotel Gulberg',       26000, 'Yes', 'Yes', 'No');
INSERT INTO hotel VALUES (203, 2, 3,  'Avari Hotel Lahore',         28000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (204, 2, 4,  'Falettis Hotel Lahore',      22000, 'Yes', 'Yes', 'No');
INSERT INTO hotel VALUES (205, 2, 5,  'Luxus Grand Hotel',          18000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (206, 2, 6,  'Park Lane Hotel Gulberg',    16000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (207, 2, 7,  'Hotel One Mall Road',        12000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (208, 2, 8,  'Indigo Heights Hotel',       15000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (209, 2, 9,  'Liberty Executive Inn',       9500, 'No',  'No',  'No');
INSERT INTO hotel VALUES (210, 2, 10, 'Lahore Budget Inn',           7000, 'No',  'No',  'No');

-- Karachi (10 Hotels)
INSERT INTO hotel VALUES (301, 3, 1,  'Movenpick Karachi',          30000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (302, 3, 2,  'Avari Towers Karachi',       28000, 'Yes', 'Yes', 'No');
INSERT INTO hotel VALUES (303, 3, 3,  'Pearl Continental Karachi',  31000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (304, 3, 4,  'Marriott Karachi',           29000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (305, 3, 5,  'Ramada Plaza Karachi',       21000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (306, 3, 6,  'Beach Luxury Hotel',         15000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (307, 3, 7,  'Hotel Mehran Karachi',       13000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (308, 3, 8,  'Regent Plaza Hotel',         14000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (309, 3, 9,  'DHA Sea View Suites',        10000, 'No',  'No',  'No');
INSERT INTO hotel VALUES (310, 3, 10, 'Clifton Guest House',         7500, 'No',  'No',  'No');

-- Murree (10 Hotels)
INSERT INTO hotel VALUES (401, 4, 1,  'PC Bhurban Murree',          38000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (402, 4, 2,  'Shangrila Pines Murree',     18000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (403, 4, 3,  'Lockwood Hotel Murree',      15000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (404, 4, 4,  'Cecil Hotel Murree',         24000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (405, 4, 5,  'Grand Taj Hotel Murree',     14000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (406, 4, 6,  'Move n Pick Murree',         12000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (407, 4, 7,  'Pine View Resort',            9500, 'No',  'No',  'Yes');
INSERT INTO hotel VALUES (408, 4, 8,  'Kashmir Point Lodge',         8500, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (409, 4, 9,  'Fiora Hotel Murree',         13000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (410, 4, 10, 'Mall Road Budget Hotel',      6000, 'No',  'No',  'No');

-- Skardu (10 Hotels)
INSERT INTO hotel VALUES (501, 5, 1,  'Shangrila Resort Skardu',    35000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (502, 5, 2,  'Khoj Resorts Skardu',        28000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (503, 5, 3,  'Serena Shigar Fort',         32000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (504, 5, 4,  'Serena Khaplu Palace',       30000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (505, 5, 5,  'Byarsa Hotel Skardu',        16000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (506, 5, 6,  'Legend Hotel Skardu',        14000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (507, 5, 7,  'Himalaya Hotel Skardu',      11000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (508, 5, 8,  'K2 Motel Skardu',            12000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (509, 5, 9,  'Baltistan Continental',       9500, 'No',  'No',  'No');
INSERT INTO hotel VALUES (510, 5, 10, 'Skardu Valley Lodge',         7500, 'No',  'No',  'No');

-- Hunza (10 Hotels)
INSERT INTO hotel VALUES (601, 6, 1,  'Hunza Serena Inn',           32000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (602, 6, 2,  'Luxus Hunza Resort',         28000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (603, 6, 3,  'Eagles Nest Hotel',          18000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (604, 6, 4,  'Famree Resort Attabad',      22000, 'Yes', 'Yes', 'No');
INSERT INTO hotel VALUES (605, 6, 5,  'Hard Rock Hunza',            14000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (606, 6, 6,  'Roomy Dastan Karimabad',     12000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (607, 6, 7,  'Hunza Embassy Hotel',        13500, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (608, 6, 8,  'Mulberry Hotel Hunza',       11000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (609, 6, 9,  'Passu Peak Inn',              8500, 'No',  'No',  'No');
INSERT INTO hotel VALUES (610, 6, 10, 'Karimabad Guest House',       6500, 'No',  'No',  'No');

-- Swat (10 Hotels)
INSERT INTO hotel VALUES (701, 7, 1,  'PC Malam Jabba',             30000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (702, 7, 2,  'Swat Serena Hotel',          22000, 'Yes', 'Yes', 'No');
INSERT INTO hotel VALUES (703, 7, 3,  'Rock City Resort Fizagat',   16000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (704, 7, 4,  'Walnut Heights Kalam',       14000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (705, 7, 5,  'Burj Al Swat Hotel',         13000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (706, 7, 6,  'Swat Continental Hotel',     10000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (707, 7, 7,  'Greens Hotel Mingora',       11000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (708, 7, 8,  'Honeymoon Hotel Kalam',       9500, 'No',  'No',  'Yes');
INSERT INTO hotel VALUES (709, 7, 9,  'Bahrain Riverside Lodge',     8000, 'No',  'No',  'No');
INSERT INTO hotel VALUES (710, 7, 10, 'Kalam River View Inn',        6500, 'No',  'No',  'No');

-- Naran (10 Hotels)
INSERT INTO hotel VALUES (801, 8, 1,  'Northern Retreat Naran',     18000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (802, 8, 2,  'Hotel Demanchi Naran',       15000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (803, 8, 3,  'Pine Park Shogran',          16000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (804, 8, 4,  'Grand Heritage Naran',       17000, 'Yes', 'Yes', 'No');
INSERT INTO hotel VALUES (805, 8, 5,  'Maisonette Firhill Naran',   14500, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (806, 8, 6,  'Kunhar View Hotel',          11000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (807, 8, 7,  'Sarai Silk Route Naran',     12500, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (808, 8, 8,  'Fairy Meadows Inn Naran',     8500, 'No',  'No',  'No');
INSERT INTO hotel VALUES (809, 8, 9,  'Batakundi Mountain Lodge',    7000, 'No',  'No',  'No');
INSERT INTO hotel VALUES (810, 8, 10, 'Naran Budget Camp',           5500, 'No',  'No',  'No');

-- Multan (10 Hotels)
INSERT INTO hotel VALUES (901, 9, 1,  'Ramada Multan',              24000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (902, 9, 2,  'Avari Xpress Multan',        16000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (903, 9, 3,  'Hotel One Multan',           13000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (904, 9, 4,  'Falettis Grand Multan',      14000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (905, 9, 5,  'Rumanza Golf Resort',        26000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (906, 9, 6,  'Sindbad Hotel Multan',       11500, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (907, 9, 7,  'Sadaf Hotel Multan',          9000, 'No',  'No',  'No');
INSERT INTO hotel VALUES (908, 9, 8,  'Cantt Executive Suites',     10500, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (909, 9, 9,  'Gulgasht Guest House',        7500, 'No',  'No',  'No');
INSERT INTO hotel VALUES (910, 9, 10, 'Multan City Lodge',           6000, 'No',  'No',  'No');

-- Peshawar (10 Hotels)
INSERT INTO hotel VALUES (1001, 10, 1,  'Pearl Continental Peshawar', 26000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (1002, 10, 2,  'Shelton Rezidor Peshawar',   15000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (1003, 10, 3,  'Fort Continental Hotel',     12000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (1004, 10, 4,  'Greens Hotel Peshawar',      11000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (1005, 10, 5,  'Peshawar Serena Annex',      18000, 'Yes', 'Yes', 'No');
INSERT INTO hotel VALUES (1006, 10, 6,  'Hayatabad Executive Inn',    10500, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (1007, 10, 7,  'University Town Suites',      9500, 'No',  'No',  'No');
INSERT INTO hotel VALUES (1008, 10, 8,  'Emirates Hotel Saddar',       8500, 'No',  'No',  'No');
INSERT INTO hotel VALUES (1009, 10, 9,  'Khyber View Guest House',     7000, 'No',  'No',  'No');
INSERT INTO hotel VALUES (1010, 10, 10, 'Saddar Budget Inn',           5500, 'No',  'No',  'No');

-- Quetta (10 Hotels)
INSERT INTO hotel VALUES (1101, 11, 1,  'Quetta Serena Hotel',        28000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (1102, 11, 2,  'Bloom Star Hotel Quetta',    13000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (1103, 11, 3,  'Grand Hotel Quetta',         11000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (1104, 11, 4,  'Lourdes Hotel Quetta',       12000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (1105, 11, 5,  'Quetta Club Suites',         16000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (1106, 11, 6,  'Bolan Continental Hotel',    10000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (1107, 11, 7,  'Zarghoon Road Inn',           9000, 'No',  'No',  'No');
INSERT INTO hotel VALUES (1108, 11, 8,  'White Hotel Jinnah Road',     8000, 'No',  'No',  'No');
INSERT INTO hotel VALUES (1109, 11, 9,  'Hanna Valley Lodge',          7000, 'No',  'No',  'No');
INSERT INTO hotel VALUES (1110, 11, 10, 'Jinnah Road Guest House',     6000, 'No',  'No',  'No');

-- Gilgit (10 Hotels)
INSERT INTO hotel VALUES (1201, 12, 1,  'Gilgit Serena Hotel',        26000, 'Yes', 'Yes', 'Yes');
INSERT INTO hotel VALUES (1202, 12, 2,  'Ramada Gilgit',              20000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (1203, 12, 3,  'Riveria Hotel Gilgit',       14000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (1204, 12, 4,  'Kallisto Hotel Gilgit',      12000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (1205, 12, 5,  'Karakoram Lodge Gilgit',     15000, 'Yes', 'No',  'Yes');
INSERT INTO hotel VALUES (1206, 12, 6,  'Madina Hotel Gilgit',        10000, 'Yes', 'No',  'No');
INSERT INTO hotel VALUES (1207, 12, 7,  'Park Hotel Gilgit',           9000, 'No',  'No',  'No');
INSERT INTO hotel VALUES (1208, 12, 8,  'Danyor Riverside Inn',        8500, 'No',  'No',  'No');
INSERT INTO hotel VALUES (1209, 12, 9,  'Jutial Executive Lodge',      7500, 'No',  'No',  'No');
INSERT INTO hotel VALUES (1210, 12, 10, 'Naltar Base Lodge',           6500, 'No',  'No',  'No');

-- ============================================================
-- 7. DATA INSERT: TRANSPORT (1 PUBLIC + 8 PRIVATE VEHICLES = 9 TOTAL)
--    Format: (id, category, vehicle_name, car_rent, driver_fee, service_tax, daily_total)
--    Note: Petrol/Fuel customer khud pay karega
-- ============================================================
INSERT INTO transport VALUES (1, 'Public',  'Public Transport (Self)',       0,     0,    0,    0);
INSERT INTO transport VALUES (2, 'Private', 'Suzuki Alto (4 Seater)',        3000,  2000, 500,  5500);
INSERT INTO transport VALUES (3, 'Private', 'Suzuki Cultus (4 Seater)',      3500,  2500, 1000, 7000);
INSERT INTO transport VALUES (4, 'Private', 'Toyota Corolla (Sedan)',        4000,  4000, 2000, 10000);
INSERT INTO transport VALUES (5, 'Private', 'Honda Civic (Comfort)',         5500,  4000, 2000, 11500);
INSERT INTO transport VALUES (6, 'Private', 'Kia Sportage (Crossover)',      7500,  4000, 2000, 13500);
INSERT INTO transport VALUES (7, 'Private', 'Toyota Fortuner (7 Seat SUV)',  9500,  4500, 2500, 16500);
INSERT INTO transport VALUES (8, 'Private', 'Toyota Prado (4x4 Luxury)',    11000,  4500, 2500, 18000);
INSERT INTO transport VALUES (9, 'Private', 'Toyota HiAce (12 Seater Van)',  8500,  4000, 2000, 14500);

-- ============================================================
-- 8. DATA INSERT: 120 TOUR GUIDES (HAR CITY KE 10 GUIDES)
-- ============================================================
DECLARE
    TYPE t_names IS VARRAY(10) OF VARCHAR2(30);
    v_first t_names := t_names('Ali', 'Bilal', 'Usman', 'Hamza', 'Zainab', 'Saad', 'Ayesha', 'Kamran', 'Faisal', 'Hina');
    v_last  t_names := t_names('Raza', 'Ahmed', 'Tariq', 'Khan', 'Malik', 'Mahmood', 'Noor', 'Shah', 'Javed', 'Siddiqui');
    v_gid   NUMBER := 1;
    v_half  NUMBER;
    v_full  NUMBER;
BEGIN
    FOR c IN 1..12 LOOP
        FOR g IN 1..10 LOOP
            v_half := 2000 + (MOD(g, 4) * 300);
            v_full := v_half + 1800;

            INSERT INTO tour_guide (guide_id, city_id, guide_no, guide_name, phone, half_day_rate, full_day_rate)
            VALUES (
                v_gid,
                c,
                g,
                v_first(g) || ' ' || v_last(MOD(c + g - 2, 10) + 1),
                '03' || LPAD(c, 2, '0') || '-111' || LPAD(v_gid, 4, '0'),
                v_half,
                v_full
            );

            v_gid := v_gid + 1;
        END LOOP;
    END LOOP;
END;
/

-- ============================================================
-- 9. SAMPLE BOOKINGS (INITIAL DATA TAKEY ADMIN PANEL EMPTY NA HO)
-- ============================================================
DECLARE
    v_cid NUMBER;
    v_bid NUMBER;
BEGIN
    -- Sample 1: Islamabad (Confirmed, Card)
    v_cid := seq_customer.NEXTVAL;
    v_bid := seq_booking.NEXTVAL;
    INSERT INTO customer VALUES (v_cid, 'Ahmed Raza', '0300-5551001', 'ahmed.raza@email.com');
    INSERT INTO booking VALUES (v_bid, v_cid, 1, 104, 1, 2, 2, 56000, 4, 20000, 1, 'Full Day', 2, 8200, 84200, 'Confirmed', SYSDATE - 3);
    INSERT INTO booking_attraction VALUES (v_bid, 101);
    INSERT INTO booking_attraction VALUES (v_bid, 102);
    INSERT INTO booking_attraction VALUES (v_bid, 105);
    INSERT INTO payment VALUES (seq_payment.NEXTVAL, v_bid, 'Card', 'Paid', 84200, SYSDATE - 3);

    -- Sample 2: Skardu (Confirmed, Bank)
    v_cid := seq_customer.NEXTVAL;
    v_bid := seq_booking.NEXTVAL;
    INSERT INTO customer VALUES (v_cid, 'Sara Khan', '0321-5551002', 'sara.khan@email.com');
    INSERT INTO booking VALUES (v_bid, v_cid, 5, 501, 2, 3, 4, 210000, 8, 54000, 41, 'Full Day', 3, 12300, 276300, 'Confirmed', SYSDATE - 2);
    INSERT INTO booking_attraction VALUES (v_bid, 501);
    INSERT INTO booking_attraction VALUES (v_bid, 502);
    INSERT INTO booking_attraction VALUES (v_bid, 503);
    INSERT INTO payment VALUES (seq_payment.NEXTVAL, v_bid, 'Bank', 'Paid', 276300, SYSDATE - 2);

    -- Sample 3: Murree (Pending, Unpaid)
    v_cid := seq_customer.NEXTVAL;
    v_bid := seq_booking.NEXTVAL;
    INSERT INTO customer VALUES (v_cid, 'Hassan Ali', '0333-5551003', 'hassan.ali@email.com');
    INSERT INTO booking VALUES (v_bid, v_cid, 4, 402, 1, 2, 2, 36000, 1, 0, NULL, 'None', 0, 0, 36000, 'Pending', SYSDATE - 1);
    INSERT INTO booking_attraction VALUES (v_bid, 401);
    INSERT INTO booking_attraction VALUES (v_bid, 402);
    INSERT INTO payment VALUES (seq_payment.NEXTVAL, v_bid, 'Unpaid', 'Pending', 36000, SYSDATE - 1);

    -- Sample 4: Hunza (Confirmed, Cash)
    v_cid := seq_customer.NEXTVAL;
    v_bid := seq_booking.NEXTVAL;
    INSERT INTO customer VALUES (v_cid, 'Ayesha Tariq', '0345-5551004', 'ayesha.tariq@email.com');
    INSERT INTO booking VALUES (v_bid, v_cid, 6, 601, 1, 3, 3, 96000, 7, 49500, 52, 'Half Day', 2, 5200, 150700, 'Confirmed', SYSDATE - 1);
    INSERT INTO booking_attraction VALUES (v_bid, 601);
    INSERT INTO booking_attraction VALUES (v_bid, 603);
    INSERT INTO booking_attraction VALUES (v_bid, 604);
    INSERT INTO payment VALUES (seq_payment.NEXTVAL, v_bid, 'Cash', 'Paid', 150700, SYSDATE - 1);

    -- Sample 5: Lahore (Cancelled, Refunded)
    v_cid := seq_customer.NEXTVAL;
    v_bid := seq_booking.NEXTVAL;
    INSERT INTO customer VALUES (v_cid, 'Usman Farooq', '0312-5551005', 'usman.farooq@email.com');
    INSERT INTO booking VALUES (v_bid, v_cid, 2, 202, 1, 1, 2, 26000, 2, 5500, NULL, 'None', 0, 0, 31500, 'Cancelled', SYSDATE);
    INSERT INTO booking_attraction VALUES (v_bid, 201);
    INSERT INTO booking_attraction VALUES (v_bid, 202);
    INSERT INTO payment VALUES (seq_payment.NEXTVAL, v_bid, 'Card', 'Refunded', 31500, SYSDATE);
END;
/

COMMIT;

-- ============================================================
-- 10. SUMMARY VIEW
-- ============================================================
CREATE OR REPLACE VIEW v_booking_summary AS
SELECT b.booking_id,
       c.full_name      AS customer,
       c.phone,
       ci.city_name     AS city,
       h.hotel_name     AS hotel,
       b.rooms,
       b.nights,
       b.persons,
       t.category       AS trans_type,
       t.vehicle_name   AS transport,
       NVL(g.guide_name, 'No Guide') AS guide,
       b.guide_type,
       b.guide_days,
       b.total_cost,
       p.pay_method,
       p.pay_status,
       b.booking_status,
       TO_CHAR(b.booking_date, 'DD-Mon-YYYY') AS booked_on
FROM   booking b
JOIN   customer   c  ON c.customer_id  = b.customer_id
JOIN   city       ci ON ci.city_id     = b.city_id
JOIN   hotel      h  ON h.hotel_id     = b.hotel_id
JOIN   transport  t  ON t.transport_id = b.transport_id
LEFT JOIN tour_guide g ON g.guide_id   = b.guide_id
LEFT JOIN payment    p ON p.booking_id = b.booking_id;

-- ============================================================
-- 11. SETUP COMPLETE REPORT
-- ============================================================
DECLARE
    v_cities NUMBER;
    v_attrs  NUMBER;
    v_hotels NUMBER;
    v_trans  NUMBER;
    v_guides NUMBER;
    v_books  NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cities FROM city;
    SELECT COUNT(*) INTO v_attrs  FROM attraction;
    SELECT COUNT(*) INTO v_hotels FROM hotel;
    SELECT COUNT(*) INTO v_trans  FROM transport;
    SELECT COUNT(*) INTO v_guides FROM tour_guide;
    SELECT COUNT(*) INTO v_books  FROM booking;

    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('      TOURISM DATABASE SETUP COMPLETE REPORT      ');
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('Total Cities             : ' || v_cities);
    DBMS_OUTPUT.PUT_LINE('Total Attractions (All)  : ' || v_attrs || ' (Isb: 12, Others: 10 each)');
    DBMS_OUTPUT.PUT_LINE('Total Hotels             : ' || v_hotels || ' (Isb: 15, Others: 10 each)');
    DBMS_OUTPUT.PUT_LINE('Total Transport Options  : ' || v_trans || ' (1 Public + 8 Private)');
    DBMS_OUTPUT.PUT_LINE('Total Tour Guides        : ' || v_guides || ' (10 per city)');
    DBMS_OUTPUT.PUT_LINE('Sample Bookings Loaded   : ' || v_books);
    DBMS_OUTPUT.PUT_LINE('==================================================');
END;
/

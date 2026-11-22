SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET VERIFY OFF
SET LINESIZE 180
SET PAGESIZE 50

UNDEFINE v_name v_phone v_email v_city_id v_place_mode v_places
UNDEFINE v_hotel_no v_rooms v_nights v_persons
UNDEFINE v_trans_opt v_vehicle_id
UNDEFINE v_guide_opt v_guide_no v_guide_type v_guide_days
UNDEFINE v_pay_opt

-- ============================================================
-- STEP 1: CUSTOMER DETAILS
-- ============================================================
PROMPT =============================================
PROMPT        STEP 1: ENTER YOUR DETAILS
PROMPT =============================================
ACCEPT v_name  CHAR PROMPT 'Enter Full Name: '
ACCEPT v_phone CHAR PROMPT 'Enter Phone Number: '
ACCEPT v_email CHAR PROMPT 'Enter Email Address: '

-- ============================================================
-- STEP 2: SHOW 12 CITIES & SELECT CITY
-- ============================================================
PROMPT
PROMPT =============================================
PROMPT        STEP 2: AVAILABLE 12 CITIES
PROMPT =============================================
SELECT city_id AS "ID", city_name AS "City Name"
FROM city
ORDER BY city_id;

ACCEPT v_city_id CHAR PROMPT 'Select City ID (1 to 12): '

-- ============================================================
-- STEP 3: SHOW ATTRACTIONS (SINGLE / MULTIPLE)
-- ============================================================
PROMPT
PROMPT =============================================
PROMPT      STEP 3: ATTRACTIONS IN SELECTED CITY
PROMPT =============================================
SELECT place_no AS "Place No", attraction_name AS "Attraction Name"
FROM attraction
WHERE city_id = TO_NUMBER(NVL(TRIM('&v_city_id'), '1'))
ORDER BY place_no;

PROMPT Choose Mode: 1 = Single Place | 2 = Multiple Places
ACCEPT v_place_mode CHAR PROMPT 'Enter Mode (1 or 2): '
ACCEPT v_places     CHAR PROMPT 'Enter Place No (Single: e.g. 2 | Multiple: e.g. 1,2,5,0 to finish): '

-- ============================================================
-- STEP 4: SHOW HOTELS (WITH BREAKFAST, LUNCH, DINNER)
-- ============================================================
PROMPT
PROMPT =============================================
PROMPT        STEP 4: HOTELS IN SELECTED CITY
PROMPT =============================================
SELECT hotel_no        AS "No",
       hotel_name      AS "Hotel Name",
       price_per_night AS "Price/Night",
       breakfast       AS "Breakfast",
       lunch           AS "Lunch",
       dinner          AS "Dinner"
FROM hotel
WHERE city_id = TO_NUMBER(NVL(TRIM('&v_city_id'), '1'))
ORDER BY hotel_no;

ACCEPT v_hotel_no CHAR PROMPT 'Select Hotel No: '
ACCEPT v_rooms    CHAR PROMPT 'Number of Rooms: '
ACCEPT v_nights   CHAR PROMPT 'Number of Nights: '
ACCEPT v_persons  CHAR PROMPT 'Number of Persons: '

-- ============================================================
-- STEP 5: TRANSPORT (1 PUBLIC + 8 PRIVATE | FUEL BY CUSTOMER)
-- ============================================================
PROMPT
PROMPT ====================================================================
PROMPT   STEP 5: TRANSPORT OPTIONS (Car + Driver + Tax | Petrol by Self)
PROMPT ====================================================================
PROMPT 1 = Public Transport (Rs. 0 Fare - Apni marzi se travel karein)
PROMPT 2 = Private Transport (Car + Driver per day, Petrol customer khud dalwayega)
SELECT transport_id AS "ID",
       vehicle_name AS "Private Vehicle",
       car_rent     AS "Car/Day",
       driver_fee   AS "Driver/Day",
       service_tax  AS "Tax/Day",
       daily_total  AS "Total/Day"
FROM transport
WHERE category = 'Private'
ORDER BY transport_id;

ACCEPT v_trans_opt  CHAR PROMPT 'Select Transport Type (1=Public, 2=Private): '
ACCEPT v_vehicle_id CHAR PROMPT 'Enter Private Vehicle ID 2-9 (Enter 0 if Public): '

-- ============================================================
-- STEP 6: TOUR GUIDES (SELECTED CITY KE 10 GUIDES)
-- ============================================================
PROMPT
PROMPT =============================================
PROMPT   STEP 6: TOUR GUIDES IN SELECTED CITY (10)
PROMPT =============================================
SELECT guide_no      AS "No",
       guide_name    AS "Guide Name",
       phone         AS "Phone",
       half_day_rate AS "Half Day (Rs)",
       full_day_rate AS "Full Day (Rs)"
FROM tour_guide
WHERE city_id = TO_NUMBER(NVL(TRIM('&v_city_id'), '1'))
ORDER BY guide_no;

ACCEPT v_guide_opt  CHAR PROMPT 'Do you want a Guide? (1=Yes, 0=No): '
ACCEPT v_guide_no   CHAR PROMPT 'Enter Guide No 1-10 (Enter 0 if No Guide): '
ACCEPT v_guide_type CHAR PROMPT 'Guide Type (1=Half Day, 2=Full Day, 0=Skip): '
ACCEPT v_guide_days CHAR PROMPT 'Guide Days (Must be <= Nights, 0=Skip): '

-- ============================================================
-- STEP 7: PAYMENT OPTION
-- ============================================================
PROMPT
PROMPT =============================================
PROMPT           STEP 7: PAYMENT OPTIONS
PROMPT =============================================
PROMPT 1 = Card (Confirmed)
PROMPT 2 = Cash (Confirmed)
PROMPT 3 = Bank Transfer (Confirmed)
PROMPT 0 = Pay Later (Pending - Not Confirmed)
ACCEPT v_pay_opt CHAR PROMPT 'Select Payment Option (1, 2, 3 or 0): '

-- ============================================================
-- STEP 8: PROCESS BOOKING & PRINT RECEIPT
-- ============================================================
DECLARE
    v_city_id       NUMBER := TO_NUMBER(NVL(TRIM('&v_city_id'), '1'));
    v_place_mode    NUMBER := TO_NUMBER(NVL(TRIM('&v_place_mode'), '1'));
    v_places_str    VARCHAR2(200) := TRIM('&v_places');
    v_hotel_no      NUMBER := TO_NUMBER(NVL(TRIM('&v_hotel_no'), '1'));
    v_rooms         NUMBER := GREATEST(1, TO_NUMBER(NVL(TRIM('&v_rooms'), '1')));
    v_nights        NUMBER := GREATEST(1, TO_NUMBER(NVL(TRIM('&v_nights'), '1')));
    v_persons       NUMBER := GREATEST(1, TO_NUMBER(NVL(TRIM('&v_persons'), '1')));
    v_trans_opt     NUMBER := TO_NUMBER(NVL(TRIM('&v_trans_opt'), '1'));
    v_vehicle_id    NUMBER := TO_NUMBER(NVL(TRIM('&v_vehicle_id'), '0'));
    v_guide_opt     NUMBER := TO_NUMBER(NVL(TRIM('&v_guide_opt'), '0'));
    v_guide_no_in   NUMBER := TO_NUMBER(NVL(TRIM('&v_guide_no'), '0'));
    v_guide_type_in NUMBER := TO_NUMBER(NVL(TRIM('&v_guide_type'), '0'));
    v_guide_days_in NUMBER := TO_NUMBER(NVL(TRIM('&v_guide_days'), '0'));
    v_pay_opt       NUMBER := TO_NUMBER(NVL(TRIM('&v_pay_opt'), '0'));

    v_cust_id       NUMBER;
    v_book_id       NUMBER;
    v_pay_id        NUMBER;
    v_city_name     VARCHAR2(50);

    v_hotel_id      NUMBER;
    v_hotel_name    VARCHAR2(80);
    v_hotel_price   NUMBER;
    v_bf            VARCHAR2(5);
    v_ln            VARCHAR2(5);
    v_dn            VARCHAR2(5);
    v_hotel_cost    NUMBER := 0;

    v_trans_id      NUMBER := 1;
    v_trans_name    VARCHAR2(60);
    v_car_rent      NUMBER := 0;
    v_driver_fee    NUMBER := 0;
    v_service_tax   NUMBER := 0;
    v_daily_total   NUMBER := 0;
    v_trans_cost    NUMBER := 0;

    v_guide_id      NUMBER := NULL;
    v_guide_name    VARCHAR2(60) := 'No Guide';
    v_guide_type    VARCHAR2(15) := 'None';
    v_guide_days    NUMBER := 0;
    v_guide_rate    NUMBER := 0;
    v_guide_cost    NUMBER := 0;

    v_total_cost    NUMBER := 0;
    v_pay_method    VARCHAR2(20);
    v_pay_status    VARCHAR2(15);
    v_book_status   VARCHAR2(15);

    v_token         VARCHAR2(20);
    v_place_num     NUMBER;
    v_attr_id       NUMBER;
    v_attr_name     VARCHAR2(80);
    v_places_list   VARCHAR2(500) := '';
    v_idx           NUMBER := 1;
BEGIN
    -- 1. Verify City
    SELECT city_name INTO v_city_name FROM city WHERE city_id = v_city_id;

    -- 2. Verify Hotel & Cost
    SELECT hotel_id, hotel_name, price_per_night, breakfast, lunch, dinner
    INTO   v_hotel_id, v_hotel_name, v_hotel_price, v_bf, v_ln, v_dn
    FROM   hotel
    WHERE  city_id = v_city_id AND hotel_no = v_hotel_no;

    v_hotel_cost := v_hotel_price * v_rooms * v_nights;

    -- 3. Transport Logic (Car + Driver + Tax, Excluding Fuel)
    IF v_trans_opt = 2 AND v_vehicle_id BETWEEN 2 AND 9 THEN
        SELECT transport_id, vehicle_name, car_rent, driver_fee, service_tax, daily_total
        INTO   v_trans_id, v_trans_name, v_car_rent, v_driver_fee, v_service_tax, v_daily_total
        FROM   transport
        WHERE  transport_id = v_vehicle_id AND category = 'Private';

        v_trans_cost := v_daily_total * v_nights;
    ELSE
        v_trans_id   := 1;
        v_trans_name := 'Public Transport (Self)';
        v_trans_cost := 0;
    END IF;

    -- 4. Guide Logic (City-specific Guide + Days <= Nights)
    IF v_guide_opt = 1 AND v_guide_no_in BETWEEN 1 AND 10 THEN
        IF v_guide_days_in <= 0 THEN
            v_guide_days := 1;
        ELSIF v_guide_days_in > v_nights THEN
            v_guide_days := v_nights;
            DBMS_OUTPUT.PUT_LINE('NOTE: Guide days trip ke nights (' || v_nights || ') se zyada nahi ho sakte. Auto-set to ' || v_nights || ' days.');
        ELSE
            v_guide_days := v_guide_days_in;
        END IF;

        IF v_guide_type_in = 1 THEN
            SELECT guide_id, guide_name, half_day_rate
            INTO   v_guide_id, v_guide_name, v_guide_rate
            FROM   tour_guide
            WHERE  city_id = v_city_id AND guide_no = v_guide_no_in;
            v_guide_type := 'Half Day';
        ELSE
            SELECT guide_id, guide_name, full_day_rate
            INTO   v_guide_id, v_guide_name, v_guide_rate
            FROM   tour_guide
            WHERE  city_id = v_city_id AND guide_no = v_guide_no_in;
            v_guide_type := 'Full Day';
        END IF;

        v_guide_cost := v_guide_rate * v_guide_days;
    ELSE
        v_guide_id   := NULL;
        v_guide_name := 'No Guide';
        v_guide_type := 'None';
        v_guide_days := 0;
        v_guide_cost := 0;
    END IF;

    -- 5. Total Cost & Payment Status
    v_total_cost := v_hotel_cost + v_trans_cost + v_guide_cost;

    IF v_pay_opt = 1 THEN
        v_pay_method  := 'Card';
        v_pay_status  := 'Paid';
        v_book_status := 'Confirmed';
    ELSIF v_pay_opt = 2 THEN
        v_pay_method  := 'Cash';
        v_pay_status  := 'Paid';
        v_book_status := 'Confirmed';
    ELSIF v_pay_opt = 3 THEN
        v_pay_method  := 'Bank';
        v_pay_status  := 'Paid';
        v_book_status := 'Confirmed';
    ELSE
        v_pay_method  := 'Unpaid';
        v_pay_status  := 'Pending';
        v_book_status := 'Pending';
    END IF;

    -- 6. Save Records
    v_cust_id := seq_customer.NEXTVAL;
    v_book_id := seq_booking.NEXTVAL;
    v_pay_id  := seq_payment.NEXTVAL;

    INSERT INTO customer (customer_id, full_name, phone, email)
    VALUES (v_cust_id, TRIM('&v_name'), TRIM('&v_phone'), TRIM('&v_email'));

    INSERT INTO booking (
        booking_id, customer_id, city_id, hotel_id,
        rooms, nights, persons, hotel_cost,
        transport_id, transport_cost,
        guide_id, guide_type, guide_days, guide_cost,
        total_cost, booking_status
    ) VALUES (
        v_book_id, v_cust_id, v_city_id, v_hotel_id,
        v_rooms, v_nights, v_persons, v_hotel_cost,
        v_trans_id, v_trans_cost,
        v_guide_id, v_guide_type, v_guide_days, v_guide_cost,
        v_total_cost, v_book_status
    );

    -- 7. Save Selected Attractions
    LOOP
        v_token := TRIM(REGEXP_SUBSTR(v_places_str, '[^,]+', 1, v_idx));
        EXIT WHEN v_token IS NULL OR v_token = '0';

        BEGIN
            v_place_num := TO_NUMBER(v_token);
            SELECT attraction_id, attraction_name
            INTO   v_attr_id, v_attr_name
            FROM   attraction
            WHERE  city_id = v_city_id AND place_no = v_place_num;

            INSERT INTO booking_attraction (booking_id, attraction_id)
            VALUES (v_book_id, v_attr_id);

            IF v_places_list IS NULL THEN
                v_places_list := v_attr_name;
            ELSE
                v_places_list := v_places_list || ', ' || v_attr_name;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND OR DUP_VAL_ON_INDEX OR VALUE_ERROR THEN
                NULL;
        END;

        EXIT WHEN v_place_mode = 1;
        v_idx := v_idx + 1;
    END LOOP;

    INSERT INTO payment (payment_id, booking_id, pay_method, pay_status, amount)
    VALUES (v_pay_id, v_book_id, v_pay_method, v_pay_status, v_total_cost);

    COMMIT;

    -- 8. Print Clean Receipt
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('             BOOKING RECEIPT SUMMARY              ');
    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('Booking ID      : ' || v_book_id);
    DBMS_OUTPUT.PUT_LINE('Customer        : ' || TRIM('&v_name') || ' (' || TRIM('&v_phone') || ')');
    DBMS_OUTPUT.PUT_LINE('Email           : ' || TRIM('&v_email'));
    DBMS_OUTPUT.PUT_LINE('City            : ' || v_city_name);
    DBMS_OUTPUT.PUT_LINE('Places Selected : ' || NVL(v_places_list, 'None'));
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Hotel           : ' || v_hotel_name);
    DBMS_OUTPUT.PUT_LINE('Meals Included  : Breakfast(' || v_bf || ') | Lunch(' || v_ln || ') | Dinner(' || v_dn || ')');
    DBMS_OUTPUT.PUT_LINE('Stay Details    : ' || v_rooms || ' Room(s), ' || v_nights || ' Night(s), ' || v_persons || ' Person(s)');
    DBMS_OUTPUT.PUT_LINE('Hotel Cost      : Rs. ' || v_hotel_cost);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    IF v_trans_id > 1 THEN
        DBMS_OUTPUT.PUT_LINE('Transport       : ' || v_trans_name);
        DBMS_OUTPUT.PUT_LINE('Daily Package   : Car(' || v_car_rent || ') + Driver(' || v_driver_fee || ') + Tax(' || v_service_tax || ') = Rs. ' || v_daily_total || '/day');
        DBMS_OUTPUT.PUT_LINE('Transport Cost  : Rs. ' || v_trans_cost || ' (' || v_nights || ' Days) *Petrol/Fuel by Customer*');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Transport       : Public Transport (Self) -> Rs. 0');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Tour Guide      : ' || v_guide_name || ' (' || v_guide_type || ', ' || v_guide_days || ' Days) -> Rs. ' || v_guide_cost);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('TOTAL COST      : Rs. ' || v_total_cost);
    DBMS_OUTPUT.PUT_LINE('Payment Method  : ' || v_pay_method || ' (' || v_pay_status || ')');
    DBMS_OUTPUT.PUT_LINE('Booking Status  : ' || v_book_status);
    DBMS_OUTPUT.PUT_LINE('==================================================');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Galat City ID, Hotel No, Vehicle ID ya Guide No enter hua hai. Dobara try karein.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/

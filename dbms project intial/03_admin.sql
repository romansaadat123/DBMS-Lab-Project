SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
SET VERIFY OFF
SET LINESIZE 200
SET PAGESIZE 50

UNDEFINE v_action v_target_id

-- ============================================================
-- 1. ALL BOOKINGS TABLE DISPLAY
-- ============================================================
PROMPT ============================================================
PROMPT                 ADMIN PANEL - ALL BOOKINGS
PROMPT ============================================================
SELECT booking_id     AS "ID",
       customer       AS "Customer",
       city           AS "City",
       hotel          AS "Hotel",
       transport      AS "Transport",
       total_cost     AS "Total (Rs)",
       pay_method     AS "Method",
       pay_status     AS "Pay Status",
       booking_status AS "Trip Status"
FROM v_booking_summary
ORDER BY booking_id DESC;

-- ============================================================
-- 2. ADMIN MENU
-- ============================================================
PROMPT
PROMPT Admin Actions:
PROMPT 1 = View Revenue Summary Only
PROMPT 2 = Cancel a Booking
PROMPT 3 = Confirm a Pending Booking
PROMPT 0 = Exit
ACCEPT v_action    CHAR PROMPT 'Enter Action (1, 2, 3 or 0): '
ACCEPT v_target_id CHAR PROMPT 'Enter Booking ID (Enter 0 if Action is 1 or 0): '

DECLARE
    v_action      NUMBER := TO_NUMBER(NVL(TRIM('&v_action'), '0'));
    v_target_id   NUMBER := TO_NUMBER(NVL(TRIM('&v_target_id'), '0'));
    v_curr_status VARCHAR2(15);
    v_pay_status  VARCHAR2(15);

    v_total_trips NUMBER;
    v_confirmed   NUMBER;
    v_pending     NUMBER;
    v_cancelled   NUMBER;
    v_revenue     NUMBER;
BEGIN
    IF v_action = 2 THEN
        SELECT booking_status INTO v_curr_status
        FROM booking WHERE booking_id = v_target_id;

        IF v_curr_status = 'Cancelled' THEN
            DBMS_OUTPUT.PUT_LINE('Booking ID ' || v_target_id || ' pehle se hi Cancelled hai.');
        ELSE
            UPDATE booking SET booking_status = 'Cancelled' WHERE booking_id = v_target_id;

            SELECT pay_status INTO v_pay_status FROM payment WHERE booking_id = v_target_id;
            IF v_pay_status = 'Paid' THEN
                UPDATE payment SET pay_status = 'Refunded' WHERE booking_id = v_target_id;
            ELSE
                UPDATE payment SET pay_status = 'Cancelled' WHERE booking_id = v_target_id;
            END IF;

            COMMIT;
            DBMS_OUTPUT.PUT_LINE('SUCCESS: Booking ID ' || v_target_id || ' cancel kar di gayi hai.');
        END IF;

    ELSIF v_action = 3 THEN
        SELECT booking_status INTO v_curr_status
        FROM booking WHERE booking_id = v_target_id;

        IF v_curr_status = 'Pending' THEN
            UPDATE booking SET booking_status = 'Confirmed' WHERE booking_id = v_target_id;
            UPDATE payment SET pay_status = 'Paid', pay_method = 'Cash' WHERE booking_id = v_target_id;
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('SUCCESS: Booking ID ' || v_target_id || ' ab Confirmed aur Paid ho chuki hai.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('NOTE: Booking ID ' || v_target_id || ' ka status "' || v_curr_status || '" hai, sirf Pending booking confirm ho sakti hai.');
        END IF;
    END IF;

    IF v_action IN (1, 2, 3) THEN
        SELECT COUNT(*),
               NVL(SUM(CASE WHEN booking_status = 'Confirmed' THEN 1 ELSE 0 END), 0),
               NVL(SUM(CASE WHEN booking_status = 'Pending'   THEN 1 ELSE 0 END), 0),
               NVL(SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END), 0),
               NVL(SUM(CASE WHEN booking_status = 'Confirmed' THEN total_cost ELSE 0 END), 0)
        INTO   v_total_trips, v_confirmed, v_pending, v_cancelled, v_revenue
        FROM   booking;

        DBMS_OUTPUT.PUT_LINE('=============================================');
        DBMS_OUTPUT.PUT_LINE('            ADMIN SUMMARY REPORT             ');
        DBMS_OUTPUT.PUT_LINE('=============================================');
        DBMS_OUTPUT.PUT_LINE('Total Bookings     : ' || v_total_trips);
        DBMS_OUTPUT.PUT_LINE('Confirmed Bookings : ' || v_confirmed);
        DBMS_OUTPUT.PUT_LINE('Pending Bookings   : ' || v_pending);
        DBMS_OUTPUT.PUT_LINE('Cancelled Bookings : ' || v_cancelled);
        DBMS_OUTPUT.PUT_LINE('Confirmed Revenue  : Rs. ' || v_revenue);
        DBMS_OUTPUT.PUT_LINE('=============================================');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Admin Panel se exit ho gaye.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Booking ID ' || v_target_id || ' database mein maujood nahi hai.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/

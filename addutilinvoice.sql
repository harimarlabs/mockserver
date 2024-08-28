-- PROCEDURE: public.addutilinvoice(character varying, integer, date, character varying, integer, date, integer, integer, integer, integer, integer, integer, boolean, integer, date, character varying, boolean, integer)

-- DROP PROCEDURE IF EXISTS public.addutilinvoice(character varying, integer, date, character varying, integer, date, integer, integer, integer, integer, integer, integer, boolean, integer, date, character varying, boolean, integer);

CREATE OR REPLACE PROCEDURE public.addutilinvoice(
	accountid character varying,
	billedamtcents integer,
	billeddate date,
	billedpdfs3loc character varying,
	billedpersonid integer,
	duedate date,
	billedpdfsizekb integer,
	paymentinvoiceid integer,
	arrearamtcents integer,
	penaltyamtcents integer,
	taxamtcents integer,
	chargesamtcents integer,
	finalbillflag boolean,
	minamtcents integer,
	raisedts date,
	billedpdfsrc character varying,
	statementbilling boolean,
	amtpaidcents integer)
LANGUAGE 'plpgsql'
AS $BODY$
        DECLARE
            utilinvoiceid integer := 0;
            pi_label varchar;
            paidamt integer := 0;
            misc_invoice_type varchar;
            auto_pay_eligible_date date := CURRENT_DATE;
            days_before_auto_pay_occurs integer;
            payment_status_ref_type_id integer;
            billed_amt_sum integer := 0;
            amt_owed integer := 0;
        BEGIN
            IF statementbilling THEN
                pi_label := CONCAT('Account #', accountid::text, '; Bill Date ', billeddate::text, '; Statement Billing');
            ELSE
                pi_label := CONCAT('Account #', accountid::text, '; Bill Date ', billeddate::text);
            END IF;

            -- Set amount already paid on bill if billed amount is negative
        --     IF billedamtcents <= 0 THEN
        --         paidamt := billedamtcents;
        --     END IF;
            
            -- Calculated sum of billed amount and arrears, do not allow negative invoice amount on FD
            IF (billedamtcents + arrearamtcents) <= 0 THEN
                billed_amt_sum := 0;
                paidamt := ABS(arrearamtcents);
                amt_owed := billedamtcents;
            ELSIF (billedamtcents + arrearamtcents) > 0 AND arrearamtcents < 0 THEN
                billed_amt_sum := billedamtcents + arrearamtcents;
                amt_owed := billed_amt_sum;
            ELSE
                billed_amt_sum := billedamtcents;
                amt_owed := billed_amt_sum;
            END IF;

            -- Set payment status id if invoice is paid
            IF billed_amt_sum = 0 THEN
                payment_status_ref_type_id := 51;
            ELSE
                payment_status_ref_type_id :=
                CASE
                    WHEN duedate >= CURRENT_DATE THEN 50
                    ELSE 55
                END;
            END IF;
            
            -- Check invoice type and set due date
            SELECT "MiscInvoiceType" FROM "UB"."Invoices"
            INTO misc_invoice_type
            WHERE "InvoiceNumber" = paymentinvoiceid::varchar;

            -- Get autopay settings
            SELECT (val ->> 'num_days_before')::integer
            INTO days_before_auto_pay_occurs
            FROM city.sys_properties sp
            WHERE sp.key = 'city_autopay_settings';

            -- Set auto pay eligible date for balance adjustments or to due date set in settings
            auto_pay_eligible_date := CASE
                WHEN misc_invoice_type = 'BalanceAdjustment' THEN NULL
                ELSE duedate - days_before_auto_pay_occurs * INTERVAL '1 day'
            END;

            INSERT INTO city.payments_invoice(
                created_ts,
                status_ts,
                due_dt,
                billed_dt,
                mod_ts,
                payment_submitted_ts,
                person_id,
                amt_arrears_cents,
                amt_billed_cents,
                amt_min_owed_cents,
                amt_owed_cents,
                amt_paid_cents,
                amt_payment_processing_cents,
                amt_penalty_cents,
                autopaid_fl,
                autopay_eligible_dt,
                autopay_eligible_fl,
                autopay_notification_fl,
                created_person_id,
                invoice_ref_type_id,
                invoice_number,
                label,
                plugin_invoice_id,
                plugin_ref_type_id,
                status_ref_type_id,
                pdf_location,
                reissue_id
            )
            VALUES (
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP,
                duedate,
                billeddate,
                null,
                null,
                billedpersonid,
                arrearamtcents,
                billed_amt_sum,
                amt_owed,
                amt_owed,
                paidamt + amtpaidcents,
                0,
                penaltyamtcents,
                false,
                auto_pay_eligible_date,
                true,
                false,
                101,
                90,
                paymentinvoiceid::varchar,
                pi_label,
                paymentinvoiceid,
                14,
                payment_status_ref_type_id,
                '',
                null
            )
            RETURNING id INTO paymentinvoiceid;

            INSERT INTO city.util_invoice(
                created_ts,
                due_dt,
                raised_ts,
                created_person_id,
                account_id,
                arrears_amt_cents,
                billed_amt_cents,
                billed_dt,
                billed_person_id,
                billed_pdf_s3_location,
                billed_pdf_src,
                billed_pdf_size_kb,
                charges_amt_cents,
                final_fl,
                min_amt_cents,
                payments_invoice_id,
                penalty_amt_cents,
                tax_amt_cents
            )
            VALUES (
                CURRENT_TIMESTAMP,
                duedate,
                raisedts,
                101,
                accountid,
                arrearamtcents,
                billed_amt_sum,
                billeddate,
                billedpersonid,
                billedpdfs3loc,
                billedpdfsrc,
                billedpdfsizekb,
                chargesamtcents,
                finalbillflag,
                amt_owed,
                paymentinvoiceid,
                penaltyamtcents,
                taxamtcents
            )
            RETURNING id INTO utilinvoiceid;

            UPDATE city.payments_invoice
            SET plugin_invoice_id = utilinvoiceid
            WHERE id = paymentinvoiceid;
        END;
        
$BODY$;

ALTER PROCEDURE public.addutilinvoice(character varying, integer, date, character varying, integer, date, integer, integer, integer, integer, integer, integer, boolean, integer, date, character varying, boolean, integer)
    OWNER TO db_client_ops;

GRANT EXECUTE ON PROCEDURE public.addutilinvoice(character varying, integer, date, character varying, integer, date, integer, integer, integer, integer, integer, integer, boolean, integer, date, character varying, boolean, integer) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE public.addutilinvoice(character varying, integer, date, character varying, integer, date, integer, integer, integer, integer, integer, integer, boolean, integer, date, character varying, boolean, integer) TO db_city_rw_2642;

GRANT EXECUTE ON PROCEDURE public.addutilinvoice(character varying, integer, date, character varying, integer, date, integer, integer, integer, integer, integer, integer, boolean, integer, date, character varying, boolean, integer) TO db_client_ops;


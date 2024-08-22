# CMS-deployment
Configurations, Scripts etc for deployment

  DECLARE
  BEGIN
    CREATE temp TABLE
    IF NOT EXISTS "UB"."AccountBalanceHistoryTemp" ( "AccountKey" uuid, "Balance" NUMERIC, "Date" DATE ) ON COMMIT DROP;
      INSERT INTO "UB"."AccountBalanceHistoryTemp"
                  (
                              "AccountKey",
                              "Balance",
                              "Date"
                  )
      SELECT "AccountKey",
             "Balance",
             current_date-1 AS "Date"
      FROM   "UB"."Accounts";
      
      -- Update history based on existing balance
      UPDATE "UB"."AccountBalanceHistories"
      SET        "Balance" = d."Balance"
      FROM       "UB"."AccountBalanceHistories" h
      inner join "UB"."AccountBalanceHistoryTemp" d
      ON         h."AccountKey" = d."AccountKey"
      AND        h."BalanceDate" = d."Date";
      
      -- If no record exists, insert a new record
      INSERT INTO "UB"."AccountBalanceHistories"
                  (
                              "Key",
                              "AccountKey",
                              "BalanceDate",
                              "Balance",
                              "IsInActive"
                  )
      SELECT uuid_generate_v4(),
             d."AccountKey",
             d."Date",
             d."Balance",
             FALSE
      FROM   "UB"."AccountBalanceHistoryTemp" d
      WHERE  NOT EXISTS
             (
                    SELECT *
                    FROM   "UB"."AccountBalanceHistories" h
                    WHERE  h."AccountKey" = d."AccountKey"
                    AND    h."BalanceDate" = d."Date" );
    
    END;

    
    #variable_conflict use_column  -- !!
    BEGIN
    BEGIN
    DECLARE
	    
	    glPaymentEventType INTEGER := 2; -- Event Type = 2 = Payments
	    glDepositEventType INTEGER := 6; -- Event Type = 6 = Deposits
	
	    paymentEventType INTEGER := 1; -- Payment recorded
	    voidPaymentEventType INTEGER := 2; -- 	Payment voided
	    badDebtPaymentEventType INTEGER := 3; -- 	Bad Debt Payment recorded
	    depositReceivedEventType INTEGER := 4; -- 	Meter Deposit received
	    appliedToBalanceEventType INTEGER := 6; -- Applied to Balance
	
	    depositTransactionType INTEGER := 0;
	    serviceChargeTransactionType INTEGER := 3;
		transferTransactionType INTEGER := 4;
    BEGIN
		CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    /*
	    Payment recorded, voided, and bad debt
    */
	--DROP TABLE "UBBKRecordsTemp";
	    INSERT INTO "UB"."UBBKEntryDatas" ("UBBKEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "PaymentMode", "TransactionType", "BankTo", "BankFrom", "Amount", "IsProcessed", "ReferenceKey", "IsInActive", "Created", "LastModified", "PaymentKey")
	    SELECT uuid_generate_v4() AS "UBBKEntryDataKey", 
		       Now() AS "CreatedDateForGL", 
		       subquery.paymentDate AS "EventDate",
		       CASE 
		   		    WHEN subquery.isVoid = true THEN voidPaymentEventType
				    WHEN subquery.isBadDebt = true THEN badDebtPaymentEventType
				    ELSE paymentEventType
		       END AS "EventType",
		       subquery.paymentMode AS "PaymentMode",
		       CASE 
		   		    WHEN subquery.isVoid = true THEN serviceChargeTransactionType
				    ELSE depositTransactionType
		       END AS "TransactionType",
		       CASE 
		   		    WHEN subquery.isVoid = true THEN NULL
					WHEN subquery.isbadDebt = true THEN "UB".GetBankByDistributionSetting(badDebtPaymentEventType, subquery.serviceTypeCode, subquery.accountTypeCode)
				    ELSE "UB".GetBankByDistributionSetting(glPaymentEventType, subquery.serviceTypeCode, subquery.accountTypeCode)
		       END AS "BankTo",
		       CASE 
		   		    WHEN subquery.isVoid = true THEN "UB".GetBankByDistributionSetting(glPaymentEventType, subquery.serviceTypeCode, subquery.accountTypeCode)
				    ELSE NULL
		       END AS "BankFrom",
		       subquery.amount AS "Amount",
		       false AS "IsProcessed",
		       subquery.paymentHistoryKey AS "ReferenceKey",
		       false AS "IsInActive",
		       subquery.created AS "Created",
		       subquery.lastmodified AS "LastModified",
			   subquery.PaymentKey AS "PaymentKey"
	    FROM
	    (
		    SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
		    acc."AccountTypeCode" AS accountTypeCode,
		    invDetail."ServiceTypeCode" AS serviceTypeCode,
		    pay."PaymentKey" AS paymentKey,
		    pay."PaymentDate" AS paymentDate,
		    pay."PaymentTypeKey" AS paymentMode,
		    ph."AmountPaid" AS amount,
		    pay."IsVoid" AS isVoid,
		    acc."IsBadDebt" AS isBadDebt,
			pay."RecordType" AS recordType,
			pay."Created" AS Created,
			pay."LastModified" AS LastModified
		    FROM "UB"."PaymentHistories" as ph
		    INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
		    INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
		    INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
		    INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
		    WHERE (payment_key IS NULL OR pay."PaymentKey" = payment_key) AND
			(ph."AmountPaid" > 0 OR  ph."AmountPaid" < 0) AND (ph."Deposit" IS NULL OR ph."Deposit" = 0) AND pay."RecordType" IS NULL
			AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
		    )
	    AS subquery
	
	    WHERE NOT EXISTS 
	    (
		    SELECT 1 
		    FROM "UB"."UBBKEntryDatas" 
		    WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
		    "Amount" = subquery.amount AND
		    CASE 
		   		    WHEN subquery.isVoid = true THEN "EventType" = voidPaymentEventType
				    WHEN subquery.isBadDebt = true THEN "EventType" = badDebtPaymentEventType
				    ELSE "EventType" = paymentEventType
		    END
	    );
		
		
		   /*
	    Payment refund deposit
    	*/
	    INSERT INTO "UB"."UBBKEntryDatas" ("UBBKEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "PaymentMode", "TransactionType", "BankTo", "BankFrom", "Amount", "IsProcessed", "ReferenceKey", "IsInActive", "Created", "LastModified", "PaymentKey")
	    SELECT uuid_generate_v4() AS "UBBKEntryDataKey", 
		       Now() AS "CreatedDateForGL", 
		       subquery.paymentDate AS "EventDate",
		       appliedToBalanceEventType AS "EventType",
		       subquery.paymentMode AS "PaymentMode",
			   transferTransactionType AS "TransactionType",
			   "UB".GetBankByDistributionSetting(glPaymentEventType, subquery.serviceTypeCode, subquery.accountTypeCode) AS "BankTo",
			   "UB".GetBankByDistributionSetting(glDepositEventType, subquery.depositServiceTypeCode) AS "BankFrom",
		       subquery.amount AS "Amount",
		       false AS "IsProcessed",
		       subquery.paymentHistoryKey AS "ReferenceKey",
		       false AS "IsInActive",
			   subquery.created AS "Created",
		       subquery.lastmodified AS "LastModified",
			   subquery.PaymentKey AS "PaymentKey"
	    FROM
	    (
		    SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
		    acc."AccountTypeCode" AS accountTypeCode,
		    invDetail."ServiceTypeCode" AS serviceTypeCode,
		    pay."PaymentKey" AS paymentKey,
		    pay."PaymentDate" AS paymentDate,
		    pay."PaymentTypeKey" AS paymentMode,
		    ph."AmountPaid" AS amount,
			ser."ServiceTypeCode" AS depositServiceTypeCode,
			pay."Created" AS Created,
			pay."LastModified" AS LastModified
		    FROM "UB"."PaymentHistories" as ph
		    INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
		    INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
		    INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
		    INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
			INNER JOIN "UB"."DepositTransactionHistories" dth ON acc."AccountKey" = dth."AccountKey"
			INNER JOIN "UB"."Services" ser ON dth."ServiceKey" = ser."ServiceKey"
		    WHERE (payment_key IS NULL OR pay."PaymentKey" = payment_key) AND
			pay."AmountPaid" = dth."AmountRefunded" AND pay."RecordType" = 'DepositRefund'
			AND "UB".GetBankByDistributionSetting(glPaymentEventType, invDetail."ServiceTypeCode", acc."AccountTypeCode") != 
			"UB".GetBankByDistributionSetting(glDepositEventType, ser."ServiceTypeCode")
		    )
	    AS subquery
	
	    WHERE NOT EXISTS 
	    (
		    SELECT 1 
		    FROM "UB"."UBBKEntryDatas" 
		    WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
		    "Amount" = subquery.amount AND
			"EventType" = appliedToBalanceEventType
	    );
	
	
	    UPDATE "UB"."UBBKEntryDatas"
	    SET "EventId" = subqueryDate."EventId"
	    FROM ( 
	      SELECT pay."PaymentKey" as "PaymentKey", uuid_generate_v4() AS "EventId"
	      FROM "UB"."UBBKEntryDatas" as bke
	      INNER JOIN "UB"."PaymentHistories" as ph ON bke."ReferenceKey" = ph."PaymentHistoryKey"
	      INNER JOIN "UB"."Payments" as pay ON ph."PaymentKey" = pay."PaymentKey"
	      WHERE "EventId" IS NULL
	      GROUP BY pay."PaymentKey"
	    ) AS subqueryDate
	    INNER JOIN "UB"."Payments" as pay ON subqueryDate."PaymentKey" = pay."PaymentKey"
	    INNER JOIN "UB"."PaymentHistories" as ph ON pay."PaymentKey" = ph."PaymentKey"
	    WHERE (payment_key IS NULL OR pay."PaymentKey" = payment_key) AND "UB"."UBBKEntryDatas"."ReferenceKey" = ph."PaymentHistoryKey";
	
	
	/*
	    Overpayment payment recorded
    */
	
	    INSERT INTO "UB"."UBBKEntryDatas" ("UBBKEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "PaymentMode", "TransactionType", "BankTo", "BankFrom", "Amount", "IsProcessed", "ReferenceKey", "IsInActive", "Created", "LastModified", "PaymentKey")
	    SELECT uuid_generate_v4() AS "UBBKEntryDataKey", 
		       Now() AS "CreatedDateForGL", 
		       subquery.paymentDate AS "EventDate",
		       CASE 
		   		    WHEN subquery.isVoid = true THEN voidPaymentEventType
				    WHEN subquery.isBadDebt = true THEN badDebtPaymentEventType
				    ELSE paymentEventType
		       END AS "EventType",
		       subquery.paymentMode AS "PaymentMode",
		       CASE 
		   		    WHEN subquery.isVoid = true THEN serviceChargeTransactionType
				    ELSE depositTransactionType
		       END AS "TransactionType",
			   CASE 
		   		    WHEN subquery.isVoid = true THEN NULL
					WHEN subquery.isbadDebt = true THEN "UB".GetBankByDistributionSetting(badDebtPaymentEventType, subquery.serviceTypeCode, subquery.accountTypeCode)
				    ELSE "UB".GetBankByDistributionSetting(glPaymentEventType, subquery.serviceTypeCode, subquery.accountTypeCode)
		       END AS "BankTo",
		       CASE 
		   		    WHEN subquery.isVoid = true THEN "UB".GetBankByDistributionSetting(glPaymentEventType, subquery.serviceTypeCode, subquery.accountTypeCode)
				    ELSE NULL
		       END AS "BankFrom",
		       subquery.amount AS "Amount",
		       false AS "IsProcessed",
		       subquery.overPaymentLogKey AS "ReferenceKey",
		       false AS "IsInActive",
			   subquery.created AS "Created",
		       subquery.lastmodified AS "LastModified",
			   subquery.PaymentKey AS "PaymentKey"
	    FROM
	    (
		    SELECT opl."OverPaymentLogKey" AS overPaymentLogKey, 
		    acc."AccountTypeCode" AS accountTypeCode,
		    "UB".GetFirstServiceTypeCode(acc."AccountKey") AS serviceTypeCode,
		    pay."PaymentKey" AS paymentKey,
		    pay."PaymentDate" AS paymentDate,
		    pay."PaymentTypeKey" AS paymentMode,
		    opl."AmountPaid" AS amount,
		    pay."IsVoid" AS isVoid,
		    acc."IsBadDebt" AS isBadDebt,
			pay."RecordType" AS recordType,
			pay."Created" AS Created,
			pay."LastModified" AS LastModified
		    FROM "UB"."OverPaymentLogs" as opl
			INNER JOIN "UB"."Payments" pay ON opl."PaymentKey" = pay."PaymentKey"
		    INNER JOIN "UB"."Accounts" acc ON pay."AccountKey" = acc."AccountKey"
		    WHERE (payment_key IS NULL OR pay."PaymentKey" = payment_key) AND opl."AmountPaid" > 0 AND opl."Type" = 'AccountBalance' AND "pay"."RecordType" IS NULL
			AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
		    )
	    AS subquery
	
	    WHERE NOT EXISTS 
	    (
		    SELECT 1 
		    FROM "UB"."UBBKEntryDatas" 
		    WHERE "ReferenceKey" = subquery.overPaymentLogKey AND "Amount" = subquery.amount
	    );
	
	/*
	    Overpayment refund deposit
    */
	    INSERT INTO "UB"."UBBKEntryDatas" ("UBBKEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "PaymentMode", "TransactionType", "BankTo", "BankFrom", "Amount", "IsProcessed", "ReferenceKey", "IsInActive", "Created", "LastModified", "PaymentKey")
	    SELECT uuid_generate_v4() AS "UBBKEntryDataKey", 
		       Now() AS "CreatedDateForGL", 
		       subquery.paymentDate AS "EventDate",
		       appliedToBalanceEventType AS "EventType",
		       subquery.paymentMode AS "PaymentMode",
		       transferTransactionType AS "TransactionType",
			   "UB".GetBankByDistributionSetting(glPaymentEventType, subquery.firstServiceTypeCode, subquery.accountTypeCode) AS "BankTo",
			   "UB".GetBankByDistributionSetting(glDepositEventType, subquery.serviceTypeCode) AS "BankFrom",
		       subquery.amount AS "Amount",
		       false AS "IsProcessed",
		       subquery.overPaymentLogKey AS "ReferenceKey",
		       false AS "IsInActive",
		       subquery.created AS "Created",
		       subquery.lastmodified AS "LastModified",
			   subquery.PaymentKey AS "PaymentKey"	    
			FROM
	    (
		    SELECT opl."OverPaymentLogKey" AS overPaymentLogKey, 
		    acc."AccountTypeCode" AS accountTypeCode,
		    ser."ServiceTypeCode" AS serviceTypeCode,
		    pay."PaymentKey" AS paymentKey,
		    pay."PaymentDate" AS paymentDate,
		    pay."PaymentTypeKey" AS paymentMode,
		    opl."AmountPaid" AS amount,
		    pay."IsVoid" AS isVoid,
		    acc."IsBadDebt" AS isBadDebt,
			pay."RecordType" AS recordType,
			"UB".GetFirstServiceTypeCode(acc."AccountKey") AS firstServiceTypeCode,
			pay."Created" AS Created,
			pay."LastModified" AS LastModified
		    FROM "UB"."OverPaymentLogs" as opl
			INNER JOIN "UB"."Payments" pay ON opl."PaymentKey" = pay."PaymentKey"
		    INNER JOIN "UB"."Accounts" acc ON pay."AccountKey" = acc."AccountKey"
			INNER JOIN "UB"."DepositTransactionHistories" dth ON acc."AccountKey" = dth."AccountKey"
			INNER JOIN "UB"."Services" ser ON dth."ServiceKey" = ser."ServiceKey"
		    WHERE (payment_key IS NULL OR pay."PaymentKey" = payment_key) AND opl."AmountPaid" > 0 AND opl."Type" = 'AccountBalance' AND pay."RecordType" = 'DepositRefund' AND
			"UB".GetBankByDistributionSetting(glPaymentEventType, "UB".GetFirstServiceTypeCode(acc."AccountKey"), acc."AccountTypeCode") != 
			"UB".GetBankByDistributionSetting(glDepositEventType, ser."ServiceTypeCode")
		    )
	    AS subquery
	
	    WHERE NOT EXISTS 
	    (
		    SELECT 1 
		    FROM "UB"."UBBKEntryDatas" 
		    WHERE "ReferenceKey" = subquery.overPaymentLogKey AND "Amount" = subquery.amount AND subquery.recordType = 'DepositRefund'
	    );
	
	    UPDATE "UB"."UBBKEntryDatas"
	    SET "EventId" = subqueryDate."EventId"
	    FROM ( 
	      SELECT pay."PaymentKey" as "PaymentKey", uuid_generate_v4() AS "EventId"
	      FROM "UB"."UBBKEntryDatas" as bke
	      INNER JOIN "UB"."OverPaymentLogs" as opl ON bke."ReferenceKey" = opl."OverPaymentLogKey"
	      INNER JOIN "UB"."Payments" as pay ON opl."PaymentKey" = pay."PaymentKey"
	      WHERE "EventId" IS NULL
	      GROUP BY pay."PaymentKey"
	    ) AS subqueryDate
	    INNER JOIN "UB"."Payments" as pay ON subqueryDate."PaymentKey" = pay."PaymentKey"
	    INNER JOIN "UB"."OverPaymentLogs" as opl ON pay."PaymentKey" = opl."PaymentKey"
	    WHERE (payment_key IS NULL OR pay."PaymentKey" = payment_key) AND "UB"."UBBKEntryDatas"."ReferenceKey" = opl."OverPaymentLogKey";
	
	
    /*
	    Deposits
    */

	    INSERT INTO "UB"."UBBKEntryDatas" ("UBBKEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "PaymentMode", "TransactionType", "BankTo", "BankFrom", "Amount", "IsProcessed", "ReferenceKey", "IsInActive", "Created", "LastModified", "PaymentKey")
	    SELECT uuid_generate_v4() AS "UBBKEntryDataKey", 
		       Now() AS "CreatedDateForGL", 
		       subquery.paymentDate AS "EventDate",
		       depositReceivedEventType AS "EventType",
		       subquery.paymentMode AS "PaymentMode",
		       depositTransactionType AS "TransactionType",
		       "UB".GetBankByDistributionSetting(glDepositEventType, subquery.serviceTypeCode) AS "BankTo",
		       NULL AS "BankFrom",
		       subquery.amount AS "Amount",
		       false AS "IsProcessed",
		       subquery.paymentHistoryKey AS "ReferenceKey",
		       false AS "IsInActive",
			   subquery.created AS "Created",
		       subquery.lastmodified AS "LastModified",
			   subquery.PaymentKey AS "PaymentKey"
	    FROM
	    (
		    SELECT phfd."PaymentHistoryForDepositKey" AS paymentHistoryKey, 
		    acc."AccountTypeCode" AS accountTypeCode,
		    ser."ServiceTypeCode" AS serviceTypeCode,

		    pay."PaymentDate" AS paymentDate,
		    pay."PaymentTypeKey" AS paymentMode,
		    phfd."Amount" AS amount,
			pay."Created" AS Created,
			pay."LastModified" AS LastModified,
			pay."PaymentKey" AS PaymentKey
		    FROM "UB"."PaymentHistoryForDeposits" as phfd
		    INNER JOIN "UB"."Payments" pay ON phfd."PaymentsKey" = pay."PaymentKey"
		    INNER JOIN "UB"."ServiceDeposits" sd ON phfd."ServiceDepositKey" = sd."ServiceDepositKey"
		    INNER JOIN "UB"."Services" as ser ON sd."ServiceKey" = ser."ServiceKey"
		    INNER JOIN "UB"."Accounts" acc ON pay."AccountKey" = acc."AccountKey"
		    WHERE (payment_key IS NULL OR pay."PaymentKey" = payment_key) AND (phfd."Amount" > 0 OR  phfd."Amount" < 0) AND (sd."RefundType" != 'Refund')
		    )
	    AS subquery
	
	    WHERE NOT EXISTS 
	    (
		    SELECT 1 
		    FROM "UB"."UBBKEntryDatas" 
		    WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
		    "Amount" = subquery.amount AND
		    "EventType" = depositReceivedEventType
	    );
	
	    UPDATE "UB"."UBBKEntryDatas"
	    SET "EventId" = subqueryDate."EventId"
	    FROM ( 
	      SELECT pay."PaymentKey" as "PaymentKey", uuid_generate_v4() AS "EventId"
	      FROM "UB"."UBBKEntryDatas" as bke
	      INNER JOIN "UB"."PaymentHistoryForDeposits" as ph ON bke."ReferenceKey" = ph."PaymentHistoryForDepositKey"
	      INNER JOIN "UB"."Payments" as pay ON ph."PaymentsKey" = pay."PaymentKey"
	      WHERE "EventId" IS NULL
	      GROUP BY pay."PaymentKey"
	    ) AS subqueryDate
	    INNER JOIN "UB"."Payments" as pay ON subqueryDate."PaymentKey" = pay."PaymentKey"
	    INNER JOIN "UB"."PaymentHistoryForDeposits" as ph ON pay."PaymentKey" = ph."PaymentsKey"
	    WHERE (payment_key IS NULL OR pay."PaymentKey" = payment_key) AND "UB"."UBBKEntryDatas"."ReferenceKey" = ph."PaymentHistoryForDepositKey";
		
		DELETE FROM "UB"."UBBKEntryDatas"
		WHERE "BankFrom" IS NULL AND "BankTo" IS NULL;
	
	       -- exception handler
        EXCEPTION
            WHEN others THEN
                -- if there is a exception, roll back the transaction
                ROLLBACK;
                -- Raise a notice with the error message
                RAISE NOTICE 'An error occurred: %', SQLERRM;
				INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
                        VALUES (public.uuid_generate_v4(), null, 4, 3, SQLERRM, 2, current_timestamp, current_user, current_timestamp, current_user, false);
        END;
    END;
    END;

    
#variable_conflict use_column
BEGIN
/*
	Query to generate GL Records for Billing Event Type
*/
	BEGIN
        DECLARE
            eventType INTEGER := 1; -- Event Type = 1 = Billing
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_Billing';
            miscChargeCreditReference TEXT := 'UB_MiscCharge_Credit';
            miscChargesBucketType INTEGER := 20;
            bucketTypeCode INTEGER := 1; -- Service Charges
        BEGIN
            IF EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
            THEN
            
                RAISE NOTICE 'Inserting Billing Event Type records in "UBGLEntryDatas" table.';
                INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
                VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Billing Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            /*
                Service Charges
            */
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    CASE WHEN "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL 
                        THEN subquery.servicecharges * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100
                        ELSE subquery.servicecharges 
                    END AS "Amount", 
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );

            /*
                Service Taxes
            */
                bucketTypeCode := 2; -- Service Taxes

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.serviceTaxes AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 ) AS serviceTaxes,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 )) > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 ) AS serviceTaxes,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 )) > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );

            /*
                Service Penalties
            */
                bucketTypeCode := 3; -- Service Penalties

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.servicePenalties AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceServiceChargePenalties" AS servicePenalties,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL  AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceServiceChargePenalties" AS servicePenalties,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL  AND inv."Created" IS NOT NULL)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );		
                
            /*
                Misc Charges
            */
                bucketTypeCode := 4; -- Misc Charges
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    CASE WHEN subquery.amount < 0 
                        THEN miscChargeCreditReference
                        ELSE reference 
                    END AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousCharges" > 0 OR invDetail."InvoiceMiscellaneousCharges" < 0) AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousCharges" > 0 OR invDetail."InvoiceMiscellaneousCharges" < 0) AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, miscChargesBucketType, subquery.serviceTypeCode) IS NULL
                AND "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, miscChargesBucketType) IS NULL;
                
            /*
                Misc Taxes
            */
                bucketTypeCode := 5; -- Misc Taxes
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    CASE WHEN subquery.amount < 0 
                        THEN miscChargeCreditReference
                        ELSE reference 
                    END AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargeTaxes" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousChargeTaxes" > 0 OR invDetail."InvoiceMiscellaneousChargeTaxes" < 0)  AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargeTaxes" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousChargeTaxes" > 0 OR invDetail."InvoiceMiscellaneousChargeTaxes" < 0) AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
            /*
                Misc Penalties
            */
                bucketTypeCode := 6; -- Misc Penalties
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargePenalties" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargePenalties" > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargePenalties" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargePenalties" > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
            /*
                Service Charges 2
            */
                bucketTypeCode := 7; -- Service Charges 2
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.servicecharges * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100 AS "Amount", 
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL
                AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) > 0;
                    
            /*
                Energy Assistance
            */
                bucketTypeCode := 9; -- Energy Assistance
                reference := 'UB_EnergyAss';

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."AppliedEnergyAssistance" AS amount,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."AppliedEnergyAssistance" > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."AppliedEnergyAssistance" AS amount,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."AppliedEnergyAssistance" > 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" IS NULL AND inv."Created" IS NOT NULL)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
                UPDATE "UB"."UBGLEntryDatas"
                SET "EventId" = subqueryDate."EventId"
                FROM ( 
                SELECT inv."BillingRunKey" as "BillingRunKey", uuid_generate_v4() AS "EventId"
                FROM "UB"."UBGLEntryDatas" as gle
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON gle."ReferenceKey" = invDetail."InvoiceDetailKey"
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                WHERE "EventId" IS NULL
                GROUP BY inv."BillingRunKey"
                ) AS subqueryDate
                INNER JOIN "UB"."Invoices" as inv ON subqueryDate."BillingRunKey" = inv."BillingRunKey"
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON inv."InvoiceKey" = invDetail."InvoiceKey"
                WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = invDetail."InvoiceDetailKey";

            END IF;
        END;
        END;

        /*
            Query to generate GL Records for Bad Debt Event Type (Old Invoices)
        */

        BEGIN
        DECLARE
            eventType INTEGER := 3; -- Event Type = 1 = Bad Debt
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_BadDebt';
            miscChargesBucketType INTEGER := 20;
            bucketTypeCode INTEGER := 1; -- Service Charges
        BEGIN
            IF EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
            THEN
            
                RAISE NOTICE 'Inserting Bad Debt Event Type records in "UBGLEntryDatas" table.';
                INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
                VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Bad Debt Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            /*
                Service Charges
            */
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    CASE WHEN "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL 
                        THEN subquery.servicecharges * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100
                        ELSE subquery.servicecharges 
                    END AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                ROUND((invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) - COALESCE( invDetail."InvoiceAmountReceived", 0 )), 2) AS serviceCharges,
                debitRecordType AS recordType,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) - COALESCE( invDetail."InvoiceAmountReceived", 0 )) > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                ROUND((invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) - COALESCE( invDetail."InvoiceAmountReceived", 0 )), 2) AS serviceCharges,
                creditRecordType AS recordType,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) - COALESCE( invDetail."InvoiceAmountReceived", 0 )) > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "EventDate" = subquery.invoiceDate AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );

            /*
                Service Taxes
            */
                bucketTypeCode := 2; -- Service Taxes

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.serviceTaxes AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 ) AS serviceTaxes,
                debitRecordType AS recordType,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 )) > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 ) AS serviceTaxes,
                creditRecordType AS recordType,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 )) > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "EventDate" = subquery.invoiceDate AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );

            /*
                Service Penalties
            */
                bucketTypeCode := 3; -- Service Penalties

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.servicePenalties AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceServiceChargePenalties" AS servicePenalties,
                debitRecordType AS recordType,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceServiceChargePenalties" > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceServiceChargePenalties" AS servicePenalties,
                creditRecordType AS recordType,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceServiceChargePenalties" > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "EventDate" = subquery.invoiceDate AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );		
                
            /*
                Misc Charges
            */
                bucketTypeCode := 4; -- Misc Charges
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousCharges" > 0 OR invDetail."InvoiceMiscellaneousCharges" < 0) 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousCharges" > 0 OR invDetail."InvoiceMiscellaneousCharges" < 0) 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "EventDate" = subquery.invoiceDate AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, miscChargesBucketType, subquery.serviceTypeCode) IS NULL
                AND "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, miscChargesBucketType) IS NULL;
                
            /*
                Misc Taxes
            */
                bucketTypeCode := 5; -- Misc Taxes
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargeTaxes" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousChargeTaxes" > 0 OR invDetail."InvoiceMiscellaneousChargeTaxes" < 0)  
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargeTaxes" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousChargeTaxes" > 0 OR invDetail."InvoiceMiscellaneousChargeTaxes" < 0) 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "EventDate" = subquery.invoiceDate AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, miscChargesBucketType, subquery.serviceTypeCode) IS NULL
                AND "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, miscChargesBucketType) IS NULL;
                
            /*
                Misc Penalties
            */
                bucketTypeCode := 6; -- Misc Penalties
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargePenalties" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargePenalties" > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargePenalties" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargePenalties" > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "EventDate" = subquery.invoiceDate AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, miscChargesBucketType, subquery.serviceTypeCode) IS NULL
                AND "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, miscChargesBucketType) IS NULL;
                
            /*
                Service Charges 2
            */
                bucketTypeCode := 7; -- Service Charges 2
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.servicecharges * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100 AS "Amount", 
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                debitRecordType AS recordType,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                creditRecordType AS recordType,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "EventDate" = subquery.invoiceDate AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL
                AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) > 0;
                
                
            /*
                Energy Assistance
            */
                bucketTypeCode := 9; -- Energy Assistance
                reference := 'UB_EnergyAss';

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."AppliedEnergyAssistance" AS amount,
                debitRecordType AS recordType,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."AppliedEnergyAssistance" > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate" AND invDetail."InvoiceStatusCode" != 2

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                acc."BadDebtFlagDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."AppliedEnergyAssistance" AS amount,
                creditRecordType AS recordType,
                acc."BadDebtFlagDate" AS Created,
                acc."BadDebtFlagDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."AppliedEnergyAssistance" > 0 
                AND acc."IsBadDebt" = true AND invDetail."UnpaidInvoiceAmount" > 0 AND inv."Created" < acc."BadDebtFlagDate"  AND invDetail."InvoiceStatusCode" != 2)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "EventDate" = subquery.invoiceDate AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
                UPDATE "UB"."UBGLEntryDatas"
                SET "EventId" = subqueryDate."EventId"
                FROM ( 
                SELECT inv."AccountKey" as "AccountKey", uuid_generate_v4() AS "EventId"
                FROM "UB"."UBGLEntryDatas" as gle
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON gle."ReferenceKey" = invDetail."InvoiceDetailKey"
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                WHERE "EventId" IS NULL
                GROUP BY inv."AccountKey"
                ) AS subqueryDate
                INNER JOIN "UB"."Invoices" as inv ON subqueryDate."AccountKey" = inv."AccountKey"
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON inv."InvoiceKey" = invDetail."InvoiceKey"
                WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = invDetail."InvoiceDetailKey";

            END IF;
        END;
        END;

        /*
            Query to generate GL Records for Bad Debt Event Type (New Invoices)
        */

        BEGIN
        DECLARE
            eventType INTEGER := 3; -- Event Type = 1 = Bad Debt
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_BadDebt';
            miscChargesBucketType INTEGER := 20;
            bucketTypeCode INTEGER := 1; -- Service Charges
        BEGIN
            IF EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
            THEN
            
                RAISE NOTICE 'Inserting Bad Event Type records in "UBGLEntryDatas" table.';
                INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
                VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Bad Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            /*
                Service Charges
            */
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    CASE WHEN "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL 
                        THEN subquery.servicecharges * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100
                        ELSE subquery.servicecharges 
                    END AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = true  AND inv."Created" IS NOT NULL)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                UPDATE "UB"."UBGLEntryDatas"
                SET "EventId" = subqueryDate."EventId"
                FROM ( 
                SELECT inv."BillingRunKey" as "BillingRunKey", uuid_generate_v4() AS "EventId"
                FROM "UB"."UBGLEntryDatas" as gle
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON gle."ReferenceKey" = invDetail."InvoiceDetailKey"
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                WHERE "EventId" IS NULL
                GROUP BY inv."BillingRunKey"
                ) AS subqueryDate
                INNER JOIN "UB"."Invoices" as inv ON subqueryDate."BillingRunKey" = inv."BillingRunKey"
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON inv."InvoiceKey" = invDetail."InvoiceKey"
                WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = invDetail."InvoiceDetailKey";

            /*
                Service Taxes
            */
                bucketTypeCode := 2; -- Service Taxes

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.serviceTaxes AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 ) AS serviceTaxes,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 )) > 0 AND acc."IsBadDebt" = true  AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 ) AS serviceTaxes,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 )) > 0 AND acc."IsBadDebt" = true  AND inv."Created" IS NOT NULL)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );

            /*
                Service Penalties
            */
                bucketTypeCode := 3; -- Service Penalties

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.servicePenalties AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceServiceChargePenalties" AS servicePenalties,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceServiceChargePenalties" > 0 AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceServiceChargePenalties" AS servicePenalties,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceServiceChargePenalties" > 0 AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );		
                
            /*
                Misc Charges
            */
                bucketTypeCode := 4; -- Misc Charges
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousCharges" > 0 OR invDetail."InvoiceMiscellaneousCharges" < 0) AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousCharges" > 0 OR invDetail."InvoiceMiscellaneousCharges" < 0) AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, miscChargesBucketType, subquery.serviceTypeCode) IS NULL
                AND "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, miscChargesBucketType) IS NULL;
                
            /*
                Misc Taxes
            */
                bucketTypeCode := 5; -- Misc Taxes
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargeTaxes" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousChargeTaxes" > 0 OR invDetail."InvoiceMiscellaneousChargeTaxes" < 0)  AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargeTaxes" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousChargeTaxes" > 0 OR invDetail."InvoiceMiscellaneousChargeTaxes" < 0) AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, miscChargesBucketType, subquery.serviceTypeCode) IS NULL
                AND "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, miscChargesBucketType) IS NULL;
                
            /*
                Misc Penalties
            */
                bucketTypeCode := 6; -- Misc Penalties
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargePenalties" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargePenalties" > 0 AND acc."IsBadDebt" = true  AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargePenalties" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargePenalties" > 0 AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, miscChargesBucketType, subquery.serviceTypeCode) IS NULL
                AND "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, miscChargesBucketType) IS NULL;
                
            /*
                Service Charges 2
            */
                bucketTypeCode := 7; -- Service Charges 2
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.servicecharges * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100 AS "Amount", 
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL
                AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) > 0;
                
                
            /*
                Energy Assistance
            */
                bucketTypeCode := 9; -- Energy Assistance
                reference := 'UB_EnergyAss';

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."AppliedEnergyAssistance" AS amount,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."AppliedEnergyAssistance" > 0 AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."AppliedEnergyAssistance" AS amount,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."AppliedEnergyAssistance" > 0 AND acc."IsBadDebt" = true AND inv."Created" IS NOT NULL)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
                UPDATE "UB"."UBGLEntryDatas"
                SET "EventId" = subqueryDate."EventId"
                FROM ( 
                SELECT inv."AccountKey" as "AccountKey", uuid_generate_v4() AS "EventId"
                FROM "UB"."UBGLEntryDatas" as gle
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON gle."ReferenceKey" = invDetail."InvoiceDetailKey"
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                WHERE "EventId" IS NULL
                GROUP BY inv."AccountKey"
                ) AS subqueryDate
                INNER JOIN "UB"."Invoices" as inv ON subqueryDate."AccountKey" = inv."AccountKey"
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON inv."InvoiceKey" = invDetail."InvoiceKey"
                WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = invDetail."InvoiceDetailKey";

            END IF;
        END;
        END;

        /*
            Query to generate GL Records for Payments Event Type
        */
        BEGIN
        DECLARE
            eventType INTEGER := 2; -- Event Type = 2 = Payments
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_Payment';
            miscChargesBucketType INTEGER := 20;
            bucketTypeCode INTEGER := 1; -- Service Charges
        BEGIN
            /*
                Service Charges
            */
            
            RAISE NOTICE 'Inserting Payment Event Type records in "UBGLEntryDatas" table.';
            INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
            VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Payment Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                CASE WHEN "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL 
                        THEN subquery.amount * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100
                        ELSE subquery.amount 
                END AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 ) AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 ) AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            );
            
            /*
                Service Taxes
            */
            bucketTypeCode := 2; -- Service Taxes
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToServiceTax" + COALESCE( ph."FuelAdjustmentTaxes", 0 ) AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (ph."AppliedToServiceTax" + COALESCE( ph."FuelAdjustmentTaxes", 0 )) > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToServiceTax" + COALESCE( ph."FuelAdjustmentTaxes", 0 ) AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (ph."AppliedToServiceTax" + COALESCE( ph."FuelAdjustmentTaxes", 0 )) > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            );
            
            /*
                Service Penalties
            */
            bucketTypeCode := 3; -- Service Penalties
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToServiceChargePenalties" AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToServiceChargePenalties" AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            );
            
            /*
                Misc Charges
            */
            bucketTypeCode := 4; -- Misc Charges
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToMiscService" AS amount,
            mca."MiscChargeCodeKey" AS miscChargeCodeKey,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"	
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscService" > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToMiscService" AS amount,
            mca."MiscChargeCodeKey" AS miscChargeCodeKey,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscService" > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            ) AND "UB".IsSpecialMiscCharge(subquery.miscChargeCodeKey) = false;
            
            /*
                Misc Taxes
            */
            bucketTypeCode := 5; -- Misc Taxes

            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToMiscTax" AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscTax" > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToMiscTax" AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscTax" > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            );
            
            /*
                Misc Penalties
            */
            bucketTypeCode := 6; -- Misc Penalties

            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToMiscServiceChargePenalties" AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToMiscServiceChargePenalties" AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            );
            
            /*
                Service Charges 2
            */
            
            bucketTypeCode := 7; -- Service Charges 2
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                subquery.amount * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100 AS "Amount", 
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 ) AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 ) AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            ) AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL
            AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) > 0;
            
            
            /*
                Overpayments
            */
            
            bucketTypeCode := 8; -- Overpayments
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT DISTINCT ON (pay."PaymentKey")
            ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            "UB".GetFirstServiceTypeCode(acc."AccountKey") AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            opl."AmountPaid" AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            INNER JOIN "UB"."OverPaymentLogs" opl ON pay."PaymentKey" = opl."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND opl."AmountPaid" > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT DISTINCT ON (pay."PaymentKey")
            ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            "UB".GetFirstServiceTypeCode(acc."AccountKey") AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            opl."AmountPaid" AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            INNER JOIN "UB"."OverPaymentLogs" opl ON pay."PaymentKey" = opl."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND opl."AmountPaid" > 0 AND acc."IsBadDebt" = false AND pay."Created" IS NOT NULL
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas"  AS gld
                INNER JOIN "UB"."PaymentHistories" ph ON gld."ReferenceKey" = ph."PaymentHistoryKey"
                INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
                WHERE pay."PaymentKey" = subquery.paymentKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                (gld."RecordType" = debitRecordType OR gld."RecordType" = creditRecordType )
            );
            
            UPDATE "UB"."UBGLEntryDatas"
            SET "EventId" = subqueryDate."EventId"
            FROM ( 
            SELECT pay."PaymentKey" as "PaymentKey", uuid_generate_v4() AS "EventId"
            FROM "UB"."UBGLEntryDatas" as gle
            INNER JOIN "UB"."PaymentHistories" as ph ON gle."ReferenceKey" = ph."PaymentHistoryKey"
            INNER JOIN "UB"."Payments" as pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE "EventId" IS NULL
            GROUP BY pay."PaymentKey"
            ) AS subqueryDate
            INNER JOIN "UB"."Payments" as pay ON subqueryDate."PaymentKey" = pay."PaymentKey"
            INNER JOIN "UB"."PaymentHistories" as ph ON pay."PaymentKey" = ph."PaymentKey"
            WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = ph."PaymentHistoryKey";
            
            /*
                Energy Assistance
            */
            
            bucketTypeCode := 9; -- Energy Assistance
            reference := 'UB_EnergyAss';
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventId", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                uuid_generate_v4() AS "EventId",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.energyAssistancePaidHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT DISTINCT ON (ph."EnergyAssistancePaidHistoryKey")
            ph."EnergyAssistancePaidHistoryKey" AS energyAssistancePaidHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            br."Created" AS paymentDate,
            creditRecordType AS recordType,
            ph."PaidAmount" AS amount,
            inv."Created" AS Created,
            inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."EnergyAssistancePaidHistories" as ph
            INNER JOIN "UB"."Invoices" as inv ON ph."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON inv."InvoiceKey" = invDetail."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."BillingRuns" br ON ph."BillingRunKey" = br."BillingRunKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."PaidAmount" > 0 AND acc."IsBadDebt" = false AND inv."Created" IS NOT NULL
            
            UNION	
            
            SELECT DISTINCT ON (ph."EnergyAssistancePaidHistoryKey")
            ph."EnergyAssistancePaidHistoryKey" AS energyAssistancePaidHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            br."Created" AS paymentDate,
            debitRecordType AS recordType,
            ph."PaidAmount" AS amount,
            inv."Created" AS Created,
            inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."EnergyAssistancePaidHistories" as ph
            INNER JOIN "UB"."Invoices" as inv ON ph."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON inv."InvoiceKey" = invDetail."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."BillingRuns" br ON ph."BillingRunKey" = br."BillingRunKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."PaidAmount" > 0 AND acc."IsBadDebt" = false AND inv."Created" IS NOT NULL
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas"  AS gld
                INNER JOIN "UB"."EnergyAssistancePaidHistories" ph ON gld."ReferenceKey" = ph."EnergyAssistancePaidHistoryKey"
                WHERE ph."EnergyAssistancePaidHistoryKey" = subquery.energyAssistancePaidHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                (gld."RecordType" = debitRecordType OR gld."RecordType" = creditRecordType )
            );
            
            UPDATE "UB"."UBGLEntryDatas"
            SET "EventId" = subqueryDate."EventId"
            FROM ( 
            SELECT pay."PaymentKey" as "PaymentKey", uuid_generate_v4() AS "EventId"
            FROM "UB"."UBGLEntryDatas" as gle
            INNER JOIN "UB"."PaymentHistories" as ph ON gle."ReferenceKey" = ph."PaymentHistoryKey"
            INNER JOIN "UB"."Payments" as pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE "EventId" IS NULL
            GROUP BY pay."PaymentKey"
            ) AS subqueryDate
            INNER JOIN "UB"."Payments" as pay ON subqueryDate."PaymentKey" = pay."PaymentKey"
            INNER JOIN "UB"."PaymentHistories" as ph ON pay."PaymentKey" = ph."PaymentKey"
            WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = ph."PaymentHistoryKey";
        END;
        END;

        /*
            Query to generate GL Records for Bad Debt Write Off Event Type
        */
        BEGIN
        DECLARE
            eventType INTEGER := 5; -- Event Type = 5 = Bad Debt Write Off
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_BD_WriteOff';
            bucketCreditTypeCode INTEGER := 10; -- Bad Debt (Account Receivable) (Credit)
            bucketDebitTypeCode INTEGER := 12; -- Bad Debt Write off (Expenses) (Debit)
        BEGIN
            IF EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
            THEN
            
            RAISE NOTICE 'Inserting Bad Debt Write Off Event Type records in "UBGLEntryDatas" table.';
            INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
            VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Bad Debt Write Off Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.invoiceDate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByOnlyServiceDistributionSetting(eventType, subquery.servicetypecode, subquery.bucketTypeCode) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.invoiceDetailKey AS "ReferenceKey",
                subquery.bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
            acc."BadDebtWriteOffDate" AS invoiceDate,
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            debitRecordType AS recordType,
            bucketDebitTypeCode As bucketTypeCode,
            invDetail."UnpaidInvoiceAmount" AS amount,
            acc."BadDebtWriteOffDate" AS Created,
            acc."BadDebtWriteOffDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."InvoiceDetails" as invDetail
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."UnpaidInvoiceAmount" > 0 AND acc."IsBadDebtWriteOff" = true
            
            UNION	
            
            SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
            acc."BadDebtWriteOffDate" AS invoiceDate,
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            creditRecordType AS recordType,
            bucketCreditTypeCode As bucketTypeCode,
            invDetail."UnpaidInvoiceAmount" AS amount,
            acc."BadDebtWriteOffDate" AS Created,
            acc."BadDebtWriteOffDate" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."InvoiceDetails" as invDetail
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."UnpaidInvoiceAmount" > 0 AND acc."IsBadDebtWriteOff" = true
            )
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
                
            UPDATE "UB"."UBGLEntryDatas"
            SET "EventId" = subqueryDate."EventId"
            FROM ( 
            SELECT inv."AccountKey" as "AccountKey", uuid_generate_v4() AS "EventId"
            FROM "UB"."UBGLEntryDatas" as gle
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON gle."ReferenceKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            WHERE "EventId" IS NULL
            GROUP BY inv."AccountKey"
            ) AS subqueryDate
            INNER JOIN "UB"."Invoices" as inv ON subqueryDate."AccountKey" = inv."AccountKey"
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON inv."InvoiceKey" = invDetail."InvoiceKey"
            WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = invDetail."InvoiceDetailKey";
            END IF;
        END;
        END;

        /*
            Query to generate GL Records for Bad Debt Payment Event Type
        */
        BEGIN
        DECLARE
            eventType INTEGER := 4; -- Event Type = 4 = Bad Debt Payments
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_BD_Payment';
            bucketCreditTypeCode INTEGER := 10; -- Bad Debt (Account Receivable) (Credit)
            bucketDebitTypeCode INTEGER := 11; -- Bad Debt Payments (Cash) (Debit)
        BEGIN

            RAISE NOTICE 'Inserting Bad Debt Payment Event Type records in "UBGLEntryDatas" table.';
            INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
            VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Bad Debt Payment Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);

            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, subquery.bucketTypeCode) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                subquery.bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            bucketDebitTypeCode As bucketTypeCode,
            ph."AmountPaid" AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AmountPaid" > 0 AND acc."IsBadDebt" = true AND acc."IsBadDebtWriteOff" = false
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            bucketCreditTypeCode As bucketTypeCode,
            ph."AmountPaid" AS amount,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AmountPaid" > 0 AND acc."IsBadDebt" = true AND acc."IsBadDebtWriteOff" = false
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            );
            UPDATE "UB"."UBGLEntryDatas"
            SET "EventId" = subqueryDate."EventId"
            FROM ( 
            SELECT pay."PaymentKey" as "PaymentKey", uuid_generate_v4() AS "EventId"
            FROM "UB"."UBGLEntryDatas" as gle
            INNER JOIN "UB"."PaymentHistories" as ph ON gle."ReferenceKey" = ph."PaymentHistoryKey"
            INNER JOIN "UB"."Payments" as pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE "EventId" IS NULL
            GROUP BY pay."PaymentKey"
            ) AS subqueryDate
            INNER JOIN "UB"."Payments" as pay ON subqueryDate."PaymentKey" = pay."PaymentKey"
            INNER JOIN "UB"."PaymentHistories" as ph ON pay."PaymentKey" = ph."PaymentKey"
            WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = ph."PaymentHistoryKey";
        END;
        END;

        /*
            Query to generate GL Records for Misc Charges Event Type
        */
        BEGIN
        DECLARE
            eventType INTEGER := 7; -- Event Type = 7 = Misc Charges
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_MiscCharge';
            debitBucketTypeCode INTEGER := 20; -- Cash (Debit)
            arBucketTypeCode INTEGER := 21; -- Accounts Receivables (required only if Accrual Accounting) (Credit/Debit)
            creditBucketTypeCode INTEGER := 22; -- Revenue (Credit)
        BEGIN
            IF EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
            THEN
            
            RAISE NOTICE 'Inserting Special Misc Event Type records in "UBGLEntryDatas" table.';
            INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
            VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Special Misc Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            /*
                Misc Charges Distributed by Service Type (Billing)
            */
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, subquery.bucketTypeCode, subquery.serviceTypeCode) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    subquery.bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                debitRecordType AS recordType,
                arBucketTypeCode AS bucketTypeCode,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousCharges" > 0 OR invDetail."InvoiceMiscellaneousCharges" < 0) AND (ABS(invDetail."InvoiceMiscellaneousCharges") = ABS(mca."ChargeAmount"))

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                creditRecordType AS recordType,
                creditBucketTypeCode AS bucketTypeCode,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousCharges" > 0 OR invDetail."InvoiceMiscellaneousCharges" < 0) AND (ABS(invDetail."InvoiceMiscellaneousCharges") = ABS(mca."ChargeAmount"))) 
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = subquery.bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, subquery.bucketTypeCode, subquery.serviceTypeCode) IS NOT NULL;
                
            /*
                Misc Charges Service Agnostic Distribution (Billing)
            */
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, subquery.bucketTypeCode) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    subquery.bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                debitRecordType AS recordType,
                arBucketTypeCode AS bucketTypeCode,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousCharges" > 0 OR invDetail."InvoiceMiscellaneousCharges" < 0) AND (ABS(invDetail."InvoiceMiscellaneousCharges") = ABS(mca."ChargeAmount"))

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                creditRecordType AS recordType,
                creditBucketTypeCode AS bucketTypeCode,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceMiscellaneousCharges" > 0 OR invDetail."InvoiceMiscellaneousCharges" < 0))
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = subquery.bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, subquery.bucketTypeCode) IS NOT NULL;
                
                
                UPDATE "UB"."UBGLEntryDatas"
                SET "EventId" = subqueryDate."EventId"
                FROM ( 
                SELECT inv."BillingRunKey" as "BillingRunKey", uuid_generate_v4() AS "EventId"
                FROM "UB"."UBGLEntryDatas" as gle
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON gle."ReferenceKey" = invDetail."InvoiceDetailKey"
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                WHERE "EventId" IS NULL
                GROUP BY inv."BillingRunKey"
                ) AS subqueryDate
                INNER JOIN "UB"."Invoices" as inv ON subqueryDate."BillingRunKey" = inv."BillingRunKey"
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON inv."InvoiceKey" = invDetail."InvoiceKey"
                WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = invDetail."InvoiceDetailKey";

            END IF;
            
            /*
                Misc Charges Distributed by Service Type (Payment)
            */
            
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, subquery.bucketTypeCodeValue, subquery.serviceTypeCode) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                subquery.bucketTypeCodeValue AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            debitBucketTypeCode AS bucketTypeCodeValue,	
            ph."AppliedToMiscService" AS amount,
            mca."MiscChargeCodeKey" AS miscChargeCodeKey,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"	
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscService" > 0
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            CASE WHEN EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
            THEN arBucketTypeCode
            ELSE creditBucketTypeCode
            END AS bucketTypeCodeValue,		
            ph."AppliedToMiscService" AS amount,
            mca."MiscChargeCodeKey" AS miscChargeCodeKey,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscService" > 0
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = subquery.bucketTypeCodeValue AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            ) AND 
                "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, subquery.bucketTypeCodeValue, subquery.serviceTypeCode) IS NOT NULL;
            
            /*
                Misc Charges Service Agnostic Distribution (Payment)
            */
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, subquery.bucketTypeCodeValue) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                subquery.bucketTypeCodeValue AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            debitBucketTypeCode As bucketTypeCodeValue,	
            ph."AppliedToMiscService" AS amount,
            mca."MiscChargeCodeKey" AS miscChargeCodeKey,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"	
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscService" > 0
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            CASE WHEN EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
                THEN arBucketTypeCode
                ELSE creditBucketTypeCode
                END AS bucketTypeCodeValue,	
            ph."AppliedToMiscService" AS amount,
            mca."MiscChargeCodeKey" AS miscChargeCodeKey,
            pay."Created" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscService" > 0
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = subquery.bucketTypeCodeValue AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            ) AND 
                "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, subquery.bucketTypeCodeValue) IS NOT NULL;
            
            
            UPDATE "UB"."UBGLEntryDatas"
            SET "EventId" = subqueryDate."EventId"
            FROM ( 
            SELECT pay."PaymentKey" as "PaymentKey", uuid_generate_v4() AS "EventId"
            FROM "UB"."UBGLEntryDatas" as gle
            INNER JOIN "UB"."PaymentHistories" as ph ON gle."ReferenceKey" = ph."PaymentHistoryKey"
            INNER JOIN "UB"."Payments" as pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE "EventId" IS NULL
            GROUP BY pay."PaymentKey"
            ) AS subqueryDate
            INNER JOIN "UB"."Payments" as pay ON subqueryDate."PaymentKey" = pay."PaymentKey"
            INNER JOIN "UB"."PaymentHistories" as ph ON pay."PaymentKey" = ph."PaymentKey"
            WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = ph."PaymentHistoryKey";
            
        END;
        END;

        /*
            Query to generate GL Records for Deposits and Interest Event Type
        */
        BEGIN
        DECLARE
            eventType INTEGER := 6; -- Event Type = 6 = Deposits and Interest
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_Deposits';
            bucketDebitTypeCode INTEGER := 13; -- Deposit Received (Cash) (Debit)
            bucketCreditTypeCode INTEGER := 14; -- Deposit Received (Liability/Revenue) (Credit)
            refundType TEXT := 'Apply To Balance'; 
        BEGIN
            /*
                Deposit Received
            */
            
            
            RAISE NOTICE 'Inserting Deposits and Interest Event Type records in "UBGLEntryDatas" table.';
            INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
            VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Deposits and Interest Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByOnlyServiceDistributionSetting(eventType, subquery.servicetypecode, subquery.bucketTypeCode) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                subquery.bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            debitRecordType AS recordType,
            bucketDebitTypeCode As bucketTypeCode,
            ph."Deposit" AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."Deposit" > 0
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')

            UNION	

            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentDate" AS paymentDate,
            creditRecordType AS recordType,
            bucketCreditTypeCode AS bucketTypeCode,
            ph."Deposit" AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."Deposit" > 0
            AND (pay."SystemPaymentType" is null OR pay."SystemPaymentType" <> 'BalanceAdjustment')
            )
            AS subquery

            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            );
            UPDATE "UB"."UBGLEntryDatas"
            SET "EventId" = subqueryDate."EventId"
            FROM ( 
            SELECT pay."PaymentKey" as "PaymentKey", uuid_generate_v4() AS "EventId"
            FROM "UB"."UBGLEntryDatas" as gle
            INNER JOIN "UB"."PaymentHistories" as ph ON gle."ReferenceKey" = ph."PaymentHistoryKey"
            INNER JOIN "UB"."Payments" as pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE "EventId" IS NULL
            GROUP BY pay."PaymentKey"
            ) AS subqueryDate
            INNER JOIN "UB"."Payments" as pay ON subqueryDate."PaymentKey" = pay."PaymentKey"
            INNER JOIN "UB"."PaymentHistories" as ph ON pay."PaymentKey" = ph."PaymentKey"
            WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = ph."PaymentHistoryKey";
            
            /*
                Deposit Refund/Apply to Balance
            */
            bucketDebitTypeCode := 15; -- Deposit Refund/Apply to Balance (Liability/Revenue) (Debit) 
            bucketCreditTypeCode := 16; -- Deposit Refund/Apply to Balance (Cash) (Credit)
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.eventDate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByOnlyServiceDistributionSetting(eventType, subquery.serviceTypeCode, subquery.bucketTypeCode) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.serviceDepositKey AS "ReferenceKey",
                subquery.bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT sd."ServiceDepositKey" AS serviceDepositKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            ser."ServiceTypeCode" AS serviceTypeCode,
            sd."LastModified" AS eventDate,
            debitRecordType AS recordType,
            bucketDebitTypeCode As bucketTypeCode,
            sd."DepositRefunded" AS amount,
            sd."LastModified" AS Created,
            sd."LastModified" AS LastModified, sd."ServiceKey" AS InvoiceKey
            FROM "UB"."ServiceDeposits" as sd
            INNER JOIN "UB"."Services" as ser ON sd."ServiceKey" = ser."ServiceKey"
            INNER JOIN "UB"."Accounts" acc ON ser."AccountKey" = acc."AccountKey"
            WHERE (invoice_key IS NULL OR ser."ServiceKey" = invoice_key) AND sd."DepositRefunded" > 0 AND sd."RefundType" = refundType AND sd."LastModified" is not null

            UNION	

            SELECT sd."ServiceDepositKey" AS serviceDepositKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            ser."ServiceTypeCode" AS serviceTypeCode,
            sd."LastModified" AS eventDate,
            creditRecordType AS recordType,
            bucketCreditTypeCode As bucketTypeCode,
            sd."DepositRefunded" AS amount,
            sd."LastModified" AS Created,
            sd."LastModified" AS LastModified, sd."ServiceKey" AS InvoiceKey
            FROM "UB"."ServiceDeposits" as sd
            INNER JOIN "UB"."Services" as ser ON sd."ServiceKey" = ser."ServiceKey"
            INNER JOIN "UB"."Accounts" acc ON ser."AccountKey" = acc."AccountKey"
            WHERE (invoice_key IS NULL OR ser."ServiceKey" = invoice_key) AND sd."DepositRefunded" > 0 AND sd."RefundType" = refundType AND sd."LastModified" is not null
            )
            AS subquery

            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.serviceDepositKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            );
            UPDATE "UB"."UBGLEntryDatas"
            SET "EventId" = subqueryDate."EventId"
            FROM ( 
            SELECT gle."ReferenceKey" as "ReferenceKey", uuid_generate_v4() AS "EventId"
            FROM "UB"."UBGLEntryDatas" as gle
            WHERE "EventId" IS NULL
            GROUP BY gle."ReferenceKey"
            ) AS subqueryDate
            WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = subqueryDate."ReferenceKey";

            /*
                Deposit Interest
            */
            bucketDebitTypeCode := 17; -- Deposit Interest (Expense) (Debit)
            bucketCreditTypeCode := 18; -- Deposit Interest (Liability) (Credit/Debit)
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.eventDate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByOnlyServiceDistributionSetting(eventType, subquery.serviceTypeCode, subquery.bucketTypeCode) AS "GLAccountNumber",
                subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.serviceDepositKey AS "ReferenceKey",
                subquery.bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT sd."ServiceDepositKey" AS serviceDepositKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            ser."ServiceTypeCode" AS serviceTypeCode,
            sd."LastModified" AS eventDate,
            debitRecordType AS recordType,
            bucketDebitTypeCode As bucketTypeCode,
            sd."Intrest" AS amount,
            sd."LastModified" AS Created,
            sd."LastModified" AS LastModified, sd."ServiceKey" AS InvoiceKey
            FROM "UB"."ServiceDeposits" as sd
            INNER JOIN "UB"."Services" as ser ON sd."ServiceKey" = ser."ServiceKey"
            INNER JOIN "UB"."Accounts" acc ON ser."AccountKey" = acc."AccountKey"
            WHERE (invoice_key IS NULL OR ser."ServiceKey" = invoice_key) AND sd."Intrest" > 0 AND sd."LastModified" is not null

            UNION	

            SELECT sd."ServiceDepositKey" AS serviceDepositKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            ser."ServiceTypeCode" AS serviceTypeCode,
            sd."LastModified" AS eventDate,
            creditRecordType AS recordType,
            bucketCreditTypeCode As bucketTypeCode,
            sd."Intrest" AS amount,
            sd."LastModified" AS Created,
            sd."LastModified" AS LastModified, sd."ServiceKey" AS InvoiceKey
            FROM "UB"."ServiceDeposits" as sd
            INNER JOIN "UB"."Services" as ser ON sd."ServiceKey" = ser."ServiceKey"
            INNER JOIN "UB"."Accounts" acc ON ser."AccountKey" = acc."AccountKey"
            WHERE (invoice_key IS NULL OR ser."ServiceKey" = invoice_key) AND sd."Intrest" > 0 AND sd."LastModified" is not null
            )
            AS subquery

            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.serviceDepositKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
            );
            UPDATE "UB"."UBGLEntryDatas"
            SET "EventId" = subqueryDate."EventId"
            FROM ( 
            SELECT gle."ReferenceKey" as "ReferenceKey", uuid_generate_v4() AS "EventId"
            FROM "UB"."UBGLEntryDatas" as gle
            WHERE "EventId" IS NULL
            GROUP BY gle."ReferenceKey"
            ) AS subqueryDate
            WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = subqueryDate."ReferenceKey";
            
        END;
        END;

        /*
            Query to generate GL Records for Void Payments Event Type
        */
        BEGIN
        DECLARE
            eventType INTEGER := 2; -- Event Type = 2 = Payments
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_VoidPayment';
            miscChargesBucketType INTEGER := 20;
            bucketTypeCode INTEGER := 1; -- Service Charges
        BEGIN
            /*
                Service Charges
            */
            
            RAISE NOTICE 'Inserting Void Payment Event Type records in "UBGLEntryDatas" table.';
            INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
            VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Void Payment Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                CASE WHEN "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL 
                        THEN -subquery.amount * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100
                        ELSE -subquery.amount 
                END AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 ) AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            
            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 ) AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType ) AND
                "Reference" = reference
            );
            
            /*
                Service Taxes
            */
            bucketTypeCode := 2; -- Service Taxes
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                -subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToServiceTax" + COALESCE( ph."FuelAdjustmentTaxes", 0 ) AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (ph."AppliedToServiceTax" + COALESCE( ph."FuelAdjustmentTaxes", 0 )) > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            
            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToServiceTax" + COALESCE( ph."FuelAdjustmentTaxes", 0 ) AS amount,
            pay."Created" AS LastModified,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (ph."AppliedToServiceTax" + COALESCE( ph."FuelAdjustmentTaxes", 0 )) > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType ) AND
                "Reference" = reference
            );
            
            /*
                Service Penalties
            */
            bucketTypeCode := 3; -- Service Penalties
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                -subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToServiceChargePenalties" AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            
            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToServiceChargePenalties" AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType ) AND
                "Reference" = reference
            );
            
            /*
                Misc Charges
            */
            bucketTypeCode := 4; -- Misc Charges
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                -subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToMiscService" AS amount,
            mca."MiscChargeCodeKey" AS miscChargeCodeKey,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"	
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscService" > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            
            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToMiscService" AS amount,
            mca."MiscChargeCodeKey" AS miscChargeCodeKey,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscService" > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            )
            AS subquery
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType ) AND
                "Reference" = reference
            )AND "UB".IsSpecialMiscCharge(subquery.miscChargeCodeKey) = false	;
            
            
            /*
                Misc Taxes
            */
            bucketTypeCode := 5; -- Misc Taxes
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                -subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToMiscTax" AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscTax" > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            
            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToMiscTax" AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscTax" > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType ) AND
                "Reference" = reference
            );
            
            /*
                Misc Penalties
            */
            bucketTypeCode := 6; -- Misc Penalties
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                -subquery.amount AS "Amount",
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToMiscServiceChargePenalties" AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            
            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToMiscServiceChargePenalties" AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToMiscServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType ) AND
                "Reference" = reference
            );
            
            /*
                Service Charges 2
            */
            
            bucketTypeCode := 7; -- Service Charges 2
            
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
            SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                Now() AS "CreatedDateForGL", 
                subquery.paymentdate AS "EventDate",
                eventType AS "EventType",
                subquery.recordType AS "RecordType",
                "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                -subquery.amount * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100 AS "Amount", 
                reference AS "Reference",
                false AS "IsProcessed",
                subquery.paymentHistoryKey AS "ReferenceKey",
                bucketTypeCode AS "GLDistributionBucketTypeCode",
                false AS "IsInActive",
                subquery.created AS "Created",
                subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
            FROM
            (
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            debitRecordType AS recordType,
            ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 ) AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToServiceCharge" > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            
            UNION	
            
            SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
            acc."AccountTypeCode" AS accountTypeCode,
            invDetail."ServiceTypeCode" AS serviceTypeCode,
            pay."PaymentKey" AS paymentKey,
            pay."PaymentVoidDate" AS paymentDate,
            creditRecordType AS recordType,
            ph."AppliedToServiceCharge" + COALESCE( ph."AdditionalCharge", 0 ) + COALESCE( ph."FuelAdjustmentCharge", 0 ) AS amount,
            pay."LastModified" AS Created,
            pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
            FROM "UB"."PaymentHistories" as ph
            INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
            INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
            INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
            INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND ph."AppliedToServiceCharge" > 0 AND acc."IsBadDebt" = false AND pay."IsVoid" = true
            )
            AS subquery
            
            WHERE NOT EXISTS 
            (
                SELECT 1 
                FROM "UB"."UBGLEntryDatas" 
                WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                "EventType" = eventType AND
                "GLDistributionBucketTypeCode" = bucketTypeCode AND
                ("RecordType" = debitRecordType OR "RecordType" = creditRecordType ) AND
                "Reference" = reference
            ) AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL
            AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) > 0;

            UPDATE "UB"."UBGLEntryDatas"
            SET "EventId" = subqueryDate."EventId"
            FROM ( 
            SELECT pay."PaymentKey" as "PaymentKey", uuid_generate_v4() AS "EventId"
            FROM "UB"."UBGLEntryDatas" as gle
            INNER JOIN "UB"."PaymentHistories" as ph ON gle."ReferenceKey" = ph."PaymentHistoryKey"
            INNER JOIN "UB"."Payments" as pay ON ph."PaymentKey" = pay."PaymentKey"
            WHERE "EventId" IS NULL
            GROUP BY pay."PaymentKey"
            ) AS subqueryDate
            INNER JOIN "UB"."Payments" as pay ON subqueryDate."PaymentKey" = pay."PaymentKey"
            INNER JOIN "UB"."PaymentHistories" as ph ON pay."PaymentKey" = ph."PaymentKey"
            WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = ph."PaymentHistoryKey" AND "UB"."UBGLEntryDatas"."Reference" = reference;
            
        END;
        END;

        /*
            Query to generate GL Records (Correct Invoices) Billing Event Type
        */
        BEGIN
        DECLARE
            eventType INTEGER := 1; -- Event Type = 1 = Billing
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_Billing';
            miscChargesBucketType INTEGER := 20;
            bucketTypeCode INTEGER := 1; -- Service Charges
        BEGIN
            IF EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
            THEN
            
            RAISE NOTICE 'Inserting Correct Invoices Event Type Records in "UBGLEntryDatas" table.';
            INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
            VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Correct Invoices Event Type Records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            /*
                Service Charges
            */
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    CASE WHEN "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL 
                        THEN -subquery.servicecharges * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100
                        ELSE -subquery.servicecharges 
                    END AS "Amount", 
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                debitRecordType AS recordType,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                creditRecordType AS recordType,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );

            /*
                Service Taxes
            */
                bucketTypeCode := 2; -- Service Taxes

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    -subquery.serviceTaxes AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 ) AS serviceTaxes,
                debitRecordType AS recordType,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceCalculationTaxes" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculationTaxes" + COALESCE( invDetail."FuelAdjustmentTaxes", 0 ) AS serviceTaxes,
                creditRecordType AS recordType,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceCalculationTaxes" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );

            /*
                Service Penalties
            */
                bucketTypeCode := 3; -- Service Penalties

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    -subquery.servicePenalties AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceServiceChargePenalties" AS servicePenalties,
                debitRecordType AS recordType,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceServiceChargePenalties" AS servicePenalties,
                creditRecordType AS recordType,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceServiceChargePenalties" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );		
                
            /*
                Misc Charges
            */
                bucketTypeCode := 4; -- Misc Charges
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    -subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousCharges" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousCharges" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, miscChargesBucketType, subquery.serviceTypeCode) IS NULL
                AND "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, miscChargesBucketType) IS NULL;
                
            /*
                Misc Taxes
            */
                bucketTypeCode := 5; -- Misc Taxes
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    -subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargeTaxes" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargeTaxes" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargeTaxes" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargeTaxes" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
            /*
                Misc Penalties
            */
                bucketTypeCode := 6; -- Misc Penalties
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    -subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargePenalties" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargePenalties" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargePenalties" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargePenalties" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true)
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
            /*
                Service Charges 2
            */
                bucketTypeCode := 7; -- Service Charges 2
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    -subquery.servicecharges * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100 AS "Amount", 
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                debitRecordType AS recordType,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 ) AS serviceCharges,
                creditRecordType AS recordType,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND (invDetail."InvoiceCalculations" + COALESCE( invDetail."AdditionalCharge", 0 ) + COALESCE( invDetail."FuelAdjustmentCharge", 0 )) > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL
                AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) > 0;
                    
            /*
                Energy Assistance
            */
                bucketTypeCode := 9; -- Energy Assistance
                reference := 'UB_EnergyAss';

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    -subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."AppliedEnergyAssistance" AS amount,
                debitRecordType AS recordType,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."AppliedEnergyAssistance" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."AppliedEnergyAssistance" AS amount,
                creditRecordType AS recordType,
                inv."LastModified" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."AppliedEnergyAssistance" > 0 AND acc."IsBadDebt" = false AND inv."IsCorrected" = true)

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
                UPDATE "UB"."UBGLEntryDatas"
                SET "EventId" = subqueryDate."EventId"
                FROM ( 
                SELECT inv."BillingRunKey" as "BillingRunKey", uuid_generate_v4() AS "EventId"
                FROM "UB"."UBGLEntryDatas" as gle
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON gle."ReferenceKey" = invDetail."InvoiceDetailKey"
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."PreviousInvoiceKey"
                WHERE "EventId" IS NULL
                GROUP BY inv."BillingRunKey"
                ) AS subqueryDate
                INNER JOIN "UB"."Invoices" as inv ON subqueryDate."BillingRunKey" = inv."BillingRunKey"
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON inv."PreviousInvoiceKey" = invDetail."InvoiceKey"
                WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = invDetail."InvoiceDetailKey" AND "UB"."UBGLEntryDatas"."Reference" = reference;

            END IF;
        END;
        END;

        /*
            Query to generate GL Records for Balance Adjustment Event Type
        */
        BEGIN
        DECLARE
            eventType INTEGER := 1; -- Event Type = 1 = Billing
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_Bal_Adj';
            bucketTypeCode INTEGER := 1; -- Service Charges
        BEGIN
            IF EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
            THEN
            /*
                Service Charges
            */
            
                RAISE NOTICE 'Inserting Balance Adjustment Event Type records in "UBGLEntryDatas" table.';
                INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
                VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Balance Adjustment Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventId", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    uuid_generate_v4() AS "EventId",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    CASE WHEN "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL 
                        THEN subquery.servicecharges * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100
                        ELSE subquery.servicecharges 
                    END AS "Amount", 
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" AS serviceCharges,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceCalculations" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment'

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" AS serviceCharges,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceCalculations" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment')

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );

            /*
                Service Taxes
            */
                bucketTypeCode := 2; -- Service Taxes

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventId", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    uuid_generate_v4() AS "EventId",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.serviceTaxes AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculationTaxes" AS serviceTaxes,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceCalculationTaxes" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment'

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculationTaxes" AS serviceTaxes,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceCalculationTaxes" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment')

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );

            /*
                Service Penalties
            */
                bucketTypeCode := 3; -- Service Penalties

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventId", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    uuid_generate_v4() AS "EventId",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.servicePenalties AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceServiceChargePenalties" AS servicePenalties,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceServiceChargePenalties" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment'

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceServiceChargePenalties" AS servicePenalties,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceServiceChargePenalties" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment')

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );		
                
            /*
                Misc Charges
            */
                bucketTypeCode := 4; -- Misc Charges
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventId", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    uuid_generate_v4() AS "EventId",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousCharges" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment'

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousCharges" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment')
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
            /*
                Misc Taxes
            */
                bucketTypeCode := 5; -- Misc Taxes
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventId", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    uuid_generate_v4() AS "EventId",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargeTaxes" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargeTaxes" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment'

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargeTaxes" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargeTaxes" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment')
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
            /*
                Misc Penalties
            */
                bucketTypeCode := 6; -- Misc Penalties
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate",  "EventId", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    uuid_generate_v4() AS "EventId",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargePenalties" AS amount,
                debitRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargePenalties" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment'

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousChargePenalties" AS amount,
                creditRecordType AS recordType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousChargePenalties" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment')
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
                
            /*
                Service Charges 2
            */
                bucketTypeCode := 7; -- Service Charges 2
            
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate",  "EventId", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    uuid_generate_v4() AS "EventId",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.servicecharges * "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode)/100 AS "Amount", 
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" AS serviceCharges,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceCalculations" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment'

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."InvoiceCalculations" AS serviceCharges,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceCalculations" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment')

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                ) AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) IS NOT NULL
                AND "UB".GetPercentageByDistributionSetting(eventType, subquery.servicetypecode, subquery.accounttypecode, bucketTypeCode) > 0;
                    
            /*
                Energy Assistance
            */
                bucketTypeCode := 9; -- Energy Assistance
                reference := 'UB_EnergyAss';

                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate",  "EventId", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    uuid_generate_v4() AS "EventId",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."AppliedEnergyAssistance" AS amount,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."AppliedEnergyAssistance" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment'

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                invDetail."AppliedEnergyAssistance" AS amount,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."AppliedEnergyAssistance" != 0 AND acc."IsBadDebt" = false AND inv."MiscInvoiceType" = 'BalanceAdjustment')

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );

            END IF;
        END;
        END;

        /*
            Query to generate GL Records for Balance Transfer
        */

        BEGIN
        DECLARE
            eventType INTEGER := 1; -- Event Type = 1 = Billing
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_BalTransfer';
            miscChargesBucketType INTEGER := 20;
            bucketTypeCode INTEGER := 4; -- Misc Charges
        BEGIN
            IF EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
            THEN
            
            RAISE NOTICE 'Inserting Balance Transfer Event Type records in "UBGLEntryDatas" table.';
            INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
            VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Balance Transfer Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            /*
                Balance Transfer Misc Charges
            */
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventId", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    uuid_generate_v4() AS "EventId",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, bucketTypeCode, subquery.recordType) AS "GLAccountNumber",
                    subquery.servicecharges AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    bucketTypeCode AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                CASE WHEN invDetail."ServiceTypeCode" IS NOT NULL 
                    THEN invDetail."ServiceTypeCode"
                    ELSE bucketTypeCode 
                END AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS serviceCharges,
                debitRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousCharges" > 0 AND inv."MiscInvoiceType" = 'BalanceTransfer'

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                CASE WHEN invDetail."ServiceTypeCode" IS NOT NULL 
                    THEN invDetail."ServiceTypeCode"
                    ELSE bucketTypeCode 
                END AS serviceTypeCode,
                invDetail."InvoiceMiscellaneousCharges" AS serviceCharges,
                creditRecordType AS recordType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND invDetail."InvoiceMiscellaneousCharges" > 0 AND inv."MiscInvoiceType" = 'BalanceTransfer')

                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = bucketTypeCode AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                );
            END IF;
        END;
        END;

        BEGIN
        DECLARE
            eventType INTEGER := 2; -- Event Type = 2 = Payment
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_Payment';
            miscChargeBucketTypeCode INTEGER := 4; -- Misc Charges
            specialMiscChargeBucket INTEGER := 20;
        BEGIN

            RAISE NOTICE 'Inserting Credits Event Type records in "UBGLEntryDatas" table.';
            INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
            VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Credits Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            /*
                Other Credits Applied
            */
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, subquery.bucketType, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    subquery.bucketType AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                bccd."CreditApplied" * -1  AS amount,
                debitRecordType AS recordType,
                bccd."CalculationChargeTypeCode" AS bucketType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                INNER JOIN "UB"."BillingRunChargewiseCreditDistributions" bccd ON inv."BillingRunKey" = bccd."BillingRunKey" AND invDetail."ServiceKey" = bccd."ServiceKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND acc."IsBadDebt" = false AND inv."BillingRunKey" IS NOT NULL AND bccd."CreditSource" = 'MiscCredits' AND 
                (invDetail."InvoiceMiscellaneousCharges" IS NULL OR invDetail."InvoiceMiscellaneousCharges" >= 0)

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                bccd."CreditApplied" * -1 AS amount,
                creditRecordType AS recordType,
                bccd."CalculationChargeTypeCode" AS bucketType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                INNER JOIN "UB"."BillingRunChargewiseCreditDistributions" bccd ON inv."BillingRunKey" = bccd."BillingRunKey" AND invDetail."ServiceKey" = bccd."ServiceKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND acc."IsBadDebt" = false AND inv."BillingRunKey" IS NOT NULL AND bccd."CreditSource" = 'MiscCredits'
                AND (invDetail."InvoiceMiscellaneousCharges" IS NULL OR invDetail."InvoiceMiscellaneousCharges" >= 0))
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    ("GLDistributionBucketTypeCode" = subquery.bucketType) AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType ) AND
                    "Reference" = reference
                );
                
                
                    /*
                Other Credits Applied (Negative Misc Charge)
            */
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, "UB".GetNegativeMiscChargeServiceTypeCode(subquery.invoiceKey), subquery.accountTypeCode, subquery.bucketType, subquery.oppositeRecordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceDetailKey AS "ReferenceKey",
                    subquery.bucketType AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.invoiceKey AS "InvoiceKey"
                FROM
                (SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey,
                inv."InvoiceKey" AS invoiceKey,
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                bccd."CreditApplied" * -1  AS amount,
                debitRecordType AS recordType,
                creditRecordType AS oppositeRecordType,
                miscChargeBucketTypeCode AS bucketType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                INNER JOIN "UB"."BillingRunChargewiseCreditDistributions" bccd ON inv."BillingRunKey" = bccd."BillingRunKey" AND invDetail."ServiceKey" = bccd."ServiceKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND acc."IsBadDebt" = false AND inv."BillingRunKey" IS NOT NULL AND bccd."CreditSource" = 'MiscCredits' AND 
                (invDetail."InvoiceMiscellaneousCharges" IS NULL OR invDetail."InvoiceMiscellaneousCharges" >= 0)

                UNION

                SELECT invDetail."InvoiceDetailKey" AS invoiceDetailKey,
                inv."InvoiceKey" AS invoiceKey,
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                invDetail."ServiceTypeCode" AS serviceTypeCode,
                bccd."CreditApplied" * -1 AS amount,
                creditRecordType AS recordType,
                debitRecordType AS oppositeRecordType,
                miscChargeBucketTypeCode AS bucketType,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                INNER JOIN "UB"."BillingRunChargewiseCreditDistributions" bccd ON inv."BillingRunKey" = bccd."BillingRunKey" AND invDetail."ServiceKey" = bccd."ServiceKey"
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND acc."IsBadDebt" = false AND inv."BillingRunKey" IS NOT NULL AND bccd."CreditSource" = 'MiscCredits'
                AND (invDetail."InvoiceMiscellaneousCharges" IS NULL OR invDetail."InvoiceMiscellaneousCharges" >= 0))
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceDetailKey AND
                    "EventType" = eventType AND
                    ("GLDistributionBucketTypeCode" = subquery.bucketType) AND
                    ("Amount" = subquery.amount) AND
                    ("GLAccountNumber" = "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, "UB".GetNegativeMiscChargeServiceTypeCode(subquery.invoiceKey), subquery.accountTypeCode, subquery.bucketType, subquery.oppositeRecordType)) AND 
                    ("IsProcessed" = true) AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType ) AND
                    "Reference" = reference
                );
                
                UPDATE "UB"."UBGLEntryDatas"
                SET "EventId" = subqueryDate."EventId"
                FROM ( 
                SELECT inv."BillingRunKey" as "BillingRunKey", uuid_generate_v4() AS "EventId"
                FROM "UB"."UBGLEntryDatas" as gle
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON gle."ReferenceKey" = invDetail."InvoiceDetailKey"
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                WHERE "EventId" IS NULL
                GROUP BY inv."BillingRunKey"
                ) AS subqueryDate
                INNER JOIN "UB"."Invoices" as inv ON subqueryDate."BillingRunKey" = inv."BillingRunKey"
                INNER JOIN "UB"."InvoiceDetails" as invDetail ON inv."InvoiceKey" = invDetail."InvoiceKey"
                WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = invDetail."InvoiceDetailKey";
        	END;
        END;	
                
            /*
                Other Credits For Balance Forwaded Misc Charges
            */

        BEGIN
        DECLARE
            eventType INTEGER := 2; -- Event Type = 2 = Payment
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_Payment';
            miscChargeBucketTypeCode INTEGER := 4; -- Misc Charges
            specialMiscChargeBucket INTEGER := 20;
        BEGIN

            RAISE NOTICE 'Inserting Other Credits Event Type records in "UBGLEntryDatas" table.';
            INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
            VALUES (public.uuid_generate_v4(), null, 3, 1, 'Inserting Other Credits Event Type records in "UBGLEntryDatas" table.', 1, current_timestamp, current_user, current_timestamp, current_user, false);
            
            CREATE TEMP TABLE billingCreditPaymentDistribution ON COMMIT DROP AS
            SELECT * FROM "UB".BillingRunCreditPaymentDistribution();
            /*
                Other Credits For Balance Forwaded Misc Charges
            */
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.paymentDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, subquery.serviceTypeCode, subquery.accountTypeCode, subquery.bucketType, subquery.recordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.paymentHistoryKey AS "ReferenceKey",
                    subquery.bucketType AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
                    acc."AccountTypeCode" AS accountTypeCode,
                    invDetail."ServiceTypeCode" AS serviceTypeCode,
                    pay."PaymentKey" AS paymentKey,
                    pay."PaymentDate" AS paymentDate,
                    debitRecordType AS recordType,
                    bd."calculationchargetypecode" AS bucketType,
                    bd."miscchargecredits" AS amount,
                    pay."Created" AS Created,
                    pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                    FROM billingCreditPaymentDistribution as bd
                    INNER JOIN "UB"."PaymentHistories" as ph ON bd."paymenthistorykey" = ph."PaymentHistoryKey"
                    INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
                    INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                    INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                    INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
                    WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND bd."miscchargecredits" > 0

                UNION
                
                SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
                    acc."AccountTypeCode" AS accountTypeCode,
                    invDetail."ServiceTypeCode" AS serviceTypeCode,
                    pay."PaymentKey" AS paymentKey,
                    pay."PaymentDate" AS paymentDate,
                    creditRecordType AS recordType,
                    bd."calculationchargetypecode" AS bucketType,
                    bd."miscchargecredits" AS amount,
                    pay."Created" AS Created,
                    pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                    FROM billingCreditPaymentDistribution as bd
                    INNER JOIN "UB"."PaymentHistories" as ph ON bd."paymenthistorykey" = ph."PaymentHistoryKey"
                    INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
                    INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                    INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                    INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
                    WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND bd."miscchargecredits" > 0)
                    AS subquery
                    WHERE NOT EXISTS 
                    (
                        SELECT 1 
                        FROM "UB"."UBGLEntryDatas" 
                        WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                        "EventType" = eventType AND
                        "GLDistributionBucketTypeCode" = subquery.bucketType AND
                        ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )
                    );
                    
                
                /*
                    Other Credits For Balance Forwaded Misc Charges (NEGATIVE)
                */
                
                INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.paymentDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, "UB".GetNegativeMiscChargeServiceTypeCodeByAccount(subquery.accountKey), subquery.accountTypeCode, subquery.bucketType, subquery.oppositeRecordType) AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.paymentHistoryKey AS "ReferenceKey",
                    subquery.bucketType AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.InvoiceKey AS "InvoiceKey"
                FROM
                (SELECT ph."PaymentHistoryKey" AS paymentHistoryKey,
                    acc."AccountKey" AS accountKey,
                    acc."AccountTypeCode" AS accountTypeCode,
                    invDetail."ServiceTypeCode" AS serviceTypeCode,
                    pay."PaymentKey" AS paymentKey,
                    pay."PaymentDate" AS paymentDate,
                    debitRecordType AS recordType,
                    creditRecordType AS oppositeRecordType,
                    miscChargeBucketTypeCode AS bucketType,
                    bd."miscchargecredits" AS amount,
                    pay."Created" AS Created,
                    pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                    FROM billingCreditPaymentDistribution as bd
                    INNER JOIN "UB"."PaymentHistories" as ph ON bd."paymenthistorykey" = ph."PaymentHistoryKey"
                    INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
                    INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                    INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                    INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
                    WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND bd."miscchargecredits" > 0

                UNION
                
                SELECT ph."PaymentHistoryKey" AS paymentHistoryKey, 
                    acc."AccountKey" AS accountKey,
                    acc."AccountTypeCode" AS accountTypeCode,
                    invDetail."ServiceTypeCode" AS serviceTypeCode,
                    pay."PaymentKey" AS paymentKey,
                    pay."PaymentDate" AS paymentDate,
                    creditRecordType AS recordType,
                    debitRecordType AS oppositeRecordType,
                    miscChargeBucketTypeCode AS bucketType,
                    bd."miscchargecredits" AS amount,
                    pay."Created" AS Created,
                    pay."LastModified" AS LastModified, inv."InvoiceKey" AS InvoiceKey
                    FROM billingCreditPaymentDistribution as bd
                    INNER JOIN "UB"."PaymentHistories" as ph ON bd."paymenthistorykey" = ph."PaymentHistoryKey"
                    INNER JOIN "UB"."InvoiceDetails" as invDetail ON ph."InvoiceDetailKey" = invDetail."InvoiceDetailKey"
                    INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                    INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                    INNER JOIN "UB"."Payments" pay ON ph."PaymentKey" = pay."PaymentKey"
                    WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND bd."miscchargecredits" > 0)
                    AS subquery
                    WHERE NOT EXISTS 
                    (
                        SELECT 1 
                        FROM "UB"."UBGLEntryDatas" 
                        WHERE "ReferenceKey" = subquery.paymentHistoryKey AND
                        "EventType" = eventType AND
                        "GLDistributionBucketTypeCode" = miscChargeBucketTypeCode AND
                        ("Amount" = subquery.amount) AND
                        ("GLAccountNumber" = "UB".GetAccountNumberByGLDistributionSettingAndRecordType(eventType, "UB".GetNegativeMiscChargeServiceTypeCodeByAccount(subquery.accountKey), subquery.accountTypeCode, subquery.bucketType, subquery.oppositeRecordType)) AND
                        ("RecordType" = subquery.recordType) AND
                        ("IsProcessed" = true)
                    );
                
                
                UPDATE "UB"."UBGLEntryDatas"
                SET "EventId" = subqueryDate."EventId"
                FROM ( 
                SELECT pay."PaymentKey" as "PaymentKey", uuid_generate_v4() AS "EventId"
                FROM "UB"."UBGLEntryDatas" as gle
                INNER JOIN "UB"."PaymentHistories" as ph ON gle."ReferenceKey" = ph."PaymentHistoryKey"
                INNER JOIN "UB"."Payments" as pay ON ph."PaymentKey" = pay."PaymentKey"
                WHERE "EventId" IS NULL
                GROUP BY pay."PaymentKey"
                ) AS subqueryDate
                INNER JOIN "UB"."Payments" as pay ON subqueryDate."PaymentKey" = pay."PaymentKey"
                INNER JOIN "UB"."PaymentHistories" as ph ON pay."PaymentKey" = ph."PaymentKey"
                WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = ph."PaymentHistoryKey";
                
                DROP TABLE IF EXISTS billingCreditPaymentDistribution;
        END;
        END;

        /*
            Query to generate GL Records for Misc Charges Event Type
        */
        BEGIN
        DECLARE
            eventType INTEGER := 7; -- Event Type = 7 = Misc Charges
            debitRecordType INTEGER := 1; -- Record Type = 1 = Debit
            creditRecordType INTEGER := 2; -- Record Type = 2 = Credit
            reference TEXT := 'UB_Billing';
            debitBucketTypeCode INTEGER := 20; -- Cash (Debit)
            arBucketTypeCode INTEGER := 21; -- Accounts Receivables (required only if Accrual Accounting) (Credit/Debit)
            creditBucketTypeCode INTEGER := 22; -- Revenue (Credit)
            specialMiscChargeBucket INTEGER := 20;  --SpecialMiscChargeBucket 
        BEGIN
            IF EXISTS (SELECT * FROM "UB"."RecognizedRevenueSettings" WHERE "IsAccrualAccounting" = true AND "IsInActive" = false )
            THEN
            /*
                Misc Charges Overpayment GL Special Distribution (Positive)
            */
            INSERT INTO "UB"."UBGLEntryDatas" ("UBGLEntryDataKey", "CreatedDateForGL", "EventDate", "EventType", "RecordType", "GLAccountNumber", "Amount", "Reference", "IsProcessed", "ReferenceKey", "GLDistributionBucketTypeCode", "IsInActive", "Created", "LastModified", "InvoiceKey")
                SELECT uuid_generate_v4() AS "UBGLEntryDataKey", 
                    Now() AS "CreatedDateForGL", 
                    subquery.invoiceDate AS "EventDate",
                    eventType AS "EventType",
                    subquery.recordType AS "RecordType",
                    CASE WHEN "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, subquery.bucketType, subquery.serviceTypeCode) IS NOT NULL
                    THEN "UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, subquery.bucketType, subquery.serviceTypeCode)
                    ELSE "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, subquery.bucketType) 
                    END AS "GLAccountNumber",
                    subquery.amount AS "Amount",
                    reference AS "Reference",
                    false AS "IsProcessed",
                    subquery.invoiceKey AS "ReferenceKey",
                    subquery.bucketType AS "GLDistributionBucketTypeCode",
                    false AS "IsInActive",
                    subquery.created AS "Created",
                    subquery.lastmodified AS "LastModified", subquery.invoiceKey AS "InvoiceKey"
                FROM
                (SELECT inv."InvoiceKey" AS invoiceKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                "UB".GetFirstServiceTypeCode(acc."AccountKey") AS serviceTypeCode,
                inv."RemainingCredits"*-1 AS amount,
                debitRecordType AS recordType,
                arBucketTypeCode AS bucketType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey" 
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND inv."RemainingCredits" < 0 AND inv."RemainingCredits" IS NOT NULL AND acc."IsBadDebt" = false AND inv."BillingRunKey" IS NOT NULL

                UNION

                SELECT inv."InvoiceKey" AS invoiceKey, 
                inv."InvoiceDate" AS invoiceDate,
                acc."AccountTypeCode" AS accountTypeCode,
                "UB".GetFirstServiceTypeCode(acc."AccountKey") AS serviceTypeCode,
                inv."RemainingCredits"*-1 AS amount,
                creditRecordType AS recordType,
                creditBucketTypeCode AS bucketType,
                mca."MiscChargeCodeKey" AS miscChargeCodeKey,
                inv."Created" AS Created,
                inv."LastModified" AS LastModified
                FROM "UB"."InvoiceDetails" as invDetail
                INNER JOIN "UB"."Invoices" as inv ON invDetail."InvoiceKey" = inv."InvoiceKey"
                INNER JOIN "UB"."Accounts" acc ON inv."AccountKey" = acc."AccountKey"
                LEFT JOIN "UB"."MiscChargeAccounts" mca ON acc."AccountKey" = mca."AccountKey" 
                WHERE (invoice_key IS NULL OR inv."InvoiceKey" = invoice_key) AND inv."RemainingCredits" < 0 AND inv."RemainingCredits" IS NOT NULL AND acc."IsBadDebt" = false AND inv."BillingRunKey" IS NOT NULL
        )
                AS subquery
                WHERE NOT EXISTS (
                    SELECT 1 
                    FROM "UB"."UBGLEntryDatas" 
                    WHERE "ReferenceKey" = subquery.invoiceKey AND
                    "EventType" = eventType AND
                    "GLDistributionBucketTypeCode" = subquery.bucketType AND
                    ("RecordType" = debitRecordType OR "RecordType" = creditRecordType )) 
                    AND ("UB".GetAccountNumberByMiscChargeAndServiceType(subquery.miscChargeCodeKey, specialMiscChargeBucket, subquery.serviceTypeCode) IS NOT NULL
                    OR "UB".GetAccountNumberByMiscCharge(subquery.miscChargeCodeKey, specialMiscChargeBucket) IS NOT NULL);
                    
                UPDATE "UB"."UBGLEntryDatas"
                SET "EventId" = subqueryDate."EventId"
                FROM ( 
                SELECT inv."BillingRunKey" as "BillingRunKey", uuid_generate_v4() AS "EventId"
                FROM "UB"."UBGLEntryDatas" as gle
                INNER JOIN "UB"."Invoices" as inv ON gle."ReferenceKey" = inv."InvoiceKey"
                WHERE "EventId" IS NULL
                GROUP BY inv."BillingRunKey"
                ) AS subqueryDate
                INNER JOIN "UB"."Invoices" as inv ON subqueryDate."BillingRunKey" = inv."BillingRunKey"
                WHERE "UB"."UBGLEntryDatas"."ReferenceKey" = inv."InvoiceKey";

            END IF;
            
        END;
	END;

	BEGIN
		DELETE FROM "UB"."UBGLEntryDatas"
		WHERE "GLAccountNumber" IS NULL;
	END;

	EXCEPTION
		WHEN others THEN
			-- if there is a exception, roll back the transaction
			ROLLBACK;
			-- Raise a notice with the error message
			RAISE NOTICE 'An error occurred: %', SQLERRM;
			INSERT INTO "FH"."FHGeneralLogs" ("FHGeneralLogKey", "EventKey", "Event", "LogType", "Description", "Status", "Created", "CreatedBy", "LastModified", "LastModifiedBy", "IsInActive")
					VALUES (public.uuid_generate_v4(), null, 4, 3, SQLERRM, 2, current_timestamp, current_user, current_timestamp, current_user, false);

    END;
    

DELIMITER //

DROP PROCEDURE IF EXISTS compactor;

CREATE PROCEDURE compactor()
  BEGIN
    -- Declare variables.
    DECLARE job_id INT DEFAULT 0;

--     DECLARE EXIT HANDLER FOR SQLEXCEPTION
--     BEGIN
--       UPDATE jobs SET `rows` = ROW_COUNT(), `state` = 'failed' WHERE id = job_id;
--       ROLLBACK;
--     END;

    -- Create Compact job
    INSERT INTO jobs (`name`, `state`, created_at, updated_at)
    VALUES ('compactor', 'created', NOW(), NOW());

    SELECT LAST_INSERT_ID() INTO job_id;

    START TRANSACTION;
      -- Save and compact liabilities.
      CREATE TEMPORARY TABLE squashed_liabilities AS
      SELECT code, currency_id, member_id, 'Job', job_id, SUM(debit) AS debit, SUM(credit) AS credit
      FROM liabilities
      GROUP BY code, currency_id, member_id;

      -- Exporting raw liabilities.
      INSERT INTO export_liabilities
      SELECT NULL, code, currency_id, member_id, reference_type, reference_id, debit, credit, created_at, updated_at
      FROM liabilities WHERE reference_type != 'Job';

      -- Squash the liabilities.
      TRUNCATE liabilities;
      INSERT INTO liabilities
      SELECT NULL, code, currency_id, member_id, 'Job', job_id, SUM(debit) AS debit, SUM(credit) AS credit, NOW() AS created_at, NOW() AS updated_at
      FROM squashed_liabilities
      GROUP BY code, currency_id, member_id;

      -- Drop the temporary table.
      DROP TEMPORARY TABLE IF EXISTS squashed_liabilities;

      CREATE TEMPORARY TABLE IF NOT EXISTS tmp_accounts LIKE accounts;
      SELECT ac.id AS id, IFNULL(main.credit - main.debit, 0) AS balance, IFNULL(locked.credit - locked.debit, 0) AS locked
      FROM accounts AS ac
      LEFT JOIN liabilities as main ON ac.member_id = main.member_id && ac.currency_id = main.currency_id && main.code IN (
        SELECT code
        FROM operations_accounts
        WHERE `type` = 'liability' AND kind = 'main'
      )
      LEFT JOIN liabilities as locked ON ac.member_id = locked.member_id && ac.currency_id = locked.currency_id && locked.code IN (
        SELECT code
        FROM operations_accounts
        WHERE `type` = 'liability' AND kind = 'locked'
      );

      -- Update accounts.
      UPDATE accounts
      INNER JOIN tmp_accounts ON tmp_accounts.id = accounts.id
      SET
        accounts.balance = tmp_accounts.balance,
        accounts.locked = tmp_accounts.locked,
        accounts.updated_at = NOW();

--       ROLLBACK;
--       INSERT liabilities (code)
--       VALUES();

      -- Set job state and rows affected.
  --     IF (ROW_COUNT() != 0 AND job_id != 0) THEN
      UPDATE jobs SET `rows` = ROW_COUNT(), `state` = 'succeed' WHERE id = job_id;
  --     ELSE
  --       UPDATE jobs SET `rows` = ROW_COUNT(), `state` = 'failed' WHERE id = job_id;
  --     END IF;

      DROP TEMPORARY TABLE IF EXISTS tmp_accounts;
    COMMIT;
  END

-- DELIMITER ;

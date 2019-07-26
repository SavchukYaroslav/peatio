INSERT INTO `liabilities` (`code`, `currency_id`, `member_id`, `reference_type`, `reference_id`, `credit`, `created_at`, `updated_at`) VALUES (202, 'btc', 170, 'Deposit', 252, 1000000000.0, '2019-07-26 19:08:14', '2019-07-26 19:08:14');
INSERT INTO `liabilities` (`code`, `currency_id`, `member_id`, `reference_type`, `reference_id`, `credit`, `created_at`, `updated_at`) VALUES (202, 'btc', 170, 'Deposit', 252, 1000000000.0, '2019-07-26 19:08:14', '2019-07-26 19:08:14');
INSERT INTO `liabilities` (`code`, `currency_id`, `member_id`, `reference_type`, `reference_id`, `credit`, `created_at`, `updated_at`) VALUES (202, 'btc', 170, 'Deposit', 252, 1000000000.0, '2019-07-26 19:08:14', '2019-07-26 19:08:14');

-- SET autocommit=0;

START TRANSACTION;
  DELETE FROM liabilities;
  INSERT INTO `liabilities` (`code`, `currency_id`, `member_id`, `reference_type`, `reference_id`, `credit`, `created_at`, `updated_at`) VALUES (202, 'btc', 170, 'Deposit', 252, 1000000000.0, '2019-07-26 19:08:14', '2019-07-26 19:08:14');
--   INSERT INTO liabilities (`code`, `currency_id`, `member_id`, `reference_type`, `reference_id`, `created_at`, `updated_at`)
--   VALUES(229, 'usd', 1, 'Job', 0, 1,2, NOW(), NOW());
ROLLBACK;
-- COMMIT;

class AddAccountingRecalculationProcedure < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          DROP PROCEDURE IF EXISTS recalculate_accounts;
        SQL

        execute <<-SQL
          CREATE PROCEDURE recalculate_accounts()
          BEGIN

           DECLARE v_finished INTEGER DEFAULT 0;
          
           DECLARE id bigINt DEFAULT 0;
           DECLARE currency_id varchar(10) DEFAULT "";
           DECLARE member_id bigINt DEFAULT 0;
          
           DEClARE account_cursor CURSOR FOR 
           SELECT accounts.id, accounts.currency_id, accounts.member_id
           FROM accounts;
           
           DECLARE CONTINUE HANDLER
                  FOR NOT FOUND SET v_finished = 1;
           
           OPEN account_cursor;
           
           accounts_loop: LOOP
           
           FETCH account_cursor INTO id, currency_id, member_id;
           
           IF v_finished = 1 THEN
              LEAVE accounts_loop;
           END IF;
           
           UPDATE accounts SET
              accounts.balance =
              (
                  SELECT IFNULL(SUM(credit) - SUM(debit), 0) FROM liabilities 
                  WHERE liabilities.member_id = member_id AND liabilities.currency_id = currency_id AND liabilities.code IN (201,202)
              ),
              accounts.locked =
              (
                  SELECT IFNULL(SUM(credit) - SUM(debit), 0) FROM liabilities 
                  WHERE liabilities.member_id = member_id AND liabilities.currency_id = currency_id AND liabilities.code IN (211,212)
              ),
              updated_at = NOW()
              WHERE accounts.id = id;
           
           END LOOP accounts_loop;
           
           CLOSE account_cursor;
          END
        SQL
      end

      dir.down do
        execute <<-SQL
          DROP PROCEDURE IF EXISTS recalculate_accounts;
        SQL
      end
    end
  end
end

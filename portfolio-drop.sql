--
-- Part of the Red, White, and Blue example application
-- from EECS 339 at Northwestern University
--
--
-- This code drops the student *part* of the Red, White, 
-- and Blue data schema.  

delete from pf_users;
delete from portfolios;
delete from shares;
delete from newStockData;
delete from predictedStockData;

commit;

drop table shares;
drop table newStockData;
drop table predictedStockData;
drop table portfolios;
drop table pf_users;

quit;

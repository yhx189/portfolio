--
-- Part of the Red, White, and Blue example application
-- from EECS 339 at Northwestern University
--
--
-- This code drops the student *part* of the Red, White, 
-- and Blue data schema.  

delete from pf_permissions;
delete from pf_users;
delete from pf_actions;
delete from pf_opinions;
delete from pf_cs_ind_to_geo;

commit;

drop table pf_cs_ind_to_geo;
drop table pf_opinions;
drop table pf_permissions;
drop table pf_actions;
drop table pf_users;




quit;

--
-- Part of the Red, White, and Blue example application
-- from EECS 339 at Northwestern University
--
--
-- This contains *part* of the Red, White, and Blue data
-- schema.  It does not include the representation of the 
-- FEC data and the Geolocation data,  which is available 
-- separately in ~pdinda/339/HANDOUT/rwb/fec.  
-- These shared tables should be 
-- access using cs339.tablename, that is, the student groups
-- share the FEC and geolocation data
--
-- Primarily, what's contained here is the user model
-- permissions, etc.  These should be accessed as tablename,
-- that is, each student group's tables are a separate
--
--


--
-- RWB users.  Self explanatory
--
create table pf_users (
--
-- Each user must have a name and a unique one at that.
--
  name  varchar(64) not null primary key,
--
-- Each user must have a password of at least eight characters
--
-- Note - this keeps the password in clear text in the database
-- which is a bad practice and only useful for illustration
--
-- The right way to do this is to store an encrypted password
-- in the database
--
  password VARCHAR(64) NOT NULL,
    constraint long_passwd_pf CHECK (password LIKE '________%'),
--
-- Each user must have an email address and it must be unique
-- the constraint checks to see that there is an "@" in the name
--
  email    varchar(256) not null UNIQUE
    constraint email_ok_pf CHECK (email LIKE '%@%')
);

create table portfolios(
  id varchar(64) not null,
  username varchar(64) not null,
  cash number default 0,
  primary key(id,username),
  foreign key (username) references pf_users(name) on delete cascade
);

create table shares(
    symbol varchar(16) not null,
    portfolioID varchar(64) not null,
    username varchar(64) not null,
    amnt number not null,
    primary key(symbol,portfolioID,username),
    foreign key(portfolioID, username) references portfolios(id,username) on delete cascade,
    foreign key(username) references pf_users(name) on delete cascade
);

create table newStockData(
    symbol varchar(16) not null,
    timestamp number not null,
    open number not null,
    high number not null,
    low number not null,
    close number not null,
    volume number not null,
    primary key(symbol,timestamp)
);

create table predictedStockData(
    symbol varchar(16) not null,
    timestamp number not null,
    open number not null,
    high number not null,
    low number not null,
    close number not null,
    volume number not null,
    primary key(symbol,timestamp)
);

create table market(
    timestamp number not null,
    close number not null,
    primary key(timestamp)
);

quit;

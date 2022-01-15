-- MySQL dump 10.13  Distrib 8.0.+, for ubuntu Linux
--
-- Host: 127.0.0.1    Database: icey_DB
-- -----------------------------------------------------------------------------------------------------
-- Server version 8.0.+

--
-- Create user 'Olge' and grant previleges -------------------------------------------------------------
--
CREATE USER 'EC2Oleg'@'%' IDENTIFIED BY '<some-password>';
GRANT  ALL ON icey_DB.* TO 'EC2Oleg'@'%';

--
-- Create User and enable IAM authentication -----------------------------------------------------------
--
CREATE USER 'legofun'@'%' IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';
GRANT  ALL ON icey_DB.* TO 'legofun'@'%';

FLUSH PRIVILEGES;
-- -----------------------------------------------------------------------------------------------------

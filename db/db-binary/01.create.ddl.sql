-- MySQL dump 10.13  Distrib 8.0.+, for ubuntu Linux
--
-- Host: 127.0.0.1    Database: icey_DB
-- -----------------------------------------------------------------------------------------------------
-- Server version 8.0.+

--
-- Create Database, Then Connect to it -----------------------------------------------------------------
--
CREATE DATABASE IF NOT EXISTS `icey_DB` default charset utf8 COLLATE utf8_general_ci;
USE `icey_DB`;

--
-- Table structure for table `ORDER` -------------------------------------------------------------------
--
DROP TABLE IF EXISTS `ORDER`;

CREATE TABLE `ORDER` (
  ID                    INT                       NOT NULL AUTO_INCREMENT,
  ADDRESS               VARCHAR(100)              NOT NULL,
  NAME                  VARCHAR(50)               NOT NULL,
  AMOUNT                DECIMAL(8,2)              NOT NULL,
  CREATED_AT            DATETIME                  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED_AT            DATETIME                  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY(`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

--
-- Table structure for table `NEXT` --------------------------------------------------------------------
--
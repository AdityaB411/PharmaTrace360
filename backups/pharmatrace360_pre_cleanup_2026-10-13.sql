-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: localhost    Database: pharmatrace360
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `audit_logs`
--

DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_logs` (
  `log_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned DEFAULT NULL,
  `action` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `table_name` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `record_id` int unsigned DEFAULT NULL,
  `details` text COLLATE utf8mb4_unicode_ci,
  `logged_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `fk_audit_user` (`user_id`),
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_logs`
--

LOCK TABLES `audit_logs` WRITE;
/*!40000 ALTER TABLE `audit_logs` DISABLE KEYS */;
INSERT INTO `audit_logs` VALUES (1,1,'CREATE_BATCH','Production_Batches',1,'Batch BT-2026-001 created for Actiflu 500mg Tablet.','2026-01-15 10:00:00'),(2,2,'RECORD_QA_TEST','Quality_Test_Reports',1,'QA test recorded for BT-2026-001 - result: Pass.','2026-01-20 14:30:00'),(3,1,'APPROVE_BATCH','Production_Batches',1,'Batch BT-2026-001 status changed to Approved.','2026-01-21 09:00:00'),(4,1,'ISSUE_QR','QR_Codes',1,'5 QR codes issued for batch BT-2026-001.','2026-01-21 09:05:00'),(5,3,'CREATE_BATCH','Production_Batches',2,'Batch BT-2026-002 created for Nodimox 500mg Tablet DT.','2026-02-10 10:00:00'),(6,4,'RECORD_QA_TEST','Quality_Test_Reports',10,'QA test recorded for BT-2026-010 - result: Fail.','2026-07-20 11:00:00'),(7,1,'REJECT_BATCH','Production_Batches',10,'Batch BT-2026-010 status changed to Rejected.','2026-07-21 08:00:00'),(8,1,'RECALL_BATCH','Production_Batches',12,'Batch BT-2026-012 recalled - impurity found in stability test.','2026-09-15 16:00:00'),(9,1,'LOGIN_FAILED','Users',1,'Failed login attempt.','2026-10-08 00:26:34'),(10,1,'LOGIN_FAILED','Users',1,'Failed login attempt.','2026-10-08 00:26:40'),(11,1,'LOGIN','Users',1,'User logged in.','2026-10-08 00:27:24'),(12,1,'REVIEW_SUSPICIOUS_CODE','Scan_Log',NULL,'Suspicious code PT360-20515ECBE7F2 review status changed to Reviewed.','2026-10-08 00:27:57'),(13,1,'REVIEW_SUSPICIOUS_CODE','Scan_Log',NULL,'Suspicious code PT360-20515ECBE7F2 review status changed to Reviewed.','2026-10-08 00:31:01'),(14,1,'REVIEW_SUSPICIOUS_CODE','Scan_Log',NULL,'Suspicious code PT360-20515ECBE7F2 review status changed to Reviewed.','2026-10-08 00:31:05'),(15,1,'REVIEW_SUSPICIOUS_CODE','Scan_Log',NULL,'Suspicious code PT360-20515ECBE7F2 review status changed to Reviewed.','2026-10-08 00:31:18'),(16,1,'LOGOUT','Users',1,'User logged out.','2026-10-08 00:40:00'),(17,2,'LOGIN','Users',2,'User logged in.','2026-10-08 00:40:02'),(18,2,'DELIVERY_RECORDED','Material_Deliveries',21,'Delivery recorded: 100.000 kg received under certificate TEST-COA-001.','2026-10-08 13:35:32'),(19,2,'BATCH_CREATED','Production_Batches',13,'Batch TEST-BATCH-001 created with quantity 500.','2026-10-08 13:35:32'),(20,2,'MATERIAL_LINKED','Batch_Materials',13,'Material from delivery_id 21 linked to batch_id 13 (25.000 kg used).','2026-10-08 13:35:32'),(21,2,'INSERT_QA_TEST','Quality_Test_Reports',14,'QA test for batch_id 13 - result: Pass.','2026-10-08 13:35:32'),(22,2,'STATUS_APPROVED','Production_Batches',13,'Batch TEST-BATCH-001 status changed from Pending to Approved.','2026-10-08 13:35:32'),(23,2,'BATCH_CREATED','Production_Batches',14,'Batch TEST-BATCH-OVERUSE created with quantity 200.','2026-10-08 13:35:32'),(24,2,'BATCH_CREATED','Production_Batches',15,'Batch TEST-BATCH-NOMAT created with quantity 300.','2026-10-08 13:35:32'),(25,2,'INSERT_QA_TEST','Quality_Test_Reports',15,'QA test for batch_id 15 - result: Pass.','2026-10-08 13:35:32'),(26,2,'DELIVERY_RECORDED','Material_Deliveries',22,'Delivery recorded: 50.000 kg received under certificate TEST-COA-TODAY.','2026-10-08 13:35:32'),(27,2,'BATCH_CREATED','Production_Batches',16,'Batch TEST-BATCH-PAST created with quantity 100.','2026-10-08 13:35:32'),(28,2,'PASSWORD_CHANGED','Users',2,'Password changed successfully.','2026-10-08 13:35:32'),(29,2,'LOGIN','Users',2,'User logged in.','2026-10-08 17:53:10'),(30,2,'DELIVERY_RECORDED','Material_Deliveries',23,'Delivery recorded: 100.000 kg received under certificate TEST-LIVE-001.','2026-10-08 17:54:24'),(31,2,'BATCH_CREATED','Production_Batches',17,'Batch TEST-LIVE-001 created with quantity 100.','2026-10-08 17:57:07'),(32,2,'MATERIAL_LINKED','Batch_Materials',17,'Material from delivery_id 23 linked to batch_id 17 (30.000 kg used).','2026-10-08 17:58:05'),(33,2,'INSERT_QA_TEST','Quality_Test_Reports',16,'QA test for batch_id 17 - result: Pass.','2026-10-08 17:58:56'),(34,2,'STATUS_APPROVED','Production_Batches',17,'Batch TEST-LIVE-001 status changed from Pending to Approved.','2026-10-08 17:59:17'),(35,2,'LOGOUT','Users',2,'User logged out.','2026-10-08 18:10:47'),(36,1,'LOGIN','Users',1,'User logged in.','2026-10-08 18:10:54'),(37,1,'INSERT_RECALL','Product_Recalls',2,'Recall created for batch_id 17. Reason: DEMO REASONS','2026-10-08 18:11:31'),(38,1,'STATUS_RECALLED','Production_Batches',17,'Batch TEST-LIVE-001 status changed from Approved to Recalled.','2026-10-08 18:11:31');
/*!40000 ALTER TABLE `audit_logs` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_audit_logs_bu` BEFORE UPDATE ON `audit_logs` FOR EACH ROW BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Audit log is append-only.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_audit_logs_bd` BEFORE DELETE ON `audit_logs` FOR EACH ROW BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Audit log is append-only.';
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `batch_materials`
--

DROP TABLE IF EXISTS `batch_materials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `batch_materials` (
  `batch_id` int unsigned NOT NULL,
  `delivery_id` int unsigned NOT NULL,
  `quantity_used_kg` decimal(10,3) NOT NULL,
  PRIMARY KEY (`batch_id`,`delivery_id`),
  KEY `fk_bm_delivery` (`delivery_id`),
  CONSTRAINT `fk_bm_batch` FOREIGN KEY (`batch_id`) REFERENCES `production_batches` (`batch_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_bm_delivery` FOREIGN KEY (`delivery_id`) REFERENCES `material_deliveries` (`delivery_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_bm_qty` CHECK ((`quantity_used_kg` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `batch_materials`
--

LOCK TABLES `batch_materials` WRITE;
/*!40000 ALTER TABLE `batch_materials` DISABLE KEYS */;
INSERT INTO `batch_materials` VALUES (1,1,18.000),(1,16,41.000),(2,2,21.000),(2,18,33.500),(3,3,24.000),(4,4,27.000),(4,17,29.000),(5,5,30.000),(6,8,39.000),(6,19,38.000),(7,6,33.000),(8,7,36.000),(8,20,23.000),(9,9,42.000),(10,10,45.000),(11,11,48.000),(12,13,54.000),(13,21,25.000),(17,23,30.000);
/*!40000 ALTER TABLE `batch_materials` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_batch_materials_bi` BEFORE INSERT ON `batch_materials` FOR EACH ROW BEGIN
    DECLARE v_delivery_mfr  INT UNSIGNED;
    DECLARE v_factory_mfr   INT UNSIGNED;
    DECLARE v_delivery_ing  INT UNSIGNED;
    DECLARE v_medicine_id   INT UNSIGNED;
    DECLARE v_ing_match     INT DEFAULT 0;
    DECLARE v_batch_status  VARCHAR(10);
    DECLARE v_mfg_date      DATE;
    DECLARE v_deliv_date    DATE;
    DECLARE v_deliv_qty     DECIMAL(10,3);
    DECLARE v_total_used_kg DECIMAL(10,3) DEFAULT 0.000;

    
    SELECT manufacturer_id, ingredient_id, quantity_kg, received_date
    INTO v_delivery_mfr, v_delivery_ing, v_deliv_qty, v_deliv_date
    FROM Material_Deliveries
    WHERE delivery_id = NEW.delivery_id;

    
    SELECT f.manufacturer_id, pb.medicine_id, pb.status, pb.manufacture_date
    INTO v_factory_mfr, v_medicine_id, v_batch_status, v_mfg_date
    FROM Production_Batches pb
    JOIN Factories f ON f.factory_id = pb.factory_id
    WHERE pb.batch_id = NEW.batch_id;

    
    IF v_batch_status != 'Pending' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Materials can only be added to Pending batches.';
    END IF;

    
    IF v_delivery_mfr != v_factory_mfr THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery manufacturer does not own the batch factory. A batch may only use deliveries received by its own manufacturer.';
    END IF;

    
    SELECT COUNT(*) INTO v_ing_match
    FROM Drug_Formulations
    WHERE medicine_id   = v_medicine_id
      AND ingredient_id = v_delivery_ing;

    IF v_ing_match = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery ingredient is not part of the batch medicine formulation.';
    END IF;

    
    IF v_deliv_date > v_mfg_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery received date cannot be after the batch manufacture date.';
    END IF;

    
    SELECT COALESCE(SUM(quantity_used_kg), 0) INTO v_total_used_kg
    FROM Batch_Materials
    WHERE delivery_id = NEW.delivery_id;

    IF (v_total_used_kg + NEW.quantity_used_kg) > v_deliv_qty THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Total quantity used exceeds the delivered quantity.';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_batch_materials_ai` AFTER INSERT ON `batch_materials` FOR EACH ROW BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (
        @app_user_id,
        'MATERIAL_LINKED',
        'Batch_Materials',
        NEW.batch_id,
        CONCAT('Material from delivery_id ', NEW.delivery_id, ' linked to batch_id ',
               NEW.batch_id, ' (', NEW.quantity_used_kg, ' kg used).')
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_batch_materials_bu` BEFORE UPDATE ON `batch_materials` FOR EACH ROW BEGIN
    DECLARE v_status VARCHAR(10);
    SELECT status INTO v_status
    FROM Production_Batches
    WHERE batch_id = OLD.batch_id;

    IF v_status != 'Pending' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Materials can only be modified for Pending batches.';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_batch_materials_bd` BEFORE DELETE ON `batch_materials` FOR EACH ROW BEGIN
    DECLARE v_status VARCHAR(10);
    SELECT status INTO v_status
    FROM Production_Batches
    WHERE batch_id = OLD.batch_id;

    IF v_status != 'Pending' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Materials can only be deleted from Pending batches.';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `drug_formulations`
--

DROP TABLE IF EXISTS `drug_formulations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `drug_formulations` (
  `medicine_id` int unsigned NOT NULL,
  `ingredient_id` int unsigned NOT NULL,
  `strength` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`medicine_id`,`ingredient_id`),
  KEY `fk_df_ingredient` (`ingredient_id`),
  CONSTRAINT `fk_df_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_df_medicine` FOREIGN KEY (`medicine_id`) REFERENCES `medicines` (`medicine_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `drug_formulations`
--

LOCK TABLES `drug_formulations` WRITE;
/*!40000 ALTER TABLE `drug_formulations` DISABLE KEYS */;
INSERT INTO `drug_formulations` VALUES (1,1,'500mg',1),(2,2,'500mg',1),(3,3,'500mg',1),(4,4,'500mg',1),(5,5,'10mg',1),(6,6,'10mg',1),(7,7,'10mg',1),(8,8,'400mg',1),(9,9,'40mg',1),(10,10,'5mg',1),(11,11,'400mg',1),(12,12,'100mg',1),(13,13,'500mg',1),(14,14,'75mg',1),(15,15,'5mg',1);
/*!40000 ALTER TABLE `drug_formulations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `factories`
--

DROP TABLE IF EXISTS `factories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `factories` (
  `factory_id` int unsigned NOT NULL AUTO_INCREMENT,
  `manufacturer_id` int unsigned NOT NULL,
  `factory_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `location` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `license_no` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`factory_id`),
  KEY `fk_factory_mfr` (`manufacturer_id`),
  CONSTRAINT `fk_factory_mfr` FOREIGN KEY (`manufacturer_id`) REFERENCES `manufacturers` (`manufacturer_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `factories`
--

LOCK TABLES `factories` WRITE;
/*!40000 ALTER TABLE `factories` DISABLE KEYS */;
INSERT INTO `factories` VALUES (1,1,'Cipla Plant 1','Mumbai','DEMO-FAC-001-1'),(2,1,'Cipla Plant 2','Hyderabad','DEMO-FAC-001-2'),(3,2,'Alkem Plant 1','Ahmedabad','DEMO-FAC-002-1'),(4,2,'Alkem Plant 2','Bangalore','DEMO-FAC-002-2'),(5,3,'Alembic Plant 1','Pune','DEMO-FAC-003-1'),(6,3,'Alembic Plant 2','Baddi','DEMO-FAC-003-2'),(7,4,'Sun Plant 1','Sikkim','DEMO-FAC-004-1'),(8,4,'Sun Plant 2','Goa','DEMO-FAC-004-2'),(9,5,'Zydus Plant 1','Chennai','DEMO-FAC-005-1'),(10,5,'Zydus Plant 2','Indore','DEMO-FAC-005-2'),(11,6,'Abbott Plant 1','Dehradun','DEMO-FAC-006-1'),(12,6,'Abbott Plant 2','Chandigarh','DEMO-FAC-006-2'),(13,7,'Lupin Plant 1','Vadodara','DEMO-FAC-007-1'),(14,7,'Lupin Plant 2','Jaipur','DEMO-FAC-007-2'),(15,8,'Mankind Plant 1','Aurangabad','DEMO-FAC-008-1'),(16,8,'Mankind Plant 2','Nashik','DEMO-FAC-008-2'),(17,9,'USV Plant 1','Pantnagar','DEMO-FAC-009-1'),(18,9,'USV Plant 2','Haridwar','DEMO-FAC-009-2');
/*!40000 ALTER TABLE `factories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ingredients`
--

DROP TABLE IF EXISTS `ingredients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ingredients` (
  `ingredient_id` int unsigned NOT NULL AUTO_INCREMENT,
  `ingredient_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cas_number` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`ingredient_id`),
  UNIQUE KEY `uq_ingredient_name` (`ingredient_name`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ingredients`
--

LOCK TABLES `ingredients` WRITE;
/*!40000 ALTER TABLE `ingredients` DISABLE KEYS */;
INSERT INTO `ingredients` VALUES (1,'Paracetamol',NULL),(2,'Amoxycillin',NULL),(3,'Azithromycin',NULL),(4,'Metformin',NULL),(5,'Atorvastatin',NULL),(6,'Omeprazole',NULL),(7,'Cetirizine',NULL),(8,'Ibuprofen',NULL),(9,'Pantoprazole',NULL),(10,'Amlodipine',NULL),(11,'Metronidazole',NULL),(12,'Doxycycline',NULL),(13,'Ciprofloxacin',NULL),(14,'Aspirin',NULL),(15,'Levocetirizine',NULL);
/*!40000 ALTER TABLE `ingredients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `manufacturers`
--

DROP TABLE IF EXISTS `manufacturers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `manufacturers` (
  `manufacturer_id` int unsigned NOT NULL AUTO_INCREMENT,
  `company_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `registration_no` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_email` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`manufacturer_id`),
  UNIQUE KEY `uq_mfr_reg` (`registration_no`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `manufacturers`
--

LOCK TABLES `manufacturers` WRITE;
/*!40000 ALTER TABLE `manufacturers` DISABLE KEYS */;
INSERT INTO `manufacturers` VALUES (1,'Cipla Ltd','DEMO-MFR-001',NULL,NULL,NULL),(2,'Alkem Laboratories Ltd','DEMO-MFR-002',NULL,NULL,NULL),(3,'Alembic Pharmaceuticals Ltd','DEMO-MFR-003',NULL,NULL,NULL),(4,'Sun Pharmaceutical Industries Ltd','DEMO-MFR-004',NULL,NULL,NULL),(5,'Zydus Cadila','DEMO-MFR-005',NULL,NULL,NULL),(6,'Abbott','DEMO-MFR-006',NULL,NULL,NULL),(7,'Lupin Ltd','DEMO-MFR-007',NULL,NULL,NULL),(8,'Mankind Pharma Ltd','DEMO-MFR-008',NULL,NULL,NULL),(9,'USV Ltd','DEMO-MFR-009',NULL,NULL,NULL);
/*!40000 ALTER TABLE `manufacturers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `material_deliveries`
--

DROP TABLE IF EXISTS `material_deliveries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `material_deliveries` (
  `delivery_id` int unsigned NOT NULL AUTO_INCREMENT,
  `supplier_id` int unsigned NOT NULL,
  `ingredient_id` int unsigned NOT NULL,
  `manufacturer_id` int unsigned NOT NULL,
  `quantity_kg` decimal(10,3) NOT NULL,
  `received_date` date NOT NULL,
  `certificate_number` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`delivery_id`),
  KEY `fk_delivery_supplier` (`supplier_id`),
  KEY `fk_delivery_ingredient` (`ingredient_id`),
  KEY `fk_delivery_mfr` (`manufacturer_id`),
  CONSTRAINT `fk_delivery_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_delivery_mfr` FOREIGN KEY (`manufacturer_id`) REFERENCES `manufacturers` (`manufacturer_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_delivery_supplier` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`supplier_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_delivery_qty` CHECK ((`quantity_kg` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `material_deliveries`
--

LOCK TABLES `material_deliveries` WRITE;
/*!40000 ALTER TABLE `material_deliveries` DISABLE KEYS */;
INSERT INTO `material_deliveries` VALUES (1,1,1,1,60.000,'2025-12-05','COA-2024-0001'),(2,2,2,2,70.000,'2026-01-05','COA-2024-0002'),(3,3,3,3,80.000,'2026-01-30','COA-2024-0003'),(4,4,4,4,90.000,'2026-02-15','COA-2024-0004'),(5,5,5,5,100.000,'2026-04-15','COA-2024-0005'),(6,1,6,2,110.000,'2024-01-25','COA-2024-0006'),(7,2,7,1,120.000,'2026-07-01','COA-2024-0007'),(8,3,8,6,130.000,'2026-05-02','COA-2024-0008'),(9,4,9,7,140.000,'2026-08-01','COA-2024-0009'),(10,5,10,8,150.000,'2026-06-10','COA-2024-0010'),(11,1,11,2,160.000,'2026-07-20','COA-2024-0011'),(12,2,12,5,170.000,'2026-03-10','COA-2024-0012'),(13,3,13,1,180.000,'2026-02-01','COA-2024-0013'),(14,4,14,9,190.000,'2026-04-10','COA-2024-0014'),(15,5,15,7,200.000,'2026-05-10','COA-2024-0015'),(16,1,1,1,120.000,'2025-12-25','COA-2024-0016'),(17,2,4,4,80.000,'2026-03-10','COA-2024-0017'),(18,3,2,2,95.000,'2026-01-20','COA-2024-0018'),(19,4,8,6,110.000,'2026-05-20','COA-2024-0019'),(20,5,7,1,60.000,'2026-07-20','COA-2024-0020'),(21,1,1,1,100.000,'2026-10-08','TEST-COA-001'),(22,1,1,1,50.000,'2026-10-08','TEST-COA-TODAY'),(23,2,1,1,100.000,'2026-10-08','TEST-LIVE-001');
/*!40000 ALTER TABLE `material_deliveries` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_deliveries_ai` AFTER INSERT ON `material_deliveries` FOR EACH ROW BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (
        @app_user_id,
        'DELIVERY_RECORDED',
        'Material_Deliveries',
        NEW.delivery_id,
        CONCAT('Delivery recorded: ', NEW.quantity_kg, ' kg received under certificate ',
               COALESCE(NEW.certificate_number, 'N/A'), '.')
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `medicine_info`
--

DROP TABLE IF EXISTS `medicine_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `medicine_info` (
  `info_id` int unsigned NOT NULL AUTO_INCREMENT,
  `medicine_id` int unsigned NOT NULL,
  `info_type` enum('use','side_effect','avoid_with') COLLATE utf8mb4_unicode_ci NOT NULL,
  `info_text` text COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`info_id`),
  KEY `fk_info_medicine` (`medicine_id`),
  CONSTRAINT `fk_info_medicine` FOREIGN KEY (`medicine_id`) REFERENCES `medicines` (`medicine_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=166 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `medicine_info`
--

LOCK TABLES `medicine_info` WRITE;
/*!40000 ALTER TABLE `medicine_info` DISABLE KEYS */;
INSERT INTO `medicine_info` VALUES (1,1,'use','Pain relief'),(2,1,'use','Treatment of Fever'),(3,1,'side_effect','Stomach pain'),(4,1,'side_effect','Nausea'),(5,1,'side_effect','Vomiting'),(6,1,'avoid_with','Nimesulide'),(7,1,'avoid_with','Oxyphenbutazone'),(8,1,'avoid_with','Metamizole'),(9,2,'use','Treatment of Bacterial infections'),(10,2,'side_effect','Rash'),(11,2,'side_effect','Vomiting'),(12,2,'side_effect','Allergic reaction'),(13,2,'side_effect','Nausea'),(14,2,'side_effect','Diarrhea'),(15,2,'avoid_with','Warfarin'),(16,2,'avoid_with','Methotrexate'),(17,2,'avoid_with','Allopurinol'),(18,2,'avoid_with','Probenecid'),(19,3,'use','Treatment of Bacterial infections'),(20,3,'side_effect','Vomiting'),(21,3,'side_effect','Nausea'),(22,3,'side_effect','Abdominal pain'),(23,3,'side_effect','Diarrhea'),(24,3,'avoid_with','Astemizole'),(25,3,'avoid_with','Ebastine'),(26,3,'avoid_with','Mizolastine'),(27,3,'avoid_with','Terfenadine'),(28,4,'use','Treatment of Type 2 diabetes mellitus'),(29,4,'side_effect','Diarrhea'),(30,4,'side_effect','Nausea'),(31,4,'side_effect','Vomiting'),(32,4,'side_effect','Flatulence'),(33,4,'avoid_with','Ketotifen'),(34,4,'avoid_with','Amiloride'),(35,4,'avoid_with','Beclometasone'),(36,4,'avoid_with','Betamethasone'),(37,5,'use','High cholesterol'),(38,5,'use','Prevention of Heart attack'),(39,5,'side_effect','Dyspepsia'),(40,5,'side_effect','Abdominal pain'),(41,5,'side_effect','Indigestion'),(42,5,'side_effect','Diarrhea'),(43,5,'side_effect','Joint pain'),(44,5,'side_effect','Nasopharyngitis (inflammation of the throat and nasal passages)'),(45,5,'side_effect','Nausea'),(46,5,'side_effect','Pain in extremities'),(47,5,'side_effect','Urinary tract infection'),(48,5,'side_effect','Abnormal liver function tests'),(49,5,'avoid_with','Clarithromycin'),(50,5,'avoid_with','Erythromycin'),(51,5,'avoid_with','Gemfibrozil'),(52,5,'avoid_with','Rifampicin'),(53,5,'avoid_with','Digoxin'),(54,6,'use','Treatment of Heartburn'),(55,6,'use','Treatment of Gastroesophageal reflux disease (Acid reflux)'),(56,6,'use','Treatment of Peptic ulcer disease'),(57,6,'side_effect','Diarrhea'),(58,6,'side_effect','Flatulence'),(59,6,'side_effect','Headache'),(60,6,'side_effect','Nausea'),(61,6,'side_effect','Stomach pain'),(62,6,'side_effect','Vomiting'),(63,6,'avoid_with','Atazanavir'),(64,6,'avoid_with','Cilostazol'),(65,6,'avoid_with','Indinavir'),(66,6,'avoid_with','Nelfinavir'),(67,7,'use','Treatment of Allergic conditions'),(68,7,'side_effect','Sleepiness'),(69,7,'side_effect','Dizziness'),(70,7,'avoid_with','Aprepitant'),(71,7,'avoid_with','Fosaprepitant'),(72,7,'avoid_with','Zafirlukast'),(73,7,'avoid_with','Alprazolam'),(74,8,'use','Pain relief'),(75,8,'use','Treatment of Fever'),(76,8,'side_effect','Vomiting'),(77,8,'side_effect','Nausea'),(78,8,'side_effect','Dizziness'),(79,8,'side_effect','Abdominal pain'),(80,8,'side_effect','Constipation'),(81,8,'side_effect','Flatulence'),(82,8,'side_effect','Diarrhea'),(83,8,'side_effect','Dyspepsia'),(84,8,'side_effect','Headache'),(85,8,'side_effect','Fatigue'),(86,8,'side_effect','Rash'),(87,8,'avoid_with','Nimesulide'),(88,8,'avoid_with','Oxyphenbutazone'),(89,8,'avoid_with','Metamizole'),(90,9,'use','Treatment of Heartburn'),(91,9,'use','Treatment of Gastroesophageal reflux disease (Acid reflux)'),(92,9,'use','Treatment of Peptic ulcer disease'),(93,9,'side_effect','Diarrhea'),(94,9,'side_effect','Flatulence'),(95,9,'side_effect','Headache'),(96,9,'side_effect','Nausea'),(97,9,'side_effect','Stomach pain'),(98,9,'side_effect','Vomiting'),(99,9,'side_effect','Dizziness'),(100,9,'avoid_with','Atazanavir'),(101,9,'avoid_with','Cilostazol'),(102,9,'avoid_with','Indinavir'),(103,9,'avoid_with','Nelfinavir'),(104,10,'use','Treatment of Hypertension (high blood pressure)'),(105,10,'use','Prevention of Angina (heart-related chest pain)'),(106,10,'side_effect','Headache'),(107,10,'side_effect','Fatigue'),(108,10,'side_effect','Nausea'),(109,10,'side_effect','Abdominal pain'),(110,10,'side_effect','Sleepiness'),(111,10,'avoid_with','Simvastatin'),(112,10,'avoid_with','Cyclosporine'),(113,10,'avoid_with','Rifampicin'),(114,10,'avoid_with','Tacrolimus'),(115,11,'use','Treatment of Bacterial infections'),(116,11,'use','Treatment of Parasitic infections'),(117,11,'side_effect','Headache'),(118,11,'side_effect','Dryness in mouth'),(119,11,'side_effect','Nausea'),(120,11,'side_effect','Metallic taste'),(121,11,'avoid_with','Disulfiram'),(122,11,'avoid_with','Acenocoumarol'),(123,11,'avoid_with','Phenobarbitone'),(124,11,'avoid_with','Warfarin'),(125,12,'use','Treatment of Bacterial infections'),(126,12,'use','Treatment of Acne'),(127,12,'side_effect','Vomiting'),(128,12,'side_effect','Nausea'),(129,12,'side_effect','Diarrhea'),(130,12,'avoid_with','Acitretin'),(131,12,'avoid_with','Strontium Chloride'),(132,12,'avoid_with','Carbamazepine'),(133,12,'avoid_with','Fosphenytoin'),(134,13,'use','Treatment of Bacterial infections'),(135,13,'side_effect','Headache'),(136,13,'side_effect','Dizziness'),(137,13,'side_effect','Gastrointestinal disorder'),(138,13,'side_effect','Joint pain'),(139,13,'side_effect','Urticaria'),(140,13,'avoid_with','Rasagiline'),(141,13,'avoid_with','Selegiline'),(142,13,'avoid_with','Tizanidine'),(143,13,'avoid_with','Strontium Chloride'),(144,14,'use','Prevention of Angina (heart-related chest pain)'),(145,14,'use','Treatment and prevention of Heart attack'),(146,14,'use','Treatment and prevention of Stroke'),(147,14,'side_effect','Heartburn'),(148,14,'side_effect','Increased bleeding tendency'),(149,14,'side_effect','Nausea'),(150,14,'side_effect','Upset stomach'),(151,14,'side_effect','Vomiting'),(152,14,'avoid_with','Nimesulide'),(153,14,'avoid_with','Oxyphenbutazone'),(154,14,'avoid_with','Metamizole'),(155,15,'use','Treatment of Allergic conditions'),(156,15,'side_effect','Sleepiness'),(157,15,'side_effect','Fatigue'),(158,15,'side_effect','Dryness in mouth'),(159,15,'side_effect','Headache'),(160,15,'side_effect','Vomiting'),(161,15,'side_effect','Nasopharyngitis (inflammation of the throat and nasal passages)'),(162,15,'avoid_with','Aprepitant'),(163,15,'avoid_with','Fosaprepitant'),(164,15,'avoid_with','Zafirlukast'),(165,15,'avoid_with','Alprazolam');
/*!40000 ALTER TABLE `medicine_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `medicines`
--

DROP TABLE IF EXISTS `medicines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `medicines` (
  `medicine_id` int unsigned NOT NULL AUTO_INCREMENT,
  `brand_name` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `manufacturer_id` int unsigned NOT NULL,
  `dosage_form` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pack_size` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `therapeutic_class` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `habit_forming` tinyint(1) NOT NULL DEFAULT '0',
  `storage_note` text COLLATE utf8mb4_unicode_ci,
  `source_note` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`medicine_id`),
  UNIQUE KEY `uq_medicine_brand` (`brand_name`,`manufacturer_id`),
  KEY `fk_medicine_mfr` (`manufacturer_id`),
  CONSTRAINT `fk_medicine_mfr` FOREIGN KEY (`manufacturer_id`) REFERENCES `manufacturers` (`manufacturer_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `medicines`
--

LOCK TABLES `medicines` WRITE;
/*!40000 ALTER TABLE `medicines` DISABLE KEYS */;
INSERT INTO `medicines` VALUES (1,'Actiflu 500mg Tablet',1,'Tablet','strip of 10 tablets','PAIN ANALGESICS',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(2,'Nodimox 500mg Tablet DT',2,'Tablet (dispersible)','strip of 10 tablet dt','ANTI INFECTIVES',0,'Store below 25 C, in a cool dry place, away from light','demo storage text; interaction: known drug interaction data, demo only'),(3,'Azithral 500 Tablet',3,'Tablet','strip of 5 tablets','ANTI INFECTIVES',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(4,'Metgem 500 Tablet ER',4,'Tablet','strip of 10 tablet er','ANTI DIABETIC',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(5,'Atorva Tablet',5,'Tablet','strip of 15 tablets','CARDIAC',0,'Store below 25 C, in a cool dry place, away from light','demo storage text; interaction: known drug interaction data, demo only'),(6,'Omee 10mg Tablet',2,'Tablet','strip of 15 tablets','GASTRO INTESTINAL',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(7,'Alerid Tablet',1,'Tablet','strip of 10 tablets','RESPIRATORY',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(8,'Brufen 400 Tablet',6,'Tablet','strip of 15 tablets','PAIN ANALGESICS',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(9,'Lupipan 40mg Tablet',7,'Tablet','strip of 10 tablets','GASTRO INTESTINAL',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(10,'Amlokind 5 Tablet',8,'Tablet','strip of 15 tablets','CARDIAC',0,'Store below 25 C, in a cool dry place, away from light','demo storage text; interaction: known drug interaction data, demo only'),(11,'Metron 400mg Tablet',2,'Tablet','strip of 10 tablets','GASTRO INTESTINAL',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(12,'Doxygee 100mg Tablet',5,'Tablet','strip of 8 tablets','ANTI INFECTIVES',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(13,'Ciplox 500 Tablet',1,'Tablet','strip of 10 tablets','GASTRO INTESTINAL',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(14,'Ecosprin 75 Tablet',9,'Tablet','strip of 14 tablets','BLOOD RELATED',0,'Store below 25 C, in a cool dry place, away from light','demo storage text'),(15,'Elate 5mg Tablet',7,'Tablet','strip of 10 tablets','RESPIRATORY',0,'Store below 25 C, in a cool dry place, away from light','demo storage text');
/*!40000 ALTER TABLE `medicines` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_recalls`
--

DROP TABLE IF EXISTS `product_recalls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_recalls` (
  `recall_id` int unsigned NOT NULL AUTO_INCREMENT,
  `batch_id` int unsigned NOT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `recall_date` date NOT NULL,
  `issued_by` int unsigned NOT NULL,
  PRIMARY KEY (`recall_id`),
  UNIQUE KEY `uq_recall_batch` (`batch_id`),
  KEY `fk_recall_user` (`issued_by`),
  CONSTRAINT `fk_recall_batch` FOREIGN KEY (`batch_id`) REFERENCES `production_batches` (`batch_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_recall_user` FOREIGN KEY (`issued_by`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_recalls`
--

LOCK TABLES `product_recalls` WRITE;
/*!40000 ALTER TABLE `product_recalls` DISABLE KEYS */;
INSERT INTO `product_recalls` VALUES (1,12,'Unexpected impurity detected in post-market stability testing. Precautionary recall pending further investigation.','2026-09-15',1),(2,17,'DEMO REASONS','2026-10-08',1);
/*!40000 ALTER TABLE `product_recalls` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_recalls_ai` AFTER INSERT ON `product_recalls` FOR EACH ROW BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (
        @app_user_id,
        'INSERT_RECALL',
        'Product_Recalls',
        NEW.recall_id,
        CONCAT('Recall created for batch_id ', NEW.batch_id,
               '. Reason: ', LEFT(NEW.reason, 200))
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `production_batches`
--

DROP TABLE IF EXISTS `production_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `production_batches` (
  `batch_id` int unsigned NOT NULL AUTO_INCREMENT,
  `batch_number` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `medicine_id` int unsigned NOT NULL,
  `factory_id` int unsigned NOT NULL,
  `quantity_units` int unsigned NOT NULL,
  `manufacture_date` date NOT NULL,
  `expiry_date` date NOT NULL,
  `status` enum('Pending','Approved','Rejected','Recalled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending',
  PRIMARY KEY (`batch_id`),
  UNIQUE KEY `uq_batch_number` (`batch_number`),
  KEY `fk_batch_medicine` (`medicine_id`),
  KEY `fk_batch_factory` (`factory_id`),
  CONSTRAINT `fk_batch_factory` FOREIGN KEY (`factory_id`) REFERENCES `factories` (`factory_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_batch_medicine` FOREIGN KEY (`medicine_id`) REFERENCES `medicines` (`medicine_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_batch_dates` CHECK ((`expiry_date` > `manufacture_date`)),
  CONSTRAINT `chk_batch_qty` CHECK ((`quantity_units` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `production_batches`
--

LOCK TABLES `production_batches` WRITE;
/*!40000 ALTER TABLE `production_batches` DISABLE KEYS */;
INSERT INTO `production_batches` VALUES (1,'BT-2026-001',1,1,6922,'2026-01-15','2028-01-15','Approved'),(2,'BT-2026-002',2,3,8984,'2026-02-10','2028-02-10','Approved'),(3,'BT-2026-003',3,5,9867,'2026-03-05','2028-03-05','Approved'),(4,'BT-2026-004',4,7,9773,'2026-04-01','2028-04-01','Approved'),(5,'BT-2026-005',5,9,8011,'2026-05-20','2028-05-20','Approved'),(6,'BT-2026-006',8,11,8879,'2026-06-10','2028-06-10','Approved'),(7,'BT-2024-007',6,3,7664,'2024-03-01','2026-02-28','Approved'),(8,'BT-2026-008',7,1,5590,'2026-08-10','2028-08-10','Pending'),(9,'BT-2026-009',9,13,7444,'2026-09-01','2028-09-01','Pending'),(10,'BT-2026-010',10,15,9650,'2026-07-15','2028-07-15','Rejected'),(11,'BT-2026-011',11,3,8066,'2026-08-20','2028-08-20','Rejected'),(12,'BT-2026-012',13,1,8564,'2026-03-01','2028-03-01','Recalled'),(13,'TEST-BATCH-001',1,1,500,'2026-10-08','2028-10-08','Approved'),(14,'TEST-BATCH-OVERUSE',1,1,200,'2026-10-08','2028-10-08','Pending'),(15,'TEST-BATCH-NOMAT',1,1,300,'2026-10-08','2028-10-08','Pending'),(16,'TEST-BATCH-PAST',1,1,100,'2026-09-28','2028-10-08','Pending'),(17,'TEST-LIVE-001',1,2,100,'2026-10-08','2028-10-08','Recalled');
/*!40000 ALTER TABLE `production_batches` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_batches_bi` BEFORE INSERT ON `production_batches` FOR EACH ROW BEGIN
    DECLARE v_med_mfr INT UNSIGNED;
    DECLARE v_fac_mfr INT UNSIGNED;

    
    SELECT manufacturer_id INTO v_med_mfr
    FROM Medicines
    WHERE medicine_id = NEW.medicine_id;

    
    SELECT manufacturer_id INTO v_fac_mfr
    FROM Factories
    WHERE factory_id = NEW.factory_id;

    
    IF v_med_mfr != v_fac_mfr THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Medicine and factory belong to different manufacturers';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_batches_ai` AFTER INSERT ON `production_batches` FOR EACH ROW BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (
        @app_user_id,
        'BATCH_CREATED',
        'Production_Batches',
        NEW.batch_id,
        CONCAT('Batch ', NEW.batch_number, ' created with quantity ', NEW.quantity_units, '.')
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_batches_bu` BEFORE UPDATE ON `production_batches` FOR EACH ROW BEGIN
    DECLARE v_med_mfr       INT UNSIGNED;
    DECLARE v_fac_mfr       INT UNSIGNED;
    DECLARE v_latest_result VARCHAR(4);
    DECLARE v_recall_count  INT DEFAULT 0;
    DECLARE v_mat_count     INT DEFAULT 0;

    
    SELECT manufacturer_id INTO v_med_mfr
    FROM Medicines
    WHERE medicine_id = NEW.medicine_id;

    SELECT manufacturer_id INTO v_fac_mfr
    FROM Factories
    WHERE factory_id = NEW.factory_id;

    IF v_med_mfr != v_fac_mfr THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Medicine and factory belong to different manufacturers';
    END IF;

    
    IF OLD.status = 'Recalled' AND NEW.status != 'Recalled' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A recalled batch cannot change status.';
    END IF;

    
    IF NEW.status = 'Approved' AND OLD.status != 'Approved' THEN
        SELECT result INTO v_latest_result
        FROM Quality_Test_Reports
        WHERE batch_id = NEW.batch_id
        ORDER BY test_date DESC, report_id DESC
        LIMIT 1;

        IF v_latest_result IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot approve batch: no quality test reports found.';
        END IF;

        IF v_latest_result != 'Pass' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot approve batch: the most recent quality test did not Pass.';
        END IF;

        
        SELECT COUNT(*) INTO v_mat_count
        FROM Batch_Materials
        WHERE batch_id = NEW.batch_id;

        IF v_mat_count = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot approve batch: at least one raw material must be linked.';
        END IF;
    END IF;

    
    IF NEW.status = 'Recalled' AND OLD.status != 'Recalled' THEN
        SELECT COUNT(*) INTO v_recall_count
        FROM Product_Recalls
        WHERE batch_id = NEW.batch_id;

        IF v_recall_count = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot set status to Recalled: no Product_Recalls row exists for this batch.';
        END IF;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_batches_au` AFTER UPDATE ON `production_batches` FOR EACH ROW BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
        VALUES (
            @app_user_id,
            CONCAT('STATUS_', UPPER(NEW.status)),
            'Production_Batches',
            NEW.batch_id,
            CONCAT('Batch ', NEW.batch_number, ' status changed from ',
                   OLD.status, ' to ', NEW.status, '.')
        );
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `qr_codes`
--

DROP TABLE IF EXISTS `qr_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qr_codes` (
  `qr_id` int unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch_id` int unsigned NOT NULL,
  `issued_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`qr_id`),
  UNIQUE KEY `uq_qr_code` (`code`),
  KEY `fk_qr_batch` (`batch_id`),
  CONSTRAINT `fk_qr_batch` FOREIGN KEY (`batch_id`) REFERENCES `production_batches` (`batch_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=66 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `qr_codes`
--

LOCK TABLES `qr_codes` WRITE;
/*!40000 ALTER TABLE `qr_codes` DISABLE KEYS */;
INSERT INTO `qr_codes` VALUES (1,'PT360-20515ECBE7F2',1,'2026-01-21 10:00:00'),(2,'PT360-2DBC2CDE0F05',1,'2026-01-21 10:00:00'),(3,'PT360-D654F7F88CD7',1,'2026-01-21 10:00:00'),(4,'PT360-C2E428857BF6',1,'2026-01-21 10:00:00'),(5,'PT360-DE879898AC3E',1,'2026-01-21 10:00:00'),(6,'PT360-FDB312766A79',2,'2026-02-16 10:00:00'),(7,'PT360-C0C87CB81406',2,'2026-02-16 10:00:00'),(8,'PT360-40DEF96F30AA',2,'2026-02-16 10:00:00'),(9,'PT360-0D0C8E92B5D6',2,'2026-02-16 10:00:00'),(10,'PT360-2AD1859FD1EB',2,'2026-02-16 10:00:00'),(11,'PT360-C25B19B3CA0C',3,'2026-03-13 10:00:00'),(12,'PT360-D1D87AE9E94C',3,'2026-03-13 10:00:00'),(13,'PT360-972B2ED2A099',3,'2026-03-13 10:00:00'),(14,'PT360-D72C0F9CF0F5',3,'2026-03-13 10:00:00'),(15,'PT360-5858F04BC830',3,'2026-03-13 10:00:00'),(16,'PT360-DC85F316F1F0',4,'2026-04-09 10:00:00'),(17,'PT360-E50CF2AEB82A',4,'2026-04-09 10:00:00'),(18,'PT360-E8F1CA7DDA05',4,'2026-04-09 10:00:00'),(19,'PT360-36DEB5875A7B',4,'2026-04-09 10:00:00'),(20,'PT360-6ACF313E45C9',4,'2026-04-09 10:00:00'),(21,'PT360-4BD0B4AA9CE3',5,'2026-05-27 10:00:00'),(22,'PT360-1CB6879FBE4A',5,'2026-05-27 10:00:00'),(23,'PT360-D28E19BE0943',5,'2026-05-27 10:00:00'),(24,'PT360-D405A66ADA4E',5,'2026-05-27 10:00:00'),(25,'PT360-54E45BB36A57',5,'2026-05-27 10:00:00'),(26,'PT360-ABBDEA3E1892',6,'2026-06-17 10:00:00'),(27,'PT360-A63B55956DCB',6,'2026-06-17 10:00:00'),(28,'PT360-0E06D2012A03',6,'2026-06-17 10:00:00'),(29,'PT360-2AB0CC723648',6,'2026-06-17 10:00:00'),(30,'PT360-56F97F97D458',6,'2026-06-17 10:00:00'),(31,'PT360-DC2566C8811D',7,'2024-03-08 10:00:00'),(32,'PT360-FD8E3B2C5DD9',7,'2024-03-08 10:00:00'),(33,'PT360-ED67B20FCDCF',7,'2024-03-08 10:00:00'),(34,'PT360-E0449CB30DAA',7,'2024-03-08 10:00:00'),(35,'PT360-B1DF37DC6FE2',7,'2024-03-08 10:00:00'),(36,'PT360-DC651A49114C',12,'2026-03-07 10:00:00'),(37,'PT360-D1800B5B69EE',12,'2026-03-07 10:00:00'),(38,'PT360-98AA7066D5B1',12,'2026-03-07 10:00:00'),(39,'PT360-2022F8713918',12,'2026-03-07 10:00:00'),(40,'PT360-061D12F1AA50',12,'2026-03-07 10:00:00'),(41,'PT360-258AC0FB495D',13,'2026-10-08 13:35:32'),(42,'PT360-9F5F27566524',13,'2026-10-08 13:35:32'),(43,'PT360-0F3F4DA46E17',13,'2026-10-08 13:35:32'),(44,'PT360-D82ABD7F579E',13,'2026-10-08 13:35:32'),(45,'PT360-77CEFE5B01AE',13,'2026-10-08 13:35:32'),(46,'PT360-4C7EDA1C1225',17,'2026-10-08 17:59:17'),(47,'PT360-C1B9B1B3B2B6',17,'2026-10-08 17:59:17'),(48,'PT360-2D7A8E2ADCD9',17,'2026-10-08 17:59:17'),(49,'PT360-E7CFC69BE23F',17,'2026-10-08 17:59:17'),(50,'PT360-2E36CBA6B8B5',17,'2026-10-08 17:59:17'),(51,'PT360-2974EB0215CF',17,'2026-10-08 17:59:17'),(52,'PT360-B318B2EE635B',17,'2026-10-08 17:59:17'),(53,'PT360-680C735E15C2',17,'2026-10-08 17:59:17'),(54,'PT360-2B504570CAAA',17,'2026-10-08 17:59:17'),(55,'PT360-D2334C4D24BB',17,'2026-10-08 17:59:17'),(56,'PT360-E64AAF4A6231',17,'2026-10-08 17:59:59'),(57,'PT360-048BB45F3217',17,'2026-10-08 17:59:59'),(58,'PT360-7A412DD5EA0A',17,'2026-10-08 17:59:59'),(59,'PT360-95EAB3F0E5B1',17,'2026-10-08 17:59:59'),(60,'PT360-4C87F939B6C9',17,'2026-10-08 17:59:59'),(61,'PT360-DA1FABAA9264',17,'2026-10-08 17:59:59'),(62,'PT360-9BE9CA457308',17,'2026-10-08 17:59:59'),(63,'PT360-8D8DE2EB8469',17,'2026-10-08 17:59:59'),(64,'PT360-8E23FDD86FE7',17,'2026-10-08 17:59:59'),(65,'PT360-E06D04C5B2C0',17,'2026-10-08 17:59:59');
/*!40000 ALTER TABLE `qr_codes` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_qr_codes_bi` BEFORE INSERT ON `qr_codes` FOR EACH ROW BEGIN
    DECLARE v_status VARCHAR(10);
    SELECT status INTO v_status
    FROM Production_Batches
    WHERE batch_id = NEW.batch_id;

    IF v_status != 'Approved' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'QR codes can only be issued for Approved batches.';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `quality_test_reports`
--

DROP TABLE IF EXISTS `quality_test_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `quality_test_reports` (
  `report_id` int unsigned NOT NULL AUTO_INCREMENT,
  `batch_id` int unsigned NOT NULL,
  `tested_by` int unsigned NOT NULL,
  `test_date` date NOT NULL,
  `purity_pct` decimal(5,2) DEFAULT NULL,
  `dissolution_pct` decimal(5,2) DEFAULT NULL,
  `weight_variation_pct` decimal(5,2) DEFAULT NULL,
  `result` enum('Pass','Fail') COLLATE utf8mb4_unicode_ci NOT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`report_id`),
  KEY `fk_qtr_batch` (`batch_id`),
  KEY `fk_qtr_user` (`tested_by`),
  CONSTRAINT `fk_qtr_batch` FOREIGN KEY (`batch_id`) REFERENCES `production_batches` (`batch_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_qtr_user` FOREIGN KEY (`tested_by`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_dissolution` CHECK (((`dissolution_pct` is null) or (`dissolution_pct` between 0 and 100))),
  CONSTRAINT `chk_purity` CHECK (((`purity_pct` is null) or (`purity_pct` between 0 and 100))),
  CONSTRAINT `chk_weight_var` CHECK (((`weight_variation_pct` is null) or (`weight_variation_pct` between 0 and 100)))
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `quality_test_reports`
--

LOCK TABLES `quality_test_reports` WRITE;
/*!40000 ALTER TABLE `quality_test_reports` DISABLE KEYS */;
INSERT INTO `quality_test_reports` VALUES (1,1,2,'2026-01-20',99.50,95.20,1.80,'Pass','All parameters within limits.'),(2,2,3,'2026-02-15',98.80,93.10,2.10,'Pass','Meets pharmacopoeia standards.'),(3,3,3,'2026-03-12',99.10,94.50,1.50,'Pass','Clear pass on all metrics.'),(4,4,4,'2026-04-08',97.60,91.00,2.40,'Pass','Acceptable dissolution rate.'),(5,5,4,'2026-05-26',98.30,92.80,1.90,'Pass','Meets all specifications.'),(6,6,2,'2026-06-16',99.00,96.10,1.20,'Pass','Excellent batch quality.'),(7,7,3,'2024-03-07',98.50,93.40,2.00,'Pass','Approved - note: batch manufactured Mar 2024.'),(8,8,2,'2026-08-15',97.90,90.50,2.30,'Pass','Awaiting final approval.'),(9,9,4,'2026-09-08',98.20,92.00,1.70,'Pass','QC complete, pending sign-off.'),(10,10,4,'2026-07-20',85.40,72.30,4.50,'Fail','Purity below 90% threshold; dissolution below 80%. Batch rejected.'),(11,10,4,'2026-07-24',97.10,91.20,2.10,'Pass','Re-test passed, but batch already marked Rejected per SOP.'),(12,11,3,'2026-08-26',88.20,78.50,5.10,'Fail','Dissolution 78.5% - below 80% threshold. Weight variation 5.1% exceeds limit.'),(13,12,2,'2026-03-06',99.20,95.80,1.40,'Pass','Passed QC before recall was issued.'),(14,13,2,'2026-10-08',99.40,95.80,1.20,'Pass','QA passed all specifications.'),(15,15,2,'2026-10-08',99.10,94.50,1.10,'Pass','Tested before material linkage attempt.'),(16,17,2,'2026-10-08',99.02,95.00,1.00,'Pass','gg');
/*!40000 ALTER TABLE `quality_test_reports` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_qtr_ai` AFTER INSERT ON `quality_test_reports` FOR EACH ROW BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (
        @app_user_id,
        'INSERT_QA_TEST',
        'Quality_Test_Reports',
        NEW.report_id,
        CONCAT('QA test for batch_id ', NEW.batch_id,
               ' - result: ', NEW.result, '.')
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `role_id` tinyint unsigned NOT NULL AUTO_INCREMENT,
  `role_name` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uq_roles_name` (`role_name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'Admin/Regulator'),(2,'Manufacturer');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scan_log`
--

DROP TABLE IF EXISTS `scan_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `scan_log` (
  `scan_id` int unsigned NOT NULL AUTO_INCREMENT,
  `scanned_code` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `qr_id` int unsigned DEFAULT NULL,
  `scanned_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `verdict` enum('Genuine','Expired','Recalled','Not approved','Suspicious') COLLATE utf8mb4_unicode_ci NOT NULL,
  `review_status` enum('New','Reviewed','Blocked') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'New',
  PRIMARY KEY (`scan_id`),
  KEY `fk_scan_qr` (`qr_id`),
  KEY `idx_scan_code_time` (`scanned_code`,`scanned_at`),
  KEY `idx_scan_at` (`scanned_at`),
  KEY `idx_scan_review_status` (`review_status`),
  CONSTRAINT `fk_scan_qr` FOREIGN KEY (`qr_id`) REFERENCES `qr_codes` (`qr_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scan_log`
--

LOCK TABLES `scan_log` WRITE;
/*!40000 ALTER TABLE `scan_log` DISABLE KEYS */;
INSERT INTO `scan_log` VALUES (1,'PT360-20515ECBE7F2',1,'2026-06-20 09:30:00','Genuine','Reviewed'),(2,'PT360-2DBC2CDE0F05',2,'2026-06-25 12:30:00','Genuine','New'),(3,'PT360-D654F7F88CD7',3,'2026-07-05 15:30:00','Genuine','New'),(4,'PT360-FDB312766A79',6,'2026-07-12 10:30:00','Genuine','New'),(5,'PT360-C0C87CB81406',7,'2026-07-20 14:15:00','Genuine','New'),(6,'PT360-40DEF96F30AA',8,'2026-07-28 16:45:00','Genuine','New'),(7,'PT360-C25B19B3CA0C',11,'2026-08-02 11:00:00','Genuine','New'),(8,'PT360-D1D87AE9E94C',12,'2026-08-08 13:30:00','Genuine','New'),(9,'PT360-972B2ED2A099',13,'2026-08-16 17:00:00','Genuine','New'),(10,'PT360-DC85F316F1F0',16,'2026-08-22 09:45:00','Genuine','New'),(11,'PT360-E50CF2AEB82A',17,'2026-08-28 12:15:00','Genuine','New'),(12,'PT360-E8F1CA7DDA05',18,'2026-09-03 15:00:00','Genuine','New'),(13,'PT360-4BD0B4AA9CE3',21,'2026-09-08 10:20:00','Genuine','New'),(14,'PT360-1CB6879FBE4A',22,'2026-09-14 14:40:00','Genuine','New'),(15,'PT360-D28E19BE0943',23,'2026-09-22 11:30:00','Genuine','New'),(16,'PT360-DC2566C8811D',31,'2026-08-20 14:00:00','Expired','New'),(17,'PT360-DC651A49114C',36,'2026-09-20 11:00:00','Recalled','New'),(18,'FAKE-000000000001',NULL,'2026-09-22 16:45:00','Suspicious','New'),(19,'COUNTERFEIT-00002',NULL,'2026-09-23 11:20:00','Suspicious','New'),(20,'PT360-20515ECBE7F2',1,'2026-08-14 08:15:00','Suspicious','Reviewed'),(21,'PT360-20515ECBE7F2',1,'2026-08-14 09:30:00','Suspicious','Reviewed'),(22,'PT360-20515ECBE7F2',1,'2026-08-14 11:00:00','Suspicious','Reviewed'),(23,'PT360-20515ECBE7F2',1,'2026-08-14 13:45:00','Suspicious','Reviewed'),(24,'PT360-20515ECBE7F2',1,'2026-08-14 15:20:00','Suspicious','Reviewed'),(25,'PT360-20515ECBE7F2',1,'2026-08-14 17:00:00','Suspicious','Reviewed'),(26,'PT360-20515ECBE7F2',1,'2026-08-14 19:30:00','Suspicious','Reviewed'),(27,'PT360-20515ECBE7F2',1,'2026-08-14 21:00:00','Suspicious','Reviewed'),(28,'PT360-20515ECBE7F2',1,'2026-08-15 07:00:00','Suspicious','Reviewed'),(29,'PT360-20515ECBE7F2',1,'2026-08-15 10:15:00','Suspicious','Reviewed'),(30,'PT360-20515ECBE7F2',1,'2026-08-15 14:30:00','Suspicious','Reviewed'),(31,'PT360-20515ECBE7F2',1,'2026-08-15 18:00:00','Suspicious','Reviewed'),(32,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:42','Genuine','Reviewed'),(33,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:47','Genuine','Reviewed'),(34,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:50','Genuine','Reviewed'),(35,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:51','Genuine','Reviewed'),(36,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:51','Genuine','Reviewed'),(37,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:52','Genuine','Reviewed'),(38,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:52','Genuine','Reviewed'),(39,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:52','Genuine','Reviewed'),(40,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:55','Genuine','Reviewed'),(41,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:57','Genuine','Reviewed'),(42,'PT360-20515ECBE7F2',1,'2026-10-07 22:59:59','Genuine','Reviewed'),(43,'PT360-20515ECBE7F2',1,'2026-10-07 23:00:01','Suspicious','Reviewed'),(44,'fake-123',NULL,'2026-10-07 23:00:10','Suspicious','New'),(45,'PT360-DC651A49114C',36,'2026-10-08 00:19:56','Recalled','New'),(46,'PT360-20515ECBE7F2',1,'2026-10-08 00:28:03','Suspicious','Reviewed'),(47,'PT360-20515ECBE7F2',1,'2026-10-08 00:28:05','Suspicious','Reviewed'),(48,'PT360-20515ECBE7F2',1,'2026-10-08 00:28:08','Suspicious','Reviewed'),(49,'PT360-20515ECBE7F2',1,'2026-10-08 00:31:09','Suspicious','Reviewed'),(50,'PT360-20515ECBE7F2',1,'2026-10-08 00:31:12','Suspicious','Reviewed'),(51,'PT360-20515ECBE7F2',1,'2026-10-08 00:31:14','Suspicious','Reviewed'),(52,'PT360-20515ECBE7F2',1,'2026-10-08 00:38:38','Suspicious','New'),(53,'PT360-2974EB0215CF',51,'2026-10-08 17:59:47','Genuine','New'),(54,'PT360-2974EB0215CF',51,'2026-10-08 17:59:49','Genuine','New'),(55,'PT360-2B504570CAAA',54,'2026-10-08 18:13:56','Recalled','New'),(56,'PT360-2B504570CAAA',54,'2026-10-08 18:25:44','Recalled','New');
/*!40000 ALTER TABLE `scan_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `suppliers`
--

DROP TABLE IF EXISTS `suppliers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `suppliers` (
  `supplier_id` int unsigned NOT NULL AUTO_INCREMENT,
  `supplier_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_email` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`supplier_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `suppliers`
--

LOCK TABLES `suppliers` WRITE;
/*!40000 ALTER TABLE `suppliers` DISABLE KEYS */;
INSERT INTO `suppliers` VALUES (1,'Greenleaf Chem Supplies','sales@greenleafchem.demo.test','+91-22-55501001','Plot 12, MIDC Andheri, Mumbai 400093'),(2,'Apex Pharma Ingredients','info@apexpharma.demo.test','+91-40-55502002','Genome Valley, Hyderabad 500078'),(3,'Nexus Raw Materials Pvt','orders@nexusraw.demo.test','+91-79-55503003','Phase III, Vatva GIDC, Ahmedabad 382445'),(4,'PrimeChem Industries','contact@primechem.demo.test','+91-20-55504004','Hinjawadi IT Park, Pune 411057'),(5,'Reliable API Corporation','api@reliableapi.demo.test','+91-172-5550505','Industrial Area, Baddi, HP 173205');
/*!40000 ALTER TABLE `suppliers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int unsigned NOT NULL AUTO_INCREMENT,
  `full_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role_id` tinyint unsigned NOT NULL,
  `manufacturer_id` int unsigned DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uq_users_email` (`email`),
  KEY `fk_users_role` (`role_id`),
  KEY `fk_users_mfr` (`manufacturer_id`),
  CONSTRAINT `fk_users_mfr` FOREIGN KEY (`manufacturer_id`) REFERENCES `manufacturers` (`manufacturer_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'Priya Sharma','priya.admin@demo.test','$2y$12$2VpamK/67hXzIvwBMXcxB.aitOvIGpOXcsZSV1UW.ZiTDP4fSlqaq',1,NULL,1,'2026-10-07 15:00:19'),(2,'Rahul Verma','rahul.mfr@demo.test','$2y$12$hmLRJt2lSlfuj.Vd7spQZO8iQgurqdm4XTG8LS01crmIjXNxJJ5J.',2,1,1,'2026-10-07 15:00:19'),(3,'Anjali Desai','anjali.mfr@demo.test','!',2,2,1,'2026-10-07 15:00:19'),(4,'Vikram Patel','vikram.mfr@demo.test','!',2,3,1,'2026-10-07 15:00:19');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_bi` BEFORE INSERT ON `users` FOR EACH ROW BEGIN
    DECLARE v_role_name VARCHAR(30);
    SELECT role_name INTO v_role_name
    FROM Roles WHERE role_id = NEW.role_id;

    IF v_role_name = 'Manufacturer' AND NEW.manufacturer_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manufacturer users must have a manufacturer_id.';
    END IF;

    IF v_role_name = 'Admin/Regulator' AND NEW.manufacturer_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Admin/Regulator users must NOT have a manufacturer_id.';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_users_bu` BEFORE UPDATE ON `users` FOR EACH ROW BEGIN
    DECLARE v_role_name VARCHAR(30);
    SELECT role_name INTO v_role_name
    FROM Roles WHERE role_id = NEW.role_id;

    IF v_role_name = 'Manufacturer' AND NEW.manufacturer_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manufacturer users must have a manufacturer_id.';
    END IF;

    IF v_role_name = 'Admin/Regulator' AND NEW.manufacturer_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Admin/Regulator users must NOT have a manufacturer_id.';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Temporary view structure for view `v_batch_overview`
--

DROP TABLE IF EXISTS `v_batch_overview`;
/*!50001 DROP VIEW IF EXISTS `v_batch_overview`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_batch_overview` AS SELECT 
 1 AS `batch_number`,
 1 AS `medicine`,
 1 AS `manufacturer`,
 1 AS `manufacturer_id`,
 1 AS `factory`,
 1 AS `status`,
 1 AS `manufacture_date`,
 1 AS `expiry_date`,
 1 AS `qr_count`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_batch_qr_codes`
--

DROP TABLE IF EXISTS `v_batch_qr_codes`;
/*!50001 DROP VIEW IF EXISTS `v_batch_qr_codes`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_batch_qr_codes` AS SELECT 
 1 AS `batch_number`,
 1 AS `manufacturer_id`,
 1 AS `qr_code`,
 1 AS `issued_at`,
 1 AS `scan_count`,
 1 AS `last_scan`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_batch_status_counts`
--

DROP TABLE IF EXISTS `v_batch_status_counts`;
/*!50001 DROP VIEW IF EXISTS `v_batch_status_counts`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_batch_status_counts` AS SELECT 
 1 AS `status`,
 1 AS `batch_count`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_batch_tests`
--

DROP TABLE IF EXISTS `v_batch_tests`;
/*!50001 DROP VIEW IF EXISTS `v_batch_tests`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_batch_tests` AS SELECT 
 1 AS `batch_number`,
 1 AS `test_date`,
 1 AS `purity`,
 1 AS `dissolution`,
 1 AS `weight_variation`,
 1 AS `result`,
 1 AS `remarks`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_batch_timeline`
--

DROP TABLE IF EXISTS `v_batch_timeline`;
/*!50001 DROP VIEW IF EXISTS `v_batch_timeline`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_batch_timeline` AS SELECT 
 1 AS `batch_number`,
 1 AS `manufacturer_id`,
 1 AS `event_time`,
 1 AS `event_type`,
 1 AS `description`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_batch_traceability`
--

DROP TABLE IF EXISTS `v_batch_traceability`;
/*!50001 DROP VIEW IF EXISTS `v_batch_traceability`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_batch_traceability` AS SELECT 
 1 AS `batch_number`,
 1 AS `medicine`,
 1 AS `material`,
 1 AS `supplier`,
 1 AS `certificate_number`,
 1 AS `delivered_kg`,
 1 AS `used_kg`,
 1 AS `received_date`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_dashboard`
--

DROP TABLE IF EXISTS `v_dashboard`;
/*!50001 DROP VIEW IF EXISTS `v_dashboard`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_dashboard` AS SELECT 
 1 AS `approved_batches`,
 1 AS `failed_tests`,
 1 AS `suspicious_scans`,
 1 AS `recalls`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_demo_codes`
--

DROP TABLE IF EXISTS `v_demo_codes`;
/*!50001 DROP VIEW IF EXISTS `v_demo_codes`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_demo_codes` AS SELECT 
 1 AS `demo_type`,
 1 AS `code`,
 1 AS `batch_number`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_form_factories`
--

DROP TABLE IF EXISTS `v_form_factories`;
/*!50001 DROP VIEW IF EXISTS `v_form_factories`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_form_factories` AS SELECT 
 1 AS `manufacturer_id`,
 1 AS `factory_name`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_form_ingredients`
--

DROP TABLE IF EXISTS `v_form_ingredients`;
/*!50001 DROP VIEW IF EXISTS `v_form_ingredients`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_form_ingredients` AS SELECT 
 1 AS `ingredient_name`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_form_medicines`
--

DROP TABLE IF EXISTS `v_form_medicines`;
/*!50001 DROP VIEW IF EXISTS `v_form_medicines`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_form_medicines` AS SELECT 
 1 AS `manufacturer_id`,
 1 AS `brand_name`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_form_suppliers`
--

DROP TABLE IF EXISTS `v_form_suppliers`;
/*!50001 DROP VIEW IF EXISTS `v_form_suppliers`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_form_suppliers` AS SELECT 
 1 AS `supplier_name`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_my_deliveries`
--

DROP TABLE IF EXISTS `v_my_deliveries`;
/*!50001 DROP VIEW IF EXISTS `v_my_deliveries`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_my_deliveries` AS SELECT 
 1 AS `manufacturer_id`,
 1 AS `certificate_number`,
 1 AS `ingredient_name`,
 1 AS `supplier_name`,
 1 AS `received_date`,
 1 AS `quantity_kg`,
 1 AS `used_kg`,
 1 AS `remaining_kg`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_recall_list`
--

DROP TABLE IF EXISTS `v_recall_list`;
/*!50001 DROP VIEW IF EXISTS `v_recall_list`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_recall_list` AS SELECT 
 1 AS `recall_id`,
 1 AS `batch_number`,
 1 AS `medicine`,
 1 AS `manufacturer`,
 1 AS `reason`,
 1 AS `recall_date`,
 1 AS `issued_by_email`,
 1 AS `qr_count`,
 1 AS `total_scans`,
 1 AS `scans_after_recall`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_recent_audit`
--

DROP TABLE IF EXISTS `v_recent_audit`;
/*!50001 DROP VIEW IF EXISTS `v_recent_audit`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_recent_audit` AS SELECT 
 1 AS `log_id`,
 1 AS `user_id`,
 1 AS `user_name`,
 1 AS `action`,
 1 AS `table_name`,
 1 AS `record_id`,
 1 AS `details`,
 1 AS `logged_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_suspicious_codes`
--

DROP TABLE IF EXISTS `v_suspicious_codes`;
/*!50001 DROP VIEW IF EXISTS `v_suspicious_codes`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_suspicious_codes` AS SELECT 
 1 AS `scanned_code`,
 1 AS `scan_count`,
 1 AS `first_scan`,
 1 AS `last_scan`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'pharmatrace360'
--

--
-- Dumping routines for database 'pharmatrace360'
--
/*!50003 DROP FUNCTION IF EXISTS `fn_qr_verdict` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_qr_verdict`(
    p_code VARCHAR(64)
) RETURNS varchar(20) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    READS SQL DATA
    DETERMINISTIC
BEGIN
    DECLARE v_batch_id     INT UNSIGNED;
    DECLARE v_status       VARCHAR(10);
    DECLARE v_expiry       DATE;
    DECLARE v_recent       INT;

    
    SELECT qr.batch_id, pb.status, pb.expiry_date
    INTO v_batch_id, v_status, v_expiry
    FROM QR_Codes qr
    JOIN Production_Batches pb ON pb.batch_id = qr.batch_id
    WHERE qr.code = p_code
    LIMIT 1;

    
    IF v_batch_id IS NULL THEN
        RETURN 'Suspicious';
    END IF;

    
    IF v_status = 'Recalled' THEN
        RETURN 'Recalled';
    END IF;

    
    IF v_status != 'Approved' THEN
        RETURN 'Not approved';
    END IF;

    
    IF v_expiry < CURDATE() THEN
        RETURN 'Expired';
    END IF;

    
    
    SET v_recent = fn_recent_scan_count(p_code, 48);
    IF v_recent > 10 THEN
        RETURN 'Suspicious';
    END IF;

    
    RETURN 'Genuine';
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_recent_scan_count` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_recent_scan_count`(
    p_code  VARCHAR(64),
    p_hours INT
) RETURNS int
    READS SQL DATA
    DETERMINISTIC
BEGIN
    DECLARE v_count INT DEFAULT 0;
    SELECT COUNT(*) INTO v_count
    FROM Scan_Log
    WHERE scanned_code = p_code
      AND scanned_at >= NOW() - INTERVAL p_hours HOUR;
    RETURN v_count;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_user_can_manage_batch` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_user_can_manage_batch`(
    p_user_id      INT UNSIGNED,
    p_batch_number VARCHAR(40)
) RETURNS tinyint
    READS SQL DATA
BEGIN
    DECLARE v_user_active   TINYINT DEFAULT 0;
    DECLARE v_user_role     VARCHAR(30) DEFAULT '';
    DECLARE v_user_mfr      INT UNSIGNED DEFAULT NULL;
    DECLARE v_batch_mfr     INT UNSIGNED DEFAULT NULL;

    
    SELECT u.is_active, r.role_name, u.manufacturer_id
    INTO v_user_active, v_user_role, v_user_mfr
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 THEN RETURN 0; END IF;
    IF v_user_role != 'Manufacturer' THEN RETURN 0; END IF;
    IF v_user_mfr IS NULL THEN RETURN 0; END IF;

    
    SELECT f.manufacturer_id INTO v_batch_mfr
    FROM Production_Batches pb
    JOIN Factories f ON f.factory_id = pb.factory_id
    WHERE pb.batch_number = p_batch_number;

    IF v_batch_mfr IS NULL THEN RETURN 0; END IF;
    IF v_user_mfr != v_batch_mfr THEN RETURN 0; END IF;

    RETURN 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_add_batch_material` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_add_batch_material`(
    IN p_user_id            INT UNSIGNED,
    IN p_batch_number       VARCHAR(40),
    IN p_certificate_number VARCHAR(60),
    IN p_quantity_used_kg   DECIMAL(10,3)
)
BEGIN
    DECLARE v_batch_id     INT UNSIGNED DEFAULT NULL;
    DECLARE v_status       VARCHAR(10) DEFAULT '';
    DECLARE v_delivery_id  INT UNSIGNED DEFAULT NULL;
    DECLARE v_err_msg      TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    
    IF fn_user_can_manage_batch(p_user_id, p_batch_number) != 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: you cannot manage this batch.';
    END IF;

    
    IF p_quantity_used_kg IS NULL OR p_quantity_used_kg <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity used must be greater than zero.';
    END IF;

    
    SELECT delivery_id INTO v_delivery_id
    FROM Material_Deliveries
    WHERE certificate_number = p_certificate_number
    LIMIT 1;

    IF v_delivery_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery not found for the given certificate number.';
    END IF;

    SET @app_user_id = p_user_id;

    START TRANSACTION;

        
        SELECT batch_id, status
        INTO v_batch_id, v_status
        FROM Production_Batches
        WHERE batch_number = p_batch_number
        FOR UPDATE;

        IF v_batch_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Batch not found.';
        END IF;

        IF v_status != 'Pending' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Materials can only be added to Pending batches.';
        END IF;

        INSERT INTO Batch_Materials (batch_id, delivery_id, quantity_used_kg)
        VALUES (v_batch_id, v_delivery_id, p_quantity_used_kg);

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Material linked to batch ', p_batch_number, '.') AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_approve_batch` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_approve_batch`(
    IN p_batch_number VARCHAR(40),
    IN p_user_id      INT UNSIGNED,
    IN p_pack_count   INT UNSIGNED
)
BEGIN
    DECLARE v_batch_id INT UNSIGNED;
    DECLARE v_status   VARCHAR(10);
    DECLARE v_i        INT DEFAULT 0;
    DECLARE v_code     VARCHAR(64);
    DECLARE v_err_msg  TEXT;

    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    
    IF fn_user_can_manage_batch(p_user_id, p_batch_number) != 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: you cannot manage this batch.';
    END IF;

    
    SET @app_user_id = p_user_id;

    START TRANSACTION;

        
        SELECT batch_id, status INTO v_batch_id, v_status
        FROM Production_Batches
        WHERE batch_number = p_batch_number
        FOR UPDATE;

        IF v_batch_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Batch not found.';
        END IF;

        
        UPDATE Production_Batches
        SET status = 'Approved'
        WHERE batch_id = v_batch_id;

        
        WHILE v_i < p_pack_count DO
            SET v_code = CONCAT('PT360-', UPPER(LEFT(MD5(UUID()), 12)));
            INSERT INTO QR_Codes (code, batch_id) VALUES (v_code, v_batch_id);
            SET v_i = v_i + 1;
        END WHILE;

    COMMIT;

    
    SET @app_user_id = NULL;

    
    SELECT CONCAT('Batch ', p_batch_number, ' approved. ',
                  p_pack_count, ' QR codes created.') AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_change_password` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_change_password`(
    IN p_user_id  INT UNSIGNED,
    IN p_new_hash VARCHAR(255)
)
BEGIN
    DECLARE v_user_exists INT DEFAULT 0;
    DECLARE v_err_msg     TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    
    SELECT COUNT(*) INTO v_user_exists
    FROM Users
    WHERE user_id = p_user_id;

    IF v_user_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not found.';
    END IF;

    
    IF p_new_hash IS NULL OR CHAR_LENGTH(p_new_hash) < 60 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Password hash is too short. Must be a valid bcrypt hash of at least 60 characters.';
    END IF;

    SET @app_user_id = p_user_id;

    START TRANSACTION;

        UPDATE Users
        SET password_hash = p_new_hash
        WHERE user_id = p_user_id;

        INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
        VALUES (p_user_id, 'PASSWORD_CHANGED', 'Users', p_user_id, 'Password changed successfully.');

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Password updated for user_id ', p_user_id, '.') AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_create_batch` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_batch`(
    IN p_user_id          INT UNSIGNED,
    IN p_batch_number     VARCHAR(40),
    IN p_medicine_name    VARCHAR(160),
    IN p_factory_name     VARCHAR(120),
    IN p_quantity         INT UNSIGNED,
    IN p_manufacture_date DATE,
    IN p_expiry_date      DATE
)
BEGIN
    DECLARE v_user_active   TINYINT DEFAULT 0;
    DECLARE v_user_role     VARCHAR(30) DEFAULT '';
    DECLARE v_mfr_id        INT UNSIGNED DEFAULT NULL;
    DECLARE v_medicine_id   INT UNSIGNED DEFAULT NULL;
    DECLARE v_factory_id    INT UNSIGNED DEFAULT NULL;
    DECLARE v_batch_count   INT DEFAULT 0;
    DECLARE v_err_msg       TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    
    SELECT u.is_active, r.role_name, u.manufacturer_id
    INTO v_user_active, v_user_role, v_mfr_id
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 OR v_user_role != 'Manufacturer' OR v_mfr_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: user must be an active Manufacturer.';
    END IF;

    
    IF p_batch_number IS NULL OR TRIM(p_batch_number) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Batch number cannot be empty.';
    END IF;

    SELECT COUNT(*) INTO v_batch_count
    FROM Production_Batches
    WHERE batch_number = p_batch_number;

    IF v_batch_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Batch number already exists.';
    END IF;

    
    IF p_quantity IS NULL OR p_quantity = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity must be greater than zero.';
    END IF;

    
    SELECT medicine_id INTO v_medicine_id
    FROM Medicines
    WHERE brand_name = p_medicine_name AND manufacturer_id = v_mfr_id
    LIMIT 1;

    IF v_medicine_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Medicine not found or does not belong to the user manufacturer.';
    END IF;

    
    SELECT factory_id INTO v_factory_id
    FROM Factories
    WHERE factory_name = p_factory_name AND manufacturer_id = v_mfr_id
    LIMIT 1;

    IF v_factory_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Factory not found or does not belong to the user manufacturer.';
    END IF;

    
    IF p_manufacture_date IS NULL OR p_manufacture_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Manufacture date cannot be in the future.';
    END IF;

    
    IF p_expiry_date IS NULL OR p_expiry_date <= p_manufacture_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Expiry date must be after manufacture date.';
    END IF;

    SET @app_user_id = p_user_id;

    START TRANSACTION;

        INSERT INTO Production_Batches
            (batch_number, medicine_id, factory_id, quantity_units, manufacture_date, expiry_date, status)
        VALUES
            (p_batch_number, v_medicine_id, v_factory_id, p_quantity, p_manufacture_date, p_expiry_date, 'Pending');

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Batch ', p_batch_number, ' created.') AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_issue_recall` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_issue_recall`(
    IN p_batch_number VARCHAR(40),
    IN p_reason       TEXT,
    IN p_user_id      INT UNSIGNED
)
BEGIN
    DECLARE v_batch_id    INT UNSIGNED;
    DECLARE v_err_msg     TEXT;
    DECLARE v_user_active TINYINT DEFAULT 0;
    DECLARE v_user_role   VARCHAR(30) DEFAULT '';

    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    
    SELECT u.is_active, r.role_name
    INTO v_user_active, v_user_role
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 OR v_user_role != 'Admin/Regulator' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: only active Admin/Regulator users can issue recalls.';
    END IF;

    
    SET @app_user_id = p_user_id;

    START TRANSACTION;

        
        SELECT batch_id INTO v_batch_id
        FROM Production_Batches
        WHERE batch_number = p_batch_number
        FOR UPDATE;

        IF v_batch_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Batch not found.';
        END IF;

        
        INSERT INTO Product_Recalls (batch_id, reason, recall_date, issued_by)
        VALUES (v_batch_id, p_reason, CURDATE(), p_user_id);

        
        UPDATE Production_Batches
        SET status = 'Recalled'
        WHERE batch_id = v_batch_id;

    COMMIT;

    
    SET @app_user_id = NULL;

    
    SELECT
        pb.batch_number,
        m.brand_name          AS medicine,
        s.supplier_name       AS supplier,
        md.certificate_number,
        (SELECT COUNT(*) FROM QR_Codes WHERE batch_id = v_batch_id)
                              AS qr_count,
        (SELECT COUNT(*) FROM Scan_Log sl
         JOIN QR_Codes qr ON qr.qr_id = sl.qr_id
         WHERE qr.batch_id = v_batch_id)
                              AS total_scans
    FROM Production_Batches  pb
    JOIN Medicines           m   ON m.medicine_id    = pb.medicine_id
    LEFT JOIN Batch_Materials bm ON bm.batch_id      = pb.batch_id
    LEFT JOIN Material_Deliveries md ON md.delivery_id = bm.delivery_id
    LEFT JOIN Suppliers      s   ON s.supplier_id    = md.supplier_id
    WHERE pb.batch_id = v_batch_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_login_lookup` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login_lookup`(
    IN p_email VARCHAR(120)
)
BEGIN
    SELECT u.user_id, u.email, u.password_hash,
           r.role_name, u.manufacturer_id, u.is_active
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.email = p_email
    LIMIT 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_log_event` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_log_event`(
    IN p_user_id INT UNSIGNED,
    IN p_action  VARCHAR(60),
    IN p_details TEXT
)
BEGIN
    INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
    VALUES (p_user_id, p_action, 'Users', p_user_id, p_details);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_record_delivery` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_record_delivery`(
    IN p_user_id            INT UNSIGNED,
    IN p_supplier_name      VARCHAR(120),
    IN p_ingredient_name    VARCHAR(120),
    IN p_quantity_kg        DECIMAL(10,3),
    IN p_received_date      DATE,
    IN p_certificate_number VARCHAR(60)
)
BEGIN
    DECLARE v_user_active   TINYINT DEFAULT 0;
    DECLARE v_user_role     VARCHAR(30) DEFAULT '';
    DECLARE v_mfr_id        INT UNSIGNED DEFAULT NULL;
    DECLARE v_supplier_id   INT UNSIGNED DEFAULT NULL;
    DECLARE v_ingredient_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_cert_count    INT DEFAULT 0;
    DECLARE v_err_msg       TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    
    SELECT u.is_active, r.role_name, u.manufacturer_id
    INTO v_user_active, v_user_role, v_mfr_id
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 OR v_user_role != 'Manufacturer' OR v_mfr_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: user must be an active Manufacturer.';
    END IF;

    
    IF p_quantity_kg IS NULL OR p_quantity_kg <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Delivery quantity must be greater than zero.';
    END IF;

    
    IF p_received_date IS NULL OR p_received_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Received date cannot be in the future.';
    END IF;

    
    IF p_certificate_number IS NULL OR TRIM(p_certificate_number) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Certificate number cannot be empty.';
    END IF;

    SELECT COUNT(*) INTO v_cert_count
    FROM Material_Deliveries
    WHERE certificate_number = p_certificate_number;

    IF v_cert_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Certificate number already exists.';
    END IF;

    
    SELECT supplier_id INTO v_supplier_id
    FROM Suppliers
    WHERE supplier_name = p_supplier_name
    LIMIT 1;

    IF v_supplier_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Supplier does not exist.';
    END IF;

    
    SELECT ingredient_id INTO v_ingredient_id
    FROM Ingredients
    WHERE ingredient_name = p_ingredient_name
    LIMIT 1;

    IF v_ingredient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ingredient does not exist.';
    END IF;

    SET @app_user_id = p_user_id;

    START TRANSACTION;

        INSERT INTO Material_Deliveries
            (supplier_id, ingredient_id, manufacturer_id, quantity_kg, received_date, certificate_number)
        VALUES
            (v_supplier_id, v_ingredient_id, v_mfr_id, p_quantity_kg, p_received_date, p_certificate_number);

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Delivery recorded under certificate ', p_certificate_number, '.') AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_record_test` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_record_test`(
    IN p_batch_number      VARCHAR(40),
    IN p_user_id           INT UNSIGNED,
    IN p_purity            DECIMAL(5,2),
    IN p_dissolution       DECIMAL(5,2),
    IN p_weight_variation  DECIMAL(5,2),
    IN p_result            VARCHAR(4),
    IN p_remarks           TEXT
)
BEGIN
    DECLARE v_batch_id INT UNSIGNED;
    DECLARE v_status   VARCHAR(10);
    DECLARE v_err_msg  TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    
    IF fn_user_can_manage_batch(p_user_id, p_batch_number) != 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: you cannot manage this batch.';
    END IF;

    START TRANSACTION;

        
        SELECT batch_id, status INTO v_batch_id, v_status
        FROM Production_Batches
        WHERE batch_number = p_batch_number
        FOR UPDATE;

        IF v_batch_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Batch not found.';
        END IF;

        IF v_status != 'Pending' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tests can only be recorded for Pending batches.';
        END IF;

        SET @app_user_id = p_user_id;

        INSERT INTO Quality_Test_Reports
            (batch_id, tested_by, test_date, purity_pct, dissolution_pct,
             weight_variation_pct, result, remarks)
        VALUES
            (v_batch_id, p_user_id, CURDATE(), p_purity, p_dissolution,
             p_weight_variation, p_result, p_remarks);

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Test recorded for batch ', p_batch_number,
                  '. Result: ', p_result, '.') AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_reject_batch` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reject_batch`(
    IN p_batch_number VARCHAR(40),
    IN p_user_id      INT UNSIGNED
)
BEGIN
    DECLARE v_batch_id      INT UNSIGNED;
    DECLARE v_status        VARCHAR(10);
    DECLARE v_latest_result VARCHAR(4);
    DECLARE v_err_msg       TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    
    IF fn_user_can_manage_batch(p_user_id, p_batch_number) != 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: you cannot manage this batch.';
    END IF;

    START TRANSACTION;

        
        SELECT batch_id, status INTO v_batch_id, v_status
        FROM Production_Batches
        WHERE batch_number = p_batch_number
        FOR UPDATE;

        IF v_batch_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Batch not found.';
        END IF;

        IF v_status != 'Pending' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only Pending batches can be rejected.';
        END IF;

        
        SELECT result INTO v_latest_result
        FROM Quality_Test_Reports
        WHERE batch_id = v_batch_id
        ORDER BY test_date DESC, report_id DESC
        LIMIT 1;

        IF v_latest_result IS NULL OR v_latest_result != 'Fail' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot reject batch: the most recent quality test is not Fail.';
        END IF;

        SET @app_user_id = p_user_id;

        UPDATE Production_Batches
        SET status = 'Rejected'
        WHERE batch_id = v_batch_id;

    COMMIT;

    SET @app_user_id = NULL;

    SELECT CONCAT('Batch ', p_batch_number, ' rejected.') AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_set_password` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_set_password`(
    IN p_email VARCHAR(120),
    IN p_hash  VARCHAR(255)
)
BEGIN
    DECLARE v_found INT DEFAULT 0;

    SELECT COUNT(*) INTO v_found
    FROM Users WHERE email = p_email;

    IF v_found = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No user found with that email.';
    END IF;

    UPDATE Users
    SET password_hash = p_hash
    WHERE email = p_email;

    SELECT CONCAT('Password updated for ', p_email, '.') AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_update_suspicious_review` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_suspicious_review`(
    IN p_code    VARCHAR(64),
    IN p_status  VARCHAR(20),
    IN p_user_id INT UNSIGNED
)
BEGIN
    DECLARE v_user_active TINYINT DEFAULT 0;
    DECLARE v_user_role   VARCHAR(30) DEFAULT '';
    DECLARE v_count       INT DEFAULT 0;
    DECLARE v_err_msg     TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_err_msg;
    END;

    
    SELECT u.is_active, r.role_name
    INTO v_user_active, v_user_role
    FROM Users u
    JOIN Roles r ON r.role_id = u.role_id
    WHERE u.user_id = p_user_id;

    IF v_user_active != 1 OR v_user_role != 'Admin/Regulator' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Permission denied: only active Admin/Regulator users can review suspicious codes.';
    END IF;

    
    IF p_status NOT IN ('New', 'Reviewed', 'Blocked') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid review status. Allowed values: New, Reviewed, Blocked.';
    END IF;

    
    SELECT COUNT(*) INTO v_count
    FROM Scan_Log
    WHERE scanned_code = p_code;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No scan records found for the specified code.';
    END IF;

    
    START TRANSACTION;

        UPDATE Scan_Log
        SET review_status = p_status
        WHERE scanned_code = p_code;

        INSERT INTO Audit_Logs (user_id, action, table_name, record_id, details)
        VALUES (
            p_user_id,
            'REVIEW_SUSPICIOUS_CODE',
            'Scan_Log',
            NULL,
            CONCAT('Suspicious code ', p_code, ' review status changed to ', p_status, '.')
        );

    COMMIT;

    SELECT CONCAT('Code ', p_code, ' review status updated to ', p_status, '.') AS result;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_verify_scan` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_verify_scan`(
    IN p_code VARCHAR(64)
)
BEGIN
    DECLARE v_verdict    VARCHAR(20);
    DECLARE v_qr_id     INT UNSIGNED DEFAULT NULL;
    DECLARE v_batch_id  INT UNSIGNED DEFAULT NULL;
    DECLARE v_med_id    INT UNSIGNED DEFAULT NULL;

    
    SET v_verdict = fn_qr_verdict(p_code);

    
    SELECT qr_id, batch_id
    INTO v_qr_id, v_batch_id
    FROM QR_Codes
    WHERE code = p_code
    LIMIT 1;

    IF v_batch_id IS NOT NULL THEN
        SELECT medicine_id INTO v_med_id
        FROM Production_Batches
        WHERE batch_id = v_batch_id;
    END IF;

    
    INSERT INTO Scan_Log (scanned_code, qr_id, scanned_at, verdict)
    VALUES (p_code, v_qr_id, NOW(), v_verdict);

    
    IF v_qr_id IS NULL THEN
        
        SELECT v_verdict AS verdict,
               'Demo data - general information only, ask a doctor or pharmacist.' AS advisory;
    ELSE
        
        SELECT
            v_verdict           AS verdict,
            m.brand_name        AS medicine_name,
            df.strength,
            ing.ingredient_name AS ingredient,
            mfr.company_name    AS manufacturer,
            pb.batch_number,
            pb.manufacture_date,
            pb.expiry_date,
            m.storage_note,
            pr.reason           AS recall_reason,
            pr.recall_date      AS recall_date,
            'Demo data - general information only, ask a doctor or pharmacist.' AS advisory
        FROM Production_Batches pb
        JOIN Medicines          m   ON m.medicine_id       = pb.medicine_id
        JOIN Manufacturers      mfr ON mfr.manufacturer_id = m.manufacturer_id
        JOIN Drug_Formulations  df  ON df.medicine_id      = m.medicine_id
        JOIN Ingredients        ing ON ing.ingredient_id   = df.ingredient_id
        LEFT JOIN Product_Recalls pr ON pr.batch_id        = pb.batch_id
        WHERE pb.batch_id = v_batch_id;

        
        SELECT info_text AS `use`
        FROM Medicine_Info
        WHERE medicine_id = v_med_id AND info_type = 'use';

        
        SELECT info_text AS side_effect
        FROM Medicine_Info
        WHERE medicine_id = v_med_id AND info_type = 'side_effect';

        
        SELECT info_text AS avoid_taking_together_with
        FROM Medicine_Info
        WHERE medicine_id = v_med_id AND info_type = 'avoid_with';
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `v_batch_overview`
--

/*!50001 DROP VIEW IF EXISTS `v_batch_overview`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_batch_overview` AS select `pb`.`batch_number` AS `batch_number`,`m`.`brand_name` AS `medicine`,`mfr`.`company_name` AS `manufacturer`,`mfr`.`manufacturer_id` AS `manufacturer_id`,`f`.`factory_name` AS `factory`,`pb`.`status` AS `status`,`pb`.`manufacture_date` AS `manufacture_date`,`pb`.`expiry_date` AS `expiry_date`,count(`qr`.`qr_id`) AS `qr_count` from ((((`production_batches` `pb` join `medicines` `m` on((`m`.`medicine_id` = `pb`.`medicine_id`))) join `factories` `f` on((`f`.`factory_id` = `pb`.`factory_id`))) join `manufacturers` `mfr` on((`mfr`.`manufacturer_id` = `f`.`manufacturer_id`))) left join `qr_codes` `qr` on((`qr`.`batch_id` = `pb`.`batch_id`))) group by `pb`.`batch_id`,`pb`.`batch_number`,`m`.`brand_name`,`mfr`.`company_name`,`mfr`.`manufacturer_id`,`f`.`factory_name`,`pb`.`status`,`pb`.`manufacture_date`,`pb`.`expiry_date` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_batch_qr_codes`
--

/*!50001 DROP VIEW IF EXISTS `v_batch_qr_codes`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_batch_qr_codes` AS select `pb`.`batch_number` AS `batch_number`,`f`.`manufacturer_id` AS `manufacturer_id`,`qr`.`code` AS `qr_code`,`qr`.`issued_at` AS `issued_at`,count(`sl`.`scan_id`) AS `scan_count`,max(`sl`.`scanned_at`) AS `last_scan` from (((`qr_codes` `qr` join `production_batches` `pb` on((`pb`.`batch_id` = `qr`.`batch_id`))) join `factories` `f` on((`f`.`factory_id` = `pb`.`factory_id`))) left join `scan_log` `sl` on((`sl`.`qr_id` = `qr`.`qr_id`))) group by `qr`.`qr_id`,`pb`.`batch_number`,`f`.`manufacturer_id`,`qr`.`code`,`qr`.`issued_at` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_batch_status_counts`
--

/*!50001 DROP VIEW IF EXISTS `v_batch_status_counts`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_batch_status_counts` AS select `pb`.`status` AS `status`,count(0) AS `batch_count` from `production_batches` `pb` group by `pb`.`status` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_batch_tests`
--

/*!50001 DROP VIEW IF EXISTS `v_batch_tests`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_batch_tests` AS select `pb`.`batch_number` AS `batch_number`,`qtr`.`test_date` AS `test_date`,`qtr`.`purity_pct` AS `purity`,`qtr`.`dissolution_pct` AS `dissolution`,`qtr`.`weight_variation_pct` AS `weight_variation`,`qtr`.`result` AS `result`,`qtr`.`remarks` AS `remarks` from (`quality_test_reports` `qtr` join `production_batches` `pb` on((`pb`.`batch_id` = `qtr`.`batch_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_batch_timeline`
--

/*!50001 DROP VIEW IF EXISTS `v_batch_timeline`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_batch_timeline` AS select `pb`.`batch_number` AS `batch_number`,`f`.`manufacturer_id` AS `manufacturer_id`,cast(`pb`.`manufacture_date` as datetime) AS `event_time`,(convert('BATCH_MANUFACTURED' using utf8mb4) collate utf8mb4_unicode_ci) AS `event_type`,(convert(concat('Batch manufactured with ',`pb`.`quantity_units`,' units.') using utf8mb4) collate utf8mb4_unicode_ci) AS `description` from (`production_batches` `pb` join `factories` `f` on((`f`.`factory_id` = `pb`.`factory_id`))) union all select `pb`.`batch_number` AS `batch_number`,`f`.`manufacturer_id` AS `manufacturer_id`,cast(`md`.`received_date` as datetime) AS `event_time`,(convert('MATERIAL_RECEIVED' using utf8mb4) collate utf8mb4_unicode_ci) AS `event_type`,(convert(concat('Raw material ',`ing`.`ingredient_name`,' (',`md`.`quantity_kg`,' kg, Cert: ',coalesce(`md`.`certificate_number`,'N/A'),') received from ',`s`.`supplier_name`,'.') using utf8mb4) collate utf8mb4_unicode_ci) AS `description` from (((((`batch_materials` `bm` join `production_batches` `pb` on((`pb`.`batch_id` = `bm`.`batch_id`))) join `factories` `f` on((`f`.`factory_id` = `pb`.`factory_id`))) join `material_deliveries` `md` on((`md`.`delivery_id` = `bm`.`delivery_id`))) join `ingredients` `ing` on((`ing`.`ingredient_id` = `md`.`ingredient_id`))) join `suppliers` `s` on((`s`.`supplier_id` = `md`.`supplier_id`))) union all select `pb`.`batch_number` AS `batch_number`,`f`.`manufacturer_id` AS `manufacturer_id`,cast(`pb`.`manufacture_date` as datetime) AS `event_time`,(convert('MATERIAL_LINKED' using utf8mb4) collate utf8mb4_unicode_ci) AS `event_type`,(convert(concat('Linked ',`bm`.`quantity_used_kg`,' kg of ',`ing`.`ingredient_name`,' (Cert: ',coalesce(`md`.`certificate_number`,'N/A'),') to batch.') using utf8mb4) collate utf8mb4_unicode_ci) AS `description` from ((((`batch_materials` `bm` join `production_batches` `pb` on((`pb`.`batch_id` = `bm`.`batch_id`))) join `factories` `f` on((`f`.`factory_id` = `pb`.`factory_id`))) join `material_deliveries` `md` on((`md`.`delivery_id` = `bm`.`delivery_id`))) join `ingredients` `ing` on((`ing`.`ingredient_id` = `md`.`ingredient_id`))) union all select `pb`.`batch_number` AS `batch_number`,`f`.`manufacturer_id` AS `manufacturer_id`,cast(`qtr`.`test_date` as datetime) AS `event_time`,(convert('QA_TEST' using utf8mb4) collate utf8mb4_unicode_ci) AS `event_type`,(convert(concat('Quality test completed. Result: ',`qtr`.`result`,'. Purity: ',convert(coalesce(concat(`qtr`.`purity_pct`,'%'),'N/A') using utf8mb4),', Dissolution: ',convert(coalesce(concat(`qtr`.`dissolution_pct`,'%'),'N/A') using utf8mb4),'.') using utf8mb4) collate utf8mb4_unicode_ci) AS `description` from ((`quality_test_reports` `qtr` join `production_batches` `pb` on((`pb`.`batch_id` = `qtr`.`batch_id`))) join `factories` `f` on((`f`.`factory_id` = `pb`.`factory_id`))) union all select `pb`.`batch_number` AS `batch_number`,`f`.`manufacturer_id` AS `manufacturer_id`,min(`qr`.`issued_at`) AS `event_time`,(convert('QR_ISSUED' using utf8mb4) collate utf8mb4_unicode_ci) AS `event_type`,(convert(concat(count(`qr`.`qr_id`),' serialized QR codes generated and issued.') using utf8mb4) collate utf8mb4_unicode_ci) AS `description` from ((`qr_codes` `qr` join `production_batches` `pb` on((`pb`.`batch_id` = `qr`.`batch_id`))) join `factories` `f` on((`f`.`factory_id` = `pb`.`factory_id`))) group by `pb`.`batch_id`,`pb`.`batch_number`,`f`.`manufacturer_id` union all select `pb`.`batch_number` AS `batch_number`,`f`.`manufacturer_id` AS `manufacturer_id`,`al`.`logged_at` AS `event_time`,(convert(`al`.`action` using utf8mb4) collate utf8mb4_unicode_ci) AS `event_type`,(convert(`al`.`details` using utf8mb4) collate utf8mb4_unicode_ci) AS `description` from ((`audit_logs` `al` join `production_batches` `pb` on((`pb`.`batch_id` = `al`.`record_id`))) join `factories` `f` on((`f`.`factory_id` = `pb`.`factory_id`))) where ((`al`.`table_name` = 'Production_Batches') and (`al`.`action` like 'STATUS_%')) union all select `pb`.`batch_number` AS `batch_number`,`f`.`manufacturer_id` AS `manufacturer_id`,cast(`pr`.`recall_date` as datetime) AS `event_time`,(convert('RECALL_ISSUED' using utf8mb4) collate utf8mb4_unicode_ci) AS `event_type`,(convert(concat('Batch recalled. Reason: ',`pr`.`reason`) using utf8mb4) collate utf8mb4_unicode_ci) AS `description` from ((`product_recalls` `pr` join `production_batches` `pb` on((`pb`.`batch_id` = `pr`.`batch_id`))) join `factories` `f` on((`f`.`factory_id` = `pb`.`factory_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_batch_traceability`
--

/*!50001 DROP VIEW IF EXISTS `v_batch_traceability`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_batch_traceability` AS select `pb`.`batch_number` AS `batch_number`,`m`.`brand_name` AS `medicine`,`ing`.`ingredient_name` AS `material`,`s`.`supplier_name` AS `supplier`,`md`.`certificate_number` AS `certificate_number`,`md`.`quantity_kg` AS `delivered_kg`,`bm`.`quantity_used_kg` AS `used_kg`,`md`.`received_date` AS `received_date` from (((((`production_batches` `pb` join `medicines` `m` on((`m`.`medicine_id` = `pb`.`medicine_id`))) join `batch_materials` `bm` on((`bm`.`batch_id` = `pb`.`batch_id`))) join `material_deliveries` `md` on((`md`.`delivery_id` = `bm`.`delivery_id`))) join `ingredients` `ing` on((`ing`.`ingredient_id` = `md`.`ingredient_id`))) join `suppliers` `s` on((`s`.`supplier_id` = `md`.`supplier_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_dashboard`
--

/*!50001 DROP VIEW IF EXISTS `v_dashboard`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_dashboard` AS select (select count(0) from `production_batches` where (`production_batches`.`status` = 'Approved')) AS `approved_batches`,(select count(0) from `quality_test_reports` where (`quality_test_reports`.`result` = 'Fail')) AS `failed_tests`,(select count(0) from `scan_log` where (`scan_log`.`verdict` = 'Suspicious')) AS `suspicious_scans`,(select count(0) from `product_recalls`) AS `recalls` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_demo_codes`
--

/*!50001 DROP VIEW IF EXISTS `v_demo_codes`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_demo_codes` AS select `t_gen`.`demo_type` AS `demo_type`,`t_gen`.`code` AS `code`,`t_gen`.`batch_number` AS `batch_number` from (select 'Genuine' AS `demo_type`,`qr`.`code` AS `code`,`pb`.`batch_number` AS `batch_number` from (`qr_codes` `qr` join `production_batches` `pb` on((`pb`.`batch_id` = `qr`.`batch_id`))) where ((`pb`.`status` = 'Approved') and (`pb`.`expiry_date` >= curdate())) order by `pb`.`manufacture_date` limit 1) `t_gen` union all select `t_exp`.`demo_type` AS `demo_type`,`t_exp`.`code` AS `code`,`t_exp`.`batch_number` AS `batch_number` from (select 'Expired' AS `demo_type`,`qr`.`code` AS `code`,`pb`.`batch_number` AS `batch_number` from (`qr_codes` `qr` join `production_batches` `pb` on((`pb`.`batch_id` = `qr`.`batch_id`))) where ((`pb`.`status` = 'Approved') and (`pb`.`expiry_date` < curdate())) order by `pb`.`expiry_date` limit 1) `t_exp` union all select `t_rec`.`demo_type` AS `demo_type`,`t_rec`.`code` AS `code`,`t_rec`.`batch_number` AS `batch_number` from (select 'Recalled' AS `demo_type`,`qr`.`code` AS `code`,`pb`.`batch_number` AS `batch_number` from (`qr_codes` `qr` join `production_batches` `pb` on((`pb`.`batch_id` = `qr`.`batch_id`))) where (`pb`.`status` = 'Recalled') order by `pb`.`batch_id` limit 1) `t_rec` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_form_factories`
--

/*!50001 DROP VIEW IF EXISTS `v_form_factories`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_form_factories` AS select `factories`.`manufacturer_id` AS `manufacturer_id`,`factories`.`factory_name` AS `factory_name` from `factories` order by `factories`.`factory_name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_form_ingredients`
--

/*!50001 DROP VIEW IF EXISTS `v_form_ingredients`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_form_ingredients` AS select `ingredients`.`ingredient_name` AS `ingredient_name` from `ingredients` order by `ingredients`.`ingredient_name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_form_medicines`
--

/*!50001 DROP VIEW IF EXISTS `v_form_medicines`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_form_medicines` AS select `medicines`.`manufacturer_id` AS `manufacturer_id`,`medicines`.`brand_name` AS `brand_name` from `medicines` order by `medicines`.`brand_name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_form_suppliers`
--

/*!50001 DROP VIEW IF EXISTS `v_form_suppliers`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_form_suppliers` AS select `suppliers`.`supplier_name` AS `supplier_name` from `suppliers` order by `suppliers`.`supplier_name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_my_deliveries`
--

/*!50001 DROP VIEW IF EXISTS `v_my_deliveries`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_my_deliveries` AS select `md`.`manufacturer_id` AS `manufacturer_id`,`md`.`certificate_number` AS `certificate_number`,`ing`.`ingredient_name` AS `ingredient_name`,`s`.`supplier_name` AS `supplier_name`,`md`.`received_date` AS `received_date`,`md`.`quantity_kg` AS `quantity_kg`,coalesce(sum(`bm`.`quantity_used_kg`),0) AS `used_kg`,(`md`.`quantity_kg` - coalesce(sum(`bm`.`quantity_used_kg`),0)) AS `remaining_kg` from (((`material_deliveries` `md` join `ingredients` `ing` on((`ing`.`ingredient_id` = `md`.`ingredient_id`))) join `suppliers` `s` on((`s`.`supplier_id` = `md`.`supplier_id`))) left join `batch_materials` `bm` on((`bm`.`delivery_id` = `md`.`delivery_id`))) group by `md`.`delivery_id`,`md`.`manufacturer_id`,`md`.`certificate_number`,`ing`.`ingredient_name`,`s`.`supplier_name`,`md`.`received_date`,`md`.`quantity_kg` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_recall_list`
--

/*!50001 DROP VIEW IF EXISTS `v_recall_list`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_recall_list` AS select `pr`.`recall_id` AS `recall_id`,`pb`.`batch_number` AS `batch_number`,`m`.`brand_name` AS `medicine`,`mfr`.`company_name` AS `manufacturer`,`pr`.`reason` AS `reason`,`pr`.`recall_date` AS `recall_date`,`u`.`email` AS `issued_by_email`,(select count(0) from `qr_codes` `qr` where (`qr`.`batch_id` = `pb`.`batch_id`)) AS `qr_count`,(select count(0) from (`scan_log` `sl` join `qr_codes` `qr` on((`qr`.`qr_id` = `sl`.`qr_id`))) where (`qr`.`batch_id` = `pb`.`batch_id`)) AS `total_scans`,(select count(0) from (`scan_log` `sl` join `qr_codes` `qr` on((`qr`.`qr_id` = `sl`.`qr_id`))) where ((`qr`.`batch_id` = `pb`.`batch_id`) and (`sl`.`scanned_at` >= cast(`pr`.`recall_date` as datetime)))) AS `scans_after_recall` from (((((`product_recalls` `pr` join `production_batches` `pb` on((`pb`.`batch_id` = `pr`.`batch_id`))) join `medicines` `m` on((`m`.`medicine_id` = `pb`.`medicine_id`))) join `factories` `f` on((`f`.`factory_id` = `pb`.`factory_id`))) join `manufacturers` `mfr` on((`mfr`.`manufacturer_id` = `f`.`manufacturer_id`))) join `users` `u` on((`u`.`user_id` = `pr`.`issued_by`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_recent_audit`
--

/*!50001 DROP VIEW IF EXISTS `v_recent_audit`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_recent_audit` AS select `al`.`log_id` AS `log_id`,`al`.`user_id` AS `user_id`,`u`.`full_name` AS `user_name`,`al`.`action` AS `action`,`al`.`table_name` AS `table_name`,`al`.`record_id` AS `record_id`,`al`.`details` AS `details`,`al`.`logged_at` AS `logged_at` from (`audit_logs` `al` left join `users` `u` on((`u`.`user_id` = `al`.`user_id`))) order by `al`.`logged_at` desc,`al`.`log_id` desc limit 20 */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_suspicious_codes`
--

/*!50001 DROP VIEW IF EXISTS `v_suspicious_codes`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_suspicious_codes` AS select `sl`.`scanned_code` AS `scanned_code`,count(0) AS `scan_count`,min(`sl`.`scanned_at`) AS `first_scan`,max(`sl`.`scanned_at`) AS `last_scan` from `scan_log` `sl` group by `sl`.`scanned_code` having (count(0) > 5) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-13 22:14:34

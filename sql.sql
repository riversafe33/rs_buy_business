CREATE TABLE IF NOT EXISTS `business_owners` (
  `business_id` int(11) NOT NULL,
  `owner_id` varchar(255) NOT NULL,
  PRIMARY KEY (`business_id`,`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

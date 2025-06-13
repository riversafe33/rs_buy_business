CREATE TABLE IF NOT EXISTS `business_owners` (
  `business_id` INT(11) NOT NULL,
  `owner_id` VARCHAR(255) NOT NULL,
  `charid` INT(11) NOT NULL,
  PRIMARY KEY (`business_id`, `owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

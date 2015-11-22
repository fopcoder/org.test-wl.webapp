SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS `actor`;
CREATE TABLE `actor` (
  `actor_id` int(11) NOT NULL AUTO_INCREMENT,
  `actor_name` varchar(200) NOT NULL,
  PRIMARY KEY (`actor_id`),
  UNIQUE KEY `actor_name` (`actor_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `film`;
CREATE TABLE `film` (
  `film_id` int(11) NOT NULL AUTO_INCREMENT,
  `film_name` varchar(100) NOT NULL,
  `film_year` smallint(6) NOT NULL,
  `format_id` tinyint(4) NOT NULL,
  PRIMARY KEY (`film_id`),
  UNIQUE KEY `film_year` (`film_name`,`film_year`),
  KEY `format_id` (`format_id`),
  CONSTRAINT `film_ibfk_1` FOREIGN KEY (`format_id`) REFERENCES `format` (`format_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `film_actor`;
CREATE TABLE `film_actor` (
  `film_id` int(11) NOT NULL,
  `actor_id` int(11) NOT NULL,
  PRIMARY KEY (`film_id`,`actor_id`),
  KEY `actor_id` (`actor_id`),
  CONSTRAINT `film_actor_ibfk_1` FOREIGN KEY (`film_id`) REFERENCES `film` (`film_id`),
  CONSTRAINT `film_actor_ibfk_2` FOREIGN KEY (`actor_id`) REFERENCES `actor` (`actor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `format`;
CREATE TABLE `format` (
  `format_id` tinyint(4) NOT NULL AUTO_INCREMENT,
  `format_name` varchar(20) NOT NULL,
  PRIMARY KEY (`format_id`),
  UNIQUE KEY `format_name` (`format_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `format` WRITE;
INSERT INTO `format` VALUES (3,'Blu-Ray'),(2,'DVD'),(1,'VHS');
UNLOCK TABLES;

SET FOREIGN_KEY_CHECKS=1;
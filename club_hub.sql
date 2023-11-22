CREATE TABLE `club` (
    `club_id` INT NOT NULL,
    `club_name` VARCHAR(20) NOT NULL,
    `brief` VARCHAR(50) NOT NULL,
    `passcode` VARCHAR(20) NOT NULL,
    `head_srn` VARCHAR(10) NOT NULL,
    PRIMARY KEY(`club_id`)
);

CREATE TABLE `club_heads` (
    `club_id` INT NOT NULL,
    `head` VARCHAR(30) NOT NULL,
    PRIMARY KEY(`club_id`, `head`),
    FOREIGN KEY(`club_id`) REFERENCES `club`(`club_id`)
);
    
CREATE TABLE `club_events` (
    `event_id` INT NOT NULL AUTO_INCREMENT,
    `club_id` INT NOT NULL,
    `event_name` VARCHAR(20) NOT NULL,
    `start_time` TIME DEFAULT CURRENT_TIMESTAMP,
    `end_time` TIME DEFAULT CURRENT_TIMESTAMP,
    `duration` FLOAT(2,2) NOT NULL,
    `venue` VARCHAR(20) NOT NULL,
    `event_date` DATE ,
    `reg_fee` INT,
    PRIMARY KEY(`event_id`)
);

CREATE TABLE `event_venue`(
	`venue` VARCHAR(20) NOT NULL,
    `event_date` DATE,
    `start_time` TIME DEFAULT CURRENT_TIMESTAMP, 
    `end_time` TIME DEFAULT CURRENT_TIMESTAMP,
    `duration` FLOAT(2,2) NOT NULL, #derived attribute 
    `availability` BOOL DEFAULT '0', 
    
    PRIMARY KEY(`venue`,`event_date`,`start_time`)
);

CREATE TABLE `registration`(
	`reg_id` INT NOT NULL, 
    `srn` VARCHAR(10) NOT NULL,
    `stud_name` VARCHAR(30),
    `email_id` VARCHAR(40) NOT NULL,
    `ph_no` INT NOT NULL,
    `trans_id` INT, #if registration requires payment
    `event_id` INT NOT NULL, 
    `reg_fee` INT,
    
    PRIMARY KEY(`reg_id`)
);

CREATE TABLE `club_membership`(
	`srn` INT NOT NULL, 
    `club_id` INT NOT NULL, 
    `designation` VARCHAR(20) NOT NULL, 
    `join_date` DATE DEFAULT(CURRENT_DATE),
    PRIMARY KEY(`srn`,`club_id`)
);

CREATE TABLE `admin_deets`(
	`admin_id` INT NOT NULL,
    `passcode` VARCHAR(30) NOT NULL,
    `email_id` VARCHAR(40) NOT NULL,
    
    PRIMARY KEY(`admin_id`)
);

CREATE TABLE `student`(
	`gpa` DOUBLE(2,2) NOT NULL,
    `srn` VARCHAR(10) NOT NULL,
    `email_id` VARCHAR(40) NOT NULL,
    `ph_no` INT NOT NULL,
    `l_name` VARCHAR(20) NOT NULL,
    `f_name` VARCHAR(20) NOT NULL,
    `passcode` VARCHAR(30) NOT NULL,
    
    PRIMARY KEY(`srn`)
);

CREATE TABLE `student_club_ID`(
	`srn` VARCHAR(10) NOT NULL,
    `club_ID` INT,
    
    PRIMARY KEY(`srn`,`club_ID`),
    FOREIGN KEY(`club_ID`) REFERENCES student(club_ID)
);

DELIMITER //
CREATE TRIGGER `update_availability`
AFTER INSERT ON `club_events`
FOR EACH ROW
BEGIN
    DECLARE existing_availability BOOL;

    -- Check if the venue is currently occupied
    SELECT `availability` INTO existing_availability
    FROM `event_venue`
    WHERE `venue` = NEW.`venue`
        AND `event_date` = NEW.`event_date`
        AND `start_time` = NEW.`start_time`;

    -- Update availability only if the venue is currently marked as unavailable
    IF existing_availability IS NULL OR existing_availability = 0 THEN
        INSERT INTO `event_venue` (`venue`, `event_date`, `start_time`, `end_time`, `duration`, `availability`)
        VALUES (NEW.`venue`, NEW.`event_date`, NEW.`start_time`, NEW.`end_time`, NEW.`duration`, 1)
        ON DUPLICATE KEY UPDATE `availability` = 1;
	ELSE 
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Venue and timings are already taken by another event.';
    END IF;
END;
//

CREATE TRIGGER `delete_student_membership`
BEFORE DELETE ON `student`
FOR EACH ROW
BEGIN
    DELETE FROM `club_membership` WHERE `srn` = OLD.`srn`;
END;
//

CREATE TRIGGER `update_club_head`
AFTER UPDATE ON `club_heads`
FOR EACH ROW
BEGIN
    UPDATE `club` SET `head_srn` = NEW.`head_srn` WHERE `club_id` = NEW.`club_id`;
END;
//

CREATE TRIGGER `registration_fee`
BEFORE INSERT ON `registration`
FOR EACH ROW
BEGIN
    DECLARE reg_fee_value INT;

    SELECT reg_fee INTO reg_fee_value FROM `club_events` WHERE `event_id` = NEW.`event_id`;

    IF reg_fee_value = 0 THEN
        SET NEW.`trans_id` = NULL;
    END IF;
END;
//
DELIMITER ;

SELECT * FROM student s 
INNER JOIN student_club_ID sc 
ON s.srn=sc.srn;

SELECT * FROM club c
INNER JOIN club_heads ch
ON c.club_id=ch.club_id;

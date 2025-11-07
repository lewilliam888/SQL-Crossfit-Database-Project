-- William Le
-- Crossfit ETL and Queries

use crossfit;

-- Creates country table and sets primary key
CREATE TABLE `country` (
	`countryofOriginCode` VARCHAR(10) NOT NULL,
    `countryofOriginName` VARCHAR(100),
    `countryPopulation` INT,
    PRIMARY KEY(`countryofOriginCode`)
);

-- Inserts data from crossfit_athletes table into the new country table
INSERT INTO `country`(`countryofOriginCode`, `countryofOriginName`, `countryPopulation`)
SELECT DISTINCT 
	`countryofOriginCode`, 
    `countryofOriginName`, 
    `countryPopulation`
FROM `crossfit_athletes`;

-- Creates affiliate table and sets primary key
CREATE TABLE `affiliate` (
	`affiliateID` INT NOT NULL,
    `affiliateName` VARCHAR(255),
    PRIMARY KEY(`affiliateID`)
);

-- Inserts data from crossfit_athletes table into the new affiliate table
INSERT INTO `affiliate`(`affiliateID`, `affiliateName`)
SELECT DISTINCT
	`affiliateID`,
    `affiliateName`
FROM `crossfit_athletes`
WHERE `affiliateid` IS NOT NULL AND `affiliateid` != '';

-- Creates division table and sets primary key
CREATE TABLE `division` (
	`divisionID` INT NOT NULL AUTO_INCREMENT,
    `divisionName` VARCHAR(255),
    PRIMARY KEY(`divisionID`)
);

-- Inserts data from crossfit_athletes table into the new division table
INSERT INTO `division`(`divisionName`)
SELECT DISTINCT
    `division`
FROM `crossfit_athletes`
WHERE `division` IS NOT NULL AND `division` != ''
GROUP BY `division`;

-- Creates status table
CREATE TABLE `status` (
	`statusID` INT NOT NULL AUTO_INCREMENT,
    `statusName` VARCHAR(255),
    PRIMARY KEY(`statusID`)
);

-- Inserts data from crossfit_athletes table into the new status table
INSERT INTO `status`(`statusName`)
SELECT DISTINCT
    `status`
FROM `crossfit_athletes`
WHERE `status` IS NOT NULL AND `status` != ''
GROUP BY `status`;

-- Creates competitor table and sets primary key
CREATE TABLE `competitor` (
	`height` FLOAT,
    `affiliateID` INT,
    `weight` FLOAT,
    `statusID` INT,
    `bibID` INT,
    `competitorID` INT NOT NULL,
    `firstName` VARCHAR(255),
    `gender` VARCHAR(255),
    `age` INT,
    `lastName` VARCHAR(255),
    `countryofOriginCode` VARCHAR(255),
    `overallRank` VARCHAR(5),
    `overallScore` INT,
    `divisionID` INT,
    PRIMARY KEY(`competitorID`)
);

-- Inserts data from crossfit_athletes table into the new competitor table
INSERT INTO `competitor`(`height`, `affiliateID`, `weight`, `statusID`, `bibID`, `competitorID`, `firstName`, 
`gender`, `age`, `lastName`, `countryofOriginCode`, `overallRank`, `overallScore`, `divisionID`)
SELECT DISTINCT
	a.`height`, a.`affiliateID`, a.`weight`, s.`statusID`, a.`bibID`, a.`competitorID`, a.`firstName`, 
	a.`gender`, a.`age`, a.`lastName`, a.`countryofOriginCode`, a.`overallRank`, a.`overallScore`, d.`divisionID`
FROM `crossfit_athletes` a
LEFT JOIN `status` AS s ON a.`status` = s.`statusName`
LEFT JOIN `division` AS d ON a.`division` = d.`divisionName`;

-- Creates score table and sets primary key
CREATE TABLE `score` (
	`workoutIDforDivision` INT NOT NULL,
    `breakdown` VARCHAR(100),
    `lane` INT,
    `rank` VARCHAR(10),
    `heat` INT,
    `points` INT,
    `scoreDisplay` VARCHAR(100),
    `time` VARCHAR(100),
    `workoutRank` VARCHAR(10),
    `competitorID` INT NOT NULL,
    `year` INT,
    PRIMARY KEY(`workoutIDforDivision`, `competitorID`, `year`)
);

-- Inserts data from crossfit_scores table into the new score table
INSERT INTO `score`(`workoutIDforDivision`, `breakdown`, `lane`, `rank`, `heat`, 
	`points`, `scoreDisplay`, `time`, `workoutrank`, `competitorID`, `year`)
SELECT DISTINCT
	`workoutIDforDivision`, `breakdown`, `lane`, `rank`, `heat`, 
    `points`, `scoredisplay`, `time`, `workoutrank`, `competitorid`, `year`
FROM `crossfit_scores`;

-- Adds foreign keys to competitor table
ALTER TABLE `competitor`
ADD CONSTRAINT affiliateID FOREIGN KEY (affiliateID)
REFERENCES affiliate(affiliateID);

ALTER TABLE `competitor`
ADD CONSTRAINT statusID FOREIGN KEY (statusID)
REFERENCES status(statusID);

ALTER TABLE `competitor`
ADD CONSTRAINT countryofOriginCode FOREIGN KEY (countryofOriginCode)
REFERENCES country(countryofOriginCode);

ALTER TABLE `competitor`
ADD CONSTRAINT divisionID FOREIGN KEY (divisionID)
REFERENCES division(divisionID);

-- Prints affiliate table
SELECT * FROM `affiliate`;

-- Prints competitor table
SELECT * FROM `competitor`;

-- Prints country table
SELECT * FROM `country`;

-- Prints division table
SELECT * FROM `division`;

-- Prints score table
SELECT * FROM `score`;

-- Prints status
SELECT * FROM `status`;

-- Lists the top competitor for 2019 with their country name in terms of overall score* 
SELECT c.`firstName`, c.`lastName`, cu.`countryofOriginName`, c.`overallScore`
FROM `competitor` c
INNER JOIN `country` AS cu ON c.`countryofOriginCode` = cu.`countryofOriginCode`
ORDER BY c.`overallScore` DESC
LIMIT 10;

-- Show the inactive competitors for 2019
SELECT c.`firstName`, c.`lastName`, s.`statusName`
FROM `competitor` c
INNER JOIN `status` AS s ON c.`statusID` = s.`statusID`
WHERE s.`statusName` = 'CUT' OR s.`statusName` = 'WD';

-- Show the total points earned by country, with the highest total points showing first. Show the population for each country also.
SELECT cu.`countryofOriginName`, cu.`countryPopulation`, sum(s.`points`) AS totalPoints
FROM `score` s
INNER JOIN `competitor` AS c ON s.`competitorID` = c.`competitorID`
INNER JOIN `country` AS cu ON c.`countryOfOriginCode` = cu.`countryOfOriginCode`
GROUP BY cu.`countryofOriginName`, cu.`countryPopulation`
ORDER BY totalPoints DESC;

-- Who are the ten best athletes in the Men (35-39) Division in terms of overall score?
SELECT c.`firstName`, c.`lastName`, c.`overallScore`, d.`divisionName`
FROM `competitor` c
INNER JOIN `division` AS d ON c.`divisionID` = d.`divisionID`
WHERE d.`divisionID` = '2'
ORDER BY `overallScore` DESC
LIMIT 10;

-- Who are the athletes from countries whose country names end in land? Use REGEXP to filter the data.
SELECT c.`firstName`, c.`lastName`, cu.`countryofOriginName`
FROM `competitor` c
INNER JOIN `country` AS cu ON c.`countryOfOriginCode` = cu.`countryofOriginCode`
WHERE cu.`countryofOriginName` REGEXP 'land$';

-- Who are the athletes with the highest score from the United States who was cut from the crossfit games?
SELECT c.`firstName`, c.`lastName`, c.`overallScore`, cu.`countryofOriginName`, s.`statusName`
FROM `competitor` c
INNER JOIN `country` AS cu ON c.`countryOfOriginCode` = cu.`countryofOriginCode`
INNER JOIN `status` AS s ON c.`statusID` = s.`statusID`
WHERE `statusName` = 'CUT' AND `countryofOriginName` = 'United States'
ORDER BY c.`overallScore` DESC;

-- What is the average overallscore for each division and how many athletes are in each division?
SELECT d.`divisionName`, COUNT(c.`competitorID`) AS totalAthletes, AVG(c.overallScore) as averageScore
FROM `competitor` c
INNER JOIN `division` AS d ON c.`divisionID` = d.`divisionID`
WHERE c.overallScore
GROUP BY d.`divisionName`
ORDER BY averageScore DESC;

-- Which competitors scored higher than the average overallscore of all athletes in the 'Men (40-44)' division?
SELECT c.`firstName`, c.`lastName`, c.`overallScore`, d.`divisionName`
FROM `competitor` c
INNER JOIN `division` AS d ON c.`divisionID` = d.`divisionID`
WHERE c.`overallScore` > (
	SELECT AVG(co.`overallScore`)
    FROM `competitor` co
    INNER JOIN `division` AS di ON co.`divisionID` = di.`divisionID`
    WHERE di.`divisionID` = '3'
)
AND d.`divisionID` = '3'
ORDER BY c.`overallScore` DESC;

-- Which competitors train at an affiliate gym that has the word 'CrossFit' anywhere in its name
SELECT c.`firstName`, c.`lastName`, a.`affiliateName`
FROM `competitor` c
INNER JOIN `affiliate` AS a ON c.`affiliateID` = a.`affiliateID`
WHERE a.`affiliateName` LIKE '%Crossfit%';


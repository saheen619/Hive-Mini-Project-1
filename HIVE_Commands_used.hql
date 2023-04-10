-- 1. Create a schema based on the given dataset.

-- SCHEMA FOR AgentLogingReport.csv

USE projects;
CREATE TABLE agentlogingreport
(
sl_no int,
agent_name string,
date string,
login_time string,
logout_time string,
duration string
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
TBLPROPERTIES ("skip.header.line.count"="1");


--SCHEMA FOR AgentPerformance.csv

CREATE TABLE agentperformance
(
sl_no int,
date string,
agent_name string,
total_chats int,
avg_response_time string,
avg_resolution_time string,
avg_rating float,
total_feedback int
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
TBLPROPERTIES ("skip.header.line.count"="1");


-- 2. Dump the data inside the hdfs in the given schema location.

-- FOR TABLE agentlogingreport

LOAD DATA LOCAL INPATH 'file:///tmp/agentlogingreport.csv' INTO TABLE agentlogingreport;

INSERT OVERWRITE TABLE agentlogingreport
SELECT sl_no, agent_name,
from_unixtime(unix_timestamp(date,'dd-MMM-yy'),'yyyy-MM-dd'),
from_unixtime(unix_timestamp(concat(date,login_time),'dd-MMM-yyHH:mm:ss'),'yyyy-MM-dd HH:mm:ss'),
from_unixtime(unix_timestamp(concat(date,logout_time),'dd-MMM-yyHH:mm:ss'),'yyyy-MM-dd HH:mm:ss'),
from_unixtime(unix_timestamp(concat(date,duration),'dd-MMM-yyHH:mm:ss'),'yyyy-MM-dd HH:mm:ss')
FROM agentlogingreport;


-- FOR TABLE agentperformance

LOAD DATA LOCAL INPATH 'file:///tmp/agentperformance.csv' INTO TABLE agentperformance;

INSERT OVERWRITE TABLE agentperformance
SELECT sl_no,
from_unixtime(unix_timestamp(date,'M/dd/yyyy'),'yyyy-MM-dd'),
agent_name,
total_chats,
from_unixtime(unix_timestamp(concat(date,avg_response_time),'M/dd/yyyyHH:mm:ss'),'yyyy-MM-dd HH:mm:ss'),
from_unixtime(unix_timestamp(concat(date,avg_resolution_time),'M/dd/yyyyHH:mm:ss'),'yyyy-MM-dd HH:mm:ss'),
avg_rating,
total_feedback
FROM agentperformance;


-- 3. List of all agents' names.

SELECT DISTINCT agent_name 
FROM agentperformance;


-- 4. Find out agent average rating.

SELECT agent_name, ROUND(AVG(avg_rating),2) AS avg_rating 
FROM agentperformance 
GROUP BY agent_name;


-- 5. Total working days for each agents 

SELECT agent_name,
COUNT(DISTINCT date) AS total_working_days 
FROM agentlogingreport 
GROUP BY agent_name;


-- 6. Total query that each agent have taken 

SELECT agent_name, SUM(total_chats) AS total_query 
FROM agentperformance 
GROUP BY agent_name;


-- 7. Total Feedback that each agent have received 

SELECT agent_name, SUM(total_feedback) AS total_feedbacks 
FROM agentperformance 
GROUP BY agent_name;


-- 8. Agent name who have average rating between 3.5 to 4 

SELECT agent_name, ROUND(AVG(avg_rating),2) 
FROM agentperformance 
WHERE avg_rating BETWEEN 3.5 AND 4 
GROUP BY agent_name;


-- 9. Agent name who have rating less than 3.5 

SELECT agent_name, ROUND(AVG(avg_rating),2) 
FROM agentperformance 
GROUP BY agent_name 
HAVING AVG(avg_rating) < 3.5;


-- 10. Agent name who have rating more than 4.5 

SELECT agent_name, ROUND(AVG(avg_rating),2) 
FROM agentperformance 
WHERE avg_rating > 4.5 
GROUP BY agent_name;


-- 11. How many feedback agents have received more than 4.5 average

SELECT agent_name, COUNT(avg_rating) 
FROM agentperformance 
WHERE avg_rating > 4.5 
GROUP BY agent_name;


-- 12. average weekly response time (in minutes) for each agent

WITH weekresponse AS(
SELECT agent_name, WEEKOFYEAR(date) AS week,
(HOUR(avg_response_time)*3600 + MINUTE(avg_response_time)*60 + SECOND(avg_response_time))/60 AS response2
FROM agentperformance)
SELECT agent_name, week, ROUND(AVG(response2),2) as avg_response_in_minutes
FROM weekresponse
GROUP BY agent_name, week;


-- 13. average weekly resolution time (in minutes) for each agents 

WITH weeklyresolution AS(
SELECT agent_name, WEEKOFYEAR(date) AS week,
(HOUR(avg_resolution_time)*3600 + MINUTE(avg_resolution_time)*60 + SECOND(avg_resolution_time))/60 AS resolution_time
FROM agentperformance)
SELECT agent_name, week, ROUND(AVG(resolution_time),2) AS avg_resolution_in_minutes
FROM weeklyresolution
GROUP BY agent_name, week;


-- 14. Find the number of chat on which they have received a feedback 

SELECT agent_name, SUM(total_chats), total_feedback 
FROM agentperformance 
WHERE total_feedback!=0 
GROUP BY agent_name;


-- 15. Total contribution hour for each and every agents weekly basis 

WITH weeklycontribution AS(
SELECT agent_name, WEEKOFYEAR(date) AS WEEK,
(HOUR(duration)*3600 + MINUTE(duration)*60 + SECOND(duration))/3600 AS hours
FROM agentlogingreport)
SELECT agent_name, week, ROUND(SUM(hours),2) AS contribution_hours
FROM weeklycontribution
GROUP BY agent_name, week;


-- 16. Perform inner join, left join and right join based on the agent column and after joining the table export that data into your local system.

-- INNER JOIN

SELECT alr.sl_no, alr.agent_name, alr.date, alr.duration, ap.total_chats, ap.avg_rating, ap.total_feedback
FROM agentlogingreport alr
JOIN
agentperformance ap
ON alr.agent_name = ap.agent_name
LIMIT 30;
    

[cloudera@quickstart ~]$ hive -e 'SELECT alr.sl_no, alr.agent_name, alr.date, alr.duration, ap.total_chats, ap.avg_rating, ap.total_feedback 
FROM projects.agentlogingreport alr JOIN projects.agentperformance ap ON alr.agent_name = ap.agent_name' >/home/cloudera/projects/inner_join.csv;


-- LEFT JOIN

SELECT alr.sl_no, alr.agent_name, alr.date, alr.duration, ap.total_chats, ap.avg_rating, ap.total_feedback
FROM agentlogingreport alr
LEFT JOIN
agentperformance ap
ON alr.agent_name = ap.agent_name
LIMIT 30;


[cloudera@quickstart ~]$ hive -e 'SELECT alr.sl_no, alr.agent_name, alr.date, alr.duration, ap.total_chats, ap.avg_rating, ap.total_feedback 
FROM projects.agentlogingreport alr LEFT JOIN projects.agentperformance ap ON alr.agent_name = ap.agent_name' >/home/cloudera/projects/left_join.csv;


-- RIGHT JOIN

SELECT alr.sl_no, alr.agent_name, alr.date, alr.duration, ap.total_chats, ap.avg_rating, ap.total_feedback
FROM agentlogingreport alr
RIGHT JOIN
agentperformance ap
ON alr.agent_name = ap.agent_name
LIMIT 30;


[cloudera@quickstart ~]$ hive -e 'SELECT alr.sl_no, alr.agent_name, alr.date, alr.duration, ap.total_chats, ap.avg_rating, ap.total_feedback 
FROM projects.agentlogingreport alr RIGHT JOIN projects.agentperformance ap ON alr.agent_name = ap.agent_name' >/home/cloudera/projects/right_join.csv


-- 17. Perform partitioning on top of the agent column and then on top of that perform bucketing for each partitioning.

CREATE TABLE alr_partition_bucket
(
sl_no int,
date string,
login_time string,
logout_time string,
duration string
)PARTITIONED BY(agent_name string)
CLUSTERED BY (date)
SORTED BY (date) INTO 4 BUCKETS
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ',';

SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

INSERT INTO TABLE alr_partition_bucket PARTITION(agent_name) 
SELECT sl_no,date,login_time,logout_time,duration,agent_name FROM agentlogingreport;


-- FOR THE TABLE agentperformance,

CREATE TABLE ap_partition_bucket
(
sl_no int,
date string,
total_chats int,
avg_response_time string,
avg_resolution_time string,
avg_rating float,
total_feedback int
)PARTITIONED BY (agent_name string)
CLUSTERED BY (date)
SORTED BY(date) INTO 8 BUCKETS
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ',';

INSERT INTO TABLE ap_partition_bucket PARTITION(agent_name)
SELECT sl_no, date, total_chats, avg_response_time, avg_resolution_time, avg_rating, total_feedback, agent_name FROM agentperformance;
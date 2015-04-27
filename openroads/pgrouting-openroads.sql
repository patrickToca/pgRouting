-- This SQL script requires a table generated by importing the roadlink shapefile from the Ordnance Survey 
-- Open Roads dataset. This script assumes that the table is named 'roadlink' and is located within
-- a schema named 'openroads'. Due to the size of the roadlink table (some 3.2 million records), this 
-- script will take a considerable length of time to complete - maybe one or two hours.

-- Add columns that will be populated with road speed and time cost
ALTER TABLE openroads.roadlink
    ADD COLUMN speed_mph integer,
    ADD COLUMN cost_time double precision;

-- Rename the existing length column to cost_len
 ALTER TABLE openroads.roadlink   
    RENAME COLUMN length TO cost_len;


-- We need to convert the startnode and endnode columns from varchar to integer as required by pgRouting.
-- First we remove the leading 'L' from the startnode and endnode values.
UPDATE openroads.roadlink set startnode = replace(startnode, 'L', '');
UPDATE openroads.roadlink set endnode = replace(startnode, 'L', '');
-- Second we convert the startnode and endnode columns to integer
ALTER TABLE openroads.roadlink ALTER COLUMN startnode  TYPE integer USING (startnode::integer);
ALTER TABLE openroads.roadlink ALTER COLUMN endnode  TYPE integer USING (endnode::integer);

 -- Rename columns to pgRouting requirements
 -- rename the startnode column to source
ALTER TABLE openroads.roadlink 
    RENAME COLUMN startnode TO source;  
-- rename the endnode column to target
ALTER TABLE openroads.roadlink 
    RENAME COLUMN endnode TO target;

-- update the speed_mph column with average speeds for each road type. These are my initial values,
-- you can set these to whatever you like
UPDATE openroads.roadlink SET speed_mph =
    CASE
	WHEN class = 'A Road' AND formofway = 'Single Carriageway' THEN 55
	WHEN class = 'A Road' AND formofway = 'Dual Carriageway' THEN 60
	WHEN class = 'A Road' AND formofway = 'Collapsed Dual Carriageway' THEN 60
	WHEN class = 'A Road' AND formofway = 'Roundabout' THEN 25
	WHEN class = 'A Road' AND formofway = 'Slip Road' THEN 50
	WHEN class = 'B Road' AND formofway = 'Single Carriageway' THEN 50
	WHEN class = 'B Road' AND formofway = 'Dual Carriageway' THEN 60
	WHEN class = 'B Road' AND formofway = 'Collapsed Dual Carriageway' THEN 60
	WHEN class = 'B Road' AND formofway = 'Roundabout' THEN 25
	WHEN class = 'B Road' AND formofway = 'Slip Road' THEN 50
	WHEN class = 'Motorway' AND formofway = 'Single Carriageway' THEN 70
	WHEN class = 'Motorway' AND formofway = 'Dual Carriageway' THEN 70
	WHEN class = 'Motorway' AND formofway = 'Collapsed Dual Carriageway' THEN 70
	WHEN class = 'Motorway' AND formofway = 'Roundabout' THEN 30
	WHEN class = 'Motorway' AND formofway = 'Slip Road' THEN 60
	WHEN class = 'Not Classified' AND formofway = 'Single Carriageway' THEN 45
	WHEN class = 'Not Classified' AND formofway = 'Dual Carriageway' THEN 55
	WHEN class = 'Not Classified' AND formofway = 'Collapsed Dual Carriageway' THEN 55
	WHEN class = 'Not Classified' AND formofway = 'Roundabout' THEN 25
	WHEN class = 'Not Classified' AND formofway = 'Slip Road' THEN 45
	WHEN class = 'Unclassified' AND formofway = 'Single Carriageway' THEN 45
	WHEN class = 'Unclassified' AND formofway = 'Dual Carriageway' THEN 55
	WHEN class = 'Unclassified' AND formofway = 'Collapsed Dual Carriageway' THEN 55
	WHEN class = 'Unclassified' AND formofway = 'Roundabout' THEN 25
	WHEN class = 'Unclassified' AND formofway = 'Slip Road' THEN 45
	ELSE 1
	END;

-- calculate the cost_time field - here I have calculated estimated journey time in minutes for each link
UPDATE openroads.roadlink SET
	cost_time = (cost_len/1000.0/(speed_mph*1.609344))*60::numeric;

-- create indexes for source and target columns to improve performance
CREATE INDEX roadlink_source_idx ON openroads.roadlink USING btree(source);
CREATE INDEX roadlink_target_idx ON openroads.roadlink USING btree(target);

-- clean-up the table
VACUUM ANALYZE VERBOSE openroads.roadlink;

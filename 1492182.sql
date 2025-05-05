-- __/\\\\\\\\\\\__/\\\\\_____/\\\__/\\\\\\\\\\\\\\\____/\\\\\_________/\\\\\\\\\_________/\\\\\\\________/\\\\\\\________/\\\\\\\________/\\\\\\\\\\________________/\\\\\\\\\_______/\\\\\\\\\_____        
--  _\/////\\\///__\/\\\\\\___\/\\\_\/\\\///////////___/\\\///\\\_____/\\\///////\\\_____/\\\/////\\\____/\\\/////\\\____/\\\/////\\\____/\\\///////\\\_____________/\\\\\\\\\\\\\___/\\\///////\\\___       
--   _____\/\\\_____\/\\\/\\\__\/\\\_\/\\\____________/\\\/__\///\\\__\///______\//\\\___/\\\____\//\\\__/\\\____\//\\\__/\\\____\//\\\__\///______/\\\_____________/\\\/////////\\\_\///______\//\\\__      
--    _____\/\\\_____\/\\\//\\\_\/\\\_\/\\\\\\\\\\\___/\\\______\//\\\___________/\\\/___\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\_________/\\\//_____________\/\\\_______\/\\\___________/\\\/___     
--     _____\/\\\_____\/\\\\//\\\\/\\\_\/\\\///////___\/\\\_______\/\\\________/\\\//_____\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\________\////\\\____________\/\\\\\\\\\\\\\\\________/\\\//_____    
--      _____\/\\\_____\/\\\_\//\\\/\\\_\/\\\__________\//\\\______/\\\______/\\\//________\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\___________\//\\\___________\/\\\/////////\\\_____/\\\//________   
--       _____\/\\\_____\/\\\__\//\\\\\\_\/\\\___________\///\\\__/\\\______/\\\/___________\//\\\____/\\\__\//\\\____/\\\__\//\\\____/\\\___/\\\______/\\\____________\/\\\_______\/\\\___/\\\/___________  
--        __/\\\\\\\\\\\_\/\\\___\//\\\\\_\/\\\_____________\///\\\\\/______/\\\\\\\\\\\\\\\__\///\\\\\\\/____\///\\\\\\\/____\///\\\\\\\/___\///\\\\\\\\\/_____________\/\\\_______\/\\\__/\\\\\\\\\\\\\\\_ 
--         _\///////////__\///_____\/////__\///________________\/////_______\///////////////_____\///////________\///////________\///////_______\/////////_______________\///________\///__\///////////////__

-- Your Name: Nhat Chi Nguyen
-- Your Student Number: 1482182
-- By submitting, you declare that this work was completed entirely by yourself.

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q1

SELECT model_name, model_year, battery_capacity
FROM electric_vehicle
WHERE battery_capacity = (
	SELECT MAX(battery_capacity)
    FROM electric_vehicle
);

-- END Q1
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q2

SELECT DISTINCT cs.station_id, cs.state, cs.postcode
FROM charging_station cs
JOIN outlet o ON cs.station_id = o.station_id
WHERE o.charging_rate >= 100;

-- END Q2
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q3

SELECT station_id
FROM charging_station cs
-- anti-join to identify stations with no matching records in facility
WHERE NOT EXISTS (
  SELECT 1
  FROM facility f
  WHERE f.station_id = cs.station_id
);


-- END Q3
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q4

SELECT
  p.license_num AS license_number,
  p.person_name AS name,
  COUNT(ev.vin) AS total_num_of_cars_with_no_charge_event_registered_to_person
FROM person p
JOIN electric_vehicle ev ON p.license_num = ev.license_num
WHERE ev.vin NOT IN (
  SELECT DISTINCT vin 
  FROM charging_event
  WHERE vin IS NOT NULL
)
GROUP BY p.license_num, p.person_name
ORDER BY p.person_name;

-- END Q4
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q5

SELECT facility_id
FROM facility f
WHERE EXISTS (
    -- 1st condition: facility has issued at least 1 coupon
	SELECT 1
    FROM coupon c
    WHERE c.facility_id = f.facility_id
)
AND NOT EXISTS (
    -- 2nd condition: none of facility's coupons were used on specific date
	SELECT 1
    FROM coupon c
    JOIN charging_event ce
		ON ce.coupon_id = c.coupon_id
    WHERE c.facility_id = f.facility_id
		AND DATE(ce.requested_at) = '2025-01-01'
);

-- END Q5
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q6

SELECT ev.model_name, ev.model_year, c.company_name, 
       ROUND(AVG(ce.kwh), 2) AS rounded_average_kwh
FROM electric_vehicle ev
JOIN company c 
	ON ev.abn = c.abn
JOIN charging_event ce 
	ON ev.vin = ce.vin
JOIN outlet o
	-- connecting to specific outlet where charging occurred
	ON ce.station_id = o.station_id 
	AND ce.outlet_number = o.outlet_number
WHERE o.charging_rate > 68 
	AND ce.kwh IS NOT NULL -- excluding incomplete charging records
GROUP BY ev.model_name, ev.model_year, c.company_name
HAVING AVG(ce.kwh) > 50;

-- END Q6
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q7

SELECT COUNT(*) AS total_number_manufactured
FROM electric_vehicle
WHERE abn = '1'
OR abn IN (SELECT abn FROM company WHERE parent_abn = '1') -- vehicles from child companies
OR abn IN (
	SELECT c2.abn -- vehicles from grandchild companies
	FROM company c1 
	JOIN company c2 
		ON c1.abn = c2.parent_abn 
	WHERE c1.parent_abn = '1');

-- END Q7
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q8

SELECT DISTINCT ce.vin
FROM charging_event ce
WHERE NOT EXISTS (              
  SELECT 1
  FROM charging_event ce2
  JOIN electric_vehicle ev
    ON ev.vin = ce2.vin
  WHERE ce2.vin = ce.vin
    AND ce2.license_num = ev.license_num
);

-- END Q8
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q9

SELECT DISTINCT ce1.license_num, ce1.vin
FROM charging_event ce1
JOIN electric_vehicle ev
  ON ev.vin = ce1.vin
WHERE NOT EXISTS (
  -- 1st condition: No outlet meeting criteria that this person-car pair hasn't used
  SELECT 1
  FROM outlet o
  JOIN charging_station cs 
	ON o.station_id = cs.station_id
  JOIN company_owns_station cos 
	ON cs.station_id = cos.station_id
  WHERE cs.postcode >= '3000'
    AND cs.postcode < '4000'
    AND cos.abn = ev.abn        
    AND NOT EXISTS (
	  -- check if this person-car pair has a charging event at this outlet
      SELECT 1
      FROM charging_event ce2
      WHERE ce2.license_num = ce1.license_num
        AND ce2.vin = ce1.vin
        AND ce2.station_id = o.station_id
        AND ce2.outlet_number = o.outlet_number
    )
)
  -- 2nd condition: ensure there's at least 1 relevant outlet
  AND EXISTS (
    SELECT 1
    FROM outlet o2
    JOIN charging_station cs2 
		ON o2.station_id = cs2.station_id
    JOIN company_owns_station cos2 
		ON cs2.station_id = cos2.station_id
    WHERE cs2.postcode BETWEEN '3000' AND '3999' 
		AND cos2.abn = ev.abn
  );


-- END Q9
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q10

SELECT ROUND(
    SUM(
      ce.kwh
      * o.price_kwh
      * COALESCE(c.discount, 1)  -- discount multiplier or 1 if no coupon used
    ),
    2
  ) AS total_income
FROM charging_event ce
JOIN outlet o
  ON ce.station_id   = o.station_id -- connect to specific outlet where charging occurred
 AND ce.outlet_number = o.outlet_number
JOIN charging_station cs
  ON ce.station_id = cs.station_id
LEFT JOIN coupon c -- ensures to include charging events without coupon
  ON ce.coupon_id = c.coupon_id
WHERE cs.street        = '125 Collins Street'
  AND cs.postcode      = '3000'
  AND o.outlet_number  = 2
  AND YEAR(ce.requested_at)  = 2025
  AND MONTH(ce.requested_at) = 1;

-- END Q10
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- END OF ASSIGNMENT Do not write below this line
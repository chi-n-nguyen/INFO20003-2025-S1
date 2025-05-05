-- __/\\\\\\\\\\\__/\\\\\_____/\\\__/\\\\\\\\\\\\\\\____/\\\\\_________/\\\\\\\\\_________/\\\\\\\________/\\\\\\\________/\\\\\\\________/\\\\\\\\\\________________/\\\\\\\\\_______/\\\\\\\\\_____        
--  _\/////\\\///__\/\\\\\\___\/\\\_\/\\\///////////___/\\\///\\\_____/\\\///////\\\_____/\\\/////\\\____/\\\/////\\\____/\\\/////\\\____/\\\///////\\\_____________/\\\\\\\\\\\\\___/\\\///////\\\___       
--   _____\/\\\_____\/\\\/\\\__\/\\\_\/\\\____________/\\\/__\///\\\__\///______\//\\\___/\\\____\//\\\__/\\\____\//\\\__/\\\____\//\\\__\///______/\\\_____________/\\\/////////\\\_\///______\//\\\__      
--    _____\/\\\_____\/\\\//\\\_\/\\\_\/\\\\\\\\\\\___/\\\______\//\\\___________/\\\/___\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\_________/\\\//_____________\/\\\_______\/\\\___________/\\\/___     
--     _____\/\\\_____\/\\\\//\\\\/\\\_\/\\\///////___\/\\\_______\/\\\________/\\\//_____\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\________\////\\\____________\/\\\\\\\\\\\\\\\________/\\\//_____    
--      _____\/\\\_____\/\\\_\//\\\/\\\_\/\\\__________\//\\\______/\\\______/\\\//________\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\___________\//\\\___________\/\\\/////////\\\_____/\\\//________   
--       _____\/\\\_____\/\\\__\//\\\\\\_\/\\\___________\///\\\__/\\\______/\\\/___________\//\\\____/\\\__\//\\\____/\\\__\//\\\____/\\\___/\\\______/\\\____________\/\\\_______\/\\\___/\\\/___________  
--        __/\\\\\\\\\\\_\/\\\___\//\\\\\_\/\\\_____________\///\\\\\/______/\\\\\\\\\\\\\\\__\///\\\\\\\/____\///\\\\\\\/____\///\\\\\\\/___\///\\\\\\\\\/_____________\/\\\_______\/\\\__/\\\\\\\\\\\\\\\_ 
--         _\///////////__\///_____\/////__\///________________\/////_______\///////////////_____\///////________\///////________\///////_______\/////////_______________\///________\///__\///////////////__

-- Your Name: DINH TUNG PHAN
-- Your Student Number: 1674345
-- By submitting, you declare that this work was completed entirely by yourself.

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q1

SELECT 
    model_name, model_year, battery_capacity
FROM
    electric_vehicle
WHERE
    battery_capacity = (SELECT 
            MAX(battery_capacity)
        FROM
            electric_vehicle);

-- END Q1
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q2
	
SELECT DISTINCT
    ss.station_id, ss.state, ss.postcode
FROM
    charging_station ss
WHERE
    EXISTS( SELECT 
            1
        FROM
            outlet ol
        WHERE
            ol.station_id = ss.station_id
                AND ol.charging_rate > 100);

-- END Q2
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q3

SELECT 
    cs.station_id
FROM
    charging_station AS cs
        LEFT JOIN
    facility AS f ON f.station_id = cs.station_id
WHERE
    f.station_id IS NULL;

-- END Q3
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q4

SELECT 
    p.license_num 	      AS license_num,
    p.person_name 		  AS person_name,
    COUNT(ev.license_num) AS total_num_of_cars_with_no_charge_event
FROM
    person AS p
        JOIN
    electric_vehicle AS ev ON p.license_num = ev.license_num
		LEFT JOIN
	charging_event AS ce ON ce.vin = ev.vin
WHERE
	ce.vin IS NULL
GROUP BY 
	p.license_num,
    p.person_name
ORDER BY
	p.person_name;
    
-- END Q4
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q5

SELECT DISTINCT
    f.facility_id AS facility_id
FROM
    facility AS f
WHERE
    NOT EXISTS( SELECT 
            1
        FROM
            coupon AS c
                JOIN
            charging_event AS ce ON c.coupon_id = ce.coupon_id
        WHERE
            c.facility_id = f.facility_id
                AND DATE(ce.requested_at) = '2025-01-01')
ORDER BY f.facility_id ASC;

-- END Q5
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q6

SELECT DISTINCT
    ev.model_name AS model_name,
    ev.model_year AS model_year,
    ROUND(AVG(ce.kwh), 2) AS rounded_average_kwh
FROM
    electric_vehicle AS ev
        JOIN
    charging_event AS ce ON ce.vin = ev.vin
        JOIN
    outlet AS ol ON ol.station_id = ce.station_id
WHERE
    ce.kwh > 50 AND ol.charging_rate > 68
GROUP BY model_name , model_year
HAVING AVG(ce.kwh) > 50
ORDER BY rounded_average_kwh DESC;

-- END Q6
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q7

WITH children AS (
  SELECT 
    abn 
  FROM 
    company 
  WHERE 
    parent_abn = '1'
), 
grandchildren AS (
  SELECT 
    abn 
  FROM 
    company 
  WHERE 
    parent_abn = (
      SELECT 
        abn 
      FROM 
        children
    )
), 
relevant_companies AS (
  SELECT 
    '1' AS abn 
  UNION 
  SELECT 
    abn 
  FROm 
    children 
  UNION 
  SELECT 
    abn 
  FROM 
    grandchildren
) 
SELECT 
  COUNT(v.vin) as total_number_manufactured 
FROM 
  electric_vehicle AS v 
WHERE 
  v.abn IN(
    SELECT 
      abn 
    FROM 
      relevant_companies
  );


-- END Q7
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q8

SELECT DISTINCT
    ev.VIN
FROM
    electric_vehicle AS ev
WHERE
    NOT EXISTS( SELECT 
            1
        FROM
            charging_event AS ce
        WHERE
            ce.VIN = ev.VIN
                AND ce.license_num = ev.license_num)
        AND EXISTS( SELECT 
            1
        FROM
            charging_event AS ce2
        WHERE
            ce2.VIN = ev.VIN);

-- END Q8
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q9

WITH eligible_stations AS (
  SELECT 
    ev.vin, 
    cs.station_id
  FROM electric_vehicle AS ev 
  JOIN company_owns_station AS c_o_s 
    ON c_o_s.abn         = ev.abn 
  JOIN charging_station AS cs 
    ON cs.station_id     = c_o_s.station_id 
  WHERE cs.postcode >= 3000
    AND cs.postcode  <  4000
), 

eligible_outlets AS (
  SELECT 
    es.vin, 
    o.outlet_number,
    o.station_id
    
  FROM eligible_stations AS es 
  JOIN outlet AS o 
    ON o.station_id = es.station_id
), 

total_outlets AS (
  SELECT 
    vin, 
    COUNT(*) AS cnt_o 
  FROM eligible_outlets 
  GROUP BY vin
), 

person_fits_car AS (
  SELECT
    ce.license_num,
    ce.vin,
    COUNT(*)  AS cnt_charges
  FROM charging_event AS ce
  JOIN eligible_outlets AS eo
    ON eo.vin           = ce.vin
   AND eo.station_id    = ce.station_id
   AND eo.outlet_number = ce.outlet_number
  GROUP BY
    ce.license_num,
    ce.vin
)
SELECT 
  pfc.license_num, 
  pfc.vin
FROM 
  person_fits_car AS pfc 
  JOIN total_outlets AS tolt ON tolt.vin = pfc.vin 
WHERE 
  pfc.cnt_charges = tolt.cnt_o;


-- END Q9
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q10

SELECT 
  ROUND(
    SUM(
      ce.kwh * o.price_kwh * COALESCE(c.discount, 1) -- treat NULL discount as 1.0
      ), 
    2
  ) AS total_income 
FROM 
  charging_event AS ce 
  JOIN outlet AS o ON ce.station_id = o.station_id 
  AND ce.outlet_number = o.outlet_number 
  AND ce.outlet_number = '2' 
  JOIN charging_station AS cs ON ce.station_id = cs.station_id 
  LEFT JOIN coupon AS c ON ce.coupon_id = c.coupon_id 
WHERE 
  MONTH(ce.requested_at) = 1 
  AND ce.kwh IS NOT NULL 
  AND cs.street = '125 Collins Street' 
  AND cs.postcode = 3000;

-- END Q10
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- END OF ASSIGNMENT Do not write below this line
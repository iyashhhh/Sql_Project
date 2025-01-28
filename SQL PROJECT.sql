CREATE SCHEMA `ev_sales`;
select * from `dim_date`;

ALTER TABLE dim_date
RENAME COLUMN `ï»¿date` to `Date`;
select * from `dim_date`;

select * from `electric_vehicle_sales_by_makers`;
ALTER TABLE electric_vehicle_sales_by_makers
RENAME COLUMN `ï»¿date` to `Date`;
select * from electric_vehicle_sales_by_makers;

select * from `electric_vehicle_sales_by_state`;
ALTER TABLE `electric_vehicle_sales_by_state`
RENAME COLUMN `ï»¿date` to `Date`;
select * from `electric_vehicle_sales_by_state`;
SET SQL_SAFE_UPDATES = 0 ;

UPDATE electric_vehicle_sales_by_state
SET state='Andaman & Nicobar Island' WHERE state='Andaman & Nicobar';

/*Q1)List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the
number of 2-wheelers sold.*/
select fiscal_year,maker,SUM(electric_vehicles_sold) as `Highest_2w_sales` from `dim_date` 
JOIN electric_vehicle_sales_by_makers ON dim_date.`DATE`=electric_vehicle_sales_by_makers.`Date`
WHERE `fiscal_year` in (2023,2024) AND `vehicle_category`='2-Wheelers'
GROUP BY `fiscal_year`,`vehicle_category`,`maker`
ORDER BY `Highest_2w_sales` DESC LIMIT 3;

select `fiscal_year`,`maker`,SUM(electric_vehicles_sold) AS `LOWEST_sales` from `dim_date` 
JOIN electric_vehicle_sales_by_makers ON dim_date.`DATE`=electric_vehicle_sales_by_makers.`Date`
WHERE `fiscal_year` in (2023,2024) AND `vehicle_category`='2-Wheelers'
GROUP BY `fiscal_year`,`vehicle_category`,`maker`
ORDER BY `LOWEST_sales` ASC LIMIT 3;

#Q2)Find the overall penetration rate in India for 2023 and 2022
select `fiscal_year`,(SUM(electric_vehicles_sold)/SUM(total_vehicles_sold))* 100 AS `Penetration rate` from `dim_date` JOIN electric_vehicle_sales_by_state
ON dim_date.`DATE`=electric_vehicle_sales_by_state.`Date`
WHERE fiscal_year in (2022,2023)
GROUP BY fiscal_year;

/*Q3)Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-
wheeler EV sales in FY 2024.*/
select `state`,`vehicle_category`,(SUM(electric_vehicles_sold)/SUM(total_vehicles_sold))* 100 AS `Penetration rate` from `dim_date` JOIN electric_vehicle_sales_by_state
ON dim_date.`DATE`=electric_vehicle_sales_by_state.`Date`
WHERE fiscal_year = 2024
GROUP BY state
ORDER BY `Penetration rate` DESC LIMIT 5;

#Q4)List the top 5 states having highest number of EVs sold in 2023
select `STATE`,SUM(electric_vehicles_sold) AS Highest_ev_sales from `dim_date` JOIN electric_vehicle_sales_by_state
ON dim_date.`DATE`=electric_vehicle_sales_by_state.`Date`
WHERE fiscal_year = 2023
GROUP BY state
ORDER BY SUM(electric_vehicles_sold) DESC LIMIT 5;

#Q5)List the states with negative penetration (decline) in EV sales from 2022 to 2024?
select `state`,`fiscal_year`,`quarter`,(SUM(electric_vehicles_sold)/SUM(total_vehicles_sold))* 100 AS `Penetration rate` from `dim_date` JOIN electric_vehicle_sales_by_state
ON dim_date.`DATE`=electric_vehicle_sales_by_state.`Date`
GROUP BY `state`,`fiscal_year`,`quarter`
ORDER BY state,`fiscal_year`,`quarter`;


#Q6)Which are the Top 5 EV makers in India?
SELECT `maker`,sum(electric_vehicles_sold) AS Top_ev_makers FROM electric_vehicle_sales_by_makers
GROUP BY maker
ORDER BY sum(electric_vehicles_sold) DESC LIMIT 5; 

#Q7)How many EV makers sell 4-wheelers in India?
select COUNT(distinct(maker)) AS EV_makers_4w from electric_vehicle_sales_by_makers
WHERE `vehicle_category`='4-wheelers';

/*Q8)What is ratio of 2-wheeler makers to 4-wheeler makers?*/
SELECT 
    (SELECT COUNT(DISTINCT maker) 
     FROM electric_vehicle_sales_by_makers 
     WHERE vehicle_category = '2-wheelers') /
    (SELECT COUNT(DISTINCT maker) 
     FROM electric_vehicle_sales_by_makers 
     WHERE vehicle_category = '4-wheelers') AS ratio;


/*Q9)What are the quarterly trends based on sales volume for the top 5 EV makers (4-
wheelers) from 2022 to 2024?*/
WITH top_EV_makers AS
(SELECT
	maker
FROM 
electric_vehicle_sales_by_makers ev
JOIN dim_date d
ON d.date=ev.date
Where vehicle_category="4-Wheelers"
GROUP BY maker
order by sum(electric_vehicles_sold) desc
limit 5)
Select 
	maker,
    fiscal_year,
    quarter,
    sum(electric_vehicles_sold) as total_sales
FROM electric_vehicle_sales_by_makers ev 
JOIN dim_date d 
On d.date=ev.date
WHERE vehicle_category="4-Wheelers" and maker in (select maker from top_ev_makers)
group by maker,fiscal_year,quarter
order by maker,fiscal_year,quarter;

/*Q10)How do the EV sales and penetration rates in Maharashtra compare to Tamil Nadu
for 2024?*/
SELECT 
	state,
    sum(electric_vehicles_sold) as ev_sales,
    (sum(electric_vehicles_sold)/sum(total_vehicles_sold))*100 as penetration_rate
FROM electric_vehicle_sales_by_state ev
JOIN dim_date d 
On d.date=ev.date
Where fiscal_year="2024" and state in ("Maharashtra", "Tamil Nadu")
group by state;

/*Q11)List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top
5 makers from 2022 to 2024.*/
WITH top5maker AS
(SELECT 
	maker
FROM electric_vehicle_sales_by_makers ev 
Where vehicle_category="4-Wheelers"
group by maker
order by sum(electric_vehicles_sold) desc
limit 5)

select
	maker,
    CONCAT(power((SUM(CASE WHEN d.fiscal_year = "2024" THEN ev.electric_vehicles_sold ELSE 0 END) / 
     SUM(CASE WHEN d.fiscal_year = "2022" THEN ev.electric_vehicles_sold ELSE 0 END)),0.5) - 1,'%') AS CAGR
From electric_vehicle_sales_by_makers ev 
JOIN dim_date d 
ON d.date=ev.date 
WHERE vehicle_category="4-Wheelers" and maker in (select maker from top5maker)
group by maker
Order by CAGR desc;

/*Q12)List down the top 10 states that had the highest compounded annual growth rate
(CAGR) from 2022 to 2024 in total vehicles sold.*/
WITH top10states AS
(SELECT 
	state
FROM electric_vehicle_sales_by_state ev 
group by state
order by sum(electric_vehicles_sold) desc
limit 10)

select
	state,
    CONCAT(power(SUM(CASE WHEN d.fiscal_year = "2024" THEN ev.electric_vehicles_sold ELSE 0 END) / 
	(SUM(CASE WHEN d.fiscal_year = "2022" THEN ev.electric_vehicles_sold ELSE 0 END)),0.5) - 1,'%') AS CAGR
From electric_vehicle_sales_by_state ev 
JOIN dim_date d 
ON d.date=ev.date 
WHERE state in (select state from top10states)
group by state
Order by CAGR desc;

/*Q13)What are the peak and low season months for EV sales based on the data from 2022
to 2024?*/
#Peak season months:
ALTER TABLE electric_vehicle_sales_by_makers
ADD COLUMN `Month` TEXT;
SELECT * FROM electric_vehicle_sales_by_makers;
SET SQL_SAFE_UPDATES = 0 ;
UPDATE  electric_vehicle_sales_by_makers
SET `Month`=SUBSTRING_INDEX(SUBSTRING_INDEX(`Date`, '-', 2), '-', -1);
SELECT 
	`month`,
    sum(electric_vehicles_sold) as PEAK_ev_sales
FROM ev_sales.electric_vehicle_sales_by_makers
group by month
order by PEAK_ev_sales desc;
#low season months:
SELECT 
	`month`,
    sum(electric_vehicles_sold) as LOWEST_ev_sales
FROM ev_sales.electric_vehicle_sales_by_makers
group by month
order by LOWEST_ev_sales;

/*Q14)Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India for 2022
vs 2024 and 2023 vs 2024, assuming an average unit price.*/
#2022 VS 2024:
CREATE view `2022_2024` AS 
(SELECT 
	vehicle_category,fiscal_year,
	CASE
		WHEN vehicle_category="2-Wheelers" THEN sum(electric_vehicles_sold*85000)
        ELSE sum(electric_vehicles_sold*1500000)
        END AS revenue
FROM electric_vehicle_sales_by_makers ev 
JOIN dim_date d 
ON d.date=ev.date
WHERE `fiscal_year` IN (2022,2024)
group by vehicle_category,fiscal_year
order by vehicle_category,fiscal_year);
SELECT * FROM `2022_2024`;

SELECT 
    t1.vehicle_category,
    t1.revenue AS revenue_2022,
    t2.revenue AS revenue_2024,
    concat(((t2.revenue - t1.revenue) / t1.revenue) * 100,'%') AS growth_rate_percentage
FROM 
    `2022_2024` t1
JOIN 
    `2022_2024` t2
ON 
    t1.vehicle_category = t2.vehicle_category
WHERE 
    t1.fiscal_year = 2022
    AND t2.fiscal_year = 2024;

#2023 vs 2024:
CREATE VIEW `2023_2024` AS 
(SELECT vehicle_category,fiscal_year,
	CASE
		WHEN vehicle_category="2-Wheelers" THEN sum(electric_vehicles_sold*85000)
        ELSE sum(electric_vehicles_sold*1500000)
        END AS revenue
FROM `electric_vehicle_sales_by_makers` ev 
JOIN `dim_date` d 
ON d.`date`=ev.`date`
WHERE `fiscal_year` IN (2023,2024)
group by vehicle_category,fiscal_year
order by vehicle_category,fiscal_year);
SELECT * FROM `2023_2024`;
SELECT 
    t1.vehicle_category,
    t1.revenue AS revenue_2023,
    t2.revenue AS revenue_2024,
    concat((((t2.revenue - t1.revenue) / t1.revenue) * 100),'%') AS growth_rate_percentage
FROM 
    `2023_2024` t1
JOIN 
    `2023_2024` t2
ON 
    t1.vehicle_category = t2.vehicle_category
WHERE 
    t1.fiscal_year = 2023
    AND t2.fiscal_year = 2024;







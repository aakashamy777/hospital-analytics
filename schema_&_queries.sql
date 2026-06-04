CREATE DATABASE hospital_analytics;
USE hospital_analytics;

SELECT * FROM Healthcare_Dataset LIMIT 5;
SELECT COUNT(*) FROM healthcare_dataset;
DESCRIBE healthcare_dataset;


USE hospital_analytics;

-- 1. Total patients by gender
SELECT Gender, COUNT(*) AS total_patients
FROM healthcare_dataset
GROUP BY Gender;

-- 2. Most common medical conditions
SELECT `Medical Condition`, COUNT(*) AS total_cases
FROM healthcare_dataset
GROUP BY `Medical Condition`
ORDER BY total_cases DESC;

-- 3. Average billing amount by medical condition
SELECT `Medical Condition`, 
       ROUND(AVG(`Billing Amount`), 2) AS avg_billing
FROM healthcare_dataset
GROUP BY `Medical Condition`
ORDER BY avg_billing DESC;

-- 4. Average length of stay per condition
SELECT `Medical Condition`,
       ROUND(AVG(DATEDIFF(`Discharge Date`, `Date of Admission`)), 1) AS avg_stay_days
FROM healthcare_dataset
GROUP BY `Medical Condition`
ORDER BY avg_stay_days DESC;

-- 5. Admission type breakdown
SELECT `Admission Type`, COUNT(*) AS total,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM healthcare_dataset), 2) AS percentage
FROM healthcare_dataset
GROUP BY `Admission Type`;

-- 6. Top 5 hospitals by patient volume
SELECT Hospital, COUNT(*) AS patients
FROM healthcare_dataset
GROUP BY Hospital
ORDER BY patients DESC
LIMIT 5;

-- 7. Insurance provider revenue
SELECT `Insurance Provider`,
       ROUND(SUM(`Billing Amount`), 2) AS total_revenue,
       ROUND(AVG(`Billing Amount`), 2) AS avg_billing
FROM healthcare_dataset
GROUP BY `Insurance Provider`
ORDER BY total_revenue DESC;

-- 8. Test results distribution
SELECT `Test Results`, COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM healthcare_dataset), 2) AS percentage
FROM healthcare_dataset
GROUP BY `Test Results`;

-- 9. Age group segmentation
SELECT 
  CASE 
    WHEN Age < 18 THEN 'Minor'
    WHEN Age BETWEEN 18 AND 35 THEN 'Young Adult'
    WHEN Age BETWEEN 36 AND 55 THEN 'Middle Age'
    WHEN Age BETWEEN 56 AND 70 THEN 'Senior'
    ELSE 'Elderly'
  END AS age_group,
  COUNT(*) AS total,
  ROUND(AVG(`Billing Amount`), 2) AS avg_billing
FROM healthcare_dataset
GROUP BY age_group
ORDER BY avg_billing DESC;

-- 10. Most prescribed medications
SELECT Medication, COUNT(*) AS prescriptions
FROM healthcare_dataset
GROUP BY Medication
ORDER BY prescriptions DESC;

-- 11. Abnormal test results by condition
SELECT `Medical Condition`, COUNT(*) AS abnormal_cases
FROM healthcare_dataset
WHERE `Test Results` = 'Abnormal'
GROUP BY `Medical Condition`
ORDER BY abnormal_cases DESC;

-- 12. Monthly admissions trend
SELECT DATE_FORMAT(`Date of Admission`, '%Y-%m') AS month,
       COUNT(*) AS admissions
FROM healthcare_dataset
GROUP BY month
ORDER BY month;

-- 13. High billing patients (top 10%)
SELECT Name, `Medical Condition`, `Billing Amount`, `Insurance Provider`
FROM healthcare_dataset
WHERE `Billing Amount` > (
    SELECT PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY `Billing Amount`)
    -- fallback below if above doesn't work in MySQL
)
ORDER BY `Billing Amount` DESC;

-- 13 (MySQL-compatible high billing)
SELECT Name, `Medical Condition`, 
       ROUND(`Billing Amount`, 2) AS billing
FROM healthcare_dataset
ORDER BY `Billing Amount` DESC
LIMIT 100;

-- 14. Doctor patient load
SELECT Doctor, COUNT(*) AS total_patients,
       ROUND(AVG(`Billing Amount`), 2) AS avg_billing_per_patient
FROM healthcare_dataset
GROUP BY Doctor
ORDER BY total_patients DESC
LIMIT 10;

-- 15. Blood type distribution
SELECT `Blood Type`, COUNT(*) AS count
FROM healthcare_dataset
GROUP BY `Blood Type`
ORDER BY count DESC;

-- =============================================
-- ADVANCED QUERIES (Window Functions + CTEs)
-- =============================================

-- 16. Rank conditions by avg billing using window function
SELECT `Medical Condition`,
       ROUND(AVG(`Billing Amount`), 2) AS avg_billing,
       RANK() OVER (ORDER BY AVG(`Billing Amount`) DESC) AS billing_rank
FROM healthcare_dataset
GROUP BY `Medical Condition`;

-- 17. CTE - Patients with longer than avg stay
WITH avg_stay AS (
  SELECT ROUND(AVG(DATEDIFF(`Discharge Date`, `Date of Admission`)), 1) AS overall_avg
  FROM healthcare_dataset
)
SELECT Name, `Medical Condition`,
       DATEDIFF(`Discharge Date`, `Date of Admission`) AS stay_days,
       a.overall_avg
FROM healthcare_dataset, avg_stay a
WHERE DATEDIFF(`Discharge Date`, `Date of Admission`) > a.overall_avg
ORDER BY stay_days DESC
LIMIT 20;

-- 18. Running total of billing by admission date
SELECT `Date of Admission`,
       ROUND(SUM(`Billing Amount`), 2) AS daily_revenue,
       ROUND(SUM(SUM(`Billing Amount`)) OVER (ORDER BY `Date of Admission`), 2) AS running_total
FROM healthcare_dataset
GROUP BY `Date of Admission`
ORDER BY `Date of Admission`;

-- 19. CREATE VIEW for dashboard use (Tableau will use this)
CREATE OR REPLACE VIEW condition_summary AS
SELECT 
  `Medical Condition`,
  COUNT(*) AS total_patients,
  ROUND(AVG(`Billing Amount`), 2) AS avg_billing,
  ROUND(AVG(DATEDIFF(`Discharge Date`, `Date of Admission`)), 1) AS avg_stay_days,
  SUM(CASE WHEN `Test Results` = 'Abnormal' THEN 1 ELSE 0 END) AS abnormal_count
FROM healthcare_dataset
GROUP BY `Medical Condition`;

SELECT * FROM condition_summary;


-- 20. Stored Procedure - Get condition report by admission type
DELIMITER $$

CREATE PROCEDURE GetConditionReport(IN admission_type VARCHAR(50))
BEGIN
  SELECT `Medical Condition`,
         COUNT(*) AS total_cases,
         ROUND(AVG(`Billing Amount`), 2) AS avg_billing,
         ROUND(AVG(DATEDIFF(`Discharge Date`, `Date of Admission`)), 1) AS avg_stay
  FROM healthcare_dataset
  WHERE `Admission Type` = admission_type
  GROUP BY `Medical Condition`
  ORDER BY total_cases DESC;
END $$

DELIMITER ;

-- Test it
CALL GetConditionReport('Emergency');
CALL GetConditionReport('Elective');



-- Run this, then export
SELECT `Medical Condition`, COUNT(*) AS total_patients,
       ROUND(AVG(`Billing Amount`),2) AS avg_billing,
       ROUND(AVG(DATEDIFF(`Discharge Date`,`Date of Admission`)),1) AS avg_stay_days
FROM healthcare_dataset
GROUP BY `Medical Condition`;

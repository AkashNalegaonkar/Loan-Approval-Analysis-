CREATE DATABASE IF NOT EXISTS Self_Project;
USE Self_Project;
SELECT * FROM Loan;

-- Take the back up of main table
CREATE TABLE Approval_loan AS 
SELECT * FROM loan;


  -- ************** Data Cleaning ************** --
  
-- Check total records in dataset.
SELECT COUNT(*) AS Total_Applicants
FROM loan;

-- Identify NULL Values in Each Column

SELECT
SUM(CASE WHEN Gender IS NULL OR TRIM(Gender) = '' THEN 1 ELSE 0 END) AS Gender_Null,
SUM(CASE WHEN Married IS NULL OR TRIM(Married) = '' THEN 1 ELSE 0 END) AS Married_Null,
SUM(CASE WHEN Dependents IS NULL OR TRIM(Dependents) = '' THEN 1 ELSE 0 END) AS Dependents_Null,
SUM(CASE WHEN Self_Employed IS NULL OR TRIM(Self_Employed) = '' THEN 1 ELSE 0 END) AS SelfEmp_Null,
SUM(CASE WHEN LoanAmount IS NULL OR TRIM(LoanAmount) = '' THEN 1 ELSE 0 END) AS LoanAmount_Null,
SUM(CASE WHEN Loan_Amount_Term IS NULL OR TRIM(Loan_Amount_Term) = '' THEN 1 ELSE 0 END) AS LoanTerm_Null,
SUM(CASE WHEN Credit_History IS NULL OR TRIM(Credit_History) = '' THEN 1 ELSE 0 END) AS CreditHistory_Null
FROM loan;

-- Fill Missing Gender (Male/Female).

SELECT Gender, Count(*) AS Total
FROM Loan
GROUP BY Gender;

UPDATE Loan
SET Gender = 'Male'										-- Filled categorical missing values using mode.
WHERE Gender IS NULL OR TRIM(Gender) = '';

-- Fill Missign Married

SELECT Married, Count(*) AS Total
FROM Loan
GROUP BY Married;

UPDATE Loan
SET Married = 'Yes'
WHERE Married IS NULL OR TRIM(Married) = '';

-- Fill Missing Dependents

SELECT Dependents, COUNT(*) AS Total
FROM Loan
GROUP BY Dependents;

UPDATE Loan
SET Dependents = 0
WHERE Dependents IS NULL OR TRIM(Dependents) = '';

-- Fill Missing Self_Employed

SELECT Self_Employed, Count(*) AS Total
FROM Loan
GROUP BY Self_Employed;

UPDATE Loan
SET Self_Employed = 'NO'
WHERE Self_Employed IS NULL OR TRIM(Self_Employed) = '';

-- Fill Missing Loan Amount

SELECT COUNT(LoanAmount) AS Missing_LoanAmount
FROM Loan
WHERE LoanAmount IS NULL OR TRIM(LoanAmount) = '';

SELECT ROUND(avg(loanamount), 2)
FROM Loan;

UPDATE Loan
SET LoanAmount = ( 
	SELECT AVG_Value FROM ( 
		SELECT ROUND(AVG(LoanAmount),2) AS AVG_Value FROM loan 
        ) temp
	)																-- I filled missing LoanAmount using AVG(), though median is better if the data is skewed.
WHERE LoanAmount IS NULL OR TRIM(LoanAmount) = '';

-- Fill Missing Loan Amount Term

SELECT Loan_Amount_Term
FROM Loan
GROUP BY Loan_Amount_Term
ORDER BY COUNT(*) DESC LIMIT 1;
	
UPDATE Loan
SET Loan_Amount_Term = (
	SELECT Loan_Amount_Term FROM ( 
		SELECT Loan_Amount_Term 
		FROM Loan
		GROUP BY Loan_Amount_Term
		ORDER BY COUNT(*) DESC LIMIT 1
	) AS Mode_Vlaue
)
WHERE Loan_Amount_Term IS NULL OR TRIM(Loan_Amount_Term) = '';

-- Fill Missing Credit History

SELECT COUNT(*) AS Missing_Credit_History
FROM Loan
WHERE Credit_History IS NULL OR TRIM(Credit_History) = '';

SELECT Credit_History
FROM Loan
GROUP BY Credit_History
ORDER BY COUNT(*) DESC LIMIT 1;

UPDATE Loan
SET Credit_History = (
	SELECT Credit_History FROM (
			SELECT Credit_History
			FROM Loan
			GROUP BY Credit_History
			ORDER BY COUNT(*) DESC LIMIT 1
	) AS Mode_Value_Credit
)
WHERE Credit_History IS NULL OR TRIM(Credit_History) = '';


-- Remove duplicate loan applications.

SELECT Loan_ID, count(*) AS Total_Duplicate
FROM Loan
GROUP BY Loan_ID
HAVING COUNT(*) > 1;

DELETE l1
FROM loan l1 JOIN loan l2
ON l1.Loan_ID = l2.Loan_ID
AND l1.Loan_ID > l2.Loan_ID;

-- Standardize Text Values
-- Gender

UPDATE loan
SET Gender = 'Male'
WHERE Gender IN ('M','male');

UPDATE loan
SET Gender = 'Female'
WHERE Gender IN ('F','female');

-- Loan Status
UPDATE loan
SET Loan_Status = 'Approved'
WHERE Loan_Status = 'Y';

UPDATE loan
SET Loan_Status = 'Rejected'
WHERE Loan_Status = 'N';

-- Create New Column
-- Total_Income
ALTER TABLE Loan ADD COLUMN Total_Income INt;

UPDATE Loan
SET Total_Income = ApplicantIncome + ApplicantIncome;

-- Loan to Income Ratio
ALTER TABLE Loan ADD COLUMN Loan_to_Income_Ratio FLOAT;

UPDATE Loan
SET Loan_to_Income_Ratio = LoanAmount / Total_Income;

-- Income_Group
ALTER TABLE Loan ADD COLUMN  Income_Group VARCHAR(50);

update Loan
SET Income_Group = ( SELECT
	CASE
		WHEN ApplicantIncome < 3000 THEN 'Low Income'
        WHEN ApplicantIncome BETWEEN 3000 AND 6000 THEN 'Medium Income'
        ELSE 'High Income'
	END AS Income_Group);

-- ************** SQL Business Analysis Questions **************
-- General Overview

-- Q.1. Total number of loan applications?
SELECT COUNT(*) 
FROM Loan;

-- Q.2.	Total approved vs rejected loans?
SELECT Loan_Status, COUNT(*) AS Total_Status
FROM Loan
GROUP BY Loan_Status;

-- Q.3.	Overall loan approval rate?
SELECT COUNT(*) AS Total_Application,
	   SUM( CASE WHEN Loan_Status = "Approved" THEN 1 ELSE 0 END ) AS Approved_Status,
	   ROUND( 
			(SUM( CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END ) * 100) /  COUNT(*),2
			) AS Approval_Rate
FROM Loan;

-- Q.4.	Average loan amount?
SELECT AVG(LoanAmount) AS AVG_Loan_Amount
FROM Loan;

-- Q.5.	Average applicant income?
SELECT AVG(ApplicantIncome) AS AVG_Applicant_Income
FROM Loan;


-- Demographic Analysis

-- Q.6.	Approval rate by Gender.
SELECT Gender, ROUND(
					(SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) * 100) / COUNT(*),2
                    ) AS Aprroval_Rate
FROM Loan
GROUP BY Gender;

-- Q.7.	Approval rate by Marital Status.
SELECT Married, ROUND(
					(SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) * 100) / COUNT(*),2
                    ) AS Aprroval_Rate
FROM Loan
GROUP BY Married;

-- Q.8.	Approval rate by Education level.
SELECT Education, ROUND(
					(SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) * 100) / COUNT(*),2
                    ) AS Approval_Rate
FROM Loan
GROUP BY Education;

-- Q.9.	Self-employed vs Non-self-employed approval rate.
SELECT (CASE WHEN Self_Employed = 'Yes' THEN 'Self_Employed' ELSE 'Non_self_employed' END) AS Employed_Status,
		ROUND(
					(SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) * 100) / COUNT(*),2
                    ) AS Approval_Rate
FROM Loan
GROUP BY Employed_Status;

-- Q.10. Property Area-wise approval rate (Urban/Semiurban/Rural).
SELECT Property_Area, ROUND(
					(SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) * 100) / COUNT(*),2
                    ) AS Approval_Rate
FROM Loan
GROUP BY Property_Area;

-- Financial Analysis.

-- Q.11. Does higher income increase approval chance?
SELECT Income_Group,
    COUNT(*) AS Total_Application,
    SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved,
    ROUND((SUM(
				CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) * 100) / COUNT(*), 2
                ) AS Approval__Rate
FROM Loan
GROUP BY Income_Group;

-- Q.12. Average loan amount for approved vs rejected.
SELECT Loan_Status,
	ROUND( AVG(LoanAmount), 2) AS AVG_Loan_Amount
FROM Loan
GROUP BY Loan_Status;

-- Q.13. Impact of Credit History on approval.
SELECT Credit_History,
		COUNT(*) AS Total_Application,
        SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved,
        ROUND((SUM(
				CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) * 100) / COUNT(*), 2
                ) AS Approval_Rate
FROM Loan
GROUP BY Credit_History;

-- Q.14. Loan-to-Income ratio comparison.
SELECT 
    Loan_Status,
    ROUND(AVG(Loan_to_Income_Ratio), 4) AS Avg_Loan_To_Income
FROM Loan
GROUP BY Loan_Status;

-- Risk Analysis

-- Q.16. Which group has highest rejection rate?
SELECT Income_Group,
		COUNT(*) AS Total_Application,
        SUM(CASE WHEN Loan_Status = 'Rejected' THEN 1 ELSE 0 END) AS Rejected,
        ROUND((SUM(
				CASE WHEN Loan_Status = 'Rejected' THEN 1 ELSE 0 END) * 100) / COUNT(*), 2
                ) AS Rejected_Rate
FROM Loan
GROUP BY Income_Group 
ORDER BY Rejected_Rate DESC;

-- Q.17. Does long Loan Term affect approval?
SELECT Loan_Amount_Term,
		COUNT(*) AS Total_Application,
        SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved,
        ROUND((SUM(
				CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) * 100) / COUNT(*), 2
                ) AS Approved_Rate
FROM Loan
GROUP BY Loan_Amount_Term;

-- Q.18. High loan amount vs rejection pattern.
SELECT CASE
			WHEN LoanAmount < 100 THEN 'Low Loan'
            WHEN LoanAmount BETWEEN 100 AND 200 THEN 'Medium Loan'
            ELSE 'High Loan'
		END AS Loan_Category,
	COUNT(*) AS Total_Application,
	SUM(CASE WHEN Loan_Status = 'Rejected' THEN 1 ELSE 0 END) AS Total_Rejected,
    ROUND((SUM(
				CASE WHEN Loan_Status = 'Rejected' THEN 1 ELSE 0 END) * 100) / COUNT(*), 2
                ) AS Rejected_Rate 
FROM Loan
GROUP BY Loan_Category
ORDER BY Rejected_Rate DESC;

--  Q.19. Applicants without credit history approval rate.
SELECT 
    Credit_History,
    COUNT(*) AS Total_Applications,
    
    SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved,
    
    ROUND(
        SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
    2) AS Approval_Rate

FROM Loan
GROUP BY Credit_History;

-- Q.20. Risk profile segmentation.
SELECT 
    CASE 
        WHEN Credit_History = 1 AND Loan_to_Income_Ratio < 0.03 THEN 'Low Risk'
        
        WHEN Credit_History = 1 AND Loan_to_Income_Ratio >= 0.03 THEN 'Medium Risk'
        
        WHEN Credit_History = 0 THEN 'High Risk'
        
        ELSE 'Medium Risk'
    END AS Risk_Profile,
    
    COUNT(*) AS Total_Applicants,
    
    SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) AS Approved,
    
    ROUND(
        SUM(CASE WHEN Loan_Status = 'Approved' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
    2) AS Approval_Rate

FROM Loan
GROUP BY Risk_Profile
ORDER BY Approval_Rate DESC;


    
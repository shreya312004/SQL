use healthcare;
#Step1: check all table records

SELECT 'Patients' AS Table_Name,
       COUNT(*) AS Total_Records
FROM Patients

UNION ALL

SELECT 'Encounters', COUNT(*) FROM Encounters

UNION ALL

SELECT 'Conditions', COUNT(*) FROM Conditions

UNION ALL

SELECT 'Medications', COUNT(*) FROM Medications

UNION ALL

SELECT 'Procedures', COUNT(*) FROM Procedures

UNION ALL

SELECT 'Observations', COUNT(*) FROM Observations

UNION ALL

SELECT 'Immunizations', COUNT(*) FROM Immunizations

UNION ALL

SELECT '[allergies (1)]', COUNT(*) FROM [allergies (1)]

UNION ALL

SELECT 'Careplans', COUNT(*) FROM Careplans

UNION ALL

SELECT 'Organizations', COUNT(*) FROM Organizations

UNION ALL

SELECT 'Providers', COUNT(*) FROM Providers

UNION ALL

SELECT 'Payers', COUNT(*) FROM Payers

UNION ALL

SELECT 'Payer_Transitions',
       COUNT(*) FROM Payer_Transitions

UNION ALL

SELECT 'Imaging_Studies',
       COUNT(*) FROM Imaging_Studies

UNION ALL

SELECT 'Devices', COUNT(*) FROM Devices;

#Step3: Check Patient information
SELECT TOP 20
    Id,
    BIRTHDATE,
    GENDER,
    MARITAL,
    RACE,
    ETHNICITY,
    CITY,
    STATE,
    HEALTHCARE_EXPENSES,
    HEALTHCARE_COVERAGE
FROM Patients;

#Step4: Understand encounter information
SELECT TOP 20
    Id,
    PATIENT,
    ORGANIZATION,
    PROVIDER,
    PAYER,
    ENCOUNTERCLASS,
    DESCRIPTION,
    START,
    STOP,
    TOTAL_CLAIM_COST,
    PAYER_COVERAGE
FROM Encounters;

#Step5: Understand medication information
SELECT TOP 20
    PATIENT,
    PAYER,
    DESCRIPTION,
    BASE_COST,
    PAYER_COVERAGE,
    DISPENSES,
    TOTALCOST
FROM Medications;

#Step6 : Check Missing Values
SELECT
    COUNT(*) AS Total_Patients,

    SUM(CASE
        WHEN BIRTHDATE IS NULL THEN 1
        ELSE 0
    END) AS Missing_Birthdate,

    SUM(CASE
        WHEN GENDER IS NULL THEN 1
        ELSE 0
    END) AS Missing_Gender,

    SUM(CASE
        WHEN CITY IS NULL THEN 1
        ELSE 0
    END) AS Missing_City,

    SUM(CASE
        WHEN STATE IS NULL THEN 1
        ELSE 0
    END) AS Missing_State

FROM Patients;

#Step7: check duplicates
SELECT
    Id,
    COUNT(*) AS Duplicate_Count
FROM Patients
GROUP BY Id
HAVING COUNT(*) > 1;

SELECT
    Id,
    COUNT(*) AS Duplicate_Count
FROM Encounters
GROUP BY Id
HAVING COUNT(*) > 1;

#Step8: Identify duplicate observation records:
SELECT
    DATE,
    PATIENT,
    ENCOUNTER,
    CODE,
    DESCRIPTION,
    VALUE,
    UNITS,
    TYPE,
    COUNT(*) AS Duplicate_Count

FROM Observations

GROUP BY
    DATE,
    PATIENT,
    ENCOUNTER,
    CODE,
    DESCRIPTION,
    VALUE,
    UNITS,
    TYPE

HAVING COUNT(*) > 1

ORDER BY Duplicate_Count DESC;

#Step9: Check invalid values
SELECT *
FROM Encounters
WHERE
    TRY_CONVERT(DECIMAL(18,2),
        TOTAL_CLAIM_COST) < 0

    OR TRY_CONVERT(DECIMAL(18,2),
        BASE_ENCOUNTER_COST) < 0

    OR TRY_CONVERT(DECIMAL(18,2),
        PAYER_COVERAGE) < 0;

		SELECT *
FROM Encounters
WHERE
    TRY_CONVERT(DATETIME2, STOP, 126)
    <
    TRY_CONVERT(DATETIME2, START, 126);

#Step10: Datacleaning
SELECT
    Id,

    TRY_CONVERT(DATE, BIRTHDATE)
        AS Birth_Date,

    TRY_CONVERT(DATE, DEATHDATE)
        AS Death_Date,

    UPPER(LTRIM(RTRIM(GENDER)))
        AS Gender,

    UPPER(LTRIM(RTRIM(MARITAL)))
        AS Marital_Status,

    LTRIM(RTRIM(RACE))
        AS Race,

    LTRIM(RTRIM(ETHNICITY))
        AS Ethnicity,

    LTRIM(RTRIM(CITY))
        AS City,

    LTRIM(RTRIM(STATE))
        AS State,

    TRY_CONVERT(DECIMAL(18,2),
        HEALTHCARE_EXPENSES)
        AS Healthcare_Expenses,

    TRY_CONVERT(DECIMAL(18,2),
        HEALTHCARE_COVERAGE)
        AS Healthcare_Coverage

INTO Patients_Clean

FROM Patients;

SELECT
    Id,
    PATIENT,
    ORGANIZATION,
    PROVIDER,
    PAYER,

    TRY_CONVERT(DATETIME2, START, 126)
        AS Encounter_Start,

    TRY_CONVERT(DATETIME2, STOP, 126)
        AS Encounter_Stop,

    ENCOUNTERCLASS,
    CODE,
    DESCRIPTION,

    TRY_CONVERT(DECIMAL(18,2),
        BASE_ENCOUNTER_COST)
        AS Base_Encounter_Cost,

    TRY_CONVERT(DECIMAL(18,2),
        TOTAL_CLAIM_COST)
        AS Total_Claim_Cost,

    TRY_CONVERT(DECIMAL(18,2),
        PAYER_COVERAGE)
        AS Payer_Coverage

INTO Encounters_Clean

FROM Encounters;

SELECT COUNT(*) AS Clean_Patient_Count
FROM Patients_Clean;

SELECT COUNT(*) AS Clean_Encounter_Count
FROM Encounters_Clean;

#Step11: Patient demographics analysis
SELECT
    COUNT(DISTINCT Id) AS Total_Patients
FROM Patients_Clean;

SELECT
    Gender,
    COUNT(*) AS Total_Patients,

    CAST(
        COUNT(*) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM Patients_Clean), 0)
        AS DECIMAL(10,2)
    ) AS Percentage

FROM Patients_Clean

GROUP BY Gender
ORDER BY Total_Patients DESC;

DECLARE @AsOfDate DATE;

SELECT @AsOfDate =
    MAX(CAST(Encounter_Start AS DATE))
FROM Encounters_Clean;

WITH Patient_Age AS
(
    SELECT
        Id,
        DATEDIFF(YEAR, Birth_Date, @AsOfDate)
        -
        CASE
            WHEN DATEADD(
                YEAR,
                DATEDIFF(YEAR, Birth_Date, @AsOfDate),
                Birth_Date
            ) > @AsOfDate
            THEN 1 ELSE 0
        END AS Age

    FROM Patients_Clean
    WHERE Birth_Date IS NOT NULL
)

SELECT
    State,
    COUNT(*) AS Total_Patients

FROM Patients_Clean

GROUP BY State
ORDER BY Total_Patients DESC;

SELECT
    COUNT(*) AS Total_Patients,

    SUM(Healthcare_Expenses)
        AS Total_Healthcare_Expenses,

    AVG(Healthcare_Expenses)
        AS Average_Healthcare_Expenses,

    MAX(Healthcare_Expenses)
        AS Highest_Healthcare_Expenses,

    MIN(Healthcare_Expenses)
        AS Lowest_Healthcare_Expenses

FROM Patients_Clean;

#Step12: Medical condition analysis
SELECT TOP 10
    DESCRIPTION AS Medical_Condition,

    COUNT(*) AS Total_Records,

    COUNT(DISTINCT PATIENT)
        AS Unique_Patients

FROM Conditions

GROUP BY DESCRIPTION

ORDER BY Unique_Patients DESC;

SELECT
    C.DESCRIPTION AS Medical_Condition,

    P.Gender,

    COUNT(DISTINCT C.PATIENT)
        AS Total_Patients

FROM Conditions C

INNER JOIN Patients_Clean P
    ON C.PATIENT = P.Id

GROUP BY
    C.DESCRIPTION,
    P.Gender

ORDER BY Total_Patients DESC;

SELECT
    CASE
        WHEN STOP IS NULL THEN 'No End Date Recorded'
        ELSE 'End Date Recorded'
    END AS Condition_Status,

    COUNT(*) AS Total_Conditions

FROM Conditions

GROUP BY
    CASE
        WHEN STOP IS NULL THEN 'No End Date Recorded'
        ELSE 'End Date Recorded'
    END;

SELECT
    PATIENT,

    COUNT(DISTINCT CODE)
        AS Total_Conditions

FROM Conditions

GROUP BY PATIENT

HAVING COUNT(DISTINCT CODE) > 1

ORDER BY Total_Conditions DESC;

SELECT
    DESCRIPTION AS Allergy,

    COUNT(DISTINCT PATIENT)
        AS Total_Patients

FROM [allergies (1)]

GROUP BY DESCRIPTION

ORDER BY Total_Patients DESC;

#Step13: Healthcare encounter analysis
SELECT
    COUNT(*) AS Total_Encounters,

    COUNT(DISTINCT PATIENT)
        AS Unique_Patients,

    COUNT(DISTINCT ORGANIZATION)
        AS Total_Organizations,

    COUNT(DISTINCT PROVIDER)
        AS Total_Providers

FROM Encounters_Clean;

SELECT
    ENCOUNTERCLASS,

    COUNT(*) AS Total_Encounters

FROM Encounters_Clean

GROUP BY ENCOUNTERCLASS

ORDER BY Total_Encounters DESC;

SELECT
    YEAR(Encounter_Start) AS Encounter_Year,

    MONTH(Encounter_Start) AS Encounter_Month,

    COUNT(*) AS Total_Encounters

FROM Encounters_Clean

WHERE Encounter_Start IS NOT NULL

GROUP BY
    YEAR(Encounter_Start),
    MONTH(Encounter_Start)

ORDER BY
    Encounter_Year,
    Encounter_Month;

SELECT
    YEAR(Encounter_Start) AS Encounter_Year,

    MONTH(Encounter_Start) AS Encounter_Month,

    COUNT(*) AS Total_Encounters

FROM Encounters_Clean

WHERE Encounter_Start IS NOT NULL

GROUP BY
    YEAR(Encounter_Start),
    MONTH(Encounter_Start)

ORDER BY
    Encounter_Year,
    Encounter_Month;

SELECT
    COUNT(*) AS Total_Encounters,

    SUM(Total_Claim_Cost)
        AS Total_Claim_Amount,

    AVG(Total_Claim_Cost)
        AS Average_Claim_Cost,

    MAX(Total_Claim_Cost)
        AS Highest_Claim_Cost,

    MIN(Total_Claim_Cost)
        AS Lowest_Claim_Cost

FROM Encounters_Clean;

SELECT TOP 10
    Id AS Encounter_ID,

    PATIENT,

    ENCOUNTERCLASS,

    DESCRIPTION,

    Total_Claim_Cost

FROM Encounters_Clean

ORDER BY Total_Claim_Cost DESC;

#Step14: Medication Analysis
SELECT
    COUNT(*) AS Total_Medication_Records,

    COUNT(DISTINCT PATIENT)
        AS Unique_Patients,

    SUM(TRY_CONVERT(DECIMAL(18,2), TOTALCOST))
        AS Total_Medication_Cost,

    AVG(TRY_CONVERT(DECIMAL(18,2), TOTALCOST))
        AS Average_Medication_Cost

FROM Medications;

SELECT TOP 10
    DESCRIPTION AS Medication_Name,

    COUNT(*) AS Prescription_Records,

    COUNT(DISTINCT PATIENT)
        AS Unique_Patients,

    SUM(TRY_CONVERT(INT, DISPENSES))
        AS Total_Dispenses

FROM Medications

GROUP BY DESCRIPTION

ORDER BY Prescription_Records DESC;

SELECT TOP 10
    DESCRIPTION AS Medication_Name,

    SUM(TRY_CONVERT(DECIMAL(18,2), TOTALCOST))
        AS Total_Medication_Cost,

    AVG(TRY_CONVERT(DECIMAL(18,2), BASE_COST))
        AS Average_Base_Cost

FROM Medications

GROUP BY DESCRIPTION

ORDER BY Total_Medication_Cost DESC;

SELECT
    SUM(TRY_CONVERT(DECIMAL(18,2), PAYER_COVERAGE))
        AS Total_Payer_Coverage,

    SUM(TRY_CONVERT(DECIMAL(18,2), TOTALCOST))
        AS Total_Medication_Cost,

    CAST(
        100.0 *
        SUM(TRY_CONVERT(DECIMAL(18,2), PAYER_COVERAGE))
        /
        NULLIF(
            SUM(TRY_CONVERT(DECIMAL(18,2), TOTALCOST)),
            0
        )
        AS DECIMAL(10,2)
    ) AS Coverage_Percentage

FROM Medications;
WITH Type2Date AS
(SELECT PersonnelNumber,FromDate AS DatePoint FROM dbo.HCH01EmailHistory 
UNION
SELECT PersonnelNumber,CASE WHEN ToDate < '9999-12-31' THEN ToDate+1 ELSE ToDate END FROM dbo.HCH01EmailHistory 
UNION
SELECT PersonnelNumber,FromDate FROM dbo.HCH01EmployeeManagerHistory 
UNION
SELECT PersonnelNumber,CASE WHEN ToDate < '9999-12-31' THEN ToDate+1 ELSE ToDate END FROM dbo.HCH01EmployeeManagerHistory 
UNION
SELECT PersonnelNumber,FromDate FROM dbo.HCH01PersonPositionHistory 
UNION
SELECT PersonnelNumber,CASE WHEN ToDate < '9999-12-31' THEN ToDate+1 ELSE ToDate END FROM dbo.HCH01PersonPositionHistory 
UNION
SELECT PersonnelNumber,FromDate FROM dbo.HCH01PartTimeHistorys
UNION
SELECT PersonnelNumber,CASE WHEN ToDate < '9999-12-31' THEN ToDate+1 ELSE ToDate END FROM dbo.HCH01PartTimeHistorys)
,DateFromToM AS (
SELECT 
td.PersonnelNumber
,td.DatePoint AS FromDate 
,td1.DatePoint AS ToDate
,ROW_NUMBER() OVER (PARTITION BY td.PersonnelNumber,td.DatePoint ORDER BY td1.DatePoint ASC) AS sortASC 
FROM Type2Date td
JOIN Type2Date td1 ON td1.DatePoint > td.DatePoint AND td.PersonnelNumber = td1.PersonnelNumber)
,DateFromTo AS (
SELECT 
dft.PersonnelNumber
,dft.FromDate
,dft.ToDate
FROM DateFromToM dft
WHERE dft.sortASC = 1
)
SELECT 
dft.PersonnelNumber
,dft.FromDate
,dft.ToDate
,e.EmailName
,m.ReportsToPersonnelNumber
,p.CompanyCode
,p.CostCenterCode
,p.PositionNumber
,t.TimeWorkedPercentage
FROM DateFromTo dft
LEFT JOIN HCH01EmailHistory e ON e.PersonnelNumber =dft.PersonnelNumber AND dft.FromDate >= e.FromDate AND dft.ToDate <= CASE WHEN e.ToDate < '9999-12-31' THEN e.ToDate+1 ELSE e.ToDate END
LEFT JOIN HCH01EmployeeManagerHistory m ON m.PersonnelNumber =dft.PersonnelNumber AND dft.FromDate >= m.FromDate AND dft.ToDate <= CASE WHEN m.ToDate < '9999-12-31' THEN m.ToDate+1 ELSE m.ToDate END
LEFT JOIN HCH01PersonPositionHistory p ON p.PersonnelNumber =dft.PersonnelNumber AND dft.FromDate >= p.FromDate AND dft.ToDate <= CASE WHEN p.ToDate < '9999-12-31' THEN p.ToDate+1 ELSE p.ToDate END
LEFT JOIN HCH01PartTimeHistorys t ON t.PersonnelNumber =dft.PersonnelNumber AND dft.FromDate >= t.FromDate AND dft.ToDate <= CASE WHEN t.ToDate < '9999-12-31' THEN t.ToDate+1 ELSE t.ToDate END
WHERE 
(
e.EmailName IS NOT NULL
OR m.ReportsToPersonnelNumber IS NOT NULL
OR p.CompanyCode IS NOT NULL
OR p.CostCenterCode IS NOT NULL
OR p.PositionNumber IS NOT NULL
OR t.TimeWorkedPercentage IS NOT NULL
)
--AND dft.PersonnelNumber = 317941
ORDER BY dft.PersonnelNumber,dft.FromDate,dft.ToDate

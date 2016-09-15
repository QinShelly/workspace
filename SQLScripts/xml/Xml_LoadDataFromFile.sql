CREATE TABLE dbo.CD_Info (
  Title        varchar(100),
  Artist       varchar(100),
  Country      varchar(25),
  Company      varchar(100),
  Price        numeric(5,2),
  YearReleased smallint);
  
DECLARE @CD TABLE (XMLData XML);
INSERT INTO @CD
SELECT *
FROM OPENROWSET(BULK N'C:\SQL\cd_catalog.xml', SINGLE_BLOB) rs;

INSERT INTO dbo.CD_Info (Title, Artist, Country, Company, Price, YearReleased)
SELECT Title = x.data.value('TITLE[1]','varchar(100)'),
       Artist = x.data.value('ARTIST[1]','varchar(100)'),
       Country = x.data.value('COUNTRY[1]','varchar(25)'),
       Company = x.data.value('COMPANY[1]','varchar(100)'),
       Price = x.data.value('PRICE[1]','numeric(5,2)'),
       YearReleased = x.data.value('YEAR[1]','smallint')
FROM @CD t
       CROSS APPLY t.XMLData.nodes('/CATALOG/CD') x(data);
SELECT * 
FROM dbo.CD_Info;

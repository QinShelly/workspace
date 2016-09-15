CREATE MEMBER CURRENTCUBE.[Measures].[DC On Hand and On Order vs. Expected Demand Var Volume Cases (NPI)]
 AS [Measures].[DC On Hand and On Order Volume Cases] - [Measures].[Future NPI Store Shelf Capacity Volume Cases],
DISPLAY_FOLDER = 'Use Cases',ASSOCIATED_MEASURE_GROUP = 'STORE SALES',FORMAT_STRING = "#,##0.00",VISIBLE = 0;

CREATE MEMBER CURRENTCUBE.[Measures].[DC On Hand and On Order vs. Expected Demand Var Volume Units (NPI)]
 AS [Measures].[DC On Hand and On Order Volume Units] - [Measures].[Future NPI Store Shelf Capacity Volume Units],
DISPLAY_FOLDER = 'Use Cases',ASSOCIATED_MEASURE_GROUP = 'STORE SALES',FORMAT_STRING = "#,###",VISIBLE = 0;

CREATE MEMBER CURRENTCUBE.[Measures].[DC On Hand vs. Expected Demand Var Volume Cases (NPI)]
 AS [Measures].[DC On Hand Volume Cases]	- [Measures].[Future NPI Store Shelf Capacity Volume Cases],
DISPLAY_FOLDER = 'Use Cases',ASSOCIATED_MEASURE_GROUP = 'STORE SALES',FORMAT_STRING = "#,##0.00",VISIBLE = 0;

CREATE MEMBER CURRENTCUBE.[Measures].[DC On Hand vs. Expected Demand Var Volume Units (NPI)]
 AS [Measures].[DC On Hand Volume Units]	- [Measures].[Future NPI Store Shelf Capacity Volume Units],
DISPLAY_FOLDER = 'Use Cases',ASSOCIATED_MEASURE_GROUP = 'STORE SALES',FORMAT_STRING = "#,###",VISIBLE = 0;

CREATE MEMBER CURRENTCUBE.[Measures].[DC On Hand vs. Expected Demand Var Volume Cases (Promo)]
 AS [Measures].[DC On Hand Volume Cases] - [Measures].[DC Expected Demand Volume Cases],
DISPLAY_FOLDER = 'Use Cases',ASSOCIATED_MEASURE_GROUP = 'STORE SALES',FORMAT_STRING = "#,##0.00",VISIBLE = 0;

CREATE MEMBER CURRENTCUBE.[Measures].[DC On Hand vs. Expected Demand Var Volume Units (Promo)]
 AS [Measures].[DC On Hand Volume Units]	-	[Measures].[DC Expected Demand Volume Units],
DISPLAY_FOLDER = 'Use Cases',ASSOCIATED_MEASURE_GROUP = 'STORE SALES',FORMAT_STRING = "#,###",VISIBLE = 0;


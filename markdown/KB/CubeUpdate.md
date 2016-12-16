# Cube Update #
## Create Stage Cube ##
Materialize included in this step, This first Materialize gets latest Master Data from Dim HUB

Assume at first Live cube uses OLAP\_ITEM and SPD\_FACT\_PIVOT.   
*It may be using OLAP\_ITEM\_T too, but same concept can be applied.*   

Materialize is processed to the OLAP\_ITEM\_T table

Stage Cube uses OLAP\_ITEM\_T, SPD\_FACT\_PIVOT

## Data Integrity Pre-Sync ##
Move data from Pivot to Pivot\_Exception, as dimension data in OLAP\_ITEM may be removed in OLAP\_ITEM\_T.

Live cube uses OLAP\_ITEM and SPD\_FACT\_PIVOT.
 
Stage Cube uses OLAP\_ITEM\_T and SPD\_FACT\_PIVOT.

## Process Cube ##
Process the stage cube

## Cube Sync ##
Now Stage is replacing live cube

Live cube uses OLAP\_ITEM\_T and SPD\_FACT\_PIVOT

Stage Cube is still there and it uses OLAP\_ITEM\_T and SPD\_FACT\_PIVOT. But it is not accessible by customer

## Data Integrity Post-Sync ##
Move data from Pivot\_Exception to Pivot, because missing dimension earlier in OLAP\_ITEM may be added in OLAP\_ITEM\_T now
## Materialize ##
This second materialize in Cube Update can be just replaced by copy. 

Copy data from OLAP\_ITEM\_T TO OLAP\_ITEM   
*depending on which is materiazlied in first materialize*

This step is very important for other code to just refer to OLAP\_ITEM only, without worrying about OLAP\_ITEM\_T existence


# Illustration #
|Step \ Start Status                          |Live cube uses OLAP_ITEM|Live cube uses OLAP_ITEM_T| 
|-------------------------------------|:-----------------------:|:------------------------:|
|Materialize (1st Materialize)|MD materialized in OLAP_ITEM_T|MD materialized in OLAP_ITEM|
|Create Stage Cube |Stage cube uses OLAP_ITEM_T|Stage cube uses OLAP_ITEM|
|Data Integrity Pre-Sync              |PIVOT to PIVOT_Exception |PIVOT to PIVOT_Exception  |
|Cube Sync                            |Live cube uses OLAP_ITEM_T|Live cube uses OLAP_ITEM|
|Data Integrity Post-Sync             |PIVOT_Exception to Pivot|PIVOT_Exception to Pivot| 
|Materialize (2nd Materialize)|OLAP_ITEM_T copied to OLAP_ITEM|OLAP_ITEM copied to OLAP_ITEM_T|

# Cube Update #
## Create Stage Cube ##
Materialize included in this step, This first Materialize is necessary to get latest MD from Dim HUB

Say at first Live cube uses OLAP\_ITEM and SPD\_FACT\_PIVOT now. It can be actually using OLAP\_ITEM\_T too, but same concept can be applied.   

Materialize is processed to the OLAP\_ITEM\_T table

Stage Cube uses OLAP\_ITEM\_T, SPD\_FACT\_PIVOT
## Data Integrity Pre-Sync ##
Move data from Pivot to Pivot\_Exception, as dimension in OLAP\_ITEM may be removed in OLAP\_ITEM\_T now

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

Copy table from OLAP\_ITEM to OLAP\_ITEM\_T, or from OLAP\_ITEM\_T TO OLAP\_ITEM, depending on which is materiazlied in first materialize

This step is very important for other code to just use OLAP\_ITEM only, without worrying about OLAP\_ITEM\_T existence
==This Hot Fix is for 7001 release to add 4 customer files for toys==


The '1535_Toys_EDI_Issue_31844' do the following steps:

1.Remove 'Toys.sqlp' & 'Toys.sql'

2.Copy the 'ToysEdi.sqlp' & 'ToysEdi.sql' from hotfix to the build folder.

3.Remove files 'Toys.ps1' & 'Toys.mdx'

4.Copy the 'ToysEdi.mdx','Toys.mdx' & 'ToysEDI.ps1' from hotfix folder to build folder



-----------------------------------------------------------------
 ------- Deployment of Hot Fix 1535-----------
---------------------------------------------------------------

1) Engineering will apply this hotfix


2) Remove and copy the customer files:


1.Remove 'Toys.sqlp' & 'Toys.sql' under scripts\rdbms\dsm\custom

2.Copy the 'ToysEdi.sqlp' & 'ToysEdi.sql' from hotfix to the build folder:scripts\rdbms\dsm\custom

3.Remove files 'Toys.ps1' & 'Toys.mdx' under scripts\cubes\dsm\custom

4.Copy the 'Toys.mdx','ToysEdi.mdx' & 'ToysEDI.ps1' from hotfix folder to build folder:scripts\cubes\dsm\custom







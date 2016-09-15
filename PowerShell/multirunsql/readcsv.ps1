
$myitems = 
@([pscustomobject]@{server="pvd1wnfs99s.colo.retailsolutions.com";db="COTY_WALGREENS"},
[pscustomobject]@{server="prodp1fs134.colo.retailsolutions.com\STAGE";db="DANNON_AHOLD"},
[pscustomobject]@{server="prodp1fs156.colo.retailsolutions.com\STAGE";db="CONAGRA_FOODLION"})

$a  = $myitems | ConvertTo-CSV
Set-Content "a.txt" -Value $a -Encoding Unicode

$data = Import-Csv "a.txt"
$data
$myitems
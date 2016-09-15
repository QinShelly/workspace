Get-Content c:\temp\test.txt | Where-Object{$_ -match '"Box11"'} |
  ForEach-Object{($_ -split "\s+")[3]} | Measure-Object -Sum |
  Select-Object -ExpandProperty Sum

  gc c:\temp\test.txt | ?{$_ -match '"Box11"'} | %{($_ -split "\s+")[3]} |
  Measure -Sum | Select -Exp Sum

  Get-Content c:\temp\test.txt | ConvertFrom-Csv -Delimiter " "
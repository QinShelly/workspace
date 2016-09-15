use 5.010;

open (FH, "+<", "7file");
$line = <FH>;
$pos = tell (FH);
$line = <FH>;
$line =~ s/friend/cosmos/;
seek(FH,$pos,SEEK_SET);
print FH $line;
close(FH);
use warnings;
use strict;

open my $FH, '<', 'db.txt' or die $!;

while (local $_ = <$FH>)
{
    chomp;
    print((split ' ')[1], "\n") if /user\@example.com/;
}
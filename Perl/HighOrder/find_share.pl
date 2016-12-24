use Data::Dump qw(dump);
use 5.012_002;
use strict;
use warnings;

sub find_share {
	my ($target, $treasures) = @_;
#	printf ("target: %d\n", $target);
#	for $i (@$treasures) {print $i; print "\n"}
	return [] if $target == 0;
	return    if $target < 0 || @$treasures == 0;

	my ($first, @rest) = @$treasures;

	# printf ("first: %d\n", $first);
	# for $i (@rest) {print $i; print "\n"}
	my $solution = find_share($target - $first, \@rest);
	return [$first, @$solution] if $solution;
	return 		   find_share($target		  , \@rest);
}

$a = find_share(5, [1,2,4,8]);
print join(", ",@$a);
print "\n";
#local $, = ', ';
#say @$a;

#dump(find_share(5, [1,2,4,8]));
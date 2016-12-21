use 5.010;

sub binary{
	my ($n) = @_;
	return $n if $n == 0 || $n == 1;

	my $k = int($n/2);
	my $b = $n % 2;

	my $E = binary($k);
	return $E . $b;
}

say binary(37)
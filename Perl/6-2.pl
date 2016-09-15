use 5.010;
use utf8;
use autodie;

open my $file,  '<', '6-2file';
while (<$file>){
	chomp;
	say "i saw $_";
	$times{$_} += 1;
	say $times{$_};
}

while (($key,$value) = each %times)
{
	say "$key => $value";
}
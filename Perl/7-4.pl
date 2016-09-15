use 5.010;
use utf8;
use autodie;

$find = "Fred";
while (<>){
	if (/$find/){
		say "$_";
	}
}
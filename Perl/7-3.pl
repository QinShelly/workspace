use 5.010;
use utf8;
use autodie;

while (<>){
	if (/\./){
		say "$_";
	}
}
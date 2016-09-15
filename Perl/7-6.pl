use 5.010;
use utf8;
use autodie;

while (<>){
	if (/[wilma.*fred|fred.*wilma]/){
		say "$_";
	}
}
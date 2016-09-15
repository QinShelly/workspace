use 5.010;
use utf8;
use autodie;

while (($key,$value) = each %ENV){
	say "$key => $value";
}
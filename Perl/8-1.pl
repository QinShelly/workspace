use 5.010;

while (<>){
	chomp;
	if(/match/i){
		say "Matched: |$`<$&>$'|";
	} else {
		say "No match";
	}
}

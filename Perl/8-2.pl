use 5.010;

while (<>){
	chomp;
	if(/\b.*a\b/i){
		say "Matched: |$`<$&>$'|";
	} else {
		say "No match";
	}
}

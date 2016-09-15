use 5.010;

while (<>){
	chomp;
	if(/\b(.*a)\b/i){
		say "\$1 contains '$1'";
	} else {
		say "No match: |$_|";
	}
}

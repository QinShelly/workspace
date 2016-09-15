use 5.010;

while (<>){
	chomp;
	if(/\b(?<word>.*a)\b/i){
		say "'word' contains '$1'";
	} else {
		say "No match: |$_|";
	}
}

use 5.010;

while (<>){
	chomp;
	if(/\b(?<word>\w*a)\b(?<word2>.{0,5})/i){
		say "'word' contains '$+{word}'";
		say "'word2' contains '$+{word2}'";
	} else {
		say "No match: |$_|";
	}
}

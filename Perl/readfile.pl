use 5.010;

open (FH, "+<", "readfile.txt");
while ($line = <FH>) {
	@a = split(/ /, $line);
	#say @a[0];
	foreach $i  (@a) {
		say $i;
	}
}
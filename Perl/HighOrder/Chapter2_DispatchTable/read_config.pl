sub read_config {
	my ($filename, $actions) = @_;
	open my($CF), $filename or return; #Failure
	while (<$CF>) {
		chomp;
		my($directive,$rest) = split /\s+/,$_,2;
		if (exists $actions->{$directive}){
			$actions->{$directive}->($rest);
		} else {
			die "Unrecognized directive $directive on line $. of $filename; aborting";
		}
	}
	return 1; #Success
}

$dispatch_table = 
{ 	CHDIR 	=> \&change_dir,
	LOGFILE => \&open_log_file,
	VERBOSITY => \&set_verbosity
};

sub change_dir {
	my ($dir) = $_[0];
	chdir($dir)
	or die "Couldn't chdir '$_[0]': $!; aborting";;
}

sub open_log_file{
	print "open log file";
	open STDERR, ">>", $_[0]
		or die "Couldn't open log file '$_[0]': $!; aborting";
}

sub set_verbosity {
	$VERBOSITY = shift;
}

read_config(config_sample, $dispatch_table)
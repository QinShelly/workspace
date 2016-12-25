
sub read_config {
	my ($filename, $actions) = @_;
	open my($CF), $filename or return; #Failure
	while (<$CF>) {
		chomp;
		#print "$_\n";
		my($directive,$rest) = split /\s+/,$_,2;
		#print "$directive\n";
		if (exists $actions->{$directive}){
			print "exists: $directive\n";
			$actions->{$directive}->($rest, $actions);
		} else {
			die "Unrecognized directive $directive on line $. of $filename; aborting";
		}
	}
	return 1; #Success
}

$dispatch_table = 
{ 	CHDIR 	=> \&change_dir,
	LOGFILE => \&open_log_file,
	VERBOSITY => \&set_verbosity,
	DEFINE => \&define_config_directive
};

sub change_dir {
	#print "change dir\n";
	my ($dir) = $_[0];
	chdir($dir)
	or die "Couldn't chdir '$_[0]': $!; aborting";;
}

sub open_log_file{
	#print "open log file\n";
	open STDERR, ">>", $_[0]
		or die "Couldn't open log file '$_[0]': $!; aborting";
}

sub set_verbosity {
	#print "set verbosity\n";
	$VERBOSITY = shift;
}

sub define_config_directive {
  my ($rest, $dispatch_table) = @_;
  $rest =~ s/^\s+//;
  my ($new_directive, $def_txt) = split /\s+/, $rest, 2;

  if (exists $dispatch_table->{$new_directive}) {
    warn "$new_directive already defined; skipping.\n";
    return;
  }

  my $def = eval "sub { $def_txt }";
  if (not defined $def) {
    warn "Could not compile definition for `$new_directive': $@; skipping.\n";
    return;       
  }

  $dispatch_table->{$new_directive} = $def;
}


read_config('config_sample', $dispatch_table);


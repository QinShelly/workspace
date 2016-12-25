use HTML::TreeBuilder;
my $tree = HTML::TreeBuilder-> new;
$tree->ignore_ignorable_whitespace(0);
$tree->parse("<h1>What Junior <b>Said</b> Next</h1>".
	" <p>But I don't <font size=3 color=\"red\">want</font> ".
	"to go to bed now!</p>");
$tree->eof();


sub walk_html {
  my ($html, $textfunc, $elementfunc) = @_;
  return $textfunc->($html) unless ref $html;   # It's a plain string

  my @results;
  for my $item (@{$html->{_content}}) {
    push @results, walk_html($item, $textfunc, $elementfunc);
  }
  return $elementfunc->($html, @results);
}


sub print_if_h1tag {
	my $element = shift;
	my $text = join '', @_;
	print $text if $element->{_tag} eq 'h1';
	return $text;
}

#Caller Example 1
#print walk_html($tree, sub{ $_[0]}, sub {shift; join '', @_});
#Caller Example 2
#walk_html($tree, sub{ $_[0]}, \&print_if_h1tag);
#Caller Example 3
sub promote_if_h1tag {
	my $element = shift;

	# if ($element->{_tag} eq 'h1') {
	if ($element->{_tag} =~ /^h\d+$/) {
		return ['KEEPER', join '', map{$_->[1]} @_];
	} else {
		return @_;
	}
}

sub promote_if {
	my $is_interesting = shift;          
	my $element = shift;
	if ($is_interesting->($element->{_tag})) {
		return ['KEEPER', join '', map {$_->[1]} @_];
	} else {
		return @_;
	}
}

sub extract_headers {
	my $tree = shift;
	# use promote_if_h1tag
	#my @tagged_texts = walk_html($tree, sub{['MAYBE', $_[0]]}, \&promote_if_h1tag);
	# use promote_if, doesn't work
	my @tagged_texts = walk_html($tree, 
                             sub { ['maybe', $_[0]] }, 
                             sub { promote_if(
                                     sub { $_[0] eq 'h1' },
                                     $_[0])
                             });
	my @keepers = grep {$_->[0] eq 'KEEPER'} @tagged_texts;
	my @keeper_text = map { $_->[1] } @keepers;
	my $header_text = join '', @keeper_text;
	return $header_text;
}

print extract_headers($tree);
print "\n";


















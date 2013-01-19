use strict;

my %a=();
while (my $a=<>) {
	chomp $a;
	next if $a =~ /^#/;
	next if $a !~ /^\w/;
	my @a=split / /,$a;
#	print $a[0],$a[3],"\n";
	$a{$a[0]} += $a[3]/3;
}

print "#	Système	Rouge M: (ROUGE_1+ROUGE2+ROUGE4)/3\n";
foreach my $key (sort {$a{$b}<=>$a{$a}} keys %a) {
	printf "%s\t%10.5f\n",$key,$a{$key};
}


use strict;

my %a=();
while (my $a=<>) {
	chomp $a;
	next if $a =~ /^#/;
	next if $a !~ /^[\w| ]/;
	my @a=split /\t/,$a;

	$a{$a[0]} = $a[4] if (@a==5);
}

print "#	Système	Fresa M: (FRESA_1*FRESA_2*FRESA_4)/3\n";
foreach my $key (sort {$a{$b}<=>$a{$a}} keys %a) {
	printf "%s\t%10.5f\n",$key,$a{$key};
}


package ParseUtil::Build;

use base qw(Module::Build);

use YAML;
use Smart::Comments;
use Net::IDN::Encode ':all';
use Unicode::CharName 'uname';
use Regexp::Assemble::Compressed;
use utf8;


sub process_tld_data_files {    #{{{
    my $self = shift;
    my ($tld_data_file) = keys %{ $self->{properties}->{tld_data_files} };
    open my $fh, "<:encoding(utf8)", $tld_data_file;
    my @content = grep { $_ !~ /^(?:\!|\s+|\/)/ } <$fh>;
    chomp @content;
    close $fh;
    my @processed_tlds = map { reverse_puny_encode($_) } @content;

    my $regexp_obj = Regexp::Assemble::Compressed->new();
    foreach my $processed_tld (@processed_tlds) {
        my ($object,$has_wildcard) = @{$processed_tld}{qw/object has_wildcard/};
        my $regexp_chunk = '\Q'.$object.'\E';
        $regexp_chunk .= '\.[^\.]+\.' if $has_wildcard;
        $regexp_obj->add($regexp_chunk);
    }
    print "Got regex:\n".$regexp_obj->re()."\n";
}    #}}}

sub reverse_puny_encode {    #{{{
    my $object = shift;
    my $has_wildcard = 0;
    $has_wildcard = $object =~ s/\*\.//;    # remove leading "*." and flag
    $object =~ s/^[\P{Alnum}\s]*([\p{Alnum}\.]+)[\P{Alnum}\s]*$/$1/;
    my @segments = split /\./, $object;
    my @reversed_segments;
    # puny encode everything
    eval {
        @reversed_segments =
          map { domain_to_ascii($_) } reverse @segments;
    };
    if ( my $e = $@ ) {
        my @components = split //, $object;
        map { print $_. " " . uname( ord($_) ) . "\n" } @components;
        warn "Unable to process $object.\n"
        ."Please report this error to package author.";
    }
    
    my $reverse_joined = join "." => @reversed_segments;
    return { object => $reverse_joined, has_wildcard => $has_wildcard };
}    #}}}

"one, but we're not the same."

__END__

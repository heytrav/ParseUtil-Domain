package ParseUtil::Build;

use base qw(Module::Build);

use YAML;
use Smart::Comments;
use Net::IDN::Encode ':all';
use Encode;
#use Regexp::Assemble::Compressed;

sub process_tld_data_files { #{{{
    my $self = shift;
    my ($tld_data_file)  = keys %{$self->{ properties }->{tld_data_files}};
    open my $fh, "<:encoding(utf8)", $tld_data_file;
    my @content =  grep { $_ !~ /^(?:\!|\s+|\/)/ } <$fh>;
    chomp @content;
    close $fh;
    print Dump(\@content)."\n";
} #}}}

"one, but we're not the same."


__END__

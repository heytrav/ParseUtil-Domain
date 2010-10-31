package ParseUtil::Build;

use base qw(Module::Build);

use YAML;
use Smart::Comments;
use Regexp::Assemble::Compressed;

sub process_tld_data_files { #{{{
    my $self = shift;
    my ($tld_data_file)  = keys %{$self->{ properties }->{tld_data_files}};
    open my $fh, "<:encoding(utf8)", $tld_data_file;
    my $content = do { local $/; <$fh>;};
    close $fh;
    print $content;
} #}}}

"one, but we're not the same."


__END__

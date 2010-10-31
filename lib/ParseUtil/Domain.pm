package ParseUtil::Domain;

use strict;
use warnings;

use version 0.77; our $VERSION = qv("v0.0.1");
use Perl6::Export::Attrs;
use ParseUtil::Domain::ConfigData;

use Smart::Comments;

my $config = ParseUtil::Domain::ConfigData->config();

sub parse_domain : Export(:DEFAULT) { #{{{
    my $name = shift;
    ### executing with : $name
    my $data = _pre_process_domain_segments($name);
    return $data;

} #}}}

sub _pre_process_domain_segments { #{{{
    my $domain_string = shift;
    my @segments = split/[\.\x{FF0E}\x{3002}\x{FF61}]/, $domain_string;
    my @reverse = reverse @segments;
    my $tld;
    my $tld_regex = $config->{tld_regex};
    my $possible_sld = join "." => @segments[-1,-2];
    ### possible sld : $possible_sld
    my $possible_tld = $segments[-1];

    ### possible tld : $possible_tld

    
    

} #}}}



"one, but we're not the same";

__END__


=head1 NAME

ParseUtil::Domain - Utility for parsing domain name into its constituent
components.

=head1 SYNOPSIS

  use ParseUtil::Domain;

  my $processed = parse_domain("somedomain.com");
    #   $processed == { 
    #        domain => 'somedomain',
    #        tld => 'com',
    #        ace => undef
    #    }


=head1 DESCRIPTION



=head1 INTERFACE

=head2 parse_domain

Parse a domain name into its constituent components.


=head1 DEPENDENCIES


=head1 SEE ALSO



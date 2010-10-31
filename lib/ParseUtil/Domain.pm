package ParseUtil::Domain;

use strict;
use warnings;

use version 0.77; our $VERSION = qv("v0.0.1");
use Perl6::Export::Attrs;
use ParseUtil::Domain::ConfigData;
use Net::IDN::Encode ':all';
use Net::IDN::Punycode ':all';
use Smart::Comments;
use utf8;

sub parse_domain : Export(:DEFAULT) {    #{{{
    my $name = shift;
    ### executing with : $name
    my $zone = _find_zone($name);
    ### found zone : $zone
    

}    #}}}

sub _find_zone {    #{{{
    my $domain_string = shift;
    my @segments = split /[\@\.\x{FF0E}\x{3002}\x{FF61}]/, $domain_string;
    my $zone;
    my $tld_regex = ParseUtil::Domain::ConfigData->config('tld_regex');
    my $possible_sld =
      join "." => map { domain_to_ascii($_) } @segments[ -1, -2 ];
    return join "." => @segments[ -2, -1 ] if $possible_sld =~ /\A$tld_regex\z/;
    my $possible_tld = domain_to_ascii( $segments[-1] );
    return $segments[-1] if $possible_tld =~ /\A$tld_regex\z/;
    die "Could not find tld.";

}    #}}}

sub _punycode_segments { #{{{
    

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



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
    my @name_segments = split /\@/, $name;

    my @segments = split /[\.\x{FF0E}\x{3002}\x{FF61}]/, $name_segments[-1];
    ### executing with : $name
    my $zone = _find_zone( \@segments );
    ### found zone : $zone
    my $puny_processed = _punycode_segments( \@segments, $zone );

}    #}}}

sub _find_zone {    #{{{
    my $domain_segments = shift;
    my $zone;
    my $tld_regex = ParseUtil::Domain::ConfigData->config('tld_regex');
    my $tld       = pop @{$domain_segments};
    my $sld       = pop @{$domain_segments};

    my $possible_tld = join "." => map { domain_to_ascii($_) } $sld,
      $tld;
    if ( $possible_tld =~ /\A$tld_regex\z/ ) {
        return { zone => $possible_tld, domain => $domain_segments };
    }
    if ( $tld =~ /\A$tld_regex\z/ ) {
        push @{$domain_segments}, $sld;
        return { zone => $tld, domain => $domain_segments };
    }
    die "Could not find tld.";
}    #}}}

sub _punycode_segments {    #{{{
    my ( $domain_segments, $zone ) = @_;

}    #}}}

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



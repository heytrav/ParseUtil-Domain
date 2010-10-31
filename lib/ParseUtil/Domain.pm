package ParseUtil::Domain;

use strict;
use warnings;

use version 0.77; our $VERSION = qv("v0.0.1");
use Perl6::Export::Attrs;
use ParseUtil::Domain::ConfigData;
use Net::IDN::Encode ':all';
use Net::IDN::Punycode ':all';
use Smart::Comments;
use YAML;
use utf8;

sub parse_domain : Export(:DEFAULT) {    #{{{
    my $name = shift;
    my @name_segments = split /\@/, $name;
    ### namesegments : Dump(\@name_segments)

    my @segments = split /[\.\x{FF0E}\x{3002}\x{FF61}]/, $name_segments[-1];
    ### executing with : $name
    my ( $zone,$zone_ace, $domain_segments ) =
      @{ _find_zone( \@segments ) }{qw/zone zone_ace domain/};
    ### found zone : $zone
    ### found zone_ace : $zone_ace

    my $puny_processed = _punycode_segments( $domain_segments, $zone );
    ### puny_processed : Dump($puny_processed)

}    #}}}

sub _find_zone {    #{{{
    my $domain_segments = shift;
    my $tld_regex       = ParseUtil::Domain::ConfigData->config('tld_regex');
    my $tld             = pop @{$domain_segments};
    my $sld             = pop @{$domain_segments};

    my $possible_tld = join "." => map { domain_to_ascii($_) } $tld, $sld;
    my @zone_params;
    if ( $possible_tld =~ /\A$tld_regex\z/ ) {
        my $zone = join "." => $sld, $tld;
        my $zone_ace = join "." => map { domain_to_ascii($_)} $sld, $tld;
        push @zone_params, zone_ace => $zone_ace
          unless $zone eq $zone_ace;
        return {
            zone   => $zone,
            domain => $domain_segments,
            @zone_params,
        };
    }
    my $zone_ace = domain_to_ascii($tld);
    if ( $zone_ace =~ /\A$tld_regex\z/ ) {
        push @{$domain_segments}, $sld;
        push @zone_params, zone_ace => $zone_ace
          unless $zone_ace eq $tld;

        return {
            zone     => $tld,
            domain   => $domain_segments,
            @zone_params
        };
    }
    die "Could not find tld.";
}    #}}}

sub _punycode_segments {    #{{{
    my ( $domain_segments, $zone ) = @_;

    if ($zone !~ /^de$/) {
        my $puny_encoded = [map { domain_to_ascii($_)  } @{$domain_segments} ];
        my $puny_decoded = [ map { domain_to_unicode($_)  } @{$puny_encoded}
        ];
        return { domain => $puny_decoded, domain_ace => $puny_encoded};
    }
   
    my @sub_param;

}    #}}}

sub _non_normative_punyencode { #{{{
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



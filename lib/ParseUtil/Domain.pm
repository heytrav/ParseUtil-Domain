package ParseUtil::Domain;

use strict;
use warnings;

use version 0.77; our $VERSION = qv("v1.0.1");
use Perl6::Export::Attrs;
use ParseUtil::Domain::ConfigData;
use Net::IDN::Encode ':all';
use Net::IDN::Punycode ':all';
use Net::IDN::Nameprep;

#use Smart::Comments;
use YAML;
use utf8;

sub parse_domain : Export(:DEFAULT) {    #{{{
    my $name = shift;
    my @name_segments = split /\@/, $name;
    ### namesegments : Dump(\@name_segments)

    my @segments = split /[\.\x{FF0E}\x{3002}\x{FF61}]/, $name_segments[-1];
    ### executing with : $name
    my ( $zone, $zone_ace, $domain_segments ) =
      @{ _find_zone( \@segments ) }{qw/zone zone_ace domain/};
    ### found zone : $zone
    ### found zone_ace : $zone_ace

    my $puny_processed = _punycode_segments( $domain_segments, $zone );
    @{$puny_processed}{qw/zone zone_ace/} = ( $zone, $zone_ace );

    # process .name "email" domains
    if ( @name_segments > 1 ) {
        my $punycoded_name = _punycode_segments( [ $name_segments[0] ], $zone );
        my ( $name_domain, $name_ace ) =
          @{$punycoded_name}{qw/domain domain_ace/};
        $puny_processed->{domain} = join '@' => $name_domain,
          $puny_processed->{domain};
        if ($name_ace) {
            $puny_processed->{domain_ace} = join '@' => $name_ace,
              $puny_processed->{domain_ace};
        }
    }
    return $puny_processed;

}    #}}}

sub _find_zone {    #{{{
    my $domain_segments = shift;
    my $tld_regex       = ParseUtil::Domain::ConfigData->config('tld_regex');
    my $tld             = pop @{$domain_segments};
    my $sld             = pop @{$domain_segments};
    my $thld            = pop @{$domain_segments};

    my ( $possible_tld, $possible_thld );
    my ( $sld_zone_ace, $tld_zone_ace ) =
      map { domain_to_ascii( nameprep $_) }$sld, $tld;
      my $thld_zone_ace;
       $thld_zone_ace = domain_to_ascii( nameprep $thld) if $thld;
    if ( $tld =~ /^de$/ ) {
        ### is a de domain
        $possible_tld = join "." => $tld, _puny_encode($sld);
    }
    else {
        $possible_tld  = join "." => $tld_zone_ace, $sld_zone_ace;
        $possible_thld = join "." => $possible_tld, $thld_zone_ace if
        $thld_zone_ace;
    }
    my ( $zone, @zone_params );

    if ($possible_thld and  $possible_thld =~ /\A$tld_regex\z/ ) {
        my $zone_ace = join "." => $thld_zone_ace, $sld_zone_ace, $tld_zone_ace;
        $zone = join "." => $thld, $sld, $tld;
        push @zone_params, zone_ace => $zone_ace;
    }
    elsif ( $possible_tld =~ /\A$tld_regex\z/ ) {
        push @{$domain_segments}, $thld;
        my $zone_ace = join "." =>$sld_zone_ace, $tld_zone_ace ;
        $zone = join "." => $sld, $tld;
        push @zone_params, zone_ace => $zone_ace;
    }
    elsif ( $tld_zone_ace =~ /\A$tld_regex\z/ ) {
        push @{$domain_segments}, $thld if $thld;
        push @{$domain_segments}, $sld;
        push @zone_params, zone_ace => $tld_zone_ace;
        $zone = $tld;
    }
    die "Could not find tld." unless $zone;
    my $unicode_zone = domain_to_unicode($zone);
    return {
        zone   => $unicode_zone,
        domain => $domain_segments,
        @zone_params
    };
}    #}}}

sub _punycode_segments {    #{{{
    my ( $domain_segments, $zone ) = @_;

    if ( not $zone or $zone !~ /^de$/ ) {
        my $puny_encoded =
          [ map { domain_to_ascii( nameprep $_) } @{$domain_segments} ];
        my $puny_decoded = [ map { domain_to_unicode($_) } @{$puny_encoded} ];
        return {
            domain     => ( join "." => @{$puny_decoded} ),
            domain_ace => ( join "." => @{$puny_encoded} )
        };
    }

    # Have to avoid the nameprep step for .de domains now that DENIC has
    # decided to allow the German "sharp S".
    my $puny_encoded = [ map { _puny_encode($_) } @{$domain_segments} ];
    my $puny_decoded = [ map { _puny_decode($_) } @{$puny_encoded} ];
    return {
        domain     => ( join "." => @{$puny_decoded} ),
        domain_ace => ( join "." => @{$puny_encoded} )
    };

}    #}}}

sub _puny_encode {    #{{{
    my $unencoded = shift;
    ### encoding : $unencoded
    # quick check to make sure that domain should be decoded
    my $temp_unencoded = nameprep $unencoded;
    ### namepreped : $temp_unencoded
    my $test_encode = domain_to_ascii($temp_unencoded);
    return $unencoded if $test_encode eq $unencoded;
    return "xn--" . encode_punycode($unencoded);
}    #}}}

sub _puny_decode {    #{{{
    my $encoded = shift;
    $encoded =~ s/^xn--//;
    ### decoding : $encoded
    my $test_decode = decode_punycode($encoded);
    ### test decode : $test_decode
    return $encoded if $encoded eq $test_decode;
    return decode_punycode($encoded);

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
    #        domain_ace => 'somedomain',
    #        zone => 'com',
    #        zone_ace => 'com'
    #    }


=head1 DESCRIPTION


Just another tool for parsing domain names.  This module makes use of the data
provided by the I<Public Suffix List> (http://publicsuffix.org/list/) to parse
tlds.  For completeness it tries to provide the respective puny encoded and decoded
domain and tld part of a domain name.  This includes proper handling of the
B<LATIN SHARP S> which is now allowed by DENIC eG (.de).


=head1 INTERFACE



=head2 parse_domain

=over 2

=item
Arguments


=over 3

=item
C<string>


Examples:

  1. 'somedomain.com' 
  2. 'test.xn--o3cw4h'
  3. 'bloß.co.at'
  4. 'bloß.de'


=back


=item
Return

=over 3


=item
C<HASHREF>


Examples:
  
  1.
  { 
    domain => 'somedomain',
    zone => 'com',
    domain_ace => 'somedomain',
    zone_ace => 'com'
   }

  2.
  { 
    domain => 'test',
    zone => 'ไทย',
    domain_ace => 'test',
    zone_ace => 'xn--o3cw4h'
   }

  3.
  { 
    domain => 'bloss',
    zone => 'co.at',
    domain_ace => 'bloss',
    zone_ace => 'co.at'
   }

  4.
  { 
    domain => 'bloß',
    zone => 'de',
    domain_ace => 'xn--blo-7ka',
    zone_ace => 'de'
   }



=back



=back



=head1 DEPENDENCIES

=over 3


=item
L<Net::IDN::Encode>


=item
L<Net::IDN::Punycode>


=item
L<Regexp::Assemble::Compressed>


=item
The Public Suffix List at http://publicsuffix.org/list/


=back


=head1 BUGS

Although, not necessarily a bug, be wary of differences in encoding/decoding
domains ending in B<.de>.  These domains are not I<nameprep>ed like other tlds
in order to allow for encoding of the German B<LATIN SHARP S>.





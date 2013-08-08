use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass( code => <<'EOF');

use utf8;

sub process_tld_data_files {    #{{{
    require Regexp::Assemble::Compressed;
    my $self = shift;
    my ($tld_data_file) = keys %{ $self->{properties}->{tld_data_files} };
    open my $fh, "<:encoding(utf8)", $tld_data_file;
    my @content = grep { $_ !~ /^(?:\s+|\/)/ } <$fh>;
    chomp @content;
    close $fh;
    my @processed_tlds = map { reverse_puny_encode($_) } @content;

    my $wildcards = {};
    my $regexp_obj = Regexp::Assemble::Compressed->new();
    
    foreach my $processed_tld (@processed_tlds) {
        my ($object,$has_wildcard,$has_exclusion) = @{$processed_tld}{qw/object has_wildcard has_exclusion/};
        my $regexp_chunk = '';
        if( $has_wildcard && ! defined $wildcards->{ $object } ) {
          $wildcards->{ $object } =  [];
        }
        elsif( $has_exclusion ) {
          my @segments = split /\./, $object;
          my $exclude = pop( @segments );
          my $wildcard = join "." => @segments;
          if( ! defined $wildcards->{$wildcard} ) {
            $wildcards->{ $wildcard } =  [];
          }
          my $exclusions = $wildcards->{$wildcard};
          push( @$exclusions, $exclude );
        }
        else {
          $regexp_chunk = '\Q'.$object.'\E';
          $regexp_obj->add($regexp_chunk);
        }
    }
    # special rules for wildcards
    foreach my $wildcard ( keys %$wildcards ) {
      my $exclusions = $wildcards->{$wildcard}; 
      my $regexp_chunk = '\Q'.$wildcard.'\E\.'; 
      foreach my $exclusion ( @$exclusions ) {
        $regexp_chunk .= '(?!'.$exclusion.'$)';
      }
      $regexp_chunk .= '[^\.]+';
      $regexp_obj->add($regexp_chunk);

      # still need to match on the actual wildcard
      $regexp_chunk = '\Q'.$wildcard.'\E'; 
      $regexp_obj->add($regexp_chunk);

    }
    $self->config_data(tld_regex => $regexp_obj->re());
}    #}}}

sub reverse_puny_encode {    #{{{
    require Net::IDN::Encode;# ':all';
    require Unicode::CharName;# q{uname};
    my $object = shift;
    my $has_wildcard = 0;
    my $has_exclusion = 0;
    $has_wildcard = $object =~ s/\*\.//;    # remove leading "*." and flag
    $has_exclusion = $object =~ s/\!//;    # remove leading "!." and flag

    $object =~ s/^[\P{Alnum}\s]*([\p{Alnum}\.]+)[\P{Alnum}\s]*$/$1/;
    my @segments = split /\./, $object;
    my @reversed_segments;
    # puny encode everything
    eval {
        @reversed_segments =
          map { Net::IDN::Encode::domain_to_ascii($_) } reverse @segments;
    };
    if ( my $e = $@ ) {
        my @components = split //, $object;
        map { print $_. " " . Unicode::CharName::uname( ord($_) ) . "\n" } @components;
        warn "Unable to process $object.\n"
        ."Please report this error to package author.";
    }

    my $reverse_joined = join "." => @reversed_segments;
    return { object => $reverse_joined, has_wildcard => $has_wildcard, has_exclusion => $has_exclusion };
}    #}}}

EOF

my $builder = $class->new(
    module_name          => 'ParseUtil::Domain',
    license              => 'perl',
    dist_author          => 'Trav Holton <heytrav@cpan.org>',
    dist_version_from    => 'lib/ParseUtil/Domain.pm',
    recursive_test_files => 1,
    meta_merge           => {
        resources => {
            repository => 'git://github.com/heytrav/ParseUtil-Domain.git',
        }
    },
    configure_requires => { 'Module::Build' => 0.4 },
    build_requires     => {
        'Regexp::Assemble::Compressed' => 0,
        'Perl::Critic'                 => 0,
        'Smart::Comments'              => 0,
        'Test::More'                   => 0,
        'Test::Class'                  => 0,
        'Test::Deep'                   => 0,
        'Test::Perl::Critic'           => 0,
        'Net::IDN::Encode'             => 2.003,
        'Unicode::CharName'            => 1.07,
        'Test::Routine'                => 0,
        'namespace::autoclean'         => 0,
    },
    requires => {
        'Carp'                 => 1.17,
        'Net::IDN::Encode'     => 2.003,
        'Net::IDN::Nameprep'   => 1.101,
        'Net::IDN::Punycode'   => 1.100,
        'Perl6::Export::Attrs' => 0,
        'perl5i'               => 0,
    },
    add_to_cleanup => ['ParseUtil-*'],
    tld_data_files =>
      { 'data/effective_tld_names.txt' => 'data/effective_tld_names.txt' }
);

$builder->add_build_element('tld_data');
$builder->create_build_script();


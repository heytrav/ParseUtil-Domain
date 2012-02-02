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
    my @content = grep { $_ !~ /^(?:\!|\s+|\/)/ } <$fh>;
    chomp @content;
    close $fh;
    my @processed_tlds = map { reverse_puny_encode($_) } @content;

    my $regexp_obj = Regexp::Assemble::Compressed->new();
    foreach my $processed_tld (@processed_tlds) {
        my ($object,$has_wildcard) = @{$processed_tld}{qw/object has_wildcard/};
        my $regexp_chunk = '\Q'.$object.'\E';
        $regexp_chunk .= '\.[^\.]+' if $has_wildcard;
        $regexp_obj->add($regexp_chunk);
    }
    $self->config_data(tld_regex => $regexp_obj->re());
}    #}}}

sub reverse_puny_encode {    #{{{
    require Net::IDN::Encode;# ':all';
    require Unicode::CharName;# q{uname};
    my $object = shift;
    my $has_wildcard = 0;
    $has_wildcard = $object =~ s/\*\.//;    # remove leading "*." and flag
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
    return { object => $reverse_joined, has_wildcard => $has_wildcard };
}    #}}}

EOF

my $builder = $class->new(
    module_name          => 'ParseUtil::Domain',
    license              => 'perl',
    dist_author          => 'William Travis Holton <wtravisholton@yahoo.de>',
    dist_version_from    => 'lib/ParseUtil/Domain.pm',
    recursive_test_files => 1,
    build_requires       => {
        'Regexp::Assemble::Compressed' => 0,
        'Perl::Critic'                 => 0,
        'Smart::Comments'              => 0,
        'YAML'                         => 0,
        'Test::More'                   => 0,
        'Test::Class'                  => 0,
        'Test::Deep'                   => 0,
        'Test::Perl::Critic'           => 0,
        'Net::IDN::Encode'             => 0,
        'Unicode::CharName'            => 0,
        'List::MoreUtils'              => 0,
    },
    requires => {
        'version'              => 0.77,
        'Net::IDN::Encode'     => 0,
        'Net::IDN::Nameprep'   => 0,
        'Net::IDN::Punycode'   => 0,
        'Perl6::Export::Attrs' => 0,
    },
    add_to_cleanup => ['ParseUtil-*'],
    tld_data_files =>
      { 'data/effective_tld_names.txt' => 'data/effective_tld_names.txt' }
);

$builder->add_build_element('tld_data');
$builder->create_build_script();


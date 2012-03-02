package ToggleTester;

use Test::Routine;

use Test::More;
use Test::Deep;
use Test::Exception;
use namespace::autoclean;

use ParseUtil::Domain ':simple';

has domains_to_test => (
    is      => 'ro',
    isa     => 'ArrayRef',
    builder => 'get_domains_to_test'
);


test => puny_toggle => { desc => 'Toggle unicode <-> ascii domains' } => sub {
    my ($self) = @_;

    my $domains_to_test = $self->domains_to_test();
    foreach my $domain ( @{$domains_to_test} ) {
        lives_ok {
            puny_convert($domain);
        }
        'No problems parsing domain';
    }
};


1;

__END__

=head1 NAME

ToggleTester - ShortDesc

=head1 SYNOPSIS

# synopsis...

=head1 DESCRIPTION

# longer description...



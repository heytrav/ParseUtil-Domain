package UnicodeToggle;

use Moose;
use perl5i::2;
use utf8;

has get_domains_to_test => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        return [
            qw/
            bloß.de
            test.xn--o3cw4h
            bloß.co.at
            /
        ];
      }
);


__END__

=head1 NAME

UnicodeToggle - ShortDesc

=head1 SYNOPSIS

# synopsis...

=head1 DESCRIPTION

# longer description...



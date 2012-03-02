package UnicodeToggle;

use Moose;

has get_domains_to_test => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        [
            qw/
            bloß.de
            test.xn--o3cw4h
            bloß.co.at
              /
        ];
      }
);

1;

__END__

=head1 NAME

UnicodeToggle - ShortDesc

=head1 SYNOPSIS

# synopsis...

=head1 DESCRIPTION

# longer description...



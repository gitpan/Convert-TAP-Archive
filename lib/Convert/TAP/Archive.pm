package Convert::TAP::Archive;
{
  $Convert::TAP::Archive::VERSION = '0.001';
}

use strict;
use warnings;

use Capture::Tiny qw( capture_merged );
use TAP::Harness;
use TAP::Harness::Archive;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(convert_from_taparchive);

# ABSTRACT: Read from a TAP archive and convert it for displaying

# one and only subroutine of this module
sub convert_from_taparchive {

    # Input Arguments
    my $archive_absolutepath       = shift;
    my $output_formatter_classname = shift || 'TAP::Formatter::HTML';

    # This is the complicate but flexible version to:
    #   use TAP::Formatter::HTML;
    #   my $formatter = TAP::Formatter::HTML->new;
    my $formatter;
    (my $require_name = $output_formatter_classname . ".pm") =~ s{::}{/}g;
    eval {
        require $require_name;
        $formatter = $output_formatter_classname->new();
    };  
    die "Problems with formatter $output_formatter_classname"
      . " at $require_name: $@"
        if $@;

    # Now we do a lot of magic to convert this stuff...

    my $harness   = TAP::Harness->new({ formatter => $formatter }); 

    $formatter->verbose(0);
    $formatter->prepare;

    my $session;
    my $aggregator = TAP::Harness::Archive->aggregator_from_archive({ 
        archive          => $archive_absolutepath,
        parser_callbacks => {
            ALL => sub {
                $session->result( $_[0] );
            },  
        },  
        made_parser_callback => sub {
                # TODO: this code here print to STDOUT, this is baaaaaaaad
                $session = $formatter->open_test( $_[1], $_[0] );
        }   
    });

    $aggregator->start;
    $aggregator->stop;

    # This code also prints to STDOUT but we will catch it!
    return capture_merged { $formatter->summary($aggregator) };

}

1;

__END__

=pod

=head1 NAME

Convert::TAP::Archive - Read from a TAP archive and convert it for displaying

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Convert::TAP::Archive qw(convert_from_taparchive);

 my $html = convert_from_taparchive(
                '/must/be/the/complete/path/to/test.tar.gz',
                'TAP::Formatter::HTML',
            );

=encoding utf8

=head1 ABOUT

This modul can be of help for you if you have TAP archives (e.g. created with C<prove -a> and now you wish to have the content of this archives in a special format like HTML or JUnit.

=head1 EXPORTED METHODS

=head2 convert_from_taparchive

The method takes two arguments.
The first is required.
It is the B<full> path to your TAP archive.
The second defaults to C<TAP::Formatter::HTML>, but you can give any other formatter.
The method will return the content of the TAP archive, parsed according to the formatter you have specified.

 my $html = convert_from_taparchive(
                '/must/be/the/complete/path/to/test.tar.gz',
                'TAP::Formatter::HTML',
            );

=head1 BUGS AND LIMITATIONS

=over

=item *

The author of this module has no expert knowledge about TAP processing and this means, this code could be crap.
The author wrote this module, because he didn't find any better solution for the simple task of reading and parsing a TAP archive.

=item *

The method prints the pure TAP to C<STDOUT>, because the parsing library is doing so... you'll have to live with it or send a patch that fixes this.
The section in the code producing this behaviour is marked with a I<TODO>.

=item *

For now there are no tests implemented to ensure quality.

=back

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>, Renée Bäcker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Boris Däppen, Renée Bäcker, plusW.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

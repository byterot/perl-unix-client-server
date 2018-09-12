#!/usr/bin/perl

use strict;
use IO::Socket::UNIX;
use Carp;
use Time::HiRes qw(time);
use Data::Dumper;

# unbufferred, line oriented, nl terminated ascii stream, with request, empty_line, and response
$|=1;

$SIG{PIPE}='IGNORE';

my $SOCK_PATH = "/tmp/foo";

sub tm {
    sprintf "%.6f", time();
}

print tm() . " starting connection\n";
my $client = IO::Socket::UNIX->new(
    Type => SOCK_STREAM(),
    Peer => $SOCK_PATH,
);

sub comms {
    while(<STDIN>) {
        print tm() . " writing: $_";
        print $client $_ or die $@;
        /^\s*$/ && last;
    }
    while(<$client>) {
        print tm() . " read: $_";
    }
}

comms();


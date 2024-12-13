#!/usr/bin/perl -w
use IO::Socket;

my $num_args = $#ARGV + 1;
if ($num_args != 3) {
    print "\nUsage: send-notify-network.pl <ip> <titre> <texte>\n";
    exit;
}

my $host=$ARGV[0];
my $title=$ARGV[1];
my $message=$ARGV[2];

my $sock = new IO::Socket::INET->new( PeerAddr => $host,
                                      PeerPort => '50000',
                                      Proto => 'udp',
                                      Timeout => 1
                                      ) or die ("Could not create socket: $@\n");
                                      
my $msg = "\"${title}\" \"${message}\"\n" ;
$sock->send( $msg ) or die "Send error: $!\n";

sleep (1);
close( $sock)
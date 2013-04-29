#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: dns_resolver.pl
#
#        USAGE: ./dns_resolver.pl
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: SHIE, Li-Yi
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 2013/04/29 10:34:55
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use Net::DNS;
use Parallel::ForkManager;

my @NAME_SERVERS = qw(
  140.114.64.1
  140.114.63.1
  168.95.1.1
  168.95.192.1
  8.8.8.8
  8.8.4.4
  208.67.222.222
  208.67.220.220
  192.71.245.208
);

my @QUESTIONS = qw(
  www.google.com
  www.google.com.tw
  www.kimo.com.tw
  www.yahoo.com
  www.facebook.com
  www.nthu.edu.tw
  www.edu.tw
  www.youtube.com
  plus.garena.tw
  mirror.uoregon.edu
  www.eecs.mit.edu
  www.hinet.net
  fedoraproject.org
);

my %ANSWERS = ();

sub main {
    my $max_procs = 10;
    my $pm        = Parallel::ForkManager->new($max_procs);

    foreach my $ns (@NAME_SERVERS) {
        $pm->start and next;
        my $res = Net::DNS::Resolver->new(
            nameservers => [$ns],
            debug       => 0,
            retry       => 2,
            tcp_timeout => 10,
            udp_timeout => 10,
        );

        foreach my $ques (@QUESTIONS) {

            my $packet = $res->send( $ques, "A" );
            if ( defined($packet) ) {
                my @answers = $packet->answer;
                if (@answers) {
                    foreach my $a (@answers) {
                        if ( $a->type eq 'A' ) {
                            printf( "INFO: $ns => $ques [%s] %s\n",
                                $a->type, $a->address );
                        }
                        elsif ( $a->type eq 'CNAME' ) {
                            printf( "INFO: $ns => $ques [%s] %s\n",
                                $a->type, $a->name );
                        }
                        else {
                            printf( "INFO: $ns => $ques [%s]\n", $a->type );
                        }
                    }
                }
                else {
                    print "WARNING: No answer for ($ques) from ($ns).\n";
                }
            }
            else {
                print "WARNING: No result for ($ques) from ($ns).\n";
            }
        }
        $pm->finish;
    }

    $pm->wait_all_children;
}

main;

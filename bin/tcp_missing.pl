#!/usr/bin/env perl
#===============================================================================
#
#         FILE: tcp_missing.pl
#
#        USAGE: ./tcp_missing.pl www.google.com
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
#      CREATED: 2013/09/05 11:53:41
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use FindBin qw($RealBin);
use Digest::MD5 qw(md5_hex);
use File::Basename;

my $HASHED      = md5_hex( $ARGV[0] || die('ERROR: No given hostname') );
my $PF_PATH     = dirname($RealBin);
my $PF_LOG_PATH = "$PF_PATH/log";
my $PF_LOG_FILE = "$PF_LOG_PATH/$HASHED.log";

my %STATUS_COUNT = ();
my $PORT         = '';

my $begin = 9_999_999_999;
my $end   = 0;
my $total = 0;

open( FH, "<", $PF_LOG_FILE ) or die("ERROR: Can't open $PF_LOG_FILE");
while (<FH>) {
    if (m/^\[(\d+)\]\s+(\S+?)\s+port\s+(\d+)\s+(.+?)\./) {
        $begin = $1 if ( $1 < $begin );
        $end   = $1 if ( $1 > $end );

        my $time   = scalar( localtime($1) );
        my $host   = $2;
        my $port   = $3;
        my $status = lc($4);

        $STATUS_COUNT{$status} = 0 unless ( $STATUS_COUNT{$status} );
        $STATUS_COUNT{$status}++;

        $PORT = $port;
    }
}
close(FH);

map { $total += $STATUS_COUNT{$_}; } keys(%STATUS_COUNT);

print " HOST: ", $ARGV[0], "\n";
print " PORT: ", $PORT, "\n";
print "BEGIN: ", scalar( localtime($begin) ), "\n";
print "  END: ", scalar( localtime($end) ),   "\n";
print "TOTAL: ", $total, "\n";

foreach my $k ( sort keys(%STATUS_COUNT) ) {
    printf( "%16s => %8d (%5.1f%%)\n",
        $k, $STATUS_COUNT{$k}, $STATUS_COUNT{$k} / $total * 100 );
}

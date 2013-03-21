#!/usr/bin/env perl
#===============================================================================
#
#         FILE: missing.pl
#
#        USAGE: ./missing.pl www.google.com
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
#      CREATED: 2013/03/21 09:36:53
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

my $prev   = 0;
my $p_time = 0;

open( FH, "<", $PF_LOG_FILE ) or die("ERROR: Can't open $PF_LOG_FILE");
while (<FH>) {
    if (m/^\[(\d+)\.\d+\]\s.*?\sicmp_seq=(\d+)/) {
        my $c_time = scalar( localtime($1) );
        my $cur    = $2;
        if ( ( $cur - $prev ) > 1 ) {
            print "($p_time) $prev <=> $cur ($c_time), ", $cur - $prev, "\n";
        }
        $prev   = $cur;
        $p_time = $c_time;
    }
}
close(FH);

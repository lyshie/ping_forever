#!/usr/bin/env perl
#===============================================================================
#
#         FILE: curses_log.pl
#
#        USAGE: ./curses_log.pl www.google.com
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
#      CREATED: 2013/03/29 16:26:53
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use POE qw(Wheel::FollowTail);
use Curses::UI::POE;
use FindBin qw($Bin);
use Digest::MD5 qw(md5_hex);
use File::Basename;

# resolve hostname and log filename
my $HASHED      = md5_hex( $ARGV[0] || die('ERROR: No given hostname') );
my $PF_PATH     = dirname($Bin);
my $PF_LOG_PATH = "$PF_PATH/log";
my $PF_LOG_FILE = "$PF_LOG_PATH/$HASHED.log";

$| = 1;

my $ui;            # Curses::UI
my $poe_timer;     # POE timer session
my $poe_tailor;    # POE tailor session
my $interval = 3;  # tailor polling interval

my @current = ();  # buffer current ping logs
my @history = ();  # buffer history logs

my $now    = time();    # FIXME: bad global var should be stored in $_[HEAP]
my $prev   = 0;         # FIXME: bad global var should be stored in $_[HEAP]
my $p_time = 0;         # FIXME: bad global var should be stored in $_[HEAP]

my $who_focus =
  'win_current';        # change focus between 'win_current' and 'win_history'

sub init_ui {
    $ui = Curses::UI::POE->new(
        -clear_on_exit => 1,
        -color_support => 1,
        -mouse_support => 0,
    );

    # lyshie_20130329: shortcut/key bindings
    $ui->set_binding(
        sub {
            $interval++;
            $interval = 300 if ( $interval > 300 );
            $poe_kernel->call( $poe_tailor, 'reset' );
        },
        '+'
    );
    $ui->set_binding(
        sub {
            $interval--;
            $interval = 1 if ( $interval < 1 );
            $poe_kernel->call( $poe_tailor, 'reset' );
        },
        '-'
    );
    $ui->set_binding( sub { exit(0); },                          'q' );
    $ui->set_binding( sub { $ui->getobj($who_focus)->focus(); }, "\t" );
    $ui->set_binding( sub { show_about(); },                     "a" );

    # lyshie_20130329: default UI layout and draw
    my $win = $ui->add(
        'win_main', 'Window',
        -title => 'Realtime Ping Check Monitor',
        qw(
          -border 0
          -height -1
          -width -1
          ),
    );

    # help label
    my $label_help = $win->add(
        'label_help', 'Label',
        -text =>
'[Q]uit  [TAB] Switch Window  [Up/Down] Select entry  [+/-] Inc/Decrese time  [A]bout',
        qw(
          -y 0
          -height 1
          -width -1
          -bg blue
          -fg yellow
          ),
    );

    # timer label
    my $label_timer = $win->add(
        'label_timer', 'Label', qw(
          -text Show_current_time
          -textalignment right
          -y 1
          -height 1
          -width -1
          ),
    );

    # current window
    my $win_current = $ui->add(
        'win_current', 'Window',
        -title   => 'Current',
        -onfocus => sub { $who_focus = 'win_history' },
        qw(
          -border 1
          -y 2
          -height 15
          -width -1
          ),
    );

    # history window
    my $win_history = $ui->add(
        'win_history', 'Window',
        -title   => 'History',
        -onfocus => sub { $who_focus = 'win_current' },
        qw(
          -border 1
          -y 17
          -height -1
          -width -1
          ),
    );

    # current list
    my $listbox_current = $win_current->add(
        'listbox_current', 'Listbox', qw(
          -y 0
          -height -1
          -width -1
          ),
    );
    $listbox_current->clear_binding('loose-focus');

    # history list
    my $listbox_history = $win_history->add(
        'listbox_history', 'Listbox', qw(
          -y 0
          -height -1
          -width -1
          ),
    );
    $listbox_history->clear_binding('loose-focus');

    $listbox_current->focus();
    $listbox_history->focus();

    $win->draw();
}

# unused
sub layout_ui {
    my $win_main    = $ui->getobj('win_main');
    my $win_current = $ui->getobj('win_current');
    my $win_history = $ui->getobj('win_history');

    $win_main->layout();
    $win_current->layout();
    $win_history->layout();
}

# unused
sub draw_ui {
    my $win_main    = $ui->getobj('win_main');
    my $win_current = $ui->getobj('win_current');
    my $win_history = $ui->getobj('win_history');

    $win_main->draw();
    $win_current->draw();
    $win_history->draw();
}

# unused
sub update_ui {
    layout_ui();
    draw_ui();
}

sub show_about {
    my $ret = $ui->dialog("Author: SHIE, Li-Yi\nEmail: lyshie\@mx.nthu.edu.tw");
}

# timer session
sub init_poe_timer {
    $poe_timer = POE::Session->create(
        inline_states => {
            _start => sub {
                $_[KERNEL]->alarm( tick => time() + 1, 0 );
            },
            tick => sub {
                $_[KERNEL]->alarm( tock => time() + 1, 0 );
                my $heap =
                  $poe_kernel->ID_id_to_session( $poe_tailor->ID() )
                  ->get_heap();
                my $label_timer =
                  $ui->getobj('win_main')->getobj('label_timer');
                $label_timer->text(
                        scalar( localtime(time) )
                      . ' (Update every '
                      . $heap->{tailor}[4]
                      . ' seconds)' );
                $label_timer->draw();
            },
            tock => sub {
                $_[KERNEL]->alarm( tick => time() + 1, 0 );
                my $heap =
                  $poe_kernel->ID_id_to_session( $poe_tailor->ID() )
                  ->get_heap();
                my $label_timer =
                  $ui->getobj('win_main')->getobj('label_timer');
                $label_timer->text(
                        scalar( localtime(time) )
                      . ' (Update every '
                      . $heap->{tailor}[4]
                      . ' seconds)' );
                $label_timer->draw();
            },
        },
    );
}

# tail session
sub init_poe_tailor {
    $poe_tailor = POE::Session->create(
        inline_states => {
            _start => sub {
                $_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
                    Filename     => "$PF_LOG_FILE",
                    InputEvent   => 'got_log_line',
                    PollInterval => $interval,
                );
            },
            reset => sub {
                my $pos = $_[HEAP]{tailor}->tell() || 0;
                delete( $_[HEAP]{tailor} );
                $_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
                    Filename     => "$PF_LOG_FILE",
                    InputEvent   => 'got_log_line',
                    PollInterval => $interval,
                    Seek         => $pos,
                );
            },
            got_log_line => sub {
                my $listbox_current =
                  $ui->getobj('win_current')->getobj('listbox_current');
                my $listbox_history =
                  $ui->getobj('win_history')->getobj('listbox_history');

                my $line = $_[ARG0];

                shift(@current) if ( @current > 12 );
                push( @current, $line );

                my $update_history = 0;
                if ( $line =~ m/unreachable/ ) {
                    $now++;
                    push( @history,
                        scalar( localtime($now) ) . " - Unreachable occurred" );
                    $update_history = 1;
                }
                else {
                    if ( $line =~ m/^\[(\d+)\.\d+\]\s.*?\sicmp_seq=(\d+)/ ) {
                        my $c_time = scalar( localtime($1) );
                        $now = $1;
                        my $cur = $2;
                        if ( ( $prev != 0 ) && ( ( $cur - $prev ) > 1 ) ) {
                            push( @history,
                                "$c_time - $cur <= $prev ($p_time), "
                                  . ( $cur - $prev ) );
                            $update_history = 1;
                        }
                        $prev   = $cur;
                        $p_time = $c_time;
                    }
                }

                $listbox_current->values(@current);
                $listbox_current->draw();

                if ($update_history) {
                    $listbox_history->values( reverse(@history) );
                    $listbox_history->draw();
                }
            },
        }
    );
}

sub main {
    init_ui();
    init_poe_tailor();
    init_poe_timer();

    $ui->mainloop;
    exit(0);
}

main;

#!/usr/bin/env perl
#===============================================================================
#
#         FILE: curses_log_multi.pl
#
#        USAGE: ./curses_log_multi.pl www.google.com
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
#      CREATED: 2013/04/01 14:25:10
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use POE qw(Wheel::FollowTail);
use Curses::UI::POE;
use FindBin qw($Bin);
use Digest::MD5 qw(md5_hex);
use File::Basename;
use Clipboard;

# resolve hostname and log filename
my $HASHED      = md5_hex( $ARGV[0] || die('ERROR: No given hostname') );
my $PF_PATH     = dirname($Bin);
my $PF_LOG_PATH = "$PF_PATH/log";
my $PF_LOG_FILE = "$PF_LOG_PATH/$HASHED.log";

$| = 1;

my $UI;            # Curses::UI
my $POE_TIMER;     # POE timer session
my $POE_TAILOR;    # POE tailor session
my $INTERVAL = 3;  # tailor polling INTERVAL
my $IS_CLIP  = 1;
my $IS_DRAW  = 1;

my @CURRENT = ();    # buffer current ping logs
my @HISTORY = ();    # buffer history logs

my $NOW      = time();    # FIXME: bad global var should be stored in $_[HEAP]
my $PREV_SEQ = 0;         # FIXME: bad global var should be stored in $_[HEAP]
my $P_TIME   = 0;         # FIXME: bad global var should be stored in $_[HEAP]

my $WHO_FOCUS =
  'win_current';          # change focus between 'win_current' and 'win_history'

sub get_multi_hosts {
    #my $cmd = `ps aux | grep ping | grep '\\-D' |awk '{print \$13}' | xargs`;
    my $cmd = `ps aux | grep ping | awk '{print \$13}' | xargs`;

    my %hosts = ();
    foreach my $item ( split( qr/\s+/, $cmd ) ) {
        my $f = "$PF_LOG_PATH/" . md5_hex($item) . ".log";
        if ( -f $f ) {
            $hosts{$f} = $item;
        }
    }

    return %hosts;
}

sub init_ui {
    $UI = Curses::UI::POE->new(
        -clear_on_exit => 1,
        -color_support => 1,
        -mouse_support => 0,
    );

    # lyshie_20130329: shortcut/key bindings
    $UI->set_binding(
        sub {
            $INTERVAL++;
            $INTERVAL = 300 if ( $INTERVAL > 300 );
            $poe_kernel->call( $POE_TAILOR, 'reset' );
        },
        '+'
    );
    $UI->set_binding(
        sub {
            $INTERVAL--;
            $INTERVAL = 1 if ( $INTERVAL < 1 );
            $poe_kernel->call( $POE_TAILOR, 'reset' );
        },
        '-'
    );
    $UI->set_binding( sub { exit(0); },                          'q' );
    $UI->set_binding( sub { $UI->getobj($WHO_FOCUS)->focus(); }, "\t" );
    $UI->set_binding( sub { show_about(); },                     "a" );
    $UI->set_binding( sub { show_multi_hosts(); },               "m" );

    # lyshie_20130329: default UI layout and draw
    my $win = $UI->add(
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
'[Q]uit  [TAB] Switch window  [M] Switch host  [Up/Down] Select entry  [+/-] Inc/Decrease time  [A]bout',
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
    my $win_current = $UI->add(
        'win_current', 'Window',
        -title   => 'Current',
        -onfocus => sub { $WHO_FOCUS = 'win_history' },
        qw(
          -border 1
          -y 2
          -height 15
          -width -1
          ),
    );

    # history window
    my $win_history = $UI->add(
        'win_history', 'Window',
        -title   => 'History',
        -onfocus => sub { $WHO_FOCUS = 'win_current' },
        qw(
          -border 1
          -y 17
          -height -1
          -width -1
          ),
    );

    # current list
    my $listbox_current;
    $listbox_current = $win_current->add(
        'listbox_current', 'Listbox', qw(
          -y 0
          -height -1
          -width -1
          ),
        -onchange,
        sub {
            copy_to_clipboard($listbox_current);
            my $select;
            ($select) = $listbox_current->get();
            if ( defined($select) && $select =~ m/^\[(\d+)\.\d+\]\s/ ) {
                my $time = scalar( localtime($1) );
                $win_current->title("Current ($time)");
            }
        }
    );
    $listbox_current->clear_binding('loose-focus');

    # history list
    my $listbox_history;
    $listbox_history = $win_history->add(
        'listbox_history', 'Listbox', qw(
          -y 0
          ),
        -onchange,
        sub {
            copy_to_clipboard($listbox_history);
        }
    );
    $listbox_history->clear_binding('loose-focus');

    $listbox_current->focus();
    $listbox_history->focus();

    $win->draw();
}

sub copy_to_clipboard {
    return if ( !defined($IS_CLIP) );

    my ($listbox) = @_;
    my $select;
    ($select) = $listbox->get();
    eval { Clipboard->copy($select) if ( defined($select) ); };

    if ($@)
    {  # FIXME: remote copy isn't supported => Error: Can't open display: (null)
        $IS_CLIP = 0;
        draw_ui();
    }
}

# unused
sub layout_ui {
    my $win_main    = $UI->getobj('win_main');
    my $win_current = $UI->getobj('win_current');
    my $win_history = $UI->getobj('win_history');

    $win_main->layout();
    $win_current->layout();
    $win_history->layout();
}

# unused
sub draw_ui {
    return if ( !$IS_DRAW );
    my $win_main    = $UI->getobj('win_main');
    my $win_current = $UI->getobj('win_current');
    my $win_history = $UI->getobj('win_history');

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
    $IS_DRAW = 0;
    my $ret = $UI->dialog("Author: SHIE, Li-Yi\nEmail: lyshie\@mx.nthu.edu.tw");
    $IS_DRAW = 1;
}

sub show_multi_hosts {
    $IS_DRAW = 0;
    if ( $UI->getobj('win_hosts') ) {    # already created
        $UI->getobj('win_hosts')->focus();
        return;
    }

    my %hosts     = get_multi_hosts();
    my $win_hosts = $UI->add(
        'win_hosts', 'Window',
        -title => 'Select a host to monitor',
        qw(
          -border 1
          -height -1
          -width -1
          -y 2
          ),
    );

    my $listbox_hosts;
    $listbox_hosts = $win_hosts->add(
        'listbox_hosts', 'Listbox', qw(
          -y 0
          -height -1
          -width -1
          ),
        -values => [ keys(%hosts) ],
        -labels => \%hosts,
        -onchange,
        sub {
            my ($select) = $listbox_hosts->get();
            $UI->delete('win_hosts');
            $IS_DRAW = 1;
            ( $NOW, $PREV_SEQ, $P_TIME ) = ( time(), 0, 0 );
            draw_ui();
            $PF_LOG_FILE = $select;
            $poe_kernel->call( $POE_TAILOR, 'restart' );
        }
    );

    $listbox_hosts->focus();
}

# timer session
sub init_poe_timer {
    $POE_TIMER = POE::Session->create(
        inline_states => {
            _start => sub {
                $_[KERNEL]->alarm( tick => time() + 1, 0 );
            },
            tick => sub {
                $_[KERNEL]->alarm( tock => time() + 1, 0 );
                my $heap =
                  $poe_kernel->ID_id_to_session( $POE_TAILOR->ID() )
                  ->get_heap();
                my $label_timer =
                  $UI->getobj('win_main')->getobj('label_timer');
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
                  $poe_kernel->ID_id_to_session( $POE_TAILOR->ID() )
                  ->get_heap();
                my $label_timer =
                  $UI->getobj('win_main')->getobj('label_timer');
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
    $POE_TAILOR = POE::Session->create(
        inline_states => {
            _start => sub {
                $_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
                    Filename     => "$PF_LOG_FILE",
                    InputEvent   => 'got_log_line',
                    PollInterval => $INTERVAL,
                );
            },
            restart => sub {
                delete( $_[HEAP]{tailor} );
                $_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
                    Filename     => "$PF_LOG_FILE",
                    InputEvent   => 'got_log_line',
                    PollInterval => $INTERVAL,
                );
            },
            reset => sub {
                my $pos = $_[HEAP]{tailor}->tell() || 0;
                delete( $_[HEAP]{tailor} );
                $_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
                    Filename     => "$PF_LOG_FILE",
                    InputEvent   => 'got_log_line',
                    PollInterval => $INTERVAL,
                    Seek         => $pos,
                );
            },
            got_log_line => sub {
                my $listbox_current =
                  $UI->getobj('win_current')->getobj('listbox_current');
                my $listbox_history =
                  $UI->getobj('win_history')->getobj('listbox_history');

                my $line = $_[ARG0];

                shift(@CURRENT) if ( @CURRENT > 12 );
                push( @CURRENT, $line );

                my $update_history = 0;
                if ( $line =~ m/unreachable/ ) {
                    $NOW++;
                    push( @HISTORY,
                        scalar( localtime($NOW) ) . " - Unreachable occurred" );
                    $update_history = 1;
                }
                else {
                    if ( $line =~ m/^\[(\d+)\.\d+\]\s.*?\sicmp_seq=(\d+)/ ) {
                        my $c_time = scalar( localtime($1) );
                        $NOW = $1;
                        my $cur = $2;
                        if (   ( $PREV_SEQ != 0 )
                            && ( ( $cur - $PREV_SEQ ) > 1 ) )
                        {
                            push( @HISTORY,
                                "$c_time - $cur <= $PREV_SEQ ($P_TIME), "
                                  . ( $cur - $PREV_SEQ ) );
                            $update_history = 1;
                        }
                        $PREV_SEQ = $cur;
                        $P_TIME   = $c_time;
                    }
                }

                $listbox_current->values(@CURRENT);
                $listbox_current->draw() if ($IS_DRAW);

                if ($update_history) {
                    $listbox_history->values( reverse(@HISTORY) );
                    $listbox_history->draw() if ($IS_DRAW);
                }
            },
        }
    );
}

sub main {
    init_ui();
    init_poe_tailor();
    init_poe_timer();

    $UI->mainloop;
    exit(0);
}

main;

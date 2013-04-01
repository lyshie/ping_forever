Ping Forever
============
Run a ping command as daemon.

Dependencies
------------
  * *daemonize*
  * Perl modules
    - POE (Perl Object Environment)
    - POE::Wheel::FollowTail
    - Curses::UI::POE
    - Curses::UI (UI framework)
    - Clipboard (Copy text)
    - Digest::MD5
    - File::Basename

Usage
-----
    # sudo yum install daemonize

    # mkdir -p /opt/local/
    # git clone https://github.com/lyshie/ping_forever.git
    # cd /opt/local/ping_forever

    # ./bin/pf.sh www.google.com
    Target: www.google.com
    Log file: /tmp/pf/log/0a137b375cc3881a70e186ce2172c8d1.log
    PID file: /tmp/pf/run/0a137b375cc3881a70e186ce2172c8d1.pid

    # tail -f ./log/0a137b375cc3881a70e186ce2172c8d1.log
    [1363589448.034274] 64 bytes from nrt19s01-in-f20.1e100.net (74.125.235.84): icmp_seq=87 ttl=54 time=35.7 ms
    [1363589449.033585] 64 bytes from nrt19s01-in-f20.1e100.net (74.125.235.84): icmp_seq=88 ttl=54 time=34.8 ms
    [1363589450.034419] 64 bytes from nrt19s01-in-f20.1e100.net (74.125.235.84): icmp_seq=89 ttl=54 time=36.3 ms

    # ./bin/unreachable.pl www.google.com
    Mon Mar 18 15:31:09 2013 (ping: sendmsg: Network is unreachable)
    Mon Mar 18 15:31:10 2013 (ping: sendmsg: Network is unreachable)
    Mon Mar 18 15:31:11 2013 (ping: sendmsg: Network is unreachable)
    Mon Mar 18 15:36:06 2013 (ping: sendmsg: Network is unreachable)
    Mon Mar 18 15:36:07 2013 (ping: sendmsg: Network is unreachable)

    # ./bin/match.sh www.google.com.tw "2013/03/18 15:20:10"

    # ./bin/missing.pl www.facebook.com
    (Thu Mar 21 01:05:13 2013) 22258 <=> 22260 (Thu Mar 21 01:05:15 2013),  2
    (Thu Mar 21 01:05:23 2013) 22268 <=> 22456 (Thu Mar 21 01:08:31 2013),  188
    (Thu Mar 21 01:09:21 2013) 22506 <=> 22508 (Thu Mar 21 01:09:23 2013),  2
    (Thu Mar 21 01:09:55 2013) 22540 <=> 22542 (Thu Mar 21 01:09:57 2013),  2
    (Thu Mar 21 01:09:59 2013) 22544 <=> 22696 (Thu Mar 21 01:12:31 2013),  152
    (Thu Mar 21 01:12:31 2013) 22696 <=> 22698 (Thu Mar 21 01:12:33 2013),  2

    # ./bin/curses_log.pl www.google.com

Author
------
    SHIE, Li-Yi <lyshie@mx.nthu.edu.tw>

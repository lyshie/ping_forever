Ping Forever
============
Run a ping command as daemon.

Dependencies
------------
  * *daemonize*

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

Author
------
    SHIE, Li-Yi <lyshie@mx.nthu.edu.tw>

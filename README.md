# Prototest

Most things require root permission to try, so to test on a PC, run:

    export SUDO_ASKPASS=/usr/bin/ssh-askpass

## Building

This module requires [libmnl](http://netfilter.org/projects/libmnl/) to build.
If you're running a Debian-based system, you can get it by running:

    sudo apt-get install libmnl-dev


#!/usr/bin/expect -f

spawn svn list https://svn.r-project.org
expect "(R)eject, accept (t)emporarily or accept (p)ermanently? "
send -- "p\r"

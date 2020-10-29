#!/usr/bin/expect -f

spawn svn list https://svn.r-project.org
expect {
    timeout                                                    { send_user "\nsvn time out\n"; exit 1 }
    "(R)eject, accept (t)emporarily or accept (p)ermanently? " { send -- "p\r" }
    eof
}

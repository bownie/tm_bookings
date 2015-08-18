#!/bin/sh

. $HOME/.bash_profile

cat $HOME/tm_bookings/mail_in/msg.0gEC | $HOME/tm_bookings/scripts/processMail.sh

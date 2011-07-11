#!/bin/bash
# irssi-annoyatron: a notification system for your irssi IRC messages,
#                   featuring both growl AND SMS notifications
#
# Based on http://justindow.com/2010/03/26/irssi-screen-and-growl-oh-my/

# TODO: Make this zsh-exy.

PHONE="8005551212"
SSH_TARGET="burr@burr.ru"
SEND_SMS=""


# Kill all current fnotify sessions.
fn_sessions='{if($0 ~ /fnotify/ && $1 ~ /[0-9]+/ && $4 !~ /awk/) print $1}'
ps | awk fn_sessions | while read id; do kill $id; done

# SSH to host, clear file and listen for notifications.
(
    ssh "${SSH_TARGET}" -o PermitLocalCommand=no \
        "> .irssi/fnotify; tail -f .irssi/fnotify" |
        while read heading message; do
            if [ ${heading:0:1} == '#' ]
                then
                    growl_msg="someone's talking about you"
                    sms_msg="${heading}: ${message}"
                else
                    growl_msg="has sent you a PM"
                    sms_msg="${heading} has sent you a PM: ${message}"
            fi
            growlnotify -t "${heading}" -m "${growl_msg}"

            # I don't want to miss a thing! Send an SMS (using pygooglevoice).
            if [ SEND_SMS ]
                then
                    gvoice send_sms $PHONE "${sms_msg}" > /dev/null
            fi
        done
)&

ssh "${SSH_TARGET}" -t screen -raAd

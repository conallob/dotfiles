# $Id: mailboxes-nestdesign.com,v 1.1 2004/04/18 19:42:43 conall Exp $

#
# nestdesign.com Email
#

mailboxes = !

# Automated emails reporting stuff to me

mailboxes = "=aide"
mailboxes = "=snort"
mailboxes = "=chkrootkit"
mailboxes = "=cron"

# Catch spam and Viruses

mailboxes = "=spam"
mailboxes = "=viruses"

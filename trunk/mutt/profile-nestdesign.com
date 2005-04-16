# $Id: profile-nestdesign.com,v 1.1 2004/04/18 19:42:43 conall Exp $

# conall@nestdesign.com Settings Profile

unmy_hdr *

my_hdr From: Conall O\'Brien <conall@nestdesign.com>

my_hdr X-Operating-System: `uname -a`
my_hdr X-GPG-FingerPrint: E3D4 A863 33E4 69FD 3FA9  C7DC 560D 0861 EE7D C74E
my_hdr X-GPG-Key-ID: EE7DC74E http://www.keyserver.net/

set signature = "~/.signature_nestdesign.com/"

my_hdr X-Website: http://www.nestdesign.com/

set attribution = "On %D, %n \n<%a> said:\n"

set realname = "Conall O'Brien"
set from = "conall@nestdesign.com"

set record = "~/mail/sent/nestdesign-`date +%Y-%m`"

set spoolfile = "imap://mail.nestdesign.com/"
set folder = "imap://mail.nestdesign.com/mail/"

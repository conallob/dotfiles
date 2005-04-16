# $Id: hooks-nestdesign.com,v 1.1 2004/04/18 19:42:43 conall Exp $

# To allow multiple accouts and multiple maliboxes

account-hook '.*nest' 'set imap_user="conall#nestdesign.com"'

# Set my defaults

folder-hook '.*conall' 'source ~/.mutt/profile-nestdesign.com'

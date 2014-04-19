# nginx formatted
au BufRead,BufNewFile /usr/local/etc/nginx/*,/usr/local/etc/nginx/*/* if &ft == '' | setfiletype nginx | endif 

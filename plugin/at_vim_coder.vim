scriptencoding utf-8

if exists('g:loaded_at_vim_coder')
	finish
endif
let g:loaded_at_vim_coder = 1

let s:save_cpo = &cpo
set cpo&vim

command! CHECK call at_vim_coder#echo_login_status()
function! at_vim_coder#echo_login_status()
	let l:logged_in = at_vim_coder#check_login()
	if !l:logged_in
		echo "not logged in"
	elseif l:logged_in
		echo "already logged in"
	endif
endfunction

command! Login call at_vim_coder#login()

let &cpo = s:save_cpo
unlet s:save_cpo

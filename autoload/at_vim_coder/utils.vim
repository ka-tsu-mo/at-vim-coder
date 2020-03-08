let s:save_cpo = &cpo
set cpo&vim

function! at_vim_coder#utils#echo_message(msg)
	echomsg '[at-vim-coder] ' . a:msg
endfunction

function! at_vim_coder#utils#echo_err_msg(msg, ...)
	echohl ErrorMsg
	echomsg '[at-vim-coder] ' . a:msg
	if exists('a:1')
		echomsg a:1
	endif
	echohl None
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

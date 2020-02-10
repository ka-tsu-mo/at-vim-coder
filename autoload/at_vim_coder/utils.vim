let s:save_cpo = &cpo
set cpo&vim

function! at_vim_coder#utils#echo_message(msg)
	echo '[at-vim-coder] ' . a:msg
endfunction

function! at_vim_coder#utils#check_workspace(contest_id)
	return isdirectory(at_vim_coder#utils#create_path(g:at_vim_coder_workspace, a:contest_id))
endfunction

function! at_vim_coder#utils#create_path(a, b)
	return a:a . '/' . a:b
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

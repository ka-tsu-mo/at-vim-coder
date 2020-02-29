scriptencoding utf-8

if exists('g:loaded_at_vim_coder')
	finish
endif
let g:loaded_at_vim_coder = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=+ Avc call <SID>At_Vim_Coder(<f-args>)
function! s:At_Vim_Coder(...)
	if a:0 == 1
		if a:1 ==# 'login'
			call at_vim_coder#login()
		elseif a:1 ==# 'logout'
			call at_vim_coder#delete_cookie()
		elseif a:1 ==# 'status'
			call at_vim_coder#echo_login_status()
		else
			call at_vim_coder#utils#echo_message('Invalid argument')
		endif
	elseif a:0 == 2
		if a:1 ==# 'new'
			call at_vim_coder#participate(a:1, a:2)
		elseif a:1 ==# 'review'
			call at_vim_coder#participate(a:1, a:2)
		endif
	else
		call at_vim_coder#utils#echo_message('Invalid argument')
	endif
endfunction

nnoremap <silent> <Plug>(at-vim-coder-run-test)      :<C-u>call at_vim_coder#contest#test()<CR>
nnoremap <silent> <Plug>(at-vim-coder-submit)        :<C-u>call at_vim_coder#contest#subimt()<CR>
nnoremap <silent> <Plug>(at-vim-coder-check-status)  :<C-u>call at_vim_coder#contest#check_status()<CR>

let &cpo = s:save_cpo
unlet s:save_cpo

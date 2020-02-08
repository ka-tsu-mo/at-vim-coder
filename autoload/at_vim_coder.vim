scriptencoding utf-8

if !exists('g:loaded_at_vim_coder')
	finish
endif
let g:loaded_at_vim_coder = 1

let s:save_cpo = &cpo
set cpo&vim

let s:at_vim_coder_base_dir = expand('<sfile>:p:h:h')

py3file <sfile>:h:h/py/at_vim_coder.py
py3 avc = AtVimCoder()

function! at_vim_coder#check_login()
	py3 avc.check_login()
	return l:logged_in
endfunction

function! at_vim_coder#echo_login_status()
	let l:logged_in = at_vim_coder#check_login()
	if !l:logged_in
		call at_vim_coder#utils#echo_message('Not logged in')
	elseif l:logged_in
		call at_vim_coder#utils#echo_message('Already logged in')
	endif
endfunction

function! s:get_user_info()
	call inputsave()
	let l:username = input('username: ', '')
	call inputrestore()
	call inputsave()
	let l:password = inputsecret('password: ', '')
	call inputrestore()
	redraw
	return [l:username, l:password]
endfunction

function! at_vim_coder#login()
	let l:logged_in = at_vim_coder#check_login()
	if !l:logged_in
		let l:user_info = s:get_user_info()
		py3 avc.login(vim.eval('l:user_info[0]'), vim.eval('l:user_info[1]'))
		if l:login_result
			call at_vim_coder#utils#echo_message('Succeeded to log-in')
		elseif !l:login_result
			call at_vim_coder#utils#echo_message('Failed to log-in')
		endif
	elseif l:logged_in
			call at_vim_coder#utils#echo_message('Already logged in')
	endif
endfunction

function! at_vim_coder#delete_cookie()
	let l:logged_in = at_vim_coder#check_login()
	if l:logged_in
		py3 avc.delete_cookies()
		call at_vim_coder#utils#echo_message('Deleted local Cookie')
	else
		call at_vim_coder#utils#echo_message('You already logged-out')
	endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

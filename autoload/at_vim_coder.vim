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

function! s:echo_message(msg)
	echo '[at-vim-coder] ' . a:msg
endfunction

function! at_vim_coder#check_login()
	py3 avc.check_login()
	return l:logged_in
endfunction

function! at_vim_coder#echo_login_status()
	let l:logged_in = at_vim_coder#check_login()
	if !l:logged_in
		call s:echo_message('Not logged in')
	elseif l:logged_in
		call s:echo_message('Already logged in')
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
			call s:echo_message('Succeeded to log-in')
		elseif !l:login_result
			call s:echo_message('Failed to log-in')
		endif
	elseif l:logged_in
			call s:echo_message('Already logged in')
	endif
endfunction

function! at_vim_coder#delete_cookie()
	let l:logged_in = at_vim_coder#check_login()
	if l:logged_in
		py3 avc.delete_cookies()
		call s:echo_message('Deleted local Cookie')
	else
		call s:echo_message('You already logged-out')
	endif
endfunction

function! at_vim_coder#get_task_list()
	call inputsave()
	let l:contest_id = input('contest ID: ', '')
	call inputrestore()
	redraw
	if l:contest_id == ''
		call s:echo_message('Cancelled')
		return
	endif
	py3 avc.download_task_list(vim.eval('l:contest_id'))
	if !l:contest_exist
		call s:echo_message('Contest was not found')
	else
		call at_vim_coder#buffer#display_list()
	endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

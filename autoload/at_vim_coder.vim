scriptencoding utf-8

if !exists('g:loaded_at_vim_coder')
	finish
endif
let g:loaded_at_vim_coder = 1

let s:save_cpo = &cpo
set cpo&vim

let g:at_vim_coder_workspace = get(g:, 'at_vim_coder_workspace', getcwd())
let s:at_vim_coder_repo_dir = expand('<sfile>:p:h:h')

py3file <sfile>:h:h/python3/at_vim_coder.py
py3 avc = AtVimCoder()

function! s:check_login()
	py3 avc.check_login()
	return l:logged_in
endfunction

function! at_vim_coder#echo_login_status()
	let l:logged_in = s:check_login()
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
	let l:logged_in = s:check_login()
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
	let l:logged_in = s:check_login()
	if l:logged_in
		py3 avc.delete_cookies()
		call at_vim_coder#utils#echo_message('Deleted local Cookie')
	else
		call at_vim_coder#utils#echo_message('You already logged-out')
	endif
endfunction

function! at_vim_coder#participate(contest_id)
	if at_vim_coder#utils#check_workspace(a:contest_id)
		call at_vim_coder#utils#echo_message('Directory(' . a:contest_id . ') already exists.')
		return
	endif
	let task_list = at_vim_coder#contest#get_task_list(a:contest_id)
	if empty(task_list)
		call at_vim_coder#utils#echo_message('Contest was not found')
		return
	endif
	let l:logged_in = s:check_login()
	if !l:logged_in
		call at_vim_coder#utils#echo_message('You can''t submit your code without login')
		let ans = confirm('Do you want to login?', "&yes\n&no")
		if ans == 1
			call at_vim_coder#login()
		endif
	endif
	call mkdir(at_vim_coder#utils#create_path(g:at_vim_coder_workspace, a:contest_id))
	call at_vim_coder#buffer#init_task_list(a:contest_id, task_list)
	call at_vim_coder#buffer#display_task_list()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

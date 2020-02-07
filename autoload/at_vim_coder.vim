scriptencoding utf-8

if !exists('g:loaded_at_vim_coder')
	finish
endif
let g:loaded_at_vim_coder = 1

let s:save_cpo = &cpo
set cpo&vim

let s:at_vim_coder_base_dir = expand('<sfile>:p:h:h')

py3file <sfile>:h:h/src/at_vim_coder.py
py3 avc = AtVimCoder()

function! at_vim_coder#check_login()
	py3 avc.check_login()
	return l:logged_in
endfunction

function! at_vim_coder#echo_login_status()
	let l:logged_in = at_vim_coder#check_login()
	if !l:logged_in
		echo 'not logged in'
	elseif l:logged_in
		echo 'already logged in'
	endif
endfunction

function! at_vim_coder#get_user_info() abort
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
		let l:user_info = at_vim_coder#get_user_info()
		py3 avc.login(vim.eval('l:user_info[0]'), vim.eval('l:user_info[1]'))
		if l:login_result
			echo 'succeeded to log-in'
		elseif !l:login_result
			echo 'failed to log-in'
		endif
	elseif l:logged_in
		echo 'already logged in'
	endif
endfunction

function! at_vim_coder#delete_cookie()
	l:logged_in = avc.check_login()
	if l:logged_in
		py3 avc.delete_cookies()
		echo '[at-vim-coder] Deleted local Cookie'
	else
		echo '[at-vim-coder] You already logged-out'
	endif
endfunction

function! at_vim_coder#get_tasks()
	call inputsave()
	let l:contest_id = input('contest ID: ', '')
	call inputrestore()
	redraw
	if l:contest_id == ''
		echo 'Cancelled'
		return
	endif
	py3 avc.get_tasks(vim.eval('l:contest_id'))
	if !l:contest_exist
		echo 'Contest was not found'
		return
	else
		let l:wnr = bufwinnr('task_list')
		if l:wnr > 0
			execute wnr . 'wincmd w'
			setlocal modifiable
			%d
		else
			vnew task_list
			nmap <buffer> <CR> <Plug>avc_select
			setlocal modifiable
			%d
		endif
		for task_id in keys(s:tasks)
			call append(line('$'), task_id . ": " . s:tasks[task_id][0])
		endfor
		0d
	endif
	setlocal nomodifiable
endfunction

function! at_vim_coder#select_task()
	echo getline('.')[0]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

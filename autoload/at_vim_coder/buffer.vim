let s:save_cpo = &cpo
set cpo&vim

function! s:get_task_id()
	let line = getline('.')
	if line[1] == ':'
		return line[0]
	endif
endfunction

function! s:init_task_list_buffer()
	if tabpagenr('$') == 1 && bufnr('$') == 1 && bufname('%') == ''
		file avc_task_list
	else
		tabnew avc_task_list
	endif
	nmap <buffer><silent> <CR> :<C-u>call at_vim_coder#contest#solve_task()<CR>
	let t:contest_id = py3eval('avc.contest_id')
endfunction

function! s:set_buffer_local_options()
	setlocal readonly
	setlocal nobuflisted
	setlocal nomodifiable
	setlocal nomodified
endfunction

function! s:unset_buffer_local_options()
	setlocal noreadonly
	setlocal buflisted
	setlocal modifiable
endfunction

function! s:focus_win(buf_name)
	let win_num = bufwinnr(a:buf_name)
	if win_num < 0
		execute 'new ' . a:buf_name
		return 0
	else
		execute win_num . 'wincmd j'
		return 1
	endif
endfunction

function! at_vim_coder#buffer#load_template(...)
	if a:0 == 0
		echo 'Hello'
	endif
endfunction

function! at_vim_coder#buffer#display_task() abort
	let task_id = s:get_task_id()
	let task = at_vim_coder#contest#get_task(task_id)
	let win_existed = s:focus_win('problem')
	if !win_existed
		wincmd J
	endif
	call s:unset_buffer_local_options()
	silent %d
	for tas in task
		call append(line('$'), tas)
	endfor
	call s:set_buffer_local_options()
endfunction

function! at_vim_coder#buffer#display_task_list() abort
	call s:init_task_list_buffer()
	let tasks = py3eval('avc.tasks')
	call s:unset_buffer_local_options()
	silent %d
	call append(0, t:contest_id)
	silent 2d
	for task_id in keys(tasks)
		call append(line('$'), task_id . ': ' . tasks[task_id][0])
	endfor
	call s:set_buffer_local_options()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

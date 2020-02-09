let s:save_cpo = &cpo
set cpo&vim

function! s:get_task_id()
	let line = getline('.')
	if line[1] == ':'
		call at_vim_coder#contest#get_task(line[0])
	endif
endfunction

function! s:init_task_list_buffer()
	if bufname('%') == ''
		file avc_task_list
	else
		vnew avc_task_list
	endif
	nmap <buffer><silent> <CR> :<C-u>call <SID>get_task_id()<CR>
endfunction

function! at_vim_coder#buffer#focus_task_list_win()
	let win_num = bufwinnr('avc_task_list')
	if win_num < 0
		vnew avc_task_list
	else
		execute win_num . 'wincmd w'
	endif
endfunction

function! at_vim_coder#buffer#display_list()
	if !bufexists('avc_task_list')
		call s:init_task_list_buffer()
	endif
	call at_vim_coder#buffer#focus_task_list_win()
	let tasks = py3eval('avc.tasks')
	setlocal noreadonly
	setlocal buflisted
	setlocal modifiable
	silent %d " Clear buffer
	call append(0, py3eval('avc.contest_id'))
	silent 2d
	for task_id in keys(tasks)
		call append(line('$'), task_id . ': ' . tasks[task_id][0])
	endfor
	setlocal readonly
	setlocal nobuflisted
	setlocal nomodifiable
	setlocal nomodified
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

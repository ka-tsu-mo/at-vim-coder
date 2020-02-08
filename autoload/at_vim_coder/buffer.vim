let s:save_cpo = &cpo
set cpo&vim

function! s:get_task_id()
	echo getline('.')[0]
endfunction

function! s:init_buffer()
	vnew avc_task_list
	nmap <buffer><silent> <CR> :<C-u>call <SID>get_task_id()<CR>
endfunction

function! s:focus_task_list_win()
	let win_num = bufwinnr('avc_task_list')
	if win_num < 0
		call s:init_buffer()
	else
		execute win_num . 'wincmd w'
	endif
endfunction

function! at_vim_coder#buffer#display_list()
	call s:focus_task_list_win()
	let tasks = py3eval('avc.tasks')
	setlocal modifiable
	%d " Clear buffer
	for task_id in keys(tasks)
		call append(line('$'), task_id . ': ' . tasks[task_id][0])
	endfor
	0d " delete first line
	setlocal nomodifiable
	setlocal nomodified
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

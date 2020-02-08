let s:save_cpo = &cpo
set cpo&vim

function! s:get_task_id()
	let line = getline('.')
	if line[1] == ':'
		py3 avc.download_task(vim.eval('line[0]'))
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

function! s:focus_task_list_win()
	if !bufexists('avc_task_list')
		call s:init_task_list_buffer()
	endif
	let win_num = bufwinnr('avc_task_list')
	if win_num < 0
		vnew avc_task_list
	else
		execute win_num . 'wincmd w'
	endif
endfunction

function! at_vim_coder#buffer#display_list()
	call s:focus_task_list_win()
	let tasks = py3eval('avc.tasks')
	setlocal noreadonly
	setlocal buflisted
	setlocal modifiable
	%d " Clear buffer
	call append(0, py3eval('avc.contest_id'))
	2d
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

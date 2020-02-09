let s:save_cpo = &cpo
set cpo&vim

function! s:get_task_id()
	let line = getline('.')
	if line[1] == ':'
		return line[0]
	endif
endfunction

function! s:init_task_list_buffer()
	if len(gettabinfo()) == 1 && len((getbufinfo())) == 1 && bufname('%') == ''
		file avc_task_list
	else
		tabnew avc_task_list
	endif
	nmap <buffer><silent> <CR> :<C-u>call at_vim_coder#buffer#display_task()<CR>
endfunction

function! s:set_buffer_local_config()
	setlocal readonly
	setlocal nobuflisted
	setlocal nomodifiable
	setlocal nomodified
endfunction

function! s:unset_buffer_local_config()
	setlocal noreadonly
	setlocal buflisted
	setlocal modifiable
endfunction

function! at_vim_coder#buffer#display_task() abort
	let task_id = s:get_task_id()
	let win_num = bufwinnr('problem')
	if win_num < 0
		new problem
		wincmd J
	else
		execute win_num . 'wincmd j'
	endif
	py3 avc.get_task(vim.eval('task_id'))
	let task = py3eval('avc.task')
	call s:unset_buffer_local_config()
	silent %d " Clear buffer
	for tas in task
		call append(line('$'), tas)
	endfor
	call s:set_buffer_local_config()
endfunction

function! at_vim_coder#buffer#display_task_list() abort
	call s:init_task_list_buffer()
	let tasks = py3eval('avc.tasks')
	call s:unset_buffer_local_config()
	silent %d " Clear buffer
	call append(0, py3eval('avc.contest_id'))
	silent 2d
	for task_id in keys(tasks)
		call append(line('$'), task_id . ': ' . tasks[task_id][0])
	endfor
	call s:set_buffer_local_config()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

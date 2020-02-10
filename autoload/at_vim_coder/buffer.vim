let s:save_cpo = &cpo
set cpo&vim

function! s:get_task_id()
	return getline('.')[0]
endfunction

function! at_vim_coder#buffer#init_task_list(contest_id, task_list)
	if tabpagenr('$') == 1 && bufnr('$') == 1 && bufname('%') == ''
		execute 'file ' . a:contest_id . '_task_list'
	else
		execute 'tabnew ' . a:contest_id . '_task_list'
	endif
	nmap <buffer><silent> <CR> :<C-u>call at_vim_coder#contest#solve_task()<CR>
	let t:contest_id = a:contest_id
	let t:task_list = a:task_list
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
	let t:task = at_vim_coder#contest#get_task(t:task_list[task_id][1])
	let win_existed = s:focus_win(t:contest_id . '_problem')
	if !win_existed
		wincmd J
	endif
	call s:unset_buffer_local_options()
	silent %d
	for tas in t:task
		call append(line('$'), tas)
	endfor
	call s:set_buffer_local_options()
endfunction

function! at_vim_coder#buffer#display_task_list() abort
	call s:unset_buffer_local_options()
	silent %d
	for task_id in keys(t:task_list)
		call append(line('$'), task_id . ': ' . t:task_list[task_id][0])
	endfor
	0d
	call s:set_buffer_local_options()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

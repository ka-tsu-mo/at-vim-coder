let s:save_cpo = &cpo
set cpo&vim

function! s:get_task_id()
	return getline('.')[0]
endfunction

function! at_vim_coder#buffer#init_task_list(contest_id)
	if tabpagenr('$') == 1 && bufnr('$') == 1 && bufname('%') == ''
		execute 'file ' . a:contest_id . '_task_list'
	else
		execute 'tabnew ' . a:contest_id . '_task_list'
	endif
	nmap <buffer><silent> <CR> :<C-u>call at_vim_coder#contest#solve_task()<CR>
	let t:contest_id = a:contest_id
	let t:task_id = ''
	execute 'tcd ' . g:at_vim_coder_workspace
	execute 'tcd ' . a:contest_id
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

function! at_vim_coder#buffer#focus_win(buf_name, cmd)
	let win_id = bufwinid(a:buf_name)
	if win_id < 0
		execute 'rightbelow ' . a:cmd . ' ' . a:buf_name
		return 0
	else
		call win_gotoid(win_id)
		return 1
	endif
endfunction

function! at_vim_coder#buffer#load_template()
	let new_file = t:task_id . '.' . g:at_vim_coder_language
	if g:at_vim_coder_template_file == ''
		execute 'file ' . new_file
		%d
		execute 'write ' . new_file
	else
		execute 'edit ' . g:at_vim_coder_template_file
		execute 'file ' . new_file
		execute 'write ' . new_file
	endif
endfunction

function! at_vim_coder#buffer#minimize_task_list()
	let task_list_buf_name = t:contest_id . '_task_list'
	let winnr = bufwinnr(task_list_buf_name)
	if winnr > 0
		execute winnr . 'resize ' . t:num_of_tasks
	endif
endfunction

function! at_vim_coder#buffer#display_task() abort
	let t:task_id = s:get_task_id()
	let task_info = at_vim_coder#contest#get_task_info(t:contest_id, t:task_id)
	let win_existed = at_vim_coder#buffer#focus_win(t:contest_id . '_problem', 'new')
	call s:unset_buffer_local_options()
	%d
	for line in task_info['problem_info']
		if line[0] == '['
			call append(line('$'), '')
		endif
		call append(line('$'), line)
	endfor
	call cursor(0, 0)
	0d
	call s:set_buffer_local_options()
endfunction

function! at_vim_coder#buffer#display_task_list() abort
	let task_list = at_vim_coder#contest#get_task_list(t:contest_id)
	let t:num_of_tasks = len(task_list)
	call s:unset_buffer_local_options()
	%d
	for task_id in keys(task_list)
		call append(line('$'), task_id . ': ' . task_list[task_id]['task_title'])
	endfor
	0d
	call s:set_buffer_local_options()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

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

function! s:focus_win(buf_name)
	let win_id = bufwinid(a:buf_name)
	if win_id < 0
		execute 'new ' . a:buf_name
		return 0
	else
		call win_gotoid(win_id)
		return 1
	endif
endfunction

function! at_vim_coder#buffer#load_template()
	echo g:at_vim_coder_template_file
	if g:at_vim_coder_template_file == ''
		execute 'rightbelow vnew ' . t:task_id . '.' . g:at_vim_coder_language
	else
		execute 'rightbelow vsplit ' . g:at_vim_coder_template_file
		execute 'file ' . t:task_id . '.' . g:at_vim_coder_language
		execute 'write ' . t:task_id . '.' . g:at_vim_coder_language
	endif
endfunction

function! at_vim_coder#buffer#display_task() abort
	let t:task_id = s:get_task_id()
	let task_info = at_vim_coder#contest#get_task_info(t:contest_id, t:task_id)
	let win_existed = s:focus_win(t:contest_id . '_problem')
	if !win_existed
		wincmd J
	endif
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

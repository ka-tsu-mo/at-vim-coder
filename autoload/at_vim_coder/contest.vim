let s:save_cpo = &cpo
set cpo&vim

let g:at_vim_coder_workspace = get(g:, 'at_vim_coder_workspace', getcwd())

function! at_vim_coder#contest#get_task_list(contest_id)
	py3 avc.get_task_list(vim.eval('a:contest_id'))
	return l:contest_exist
endfunction

function! at_vim_coder#contest#get_task(task_id)
	py3 avc.get_task(vim.eval('a:task_id'))
	return py3eval('avc.task')
endfunction

function! s:create_contest_workspace()
	let contest_id = py3eval('avc.contest_id')
	if !isdirectory(contest_id)
		call mkdir(contest_id)
	endif
endfunction

function! at_vim_coder#contest#solve_task()
	call s:create_contest_workspace()
	call at_vim_coder#buffer#display_task()
	call at_vim_coder#buffer#load_template()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

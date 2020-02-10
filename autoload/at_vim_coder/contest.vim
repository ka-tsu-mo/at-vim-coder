let s:save_cpo = &cpo
set cpo&vim

function! at_vim_coder#contest#get_task_list(contest_id)
	py3 avc.get_task_list(vim.eval('a:contest_id'))
	return task_list
endfunction

function! at_vim_coder#contest#get_task(task_id)
	py3 avc.get_task(vim.eval('a:task_id'))
	return task
endfunction

function! at_vim_coder#contest#load()

endfunction

function! at_vim_coder#contest#solve_task()
	call at_vim_coder#buffer#display_task()
	call at_vim_coder#buffer#load_template()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

let s:save_cpo = &cpo
set cpo&vim

function! at_vim_coder#contest#get_task_list(contest_id)
	py3 avc.get_task_list(vim.eval('a:contest_id'))
	return l:contest_exist
endfunction

function! at_vim_coder#contest#get_task(task_id)
	py3 avc.get_task(vim.eval('a:task_id'))
	"let task = py3eval('avc.task')
	"return task
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

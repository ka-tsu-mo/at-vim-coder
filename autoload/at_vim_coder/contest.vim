let s:save_cpo = &cpo
set cpo&vim

function! at_vim_coder#contest#create_tasks(contest_id)
	py3 avc.create_tasks(vim.eval('a:contest_id'))
	return created_tasks
endfunction

function! at_vim_coder#contest#load()

endfunction

function! at_vim_coder#contest#solve_task()
	call at_vim_coder#buffer#display_task()
	call at_vim_coder#buffer#load_template()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

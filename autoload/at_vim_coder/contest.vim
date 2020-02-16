let s:save_cpo = &cpo
set cpo&vim

function! at_vim_coder#contest#create_tasks(contest_id)
	py3 avc.create_tasks(vim.eval('a:contest_id'))
	return created_tasks
endfunction

function! at_vim_coder#contest#get_task_list(contest_id)
	py3 avc.get_task_list(vim.eval('a:contest_id'))
	return task_list
endfunction

function! at_vim_coder#contest#get_task_info(contest_id, task_id)
	py3 avc.get_task_info(vim.eval('a:contest_id'), vim.eval('a:task_id'))
	return task_info
endfunction

function! at_vim_coder#contest#check_workspace(contest_id)

py3 << EOF
contest_workspace = os.path.join(vim.eval('g:at_vim_coder_workspace'), vim.eval('a:contest_id'))
if os.path.exists(contest_workspace):
	vim.command('let l:workspace_exists = 1')
else:
	vim.command('let l:workspace_exists = 0')
EOF

	return workspace_exists
endfunction

function! at_vim_coder#contest#create_workspace(contest_id)

py3 << EOF
contest_workspace = os.path.join(vim.eval('g:at_vim_coder_workspace'), vim.eval('a:contest_id'))
os.makedirs(contest_workspace)
EOF

endfunction

function! at_vim_coder#contest#load()

endfunction

function! at_vim_coder#contest#solve_task()
	call at_vim_coder#buffer#display_task()
	call at_vim_coder#buffer#load_template()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

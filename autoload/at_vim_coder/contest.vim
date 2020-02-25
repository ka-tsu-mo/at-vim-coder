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
	let current_dir = getcwd()
	execute 'lcd ' . g:at_vim_coder_workspace
	let result = isdirectory(a:contest_id)
	execute 'lcd ' . current_dir
	return result
endfunction

function! at_vim_coder#contest#create_workspace(contest_id)
	let current_dir = getcwd()
	execute 'lcd ' . g:at_vim_coder_workspace
	call mkdir(a:contest_id)
	execute 'lcd ' . current_dir
endfunction

function! at_vim_coder#contest#solve_task()
	let current_task_id = t:task_id
	call at_vim_coder#buffer#display_task()
	let new_task_id = t:task_id
	call at_vim_coder#language#redefine()
	let current_task_source_code = current_task_id . at_vim_coder#language#get_extension()
	let new_task_source_code = new_task_id . at_vim_coder#language#get_extension()
	call at_vim_coder#buffer#focus_win(current_task_source_code, 'vnew')
	setlocal nobuflisted
	if filereadable(new_task_source_code)
		execute 'edit ' . new_task_source_code
	else
		call at_vim_coder#buffer#load_template()
	endif
	setlocal nobuflisted
	call at_vim_coder#buffer#minimize_task_list()
endfunction

function! at_vim_coder#contest#test()
	let source_code = at_vim_coder#buffer#get_source_code()
	if empty(source_code)
		call at_vim_coder#utils#echo_message('SourceCode is not loaded')
	else
		if at_vim_coder#language#needs_compile()
			if !isdirectory('bin')
				call mkdir('bin')
			endif
			let compile_output = system(at_vim_coder#language#get_compile_command())
			if v:shell_error != 0
				call at_vim_coder#utils#echo_message('CE')
				echo compile_output
				return
			endif
		endif
		let test_info = at_vim_coder#contest#get_task_info(t:contest_id, t:task_id)
		let test_info['command'] = at_vim_coder#language#get_exe()
		let test_py = g:at_vim_coder_repo_dir . '/python3/test_runner.py'
		if has('nvim')
			let job = jobstart('python3 ' . test_py, {'on_stdout': function('s:test_result_handler'), 'stdout_buffered': v:true})
			call at_vim_coder#utils#echo_message('Testing...')
			call chansend(job, json_encode(test_info))
			call chanclose(job, 'stdin')
		else
			let job = job_start('python3 '. test_py, {'out_cb': function('test_result_handler')})
			let channel = job_getchannel(job)
			call ch_sendraw(channel, json(test_info))
			call ch_close_in(channel)
		endif
	endif
endfunction

function! s:test_result_handler(channel, data, name)
	let test_result_list = []
	for test_result in a:data
		if test_result != ''
			let test_result = substitute(test_result, "'", "\"", "g")
			call add(test_result_list, json_decode(test_result))
		endif
	endfor
	execute 'let t:'. t:task_id . '_test_result = ' string(test_result_list)
	call at_vim_coder#utils#echo_message('Test Completed')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

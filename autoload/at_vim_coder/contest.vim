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

function! s:check_tab_duplicate(contest_id)
	let tabs_info = gettabinfo()
	for tab_info in tabs_info
		let variables = tab_info['variables']
		if index(keys(variables), 'contest_id') >= 0
			let contest_id = variables['contest_id']
			if contest_id == a:contest_id
				return tab_info['tabnr']
			endif
		endif
	endfor
	return -1
endfunction

function! at_vim_coder#contest#new(contest_to_participate) abort
	let contest_id = a:contest_to_participate[0]
	call at_vim_coder#contest#create_workspace(contest_id)
	let tabnr = s:check_tab_duplicate(contest_id)
	if tabnr > 0
		let win_id = win_getid(contest_id.'_task_list', tabnr)
		call win_gotoid(win_id)
	else
		call at_vim_coder#buffer#init_task_list(contest_id)
		call at_vim_coder#buffer#display_task_list()
	endif
	if len(a:contest_to_participate) == 2
		let task_id = a:contest_to_participate[1]
		let task_exists = at_vim_coder#buffer#select_task(task_id)
		if task_exists
			call at_vim_coder#contest#solve_task()
		endif
	endif
endfunction

function! at_vim_coder#contest#review(contest_to_participate) abort
	let contest_id = a:contest_to_participate[0]
	let tabnr = s:check_tab_duplicate(contest_id)
	if tabnr > 0
		let win_id = win_getid(contest_id.'_task_list', tabnr)
		call win_gotoid(win_id)
	else
		call at_vim_coder#buffer#init_task_list(contest_id)
		call at_vim_coder#buffer#display_task_list()
	endif
	if len(a:contest_to_participate) == 2
		let task_id = a:contest_to_participate[1]
		let task_exists = at_vim_coder#buffer#select_task(task_id)
		if task_exists
			call at_vim_coder#contest#solve_task()
		else
			call at_vim_coder#utils#echo_message('Task not found')
		endif
	endif
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
		let test_info['task_id'] = t:task_id
		let test_info['command'] = at_vim_coder#language#get_exe()
		let test_py = g:at_vim_coder_repo_dir . '/python3/test_runner.py'
		if has('nvim')
			let job = jobstart('python3 ' . test_py, {'on_stdout': function('s:test_result_handler_nvim'), 'stdout_buffered': v:true})
			call at_vim_coder#utils#echo_message('Testing... '. '[' . t:task_id . ']')
			call chansend(job, json_encode(test_info))
			call chanclose(job, 'stdin')
		else
			let job = job_start('python3 '. test_py, {'close_cb': function('s:test_result_handler_vim8')})
			let channel = job_getchannel(job)
			call at_vim_coder#utils#echo_message('Testing... '. '[' . t:task_id . ']')
			call ch_sendraw(channel, json_encode(test_info))
			call ch_close_in(channel)
		endif
	endif
endfunction

function! s:test_result_handler_nvim(channel, data, name)
	let test_result_list = []
	let task_id = a:data[0]
	for test_result in a:data[1:-2]
		let test_result = substitute(test_result, "'", "\"", "g")
		call add(test_result_list, json_decode(test_result))
	endfor
	execute 'let t:'. task_id . '_test_result = ' string(test_result_list)
	call at_vim_coder#utils#echo_message('Test Completed ' . '[' . task_id . ']')
endfunction

function! s:test_result_handler_vim8(channel)
	let test_result_list = []
	let i = 0
	while ch_status(a:channel, {'part': 'out'}) == 'buffered'
		if i == 0
			let task_id = ch_read(a:channel, {'timeout': 0})
		else
			let test_result = substitute(ch_read(a:channel, {'timeout': 0}), "'", "\"", "g")
			call add(test_result_list, json_decode(test_result))
		endif
		let i += 1
	endwhile
	execute 'let t:'. task_id . '_test_result = ' string(test_result_list)
	call at_vim_coder#utils#echo_message('Test Completed ' . '[' . task_id . ']')
endfunction

function! at_vim_coder#contest#check_status()
	if t:task_id != ''
		let contest_status = s:create_contest_status()
		if has('nvim')
			let buf = at_vim_coder#buffer#init_status_buf(contest_status)
			let opts = {
						\	'relative': 'editor',
						\	'width': 100,
						\	'height': len(contest_status),
						\	'row': &lines/2 - len(contest_status)/2,
						\	'col': &columns/2 - 50,
						\	'style': 'minimal'
						\}
			let win = nvim_open_win(buf, 1, opts)
			execute 'file ' . t:task_id . '_status'
		else
			let win = popup_create(contest_status, {})
		endif
		nmap <buffer><silent> q :<C-u>call at_vim_coder#buffer#close_popup()<CR>
	endif
endfunction

function! s:create_contest_status()
	let contest_status = []
	let test_result = 't:' . t:task_id . '_test_result'
	let submit_result = 't:' . t:task_id . '_submit_result'
	if exists(submit_result)
		call add(contest_status, 'Submit: ' . eval(submit_result))
	else
		call add(contest_status, "Submit: NONE")
	endif
	" insert blank line
	call add(contest_status, '')

	let task_info = at_vim_coder#contest#get_task_info(t:contest_id, t:task_id)
	let sample_input = task_info['sample_input']
	let sample_output = task_info['sample_output']
	let i = 0
	while i < len(sample_input)
		call add(contest_status, 'Sample Input '. string(i+1))
		for line in sample_input[i]
			call add(contest_status, line)
		endfor
		call add(contest_status, '')
		call add(contest_status, 'Sample Output ' . string(i+1))
		for line in sample_output[i]['value']
			call add(contest_status, line)
		endfor
		call add(contest_status, '')
		if !empty(sample_output[i]['explanation'])
			for line in sample_output[i]['explanation']
				call add(contest_status, line)
			endfor
			call add(contest_status, '')
		endif
		if exists(test_result)
			let test_result_status = eval(test_result)[i]['status']
			call add(contest_status, 'Test Result: ' . test_result_status)
			if test_result_status == 'WA'
				call add(contest_status, 'stdout')
				call add(contest_status, eval(test_result)[i]['stdout'])
				call add(contest_status, 'stderr')
				call add(contest_status, eval(test_result)[i]['stderr'])
			endif
		else
			call add(contest_status, "Test Result: NONE")
		endif
		call add(contest_status, '')
		let i += 1
	endwhile
	return contest_status
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

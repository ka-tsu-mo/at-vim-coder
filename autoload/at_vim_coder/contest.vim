let s:save_cpo = &cpo
set cpo&vim

let s:tasks = {}
"tasks = { 'contest_id': task_list }
"task_list = {
" 'task_id': task_info,
"}
"task_info = {
" 'task_title': ''
" 'task_url': ''
" 'problem_info': [], # problem statement, constraints, etc...
" 'sample_input': [],
" 'sample_output': [{
"     'value': '',
"     'explanation': ''
" }],
" 'submissions': [{
"     'time': '',
"     'language': ''
"     'status': '' # AC WA
" }]
"}

function! at_vim_coder#contest#create_task_list(contest_id)
  py3 avc.create_task_list(vim.eval('a:contest_id'))
  if exists('err')
    call at_vim_coder#utils#echo_err_msg('Failed to create task list', err)
    throw 'avc_python_err'
  endif
  if !empty(created_task_list)
    let s:tasks[a:contest_id] = created_task_list
  endif
  return created_task_list
endfunction

function! s:create_task_info(contest_id, task_id)
  let task_url = s:tasks[a:contest_id][a:task_id]['task_url']
  py3 avc.create_task_info(vim.eval('task_url'))
  if exists('err')
    call at_vim_coder#utils#echo_err_msg('Failed to create task info', err)
    throw 'avc_python_err'
  endif
  return task_info
endfunction

function! s:check_workspace(contest_id)
  let workspace = expand(g:at_vim_coder_workspace)
  if !isdirectory(workspace)
    call at_vim_coder#utils#echo_err_msg('Can''t find directory(' . g:at_vim_coder_workspace . ')')
    throw 'avc_workspace_err'
  endif
  let current_dir = getcwd()
  execute 'lcd ' . workspace
  let result = isdirectory(a:contest_id)
  execute 'lcd ' . current_dir
  return result
endfunction

function! s:create_workspace(contest_id)
  let current_dir = getcwd()
  execute 'lcd ' . expand(g:at_vim_coder_workspace)
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

function! s:confirm_login()
  let ans = confirm('Do you want to login?', "&yes\n&no")
  if ans == 1
    try
      call at_vim_coder#login()
    catch /^avc_python_err$/
      call at_vim_coder#utils#echo_err_msg('contest.vim/s:confirm_login()')
      let login_success = -1
      return login_success
    endtry
    let login_success = 1
  else
    let login_success = 0
  endif
  return login_success
endfunction

function! at_vim_coder#contest#participate(contest_to_participate) abort
  " prepare for contest
  let contest_id = a:contest_to_participate[0]
  try
    let ready_for_contest = s:check_workspace(contest_id)
  catch /^avc_workspace_err$/
    call at_vim_coder#utils#echo_err_msg('@at_vim_coder#contest#participate()')
    call at_vim_coder#utils#echo_err_msg('Please create workspace')
    return
  endtry
  if !ready_for_contest
    call s:create_workspace(contest_id)
  endif
  try
    let logged_in = at_vim_coder#check_login()
  catch /^avc_python_err$/
    call at_vim_coder#utils#echo_err_msg('@at_vim_coder#contest#participate()')
    return
  endtry
  if !logged_in
    call at_vim_coder#utils#echo_message('You can''t submit your code without login')
    let login_success = s:confirm_login()
    if login_success == -1
      return
    endif
  endif

  let tabnr = s:check_tab_duplicate(contest_id)
  if tabnr > 0
    execute tabnr . 'tabn'
  else
    call at_vim_coder#buffer#init_task_list(contest_id)
    call at_vim_coder#buffer#display_task_list(s:tasks[contest_id])
  endif

  " if specified task ID e.g abc:A
  if len(a:contest_to_participate) == 2
    let task_id = a:contest_to_participate[1]
    let task_exists = at_vim_coder#buffer#select_task(task_id)
    if task_exists
      call at_vim_coder#contest#solve_task(task_id)
    endif
  endif
endfunction

function! at_vim_coder#contest#solve_task(task_id) abort
  let current_task_id = t:task_id
  if a:task_id == 'buffer'
    let new_task_id = at_vim_coder#buffer#get_task_id()
  else
    let new_task_id = a:task_id
  endif

  try
    let task_info = get(
          \s:tasks[t:contest_id][new_task_id],
          \'problem_info',
          \s:create_task_info(t:contest_id, new_task_id)
          \)
  catch /^avc_python_err$/
    call at_vim_coder#utils#echo_err_msg('@at_vim_coder#contest#solve_task')
    return
  endtry
  call at_vim_coder#buffer#display_task(task_info)
  let current_task_source_code = current_task_id . at_vim_coder#language#get_extension()
  let new_task_source_code = new_task_id . at_vim_coder#language#get_extension()
  call at_vim_coder#buffer#focus_win(current_task_source_code, 'vnew')
  if current_task_id == ''
    " delete unnecessary buffer created by this function (first time)
    execute 'bwipeout ' . bufnr(current_task_source_code)
  endif

  if filereadable(new_task_source_code)
    execute 'edit ' . new_task_source_code
  else
    call s:load_template(new_task_source_code)
  endif

  setlocal nobuflisted
  call at_vim_coder#buffer#minimize_task_list()
  let t:task_id = new_task_id

endfunction

function! s:load_template(new_file)
  if g:at_vim_coder_template_file == ''
    execute 'file ' . a:new_file
    %d
    execute 'write ' . a:new_file
  else
    execute 'edit ' . expand(g:at_vim_coder_template_file)
    execute 'file ' . a:new_file
    execute 'write ' . a:new_file
  endif
endfunction

function! s:get_cookies()
  if g:at_vim_coder_save_cookies
    return [g:at_vim_coder_repo_dir, 'cookies']
  endif
    py3 avc.get_cookies()
    return cookies
endfunction

function! s:get_task_screen_name(task_id)
  let task_url = s:tasks[t:contest_id][a:task_id]['task_url']
  let task_url = split(task_url, '/')
  return task_url[-1]
endfunction

function! s:create_submissions_list(task_id)
  let task_screen_name = s:get_task_screen_name(a:task_id)
  py3 avc.create_submissions_list(vim.eval('t:contest_id'), vim.eval('task_screen_name'))
  if exists('err')
    call at_vim_coder#utils#echo_err_msg('Failed to create submissions list', err)
    throw 'avc_python_err'
  endif
  let s:tasks[t:contest_id][a:task_id]['submissions'] = submissions_list
  return submissions_list
endfunction

function! s:check_submission(task_id)
  try
    let submissions = get(
          \s:tasks[t:contest_id][a:task_id],
          \'submissions',
          \s:create_submissions_list(a:task_id))
  catch /^avc_python_err$/
    throw 'avc_python_err'
  endtry
  if submissions != []
    for submission in submissions
      if submission['status'] == 'AC' && submission['language'] == g:at_vim_coder_language
        return 1
      endif
    endfor
  endif
  return 0
endfunction

function! at_vim_coder#contest#submit(...)
  if a:0 == 0
    let task_id = t:task_id
  else
    let task_id = at_vim_coder#buffer#get_task_id()
  endif
  let source_code = task_id . g:at_vim_coder#language#get_extension()
  if !filereadable(source_code)
    call at_vim_coder#utils#echo_message('Source code was not found')
    return
  endif
  try
    let logged_in = at_vim_coder#check_login()
  catch /^avc_python_err$/
    call at_vim_coder#utils#echo_err_msg('@at_vim_coder#contest#submit()')
    call at_vim_coder#utils#echo_err_msg('Submission aborted')
    return
  endtry
  if !logged_in
    call at_vim_coder#utils#echo_message('You can''t submit your code without login')
    let login_success = s:confirm_login()
    if !login_success
      return
    endif
  endif
  try
    let isAC = s:check_submission(task_id)
  catch /^avc_python_err$/
    call at_vim_coder#utils#echo_err_msg('@at_vim_coder#contest#submit()')
    call at_vim_coder#utils#echo_err_msg('Submission aborted')
    return
  endtry
  if isAC
    call at_vim_coder#utils#echo_message('You''ve already got AC')
    let ans = confirm('submit?', "&yes\n&no")
    if ans != 1
      return
    endif
  endif
  let task_screen_name = s:get_task_screen_name(task_id)
  let cookies = s:get_cookies()
  let submit_info = {
        \ 'contest_id': t:contest_id,
        \ 'task_id': task_id,
        \ 'task_screen_name': task_screen_name,
        \ 'cookies': cookies,
        \ 'language': g:at_vim_coder_language,
        \ 'source_code': [getcwd(), source_code]
        \}
  let submit_py = at_vim_coder#utils#path_builder([g:at_vim_coder_repo_dir, 'python3', 'submitter.py'])
  if has('nvim')
    let job = jobstart(g:at_vim_coder_process_runner . ' ' . submit_py, {
          \'on_stdout': function('s:submit_result_handler_nvim'),
          \'stdout_buffered': v:true})
    call at_vim_coder#utils#echo_message('Submitting... '. '[' . task_id . ']')
    call chansend(job, json_encode(submit_info))
    call chanclose(job, 'stdin')
  else
    let job = job_start(g:at_vim_coder_process_runner . ' ' . submit_py, {'callback': function('s:submit_result_handler_vim8'), 'mode': 'raw'})
    let channel = job_getchannel(job)
    call at_vim_coder#utils#echo_message('Submitting... '. '[' . task_id . ']')
    call ch_sendraw(channel, json_encode(submit_info))
    call ch_close_in(channel)
  endif
endfunction

function! s:submit_result_handler_nvim(channel, data, name)
  let job_result = json_decode(a:data[0])  "json string (a:data[1] is '' which means 'EOF')
  let task_id = job_result['task_id']
  let submit_result = job_result['result']
  if submit_result != 'success'
    let message = 'Faild to submit [' . task_id . '] (caused by: ' . submit_result . ')'
    call at_vim_coder#utils#echo_err_msg(message)
  else
    call at_vim_coder#utils#echo_message('Succeeded to submit [' . task_id . ']')
    let task_screen_name = s:get_task_screen_name(task_id)
    py3 avc.get_latest_submission(vim.eval('t:contest_id'), vim.eval('task_screen_name'))
    if exists('err')
      call at_vim_coder#utils#echo_err_msg('Failed to get latest submission', err)
      return
    endif
    call add(s:tasks[t:contest_id][task_id]['submissions'], latest_submission)
  endif
endfunction

function! s:submit_result_handler_vim8(channel, msg)
  let job_result = json_decode(a:msg)
  let task_id = job_result["task_id"]
  let submit_result = job_result["result"]
  if submit_result != 'success'
    let message = 'Faild to submit [' . task_id . '] (caused by: ' . submit_result . ')'
    call at_vim_coder#utils#echo_err_msg(message)
  else
    call at_vim_coder#utils#echo_message('Succeeded to submit [' . task_id . ']')
    let task_screen_name = s:get_task_screen_name(task_id)
    py3 avc.get_latest_submission(vim.eval('t:contest_id'), vim.eval('task_screen_name'))
    if exists('err')
      call at_vim_coder#utils#echo_err_msg('Failed to get latest submission', err)
      return
    endif
    call add(s:tasks[t:contest_id][task_id]['submissions'], latest_submission)
  endif
  call ch_close(a:channel)
endfunction

function! at_vim_coder#contest#test(...)
  if a:0 == 0
    let task_id = t:task_id
  else
    let task_id = at_vim_coder#buffer#get_task_id()
  endif
  let file_name = task_id . g:at_vim_coder#language#get_extension()
  if !filereadable(file_name)
    call at_vim_coder#utils#echo_message('Source code was not found')
    return
  endif
  if at_vim_coder#language#needs_compile()
    if !isdirectory('bin')
      call mkdir('bin')
    endif
    let compile_output = system(at_vim_coder#language#get_compile_command(task_id))
    if v:shell_error != 0
      call at_vim_coder#utils#echo_warning('CE', compile_output)
      return
    endif
  endif
  let test_info = {}
  let test_info['task_id'] = task_id
  let test_info['command'] = at_vim_coder#language#get_exe(task_id)
  try
    let task_info = get(s:tasks[t:contest_id][task_id], 'sample_input', s:create_task_info(t:contest_id, task_id))
  catch /^avc_python_err$/
    call at_vim_coder#utils#echo_err_msg('@at_vim_coder#contest#test()')
    call at_vim_coder#utils#echo_err_msg('Running test aborted')
    return
  endtry
  let test_info['sample_input'] = task_info['sample_input']
  let test_info['sample_output'] = task_info['sample_output']
  let test_py = at_vim_coder#utils#path_builder([g:at_vim_coder_repo_dir, 'python3', 'test_runner.py'])
  if has('nvim')
    let job = jobstart(g:at_vim_coder_process_runner . ' ' . test_py, {'on_stdout': function('s:test_result_handler_nvim'), 'stdout_buffered': v:true})
    call at_vim_coder#utils#echo_message('Testing... '. '[' . task_id . ']')
    call chansend(job, json_encode(test_info))
    call chanclose(job, 'stdin')
  else
    let job = job_start(g:at_vim_coder_process_runner . ' ' . test_py, {'close_cb': function('s:test_result_handler_vim8')})
    let channel = job_getchannel(job)
    call at_vim_coder#utils#echo_message('Testing... '. '[' . task_id . ']')
    call ch_sendraw(channel, json_encode(test_info))
    call ch_close_in(channel)
  endif
endfunction

function! s:test_result_handler_nvim(channel, data, name)
  let test_result_list = []
  let task_id = a:data[0]
  for test_result in a:data[1:-2]
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
      let task_id = ch_read(a:channel)
    else
      let test_result = ch_read(a:channel)
      call add(test_result_list, json_decode(test_result))
    endif
    let i += 1
  endwhile
  execute 'let t:'. task_id . '_test_result = ' string(test_result_list)
  call at_vim_coder#utils#echo_message('Test Completed ' . '[' . task_id . ']')
endfunction

function! at_vim_coder#contest#check_status(...)
  if a:0 == 0
    let task_id = t:task_id
  else
    let task_id = at_vim_coder#buffer#get_task_id()
  endif
  if task_id != ''
    let contest_status = s:create_contest_status(task_id)
    if has('nvim')
      let buf = at_vim_coder#buffer#create_status_buf(contest_status)
      let opts = {
            \ 'relative': 'editor',
            \ 'width': 100,
            \ 'height': len(contest_status),
            \ 'row': &lines/2 - len(contest_status)/2,
            \ 'col': &columns/2 - 50,
            \ 'style': 'minimal'
            \}
      let win = nvim_open_win(buf, 1, opts)
      execute 'file ' . t:contest_id . '_status'
    else
      let win = popup_create(contest_status, {})
    endif
    nmap <buffer><silent> q :<C-u>call at_vim_coder#buffer#close_popup()<CR>
  endif
endfunction

function! s:create_contest_status(task_id)
  let contest_status = []
  let test_result_var = 't:' . a:task_id . '_test_result'

  " submission status
  try
    let submissions = get(s:tasks[t:contest_id][a:task_id], 'submissions', s:create_submissions_list(a:task_id))
  catch /^avc_python_err$/
    let submissions = [{'status': 'ERROR[at-vim-coder]'}]
  endtry
  call filter(submissions, 'v:val["language"] == g:at_vim_coder_language')
  if submissions == []
    call add(contest_status, 'Submit: NONE')
  else
    let latest_submission_status = submissions[-1]['status']
    if latest_submission_status == 'WJ'
      let task_screen_name = s:get_task_screen_name(a:task_id)
      py3 avc.get_latest_submission(vim.eval('t:contest_id'), vim.eval('task_screen_name'))
      if exists('err')
        call at_vim_coder#utils#echo_err_msg('Failed to get latest submission', err)
        let latest_submission['status'] = 'ERROR[at-vim-coder]'
      endif
      let latest_submission_status = latest_submission['status']
      if latest_submission_status != 'WJ'
        s:tasks[t:contest_id][a:task_id]['submissions'][-1]['status'] = latest_submission_status
      endif
    endif
    call add(contest_status, 'Submit: ' . latest_submission_status . '[latest]')
  endif
  " insert blank line
  call add(contest_status, '')

  " test status
  try
    let task_info = get(s:tasks[t:contest_id][a:task_id], 'sample_input', s:create_task_info(t:contest_id, a:task_id))
  catch /^avc_python_err$/
    call add(contest_status, 'Failed to get sample IO')
    return contest_status
  endtry
  let sample_input = task_info['sample_input']
  let sample_output = task_info['sample_output']
  let i = 0
  while i < len(sample_input)
    let box = s:create_sample_io_box(sample_input[i], sample_output[i]['value'], i+1)
    call extend(contest_status, box)
    call add(contest_status, '')
    if !empty(sample_output[i]['explanation'])
      for line in sample_output[i]['explanation']
        call add(contest_status, line)
      endfor
      call add(contest_status, '')
    endif
    if exists(test_result_var)
      let test_result = eval(test_result_var)
      let test_result_status = test_result[i]['status']
      call add(contest_status, 'Test Result ' . string(i+1) . ': ' . test_result_status)
      if test_result_status == 'WA'
        call add(contest_status, '[stdout]')
        call extend(contest_status, test_result[i]['stdout'])
        call add(contest_status, '')
        call add(contest_status, '[stderr]')
        call extend(contest_status, test_result[i]['stderr'])
      endif
    else
      call add(contest_status, 'Test Result ' . string(i+1) . ': NONE')
    endif
    call add(contest_status, '')
    let i += 1
  endwhile
  return contest_status
endfunction

function! s:create_sample_io_box(sample_input, sample_output, num)
  let input = a:sample_input
  let output = a:sample_output
  let height = (len(input) > len(output)) ? len(input) : len(output)
  let input_max_width = max(map(copy(input), 'strchars(v:val)'))
  if input_max_width < strchars('Sample Input 1')
    let input_max_width = strchars('Sample Input 1')
  endif
  " +2 -> space and |
  let input_max_width += 2

  let box = []

  " header
  let line = 'Sample Input ' . string(a:num)
  let num_of_space = input_max_width - strchars(line) - 1
  for i in range(num_of_space)
    let line .= ' '
  endfor
  let line .= '| '
  let line .= 'Sample Output ' . string(a:num)
  call add(box, line)
  let sep = ''
  for i in range(strchars(line))
    let sep .= '-'
  endfor
  call add(box, sep)

  for i in range(height)
    let line = get(input, i, '')
    let num_of_space = input_max_width - strchars(line) - 1
    for j in range(num_of_space)
      let line .= ' '
    endfor
    let line .= '| '
    let line .= get(output, i, '')
    call add(box, line)
  endfor
  return box
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

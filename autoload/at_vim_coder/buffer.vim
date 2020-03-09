let s:save_cpo = &cpo
set cpo&vim

function! at_vim_coder#buffer#get_task_id()
  let task = getline('.')
  return task[:stridx(task, ':')-1]
endfunction

function! at_vim_coder#buffer#init_task_list(contest_id)
  execute 'tcd ' . g:at_vim_coder_workspace
  if tabpagenr('$') == 1 && bufnr('$') == 1 && bufname('%') == ''
    execute 'file ' . a:contest_id . '_task_list'
  else
    execute 'tabnew ' . a:contest_id . '_task_list'
  endif
  nmap <buffer><silent> <CR> :<C-u>call at_vim_coder#contest#solve_task('buffer')<CR>
  nmap <buffer><silent> t :<C-u>call at_vim_coder#contest#test('buffer')<CR>
  nmap <buffer><silent> c :<C-u>call at_vim_coder#contest#check_status('buffer')<CR>
  nmap <buffer><silent> s :<C-u>call at_vim_coder#contest#submit('buffer')<CR>
  let t:contest_id = a:contest_id
  let t:task_id = ''
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

function! at_vim_coder#buffer#select_task(task_id)
  let win_id = bufwinid(t:contest_id.'_task_list')
  if win_id > 0
    call win_gotoid(win_id)
    for i in range(line('$'))
      call cursor(i, 0)
      let task_id = at_vim_coder#buffer#get_task_id()
      if task_id == a:task_id
        return 1
      endif
    endfor
  endif
  return 0
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

function! at_vim_coder#buffer#minimize_task_list()
  let task_list_buf_name = t:contest_id . '_task_list'
  let winnr = bufwinnr(task_list_buf_name)
  if winnr > 0
    execute winnr . 'resize ' . t:num_of_tasks
  endif
endfunction

function! at_vim_coder#buffer#display_task(task_info) abort
  call at_vim_coder#buffer#focus_win(t:contest_id . '_problem', 'new')
  call s:unset_buffer_local_options()
  %d
  let index = 1
  for line in a:task_info['problem_info']
    if line[0] == '['
      call append(line('$'), '')
      let index += 1
    endif
    call setline(index, line)
    let index += 1
  endfor
  call cursor(0, 0)
  0d
  call s:set_buffer_local_options()
endfunction

function! at_vim_coder#buffer#display_task_list(task_list) abort
  let t:num_of_tasks = len(a:task_list)
  call s:unset_buffer_local_options()
  let index = 1
  for task_id in keys(a:task_list)
    call setline(index, task_id . ': ' . a:task_list[task_id]['task_title'])
    let index += 1
  endfor
  call s:set_buffer_local_options()
endfunction

function! at_vim_coder#buffer#create_status_buf(contest_status)
  if has('nvim')
    let buf_name = t:contest_id . '_status'
    if bufexists(buf_name)
      let buf = bufnr(buf_name)
    else
      let buf = nvim_create_buf(v:false, v:true)
    endif
    call nvim_buf_set_option(buf, 'modifiable', v:true)
    call nvim_buf_set_lines(buf, 0, -1, v:true, a:contest_status)
    call nvim_buf_set_option(buf, 'modifiable', v:false)
    return buf
  endif
endfunction

function! at_vim_coder#buffer#close_popup()
  if has('nvim')
    let buf_name = t:contest_id . '_status'
    let win_id= bufwinid(buf_name)
    if win_id > 0
      call nvim_win_close(win_id, v:true)
    endif
  else
    call popup_clear()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

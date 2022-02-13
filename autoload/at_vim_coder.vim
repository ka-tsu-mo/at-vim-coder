scriptencoding utf-8

if !exists('g:loaded_at_vim_coder')
  finish
endif
let g:loaded_at_vim_coder = 1

let s:save_cpo = &cpo
set cpo&vim

let g:at_vim_coder_workspace = get(g:, 'at_vim_coder_workspace', getcwd())
let g:at_vim_coder_template_file = get(g:, 'at_vim_coder_template_file', '')
let g:at_vim_coder_language = get(g:, 'at_vim_coder_language', 'C++ (GCC 9.2.1)')
let g:at_vim_coder_save_cookies = get(g:, 'at_vim_coder_save_cookies', 1)
let g:at_vim_coder_locale = get(g:, 'at_vim_coder_locale', expand($LANG))
if has('win32') || has('win64')
  let g:at_vim_coder_process_runner = get(g:, 'at_vim_coder_process_runner',
        \get(g:, 'python3_host_prog', trim(system('where python'))))
else
  let g:at_vim_coder_process_runner = get(g:, 'at_vim_coder_process_runner',
        \get(g:, 'python3_host_prog', trim(system('which python'))))
endif
let g:at_vim_coder_repo_dir = expand('<sfile>:p:h:h')

call at_vim_coder#language#init()

py3file <sfile>:h:h/python3/at_vim_coder.py
py3 avc = AtVimCoder()

function! at_vim_coder#check_login()
  py3 avc.check_login()
  if exists('err')
    call at_vim_coder#utils#echo_err_msg('Failed to get login status', err)
    throw 'avc_python_err'
  endif
  return l:logged_in
endfunction

function! at_vim_coder#echo_login_status()
  try
    let l:logged_in = at_vim_coder#check_login()
  catch /^avc_python_err$/
    call at_vim_coder#utils#echo_err_msg('@at_vim_coder#echo_login_status()')
    return
  endtry
  if !l:logged_in
    call at_vim_coder#utils#echo_message('Not logged in')
  elseif l:logged_in
    call at_vim_coder#utils#echo_message('Already logged in')
  endif
endfunction

function! s:get_user_info()
  call inputsave()
  let l:username = input('username: ', '')
  call inputrestore()
  call inputsave()
  let l:password = inputsecret('password: ', '')
  call inputrestore()
  redraw
  return [l:username, l:password]
endfunction

function! at_vim_coder#login()
  try
    let l:logged_in = at_vim_coder#check_login()
  catch /^avc_python_err$/
    call at_vim_coder#utils#echo_err_msg('@at_vim_coder#login()')
    return
  endtry
  if !l:logged_in
    let l:user_info = s:get_user_info()
    py3 avc.login(vim.eval('l:user_info[0]'), vim.eval('l:user_info[1]'), vim.eval('g:at_vim_coder_save_cookies'))
    if exists('err')
      call at_vim_coder#utils#echo_err_msg('Failed to log-in', err)
      throw 'avc_python_err'
    endif
    if l:login_success
      call at_vim_coder#utils#echo_message('Succeeded to log-in')
    else
      call at_vim_coder#utils#echo_message('Failed to log-in')
    endif
  else
      call at_vim_coder#utils#echo_message('Already logged in')
  endif
endfunction

function! at_vim_coder#logout()
  try
    let l:logged_in = at_vim_coder#check_login()
  catch /^avc_python_err$/
    call at_vim_coder#utils#echo_err_msg('@at_vim_coder#logout()')
    return
  endtry
  if l:logged_in
    py3 avc.logout()
    if exists('err')
      call at_vim_coder#utils#echo_err_msg('Failed to logout', err)
      return
    endif
    if logout_success
      call at_vim_coder#utils#echo_message('logged out')
      if g:at_vim_coder_save_cookies
        py3 avc.delete_cookies()
      endif
    endif
  else
    call at_vim_coder#utils#echo_message('You already logged-out')
  endif
endfunction

function! at_vim_coder#participate(contest_specifier) abort
  let contest_specifier = split(a:contest_specifier, ':')
  if len(contest_specifier) >= 3
    call at_vim_coder#utils#echo_err_msg('Invalid contest specifier')
    return
  endif
  let contest_status = at_vim_coder#contest#check_availability(contest_specifier[0])
  if contest_status == 'not found'
    call at_vim_coder#utils#echo_err_msg(contest_specifier[0] . ' was not found')
  elseif contest_status == 'available'
    call at_vim_coder#contest#participate(contest_specifier)
  else
    let msg = contest_specifier[0] . ' will be held on ' . contest_status . '. '
    let msg .= "If you wan't to register for it, please see it on browser."
    call at_vim_coder#utils#echo_message(msg)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

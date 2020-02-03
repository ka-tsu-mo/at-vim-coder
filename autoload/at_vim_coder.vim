scriptencoding utf-8

if !exists('g:loaded_at_vim_coder')
  finish
endif
let g:loaded_at_vim_coder = 1

let s:save_cpo = &cpo
set cpo&vim

py3file <sfile>:h:h/src/at_vim_coder.py

function! at_vim_coder#check_login()
  py3 avc_check_login()
  return l:logged_in
endfunction

function! at_vim_coder#get_user_info()
  echon "Please log-in to AtCoder"
  call inputsave()
  let l:username = input("username: ", "")
  call inputrestore()
  call inputsave()
  let l:password = inputsecret("password: ", "")
  call inputrestore()
  redraw
  return [l:username, l:password]
endfunction

function! at_vim_coder#login()
  let l:logged_in = at_vim_coder#check_login()
  if !l:logged_in
    let l:user_info = at_vim_coder#get_user_info()
    py3 avc_login(vim.eval("l:user_info[0]"), vim.eval("l:user_info[1]"))
    if l:login_result
      echo "succeeded to log-in"
    elseif !l:login_result
      echo "failed to log-in"
    endif
  elseif l:logged_in
    echo "already logged in"
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

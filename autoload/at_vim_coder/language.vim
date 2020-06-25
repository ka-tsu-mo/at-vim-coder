let s:save_cpo = &cpo
set cpo&vim

" based on
"   https://atcoder.jp/contests/language-test-202001/

function! at_vim_coder#language#init()
  let s:language = {
        \  'C++ (GCC 9.2.1)': {
        \    'extension': '.cpp',
        \    'compile_command': 'g++ -std=gnu++17 -Wall -Wextra -O2 -DONLINE_JUDGE -I/opt/boost/gcc/include -L/opt/boost/gcc/lib -o ./bin/{task_id} {task_id}.cpp',
        \    'exe': ['./bin/{task_id}']
        \  },
        \  'Go (1.14.1)': {
        \    'extension': '.go',
        \    'compile_command': 'go build -buildmode=exe -o ./bin/{task_id} {task_id}.go',
        \    'exe': ['./bin/{task_id}']
        \  },
        \  'Python (3.8.2)': {
        \    'extension': '.py',
        \    'compile_command': '',
        \    'exe': [g:at_vim_coder_process_runner, './{task_id}.py', 'ONLINE_JUDGE', '2>/dev/null']
        \  }
        \}
endfunction

function! at_vim_coder#language#get_compile_command(task_id)
  let compile_command = s:language[g:at_vim_coder_language]['compile_command']
  return substitute(compile_command, '{task_id}', a:task_id, 'g')
endfunction

function! at_vim_coder#language#get_extension()
  return s:language[g:at_vim_coder_language]['extension']
endfunction

function! at_vim_coder#language#get_exe(task_id)
  let exe = []
  for option in s:language[g:at_vim_coder_language]['exe']
    call add(exe, substitute(option, '{task_id}', a:task_id, 'g'))
  endfor
  return exe
endfunction

function! at_vim_coder#language#needs_compile()
  return s:language[g:at_vim_coder_language]['compile_command'] != ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

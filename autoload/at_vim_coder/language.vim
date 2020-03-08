let s:save_cpo = &cpo
set cpo&vim

let s:language = {
			\	'C++14 (GCC 5.4.1)': {
			\		'extension': '.cpp',
			\		'complie_command': 'g++ -std=gnu++1y -O2 -I/opt/boost/gcc/include -L/opt/boost/gcc/lib -o ./bin/{task_id} {task_id}.cpp',
			\		'exe': './bin/{task_id}'
			\	},
			\	'Bash (GNU bash v4.3.11)': {
			\		'extension': '.sh',
			\		'complie_command': "cat Main.sh | tr -d '\r' >./bin/{task_id}",
			\		'exe': 'bash ./bin/{task_id}'
			\	},
			\	'C (GCC 5.4.1)': {
			\		'extension': '.c',
			\		'complie_command': 'gcc -std=gnu11 -O2 -o ./bin/{task_id} {task_id}.c -lm',
			\		'exe': './bin/{task_id}'
			\	},
			\	'C (Clang 3.8.0)': {
			\		'extension': '.c',
			\		'complie_command': 'clang -O2 {task_id}.c -o ./bin/{task_id} -lm',
			\		'exe': './bin/{task_id}'
			\	}
			\}

function! at_vim_coder#language#get_compile_command(task_id)
	let complie_command = s:language[g:at_vim_coder_language]['complie_command']
	return substitute(complie_command, '{task_id}', a:task_id, 'g')
endfunction

function! at_vim_coder#language#get_extension()
	return s:language[g:at_vim_coder_language]['extension']
endfunction

function! at_vim_coder#language#get_exe(task_id)
	let exe = s:language[g:at_vim_coder_language]['exe']
	return substitute(exe, '{task_id}', a:task_id, 'g')
endfunction

function! at_vim_coder#language#needs_compile()
	return s:language[g:at_vim_coder_language]['complie_command'] !=# ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

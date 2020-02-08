let s:save_cpo = &cpo
set cpo&vim

function! at_vim_coder#contest#get_task_list()
	call inputsave()
	let l:contest_id = input('contest ID: ', '')
	call inputrestore()
	redraw
	if l:contest_id == ''
		call at_vim_coder#utils#echo_message('Cancelled')
		return
	endif
	py3 avc.download_task_list(vim.eval('l:contest_id'))
	if !l:contest_exist
		call at_vim_coder#utils#echo_message('Contest was not found')
	else
		call at_vim_coder#buffer#display_list()
	endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

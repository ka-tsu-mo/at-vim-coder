# at-vim-coder
Be contestant of AtCoder on Vim8/Neovim

## Requirements
- Neovim with python3 and floating window
  - tested with NVIM v0.4.3 (macOS 10.15.3)
- vim8 with python3 and popup
  - tested with
    - version 8.2.250 (macOS 10.15.3)
    - version 8.2.259 (Windows 10)

## Demo
![atvimcoder_demo](https://user-images.githubusercontent.com/46083154/76198792-0d585100-6232-11ea-9e8b-e89e5531983a.gif)

## Usage
```vim
" Login to AtCoder. It's necessary for submitting code.
AtVimCoder login

" Logout from AtCoder.
AtVimCoder logout

" Check if logged in or not.
AtVimCoder status

" Participate contest specified by contest ID( and solve task if task ID specified)
" e.g. AtVimCoder abc111 or AtVimCoder abc111:A
AtVimCoder {contest ID}
AtVimCoder {contest ID}:{task ID}
```

## Option variables
### g:at_vim_coder_workspace
workspace for at-vim-coder (create directory named {contest ID} under this directory)
```vim
let g:at_vim_coder_workspace = 'path/to/workspace'
```

### g:at_vim_coder_template_file
if specified, copy the file to solve task
```vim
let g:at_vim_coder_template_file = 'path/to/template_file'
```
### g:at_vim_coder_language
language to participate (currently only 3 languages are available)

Please set to 'C++ (9.2.1)', 'Go (1.14.1)' or 'Python (3.8.2)'.
These languages are based on [Language Test 202001](https://atcoder.jp/contests/language-test-202001/)
```vim
let g:at_vim_coder_language = 'C++ (9.2.1)' " default
```

### g:at_vim_coder_save_cookies
if 1, save session cookies to local (if logout, delete this cookies)
```vim
let g:at_vim_coder_save_cookies = 1
```

### g:at_vim_coder_process_runner
This plugin use subprocess module of python3,
so you must let plugin know path to python3.

if not set, get g:python3_host_prog, and g:python3_host_prog is not set, get from command `where python | which python`.
```vim
let g:at_vim_coder_process_runner = 'path/to/python3'
```

## Command
```vim
<Plug>(at-vim-coder-check-status)  :<C-u>call at_vim_coder#contest#check_status()<CR>
<Plug>(at-vim-coder-run-test)      :<C-u>call at_vim_coder#contest#test()<CR>
<Plug>(at-vim-coder-submit)        :<C-u>call at_vim_coder#contest#submit()<CR>
```

on {contest ID}_task_list buffer, above 3 actions are mapped by following key
- `c`
  - check contest status.
  - Popup window will appear and you can get information about submission and local test result.
- `t`
  - run local test.
- `s`
  - submit code. login required.

Also, you can map 3 actions by configuring like:
```vim
nmap <silent> ;c <Plug>(at-vim-coder-check-status)
nmap <silent> ;t <Plug>(at-vim-coder-run-test)
nmap <silent> ;s <Plug>(at-vim-coder-submit)
```

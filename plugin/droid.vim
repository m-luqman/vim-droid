" plugin/droid.vim - Provide utilities for app development
" Author: Tim Horton

if exists('g:loaded_droid') || &cp || v:version < 700
  finish
endif
let g:loaded_droid = '0.1'
if !exists("g:droid_templates")
  let g:droid_templates = 1
endif

function! s:Detect(filename)
  if a:filename == '/' | return 0 | endif
  if isdirectory(a:filename)
    let files = map(split(expand(a:filename . '/*')), "fnamemodify(v:val, ':t')")
    for file in files 
      if file == "AndroidManifest.xml" 
        return droid#init(a:filename)
      endif
    endfor
  endif
  return s:Detect(fnamemodify(a:filename, ":h"))
endfunction

augroup droidAppDetect
  autocmd!
  autocmd BufNewFile,BufRead * call s:Detect(expand("<afile>:p"))
  autocmd VimEnter * if expand("<amatch>") == "" && !exists("b:approot") | call s:Detect(getcwd()) | endif | if exists("b:approot") | silent doau User BufEnterRails | endif
augroup END

" vim:set ft=vim sw=2 ts=2: 

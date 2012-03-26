" autoload/droid.vim
" Author:       Tim Horton

if exists('g:autoloaded_droid') || &cp
  finish
endif
let g:autoloaded_droid = '0.1'

" {{{ Utilities

function! s:error(str)
  echohl ErrorMsg
  echomsg a:str
  echohl None
  let v:errmsg = a:str
endfunction

" }}}
" {{{ Libs functions

function droid#list_avds()
  let avds = s:listavds()
  call setqflist(avds)
  copen
endfunction

function droid#run_avd(avd)
  call system('emulator -avd ' . a:avd . ' &')
endfunction

function! droid#init(approot)
  let b:approot = a:approot
  setlocal makeprg=ant\ -quiet\ -emacs
  call s:bufinit()
endfunction

function! droid#ant(bang, cmd)
  exe "chdir " .b:approot
  exe "make" (a:bang ? '!' : '') . ' ' . a:cmd
endfunction

" }}}

function! s:bufinit()
  call s:addrelated("layouts")
  call s:addrelated("menu")
  call s:addrelated("xml")
  call s:addrelated("values")

  command! -buffer -bang AntClean     call droid#ant(<bang>0, "clean")
  command! -buffer -bang AntCompile   call droid#ant(<bang>0, "compile")
  command! -buffer -bang AntDebug     call droid#ant(<bang>0, "debug")
  command! -buffer -bang AntRelease   call droid#ant(<bang>0, "release")
  command! -buffer -bang AntInstall   call droid#ant(<bang>0, "install")
  command! -buffer -bang Antuninstall call droid#ant(<bang>0, "uninstall")

  command! -buffer DroidListAvd call droid#list_avds()
  command! -buffer -nargs=* -complete=customlist,s:listavdscomplete DroidRunAvd  call droid#run_avd()
endfunction

function! s:listavds()
  let avds = []
  let rows = system("android list avd")
  for row in split(rows, "-------")
    let l = matchlist(row, "Name: \(.+\)")
    if !empty(l)
      let d = { 'name' : l[1] }
      let avds += [d]
    endif
  endfor
  return avds
endfunction

function! s:listavdscomplete(A, L, P)
  return map(s:listavds(), ' v:val["name"] ')
endfunction

function! s:addrelated(type)
  let l = a:type
  let cmds = 'ESVT '
  let cmd = ''
  while cmds != ''
    let cplt = " -complete=customlist,s:".l."List"
    exe "command! -buffer -bar -bang -nargs=*".cplt." R".cmd.l." :call s:".l.'Edit("'.cmd.'<bang>","'.l.'",<f-args>)'
    let cmd = strpart(cmds,0,1)
    let cmds = strpart(cmds,1)
  endwhile
endfunction

function! s:cmdtoedit(cmd)
  let cmd = substitute(a:cmd, '\!$', '', '')
  if     cmd == 'S' | return 'split'
  elseif cmd == 'V' | return 'vsplit'
  elseif cmd == 'T' | return 'tabnew'
  elseif cmd == 'D' | return 'XXX: todo'
  endif
  return 'edit'
endfunction

function! s:valuesList(A,L,P)
  return s:relglob("res/values/", "*")
endfunction

function! s:valuesEdit(cmd,prefix,...)
  call s:simpleedit(a:cmd, a:prefix, "/res/values/", (a:0 ? a:1 : ''))
endfunction

function! s:layoutsList(A,L,P)
  return s:relglob("/res/layouts/", "*")
endfunction

function! s:layoutsEdit(cmd,prefix,...)
  call s:simpleedit(a:cmd, a:prefix, "/res/layouts/",  (a:0 ? a:1 : ''))
endfunction

function! s:menuList(A,L,P)
  return s:relglob("/res/menu/", "*")
endfunction

function! s:menuEdit(cmd,prefix,...)
  call s:simpleedit(a:cmd, a:prefix, "/res/menu/",  (a:0 ? a:1 : ''))
endfunction

function! s:xmlList(A,L,P)
  return s:relglob("res/xml/", "*")
endfunction

function! s:xmlEdit(cmd,prefix,...)
  call s:simpleedit(a:cmd, a:prefix, "/res/xml/",  (a:0 ? a:1 : ''))
endfunction

function! s:relglob(path, glob)
  let path = b:approot . "/" . a:path . "/" 
  if isdirectory(path)
    let result = expand(path . a:glob)
    return split(substitute(result, path, "", "g"))
  else
    return []
  endif
endfunction

function! s:simpleedit(cmd, prefix, path, file)
  let bang = a:cmd =~ '\!$'
  let dir = b:approot . a:path
  let cmd = s:cmdtoedit(a:cmd) . (bang ? '!' : '')
  let fullfile = dir . a:file
  let fullcmd = cmd . " " . fullfile
  if isdirectory(dir) && filereadable(fullfile)
    exe fullcmd
  else
    if bang
      if !isdirectory(dir) | call mkdir(dir) | endif
      exe fullcmd
      call s:readtemplate(a:prefix)
    else
      call s:error('File does not exist!')
    endif
  endif
endfunction

function! s:readtemplate(prefix)
  if !g:droid_templates
    return
  endif
  let paths = split(globpath(&rtp, "**/res_templates/" . a:prefix . ".xml"))
  if len(paths) > 0
    let t = paths[0]
    if filereadable(t)
      exe "read " . t
      exe "normal ggdd"
    endif
  endif 
endfunction

" {{{ Initialization

" }}}


" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:tempstr() "{{{
  return tempname() . reltimestr(reltime())
endfunction "}}}

function! s:run() "{{{
  let name = s:tempstr()
  let table = eskk#table#new(name, 'rom_to_hira')
  call table.remove_map('a')
  OK !table.has_map('a'),
        \   "table does not have a map 'a'."
endfunction "}}}

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:glob(...)
  return split(call('glob', a:000), '\n')
endfunction

function! s:run()
  for s in s:glob('plugin/eskk**/*.vim') + s:glob('autoload/eskk**/*.vim')
    try
      source `=s`
      Ok 1, s . ' - no exception was thrown'
    catch
      Ok 0, s . ' - exception was thrown'
      Diag v:exception
      Diag v:throwpoint
    endtry
  endfor
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

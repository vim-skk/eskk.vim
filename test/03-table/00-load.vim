" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
  let tables = {}
  for name in eskk#table#get_all_tables()
    try
      " Loading test.
      let tables[name] = eskk#table#new(name)
      Ok 1
    catch
      Ok 0
    endtry
  endfor

  for name in eskk#table#get_all_tables()
    " Reference equality test.
    Ok tables[name] isnot eskk#table#new(name)
  endfor
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

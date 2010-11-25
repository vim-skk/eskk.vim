" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    let orig = {'foo': 1}
    let D = copy(orig)
    IsDeeply eskk#util#dict_add(D, 'bar', 2), {'foo': 1, 'bar': 2}
    IsDeeply D, orig, 'dict is not destroyed.'
    IsDeeply eskk#util#dict_add(D, 'bar', 2, 'baz', 3), {'foo': 1, 'bar': 2, 'baz': 3}
    IsDeeply eskk#util#dict_add(D, 'foo', -1, 'baz', 3), {'foo': 1, 'baz': 3}
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

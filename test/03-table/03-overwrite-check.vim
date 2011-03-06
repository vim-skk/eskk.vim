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
    for base in eskk#table#get_all_tables()
        let name = s:tempstr()
        let table = eskk#table#new(name, base)
        call table.add_map('lhs', 'map', 'rest')
        call table.add_map('lhs', 'foo', 'bar')

        " table.add_map() will overwrite maps.
        Is table.get_map('lhs'), 'foo',
        \   'table.get_map("lhs") ==# "foo"'
        Is table.get_rest('lhs'), 'bar',
        \   'table.get_map("lhs") ==# "bar"'
    endfor
endfunction "}}}

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

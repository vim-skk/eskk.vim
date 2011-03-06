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
    let table = eskk#table#new(name)
    let maps = {}

    let lhs = s:tempstr()
    call table.add_map(lhs, '', '')
    let maps[lhs] = ['', '']

    let lhs = s:tempstr()
    call table.add_map(lhs, 'vim', '')
    let maps[lhs] = ['vim', '']

    let lhs = s:tempstr()
    call table.add_map(lhs, '', 'is')
    let maps[lhs] = ['', 'is']

    let lhs = s:tempstr()
    call table.add_map(lhs, 'awesome', 'editor')
    let maps[lhs] = ['awesome', 'editor']


    for lhs in keys(maps)
        let [map, rest] = maps[lhs]

        " Empty maps are treated as like
        " those are not registered.
        if map != ''
            Ok table.has_map(lhs)
            Is table.get_map(lhs, -1), map
        else
            Ok !table.has_map(lhs)
            Is table.get_map(lhs, -1), -1
        endif

        if rest != ''
            Ok table.has_rest(lhs)
            Is table.get_rest(lhs, -1), rest
        else
            Ok !table.has_rest(lhs)
            Is table.get_rest(lhs, -1), -1
        endif
    endfor
endfunction "}}}

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

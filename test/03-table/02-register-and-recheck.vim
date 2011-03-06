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
    " this variable `tables` holds elements
    " of the following structure:
    " {
    "   "name" : {table_name},
    "   "base" : {base_table_name},
    "   "maps" : {maps_of_table},
    " }
    let tables_info = []
    for base in eskk#table#get_all_tables()
        let name = s:tempstr()
        let table = eskk#table#new(name, base)
        Is table.get_name(), name,
        \   'table.get_name() ==# name'
        let maps = []
        for _ in range(5)
            let [l, r] = [s:tempstr(), s:tempstr()]
            call add(maps, [l, r])
            call table.add_map(l, r)
        endfor
        call add(tables_info,
        \   {'name': name, 'base': base, 'maps': maps})
        call eskk#register_table(table)
    endfor

    for info in tables_info
        Ok eskk#has_table(info.name),
        \   "eskk has the table '" . info.name . "'."
        let table = eskk#get_table(info.name)
        Is table.get_name(), info.name,
        \   'table.get_name() ==# info.name'
        Ok table.derived_from(info.base),
        \   'table derived from info.base'
        for [l, r] in info.maps
            Is table.get_map(l), r,
            \   'table.get_map(l) ==# r'
        endfor
    endfor
endfunction "}}}

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

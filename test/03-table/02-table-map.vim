" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:tempstr() "{{{
    return tempname() . reltimestr(reltime())
endfunction "}}}

function! s:register_and_recheck() "{{{
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

function! s:do_test_add_overwrite() "{{{
    let name = s:tempstr()
    let table = eskk#table#create(name)

    call table.add('lhs', 'map', 'rest')
    call table.add('lhs', 'foo', 'bar')

    call table.register()

    " Currently overwrite lhs if it exists.
    let table = eskk#table#new(name)
    Is table.get_map('lhs'), 'foo'
    Is table.get_rest('lhs'), 'bar'
endfunction "}}}

function! s:do_test_remove_base_map() "{{{
    let name = s:tempstr()
    let table = eskk#table#create(name, 'rom_to_hira')
    call table.remove('a')
    call table.register()

    let table = eskk#table#new(name)
    OK !table.has_map('a')
endfunction "}}}

function! s:do_test_empty_string() "{{{
    let name = s:tempstr()
    let table = eskk#table#create(name)
    let maps = {}

    let lhs = s:tempstr()
    call table.add(lhs, '', '')
    let maps[lhs] = ['', '']

    let lhs = s:tempstr()
    call table.add(lhs, 'vim', '')
    let maps[lhs] = ['vim', '']

    let lhs = s:tempstr()
    call table.add(lhs, '', 'is')
    let maps[lhs] = ['', 'is']

    let lhs = s:tempstr()
    call table.add(lhs, 'awesome', 'editor')
    let maps[lhs] = ['awesome', 'editor']

    call table.register()


    let table = eskk#table#new(name)
    for lhs in keys(maps)
        let [map, rest] = maps[lhs]

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

function! s:run() "{{{
    call s:register_and_recheck()
    " call s:do_test_add_overwrite()
    " call s:do_test_remove_base_map()
    " call s:do_test_empty_string()
endfunction "}}}

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

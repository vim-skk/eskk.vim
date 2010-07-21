" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:tempstr() "{{{
    return tempname() . reltimestr(reltime())
endfunction "}}}

function! s:add_map(t, maps, times) "{{{
    let t = a:t
    let maps = a:maps

    for _ in range(a:times)
        if _ % 2 == 0
            let [lhs, rhs] = [s:tempstr(), s:tempstr()]
            call t.add(lhs, rhs)
            call add(maps[t.name], [lhs, rhs])
        else
            " Also include rest.
            let [lhs, rhs, rest] = [s:tempstr(), s:tempstr(), s:tempstr()]
            call t.add(lhs, rhs, rest)
            call add(maps[t.name], [lhs, rhs, rest])
        endif
    endfor

    try
        call t.register()
        Ok 1, "must not throw exception (does not conflict)"
    catch
        Ok 0, "must not throw exception (does not conflict)"
    endtry
endfunction "}}}

function! s:do_test_many_tables() "{{{
    let table_names = []
    let maps = {}

    for _ in range(10)
        let name_which_does_not_conflict = s:tempstr()
        if !has_key(maps, name_which_does_not_conflict)
            let maps[name_which_does_not_conflict] = []
        endif

        let t = eskk#table#create(name_which_does_not_conflict)
        Is name_which_does_not_conflict, t.name, 'table name must be the same (' . t.name . ')'

        call s:add_map(t, maps, 10)
        call add(table_names, name_which_does_not_conflict)
    endfor

    for name in table_names
        let t = eskk#table#new(name)
        for [lhs, map; rest] in maps[name]
            Ok t.has_map(lhs)
            Ok t.get_map(lhs) ==# map

            let map_does_not_conflict = map . "hogera"
            Ok t.get_map(lhs, map_does_not_conflict) ==# map

            if !empty(rest)
                Ok t.has_rest(lhs)
                Ok t.get_rest(lhs) ==# rest[0]

                let rest_does_not_conflict = rest[0] . "hogera"
                Ok t.get_rest(lhs, rest_does_not_conflict) ==# rest[0]
            endif
            unlet rest
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
    call s:do_test_many_tables()
    call s:do_test_add_overwrite()
    call s:do_test_empty_string()
endfunction "}}}

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

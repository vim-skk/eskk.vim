" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:tempstr()
    return tempname() . reltimestr(reltime())
endfunction

function! s:add_map(t, maps, times)
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
endfunction

function! s:run()
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
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" NOTE: Argument for table's name must be a:table_name.
" Because of readability to call s:load_table().

" TODO
" - Build table in Vim <SID> mapping table.
" - Make util functions to parse command macro arguments.
" - OO-ize table



" Variables {{{
let s:current_table_name = ''
let s:table_defs = {}
" }}}


" Functions {{{

function! s:parse_arg(arg) "{{{
    let arg = a:arg
    let opt_regex = '-\(\w\+\)=\(\S\+\)'

    " Parse options.
    let opt = {}
    while arg != ''
        let arg = eskk#util#skip_spaces(arg)
        let [a, arg] = eskk#util#get_arg(arg)

        let m = matchlist(a, opt_regex)
        if !empty(m)
            " a is option.
            let [opt_name, opt_value] = m[1:2]
            if opt_name ==# 'rest'
                let opt.rest = opt_value
            else
                throw printf("eskk: EskkTableMap: unknown option '%s'.", opt_name)
            endif
        else
            let arg = eskk#util#unget_arg(arg, a)
            break
        endif
    endwhile

    " Parse arguments.
    let lhs_rhs = []
    while arg != ''
        let arg = eskk#util#skip_spaces(arg)
        let [a, arg] = eskk#util#get_arg(arg)
        call add(lhs_rhs, a)
    endwhile
    if len(lhs_rhs) != 2
        call eskk#util#logf('lhs_rhs = %s', string(lhs_rhs))
        throw 'eskk: EskkTableMap [-rest=...] lhs rhs'
    endif

    return lhs_rhs + [get(opt, 'rest', '')]
endfunction "}}}


function! s:is_mapping_table() "{{{
    return s:current_table_name != ''
endfunction "}}}

function! s:load_table(table_name) "{{{
    call eskk#table#{a:table_name}#load()
endfunction "}}}

function! s:get_table(table_name, ...) "{{{
    call s:load_table(a:table_name)

    return call('get', [s:table_defs, a:table_name] + a:000)
endfunction "}}}

function! s:get_current_table(...) "{{{
    return call('s:get_table', [s:current_table_name] + a:000)
endfunction "}}}


function! eskk#table#define_macro() "{{{
    command!
    \   -buffer -nargs=1
    \   TableBegin
    \   call s:cmd_table_begin(<f-args>)
    command!
    \   -buffer
    \   TableEnd
    \   call s:cmd_table_end()
    command!
    \   -buffer -nargs=+ -bang
    \   Map
    \   call s:cmd_map(<q-args>, "<bang>")
endfunction "}}}

function! eskk#table#undefine_macro() "{{{
    delcommand TableBegin
    delcommand TableEnd
    delcommand Map
endfunction "}}}

function! s:cmd_table_begin(arg) "{{{
    return eskk#table#table_begin(a:arg)
endfunction "}}}

function! s:cmd_table_end() "{{{
    return eskk#table#table_end()
endfunction "}}}

function! s:cmd_map(arg, bang) "{{{
    try
        let [lhs, rhs, rest] = s:parse_arg(a:arg)
        return call('eskk#table#map', [lhs, rhs, (a:bang != '' ? 1 : 0), rest])
    catch /^eskk:/
        call eskk#util#warn(v:exception)
    endtry
endfunction "}}}

function! eskk#table#table_begin(name) "{{{
    let s:current_table_name = a:name
    if !has_key(s:table_defs, s:current_table_name)
        let s:table_defs[s:current_table_name] = {}
    endif
endfunction "}}}

function! eskk#table#table_end() "{{{
    lockvar s:table_defs[s:current_table_name]
    let s:current_table_name = ''
endfunction "}}}

" Force overwrite if a:bang is true.
function! eskk#table#map(lhs, rhs, ...) "{{{
    let [bang, rest] = eskk#util#get_args(a:000, 0, '')

    if !s:is_mapping_table() | return | endif

    " a:lhs is already defined and not banged.
    if !eskk#table#has_map(s:current_table_name, a:lhs) || bang
        call s:create_map(a:lhs, a:rhs, rest)
    endif
endfunction "}}}

function! s:create_map(lhs, rhs, rest) "{{{
    let def = s:get_current_table()
    let def[a:lhs] = {'map_to': a:rhs}
    if a:rest != ''
        " TODO Include 'rest' always.
        let def[a:lhs].rest = a:rest
    endif
endfunction "}}}

function! eskk#table#unmap(lhs) "{{{
    if !s:is_mapping_table() | return | endif
    if eskk#table#has_map(s:current_table_name, a:lhs)
        unlet s:table_defs[s:current_table_name][a:lhs]
    endif
endfunction "}}}


" TODO
" Current implementation is smart but heavy.
" Make table like this?
" 's': {
"   'a': {'map_to': 'さ'},
"
"   .
"   .
"   .
"
"   'y': {'a': {'map_to': 'しゃ'}}
" }
" But this uses a lot of memory.
"
function! eskk#table#has_candidates(...) "{{{
    return !empty(call('eskk#table#get_candidates', a:000))
endfunction "}}}

function! eskk#table#get_candidates(table_name, str_buf) "{{{
    call s:load_table(a:table_name)

    if empty(a:str_buf)
        throw eskk#error#internal_error('eskk: table:')
    endif

    let no_table = {}
    let def = s:get_table(a:table_name, no_table)
    if def is no_table
        return no_table
    else
        return filter(
        \   keys(def),
        \   'stridx(v:val, a:str_buf) == 0'
        \)
    endif
endfunction "}}}


function! eskk#table#has_table(name) "{{{
    return s:get_table(a:name, -1) !=# -1
endfunction "}}}

function! eskk#table#has_map(table_name, lhs) "{{{
    call s:load_table(a:table_name)

    return eskk#util#has_key_f(s:table_defs, [a:table_name, a:lhs])
endfunction "}}}


function! eskk#table#get_map_to(table_name, lhs, ...) "{{{
    call s:load_table(a:table_name)

    if !eskk#table#has_map(a:table_name, a:lhs)
        if a:0 == 0
            throw eskk#error#argument_error('eskk: table:')
        else
            return a:1
        endif
    endif
    return s:table_defs[a:table_name][a:lhs].map_to
endfunction "}}}


function! eskk#table#has_rest(table_name, lhs) "{{{
    call s:load_table(a:table_name)

    return eskk#util#has_key_f(s:table_defs, [a:table_name, a:lhs, 'rest'])
endfunction "}}}

function! eskk#table#get_rest(table_name, lhs, ...) "{{{
    call s:load_table(a:table_name)

    if !eskk#table#has_rest(a:table_name, a:lhs)
        if a:0 == 0
            throw eskk#error#argument_error('eskk: table:')
        else
            return a:1
        endif
    endif
    return s:table_defs[a:table_name][a:lhs].rest
endfunction "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

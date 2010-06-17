" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Load once {{{
if exists('s:loaded')
    finish
endif
let s:loaded = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}
runtime! plugin/eskk.vim

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
                throw eskk#user_error(['eskk', 'table'], printf("unknown option '%s'.", opt_name))
            endif
        else
            let arg = eskk#util#unget_arg(arg, a)
            break
        endif
    endwhile

    " Parse arguments.
    let lhs = ''
    let rhs = ''
    while arg != ''
        let arg = eskk#util#skip_spaces(arg)
        let [a, arg] = eskk#util#get_arg(arg)
        if lhs == ''
            let lhs = a
        else
            let rhs = a
        endif
    endwhile
    if lhs == '' && rhs == ''
        call eskk#util#logf('lhs = %s, rhs = %s', lhs, rhs)
        throw eskk#user_error(['eskk', 'table'], 'Map [-rest=...] lhs rhs')
    endif

    return {
    \   'lhs': lhs,
    \   'rhs': rhs,
    \   'rest': get(opt, 'rest', ''),
    \}
endfunction "}}}


function! s:is_mapping_table() "{{{
    return s:current_table_name != ''
endfunction "}}}

function! s:load_table(table_name) "{{{
    if has_key(s:table_defs, a:table_name)
        return 1
    endif

    " Lazy loading.
    try
        call eskk#table#{a:table_name}#load()
        call eskk#util#logf("table '%s' has been loaded.", a:table_name)
        return 1
    catch
        call eskk#util#logf("can't load table '%s'.", a:table_name)
        return 0
    endtry
endfunction "}}}

function! s:get_table(table_name, ...) "{{{
    if s:load_table(a:table_name)
        call eskk#util#assert(has_key(s:table_defs, a:table_name))
        return s:table_defs[a:table_name]
    else
        let msg = printf("can't load table '%s'.", a:table_name)
        throw eskk#internal_error(['eskk', 'table'], msg)
    endif
endfunction "}}}

function! s:get_current_table(...) "{{{
    return call('s:get_table', [s:current_table_name] + a:000)
endfunction "}}}


" Autoload functions for writing table. {{{

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
    command!
    \   -buffer -nargs=+ -bang
    \   Unmap
    \   call s:cmd_unmap(<q-args>, "<bang>")
endfunction "}}}

function! eskk#table#undefine_macro() "{{{
    delcommand TableBegin
    delcommand TableEnd
    delcommand Map
    delcommand Unmap
endfunction "}}}

function! s:cmd_table_begin(arg) "{{{
    return eskk#table#table_begin(a:arg)
endfunction "}}}

function! s:cmd_table_end() "{{{
    return eskk#table#table_end()
endfunction "}}}

function! s:cmd_map(arg, bang) "{{{
    let parsed = s:parse_arg(a:arg)
    let [lhs, rhs, rest] = [parsed.lhs, parsed.rhs, parsed.rest]
    return call('eskk#table#map', [s:current_table_name, (a:bang != '' ? 1 : 0), lhs, rhs, rest])
endfunction "}}}

function! s:cmd_unmap(arg, bang) "{{{
    let parsed = s:parse_arg(a:arg)
    let [lhs, rhs, rest] = [parsed.lhs, parsed.rhs, parsed.rest]
    return call('eskk#table#unmap', [s:current_table_name, (a:bang != '' ? 1 : 0), lhs, rest])
endfunction "}}}

function! eskk#table#table_begin(name) "{{{
    let s:current_table_name = a:name
    if !has_key(s:table_defs, s:current_table_name)
        let s:table_defs[s:current_table_name] = {}
    endif
endfunction "}}}

function! eskk#table#table_end() "{{{
    let s:current_table_name = ''
endfunction "}}}

" Force overwrite if a:bang is true.
function! eskk#table#map(table_name, force, lhs, rhs, ...) "{{{
    let [rest] = eskk#util#get_args(a:000, '')

    if !s:is_mapping_table() | return | endif

    " a:lhs is already defined and not banged.
    let evaled_lhs = eskk#util#eval_key(a:lhs)
    if !eskk#table#has_map(a:table_name, evaled_lhs) || a:force
        call s:create_map(a:table_name, evaled_lhs, a:rhs, rest)
    endif
endfunction "}}}

function! s:create_map(table_name, lhs, rhs, rest) "{{{
    let def = s:get_table(a:table_name)
    let def[a:lhs] = {'map_to': a:rhs}
    if a:rest != ''
        let def[a:lhs].rest = a:rest
    endif
endfunction "}}}

function! eskk#table#unmap(table_name, silent, lhs, ...) "{{{
    let [rest] = eskk#util#get_args(a:000, '')

    if !s:is_mapping_table() | return | endif

    let evaled_lhs = eskk#util#eval_key(a:lhs)
    if eskk#table#has_map(evaled_lhs)
        call s:destroy_map(a:table_name, evaled_lhs)
    elseif !a:silent
        throw eskk#user_error(['eskk', 'table'], 'No table mapping.')
    endif
endfunction "}}}

function! s:destroy_map(table_name, lhs) "{{{
    let def = s:get_table(a:table_name)
    unlet def[a:lhs]
endfunction "}}}

" }}}


" Autoload functions {{{

function! eskk#table#has_candidates(...) "{{{
    return !empty(call('eskk#table#get_candidates', a:000))
endfunction "}}}

function! eskk#table#get_candidates(table_name, str_buf) "{{{
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

    if !s:load_table(a:table_name)
        let msg = printf("can't load table '%s'.", a:table_name)
        throw eskk#internal_error(['eskk', 'table'], msg)
    endif
    if empty(a:str_buf)
        throw eskk#internal_error(['eskk', 'table'], "a:str_buf is empty.")
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
    return has_key(s:get_table(a:table_name), a:lhs)
endfunction "}}}


function! eskk#table#get_map_to(table_name, lhs, ...) "{{{
    let def = s:get_table(a:table_name)
    if empty(def) || !eskk#table#has_map(a:table_name, a:lhs)
        if a:0 == 0
            throw eskk#internal_error(['eskk', 'table'])
        else
            return a:1
        endif
    endif
    return def[a:lhs].map_to
endfunction "}}}


function! eskk#table#has_rest(table_name, lhs) "{{{
    return eskk#util#has_key_f(s:get_table(a:table_name), [a:lhs, 'rest'])
endfunction "}}}

function! eskk#table#get_rest(table_name, lhs, ...) "{{{
    let def = s:get_table(a:table_name)
    if empty(def) || !eskk#table#has_rest(a:table_name, a:lhs)
        if a:0 == 0
            throw eskk#internal_error(['eskk', 'table'])
        else
            return a:1
        endif
    endif
    return def[a:lhs].rest
endfunction "}}}


function! eskk#table#get_definition(table_name) "{{{
    return s:get_table(a:table_name)
endfunction "}}}

" }}}


" OO interface {{{
let s:table_obj = {}

function! eskk#table#new(table_name) "{{{
    call s:load_table(a:table_name)

    let obj = deepcopy(s:table_obj)
    let obj.table_name = a:table_name

    return obj
endfunction "}}}


" I need meta programming in Vim script!!

function! s:table_obj.has_candidates(...) dict "{{{
    return call('eskk#table#has_candidates', [self.table_name] + a:000)
endfunction "}}}

function! s:table_obj.get_candidates(...) dict "{{{
    return call('eskk#table#get_candidates', [self.table_name] + a:000)
endfunction "}}}

function! s:table_obj.has_map(...) dict "{{{
    return call('eskk#table#has_map', [self.table_name] + a:000)
endfunction "}}}

function! s:table_obj.get_map_to(...) dict "{{{
    return call('eskk#table#get_map_to', [self.table_name] + a:000)
endfunction "}}}

function! s:table_obj.has_rest(...) dict "{{{
    return call('eskk#table#has_rest', [self.table_name] + a:000)
endfunction "}}}

function! s:table_obj.get_rest(...) dict "{{{
    return call('eskk#table#get_rest', [self.table_name] + a:000)
endfunction "}}}


lockvar s:table_obj
" }}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

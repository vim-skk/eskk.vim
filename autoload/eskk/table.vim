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



" Variables {{{
let s:table_defs = {}

let s:MAP_TO_INDEX = 0
let s:REST_INDEX = 1
lockvar s:MAP_TO_INDEX
lockvar s:REST_INDEX
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


function! s:get_table(table_name, ...) "{{{
    if has_key(s:table_defs, a:table_name)
        return s:table_defs[a:table_name]
    endif

    " Lazy loading.
    let s:table_defs[a:table_name] = eskk#table#{a:table_name}#load()
    call eskk#util#logf("table '%s' has been loaded.", a:table_name)
    return s:table_defs[a:table_name]
endfunction "}}}

function! s:get_current_table(...) "{{{
    return call('s:get_table', [s:current_table_name] + a:000)
endfunction "}}}


" Autoload functions for writing table. {{{

" Force overwrite if a:bang is true.
function! eskk#table#map(table_name, force, lhs, rhs, ...) "{{{
    let [rest] = eskk#util#get_args(a:000, '')

    " a:lhs is already defined and not banged.
    let evaled_lhs = eskk#util#eval_key(a:lhs)
    if !eskk#table#has_map(a:table_name, evaled_lhs) || a:force
        call s:create_map(a:table_name, evaled_lhs, a:rhs, rest)
    endif
endfunction "}}}

function! s:create_map(table_name, lhs, rhs, rest) "{{{
    let def = s:get_table(a:table_name)
    let def[a:lhs] = [a:rhs, a:rest]
endfunction "}}}

function! eskk#table#unmap(table_name, silent, lhs, ...) "{{{
    let [rest] = eskk#util#get_args(a:000, '')

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
    return def[a:lhs][s:MAP_TO_INDEX]
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
    return def[a:lhs][s:REST_INDEX]
endfunction "}}}


function! eskk#table#get_definition(table_name) "{{{
    return s:get_table(a:table_name)
endfunction "}}}

" }}}


" OO interface {{{
let s:table_obj = {}

function! eskk#table#new(table_name) "{{{
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

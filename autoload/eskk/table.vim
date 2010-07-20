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

" NOTE: `s:table_defs` Structure is:
"
" let s:table_defs['table_name'] = eskk#table#create()
"
" BASE TABLE:
" eskk#table#create() = {
"   'name': 'table_name',
"   'data': {...},
" }
"
" DERIVED TABLE:
" eskk#table#create() = {
"   'name': 'table_name',
"   'data': {
"       {'method': 'add', 'data': {...}},
"       {'method': 'remove', 'data': {...}},
"       ...
"   },
"   'parents': [
"       eskk#table#create(),
"       eskk#table#create(),
"       ...
"   ],
" }

" Variables {{{
let s:table_defs = {}
let s:cached_tables = {}

let s:MAP_TO_INDEX = 0
let s:REST_INDEX = 1
lockvar s:MAP_TO_INDEX
lockvar s:REST_INDEX
" }}}

" Functions {{{

" Primitive table functions {{{

function! s:load_table(table_name) "{{{
    if !has_key(s:table_defs, a:table_name)
        let msg = printf('warning: %s is not registered.', a:table_name)
        throw eskk#internal_error(['eskk', 'table'], msg)
    endif
    let def = s:table_defs[a:table_name]

    if !def._loaded
        call def.init()
        let def._loaded = 1
    endif
endfunction "}}}

function! s:get_table_data(table_name, ...) "{{{
    if s:table_defs[a:table_name]._loaded
        return s:table_defs[a:table_name].data
    endif

    " Lazy loading.
    call s:load_table(a:table_name)
    return s:table_defs[a:table_name].data
endfunction "}}}

function! s:has_table(table_name) "{{{
    call s:load_table(a:table_name)    " to load this table.
    return has_key(s:table_defs, a:table_name)
endfunction "}}}

function! s:register_table(skel) "{{{
    let skel = a:skel

    if has_key(s:table_defs, skel.name)
        " Do not allow override table.
        let msg = printf("'%s' has been already registered.", skel.name)
        throw eskk#internal_error(['eskk', 'table'], msg)
    endif

    let s:table_defs[skel.name] = skel
endfunction "}}}

function! s:is_base_table(table_name) "{{{
    return !has_key(s:get_table_data(a:table_name), 'parents')
endfunction "}}}

function! s:get_map(table_name, search_lhs, index, ...) "{{{
    if s:is_base_table(a:table_name)
        let t = s:get_table_data(a:table_name)
        if !eskk#util#has_key_f(t, [a:search_lhs, a:index])
        \   || t[a:search_lhs][a:index] == ''
            if a:0
                return a:1
            else
                throw eskk#internal_error(['eskk', 'table'])
            endif
        endif
        return t[a:search_lhs][a:index]
    else
        let derived = s:table_defs[a:table_name].derived
        let derived_result = {}    " key is lhs.
        " Process each derived List elements *in order*.
        " NOTE: Do not return inside `:for`.
        for i in range(len(derived))
            if has_key(derived[i].data, a:search_lhs)
                if derived[i].method ==# 'add'
                    let derived_result[a:search_lhs] = derived[i].data[a:search_lhs][a:index]
                elseif derived[i].method ==# 'remove'
                    if has_key(derived_result, a:search_lhs)
                        unlet derived_result[a:search_lhs]
                    endif
                else
                    let msg = "`method` key's value is one of 'add', 'remove'."
                    throw eskk#internal_error(['eskk', 'table'], msg)
                endif
            endif
        endfor
        if has_key(derived_result, a:search_lhs)
            return derived_result[a:search_lhs]
        endif

        " No map in `derived`. Look up in base dict.
        return call('s:get_map', [s:table_defs[a:table_name].name, a:search_lhs, a:index] + a:000)
    endif

    " No lhs in `s:table_defs`.
    if a:0
        return a:1
    else
        throw eskk#internal_error(['eskk', 'table'])
    endif
endfunction "}}}

function! s:has_map(table_name, lhs, index) "{{{
    let no_map = {}
    return s:get_map(a:table_name, a:lhs, a:index, no_map) isnot no_map
endfunction "}}}

" }}}


" eskk#table#create() {{{
let s:register_skeleton = {'data': {}, '_loaded': 0}

function! eskk#table#create(name) "{{{
    let obj = deepcopy(s:register_skeleton, 1)
    let obj.name = a:name
    return obj
endfunction "}}}

" TODO
function! s:register_skeleton.add() dict "{{{
endfunction "}}}

function! s:register_skeleton.add_from_dict(dict) dict "{{{
    let self.data = a:dict
endfunction "}}}

function! s:register_skeleton.register() dict "{{{
    call s:register_table(self)
endfunction "}}}

lockvar s:register_skeleton
" }}}


" Autoload functions {{{

function! eskk#table#has_candidates(...) "{{{
    return !empty(call('eskk#table#get_candidates', a:000))
endfunction "}}}

function! eskk#table#get_candidates(table_name, str_buf) "{{{
    if empty(a:str_buf)
        throw eskk#internal_error(['eskk', 'table'], "a:str_buf is empty.")
    endif

    if !s:has_table(a:table_name)
        return {}
    else
        return filter(
        \   keys(s:get_table_data(a:table_name)),
        \   'stridx(v:val, a:str_buf) == 0'
        \)
    endif
endfunction "}}}

function! eskk#table#has_map(table_name, lhs) "{{{
    return call('s:has_map', [a:table_name, a:lhs, s:MAP_TO_INDEX])
endfunction "}}}

function! eskk#table#get_map(table_name, lhs, ...) "{{{
    return call('s:get_map', [a:table_name, a:lhs, s:MAP_TO_INDEX] + a:000)
endfunction "}}}

function! eskk#table#has_rest(table_name, lhs) "{{{
    return call('s:has_map', [a:table_name, a:lhs, s:REST_INDEX])
endfunction "}}}

function! eskk#table#get_rest(table_name, lhs, ...) "{{{
    return call('s:get_map', [a:table_name, a:lhs, s:REST_INDEX] + a:000)
endfunction "}}}

" }}}


" OO interface {{{
let s:table_obj = {}

function! eskk#table#new(table_name) "{{{
    if has_key(s:cached_tables, a:table_name)
        return s:cached_tables[a:table_name]
    endif

    " Cache under s:cached_tables.
    let s:cached_tables[a:table_name] = s:table_obj_new(a:table_name)
    return s:cached_tables[a:table_name]
endfunction "}}}

function! s:table_obj_new(table_name) "{{{
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

function! s:table_obj.get_map(...) dict "{{{
    return call('eskk#table#get_map', [self.table_name] + a:000)
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

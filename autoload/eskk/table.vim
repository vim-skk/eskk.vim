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
"   'data': {
"       'lhs': ['map', 'rest'],
"       'lhs2': ['map2', 'rest2'],
"       ...
"   },
" }
"
" DERIVED TABLE:
" eskk#table#create() = {
"   'name': 'table_name',
"   'data': {
"       'lhs': {'method': 'add', 'data': ['map', 'rest']},
"       'lhs2': {'method': 'remove', 'data': ['map2', 'rest2']},
"       ...
"   },
"   'bases': [
"       eskk#table#create(),
"       eskk#table#create(),
"       ...
"   ],
" }

" Variables {{{
let s:table_defs = {}
let s:cached_tables = {}
" let s:cached_maps = {}    " TODO

let s:MAP_TO_INDEX = 0
let s:REST_INDEX = 1
lockvar s:MAP_TO_INDEX
lockvar s:REST_INDEX
" }}}

" Functions {{{

" Primitive table functions {{{

function! s:load_table(table_name) "{{{
    if !has_key(s:table_defs, a:table_name)
        let msg = printf('%s is not registered.', a:table_name)
        throw eskk#internal_error(['eskk', 'table'], msg)
    endif
    let def = s:table_defs[a:table_name]

    if def._loaded
        return
    endif

    if has_key(def, 'init')
        call def.init()
    endif

    if has_key(def, 'bases')
        call eskk#util#logf("table %s is derived table. Let's load base tables...", a:table_name)
        for base in def.bases
            call s:load_table(base.name)
        endfor
    endif

    let def._loaded = 1
    call eskk#util#logf('table %s has been loaded.', a:table_name)
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

function! s:is_base_table(table_name) "{{{
    return !has_key(s:get_table_data(a:table_name), 'bases')
endfunction "}}}

function! s:get_map(table_name, search_lhs, index, ...) "{{{
    let data = s:get_table_data(a:table_name)

    if s:is_base_table(a:table_name)
        if !eskk#util#has_key_f(data, [a:search_lhs, a:index])
        \   || data[a:search_lhs][a:index] == ''
            " No lhs in `s:table_defs`.
            if a:0
                return a:1
            else
                throw eskk#internal_error(['eskk', 'table'])
            endif
        endif
        return data[a:search_lhs][a:index]
    else
        if has_key(data, a:search_lhs)
            if data[a:search_lhs].method ==# 'add'
                return data[a:search_lhs].data[a:index]
            elseif data[a:search_lhs].method ==# 'remove'
                " No lhs in `s:table_defs`.
                if a:0
                    return a:1
                else
                    throw eskk#internal_error(['eskk', 'table'])
                endif
            else
                throw eskk#internal_error(
                \   ['eskk', 'table'],
                \   printf("%s: invalid method of lhs '%s'.",
                \       data[a:search_lhs].method,
                \       a:search_lhs
                \   )
                \)
            endif
        endif

        let not_found = {}
        for parent in s:table_defs[a:table_name].bases
            let r = call('s:get_map', [a:table_name, a:search_lhs, a:index, not_found])
            if r isnot not_found
                return r
            endif
        endfor

        " No lhs in `s:table_defs`.
        if a:0
            return a:1
        else
            throw eskk#internal_error(['eskk', 'table'])
        endif
    endif
endfunction "}}}

function! s:has_map(table_name, lhs, index) "{{{
    let not_found = {}
    return s:get_map(a:table_name, a:lhs, a:index, not_found) isnot not_found
endfunction "}}}

" }}}


" Table information per one table {{{
let s:register_skeleton = {'data': {}, '_loaded': 0}

function! eskk#table#create(name, ...) "{{{
    let obj = deepcopy(s:register_skeleton, 1)
    let obj.name = a:name
    if a:0
        let names = type(a:1) == type([]) ? a:1 : [a:1]
        let obj.bases = map(names, 'eskk#table#create(v:val)')
    endif
    return obj
endfunction "}}}

function! s:register_skeleton.is_base() dict "{{{
    return !has_key(self, 'bases')
endfunction "}}}

function! s:register_skeleton.add(lhs, map, ...) dict "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    if self.is_base()
        let self.data[a:lhs] = pair
    else
        let self.data[a:lhs] = {'method': 'add', 'data': pair}
    endif
endfunction "}}}

function! s:register_skeleton.remove(lhs, map, ...) dict "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    if self.is_base()
        let self.data[a:lhs] = pair
    else
        let self.data[a:lhs] = {'method': 'remove', 'data': pair}
    endif
endfunction "}}}

function! s:register_skeleton.add_from_dict(dict) dict "{{{
    let self.data = a:dict
endfunction "}}}

function! s:register_skeleton.register() dict "{{{
    if has_key(s:table_defs, self.name)
        " Do not allow override table.
        let msg = printf("'%s' has been already registered.", self.name)
        throw eskk#internal_error(['eskk', 'table'], msg)
    endif

    let s:table_defs[self.name] = self
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

" OO interface for autoload functions {{{
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


" Debug {{{

function! eskk#table#_dump() "{{{
    let def = s:table_defs
    PP def
endfunction "}}}
" }}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

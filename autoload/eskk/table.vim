" vim:foldmethod=marker:fen:
scriptencoding utf-8


" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" NOTE: s:table_defs is in autoload/eskk.vim
"
" s:table_defs = {
"   'table_name': eskk#table#new(),
"   'table_name2': eskk#table#new(),
"   ...
" }
"
" Base Table:
" {
"   '_name': 'table_name',
"   '_data': {
"       'lhs': ['map', 'rest'],
"       'lhs2': ['map2', 'rest2'],
"       ...
"   },
" }
"
" Derived Table:
" {
"   '_name': 'table_name',
"   '_data': {
"       'lhs': {'method': 'add', 'data': ['map', 'rest']},
"       'lhs2': {'method': 'remove'},
"       ...
"   },
"   '_bases': [
"       eskk#table#new(),
"       eskk#table#new(),
"       ...
"   ],
" }


function! eskk#table#get_all_tables() "{{{
    return map(
    \   eskk#util#globpath('autoload/eskk/table/*.vim'),
    \   'fnamemodify(v:val, ":t:r")'
    \)
endfunction "}}}

" s:register_skeleton {{{
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

function! eskk#table#create_from_file(name) "{{{
    let table = eskk#table#create(a:name)
    let def = eskk#table#{a:name}#load()
    for lhs in keys(def)
        let [map_to, rest] = def[lhs]
        call table.add(lhs, map_to, rest)
    endfor
    return table
endfunction "}}}

function! s:register_skeleton.is_base() "{{{
    return !has_key(self, 'bases')
endfunction "}}}

function! s:register_skeleton.add(lhs, map, ...) "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    if self.is_base()
        let self.data[a:lhs] = pair
    else
        let self.data[a:lhs] = {'method': 'add', 'data': pair}
    endif
    return self
endfunction "}}}

function! s:register_skeleton.remove(lhs) "{{{
    if self.is_base()
        throw eskk#user_error(
        \   ['eskk', 'table'],
        \   "Must not remove base class map."
        \)
    else
        let self.data[a:lhs] = {'method': 'remove'}
    endif
    return self
endfunction "}}}

function! s:register_skeleton.add_from_dict(dict) "{{{
    let self.data = a:dict
    return self
endfunction "}}}
" }}}


function! s:is_base_table(table) "{{{
    return !has_key(a:table, '_bases')
endfunction "}}}

" s:table_obj {{{
let s:table_obj = {'_data': {}}

function! eskk#table#new(table_name, ...) "{{{
    if a:0
        let obj = deepcopy(s:derived_table)
        let obj._table_name = a:table_name
        let obj._bases = a:1
    else
        let obj = deepcopy(s:base_table)
        let obj.table_name = a:table_name
    endif

    return obj
endfunction "}}}

function! eskk#table#new_from_file(table_name) "{{{
    let obj = eskk#table#new(a:table_name)
    function obj.initialize()
        call self.add_from_dict(eskk#table#{self._name}#load())
    endfunction
    return obj
endfunction "}}}


function! s:table_obj.has_candidates(lhs_head) "{{{
    let not_found = {}
    return self.get_candidates(a:lhs_head, 1, not_found) isnot not_found
endfunction "}}}
function! s:table_obj.get_candidates(lhs_head, max_candidates, ...) "{{{
    return call(
    \   's:get_candidates',
    \   [self.table_name, a:lhs_head, a:max_candidates] + a:000
    \)
endfunction "}}}
function! s:get_candidates(table_name, lhs_head, max_candidates, ...) "{{{
    call eskk#util#assert(
    \   a:max_candidates !=# 0,
    \   "a:max_candidates must be negative or positive."
    \)

    let data = eskk#get_table(a:table_name)
    let cached_candidates = eskk#_get_cached_candidates()
    if g:eskk#cache_table_candidates
    \   && eskk#util#has_key_f(
    \           cached_candidates,
    \           [a:table_name, a:lhs_head]
    \       )
        let candidates = cached_candidates[a:table_name][a:lhs_head]
    else
        let candidates = filter(
        \   copy(data), 'stridx(v:key, a:lhs_head) == 0'
        \)
        if g:eskk#cache_table_candidates
            call eskk#util#let_f(
            \   cached_candidates,
            \   [a:table_name, a:lhs_head],
            \   candidates
            \)
        endif
    endif

    if !empty(candidates)
        return candidates
    endif

    if !s:is_base_table(data)
        " Search base tables.
        let not_found = {}
        let table_defs = eskk#_get_table_defs()
        for base in table_defs[a:table_name].bases
            let r = s:get_candidates(
            \   base.name,
            \   a:lhs_head,
            \   a:max_candidates,
            \   not_found
            \)
            if r isnot not_found
                return r
            endif
        endfor
    endif

    " No lhs_head in `eskk#_get_table_defs()`.
    if a:0
        return a:1
    else
        throw eskk#internal_error(['eskk', 'table'])
    endif
endfunction "}}}

function! s:table_obj.has_map(lhs) "{{{
    let not_found = {}
    return self.get_map(a:lhs, not_found) isnot not_found
endfunction "}}}
function! s:table_obj.get_map(lhs, ...) "{{{
    return call(
    \   's:get_map',
    \   [self.table_name, a:lhs, 0] + a:000
    \)
endfunction "}}}
function! s:table_obj.has_rest(lhs) "{{{
    let not_found = {}
    return self.get_rest(a:lhs, not_found) isnot not_found
endfunction "}}}
function! s:table_obj.get_rest(lhs, ...) "{{{
    return call(
    \   's:get_map',
    \   [self.table_name, a:lhs, 1] + a:000
    \)
endfunction "}}}
function! s:get_map(table_name, lhs, index, ...) "{{{
    let data = eskk#get_table(a:table_name)
    let cached_maps = eskk#_get_cached_maps()

    if g:eskk#cache_table_map
    \   && eskk#util#has_key_f(cached_maps, [a:table_name, a:lhs])
        if cached_maps[a:table_name][a:lhs][a:index] != ''
            return cached_maps[a:table_name][a:lhs][a:index]
        else
            " No lhs in `eskk#_get_table_defs()`.
            if a:0
                return a:1
            else
                throw eskk#internal_error(['eskk', 'table'])
            endif
        endif
    endif

    if s:is_base_table(data)
        if eskk#util#has_key_f(data, [a:lhs, a:index])
        \   && data[a:lhs][a:index] != ''
            if g:eskk#cache_table_map
                call eskk#util#let_f(
                \   cached_maps,
                \   [a:table_name, a:lhs],
                \   data[a:lhs]
                \)
            endif
            return data[a:lhs][a:index]
        endif
    else
        if has_key(data, a:lhs)
            if data[a:lhs].method ==# 'add'
            \   && data[a:lhs].data[a:index] != ''
                if g:eskk#cache_table_map
                    call eskk#util#let_f(
                    \   cached_maps,
                    \   [a:table_name, a:lhs],
                    \   data[a:lhs].data
                    \)
                endif
                return data[a:lhs].data[a:index]
            elseif data[a:lhs].method ==# 'remove'
                " No lhs in `eskk#_get_table_defs()`.
                if a:0
                    return a:1
                else
                    throw eskk#internal_error(['eskk', 'table'])
                endif
            endif
        endif

        let not_found = {}
        let table_defs = eskk#_get_table_defs()
        for base in table_defs[a:table_name].bases
            let r = s:get_map(base.name, a:lhs, a:index, not_found)
            if r isnot not_found
                return r
            endif
        endfor
    endif

    " No lhs in `eskk#_get_table_defs()`.
    if a:0
        return a:1
    else
        throw eskk#internal_error(
        \   ['eskk', 'table'],
        \   eskk#util#formatstrf(
        \       'table name = %s, lhs = %s, index = %d',
        \       a:table_name, a:lhs, a:index
        \   )
        \)
    endif
endfunction "}}}

function! s:table_obj.load() "{{{
    if has_key(self, 'initialize')
        if has_key(self, '_bases')
            " TODO: after initializing base tables,
            " this object has no need to have base references.
            " because they can ("should", curerntly) be
            " obtained from s:table_defs in autoload/eskk.vim
            " (it can be considered as flyweight object for all tables)
            for base in self._bases
                if has_key(base, 'initialize')
                    call base.initialize()
                    unlet base.initialize
                endif
            endfor
        endif
        call self.initialize()
        unlet self.initialize
    endif
    return self._data
endfunction "}}}

function! s:table_obj.is_base() "{{{
    return has_key(self, '_bases')
endfunction "}}}

" }}}

" s:base_table {{{
let s:base_table = deepcopy(s:table_obj)

function! s:base_table.add_from_dict(dict) "{{{
    let self._data = a:dict
endfunction "}}}

function! s:base_table.add(lhs, map, ...) "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    let self._data[a:lhs] = pair
endfunction "}}}
" }}}

" s:derived_table {{{
let s:derived_table = deepcopy(s:table_obj)

function! s:derived_table.add(lhs, map, ...) "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    let self._data[a:lhs] = {'method': 'add', 'data': pair}
endfunction "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

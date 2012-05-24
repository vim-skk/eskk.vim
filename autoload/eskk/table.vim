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
" s:DataTable = {
"   '_name': 'table_name',
"   '_data': {
"       'lhs': ['map', 'rest'],
"       'lhs2': ['map2', 'rest2'],
"       ...
"   },
" }
"
" s:DiffTable = {
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

function! s:get_table_obj(table) "{{{
    return type(a:table) ==# type({}) ?
    \       a:table :
    \       type(a:table) ==# type('') ?
    \       eskk#get_table(a:table) :
    \       s:must_not_reach_here(a:table)
endfunction "}}}
function! s:must_not_reach_here(table) "{{{
    " Handle cyclic reference.
    let dump = type(a:table) ==# type([]) ? '[Array]' : string(a:table)
    throw eskk#util#build_error(
    \   ['eskk', 'build'],
    \   ["s:get_table_obj() received invalid arguments: "
    \   . dump]
    \)
endfunction "}}}


function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID

" s:AbstractTable {{{

" Constructor of s:DataTable, s:DiffTable
function! eskk#table#new(table_name, ...) "{{{
    if a:0
        let obj = deepcopy(s:DiffTable)
        let obj._name = a:table_name
        let obj._bases = []
        for base in type(a:1) == type([]) ? a:1 : [a:1]
            if type(base) == type("")
                " Assume it's installed table name.
                call add(obj._bases, eskk#table#new_from_file(base))
            elseif type(base) == type({})
                " Assume it's s:AbstractTable object.
                call add(obj._bases, base)
            else
                throw eskk#table#invalid_arguments_error(a:table_name)
            endif
        endfor
        call s:validate_base_tables(obj)
    else
        let obj = deepcopy(s:DataTable)
        let obj._name = a:table_name
    endif

    return obj
endfunction "}}}
function! s:validate_base_tables(this) "{{{
    " a:this.get_all_base_tables() will throw
    " an exception when duplicated tables
    " in ancestors.
    " s:validate_base_tables()'s job is to throw
    " an exception when duplicated tables
    " in ancestors.
    call a:this.get_all_base_tables()
endfunction "}}}
function! eskk#table#extending_myself_error(table_name) "{{{
    return eskk#util#build_error(
    \   ['eskk', 'table'],
    \   ["table '" . a:table_name . "' derived from itself"]
    \)
endfunction "}}}
function! eskk#table#invalid_arguments_error(table_name) "{{{
    return eskk#util#build_error(
    \   ['eskk', 'build'],
    \   ["eskk#table#new() received invalid arguments "
    \   . "(table name: " . a:table_name . ")"]
    \)
endfunction "}}}

function! eskk#table#new_from_file(table_name) "{{{
    let obj = eskk#table#new(a:table_name)
    function obj.initialize()
        call self.add_from_dict(eskk#table#{self._name}#load())
    endfunction
    return obj
endfunction "}}}

function! s:AbstractTable_get_all_base_tables() dict "{{{
    let set = eskk#util#create_data_ordered_set()
    let table_stack = [self]
    while !empty(table_stack)
        let table = remove(table_stack, -1)
        if set.has(table._name)
            throw eskk#table#extending_myself_error(table._name)
        endif
        call set.push(table._name)
        if table.is_child()
            let table_stack += table._bases
        endif
    endwhile
    return set.to_list()
endfunction "}}}
function! s:AbstractTable_derived_from(base) dict "{{{
    for table in self.get_all_base_tables()
        if table ==# a:base
            return 1
        endif
    endfor
    return 0
endfunction "}}}

function! s:AbstractTable_has_candidates(lhs_head) dict "{{{
    return self.has_n_candidates(a:lhs_head, 1)
endfunction "}}}
function! s:AbstractTable_has_n_candidates(lhs_head, n) dict "{{{
    if a:n <= 0
        throw eskk#util#build_error(
        \   ['eskk', 'table'],
        \   's:AbstractTable.has_n_candidates(): a:n must be positive'
        \)
    endif
    " Has n candidates at least.
    let NONE = []
    let c = self.get_candidates(a:lhs_head, NONE)
    return c isnot NONE && len(c) >= a:n
endfunction "}}}
function! s:AbstractTable_get_candidates(lhs_head, ...) dict "{{{
    return call(
    \   's:get_candidates',
    \   [self, a:lhs_head] + a:000
    \)
endfunction "}}}
function! s:get_candidates(table, lhs_head, ...) "{{{
    " Search in this table.
    let candidates = eskk#util#create_data_ordered_set()
    call candidates.append(filter(
    \   keys(a:table.load()),
    \   '!stridx(v:val, a:lhs_head)'
    \))

    " Search in base tables.
    if a:table.is_child()
        for base in a:table._bases
            call candidates.append(s:get_candidates(
            \   base,
            \   a:lhs_head,
            \   []
            \))
        endfor
    endif

    if !candidates.empty()
        return candidates.to_list()
    endif

    " No lhs_head in a:table and its base tables.
    if a:0
        return a:1
    else
        throw eskk#internal_error(['eskk', 'table'])
    endif
endfunction "}}}


let [
\   s:MAP_INDEX,
\   s:REST_INDEX
\] = range(2)

function! s:AbstractTable_has_map(lhs) dict "{{{
    let not_found = {}
    return self.get_map(a:lhs, not_found) isnot not_found
endfunction "}}}
function! s:AbstractTable_get_map(lhs, ...) dict "{{{
    return call(
    \   's:get_map',
    \   [self, a:lhs, s:MAP_INDEX] + a:000
    \)
endfunction "}}}
function! s:AbstractTable_has_rest(lhs) dict "{{{
    let not_found = {}
    return self.get_rest(a:lhs, not_found) isnot not_found
endfunction "}}}
function! s:AbstractTable_get_rest(lhs, ...) dict "{{{
    return call(
    \   's:get_map',
    \   [self, a:lhs, s:REST_INDEX] + a:000
    \)
endfunction "}}}
function! s:get_map(table, lhs, index, ...) "{{{
    if a:lhs ==# ''
        return s:get_map_not_found(a:table, a:lhs, a:index, a:000)
    endif

    let data = a:table.load()
    if g:eskk#cache_table_map
    \   && has_key(a:table._cached_maps, a:lhs)
        if a:table._cached_maps[a:lhs][a:index] != ''
            return a:table._cached_maps[a:lhs][a:index]
        else
            return s:get_map_not_found(a:table, a:lhs, a:index, a:000)
        endif
    endif

    if a:table.is_base()
        if has_key(data, a:lhs)
        \   && eskk#util#has_idx(data[a:lhs], a:index)
        \   && data[a:lhs][a:index] != ''
            if g:eskk#cache_table_map
                let a:table._cached_maps[a:lhs] = data[a:lhs]
            endif
            return data[a:lhs][a:index]
        endif
    else
        if has_key(data, a:lhs)
            if data[a:lhs].method ==# 'add'
            \   && data[a:lhs].data[a:index] != ''
                if g:eskk#cache_table_map
                    let a:table._cached_maps[a:lhs] = data[a:lhs].data
                endif
                return data[a:lhs].data[a:index]
            elseif data[a:lhs].method ==# 'remove'
                return s:get_map_not_found(a:table, a:lhs, a:index, a:000)
            endif
        endif

        let not_found = {}
        for base in a:table._bases
            let r = s:get_map(base, a:lhs, a:index, not_found)
            if r isnot not_found
                " TODO: cache here
                return r
            endif
        endfor
    endif

    return s:get_map_not_found(a:table, a:lhs, a:index, a:000)
endfunction "}}}
function! s:get_map_not_found(table, lhs, index, rest_args) "{{{
    " No lhs in a:table.
    if !empty(a:rest_args)
        return a:rest_args[0]
    else
        throw eskk#internal_error(
        \   ['eskk', 'table'],
        \   printf(
        \       'table name = %s, lhs = %s, index = %d',
        \       string(a:table._name),
        \       string(a:lhs),
        \       string(a:index)
        \   )
        \)
    endif
endfunction "}}}

function! s:AbstractTable_load() dict "{{{
    if has_key(self, '_bases')
        " TODO: after initializing base tables,
        " this object has no need to have base references.
        " because they can ("should", curerntly) be
        " obtained from s:table_defs in autoload/eskk.vim
        " (it can be considered as flyweight object for all tables)
        for base in self._bases
            call s:do_initialize(base)
        endfor
    endif
    call s:do_initialize(self)
    return self._data
endfunction "}}}
function! s:AbstractTable_get_mappings() dict "{{{
    return self._data
endfunction "}}}
function! s:do_initialize(table) "{{{
    if has_key(a:table, 'initialize')
        call a:table.initialize()
        unlet a:table.initialize
    endif
endfunction "}}}

function! s:AbstractTable_is_base() dict "{{{
    return !has_key(self, '_bases')
endfunction "}}}
function! s:AbstractTable_is_child() dict "{{{
    return !self.is_base()
endfunction "}}}

function! s:AbstractTable_get_name() dict "{{{
    return self._name
endfunction "}}}
function! s:AbstractTable_get_base_tables() dict "{{{
    return self.is_child() ? self._bases : []
endfunction "}}}


let s:AbstractTable = {
\   '_name': '',
\   '_data': {},
\   '_cached_maps': {},
\
\   'get_all_base_tables': eskk#util#get_local_funcref('AbstractTable_get_all_base_tables', s:SID_PREFIX),
\   'derived_from': eskk#util#get_local_funcref('AbstractTable_derived_from', s:SID_PREFIX),
\   'has_candidates': eskk#util#get_local_funcref('AbstractTable_has_candidates', s:SID_PREFIX),
\   'has_n_candidates': eskk#util#get_local_funcref('AbstractTable_has_n_candidates', s:SID_PREFIX),
\   'get_candidates': eskk#util#get_local_funcref('AbstractTable_get_candidates', s:SID_PREFIX),
\   'has_map': eskk#util#get_local_funcref('AbstractTable_has_map', s:SID_PREFIX),
\   'get_map': eskk#util#get_local_funcref('AbstractTable_get_map', s:SID_PREFIX),
\   'has_rest': eskk#util#get_local_funcref('AbstractTable_has_rest', s:SID_PREFIX),
\   'get_rest': eskk#util#get_local_funcref('AbstractTable_get_rest', s:SID_PREFIX),
\   'load': eskk#util#get_local_funcref('AbstractTable_load', s:SID_PREFIX),
\   'get_mappings': eskk#util#get_local_funcref('AbstractTable_get_mappings', s:SID_PREFIX),
\   'is_base': eskk#util#get_local_funcref('AbstractTable_is_base', s:SID_PREFIX),
\   'is_child': eskk#util#get_local_funcref('AbstractTable_is_child', s:SID_PREFIX),
\   'get_name': eskk#util#get_local_funcref('AbstractTable_get_name', s:SID_PREFIX),
\   'get_base_tables': eskk#util#get_local_funcref('AbstractTable_get_base_tables', s:SID_PREFIX),
\}

" }}}

" s:DataTable {{{

function! s:DataTable_add_from_dict(dict) dict "{{{
    let self._data = a:dict
endfunction "}}}

function! s:DataTable_add_map(lhs, map, ...) dict "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    let self._data[a:lhs] = pair
endfunction "}}}


let s:DataTable = extend(
\   deepcopy(s:AbstractTable),
\   {
\       'add_from_dict': eskk#util#get_local_funcref('DataTable_add_from_dict', s:SID_PREFIX),
\       'add_map': eskk#util#get_local_funcref('DataTable_add_map', s:SID_PREFIX),
\   }
\)

" }}}

" s:DiffTable {{{

function! s:DiffTable_add_map(lhs, map, ...) dict "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    let self._data[a:lhs] = {'method': 'add', 'data': pair}
endfunction "}}}

function! s:DiffTable_remove_map(lhs) dict "{{{
    if has_key(self._data, a:lhs)
        unlet self._data[a:lhs]
    else
        " Assumpiton: It must be a lhs of bases.
        " One of base tables must have this lhs.
        " No way to check if this lhs is base one,
        " because .load() is called lazily
        " for saving memory.
        let self._data[a:lhs] = {'method': 'remove'}
    endif
endfunction "}}}

let s:DiffTable = extend(
\   deepcopy(s:AbstractTable),
\   {
\       'add_map': eskk#util#get_local_funcref('DiffTable_add_map', s:SID_PREFIX),
\       'remove_map': eskk#util#get_local_funcref('DiffTable_remove_map', s:SID_PREFIX),
\   }
\)

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

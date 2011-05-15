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
" Child Table:
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
    throw eskk#error#build_error(
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

let s:VICE_OPTIONS = {'generate_stub': 1, 'auto_clone_method': 1}

" s:TableObj {{{
let s:TableObj = vice#class('TableObj', s:SID_PREFIX, s:VICE_OPTIONS)

call s:TableObj.attribute('_name', '')
call s:TableObj.attribute('_data', {})
call s:TableObj.attribute('_cached_maps', {})
call s:TableObj.attribute('_cached_candidates', {})

" Constructor of s:ParentTable, s:ChildTable
function! eskk#table#new(table_name, ...) "{{{
    if a:0
        let obj = s:ChildTable.clone()
        let obj._name = a:table_name
        let obj._bases = []
        for base in type(a:1) == type([]) ? a:1 : [a:1]
            if type(base) == type("")
                " Assume it's installed table name.
                call add(obj._bases, eskk#table#new_from_file(base))
            elseif type(base) == type({})
                " Assume it's s:TableObj object.
                call add(obj._bases, base)
            else
                throw eskk#table#invalid_arguments_error(a:table_name)
            endif
        endfor
        call s:validate_base_tables(obj)
    else
        let obj = s:BaseTable.clone()
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
    return eskk#error#build_error(
    \   ['eskk', 'table'],
    \   ["table '" . a:table_name . "' derived from itself"]
    \)
endfunction "}}}
function! eskk#table#invalid_arguments_error(table_name) "{{{
    return eskk#error#build_error(
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

function! {s:TableObj.method('get_all_base_tables')}(this) "{{{
    let set = g:eskk#V.Data.OrderedSet.new()
    let table_stack = [a:this]
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
function! {s:TableObj.method('derived_from')}(this, base) "{{{
    for table in a:this.get_all_base_tables()
        if table ==# a:base
            return 1
        endif
    endfor
    return 0
endfunction "}}}

function! {s:TableObj.method('has_candidates')}(this, lhs_head) "{{{
    let not_found = {}
    return a:this.get_candidates(a:lhs_head, 1, not_found) isnot not_found
endfunction "}}}
function! {s:TableObj.method('has_n_candidates')}(this, lhs_head, n) "{{{
    " Has n candidates at least.
    let not_found = {}
    let c = a:this.get_candidates(a:lhs_head, a:n, not_found)
    return c isnot not_found && len(c) >= a:n
endfunction "}}}
function! {s:TableObj.method('get_candidates')}(this, lhs_head, max_candidates, ...) "{{{
    return call(
    \   's:get_candidates',
    \   [a:this, a:lhs_head, a:max_candidates] + a:000
    \)
endfunction "}}}
function! s:get_candidates(table, lhs_head, max_candidates, ...) "{{{
    let table_name = a:table._name
    call eskk#error#assert(
    \   a:max_candidates !=# 0,
    \   "a:max_candidates must be negative or positive."
    \)

    if g:eskk#cache_table_candidates
    \   && has_key(a:table._cached_candidates, a:lhs_head)
        let candidates = a:table._cached_candidates[a:lhs_head]
    else
        let candidates = filter(
        \   copy(a:table.load()), 'stridx(v:key, a:lhs_head) == 0'
        \)
        if g:eskk#cache_table_candidates
            let a:table._cached_candidates[a:lhs_head] = candidates
        endif
    endif

    if !empty(candidates)
        return candidates
    endif

    if a:table.is_child()
        " Search base tables.
        let not_found = {}
        for base in a:table._bases
            let r = s:get_candidates(
            \   base,
            \   a:lhs_head,
            \   a:max_candidates,
            \   not_found
            \)
            if r isnot not_found
                return r
            endif
        endfor
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

function! {s:TableObj.method('has_map')}(this, lhs) "{{{
    let not_found = {}
    return a:this.get_map(a:lhs, not_found) isnot not_found
endfunction "}}}
function! {s:TableObj.method('get_map')}(this, lhs, ...) "{{{
    return call(
    \   's:get_map',
    \   [a:this, a:lhs, s:MAP_INDEX] + a:000
    \)
endfunction "}}}
function! {s:TableObj.method('has_rest')}(this, lhs) "{{{
    let not_found = {}
    return a:this.get_rest(a:lhs, not_found) isnot not_found
endfunction "}}}
function! {s:TableObj.method('get_rest')}(this, lhs, ...) "{{{
    return call(
    \   's:get_map',
    \   [a:this, a:lhs, s:REST_INDEX] + a:000
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
        \   eskk#util#formatstrf(
        \       'table name = %s, lhs = %s, index = %d',
        \       a:table._name, a:lhs, a:index
        \   )
        \)
    endif
endfunction "}}}

function! {s:TableObj.method('load')}(this) "{{{
    if has_key(a:this, '_bases')
        " TODO: after initializing base tables,
        " this object has no need to have base references.
        " because they can ("should", curerntly) be
        " obtained from s:table_defs in autoload/eskk.vim
        " (it can be considered as flyweight object for all tables)
        for base in a:this._bases
            call s:do_initialize(base)
        endfor
    endif
    call s:do_initialize(a:this)
    return a:this._data
endfunction "}}}
function! s:TableObj_get_mappings() dict "{{{
    return self._data
endfunction "}}}
function! s:do_initialize(table) "{{{
    if has_key(a:table, 'initialize')
        call a:table.initialize()
        unlet a:table.initialize

        " TODO: You can't this if using vice.vim!
        " let a:table.load = eskk#util#get_local_func(
        " \                       'TableObj_get_mappings', s:SID_PREFIX)
    endif
endfunction "}}}

function! {s:TableObj.method('is_base')}(this) "{{{
    return !has_key(a:this, '_bases')
endfunction "}}}
function! {s:TableObj.method('is_child')}(this) "{{{
    return !a:this.is_base()
endfunction "}}}

function! {s:TableObj.method('get_name')}(this) "{{{
    return a:this._name
endfunction "}}}
function! {s:TableObj.method('get_base_tables')}(this) "{{{
    return a:this.is_child() ? a:this._bases : []
endfunction "}}}
" }}}

" s:BaseTable {{{
let s:BaseTable = vice#class('BaseTable', s:SID_PREFIX, s:VICE_OPTIONS)
call s:BaseTable.extends(s:TableObj)

function! {s:BaseTable.method('add_from_dict')}(this, dict) "{{{
    let a:this._data = a:dict
endfunction "}}}

function! {s:BaseTable.method('add_map')}(this, lhs, map, ...) "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    let a:this._data[a:lhs] = pair
endfunction "}}}
" }}}

" s:ChildTable {{{
let s:ChildTable = vice#class('ChildTable', s:SID_PREFIX, s:VICE_OPTIONS)
call s:ChildTable.extends(s:TableObj)

function! {s:ChildTable.method('add_map')}(this, lhs, map, ...) "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    let a:this._data[a:lhs] = {'method': 'add', 'data': pair}
endfunction "}}}

function! {s:ChildTable.method('remove_map')}(this, lhs) "{{{
    if has_key(a:this._data, a:lhs)
        unlet a:this._data[a:lhs]
    else
        " Assumpiton: It must be a lhs of bases.
        " One of base tables must have this lhs.
        " No way to check if this lhs is base one,
        " because .load() is called lazily
        " for saving memory.
        let a:this._data[a:lhs] = {'method': 'remove'}
    endif
endfunction "}}}
" }}}

" for memory, store object instead of object factory (class).
unlet s:TableObj
let s:BaseTable = s:BaseTable.new()
let s:ChildTable = s:ChildTable.new()


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

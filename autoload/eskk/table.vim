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

" s:table_obj {{{
let s:table_obj = {'_data': {}, '_cached_maps': {}, '_cached_candidates': {}}

function! eskk#table#new(table_name, ...) "{{{
    if a:0
        let obj = deepcopy(s:child_table)
        let obj._name = a:table_name
        let obj._bases = []
        for base in type(a:1) == type([]) ? a:1 : [a:1]
            if type(base) == type("")
                " Assume it's installed table name.
                call add(obj._bases, eskk#table#new_from_file(base))
            elseif type(base) == type({})
                " Assume it's s:table_obj object.
                call add(obj._bases, base)
            endif
        endfor
    else
        let obj = deepcopy(s:base_table)
        let obj._name = a:table_name
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
    \   [self, a:lhs_head, a:max_candidates] + a:000
    \)
endfunction "}}}
function! s:get_candidates(table, lhs_head, max_candidates, ...) "{{{
    let table_name = a:table._name
    call eskk#util#assert(
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

    if !a:table.is_base()
        " Search base tables.
        let not_found = {}
        let table_defs = eskk#_get_table_defs()
        for base in table_defs[table_name]._bases
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

function! s:table_obj.has_map(lhs) "{{{
    let not_found = {}
    return self.get_map(a:lhs, not_found) isnot not_found
endfunction "}}}
function! s:table_obj.get_map(lhs, ...) "{{{
    return call(
    \   's:get_map',
    \   [self, a:lhs, 0] + a:000
    \)
endfunction "}}}
function! s:table_obj.has_rest(lhs) "{{{
    let not_found = {}
    return self.get_rest(a:lhs, not_found) isnot not_found
endfunction "}}}
function! s:table_obj.get_rest(lhs, ...) "{{{
    return call(
    \   's:get_map',
    \   [self, a:lhs, 1] + a:000
    \)
endfunction "}}}
function! s:get_map(table, lhs, index, ...) "{{{
    let table_name = a:table._name
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
        if eskk#util#has_key_f(data, [a:lhs, a:index])
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

function! s:table_obj.load() "{{{
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
function! s:table_obj.get_mappings() "{{{
    return self._data
endfunction "}}}
function! s:do_initialize(table) "{{{
    if has_key(a:table, 'initialize')
        call a:table.initialize()
        unlet a:table.initialize
        let a:table.load = s:table_obj.get_mappings
    endif
endfunction "}}}

function! s:table_obj.is_base() "{{{
    return !has_key(self, '_bases')
endfunction "}}}

function! s:table_obj.get_name() "{{{
    return self._name
endfunction "}}}
function! s:table_obj.get_base_tables() "{{{
    return self.is_base() ? [] : self._bases
endfunction "}}}

" }}}

" s:base_table {{{
let s:base_table = deepcopy(s:table_obj)

function! s:base_table.add_from_dict(dict) "{{{
    let self._data = a:dict
endfunction "}}}

function! s:base_table.add_map(lhs, map, ...) "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    let self._data[a:lhs] = pair
endfunction "}}}
" }}}

" s:child_table {{{
let s:child_table = deepcopy(s:table_obj)

function! s:child_table.add_map(lhs, map, ...) "{{{
    let pair = [a:map, (a:0 ? a:1 : '')]
    let self._data[a:lhs] = {'method': 'add', 'data': pair}
endfunction "}}}

function! s:child_table.remove_map(lhs) "{{{
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

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

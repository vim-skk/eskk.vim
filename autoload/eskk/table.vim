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

" s:table_defs = {
"   'table_name': eskk#table#create(),
"   'table_name2': eskk#table#create(),
"   ...
" }
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
"       'lhs2': {'method': 'remove'},
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
let s:cached_maps = {}
let s:cached_candidates = {}

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
    call eskk#util#logf("Loading table %s...", a:table_name)

    if has_key(def, 'bases')
        call eskk#util#logf("table %s is derived table. Let's load base tables...", a:table_name)
        for base in def.bases
            call s:load_table(base.name)
        endfor
    endif

    if has_key(def, 'init')
        call def.init()
    endif

    let def._loaded = 1
    call eskk#util#logf('table %s has been loaded.', a:table_name)
endfunction "}}}

function! s:get_table_data(table_name, ...) "{{{
    if s:table_defs[a:table_name]._loaded
        return s:table_defs[a:table_name].data
    endif

    " Lazy loading.
    if !s:table_defs[a:table_name]._loaded
        call s:load_table(a:table_name)
    endif
    return s:table_defs[a:table_name].data
endfunction "}}}

function! s:has_table(table_name) "{{{
    if !s:table_defs[a:table_name]._loaded
        call s:load_table(a:table_name)
    endif
    return has_key(s:table_defs, a:table_name)
endfunction "}}}

function! s:is_base_table(table_name) "{{{
    if !s:table_defs[a:table_name]._loaded
        call s:load_table(a:table_name)
    endif
    return !has_key(s:table_defs[a:table_name], 'bases')
endfunction "}}}

function! s:get_map(table_name, lhs, index, ...) "{{{
    let data = s:get_table_data(a:table_name)

    if g:eskk_cache_table_map && eskk#util#has_key_f(s:cached_maps, [a:table_name, a:lhs])
        if s:cached_maps[a:table_name][a:lhs][a:index] != ''
            return s:cached_maps[a:table_name][a:lhs][a:index]
        else
            " No lhs in `s:table_defs`.
            if a:0
                return a:1
            else
                throw eskk#internal_error(['eskk', 'table'])
            endif
        endif
    endif

    if s:is_base_table(a:table_name)
        call eskk#util#logf('table %s is base table.', a:table_name)

        if eskk#util#has_key_f(data, [a:lhs, a:index])
        \   && data[a:lhs][a:index] != ''
            call eskk#util#logstrf('found %s: %s', a:lhs, data[a:lhs])
            if g:eskk_cache_table_map
                call eskk#util#let_f(s:cached_maps, [a:table_name, a:lhs], data[a:lhs])
            endif
            return data[a:lhs][a:index]
        endif
    else
        call eskk#util#logf('table %s is derived table.', a:table_name)

        if has_key(data, a:lhs)
            call eskk#util#logstrf('found %s: %s', a:lhs, data[a:lhs])

            if data[a:lhs].method ==# 'add' && data[a:lhs].data[a:index] != ''
                if g:eskk_cache_table_map
                    call eskk#util#let_f(s:cached_maps, [a:table_name, a:lhs], data[a:lhs].data)
                endif
                return data[a:lhs].data[a:index]
            elseif data[a:lhs].method ==# 'remove'
                " No lhs in `s:table_defs`.
                if a:0
                    return a:1
                else
                    throw eskk#internal_error(['eskk', 'table'])
                endif
            endif
        endif

        let not_found = {}
        for parent in s:table_defs[a:table_name].bases
            let r = s:get_map(parent.name, a:lhs, a:index, not_found)
            if r isnot not_found
                return r
            endif
        endfor
    endif

    " No lhs in `s:table_defs`.
    if a:0
        return a:1
    else
        let msg = eskk#util#printstrf('table name = %s, lhs = %s, index = %d', a:table_name, a:lhs, a:index)
        throw eskk#internal_error(['eskk', 'table'], msg)
    endif
endfunction "}}}

function! s:get_candidates(table_name, lhs_head, max_candidates, ...) "{{{
    call eskk#util#assert(a:max_candidates !=# 0, "a:max_candidates must be negative or positive.")

    if g:eskk_cache_table_candidates && eskk#util#has_key_f(s:cached_candidates, [a:table_name, a:lhs_head])
        let candidates = s:cached_candidates[a:table_name][a:lhs_head]
    else
        let data = s:get_table_data(a:table_name)
        let candidates = filter(copy(data), 'stridx(v:key, a:lhs_head) == 0')
        if g:eskk_cache_table_candidates
            call eskk#util#let_f(s:cached_candidates, [a:table_name, a:lhs_head], candidates)
        endif
    endif

    if !empty(candidates)
        call eskk#util#logstrf('found %s: %s', a:lhs_head, candidates)
        return candidates
    endif

    if !s:is_base_table(a:table_name)
        " Search parent tables.
        let not_found = {}
        for parent in s:table_defs[a:table_name].bases
            let r = s:get_candidates(parent.name, a:lhs_head, a:max_candidates, not_found)
            if r isnot not_found
                return r
            endif
        endfor
    endif

    " No lhs_head in `s:table_defs`.
    if a:0
        return a:1
    else
        throw eskk#internal_error(['eskk', 'table'])
    endif
endfunction "}}}

" }}}


" s:register_skeleton {{{
let s:register_skeleton = {'data': {}, '_loaded': 0}

function! eskk#table#create(name, ...) "{{{
    call eskk#util#logf('created table %s', a:name)
    let obj = deepcopy(s:register_skeleton, 1)
    let obj.name = a:name
    if a:0
        let names = type(a:1) == type([]) ? a:1 : [a:1]
        call eskk#util#logstrf('created table %s: base tables are %s', a:name, names)
        let obj.bases = map(names, 'eskk#table#create(v:val)')
    endif
    return obj
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
        throw eskk#user_error(['eskk', 'table'], "Must not remove base class map.")
    else
        let self.data[a:lhs] = {'method': 'remove'}
    endif
    return self
endfunction "}}}

function! s:register_skeleton.add_from_dict(dict) "{{{
    let self.data = a:dict
    return self
endfunction "}}}

function! s:register_skeleton.register() "{{{
    if has_key(s:table_defs, self.name)
        " Do not allow override table.
        "
        let msg = printf("'%s' has been already registered.", self.name)
        " throw eskk#internal_error(['eskk', 'table'], msg)
        call eskk#util#log_warn(msg)
        return
    endif

    call eskk#util#logf('Register table %s.', self.name)
    let s:table_defs[self.name] = self
    return self
endfunction "}}}

lockvar s:register_skeleton
" }}}


" Autoload functions {{{

function! eskk#table#get_all_tables() "{{{
    return map(eskk#util#globpath('autoload/eskk/table/*.vim'), 'fnamemodify(v:val, ":t:r")')
endfunction "}}}

function! eskk#table#get_all_registered_tables() "{{{
    return keys(s:table_defs)
endfunction "}}}

function! eskk#table#has_table(table_name) "{{{
    return has_key(s:table_defs, a:table_name)
endfunction "}}}

" }}}

" s:table_obj {{{
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


function! s:table_obj.has_candidates(lhs_head) "{{{
    let not_found = {}
    return self.get_candidates(a:lhs_head, 1, not_found) isnot not_found
endfunction "}}}

function! s:table_obj.get_candidates(lhs_head, max_candidates, ...) "{{{
    return call('s:get_candidates', [self.table_name, a:lhs_head, a:max_candidates] + a:000)
endfunction "}}}

function! s:table_obj.has_map(lhs) "{{{
    let not_found = {}
    return self.get_map(a:lhs, not_found) isnot not_found
endfunction "}}}

function! s:table_obj.get_map(lhs, ...) "{{{
    return call('s:get_map', [self.table_name, a:lhs, s:MAP_TO_INDEX] + a:000)
endfunction "}}}

function! s:table_obj.has_rest(lhs) "{{{
    let not_found = {}
    return self.get_rest(a:lhs, not_found) isnot not_found
endfunction "}}}

function! s:table_obj.get_rest(lhs, ...) "{{{
    return call('s:get_map', [self.table_name, a:lhs, s:REST_INDEX] + a:000)
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

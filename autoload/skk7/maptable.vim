" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Scope Variables {{{
" }}}
" Global Variables {{{
if !exists('g:maptable_debug')
    let g:maptable_debug = 0
endif
" }}}


" TODO
" - Check if mode is supported.

" Functions {{{

func! skk7#maptable#new()
    return deepcopy(s:maptable)
endfunc


let s:maptable = {'table': {}}

" Map key.
func! s:maptable.map(lhs, rhs, local_mode, force) dict "{{{
    let evaled_lhs = skk7#util#eval_key(a:lhs)
    let evaled_rhs = skk7#util#eval_key(a:rhs)
    if !has_key(self.table, evaled_lhs)
        let self.table[evaled_lhs] = {}
    endif
    let t = self.table[evaled_lhs]

    let opt = a:force ? 'force' : 'keep'
    if a:local_mode == ''
        " Create non-local mapping.
        call extend(
        \   t,
        \   s:create_key(evaled_rhs, a:rhs),
        \   opt
        \)
    else
        " Create mode local mapping.
        if !has_key(t, 'local')
            let t.local = {}
        endif
        if !has_key(t.local, a:local_mode)
            let t.local[a:local_mode] = {}
        endif

        call extend(
        \   t.local[a:local_mode],
        \   s:create_key(evaled_rhs, a:rhs),
        \   opt
        \)
    endif

    " non-evaled rhs.
    return a:rhs
endfunc "}}}

func! s:maptable.unmap(lhs, local_mode) dict "{{{
    let evaled_lhs = skk7#util#eval_key(a:lhs)

    if !self.hasmapof(a:lhs, a:local_mode)
        " TODO Message?
        return
    endif
    if a:local_mode != ''
    \   && !skk7#util#has_key_f(self.table[evaled_lhs], ['local', a:local_mode])
        " TODO Message?
        return
    endif

    call s:destroy_key(self.table, evaled_lhs, a:local_mode)
endfunc "}}}

func! s:maptable.mapclear(local_mode) dict "{{{
    if a:local_mode == ''
        " FIXME This delete also local mappings
        let self.table = {}
    else
        " Delete all mode local mappings.
        " FIXME This delete also non-local mappings
        let self.table = s:filter_table(
        \   self.table,
        \   '! has_key(val, "local")'
        \)
    endif
endfunc "}}}

func! s:maptable.maparg(lhs, local_mode) dict "{{{
    if !self.hasmapof(a:lhs, a:local_mode)
        return ''
    endif
    let evaled_lhs = skk7#util#eval_key(a:lhs)

    if a:local_mode == ''
        return get(self.table[evaled_lhs], 'map_to', '')
    else
        return skk7#util#get_f(self.table[evaled_lhs], ['local', a:local_mode, 'map_to'], '')
    endif
endfunc "}}}

" NOTE: Return value is List not Str.
func! s:maptable.mapcheck(lhs, local_mode) dict "{{{
    let maparg = self.maparg(a:lhs, a:local_mode)
    if maparg != ''
        return [maparg]
    endif

    let evaled_lhs = skk7#util#eval_key(a:lhs)
    return map(
    \   s:filter_table(
    \       self.table,
    \       skk7#util#bind(
    \           'has_key(val, "map_to")' .
    \           ' && strpart(key, 0, strlen(%1%)) ==# %1%',
    \           evaled_lhs
    \       ),
    \       1
    \   ),
    \   'v:val.map_to'
    \)
endfunc "}}}

func! s:maptable.hasmapof(lhs, local_mode) dict "{{{
    let evaled_lhs = skk7#util#eval_key(a:lhs)

    if a:local_mode == ''
        return skk7#util#has_key_f(self.table, [evaled_lhs, 'map_to'])
    else
        return skk7#util#has_key_f(self.table, [evaled_lhs, 'local', a:local_mode, 'map_to'])
    endif
endfunc "}}}

func! s:maptable.hasmapto(rhs, local_mode) dict "{{{
    " TODO
endfunc "}}}



func! s:filter_table(table, expr, sort_p) "{{{
    let ret = []
    for key in a:sort_p ? sort(keys(a:table)) : keys(a:table)
        let val = a:table[key]
        if eval(a:expr)
            call add(ret, val)
        endif
    endfor
    return ret
endfunc "}}}

" Create map structure.
func! s:create_key(rhs, raw_rhs) "{{{
    return {
    \   'evaled_map_to': a:rhs,
    \   'map_to': a:raw_rhs
    \}
endfunc "}}}

func! s:destroy_key(table, evaled_lhs, local_mode) "{{{
    let t = a:table[a:evaled_lhs]
    if a:local_mode == ''
        " Destroy non-local mapping.
        unlet! t.map_to t.evaled_map_to
    else
        " Destroy local mapping.
        unlet! t.local[a:local_mode]
    endif
endfunc "}}}


lockvar s:maptable

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

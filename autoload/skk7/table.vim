" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:current_table_name = ''


" Functions {{{

func! s:parse_qarg(qarg) "{{{
    " TODO
endfunc "}}}

func! s:table_varname()
    return printf('g:skk7#table#%s#definition', s:current_table_name)
endfunc



func! skk7#table#define_macro() "{{{
    command! -buffer -nargs=1 Skk7Table     call s:cmd_table(<f-args>)
    command! -buffer -nargs=+ Skk7TableMap  call s:cmd_table_map(<q-args>)
endfunc "}}}

func! s:cmd_table(arg) "{{{
    return skk7#table#table_name(a:arg)
endfunc

func! s:cmd_table_map(qarg) "{{{
    let [type, lhs, rhs] = s:parse_qarg(a:qarg)
    return skk7#table#map(type, lhs, rhs)
endfunc "}}}

func! skk7#table#table_name(name) "{{{
    let s:current_table_name = a:name
    let varname = s:table_varname()
    if !exists(varname)
        let {varname} = {}
    endif
endfunc "}}}

" Force overwrite if a:bang is true.
func! skk7#table#map(lhs, rhs, ...) "{{{
    let [bang, rest] = skk7#util#get_args(a:000, 0, '')

    if s:current_table_name == '' | return | endif
    let def = {s:table_varname()}

    " a:lhs is already defined and not banged.
    if has_key(def, a:lhs) && !a:bang
        return
    endif
    let def[a:lhs] = {'map_to': a:rhs}

    if rest != ''
        let def[a:lhs].rest = rest
    endif
endfunc "}}}

func! skk7#table#unmap(lhs) "{{{
    if s:current_table_name == '' | return | endif
    unlet {s:table_varname()}[a:lhs]
endfunc "}}}


" TODO
" Current implementation is smart but heavy.
" Make table like this?
" 's': {
"   'a': {'kana': 'さ'},
"
"   .
"   .
"   .
"
"   'y': {'a': {'kana': 'しゃ'}}
" }
" But this uses a lot of memory.
"
func! skk7#table#has_candidates(definition, str) "{{{
    let regex = '^' . a:str
    return !empty(filter(keys(a:definition), 'v:val =~# regex'))
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

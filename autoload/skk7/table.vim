" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:current_table_name = ''


" Functions {{{

func! s:skip_spaces(str) "{{{
    return substitute(a:str, '^\s*', '', '')
endfunc "}}}

" TODO Escape + Whitespace
func! s:get_arg(arg) "{{{
    let matched = matchstr(a:arg, '^\S\+')
    return [matched, strpart(a:arg, strlen(matched))]
endfunc "}}}

func! s:unget_arg(arg, str) "{{{
    return a:str . a:arg
endfunc

func! s:parse_arg(arg) "{{{
    let arg = a:arg
    let opt_regex = '-\(\w\+\)=\(\S\+\)'

    " Parse options.
    let opt = {}
    while arg != ''
        let arg = s:skip_spaces(arg)
        let [a, arg] = s:get_arg(arg)

        let m = matchlist(a, opt_regex)
        if !empty(m)
            " a is option.
            let [opt_name, opt_value] = m[1:2]
            if opt_name ==# 'rest'
                let opt.rest = opt_value
            else
                throw printf("skk7: Skk7TableMap: unknown '%s' option.", opt_name)
            endif
        else
            let arg = s:unget_arg(arg, a)
            break
        endif
    endwhile

    " Parse arguments.
    let lhs_rhs = []
    while arg != ''
        let arg = s:skip_spaces(arg)
        let [a, arg] = s:get_arg(arg)
        call add(lhs_rhs, a)
    endwhile
    if len(lhs_rhs) != 2
        call skk7#util#logf('lhs_rhs = %s', string(lhs_rhs))
        throw 'skk7: Skk7TableMap [-rest=...] lhs rhs'
    endif

    return lhs_rhs + [get(opt, 'rest', '')]
endfunc "}}}

func! s:table_varname()
    return printf('g:skk7#table#%s#definition', s:current_table_name)
endfunc



func! skk7#table#define_macro() "{{{
    command!
    \   -buffer -nargs=1
    \   Skk7Table
    \   call s:cmd_table(<f-args>)
    command!
    \   -buffer -nargs=+ -bang
    \   Skk7TableMap
    \   call s:cmd_table_map(<q-args>, "<bang>")
endfunc "}}}

func! s:cmd_table(arg) "{{{
    return skk7#table#table_name(a:arg)
endfunc

func! s:cmd_table_map(arg, bang) "{{{
    try
        let [lhs, rhs, rest] = s:parse_arg(a:arg)
        return call('skk7#table#map', [lhs, rhs, (a:bang != '' ? 1 : 0), rest])
    catch /^skk7:/
        echoerr v:exception
    endtry
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
    if has_key(def, a:lhs) && !bang
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

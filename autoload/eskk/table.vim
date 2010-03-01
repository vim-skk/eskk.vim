" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:current_table_name = ''

" TODO
" - Build table in Vim <SID> mapping table.

" Functions {{{

func! s:parse_arg(arg) "{{{
    let arg = a:arg
    let opt_regex = '-\(\w\+\)=\(\S\+\)'

    " Parse options.
    let opt = {}
    while arg != ''
        let arg = eskk#util#skip_spaces(arg)
        let [a, arg] = eskk#util#get_arg(arg)

        let m = matchlist(a, opt_regex)
        if !empty(m)
            " a is option.
            let [opt_name, opt_value] = m[1:2]
            if opt_name ==# 'rest'
                let opt.rest = opt_value
            else
                throw printf("eskk: EskkTableMap: unknown option '%s'.", opt_name)
            endif
        else
            let arg = eskk#util#unget_arg(arg, a)
            break
        endif
    endwhile

    " Parse arguments.
    let lhs_rhs = []
    while arg != ''
        let arg = eskk#util#skip_spaces(arg)
        let [a, arg] = eskk#util#get_arg(arg)
        call add(lhs_rhs, a)
    endwhile
    if len(lhs_rhs) != 2
        call eskk#util#logf('lhs_rhs = %s', string(lhs_rhs))
        throw 'eskk: EskkTableMap [-rest=...] lhs rhs'
    endif

    return lhs_rhs + [get(opt, 'rest', '')]
endfunc "}}}

func! s:table_varname() "{{{
    return printf('g:eskk#table#%s#definition', s:current_table_name)
endfunc "}}}



func! eskk#table#define_macro() "{{{
    command!
    \   -buffer -nargs=1
    \   EskkTableBegin
    \   call s:cmd_table_begin(<f-args>)
    command!
    \   -buffer
    \   EskkTableEnd
    \   call s:cmd_table_end()
    command!
    \   -buffer -nargs=+ -bang
    \   EskkTableMap
    \   call s:cmd_table_map(<q-args>, "<bang>")
endfunc "}}}

func! s:cmd_table_begin(arg) "{{{
    return eskk#table#table_name(a:arg)
endfunc "}}}

func! s:cmd_table_end() "{{{
    lockvar {s:table_varname()}
endfunc "}}}

func! s:cmd_table_map(arg, bang) "{{{
    try
        let [lhs, rhs, rest] = s:parse_arg(a:arg)
        return call('eskk#table#map', [lhs, rhs, (a:bang != '' ? 1 : 0), rest])
    catch /^eskk:/
        call eskk#util#warn(v:exception)
    endtry
endfunc "}}}

func! eskk#table#table_name(name) "{{{
    let s:current_table_name = a:name
    let varname = s:table_varname()
    if !exists(varname)
        let {varname} = {}
    endif
endfunc "}}}

" Force overwrite if a:bang is true.
func! eskk#table#map(lhs, rhs, ...) "{{{
    let [bang, rest] = eskk#util#get_args(a:000, 0, '')

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

func! eskk#table#unmap(lhs) "{{{
    if s:current_table_name == '' | return | endif
    unlet {s:table_varname()}[a:lhs]
endfunc "}}}


" TODO
" Current implementation is smart but heavy.
" Make table like this?
" 's': {
"   'a': {'map_to': 'さ'},
"
"   .
"   .
"   .
"
"   'y': {'a': {'map_to': 'しゃ'}}
" }
" But this uses a lot of memory.
"
func! eskk#table#has_candidates(...) "{{{
    return !empty(call('eskk#table#get_candidates', a:000))
endfunc "}}}

func! eskk#table#get_candidates(table_name, str_buf) "{{{
    if empty(a:str_buf)
        throw eskk#error#internal_error('eskk: table:')
    endif

    let def = {s:table_varname()}
    return !empty(
    \   filter(
    \       keys(def),
    \       'stridx(v:val, a:str_buf) == 0'
    \   )
    \)
endfunc "}}}


func! eskk#table#has_map(table_name, lhs) "{{{
    let def = eskk#table#{a:table_name}#get_definition()
    return has_key(def, a:lhs)
endfunc "}}}


func! eskk#table#get_map_to(table_name, lhs, ...) "{{{
    if !eskk#table#has_map(a:table_name, a:lhs)
        if a:0 == 0
            throw eskk#error#argument_error('eskk: table:')
        else
            return a:1
        endif
    endif
    let def = eskk#table#{a:table_name}#get_definition()
    return def[a:lhs].map_to
endfunc "}}}


func! eskk#table#has_rest(table_name, lhs) "{{{
    let def = eskk#table#{a:table_name}#get_definition()

    return has_key(def, a:lhs)
    \   && has_key(def[a:lhs], 'rest')
endfunc "}}}

func! eskk#table#get_rest(table_name, lhs, ...) "{{{
    if !eskk#table#has_rest(a:table_name, a:lhs)
        if a:0 == 0
            throw eskk#error#argument_error('eskk: table:')
        else
            return a:1
        endif
    endif
    let def = eskk#table#{a:table_name}#get_definition()
    return def[a:lhs].rest
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

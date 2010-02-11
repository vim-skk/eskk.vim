" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Functions {{{

func! skk7#util#warn(msg) "{{{
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunc "}}}

func! skk7#util#warnf(msg, ...) "{{{
    call skk7#util#warn(call('printf', [a:msg] + a:000))
endfunc "}}}

func! skk7#util#log(...) "{{{
    if g:skk7_debug
        return call('skk7#debug#log', a:000)
    endif
endfunc "}}}

func! skk7#util#logf(...) "{{{
    if g:skk7_debug
        return call('skk7#debug#logf', a:000)
    endif
endfunc "}}}

func! skk7#util#internal_error(...) "{{{
    if a:0 == 0
        throw 'skk7: util: sorry, internal error.'
    else
        throw 'skk7: util: sorry, internal error: ' . a:1
    endif
endfunc "}}}


func! skk7#util#mb_strlen(str) "{{{
    return strlen(substitute(copy(a:str), '.', 'x', 'g'))
endfunc "}}}

func! skk7#util#mb_chop(str) "{{{
    return substitute(a:str, '.$', '', '')
endfunc "}}}


func! skk7#util#get_args(args, ...) "{{{
    let ret_args = []
    let i = 0

    while i < len(a:000)
        call add(
        \   ret_args,
        \   skk7#util#has_idx(a:args, i) ?
        \       a:args[i]
        \       : a:000[i]
        \)
        let i += 1
    endwhile

    return ret_args
endfunc "}}}


func! skk7#util#has_idx(list, idx) "{{{
    let idx = a:idx >= 0 ? a:idx : len(a:list) + a:idx
    return 0 <= idx && idx < len(a:list)
endfunc "}}}


" a:func is string.
"
" NOTE: This returns 0 for script local function.
func! skk7#util#is_callable(Fn) "{{{
    return type(a:Fn) == type(function('tr'))
    \   || exists('*' . a:Fn)
endfunc "}}}

" arg 3 is not for 'self'.
func! skk7#util#call_if_exists(Fn, args, ...) "{{{
    if skk7#util#is_callable(a:Fn)
        return call(a:Fn, a:args)
    elseif a:0 != 0
        return a:1
    else
        throw printf("skk7: no such function '%s'.", a:Fn)
    endif
endfunc "}}}


" For macro. {{{

func! skk7#util#skip_spaces(str) "{{{
    return substitute(a:str, '^\s*', '', '')
endfunc "}}}

" TODO Escape + Whitespace
func! skk7#util#get_arg(arg) "{{{
    let matched = matchstr(a:arg, '^\S\+')
    return [matched, strpart(a:arg, strlen(matched))]
endfunc "}}}

func! skk7#util#unget_arg(arg, str) "{{{
    return a:str . a:arg
endfunc "}}}

" }}}


func! s:split_key(key) "{{{
    let head = matchstr(a:key, '^[^<]\+')
    return [head, strpart(a:key, strlen(head))]
endfunc "}}}

func! s:split_special_key(key) "{{{
    let head = matchstr(a:key, '^<[^>]\+>')
    return [head, strpart(a:key, strlen(head))]
endfunc "}}}

" TODO Rename to unescape_key()?
func! skk7#util#eval_key(key) "{{{
    let key = a:key
    let evaled = ''
    while 1
        let [left, key] = s:split_key(key)
        let evaled .= left
        if key == ''
            return evaled
        elseif key[0] ==# '<' && key[1] ==# '>'
            " '<>'
            let evaled .= strpart(key, 0, 2)
            let key = strpart(key, 2)
        elseif key[0] ==# '<' && key =~# '^<[^>]*$'
            " No '>'
            return evaled . key
        elseif tolower(key) =~# '^<lt>'
            " '<lt>' -> '<'
            let evaled .= '<'
            let key = strpart(key, strlen('<lt>'))
        elseif key[0] ==# '<'
            " Special key.
            let [sp_key, key] = s:split_special_key(key)
            let evaled .= eval(printf('"\%s"', sp_key))
        else
            call skk7#util#internal_error()
        endif
    endwhile
endfunc "}}}


" Boost.Format-like function.
" This is useful for embedding values in string.
func! skk7#util#bind(fmt, ...) "{{{
    let ret = a:fmt
    for i in range(len(a:000))
        let regex = '%' . (i + 1) . '%'
        let ret = substitute(ret, regex, string(a:000[i]), 'g')
    endfor
    return ret
endfunc "}}}


func! skk7#util#get_f(...) "{{{
    return call('s:follow', [0] + a:000)
endfunc "}}}

func! skk7#util#has_key_f(...) "{{{
    return call('s:follow', [1] + a:000)
endfunc "}}}

" Built-in 'get()' like function.
" But 3 arg is omitted, this throws an exception.
"
" This allows both Dictionary and List as a:dict.
" And if a:ret_bool is true:
"   Return boolean value(existence of key).
" And if a:ret_bool is false:
"   Raise an exception or return value if it exists.
func! s:follow(ret_bool, dict, follow, ...) "{{{
    if empty(a:follow)
        call skk7#util#internal_error()
    endif

    if a:0 == 0
        if type(a:dict) == type([])
            if !skk7#util#has_idx(a:dict, a:follow[0])
                if a:ret_bool
                    return 0
                else
                    call skk7#util#internal_error()
                endif
            endif
        elseif type(a:dict) == type({})
            if !has_key(a:dict, a:follow[0])
                if a:ret_bool
                    return 0
                else
                    call skk7#util#internal_error()
                endif
            endif
        else
            call skk7#util#internal_error()
        endif
        let got = get(a:dict, a:follow[0])
    else
        let got = get(a:dict, a:follow[0], a:1)
    endif

    if len(a:follow) == 1
        return a:ret_bool ? 1 : got
    else
        return call('s:follow', [a:ret_bool, got, remove(a:follow, 1, -1)] + a:000)
    endif
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

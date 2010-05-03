" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Functions {{{
function! eskk#util#warn(msg) "{{{
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction "}}}
function! eskk#util#warnf(msg, ...) "{{{
    call eskk#util#warn(call('printf', [a:msg] + a:000))
endfunction "}}}
function! eskk#util#log(...) "{{{
    if g:eskk_debug
        return call('eskk#debug#log', a:000)
    endif
endfunction "}}}
function! eskk#util#logf(...) "{{{
    if g:eskk_debug
        return call('eskk#debug#logf', a:000)
    endif
endfunction "}}}

function! eskk#util#mb_strlen(str) "{{{
    return strlen(substitute(copy(a:str), '.', 'x', 'g'))
endfunction "}}}
function! eskk#util#mb_chop(str) "{{{
    return substitute(a:str, '.$', '', '')
endfunction "}}}

function! eskk#util#get_args(args, ...) "{{{
    let ret_args = []
    let i = 0

    while i < len(a:000)
        call add(
        \   ret_args,
        \   eskk#util#has_idx(a:args, i) ?
        \       a:args[i]
        \       : a:000[i]
        \)
        let i += 1
    endwhile

    return ret_args
endfunction "}}}

function! eskk#util#has_idx(list, idx) "{{{
    let idx = a:idx >= 0 ? a:idx : len(a:list) + a:idx
    return 0 <= idx && idx < len(a:list)
endfunction "}}}

" a:func is string.
"
" NOTE: This returns 0 for script local function.
function! eskk#util#is_callable(Fn) "{{{
    return type(a:Fn) == type(function('tr'))
    \   || exists('*' . a:Fn)
endfunction "}}}

" arg 3 is not for 'self'.
function! eskk#util#call_if_exists(Fn, args, ...) "{{{
    if eskk#util#is_callable(a:Fn)
        return call(a:Fn, a:args)
    elseif a:0 != 0
        return a:1
    else
        throw printf("eskk: no such function '%s'.", a:Fn)
    endif
endfunction "}}}

function! eskk#util#skip_spaces(str) "{{{
    return substitute(a:str, '^\s*', '', '')
endfunction "}}}
" TODO Escape + Whitespace
function! eskk#util#get_arg(arg) "{{{
    let matched = matchstr(a:arg, '^\S\+')
    return [matched, strpart(a:arg, strlen(matched))]
endfunction "}}}
function! eskk#util#unget_arg(arg, str) "{{{
    return a:str . a:arg
endfunction "}}}

function! s:split_key(key) "{{{
    let head = matchstr(a:key, '^[^<]\+')
    return [head, strpart(a:key, strlen(head))]
endfunction "}}}
function! s:split_special_key(key) "{{{
    let head = matchstr(a:key, '^<[^>]\+>')
    return [head, strpart(a:key, strlen(head))]
endfunction "}}}
function! eskk#util#eval_key(key) "{{{
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
        elseif key[0] ==# '<'
            " Special key.
            let [sp_key, key] = s:split_special_key(key)
            let evaled .= eval(printf('"\%s"', sp_key))
        else
            throw eskk#error#internal_error('eskk: util:')
        endif
    endwhile
    throw eskk#error#never_reached('eskk: util:')
endfunction "}}}

" Boost.Format-like function.
" This is useful for embedding values in string.
function! eskk#util#bind(fmt, ...) "{{{
    let ret = a:fmt
    for i in range(len(a:000))
        let regex = '%' . (i + 1) . '%'
        let ret = substitute(ret, regex, string(a:000[i]), 'g')
    endfor
    return ret
endfunction "}}}
function! eskk#util#stringf(fmt, ...) "{{{
    return call('printf', [a:fmt] + map(copy(a:000), 'string(v:val)'))
endfunction "}}}

function! eskk#util#get_f(...) "{{{
    return call('s:follow', [0] + a:000)
endfunction "}}}
function! eskk#util#has_key_f(...) "{{{
    return call('s:follow', [1] + a:000)
endfunction "}}}

" Built-in 'get()' like function.
" But 3 arg is omitted, this throws an exception.
"
" This allows both Dictionary and List as a:dict.
" And if a:ret_bool is true:
"   Return boolean value(existence of key).
" And if a:ret_bool is false:
"   Raise an exception or return value if it exists.
function! s:follow(ret_bool, dict, follow, ...) "{{{
    if empty(a:follow)
        throw eskk#error#internal_error('eskk: util:')
    endif

    if a:0 == 0
        if type(a:dict) == type([])
            if !eskk#util#has_idx(a:dict, a:follow[0])
                if a:ret_bool
                    return 0
                else
                    throw eskk#error#internal_error('eskk: util:')
                endif
            endif
        elseif type(a:dict) == type({})
            if !has_key(a:dict, a:follow[0])
                if a:ret_bool
                    return 0
                else
                    throw eskk#error#internal_error('eskk: util:')
                endif
            endif
        else
            throw eskk#error#internal_error('eskk: util:')
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
endfunction "}}}

function! eskk#util#zip(list1, list2) "{{{
    let ret = []
    let i = 0
    while 1
        let list1_has_idx = eskk#util#has_idx(a:list1, i)
        let list2_has_idx = eskk#util#has_idx(a:list2, i)
        if !list1_has_idx && !list2_has_idx
            return ret
        else
            call add(
            \   ret,
            \   (list1_has_idx ? [a:list1[i]] : [])
            \       + (list2_has_idx ? [a:list2[i]] : [])
            \)
        endif
        let i += 1
    endwhile

    call eskk#error#internal_error('eskk: util:', 'this block will be never reached')
endfunction "}}}

function! eskk#util#make_bs(n) "{{{
    return repeat("\<BS>", a:n)
endfunction "}}}

function! eskk#util#assert(cond, ...) "{{{
    if !a:cond
        throw call('eskk#error#assertion_failure', ['eskk: util:'] + a:000)
    endif
endfunction "}}}

" NOTE: Return value may be Funcref.
function! eskk#util#get_local_func(funcname, sid) "{{{
    " :help <SID>
    return printf('<SNR>%d_%s', a:sid, a:funcname)
endfunction "}}}

function! eskk#util#setbufline(expr, lnum, line) "{{{
    return eskk#util#call_on_buffer(a:expr, 'setline', [a:lnum, a:line])
endfunction "}}}

function! eskk#util#call_on_buffer(expr, Fn, args) "{{{
    let [cur_bufnr, to_bufnr] = [bufnr('%'), bufnr(a:expr)]
    let [cur_bufhidden, to_bufhidden] = [getbufvar('%', '&bufhidden'), getbufvar(to_bufnr, '&bufhidden')]
    call setbufvar('%', '&bufhidden', 'hide')
    call setbufvar(to_bufnr, '&bufhidden', 'hide')
    try
        if cur_bufnr != to_bufnr
            execute to_bufnr . 'buffer'
        endif
        return call(a:Fn, a:args)
    finally
        execute cur_bufnr . 'buffer'
        call setbufvar('%', '&bufhidden', cur_bufhidden)
        call setbufvar(to_bufnr, '&bufhidden', to_bufhidden)
    endtry
endfunction "}}}


function! eskk#util#parse_map(line) "{{{
    let m = matchlist(a:line, '^\([nvoiclxs]\)\s\+\(\S\+\)\s\+\(\*\)\(@\)\(\S\+\)$')
    if empty(m)
        throw eskk#error#parse_error('eskk: map', "Can't parse :map output")
    endif
    let [mode, lhs, noremap, buffer, rhs] = m[1:]
    return {
    \   'mode': mode,
    \   'lhs': lhs,
    \   'noremap': noremap ==# '*',
    \   'buffer': buffer ==# '@',
    \   'rhs': rhs,
    \}
endfunction "}}}
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

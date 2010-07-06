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


" Functions {{{
function! eskk#util#warn(msg) "{{{
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction "}}}
function! eskk#util#warnf(msg, ...) "{{{
    call eskk#util#warn(call('printf', [a:msg] + a:000))
endfunction "}}}
function! eskk#util#log(msg) "{{{
    if !g:eskk_debug
        return
    endif

    redraw

    if exists('g:eskk_debug_file')
        let file = expand(g:eskk_debug_file)
        execute 'redir >>' file
        silent echo a:msg
        redir END
    else
        call eskk#util#warn(a:msg)
    endif

    if g:eskk_debug_wait_ms !=# 0
        execute printf('sleep %dm', g:eskk_debug_wait_ms)
    endif
endfunction "}}}
function! eskk#util#logf(fmt, ...) "{{{
    call eskk#util#log(call('printf', [a:fmt] + a:000))
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
    " Return true when negative idx.
    " let idx = a:idx >= 0 ? a:idx : len(a:list) + a:idx
    let idx = a:idx
    return 0 <= idx && idx < len(a:list)
endfunction "}}}

function! eskk#util#has_elem(list, elem) "{{{
    for Value in a:list
        if Value ==# a:elem
            return 1
        endif
    endfor
    return 0
endfunction "}}}

" a:func is string.

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
function! eskk#util#key2char(key) "{{{
    " From arpeggio.vim

    let keys = s:split_to_keys(a:key)
    call map(keys, 'v:val =~ "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val')
    return join(keys, '')
endfunction "}}}
function! s:split_to_keys(lhs)  "{{{
    " From arpeggio.vim
    "
    " Assumption: Special keys such as <C-u> are escaped with < and >, i.e.,
    "             a:lhs doesn't directly contain any escape sequences.
    return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfunction "}}}

function! eskk#util#str2map(str) "{{{
    let s = a:str
    let s = substitute(s, '<', '<lt>', 'g')
    let s = substitute(s, ' ', '<Space>', 'g')
    return s
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
        throw eskk#internal_error(['eskk', 'util'])
    endif

    if a:0 == 0
        if type(a:dict) == type([])
            if !eskk#util#has_idx(a:dict, a:follow[0])
                if a:ret_bool
                    return 0
                else
                    throw eskk#internal_error(['eskk', 'util'])
                endif
            endif
        elseif type(a:dict) == type({})
            if !has_key(a:dict, a:follow[0])
                if a:ret_bool
                    return 0
                else
                    throw eskk#internal_error(['eskk', 'util'])
                endif
            endif
        else
            throw eskk#internal_error(['eskk', 'util'])
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

function! eskk#util#assert(cond, ...) "{{{
    if !a:cond
        throw call('eskk#assertion_failure_error', [['eskk', 'util']] + a:000)
    endif
endfunction "}}}

" NOTE: Return value may be Funcref.
function! eskk#util#get_local_func(funcname, sid) "{{{
    " :help <SID>
    return printf('<SNR>%d_%s', a:sid, a:funcname)
endfunction "}}}


function! eskk#util#option_value(value, list, default_index) "{{{
    let match = 0
    for _ in a:list
        if _ ==# a:value
            let match = 1
            break
        endif
    endfor
    if match
        return a:value
    else
        return a:list[a:default_index]
    endif
endfunction "}}}


function! eskk#util#identity(value) "{{{
    return a:value
endfunction "}}}


function! eskk#util#rand(max) "{{{
    let next = localtime() * 1103515245 + 12345
    return (next / 65536) % (a:max + 1)
endfunction "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:sw=4:sts=4
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
function! eskk#util#logstrf(fmt, ...) "{{{
    return call('eskk#util#logf', [a:fmt] + map(copy(a:000), 'string(v:val)'))
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

function! eskk#util#unique(list) "{{{
    let list = []
    let dup_check = {}
    for item in a:list
        if !has_key(dup_check, item)
            let dup_check[item] = 1

            call add(list, item)
        endif
    endfor

    return list
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

function! eskk#util#can_access(cont, key) "{{{
    try
        let Value = a:cont[a:key]
        return 1
    catch
        return 0
    endtry
endfunction "}}}

function! eskk#util#get_f(dict, keys, ...) "{{{
    if empty(a:keys)
        throw eskk#internal_error(['eskk', 'util'])
    elseif len(a:keys) == 1
        if !eskk#util#can_access(a:dict, a:keys[0])
            if a:0
                return a:1
            else
                throw eskk#internal_error(['eskk', 'util'])
            endif
        endif
        return a:dict[a:keys[0]]
    else
        if eskk#util#can_access(a:dict, a:keys[0])
            return call('eskk#util#get_f', [a:dict[a:keys[0]], a:keys[1:]] + a:000)
        else
            if a:0
                return a:1
            else
                throw eskk#internal_error(['eskk', 'util'])
            endif
        endif
    endif
endfunction "}}}
function! eskk#util#has_key_f(dict, keys) "{{{
    if empty(a:keys)
        throw eskk#internal_error(['eskk', 'util'])
    elseif len(a:keys) == 1
        return eskk#util#can_access(a:dict, a:keys[0])
    else
        if eskk#util#can_access(a:dict, a:keys[0])
            return eskk#util#has_key_f(a:dict[a:keys[0]], a:keys[1:])
        else
            return 0
        endif
    endif
endfunction "}}}
function! eskk#util#let_f(dict, keys, value) "{{{
    if empty(a:keys)
        throw eskk#internal_error(['eskk', 'util'])
    elseif len(a:keys) == 1
        if eskk#util#can_access(a:dict, a:keys[0])
            return a:dict[a:keys[0]]
        else
            let a:dict[a:keys[0]] = a:value
            return a:value
        endif
    else
        if !eskk#util#can_access(a:dict, a:keys[0])
            let unused = -1
            let values = [unused, unused, unused, [], {}, unused]
            let a:dict[a:keys[0]] = values[type(a:dict)]
        endif
        return eskk#util#let_f(a:dict[a:keys[0]], a:keys[1:])
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


function! eskk#util#get_syn_names(...) "{{{
    let [line, col] = eskk#util#get_args(a:000, line('.'), col('.'))
    " synstack() returns strange value when col is over $ pos. Bug?
    if col >= col('$')
        return []
    endif
    return map(synstack(line, col), 'synIDattr(synIDtrans(v:val), "name")')
endfunction "}}}


function! eskk#util#escape_regex(regex) "{{{
    " XXX
    let s = a:regex
    let s = substitute(s, "\\", "\\\\", 'g')
    let s = substitute(s, '\*', "\\*", 'g')
    let s = substitute(s, '\.', "\\.", 'g')
    let s = substitute(s, '\^', "\\^", 'g')
    let s = substitute(s, '\$', "\\$", 'g')
    return s
endfunction "}}}

function! eskk#util#do_remap(map, modes) "{{{
    let m = maparg(a:map, a:modes)
    return m != '' ? m : a:map
endfunction "}}}

function! eskk#util#remove_ctrl_char(s, ctrl_char) "{{{
    let s = a:s
    let pos = stridx(s, a:ctrl_char)
    if pos != -1
        let before = strpart(s, 0, pos)
        let after  = strpart(s, pos + strlen(a:ctrl_char))
        let s = before . after
    endif
    return [s, pos]
endfunction "}}}
function! eskk#util#remove_all_ctrl_chars(s, ctrl_char) "{{{
    let s = a:s
    while 1
        let [s, pos] = eskk#util#remove_ctrl_char(s, a:ctrl_char)
        if pos == -1
            break
        endif
    endwhile
    return s
endfunction "}}}

function! eskk#util#glob(...) "{{{
    return split(call('glob', a:000), '\n')
endfunction "}}}
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

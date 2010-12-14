" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8


" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID


" Message
function! eskk#util#warn(msg) "{{{
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction "}}}
function! eskk#util#warnf(msg, ...) "{{{
    call eskk#util#warn(call('printf', [a:msg] + a:000))
endfunction "}}}


" Encoding
function! eskk#util#mb_strlen(str) "{{{
    return strlen(substitute(copy(a:str), '.', 'x', 'g'))
endfunction "}}}
function! eskk#util#mb_chop(str) "{{{
    return substitute(a:str, '.$', '', '')
endfunction "}}}
function! eskk#util#iconv(expr, from, to) "{{{
    if a:from == '' || a:to == '' || a:from ==? a:to
        return a:expr
    endif
    let result = iconv(a:expr, a:from, a:to)
    return result != '' ? result : a:expr
endfunction "}}}


" List function
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
function! eskk#util#flatten(list) "{{{
    let ret = []
    for _ in a:list
        if type(_) == type([])
            let ret += eskk#util#flatten(_)
        else
            call add(ret, _)
        endif
    endfor
    return ret
endfunction "}}}
function! eskk#util#list_has(list, elem) "{{{
    for _ in a:list
        if _ ==# a:elem
            return 1
        endif
    endfor
    return 0
endfunction "}}}


" Dict function
function! eskk#util#dict_add(dict, ...) "{{{
    if a:0 % 2
        return a:dict
    endif
    let dict = copy(a:dict)
    let kv = copy(a:000)
    while !empty(kv)
        let [key, Value] = remove(kv, 0, 1)
        if !has_key(dict, key)
            let dict[key] = Value
        endif
    endwhile
    return dict
endfunction "}}}

" Various structure function
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
            return call(
            \   'eskk#util#get_f',
            \   [a:dict[a:keys[0]], a:keys[1:]] + a:000
            \)
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
        return eskk#util#let_f(a:dict[a:keys[0]], a:keys[1:], a:value)
    endif
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
function! eskk#util#can_access(cont, key) "{{{
    try
        let Value = a:cont[a:key]
        return 1
    catch
        return 0
    endtry
endfunction "}}}


" String/Regex
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
function! eskk#util#is_lower(char) "{{{
    return a:char =~ '^\a$' && a:char ==# tolower(a:char)
endfunction "}}}
function! eskk#util#is_upper(char) "{{{
    return a:char =~ '^\a$' && a:char ==# toupper(a:char)
endfunction "}}}
function! eskk#util#formatstrf(fmt, ...) "{{{
    return call(
    \   'printf',
    \   [a:fmt] + map(copy(a:000), 'string(v:val)')
    \)
endfunction "}}}


" Mappings
function! eskk#util#get_tab_raw_str() "{{{
    return &l:expandtab ? repeat(' ', &tabstop) : "\<Tab>"
endfunction "}}}
function! eskk#util#get_local_func(funcname, sid) "{{{
    " :help <SID>
    return printf('<SNR>%d_%s', a:sid, a:funcname)
endfunction "}}}
function! eskk#util#get_sid_from_source(regex) "{{{
    redir => output
    silent scriptnames
    redir END

    for line in split(output, '\n')
        if line =~# a:regex
            let sid = matchstr(line, '\C'.'\s*\zs\d\+')
            return sid != '' ? str2nr(sid) : -1
        endif
    endfor
endfunction "}}}


" System
function! eskk#util#move_file(src, dest, ...) "{{{
    let show_error = a:0 ? a:1 : 1
    if executable('mv')
        silent execute '!mv' shellescape(a:src) shellescape(a:dest)
        if show_error && v:shell_error
            call eskk#util#warn("'mv' returned failure value: " . v:shell_error)
            sleep 1
            return 0
        endif
    else
        let ret = writefile(readfile(a:src, "b"), a:dest, "b")
        if show_error && ret == -1
            call eskk#util#warn("can't copy '" . a:src . "' to '" . a:dest . "'.")
            sleep 1
            return 0
        endif
    endif
    return 1
endfunction "}}}
function! eskk#util#copy_file(src, dest, ...) "{{{
    let show_error = a:0 ? a:1 : 1
    if executable('cp')
        silent execute '!cp' shellescape(a:src) shellescape(a:dest)
        if show_error && v:shell_error
            call eskk#util#warn("'cp' returned failure value: " . v:shell_error)
            sleep 1
            return 0
        endif
    else
        return s:copy_file_vimscript(a:src, a:dest, show_error)
    endif
    return 1
endfunction "}}}
function! s:copy_file_vimscript(src, dest, show_error) "{{{
    let ret = writefile(readfile(a:src, "b"), a:dest, "b")
    if a:show_error && ret == -1
        call eskk#util#warn("can't copy '" . a:src . "' to '" . a:dest . "'.")
        sleep 1
        return 0
    endif
endfunction "}}}


" Misc.
function! eskk#util#identity(value) "{{{
    return a:value
endfunction "}}}
function! eskk#util#rand(max) "{{{
    let next = localtime() * 1103515245 + 12345
    return (next / 65536) % (a:max + 1)
endfunction "}}}
function! eskk#util#get_syn_names(...) "{{{
    let line = get(a:000, 0, line('.'))
    let col = get(a:000, 1, col('.'))
    " synstack() returns strange value when col is over $ pos.
    " it's fixed now, but remain this code for the old Vims.
    if col >= col('$')
        return []
    endif
    return map(
    \   synstack(line, col),
    \   'synIDattr(synIDtrans(v:val), "name")'
    \)
endfunction "}}}
function! eskk#util#globpath(pat) "{{{
    return split(globpath(&runtimepath, a:pat), '\n')
endfunction "}}}
function! eskk#util#getchar(...) "{{{
    let success = 0
    if inputsave() !=# success
        call eskk#error#log("inputsave() failed")
    endif
    try
        let c = call('getchar', a:000)
        return type(c) == type("") ? c : nr2char(c)
    finally
        if inputrestore() !=# success
            call eskk#error#log("inputrestore() failed")
        endif
    endtry
endfunction "}}}
function! eskk#util#input(...) "{{{
    let success = 0
    if inputsave() !=# success
        call eskk#error#log("inputsave() failed")
    endif
    try
        return call('input', a:000)
    finally
        if inputrestore() !=# success
            call eskk#error#log("inputrestore() failed")
        endif
    endtry
endfunction "}}}
function! eskk#util#mkdir_nothrow(...) "{{{
    try
        call call('mkdir', a:000)
        return 1
    catch
        return 0
    endtry
endfunction "}}}

let s:path_sep = has('win32') ? "\\" : '/'
function! eskk#util#join_path(dir, ...) "{{{
    return join([a:dir] + a:000, s:path_sep)
endfunction "}}}

function! eskk#util#redir_english(excmd) "{{{
    let save_lang = v:lang
    lang messages C
    try
        redir => output
        silent execute a:excmd
        redir END
    finally
        execute 'lang messages' save_lang
    endtry
endfunction "}}}

function! eskk#util#make_random_number(n) "{{{
    " http://vim-users.jp/2009/11/hack98/
    if a:n < 1
        return -1
    endif
    let match_end = matchend(reltimestr(reltime()), '\d\+\.') + 1
    let rand = reltimestr(reltime())[match_end : ] % (a:n)
    return rand
endfunction "}}}
function! eskk#util#make_random_string(length) "{{{
    let ret = ''
    let i = 0
    let str =
    \   "abcdefghijklmnopqrstuvwxyz"
    \   . "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    \   . "123456789"
    let len = strlen(str)

    while i < a:length
        let rand = eskk#util#make_random_number(len)
        let ret .= str[rand]
        let i += 1
    endwhile

    return ret
endfunction "}}}
function! eskk#util#make_ascii_expr(...) "{{{
    while 1
        let varname =
        \   "make_ascii_expr_"
        \   . eskk#util#make_random_string(10)
        if !eskk#buffer_value_has(varname)
            break
        endif
    endwhile

    if a:0
        call eskk#register_temp_event(
        \   'filter-begin',
        \   'eskk#buffer_value_remove',
        \   [varname]
        \)
        call eskk#buffer_value_put(varname, a:1)
    endif

    return 'eskk#buffer_value_get(' . string(varname) . ')'
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

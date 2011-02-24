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


" Options
function! eskk#util#set_default(var, val) "{{{
    if !exists(a:var) || type({a:var}) != type(a:val)
        let {a:var} = a:val
    endif
endfunction "}}}


" Encoding
" eskk#util#mb_strlen(str) {{{
if exists('*strchars')
    function! eskk#util#mb_strlen(str)
        return strchars(a:str)
    endfunction
else
    function! eskk#util#mb_strlen(str)
        return strlen(substitute(copy(a:str), '.', 'x', 'g'))
    endfunction
endif "}}}
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
function! eskk#util#flatten_list(list) "{{{
    let ret = []
    for _ in a:list
        if type(_) == type([])
            let ret += eskk#util#flatten_list(_)
        else
            call add(ret, _)
        endif
    endfor
    return ret
endfunction "}}}
function! eskk#util#list_has(list, elem) "{{{
    for Value in a:list
        if Value ==# a:elem
            return 1
        endif
    endfor
    return 0
endfunction "}}}
function! eskk#util#has_idx(list, idx) "{{{
    " Return true when negative idx.
    " let idx = a:idx >= 0 ? a:idx : len(a:list) + a:idx
    let idx = a:idx
    return 0 <= idx && idx < len(a:list)
endfunction "}}}


" Format
function! eskk#util#formatstrf(fmt, ...) "{{{
    return call(
    \   'printf',
    \   [a:fmt] + map(copy(a:000), 'string(v:val)')
    \)
endfunction "}}}


" SID/Scripts
function! eskk#util#get_local_func(funcname, sid) "{{{
    " :help <SID>
    return printf('<SNR>%d_%s', a:sid, a:funcname)
endfunction "}}}
function! eskk#util#get_loaded_scripts(regex) "{{{
    let output = eskk#util#redir_english('scriptnames')
    let scripts = []
    for line in split(output, '\n')
        let path = matchstr(line, '^ *\d\+: \+\zs.\+$')
        if path != '' && path =~# a:regex
            call add(scripts, path)
        endif
    endfor
    return scripts
endfunction "}}}


" Filesystem
function! eskk#util#move_file(src, dest, ...) "{{{
    let show_error = a:0 ? a:1 : 1
    if executable('mv')
        silent execute '!mv' shellescape(a:src) shellescape(a:dest)
        if v:shell_error
            if show_error
                call eskk#util#warn("'mv' returned failure value: " . v:shell_error)
                sleep 1
            endif
            return 0
        endif
        return 1
    else
        return s:move_file_vimscript(a:src, a:dest, show_error)
    endif
endfunction "}}}
function! s:move_file_vimscript(src, dest, show_error) "{{{
    let copy_success = eskk#util#copy_file(a:src, a:dest, a:show_error)
    let remove_success = delete(a:src) == 0

    if copy_success && remove_success
        return 1
    else
        if a:show_error
            call eskk#util#warn("can't move '" . a:src . "' to '" . a:dest . "'.")
        endif
        return 0
    endif
endfunction "}}}
function! eskk#util#copy_file(src, dest, ...) "{{{
    let show_error = a:0 ? a:1 : 1
    if executable('cp')
        silent execute '!cp' shellescape(a:src) shellescape(a:dest)
        if v:shell_error
            if show_error
                call eskk#util#warn("'cp' returned failure value: " . v:shell_error)
            endif
            return 0
        endif
        return 1
    else
        return s:copy_file_vimscript(a:src, a:dest, show_error)
    endif
endfunction "}}}
function! s:copy_file_vimscript(src, dest, show_error) "{{{
    let ret = writefile(readfile(a:src, "b"), a:dest, "b")
    if ret == -1
        if a:show_error
            call eskk#util#warn("can't copy '" . a:src . "' to '" . a:dest . "'.")
            sleep 1
        endif
        return 0
    endif
    return 1
endfunction "}}}
function! eskk#util#mkdir_nothrow(...) "{{{
    try
        call call('mkdir', a:000)
        return 1
    catch
        return 0
    endtry
endfunction "}}}


" Path
let s:path_sep = has('win32') ? "\\" : '/'
function! eskk#util#join_path(dir, ...) "{{{
    return join([a:dir] + a:000, s:path_sep)
endfunction "}}}


" Misc.
function! eskk#util#identity(value) "{{{
    return a:value
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
function! eskk#util#redir_english(excmd) "{{{
    let save_lang = v:lang
    lang messages C
    try
        redir => output
        silent execute a:excmd
        redir END
    finally
        redir END
        execute 'lang messages' save_lang
    endtry
    return output
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

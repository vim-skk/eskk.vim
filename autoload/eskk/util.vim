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


" Load the vital of eskk.
let s:Vital = vital#of('eskk')
call s:Vital.load('Data.OrderedSet')
call s:Vital.load('Data.List')
call s:Vital.load('Data.String')
call s:Vital.load('System.Filepath')


" Environment
" function! eskk#util#is_mswin() {{{
if has('win16') || has('win32') || has('win64') || has('win95')
    function! eskk#util#is_mswin()
        return 1
    endfunction
else
    function! eskk#util#is_mswin()
        return 0
    endfunction
endif
" }}}


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
function! eskk#util#mb_strlen(...)
    let module = s:Vital.Data.String
    return call(module.strchars, a:000, module)
endfunction
function! eskk#util#mb_chop(...)
    let module = s:Vital.Data.String
    return call(module.chop, a:000, module)
endfunction
function! eskk#util#iconv(...)
    let module = s:Vital.Data.String
    return call(module.iconv, a:000, module)
endfunction


" List function
function! eskk#util#flatten_list(...)
    let module = s:Vital.Data.List
    return call(module.flatten, a:000, module)
endfunction
function! eskk#util#list_has(...)
    let module = s:Vital.Data.List
    return call(module.has, a:000, module)
endfunction
function! eskk#util#has_idx(...)
    let module = s:Vital.Data.List
    return call(module.has_index, a:000, module)
endfunction


" Ordered Set
function! eskk#util#create_data_ordered_set(...)
    let module = s:Vital.Data.OrderedSet
    return call(module.new, a:000, module)
endfunction


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
function! eskk#util#join_path(...) "{{{
    let module = s:Vital.System.Filepath
    return call(module.join, a:000, module)
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

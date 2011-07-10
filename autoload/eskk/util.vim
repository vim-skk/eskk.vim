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
call s:Vital.load('System.File')
call s:Vital.load('Mapping')


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


" Multibyte/Encoding
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
function! eskk#util#move_file(src, dest) "{{{
    return s:Vital.System.File.move_file(a:src, a:dest)
endfunction "}}}
function! eskk#util#copy_file(src, dest) "{{{
    return s:Vital.System.File.copy_file(a:src, a:dest)
endfunction "}}}
function! eskk#util#mkdir_nothrow(...) "{{{
    let module = s:Vital.System.File
    return call(module.mkdir_nothrow, a:000, module)
endfunction "}}}


" Path
function! eskk#util#join_path(...) "{{{
    let module = s:Vital.System.Filepath
    return call(module.join, a:000, module)
endfunction "}}}
function! eskk#util#globpath(pat) "{{{
    return split(globpath(&runtimepath, a:pat), '\n')
endfunction "}}}


" Mapping
function! eskk#util#mapopt_chars2raw(...) "{{{
    let module = s:Vital.Mapping
    return call(module.options_chars2raw, a:000, module)
endfunction "}}}
function! eskk#util#mapopt_chars2dict(...) "{{{
    let module = s:Vital.Mapping
    return call(module.options_chars2dict, a:000, module)
endfunction "}}}
function! eskk#util#mapopt_dict2chars(...) "{{{
    let module = s:Vital.Mapping
    return call(module.options_dict2chars, a:000, module)
endfunction "}}}
function! eskk#util#get_map_command(...) "{{{
    let module = s:Vital.Mapping
    return call(module.get_map_command, a:000, module)
endfunction "}}}
function! eskk#util#get_unmap_command(...) "{{{
    let module = s:Vital.Mapping
    return call(module.get_unmap_command, a:000, module)
endfunction "}}}
function! eskk#util#is_mode_char(...) "{{{
    let module = s:Vital.Mapping
    return call(module.is_mode_char, a:000, module)
endfunction "}}}


" Misc.
function! eskk#util#identity(value) "{{{
    return a:value
endfunction "}}}
function! eskk#util#getchar(...) "{{{
    let module = s:Vital
    return call(module.getchar_safe, a:000, module)
endfunction "}}}
function! eskk#util#input(...) "{{{
    let module = s:Vital
    return call(module.input_safe, a:000, module)
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

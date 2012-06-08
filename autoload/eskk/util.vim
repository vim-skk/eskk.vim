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
let s:Vital = vital#of('eskk.vim')
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


" Assert, Error
function! eskk#util#assert(cond, msg) "{{{
    if !a:cond
        throw eskk#util#build_error(
        \   ['eskk', 'util'],
        \   ['assertion failed', a:msg]
        \)
    endif
endfunction "}}}
function! eskk#util#build_error(from, msg_list) "{{{
    let file = 'autoload/' . join(a:from, '/') . '.vim'
    return 'eskk: ' . join(a:msg_list, ': ') . ' (at ' . file . ')'
endfunction "}}}


" Options
function! eskk#util#set_default(var, Value) "{{{
    if !exists(a:var)
        let {a:var} = a:Value
    elseif type({a:var}) isnot type(a:Value)
        call eskk#logger#warn(
        \   "'".string(a:var)."' is invalid type value. "
        \   . "use default value...")
        execute 'unlet' a:var
        let {a:var} = a:Value
    endif
endfunction "}}}
function! eskk#util#set_default_dict(var, dict) "{{{
    if type(a:dict) isnot type({})
        call eskk#logger#warn('invalid argument for eskk#util#set_default_dict('.string(a:var).', ...)')
        return
    endif
    if !exists(a:var)
        let {a:var} = a:dict
    else
        call extend({a:var}, a:dict, 'keep')
    endif
endfunction "}}}


" Multibyte/Encoding
function! eskk#util#mb_strlen(...) "{{{
    let module = s:Vital.Data.String
    return call(module.strchars, a:000, module)
endfunction "}}}
function! eskk#util#mb_chop(...) "{{{
    let module = s:Vital.Data.String
    return call(module.chop, a:000, module)
endfunction "}}}
function! eskk#util#iconv(...) "{{{
    let module = s:Vital
    return call(module.iconv, a:000, module)
endfunction "}}}


" List function
function! eskk#util#flatten_list(...) "{{{
    let module = s:Vital.Data.List
    return call(module.flatten, a:000, module)
endfunction "}}}
function! eskk#util#has_idx(...) "{{{
    let module = s:Vital.Data.List
    return call(module.has_index, a:000, module)
endfunction "}}}


" String function
function! eskk#util#diffidx(...) "{{{
    let module = s:Vital.Data.String
    return call(module.diffidx, a:000, module)
endfunction "}}}
function! eskk#util#split_byte_range(s, begin, end) "{{{
    let s     = a:s
    let begin = a:begin
    let end   = a:end

    if end < begin
        return []
    endif

    let len   = strlen(s)
    let begin = begin <# 0 ? 0 :
    \           (begin >=# len ? len - 1 : begin)
    let end   = end   <# 0 ? 0 :
    \           (end   >=# len ? len - 1 : end  )

    return [
    \   (begin >=# 1 ? s[: begin-1] : ''),
    \   s[begin : end],
    \   (end < strlen(s) - 1 ? s[end+1 :] : ''),
    \]
endfunction "}}}


" Ordered Set
function! eskk#util#create_data_ordered_set(...) "{{{
    let module = s:Vital.Data.OrderedSet
    return call(module.new, a:000, module)
endfunction "}}}


" SID/Scripts
function! eskk#util#get_local_funcref(funcname, sid) "{{{
    return function(eskk#util#get_local_func(a:funcname, a:sid))
endfunction "}}}
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
function! eskk#util#dlog(data, filename) "{{{
    let data = type(a:data) is type([]) ?
    \              a:data :
    \          type(a:data) is type("") ?
    \              split(a:data, "\n") :
    \              0
    if data is 0 | return | endif

    " Append to filename.
    try | let lines = readfile(a:filename)
    catch | let lines = [] | endtry
    call writefile(lines + data, a:filename)
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

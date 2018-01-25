" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8


" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:SID() abort "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID


" Load the vital of eskk.
let s:Vital = vital#eskk#new()
call s:Vital.load('Prelude')
call s:Vital.load('Process')
call s:Vital.load('Data.OrderedSet')
call s:Vital.load('Data.List')
call s:Vital.load('Data.String')
call s:Vital.load('System.Filepath')
call s:Vital.load('System.File')
call s:Vital.load('Mapping')


" Environment
" function! eskk#util#is_mswin() {{{
if has('win16') || has('win32') || has('win64') || has('win95')
    function! eskk#util#is_mswin() abort
        return 1
    endfunction
else
    function! eskk#util#is_mswin() abort
        return 0
    endfunction
endif
" }}}
function! eskk#util#has_vimproc(...) abort "{{{
    let module = s:Vital.Process
    return call(module.has_vimproc, a:000, module)
endfunction "}}}


" Assert, Error
function! eskk#util#assert(cond, msg) abort "{{{
    if !a:cond
        throw eskk#util#build_error(
                    \   ['eskk', 'util'],
                    \   ['assertion failed', a:msg]
                    \)
    endif
endfunction "}}}
function! eskk#util#build_error(from, msg_list) abort "{{{
    let file = 'autoload/' . join(a:from, '/') . '.vim'
    let msg = type(a:msg_list) is type([]) ?
                \           join(a:msg_list, ': ') : a:msg_list
    return 'eskk: ' . msg . ' (at ' . file . ')'
endfunction "}}}


" Options
function! eskk#util#set_default(var, Value) abort "{{{
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
function! eskk#util#set_default_dict(var, dict) abort "{{{
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
function! eskk#util#mb_strlen(...) abort "{{{
    let module = s:Vital.Data.String
    return call(module.strchars, a:000, module)
endfunction "}}}
function! eskk#util#mb_chop(...) abort "{{{
    let module = s:Vital.Data.String
    return call(module.chop, a:000, module)
endfunction "}}}
function! eskk#util#iconv(...) abort "{{{
    let module = s:Vital.Process
    return call(module.iconv, a:000, module)
endfunction "}}}


" List function
function! eskk#util#flatten_list(...) abort "{{{
    let module = s:Vital.Data.List
    return call(module.flatten, a:000, module)
endfunction "}}}
function! eskk#util#has_idx(...) abort "{{{
    let module = s:Vital.Data.List
    return call(module.has_index, a:000, module)
endfunction "}}}
function! eskk#util#uniq_by(...) abort "{{{
    let module = s:Vital.Data.List
    return call(module.uniq_by, a:000, module)
endfunction "}}}


" String function
function! eskk#util#diffidx(...) abort "{{{
    let module = s:Vital.Data.String
    return call(module.diffidx, a:000, module)
endfunction "}}}
function! eskk#util#split_byte_range(s, begin, end) abort "{{{
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
function! eskk#util#create_data_ordered_set(...) abort "{{{
    let module = s:Vital.Data.OrderedSet
    return call(module.new, a:000, module)
endfunction "}}}


" SID/Scripts
function! eskk#util#get_local_funcref(funcname, sid) abort "{{{
    return function(eskk#util#get_local_func(a:funcname, a:sid))
endfunction "}}}
function! eskk#util#get_local_func(funcname, sid) abort "{{{
    " :help <SID>
    return printf('<SNR>%d_%s', a:sid, a:funcname)
endfunction "}}}
function! eskk#util#get_loaded_scripts(regex) abort "{{{
    let output = eskk#util#redir_english('scriptnames')
    let scripts = []
    for line in split(output, '\n')
        let path = matchstr(line, '^ *\d\+: \+\zs.\+$')
        if path !=# '' && path =~# a:regex
            call add(scripts, path)
        endif
    endfor
    return scripts
endfunction "}}}


" Filesystem
function! eskk#util#move_file(src, dest) abort "{{{
    return s:Vital.System.File.move_file(a:src, a:dest)
endfunction "}}}
function! eskk#util#copy_file(src, dest) abort "{{{
    return s:Vital.System.File.copy(a:src, a:dest)
endfunction "}}}
function! eskk#util#mkdir_nothrow(...) abort "{{{
    let module = s:Vital.System.File
    return call(module.mkdir_nothrow, a:000, module)
endfunction "}}}
function! eskk#util#dlog(data, filename) abort "{{{
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
function! eskk#util#join_path(...) abort "{{{
    let module = s:Vital.System.Filepath
    return call(module.join, a:000, module)
endfunction "}}}
function! eskk#util#globpath(pat) abort "{{{
    return split(globpath(&runtimepath, a:pat), '\n')
endfunction "}}}


" Mapping
function! eskk#util#mapopt_chars2raw(...) abort "{{{
    let module = s:Vital.Mapping
    return call(module.options_chars2raw, a:000, module)
endfunction "}}}
function! eskk#util#mapopt_chars2dict(...) abort "{{{
    let module = s:Vital.Mapping
    return call(module.options_chars2dict, a:000, module)
endfunction "}}}
function! eskk#util#mapopt_dict2chars(...) abort "{{{
    let module = s:Vital.Mapping
    return call(module.options_dict2chars, a:000, module)
endfunction "}}}
function! eskk#util#get_map_command(...) abort "{{{
    let module = s:Vital.Mapping
    return call(module.get_map_command, a:000, module)
endfunction "}}}
function! eskk#util#get_unmap_command(...) abort "{{{
    let module = s:Vital.Mapping
    return call(module.get_unmap_command, a:000, module)
endfunction "}}}
function! eskk#util#is_mode_char(...) abort "{{{
    let module = s:Vital.Mapping
    return call(module.is_mode_char, a:000, module)
endfunction "}}}
function! eskk#util#key2char(key) abort "{{{
    if stridx(a:key, '<') ==# -1    " optimization
        return a:key
    endif
    return join(
                \   map(
                \       s:split_to_keys(a:key),
                \       'v:val =~# "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val'
                \   ),
                \   ''
                \)
endfunction "}}}
function! s:split_to_keys(lhs) abort  "{{{
    " From arpeggio.vim
    "
    " Assumption: Special keys such as <C-u>
    " are escaped with < and >, i.e.,
    " a:lhs doesn't directly contain any escape sequences.
    return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfunction "}}}


" Misc.
function! eskk#util#identity(value) abort "{{{
    return a:value
endfunction "}}}
function! eskk#util#getchar(...) abort "{{{
    let module = s:Vital.Prelude
    return call(module.getchar_safe, a:000, module)
endfunction "}}}
function! eskk#util#input(...) abort "{{{
    let module = s:Vital.Prelude
    return call(module.input_safe, a:000, module)
endfunction "}}}
function! eskk#util#redir_english(excmd) abort "{{{
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

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


" Logging/Output
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
    if !eskk#is_initialized()
        call eskk#register_temp_event('enable-im', 'eskk#util#log', [a:msg])
        return
    endif

    redraw

    let stdout = eskk#util#option_value(
    \   g:eskk_debug_stdout,
    \   ['file', 'cmdline'],
    \   0
    \)

    if stdout ==# 'file'
        let file = expand(eskk#util#join_path(g:eskk_directory, 'log', 'debug.log'))
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

function! eskk#util#printstrf(fmt, ...) "{{{
    return call('printf', [a:fmt] + map(copy(a:000), 'string(v:val)'))
endfunction "}}}


" Multibyte
function! eskk#util#mb_strlen(str) "{{{
    return strlen(substitute(copy(a:str), '.', 'x', 'g'))
endfunction "}}}
function! eskk#util#mb_chop(str) "{{{
    return substitute(a:str, '.$', '', '')
endfunction "}}}


" Argument
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

function! eskk#util#list_any(elem, list) "{{{
    for _ in a:list
        if _ ==# a:elem
            return 1
        endif
    endfor
    return 0
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


" Parsing
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
function! eskk#util#is_lower(char) "{{{
    return a:char ==# tolower(a:char)
endfunction "}}}
function! eskk#util#is_upper(char) "{{{
    return a:char ==# toupper(a:char)
endfunction "}}}


" Mappings
function! s:split_to_keys(lhs)  "{{{
    " From arpeggio.vim
    "
    " Assumption: Special keys such as <C-u> are escaped with < and >, i.e.,
    "             a:lhs doesn't directly contain any escape sequences.
    return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfunction "}}}
function! eskk#util#key2char(key) "{{{
    " From arpeggio.vim

    let keys = s:split_to_keys(a:key)
    call map(keys, 'v:val =~ "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val')
    return join(keys, '')
endfunction "}}}
function! eskk#util#str2map(str) "{{{
    let s = a:str
    for key in [
    \   '<lt>',
    \   '<Space>',
    \   '<Esc>',
    \   '<Tab>',
    \]
        let s = substitute(s, eskk#util#key2char(key), key, 'g')
    endfor
    return s != '' ? s : '<Nop>'
endfunction "}}}
function! eskk#util#get_tab_raw_str() "{{{
    return &l:expandtab ? repeat(' ', &tabstop) : "\<Tab>"
endfunction "}}}
function! eskk#util#do_remap(map, modes) "{{{
    let m = maparg(a:map, a:modes)
    return m != '' ? m : a:map
endfunction "}}}
function! eskk#util#get_nore_map(key, ...) "{{{
    " NOTE:
    " a:key is escaped. So when a:key is '<C-a>', return value is
    "   `<Plug>(eskk:filter:<C-a>)`
    " not
    "   `<Plug>(eskk:filter:^A)` (^A is control character)

    let [rhs, key] = [a:key, a:key]
    let key = eskk#util#str2map(key)

    let lhs = printf('<Plug>(eskk:noremap:%s)', key)
    if maparg(lhs, 'icl') != ''
        return lhs
    endif

    call eskk#map((a:0 ? substitute(a:1, 'r', '', 'g') : ''), lhs, rhs)

    return lhs
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
function! eskk#util#mapopt_chars2dict(options) "{{{
    let opt = s:create_default_mapopt()
    for c in split(a:options, '\zs')
        if c ==# 'b'
            let opt.buffer = 1
        elseif c ==# 'e'
            let opt.expr = 1
        elseif c ==# 's'
            let opt.silent = 1
        elseif c ==# 'u'
            let opt.unique = 1
        elseif c ==# 'r'
            let opt.remap = 1
        endif
    endfor
    return opt
endfunction "}}}
function! eskk#util#mapopt_dict2raw(options) "{{{
    let ret = ''
    for [key, val] in items(a:options)
        if key ==# 'remap' || key ==# 'map-if'
            continue
        endif
        if val
            let ret .= printf('<%s>', key)
        endif
    endfor
    return ret
endfunction "}}}
function! eskk#util#mapopt_chars2raw(options) "{{{
    let table = {
    \   'b': '<buffer>',
    \   'e': '<expr>',
    \   's': '<silent>',
    \   'u': '<unique>',
    \}
    return join(map(split(a:options, '\zs'), 'get(table, v:val, "")'), '')
endfunction "}}}


" Misc.
function! eskk#util#assert(cond, ...) "{{{
    if !a:cond
        throw call('eskk#assertion_failure_error', [['eskk', 'util']] + a:000)
    endif
endfunction "}}}

function! eskk#util#option_value(value, list, default_index) "{{{
    for _ in a:list
        if _ ==# a:value
            return a:value
        endif
    endfor
    return a:list[a:default_index]
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
function! eskk#util#globpath(pat) "{{{
    return split(globpath(&runtimepath, a:pat), '\n')
endfunction "}}}
function! eskk#util#getchar(...) "{{{
    let c = call('getchar', a:000)
    return type(c) == type("") ? c : nr2char(c)
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


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

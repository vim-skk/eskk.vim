" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:LOG_NONE = 0
let s:LOG_ERROR = 1
let s:LOG_WARN = 2
let s:LOG_INFO = 3
let s:LOG_DEBUG = 4
let s:LEVEL_STR_TABLE = {
\   s:LOG_NONE : "",
\   s:LOG_ERROR : "ERROR",
\   s:LOG_WARN : "WARN",
\   s:LOG_INFO : "INFO",
\   s:LOG_DEBUG : "DEBUG",
\}


let s:warning_messages = []

function! eskk#logger#write_debug_log_file() "{{{
    if empty(s:warning_messages)
        return
    endif
    try
        execute 'redir >>' expand(
        \   eskk#util#join_path(
        \       g:eskk#directory,
        \       'log',
        \       'debug' . strftime('-%Y-%m-%d') . '.log'
        \   )
        \)
        for msg in s:warning_messages
            silent echo msg
        endfor
    finally
        redir END
        let s:warning_messages = []
    endtry
endfunction "}}}
function! eskk#logger#write_error_log_file(stash, ...) "{{{
    let v_exception = a:0 ? a:1 : v:exception

    let lines = []

    call add(lines, "Please report this error to author.")
    call add(lines, "`:help eskk` to see author's e-mail address.")
    call add(lines, '')
    call add(lines, strftime('%c'))
    call add(lines, '')

    call add(lines, '--- char ---')
    let char = get(a:stash, 'char', '')
    call add(lines, printf('char: %s(%d)', string(char), char2nr(char)))
    call add(lines, printf('mode(): %s', mode()))
    call add(lines, '--- char ---')

    call add(lines, '')

    call add(lines, '--- exception ---')
    if v_exception =~# '^eskk:'
        call add(lines, 'exception type: eskk exception')
        call add(lines, printf('v:exception: %s', v_exception))
    else
        call add(lines, 'exception type: Vim internal error')
        call add(lines, printf('v:exception: %s', v_exception))
    endif
    call add(lines, printf('v:throwpoint: %s', v:throwpoint))

    call add(lines, '')

    let arg = {
    \   'snr_funcname': '<SNR>\d\+_\w\+',
    \   'autoload_funcname': '[\w#]\+',
    \   'global_funcname': '[A-Z]\w*',
    \   'lines': lines,
    \}
    let o = {}

    function o['a'](arg)
        let a:arg.stacktrace =
        \   matchstr(v:throwpoint, '\C'.'^function \zs\S\+\ze, ')
        return a:arg.stacktrace != ''
    endfunction

    function o['b'](arg)
        let a:arg.funcname = get(split(a:arg.stacktrace, '\.\.'), -1, '')
        return a:arg.funcname != ''
    endfunction

    function o['c'](arg)
        try
            return exists('*' . a:arg.funcname)
        catch    " E129: Function name required
            " but "s:" prefixed function also raises this error.
            return a:arg.funcname =~# a:arg.snr_funcname ? 1 : 0
        endtry
    endfunction

    function o['d'](arg)
        let output = eskk#util#redir_english('function ' . a:arg.funcname)
        let a:arg.lines += split(output, '\n')
    endfunction

    for k in sort(keys(o))
        if !o[k](arg)
            break
        endif
    endfor
    call add(lines, '--- exception ---')

    call add(lines, '')

    call add(lines, '--- preedit ---')
    if has_key(a:stash, 'preedit')
        let lines += a:stash.preedit.dump()
    else
        let lines += ['(no preedit)']
    endif
    call add(lines, '--- preedit ---')

    call add(lines, '')

    call add(lines, "--- Vim's :version ---")
    redir => output
    silent version
    redir END
    let lines += split(output, '\n')
    call add(lines, "--- Vim's :version ---")

    call add(lines, '')
    call add(lines, '')

    if executable('uname')
        call add(lines, "--- Operating System ---")
        let uname = substitute(system('uname -a'), '\n\+$', '', '')
        call add(lines, printf('"uname -a" = %s', uname))
        call add(lines, "--- Operating System ---")
        call add(lines, '')
    endif

    call add(lines, '--- feature-list ---')
    call add(lines, 'gui_running = '.has('gui_running'))
    call add(lines, 'unix = '.has('unix'))
    call add(lines, 'mac = '.has('mac'))
    call add(lines, 'macunix = '.has('macunix'))
    call add(lines, 'win16 = '.has('win16'))
    call add(lines, 'win32 = '.has('win32'))
    call add(lines, 'win64 = '.has('win64'))
    call add(lines, 'win32unix = '.has('win32unix'))
    call add(lines, 'win95 = '.has('win95'))
    call add(lines, 'amiga = '.has('amiga'))
    call add(lines, 'beos = '.has('beos'))
    call add(lines, 'dos16 = '.has('dos16'))
    call add(lines, 'dos32 = '.has('dos32'))
    call add(lines, 'os2 = '.has('macunix'))
    call add(lines, 'qnx = '.has('qnx'))
    call add(lines, 'vms = '.has('vms'))
    call add(lines, '--- feature-list ---')



    let log_file = expand(
    \   eskk#util#join_path(
    \       g:eskk#directory,
    \       'log', 'error' . strftime('-%Y-%m-%d-%H%M%S') . '.log'
    \   )
    \)
    let write_success = 0
    try
        call writefile(lines, log_file)
        let write_success = 1
    catch
        call eskk#logger#warnf("Cannot write to log file '%s'.", log_file)
    endtry

    let save_cmdheight = &cmdheight
    setlocal cmdheight=3
    try
        call eskk#logger#warnf(
        \   "Error!! See %s for details.",
        \   (write_success ? string(log_file) : ':messages')
        \)
    finally
        let &cmdheight = save_cmdheight
    endtry
endfunction "}}}

function! s:do_log(level, hl, msg) "{{{
    let msg = printf('[%s] [%s] %s',
    \           strftime('%c'), s:LEVEL_STR_TABLE[a:level], a:msg)
    " g:eskk#log_cmdline_level
    if g:eskk#log_cmdline_level >= a:level
        call s:echomsg(a:hl, msg)
    endif
    " g:eskk#log_file_level
    if g:eskk#log_file_level >= a:level
        call add(s:warning_messages, msg)
    endif

    " g:eskk#debug_wait_ms
    if eskk#is_initialized() && g:eskk#debug_wait_ms ># 0
        execute printf('sleep %dm', g:eskk#debug_wait_ms)
    endif
endfunction "}}}
function! s:do_logf(level, hl, ...) "{{{
    call s:do_log(a:level, a:hl, call('printf', a:000))
endfunction "}}}

function! eskk#logger#log_exception(what) "{{{
    call eskk#logger#warn("'" . a:what . "' threw exception")
    call eskk#logger#warn('v:exception = ' . string(v:exception))
    call eskk#logger#warn('v:throwpoint = ' . string(v:throwpoint))
endfunction "}}}

function! s:echomsg(hl, msg) "{{{
    execute 'echohl' a:hl
    try
        echomsg a:msg
    finally
        echohl None
    endtry
endfunction "}}}

function! eskk#logger#warn(msg) "{{{
    call s:do_log(s:LOG_WARN, 'WarningMsg', a:msg)
endfunction "}}}
function! eskk#logger#warnf(...) "{{{
    call eskk#logger#warn(call('printf', a:000))
endfunction "}}}

function! eskk#logger#info(msg) "{{{
    call s:do_log(s:LOG_INFO, 'WarningMsg', a:msg)
endfunction "}}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

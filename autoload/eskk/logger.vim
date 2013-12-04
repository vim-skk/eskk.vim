" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


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
        call add(lines, printf('"uname -a" = %s', system('uname -a')))
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
        call eskk#logger#logf("Cannot write to log file '%s'.", log_file)
    endtry

    let save_cmdheight = &cmdheight
    setlocal cmdheight=3
    try
        call eskk#logger#errorf(
        \   "Error!! See %s for details.",
        \   (write_success ? string(log_file) : ':messages')
        \)
    finally
        let &cmdheight = save_cmdheight
    endtry
endfunction "}}}

function! eskk#logger#log(msg) "{{{
    if !g:eskk#debug
        return
    endif

    let msg = printf('[%s]::%s', strftime('%c'), a:msg)
    call add(s:warning_messages, msg)

    if eskk#is_initialized() && g:eskk#debug_wait_ms ># 0
        execute printf('sleep %dm', g:eskk#debug_wait_ms)
    endif
endfunction "}}}
function! eskk#logger#logf(...) "{{{
    call eskk#logger#log(call('printf', a:000))
endfunction "}}}
function! eskk#logger#logstrf(fmt, ...) "{{{
    return call(
    \   'eskk#logger#logf',
    \   [a:fmt] + map(copy(a:000), 'string(v:val)')
    \)
endfunction "}}}
function! eskk#logger#log_exception(what) "{{{
    call eskk#logger#log("'" . a:what . "' threw exception")
    call eskk#logger#log('v:exception = ' . string(v:exception))
    call eskk#logger#log('v:throwpoint = ' . string(v:throwpoint))
endfunction "}}}

function! eskk#logger#warnlog(msg) "{{{
    call eskk#logger#warn(a:msg)
    call eskk#logger#log(a:msg)
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
    call s:echomsg('WarningMsg', a:msg)
    call eskk#logger#log(a:msg)
endfunction "}}}
function! eskk#logger#warnf(...) "{{{
    call eskk#logger#warn(call('printf', a:000))
endfunction "}}}

function! eskk#logger#error(msg) "{{{
    call s:echomsg('ErrorMsg', a:msg)
    call eskk#logger#log(a:msg)
endfunction "}}}
function! eskk#logger#errorf(...) "{{{
    call eskk#logger#error(call('printf', a:000))
endfunction "}}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

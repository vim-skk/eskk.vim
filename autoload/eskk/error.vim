" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:warning_messages = []

function! eskk#error#write_to_log_file() "{{{
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
    redir END
endfunction "}}}

function! eskk#error#log(msg) "{{{
    if !g:eskk#debug
        return
    endif
    if !eskk#is_initialized()
        call eskk#register_temp_event(
        \   'enable-im',
        \   'eskk#error#log',
        \   [a:msg]
        \)
        return
    endif

    redraw

    let msg = printf('[%s]::%s', strftime('%c'), a:msg)
    if g:eskk#debug_out ==# 'file'
        call add(s:warning_messages, msg)
    elseif g:eskk#debug_out ==# 'cmdline'
        call eskk#util#warn(msg)
    endif

    if g:eskk#debug_wait_ms !=# 0
        execute printf('sleep %dm', g:eskk#debug_wait_ms)
    endif
endfunction "}}}
function! eskk#error#logf(fmt, ...) "{{{
    call eskk#error#log(call('printf', [a:fmt] + a:000))
endfunction "}}}
function! eskk#error#logstrf(fmt, ...) "{{{
    return call(
    \   'eskk#error#logf',
    \   [a:fmt] + map(copy(a:000), 'string(v:val)')
    \)
endfunction "}}}
function! eskk#error#log_exception(what) "{{{
    call eskk#error#log("'" . a:what . "' throwed exception")
    call eskk#error#log('v:exception = ' . string(v:exception))
    call eskk#error#log('v:throwpoint = ' . string(v:throwpoint))
endfunction "}}}

function! eskk#error#build_error(from, msg_list) "{{{
    let file = 'autoload/' . join(a:from, '/') . '.vim'
    return 'eskk: ' . join(a:msg_list, ': ') . ' (at ' . file . ')'
endfunction "}}}

function! eskk#error#assert(cond, ...) "{{{
    if !a:cond
        throw call('eskk#error#assertion_failure_error', a:000)
    endif
endfunction "}}}
function! eskk#error#assertion_failure_error(from, ...) "{{{
    " This is only used from eskk#error#assert().
    return eskk#error#build_error(
    \   ['eskk', 'error'],
    \   ['assertion failed'] + a:000
    \)
endfunction "}}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

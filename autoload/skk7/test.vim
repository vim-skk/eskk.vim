" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Variables {{{

let skk7#test#ok_ok_str = 'ok'
let skk7#test#ok_not_ok_str = 'NOT ok'
let skk7#test#is_ok_str = 'ok'
let skk7#test#is_not_ok_str = 'got: %s, expected: %s'
let skk7#test#back_to_start_of_line = 1
let skk7#test#test_dir = './test'

let s:current_test_num = 1

" }}}


" Functions {{{

func! skk7#test#run() "{{{
    let tested = 0
    for t in s:glob(printf('%s/*.vim', g:skk7#test#test_dir))
        source t
        let tested = 1
    endfor

    if !tested
        echohl WarningMsg
        echomsg 'no tests to run.'
        echohl None
    endif
endfunc "}}}

func! s:glob(expr) "{{{
    return split(glob(a:expr), "\n")
endfunc "}}}


func! skk7#test#ok(cond, ...) "{{{
    let testname = a:0 != 0 ? printf('%s:', a:1) : ''

    let str =
    \   g:skk7#test#back_to_start_of_line ?
    \       "\r"
    \       : ''
    \   s:current_test_num
    \   '...'
    \   g:skk7#test#{a:cond ? 'ok_ok_str' : 'ok_not_ok_str'}
    echon str
    let s:current_test_num += 1
endfunc "}}}

func! skk7#test#is(got, expected, ...) "{{{
    let testname = a:0 != 0 ? printf('%s:', a:1) : ''

    let str =
    \   g:skk7#test#back_to_start_of_line ?
    \       "\r"
    \       : ''
    \   s:current_test_num
    \   '...'
    \   a:got ==# a:expected ?
    \       g:skk7#test#is_ok_str
    \       : printf(
    \           g:skk7#test#is_not_ok_str,
    \           string(a:got),
    \           string(a:expected))
    echon str
    let s:current_test_num += 1
endfunc "}}}

func! s:begin_test() "{{{
    let s:current_test_num = 1
endfunc "}}}

func! s:end_test() "{{{
    let s:current_test_num = 1
    echomsg 'Done.'
endfunc "}}}

" }}}


" Commands {{{

command! Skk7TestBegin
\   call s:begin_test()

command! Skk7TestEnd
\   call s:end_test()

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

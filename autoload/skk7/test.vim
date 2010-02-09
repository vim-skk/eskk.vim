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
let skk7#test#test_dir = '.'

let s:current_test_num = 1

" }}}


" Functions {{{

" I do not use skk7#util#warn()
" because I want to upload this test library
" to www.vim.org indivisually.
func! s:warn(...) "{{{
    echohl WarningMsg
    echomsg join(a:000, ' ')
    echohl None
endfunc "}}}

func! skk7#test#run() "{{{
    let tested = 0
    for t in s:glob(printf('%s/*.vim', g:skk7#test#test_dir))
        echomsg 'begin test:' t
        execute 'source' t
        let tested = 1
    endfor

    if !tested
        call s:warn('no tests to run.')
    endif
endfunc "}}}

func! s:glob(expr) "{{{
    return split(glob(a:expr), "\n")
endfunc "}}}


func! skk7#test#ok(cond, ...) "{{{
    let testname = a:0 != 0 ? a:1 : ''

    if a:cond
        echomsg printf(
        \   '%d. %s ... %s',
        \   s:current_test_num,
        \   testname,
        \   g:skk7#test#ok_ok_str
        \)
    else
        call s:warn(
        \   printf(
        \      '%d. %s ... %s',
        \      s:current_test_num,
        \      testname,
        \      g:skk7#test#ok_not_ok_str
        \   )
        \)
    endif

    let s:current_test_num += 1
endfunc "}}}

func! skk7#test#is(got, expected, ...) "{{{
    let testname = a:0 != 0 ? a:1 : ''

    if a:got ==# a:expected
        echomsg printf(
        \   '%d. %s ... %s',
        \   s:current_test_num,
        \   testname,
        \   g:skk7#test#is_ok_str
        \)
    else
        call s:warn(
        \   printf(
        \      '%d. %s ... %s',
        \      s:current_test_num,
        \      testname,
        \      printf(
        \          g:skk7#test#is_not_ok_str,
        \          string(a:got),
        \          string(a:expected))
        \   )
        \)
    endif

    let s:current_test_num += 1
endfunc "}}}

func! skk7#test#diag(msg) "{{{
    call s:warn('#', a:msg)
endfunc "}}}


func! skk7#test#exists_func(Fn, ...) "{{{
    let args = a:0 != 0 ? a:1 : []

    try
        call call(a:Fn, args)
        return 1
    catch /E116:/
        return 0
    catch /E117:/    " 未知の関数です
        return 0
    catch /E118:/
        return 0
    catch /E119:/    " 関数の引数が少な過ぎます
        return 1
    catch /E120:/
        return 0
    endtry
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

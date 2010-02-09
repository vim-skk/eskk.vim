" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


silent! delfunc FuncForTest
silent! delfunc FuncForTestHoge

func! FuncForTest()
    " Function for testing if this is callable.
    throw 'FuncForTestException'
endfunc


func! s:run()
    call skk7#test#ok(skk7#util#is_callable('FuncForTest'), 'FuncForTest() is callable')
    call skk7#test#ok(! skk7#util#is_callable('FuncForTestHoge'), 'FuncForTestHoge() is not callable')

    try
        call skk7#util#call_if_exists('FuncForTest', [])
        call skk7#test#ok(0, 'FuncForTest() throws exception')
    catch /^FuncForTestException$/
        call skk7#test#ok(1, 'FuncForTest() throws exception')
    endtry

    try
        call skk7#util#call_if_exists('FuncForTestHoge', [])
        call skk7#test#ok(0, 'FuncForTestHoge() does not exist')
    catch
        call skk7#test#ok(1, 'FuncForTestHoge() does not exist')
    endtry

    call skk7#test#is(
    \   skk7#util#call_if_exists(
    \       'FuncForTestHoge',
    \       [],
    \       0
    \   ),
    \   0,
    \   "skk7#util#call_if_exists()'s arg 3 is for return value"
    \)
endfunc


Skk7TestBegin
call s:run()
Skk7TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

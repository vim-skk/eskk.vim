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
    call simpletap#ok(eskk#util#is_callable('FuncForTest'), 'FuncForTest() is callable')
    call simpletap#ok(! eskk#util#is_callable('FuncForTestHoge'), 'FuncForTestHoge() is not callable')

    try
        call eskk#util#call_if_exists('FuncForTest', [])
        call simpletap#ok(0, 'FuncForTest() throws exception')
    catch /^FuncForTestException$/
        call simpletap#ok(1, 'FuncForTest() throws exception')
    endtry

    try
        call eskk#util#call_if_exists('FuncForTestHoge', [])
        call simpletap#ok(0, 'FuncForTestHoge() does not exist')
    catch
        call simpletap#ok(1, 'FuncForTestHoge() does not exist')
    endtry

    call simpletap#is(
    \   eskk#util#call_if_exists(
    \       'FuncForTestHoge',
    \       [],
    \       0
    \   ),
    \   0,
    \   "eskk#util#call_if_exists()'s arg 3 is for return value"
    \)
endfunc


TestBegin
call s:run()
TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

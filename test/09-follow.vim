" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" TODO
" Test skk7#util#has_key_f().

func! s:run()
    " Dictionary
    call skk7#test#is(
    \   skk7#util#get_f(
    \       {'foo': 1},
    \       ['foo']
    \   ),
    \   1
    \)
    call skk7#test#is(
    \   skk7#util#get_f(
    \       {'foo': {'bar': 1}},
    \       ['foo', 'bar']
    \   ),
    \   1
    \)
    call skk7#test#is(
    \   skk7#util#get_f(
    \       {},
    \       ['foo'],
    \       1
    \   ),
    \   1
    \)

    " List
    call skk7#test#is(
    \   skk7#util#get_f(
    \       [1,2,3],
    \       [0]
    \   ),
    \   1
    \)
    call skk7#test#is(
    \   skk7#util#get_f(
    \       [[1], 2 ,3],
    \       [0, 0]
    \   ),
    \   1
    \)
    call skk7#test#is(
    \   skk7#util#get_f(
    \       [1],
    \       [1],
    \       1
    \   ),
    \   1
    \)

    try
        call skk7#util#get_f(
        \   {'foo': 1},
        \   [],
        \)
        call skk7#test#ok(0, 'raise error')
    catch
        call skk7#test#ok(1, 'raise error')
    endtry

    try
        call skk7#util#get_f(
        \   {},
        \   ['foo'],
        \)
        call skk7#test#ok(0, 'raise error')
    catch
        call skk7#test#ok(1, 'raise error')
    endtry

    try
        call skk7#util#get_f(
            {},
            ['foo', 'bar'],
        )
        call skk7#test#ok(0, 'raise error')
    catch
        call skk7#test#ok(1, 'raise error')
    endtry

endfunc


Skk7TestBegin
call s:run()
Skk7TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}



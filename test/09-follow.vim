" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" TODO
" Test eskk#util#has_key_f().

func! s:run()
    " Dictionary
    call simpletap#is(
    \   eskk#util#get_f(
    \       {'foo': 1},
    \       ['foo']
    \   ),
    \   1
    \)
    call simpletap#is(
    \   eskk#util#get_f(
    \       {'foo': {'bar': 1}},
    \       ['foo', 'bar']
    \   ),
    \   1
    \)
    call simpletap#is(
    \   eskk#util#get_f(
    \       {},
    \       ['foo'],
    \       1
    \   ),
    \   1
    \)

    " List
    call simpletap#is(
    \   eskk#util#get_f(
    \       [1,2,3],
    \       [0]
    \   ),
    \   1
    \)
    call simpletap#is(
    \   eskk#util#get_f(
    \       [[1], 2 ,3],
    \       [0, 0]
    \   ),
    \   1
    \)
    call simpletap#is(
    \   eskk#util#get_f(
    \       [1],
    \       [1],
    \       1
    \   ),
    \   1
    \)

    " TODO Use simpletap#throws_ok() or simpletap#ok().

    try
        call eskk#util#get_f(
        \   {'foo': 1},
        \   [],
        \)
        call simpletap#ok(0, 'raise error')
    catch
        call simpletap#ok(1, 'raise error')
    endtry

    try
        call eskk#util#get_f(
        \   {},
        \   ['foo'],
        \)
        call simpletap#ok(0, 'raise error')
    catch
        call simpletap#ok(1, 'raise error')
    endtry

    try
        call eskk#util#get_f(
            {},
            ['foo', 'bar'],
        )
        call simpletap#ok(0, 'raise error')
    catch
        call simpletap#ok(1, 'raise error')
    endtry

endfunc


call s:run()


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}



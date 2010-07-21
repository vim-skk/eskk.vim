" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:run()
    " Dictionary
    Is
    \   eskk#util#get_f(
    \       {'foo': 1},
    \       ['foo']
    \   ),
    \   1
    Ok
    \   eskk#util#has_key_f(
    \       {'foo': 1},
    \       ['foo']
    \   ),

    let dict = {'foo': 1}
    Is
    \   eskk#util#let_f(
    \       dict,
    \       ['foo'],
    \       2
    \   ),
    \   1
    Ok has_key(dict, 'foo') && dict.foo ==# 1
    let dict = {}
    Is
    \   eskk#util#let_f(
    \       dict,
    \       ['foo'],
    \       2
    \   ),
    \   2
    Ok has_key(dict, 'foo') && dict.foo ==# 2

    Is
    \   eskk#util#get_f(
    \       {'foo': {'bar': 1}},
    \       ['foo', 'bar']
    \   ),
    \   1
    Ok
    \   eskk#util#has_key_f(
    \       {'foo': {'bar': 1}},
    \       ['foo', 'bar']
    \   ),

    Is
    \   eskk#util#get_f(
    \       {},
    \       ['foo'],
    \       1
    \   ),
    \   1
    Ok
    \   ! eskk#util#has_key_f(
    \       {},
    \       ['foo'],
    \   ),

    " List
    Is
    \   eskk#util#get_f(
    \       [1,2,3],
    \       [0]
    \   ),
    \   1
    Ok
    \   eskk#util#has_key_f(
    \       [1,2,3],
    \       [0]
    \   ),

    Is
    \   eskk#util#get_f(
    \       [[1], 2 ,3],
    \       [0, 0]
    \   ),
    \   1
    Ok
    \   eskk#util#has_key_f(
    \       [[1], 2 ,3],
    \       [0, 0]
    \   ),

    Is
    \   eskk#util#get_f(
    \       [1],
    \       [1],
    \       2
    \   ),
    \   2
    Ok
    \   ! eskk#util#has_key_f(
    \       [1],
    \       [1],
    \   ),


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

endfunction


call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

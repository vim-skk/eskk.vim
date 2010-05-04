" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    call simpletap#is(
    \   eskk#util#eval_key('<CR>'),
    \   "\<CR>"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('a<CR>'),
    \   "a\<CR>"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('<CR>b'),
    \   "\<CR>b"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('a<CR>b'),
    \   "a\<CR>b"
    \)

    call simpletap#is(
    \   eskk#util#eval_key('<lt>CR>'),
    \   "<CR>"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('a<lt>CR>'),
    \   "a<CR>"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('<lt>CR>b'),
    \   "<CR>b"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('a<lt>CR>b'),
    \   "a<CR>b"
    \)

    call simpletap#is(
    \   eskk#util#eval_key('<Plug>(eskk:enable)'),
    \   "\<Plug>(eskk:enable)"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('a<Plug>(eskk:enable)'),
    \   "a\<Plug>(eskk:enable)"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('<Plug>(eskk:enable)b'),
    \   "\<Plug>(eskk:enable)b"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('a<Plug>(eskk:enable)b'),
    \   "a\<Plug>(eskk:enable)b"
    \)

    call simpletap#is(
    \   eskk#util#eval_key('abc'),
    \   "abc"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('<'),
    \   "<"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('<>'),
    \   "<>"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('<tes'),
    \   "<tes"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('tes>'),
    \   "tes>"
    \)
    call simpletap#is(
    \   eskk#util#eval_key('<tes>'),
    \   "<tes>"
    \)
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



func! s:run()
    call skk7#test#is(
    \   skk7#util#eval_key('<CR>'),
    \   "\<CR>"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('a<CR>'),
    \   "a\<CR>"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('<CR>b'),
    \   "\<CR>b"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('a<CR>b'),
    \   "a\<CR>b"
    \)

    call skk7#test#is(
    \   skk7#util#eval_key('<lt>CR>'),
    \   "<CR>"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('a<lt>CR>'),
    \   "a<CR>"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('<lt>CR>b'),
    \   "<CR>b"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('a<lt>CR>b'),
    \   "a<CR>b"
    \)

    call skk7#test#is(
    \   skk7#util#eval_key('<Plug>(skk7-enable)'),
    \   "\<Plug>(skk7-enable)"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('a<Plug>(skk7-enable)'),
    \   "a\<Plug>(skk7-enable)"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('<Plug>(skk7-enable)b'),
    \   "\<Plug>(skk7-enable)b"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('a<Plug>(skk7-enable)b'),
    \   "a\<Plug>(skk7-enable)b"
    \)

    call skk7#test#is(
    \   skk7#util#eval_key('abc'),
    \   "abc"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('<'),
    \   "<"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('<>'),
    \   "<>"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('<tes'),
    \   "<tes"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('tes>'),
    \   "tes>"
    \)
    call skk7#test#is(
    \   skk7#util#eval_key('<tes>'),
    \   "<tes>"
    \)
endfunc

Skk7TestBegin
call s:run()
Skk7TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

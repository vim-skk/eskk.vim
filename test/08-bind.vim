" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



func! s:run()
    call skk7#test#is(
    \   skk7#util#bind('%1%', 'hello'),
    \   string('hello')
    \)
    call skk7#test#is(
    \   skk7#util#bind('%1% world', 'hello'),
    \   printf('%s world', string('hello'))
    \)
    call skk7#test#is(
    \   skk7#util#bind('hey %1%', 'hello'),
    \   printf('hey %s', string('hello'))
    \)
    call skk7#test#is(
    \   skk7#util#bind('hey %2%', 'hello'),
    \   'hey %2%'
    \)
    call skk7#test#is(
    \   skk7#util#bind('hey %1% %1%', 'hello'),
    \   printf('hey %s %s', string('hello'), string('hello'))
    \)
endfunc


Skk7TestBegin
call s:run()
Skk7TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}


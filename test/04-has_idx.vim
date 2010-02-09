" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


func! s:run()
    call skk7#test#ok(skk7#util#has_idx([0], 0))
    call skk7#test#ok(! skk7#util#has_idx([0], 1))

    call skk7#test#ok(skk7#util#has_idx([0], -1))
    call skk7#test#ok(! skk7#util#has_idx([0], -2))
endfunc


Skk7TestBegin
call s:run()
Skk7TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:run()
  call simpletap#ok(eskk#util#has_idx([0], 0))
  call simpletap#ok(! eskk#util#has_idx([0], 1))

  " The followings should not be allowed!
  " call simpletap#ok(eskk#util#has_idx([0], -1))
  " call simpletap#ok(! eskk#util#has_idx([0], -2))
endfunction


call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

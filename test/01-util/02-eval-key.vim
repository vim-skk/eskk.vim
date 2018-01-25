" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
  call simpletap#is(
        \   eskk#util#key2char('<CR>'),
        \   "\<CR>"
        \)
  call simpletap#is(
        \   eskk#util#key2char('a<CR>'),
        \   "a\<CR>"
        \)
  call simpletap#is(
        \   eskk#util#key2char('<CR>b'),
        \   "\<CR>b"
        \)
  call simpletap#is(
        \   eskk#util#key2char('a<CR>b'),
        \   "a\<CR>b"
        \)

  call simpletap#is(
        \   eskk#util#key2char('<lt>CR>'),
        \   "<CR>"
        \)
  call simpletap#is(
        \   eskk#util#key2char('a<lt>CR>'),
        \   "a<CR>"
        \)
  call simpletap#is(
        \   eskk#util#key2char('<lt>CR>b'),
        \   "<CR>b"
        \)
  call simpletap#is(
        \   eskk#util#key2char('a<lt>CR>b'),
        \   "a<CR>b"
        \)

  call simpletap#is(
        \   eskk#util#key2char('<Plug>(eskk:enable)'),
        \   "\<Plug>(eskk:enable)"
        \)
  call simpletap#is(
        \   eskk#util#key2char('a<Plug>(eskk:enable)'),
        \   "a\<Plug>(eskk:enable)"
        \)
  call simpletap#is(
        \   eskk#util#key2char('<Plug>(eskk:enable)b'),
        \   "\<Plug>(eskk:enable)b"
        \)
  call simpletap#is(
        \   eskk#util#key2char('a<Plug>(eskk:enable)b'),
        \   "a\<Plug>(eskk:enable)b"
        \)

  call simpletap#is(
        \   eskk#util#key2char('abc'),
        \   "abc"
        \)
  call simpletap#is(
        \   eskk#util#key2char('<'),
        \   "<"
        \)
  call simpletap#is(
        \   eskk#util#key2char('<>'),
        \   "<>"
        \)
  call simpletap#is(
        \   eskk#util#key2char('<tes'),
        \   "<tes"
        \)
  call simpletap#is(
        \   eskk#util#key2char('tes>'),
        \   "tes>"
        \)
  call simpletap#is(
        \   eskk#util#key2char('<tes>'),
        \   "<tes>"
        \)
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

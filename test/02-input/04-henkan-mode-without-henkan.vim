" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:egg_like_newline() "{{{
  return g:eskk#egg_like_newline ? "\<CR>" : "\<CR>\<CR>"
endfunction "}}}

function! s:do_test() "{{{
  let cr = g:eskk#egg_like_newline ? '' : "\<CR>"
  for [l, r] in [
        \   [";a\<CR>", 'あ'.cr],
        \   [";sa\<CR>", 'さ'.cr],
        \   [" ;sa\<CR>", ' さ'.cr],
        \   [";sa\<CR> ", 'さ'.cr.' '],
        \   [" ;na\<CR>", ' な'.cr],
        \   [" ;nna\<CR>", ' んあ'.cr],
        \   [" ;nnna\<CR>", ' んな'.cr],
        \   [";na\<CR> ", 'な'.cr.' '],
        \   [";tty\<CR>", 'っty'.cr],
        \   [" ;ka\<CR>", ' か'.cr],
        \   [";&ka\<CR>", '&か'.cr],
        \]
    Diag 'g:eskk#egg_like_newline = ' . g:eskk#egg_like_newline
    Is eskk#test#emulate_filter_keys(l), r,
          \   string(l).' => '.string(r)
  endfor
endfunction "}}}

function! s:create_map_and_test(lhs, rhs) "{{{
  let map = savemap#save_map('i', a:lhs)
  execute 'inoremap' a:lhs a:rhs
  try
    call s:do_test()
  finally
    call map.restore()
  endtry
endfunction "}}}

function! s:run() "{{{
  if globpath(&rtp, 'autoload/savemap.vim') ==# ''
    Skip "you must install savemap.vim to run this test."
  endif

  let script = '04-henkan-mode-without-henkan'
  Diag script . ' - This test must NOT show prompt. '
        \   . 'please report if you met a prompt message '
        \   . 'during this test.'

  let save_eln = g:eskk#egg_like_newline
  for eln in [1,0]
    let g:eskk#egg_like_newline = eln
    call s:create_map_and_test('<C-g>', 'foo')
    call s:create_map_and_test('<C-g>u', 'bar')
  endfor
  let g:eskk#egg_like_newline = save_eln

  Diag script . ' - done.'
endfunction "}}}

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

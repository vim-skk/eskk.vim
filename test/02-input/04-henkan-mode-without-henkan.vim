" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:do_test() "{{{
    for [l, r] in [
    \   [";a\<CR>", 'あ'],
    \   [";sa\<CR>", 'さ'],
    \   [" ;sa\<CR>", ' さ'],
    \   [";sa\<CR> ", 'さ '],
    \   [" ;na\<CR>", ' な'],
    \   [" ;nna\<CR>", ' んあ'],
    \   [" ;nnna\<CR>", ' んな'],
    \   [";na\<CR> ", 'な '],
    \   [";tty\<CR>", 'っty'],
    \   [" ;ka\<CR>", ' か'],
    \   [";&ka\<CR>", '&か'],
    \]
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
    if globpath(&rtp, 'autoload/savemap.vim') == ''
        Skip "you must install savemap.vim to run this test."
    endif

    let script = '04-henkan-mode-without-henkan'
    Diag script . ' - This test must NOT show prompt. '
    \   . 'please report if you met a prompt message '
    \   . 'during this test.'

    call s:create_map_and_test('<C-g>', 'foo')
    call s:create_map_and_test('<C-g>u', 'bar')

    Diag script . ' - done.'
endfunction "}}}

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

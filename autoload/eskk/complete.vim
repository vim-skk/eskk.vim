" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Load once {{{
if exists('s:loaded')
    finish
endif
let s:loaded = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}
runtime! plugin/eskk.vim

" Complete function.
function! eskk#complete#eskkcomplete(findstart, base)"{{{
    if a:findstart
        return matchstr(s:get_cur_text(), g:eskk_marker_henkan . '.*$')
    endif

    " Test.
    return ['ほげ', 'ぴよ']
endfunction "}}}
function! s:get_cur_text()"{{{
    return col('.') < 2 ? '' : matchstr(getline('.'), '.*')[: col('.') - 2]
endfunction "}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

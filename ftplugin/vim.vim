" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if exists('g:loaded_eskk_vim_ftplugin') && g:loaded_eskk_vim_ftplugin
    finish
endif

" if exists("b:did_ftplugin")
"     finish
" endif
" let b:did_ftplugin = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



let b:eskk_context = {'synname': 'vimLineComment'}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

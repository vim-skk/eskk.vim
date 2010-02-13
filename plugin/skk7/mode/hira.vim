" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Load Once {{{
if exists('g:loaded_skk7_mode_hira') && g:loaded_skk7_mode_hira
    finish
endif
let g:loaded_skk7_mode_hira = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


call skk7#register_mode('hira')

" Global variables {{{
if !exists('g:skk7_mode_hira_no_default_mappings')
    let g:skk7_mode_hira_no_default_mappings = 0
endif
" }}}

" Mappings {{{
if g:skk7_mode_hira_no_default_mappings
    call skk7#map('q', '<Plug>(skk7-mode-to-kata)', 'hira')
    call skk7#map('l', '<Plug>(skk7-mode-to-ascii)', 'hira')
    call skk7#map('L', '<Plug>(skk7-mode-to-zenei)', 'hira')
endif
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

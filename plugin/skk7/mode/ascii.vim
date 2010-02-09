" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Load Once {{{
if exists('g:loaded_skk7_mode_ascii') && g:loaded_skk7_mode_ascii
    finish
endif
let g:loaded_skk7_mode_ascii = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Global variables {{{

if !exists('g:skk7_mode_ascii_no_default_mappings')
    let g:skk7_mode_ascii_no_default_mappings = 0
endif

" }}}

" Mappings {{{

lmap <expr> <Plug>(skk7-mode-ascii.enable)  skk7#mode#ascii#enable(0)

if g:skk7_mode_ascii_no_default_mappings
    lmap l      <Plug>(skk7-mode-ascii.enable)
endif
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

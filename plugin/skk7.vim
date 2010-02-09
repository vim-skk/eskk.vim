" vim:foldmethod=marker:fen:
scriptencoding utf-8

" License is Public Domain.

" Change Log: {{{
" }}}
" Document {{{
"
" Name: skk7
" Version: 0.0.0
" Author:  tyru <tyru.exe@gmail.com>
" Last Change: 2010-02-09.
"
" Description:
"   NO DESCRIPTION YET
"
" Usage: {{{
"   Commands: {{{
"   }}}
"   Mappings: {{{
"   }}}
"   Global Variables: {{{
"   }}}
" }}}
" }}}

" Load Once {{{
if exists('g:loaded_skk7') && g:loaded_skk7
    finish
endif
let g:loaded_skk7 = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

;
" Scope Variables {{{
let s:debug_errmsg = []
" }}}
" Global Variables {{{

" Debug
if !exists('g:skk7_debug')
    let g:skk7_debug = 0
endif
if !exists('g:skk7_debug_wait_ms')
    let g:skk7_debug_wait_ms = 500
endif

" Mappings
if !exists('skk7_no_default_mappings')
    let skk7_no_default_mappings = 0
endif

" Misc.
if !exists('skk7_initial_mode')
    let skk7_initial_mode = 'hira'
endif
if !exists("skk7_marker_white")
  let skk7_marker_white = '▽'
endif
if !exists("skk7_marker_black")
  let skk7_marker_black = '▼'
endif

" }}}

" Mappings {{{

noremap! <expr> <Plug>(skk7-enable)     skk7#enable()
noremap! <expr> <Plug>(skk7-disable)    skk7#disable()
noremap! <expr> <Plug>(skk7-toggle)     skk7#toggle()
lnoremap <expr> <Plug>(skk7-init-keys)  skk7#init_keys()
lnoremap <expr> <Plug>(skk7-sticky-key) skk7#sticky_key(0)

if !g:skk7_no_default_mappings
    map! <C-j>  <Plug>(skk7-toggle)
    lmap ;      <Plug>(skk7-sticky-key)
endif

" }}}

" Commands {{{

" :Skk7SetMode {{{

command!
\   -nargs=?
\   Skk7SetMode
\   call s:cmd_set_mode(<f-args>)

func! s:cmd_set_mode(...) "{{{
    if a:0 != 0
        if skk7#is_supported_mode(a:1)
            call skk7#set_mode(a:1)
        else
            call skk7#util#warnf("mode '%s' is not supported.", a:1)
            return
        endif
    endif
    echo skk7#get_mode()
endfunc "}}}

" }}}

" :Skk7Reset {{{

command!
\   Skk7Reset
\   call skk7#init_keys()

" }}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

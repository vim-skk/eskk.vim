" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'doc/eskk.txt'.

" Load Once {{{
if exists('g:loaded_eskk') && g:loaded_eskk
    finish
endif
let g:loaded_eskk = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Global Variables {{{

" Debug
if !exists('g:eskk_debug')
    let g:eskk_debug = 0
endif
if !exists('g:eskk_debug_wait_ms')
    let g:eskk_debug_wait_ms = 500
endif

" Dictionary
if !exists("g:eskk_dictionary")
  let g:eskk_dictionary = "~/.skk-jisyo"
endif
if !exists("g:eskk_backup_dictionary")
  let g:eskk_backup_dictionary = g:eskk_dictionary . ".BAK"
endif
if !exists("g:eskk_large_dictionary")
  let g:eskk_large_dictionary = "/usr/local/share/skk/SKK-JISYO.L"
endif

" Mappings
if !exists('g:eskk_no_default_mappings')
    let g:eskk_no_default_mappings = 0
endif
if !exists('g:eskk_mapped_key')
    let g:eskk_mapped_key = split(
    \   'abcdefghijklmnopqrstuvwxyz'
    \  .'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    \  .'1234567890'
    \  .'!"#$%&''()'
    \  .',./;:]@[-^\'
    \  .'>?_+*}`{=~'
    \   ,
    \   '\zs'
    \) + [
    \   "<lt>",
    \   "<Bar>",
    \   "<Tab>",
    \   "<BS>",
    \   "<C-h>",
    \]
endif

" Misc.
if !exists('g:eskk_initial_mode')
    let g:eskk_initial_mode = 'hira'
endif
if !exists("g:eskk_marker_henkan")
    let g:eskk_marker_henkan = '▽'
endif
if !exists("g:eskk_marker_okuri")
    let g:eskk_marker_okuri = '*'
endif
if !exists("g:eskk_marker_henkan_select")
    let g:eskk_marker_henkan_select = '▼'
endif
if !exists("g:eskk_marker_jisyo_touroku")
    let g:eskk_marker_jisyo_touroku = '?'
endif

" }}}

" Mappings {{{

noremap! <expr> <Plug>(eskk-enable)     eskk#enable()
noremap! <expr> <Plug>(eskk-disable)    eskk#disable()
noremap! <expr> <Plug>(eskk-toggle)     eskk#toggle()
lnoremap <expr> <Plug>(eskk-init-keys)  eskk#init_keys()
lnoremap <expr> <Plug>(eskk-sticky-key) eskk#sticky_key(0)

if !g:eskk_no_default_mappings
    map! <C-j>  <Plug>(eskk-toggle)
    lmap ;      <Plug>(eskk-sticky-key)
endif

" }}}

" Commands {{{

" :EskkSetMode {{{

command!
\   -nargs=?
\   EskkSetMode
\   call s:cmd_set_mode(<f-args>)

function! s:cmd_set_mode(...) "{{{
    if a:0 != 0
        if eskk#is_supported_mode(a:1)
            call eskk#set_mode(a:1)
        else
            call eskk#util#warnf("mode '%s' is not supported.", a:1)
            return
        endif
    endif
    echo eskk#get_mode()
endfunction "}}}

" }}}

" :EskkReset {{{

command!
\   EskkReset
\   call eskk#init_keys()

" }}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

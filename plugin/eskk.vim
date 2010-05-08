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
    let g:eskk_debug_wait_ms = 0
endif

" Dictionary
if !exists("g:eskk_dictionary")
  let g:eskk_dictionary = "~/.skk-jisyo"
endif
if type(g:eskk_dictionary) == type("")
    let s:temp = g:eskk_dictionary
    unlet g:eskk_dictionary
    let g:eskk_dictionary = {
    \   'path': s:temp,
    \   'sorted': 0,
    \   'encoding': 'utf-8',
    \}
    unlet s:temp
elseif type(g:eskk_dictionary) != type({})
    call eskk#util#warn(
    \   eskk#user_error(['eskk'], "g:eskk_dictionary's type is either String or Dictionary.")
    \)
endif


if !exists("g:eskk_large_dictionary")
  let g:eskk_large_dictionary = "/usr/local/share/skk/SKK-JISYO.L"
endif
if type(g:eskk_large_dictionary) == type("")
    let s:temp = g:eskk_large_dictionary
    unlet g:eskk_large_dictionary
    let g:eskk_large_dictionary = {
    \   'path': s:temp,
    \   'sorted': 1,
    \   'encoding': 'euc-jp',
    \}
    unlet s:temp
elseif type(g:eskk_large_dictionary) != type({})
    call eskk#util#warn(
    \   eskk#user_error(['eskk'], "g:eskk_large_dictionary's type is either String or Dictionary.")
    \)
endif

if !exists("g:eskk_backup_dictionary")
    let g:eskk_backup_dictionary = g:eskk_dictionary.path . ".BAK"
endif

" Mappings
if !exists('g:eskk_no_default_mappings')
    let g:eskk_no_default_mappings = 0
endif
if !exists('g:eskk_mapped_key')
    let g:eskk_mapped_key = eskk#default_mapped_keys()
endif

" Mode
if !exists('g:eskk_initial_mode')
    let g:eskk_initial_mode = 'hira'
endif

" Markers
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

" Misc.
if !exists("g:eskk_egg_like_newline")
    let g:eskk_egg_like_newline = 0
endif

" }}}

" Mappings {{{

noremap! <expr> <Plug>(eskk:enable)     eskk#enable()
lnoremap <expr> <Plug>(eskk:enable)     eskk#enable()

noremap! <expr> <Plug>(eskk:disable)    eskk#disable()
lnoremap <expr> <Plug>(eskk:disable)    eskk#disable()

noremap! <expr> <Plug>(eskk:toggle)     eskk#toggle()
lnoremap <expr> <Plug>(eskk:toggle)     eskk#toggle()

noremap! <expr> <Plug>(eskk:sticky-key) eskk#sticky_key(0, {})
lnoremap <expr> <Plug>(eskk:sticky-key) eskk#sticky_key(0, {})

noremap! <expr> <Plug>(eskk:henkan-key) eskk#filter(eskk#get_henkan_char())
lnoremap <expr> <Plug>(eskk:henkan-key) eskk#filter(eskk#get_henkan_char())

noremap! <expr> <Plug>(eskk:escape-key) eskk#escape_key()
lnoremap <expr> <Plug>(eskk:escape-key) eskk#escape_key()

if !g:eskk_no_default_mappings
    silent! map! <unique> <C-j>   <Plug>(eskk:toggle)
    silent! lmap <unique> <C-j>   <Plug>(eskk:toggle)
    silent! lmap <unique> ;       <Plug>(eskk:sticky-key)
    silent! lmap <unique> <Space> <Plug>(eskk:henkan-key)
    silent! lmap <unique> <Esc>   <Plug>(eskk:escape-key)
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

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

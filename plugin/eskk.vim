" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'doc/eskk.txt'.

let g:eskk_version = str2nr(printf('%2d%02d%03d', 0, 3, 58))

" Load Once {{{
if exists('g:loaded_eskk') && g:loaded_eskk
    finish
endif
let g:loaded_eskk = 1
" }}}
" g:eskk_disable {{{
if !exists('g:eskk_disable')
    let g:eskk_disable = 0
endif
if g:eskk_disable
    finish
endif
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

if !exists('g:eskk_debug_stdout')
    let g:eskk_debug_stdout = "file"
endif

if !exists('g:eskk_directory')
    let g:eskk_directory = '~/.eskk'
endif

" Dictionary
let s:default = {
\   'path': "~/.skk-jisyo",
\   'sorted': 0,
\   'encoding': 'utf-8',
\}
if exists('g:eskk_dictionary')
    if type(g:eskk_dictionary) == type("")
        let s:default.path = g:eskk_dictionary
        unlet g:eskk_dictionary
        let g:eskk_dictionary = s:default
    elseif type(g:eskk_dictionary) == type({})
        call extend(g:eskk_dictionary, s:default, "keep")
    else
        call eskk#util#warn(
        \   "g:eskk_dictionary's type is either String or Dictionary."
        \)
    endif
else
    let g:eskk_dictionary = s:default
endif
unlet s:default


let s:default = {
\   'path': "/usr/local/share/skk/SKK-JISYO.L",
\   'sorted': 1,
\   'encoding': 'euc-jp',
\}
if exists('g:eskk_large_dictionary')
    if type(g:eskk_large_dictionary) == type("")
        let s:default.path = g:eskk_large_dictionary
        unlet g:eskk_large_dictionary
        let g:eskk_large_dictionary = s:default
    elseif type(g:eskk_large_dictionary) == type({})
        call extend(g:eskk_large_dictionary, s:default, "keep")
    else
        call eskk#util#warn(
        \   "g:eskk_large_dictionary's type is either String or Dictionary."
        \)
    endif
else
    let g:eskk_large_dictionary = s:default
endif
unlet s:default


if !exists("g:eskk_backup_dictionary")
    let g:eskk_backup_dictionary = g:eskk_dictionary.path . ".BAK"
endif

if !exists("g:eskk_auto_save_dictionary_at_exit")
    let g:eskk_auto_save_dictionary_at_exit = 1
endif

" Henkan
if !exists("eskk_select_cand_keys")
  let eskk_select_cand_keys = "asdfjkl"
endif

if !exists("eskk_show_candidates_count")
  let eskk_show_candidates_count = 4
endif

if !exists("eskk_kata_convert_to_hira_at_henkan")
  let eskk_kata_convert_to_hira_at_henkan = 1
endif

if !exists("eskk_kata_convert_to_hira_at_completion")
  let eskk_kata_convert_to_hira_at_completion = 1
endif

if !exists("eskk_show_annotation")
  let eskk_show_annotation = 0
endif

" Mappings
if !exists('g:eskk_no_default_mappings')
    let g:eskk_no_default_mappings = 0
endif

if !exists('g:eskk_dont_map_default_if_already_mapped')
    let g:eskk_dont_map_default_if_already_mapped = 1
endif

function! EskkDefaultMappedKeys() "{{{
    return split(
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
    \   "<CR>",
    \   "<Space>",
    \   "<C-q>",
    \   "<C-y>",
    \   "<C-e>",
    \   "<PageUp>",
    \   "<PageDown>",
    \   "<Up>",
    \   "<Down>",
    \   "<C-n>",
    \   "<C-p>",
    \]
endfunction "}}}
if !exists('g:eskk_mapped_keys')
    let g:eskk_mapped_keys = EskkDefaultMappedKeys()
endif

" Mode
if !exists('g:eskk_initial_mode')
    let g:eskk_initial_mode = 'hira'
endif

if !exists('g:eskk_statusline_mode_strings')
    let g:eskk_statusline_mode_strings =  {'hira': 'あ', 'kata': 'ア', 'ascii': 'aA', 'zenei': 'ａ', 'hankata': 'ｧｱ', 'abbrev': 'aあ'}
endif

if !exists('g:eskk_mode_use_tables')
    let g:eskk_mode_use_tables =  {'hira': 'rom_to_hira', 'kata': 'rom_to_kata', 'zenei': 'rom_to_zenei', 'hankata': 'rom_to_hankata'}
endif

" Table
if !exists('g:eskk_cache_table_map')
    let g:eskk_cache_table_map = 1
endif

if !exists('g:eskk_cache_table_candidates')
    let g:eskk_cache_table_candidates = 1
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

if !exists("g:eskk_marker_popup")
    let g:eskk_marker_popup = '#'
endif

" Completion
if !exists('g:eskk_enable_completion')
    let g:eskk_enable_completion = 1
endif

if !exists('g:eskk_candidates_max')
    let g:eskk_candidates_max = 10
endif

" Cursor color
if !exists('g:eskk_use_color_cursor')
    let g:eskk_use_color_cursor = 1
endif

if !exists('g:eskk_cursor_color')
    " ascii: ivory4:#8b8b83, gray:#bebebe
    " hira: coral4:#8b3e2f, pink:#ffc0cb
    " kata: forestgreen:#228b22, green:#00ff00
    " abbrev: royalblue:#4169e1
    " zenei: gold:#ffd700
    let g:eskk_cursor_color = {
    \   'ascii': ['#8b8b83', '#bebebe'],
    \   'hira': ['#8b3e2f', '#ffc0cb'],
    \   'kata': ['#228b22', '#00ff00'],
    \   'abbrev': '#4169e1',
    \   'zenei': '#ffd700',
    \}
endif

" Misc.
if !exists("g:eskk_egg_like_newline")
    let g:eskk_egg_like_newline = 0
endif

if !exists("g:eskk_keep_state")
    let g:eskk_keep_state = 0
endif

if !exists('g:eskk_keep_state_beyond_buffer')
    let g:eskk_keep_state_beyond_buffer = 0
endif

if !exists("g:eskk_revert_henkan_style")
    let g:eskk_revert_henkan_style = 'okuri'
endif

if !exists("g:eskk_delete_implies_kakutei")
    let g:eskk_delete_implies_kakutei = 0
endif

if !exists("g:eskk_rom_input_style")
    let g:eskk_rom_input_style = 'skk'
endif

if !exists("g:eskk_auto_henkan_at_okuri_match")
    let g:eskk_auto_henkan_at_okuri_match = 1
endif

if !exists("g:eskk_set_undo_point")
    let g:eskk_set_undo_point = {
    \   'sticky': 1,
    \   'kakutei': 1,
    \}
endif

if !exists("g:eskk_context_control")
    let g:eskk_context_control = []
endif

if !exists("g:eskk_fix_extra_okuri")
    let g:eskk_fix_extra_okuri = 1
endif

if !exists('g:eskk_ignore_continuous_sticky')
    let g:eskk_ignore_continuous_sticky = 1
endif

if !exists('g:eskk_convert_at_exact_match')
    let g:eskk_convert_at_exact_match = 0
endif

" }}}

" Mappings {{{

noremap! <expr> <Plug>(eskk:enable)     eskk#enable()
lnoremap <expr> <Plug>(eskk:enable)     eskk#enable()

noremap! <expr> <Plug>(eskk:disable)    eskk#disable()
lnoremap <expr> <Plug>(eskk:disable)    eskk#disable()

noremap! <expr> <Plug>(eskk:toggle)     eskk#toggle()
lnoremap <expr> <Plug>(eskk:toggle)     eskk#toggle()

nnoremap        <Plug>(eskk:save-dictionary) :<C-u>call eskk#update_dictionary()<CR>

nnoremap <silent> <Plug>(eskk:alpha-t) :<C-u>call eskk#jump_one_char('t')<CR>
nnoremap <silent> <Plug>(eskk:alpha-f) :<C-u>call eskk#jump_one_char('f')<CR>
nnoremap <silent> <Plug>(eskk:alpha-T) :<C-u>call eskk#jump_one_char('T')<CR>
nnoremap <silent> <Plug>(eskk:alpha-F) :<C-u>call eskk#jump_one_char('F')<CR>
nnoremap <silent> <Plug>(eskk:alpha-,) :<C-u>call eskk#repeat_last_jump(',')<CR>
nnoremap <silent> <Plug>(eskk:alpha-;) :<C-u>call eskk#repeat_last_jump(';')<CR>

if !g:eskk_no_default_mappings
    function! s:do_map(rhs, mode)
        let map_default_even_if_already_mapped = !g:eskk_dont_map_default_if_already_mapped
        return
        \   map_default_even_if_already_mapped
        \   || !hasmapto(a:rhs, a:mode)
    endfunction

    if s:do_map('<Plug>(eskk:toggle)', 'i')
        silent! imap <unique> <C-j>   <Plug>(eskk:toggle)
    endif
    if s:do_map('<Plug>(eskk:toggle)', 'c')
        silent! cmap <unique> <C-j>   <Plug>(eskk:toggle)
    endif
    if s:do_map('<Plug>(eskk:toggle)', 'l')
        silent! lmap <unique> <C-j>   <Plug>(eskk:toggle)
    endif

    delfunc s:do_map
endif

" }}}

" Commands {{{

command!
\   -nargs=+
\   EskkMap
\   call eskk#_cmd_eskk_map(<q-args>)

command!
\   -bar
\   EskkForgetRegisteredWords
\   call eskk#forget_registered_words()

command!
\   -bar -bang
\   EskkUpdateDictionary
\   call eskk#update_dictionary(<bang>0)

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

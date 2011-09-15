" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    IsDeeply eskk#dictionary#parse_skk_dict_line(
    \   'かんがe /考/稽;<rare>/勘;<rare>/攷;<rare>/', -1
    \), [
    \   {'key': 'かんが', 'okuri_rom_first': 'e', 'from_type': -1, 'input': '考', 'annotation': ''},
    \   {'key': 'かんが', 'okuri_rom_first': 'e', 'from_type': -1, 'input': '稽', 'annotation': '<rare>'},
    \   {'key': 'かんが', 'okuri_rom_first': 'e', 'from_type': -1, 'input': '勘', 'annotation': '<rare>'},
    \   {'key': 'かんが', 'okuri_rom_first': 'e', 'from_type': -1, 'input': '攷', 'annotation': '<rare>'},
    \]

    IsDeeply eskk#dictionary#parse_skk_dict_line(
    \   'わんたんめん /雲呑麺/ワンタン麺/', -1
    \), [
    \   {'key': 'わんたんめん', 'okuri_rom_first': '', 'from_type': -1, 'input': '雲呑麺', 'annotation': ''},
    \   {'key': 'わんたんめん', 'okuri_rom_first': '', 'from_type': -1, 'input': 'ワンタン麺', 'annotation': ''},
    \]
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

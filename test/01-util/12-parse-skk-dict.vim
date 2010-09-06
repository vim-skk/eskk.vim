" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    IsDeeply eskk#dictionary#parse_skk_dict_line(
    \   'かんがe /考/稽;<rare>/勘;<rare>/攷;<rare>/', -1
    \), ['かんが', 'e', [
    \       {'has_okuri': 1, 'from_type': -1, 'input': '考'},
    \       {'has_okuri': 1, 'from_type': -1, 'input': '稽', 'annotation': '<rare>'},
    \       {'has_okuri': 1, 'from_type': -1, 'input': '勘', 'annotation': '<rare>'},
    \       {'has_okuri': 1, 'from_type': -1, 'input': '攷', 'annotation': '<rare>'},
    \   ]]

    IsDeeply eskk#dictionary#parse_skk_dict_line(
    \   'わんたんめん /雲呑麺/ワンタン麺/', -1
    \), ['わんたんめん', '', [
    \       {'has_okuri': 0, 'from_type': -1, 'input': '雲呑麺'},
    \       {'has_okuri': 0, 'from_type': -1, 'input': 'ワンタン麺'},
    \   ]]
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

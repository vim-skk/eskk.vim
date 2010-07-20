" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    IsDeeply eskk#dictionary#parse_skk_dict_line(
    \   'かんがe /考/稽;<rare>/勘;<rare>/攷;<rare>/'
    \), ['かんが', 'e', [
    \       {'result': '考'},
    \       {'result': '稽', 'annotation': '<rare>'},
    \       {'result': '勘', 'annotation': '<rare>'},
    \       {'result': '攷', 'annotation': '<rare>'},
    \   ]]

    IsDeeply eskk#dictionary#parse_skk_dict_line(
    \   'わんたんめん /雲呑麺/ワンタン麺/'
    \), ['わんたんめん', '', [
    \       {'result': '雲呑麺'},
    \       {'result': 'ワンタン麺'},
    \   ]]
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    Is eskk#emulate_filter_keys('qaq'), 'ア'
    Is eskk#emulate_filter_keys('qsq'), ''
    Is eskk#emulate_filter_keys("qasq"), "ア"
    Is eskk#emulate_filter_keys("qasaq"), "アサ"

    Is eskk#emulate_filter_keys(';aq'), 'ア'
    Is eskk#emulate_filter_keys(';sq'), ''
    Is eskk#emulate_filter_keys(";asq"), "ア"
    Is eskk#emulate_filter_keys(";asaq"), "アサ"
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

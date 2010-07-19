" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:do_general_test()
    Is eskk#emulate_filter_keys('a'), 'あ'
    Is eskk#emulate_filter_keys('sa'), 'さ'
    Is eskk#emulate_filter_keys(' sa'), ' さ'
    Is eskk#emulate_filter_keys('sa '), 'さ '
    Is eskk#emulate_filter_keys('sa '), 'さ '
    Is eskk#emulate_filter_keys('tty'), 'っty'
    Is eskk#emulate_filter_keys(' ka'), ' か'
    Is eskk#emulate_filter_keys('&ka'), '&か'
endfunction

function! s:do_test_skk()
    let g:eskk_rom_input_style = 'skk'

    call s:do_general_test()
    Is eskk#emulate_filter_keys('jka'), 'か'
    Is eskk#emulate_filter_keys('jkjka'), 'か'
    Is eskk#emulate_filter_keys('jkjkka'), 'っか'
endfunction

function! s:do_test_msime()
    let g:eskk_rom_input_style = 'msime'

    call s:do_general_test()
    Is eskk#emulate_filter_keys('jka'), 'jか'
    Is eskk#emulate_filter_keys('jkjka'), 'jkjか'
    Is eskk#emulate_filter_keys('jkjkka'), 'jkjっか'
endfunction

function! s:do_test_quickmatch()
    let g:eskk_rom_input_style = 'quickmatch'

    " TODO: Not implemented
endfunction

function! s:run()
    let original = g:eskk_rom_input_style

    try
        call s:do_test_skk()
        call s:do_test_msime()
        call s:do_test_quickmatch()
    finally
        let g:eskk_rom_input_style = original
    endtry
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

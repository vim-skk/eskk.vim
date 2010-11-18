" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:do_general_test()
    Is eskk#test#emulate_filter_keys('a'), 'あ', '"a" => "あ"'
    Is eskk#test#emulate_filter_keys('sa'), 'さ', '"sa" => "さ"'
    Is eskk#test#emulate_filter_keys(' sa'), ' さ', '" sa" => " さ"'
    Is eskk#test#emulate_filter_keys('sa '), 'さ ', '"sa " => "さ "'
    Is eskk#test#emulate_filter_keys('tty'), 'っty', '"tty" => "っty"'
    Is eskk#test#emulate_filter_keys(' ka'), ' か', '" ka" => " か"'
    Is eskk#test#emulate_filter_keys('&ka'), '&か', '"&ka" => "&か"'
endfunction

function! s:do_test_skk()
    let g:eskk#rom_input_style = 'skk'
    Diag 'let g:eskk#rom_input_style = "skk"'

    call s:do_general_test()
    Is eskk#test#emulate_filter_keys('jka'), 'か', '"jka" => "か"'
    Is eskk#test#emulate_filter_keys('jkjka'), 'か', '"jkjka" => "か"'
    Is eskk#test#emulate_filter_keys('jkjkka'), 'っか', '"jkjkka" => "っか"'
endfunction

function! s:do_test_msime()
    let g:eskk#rom_input_style = 'msime'
    Diag 'let g:eskk#rom_input_style = "msime"'

    call s:do_general_test()
    Is eskk#test#emulate_filter_keys('jka'), 'jか', '"jka" => "jか"'
    Is eskk#test#emulate_filter_keys('jkjka'), 'jkjか', '"jkjka" => "jkjか"'
    Is eskk#test#emulate_filter_keys('jkjkka'), 'jkjっか', '"jkjkka" => "jkjっか"'
endfunction

function! s:do_test_quickmatch()
    let g:eskk#rom_input_style = 'quickmatch'
    Diag 'let g:eskk#rom_input_style = "quickmatch"'

    " TODO: Not implemented
endfunction

function! s:run()
    let rom_input_style = g:eskk#rom_input_style
    let cache_table_map = g:eskk#cache_table_map

    try
        Diag 'let g:eskk#cache_table_map = 0'
        let g:eskk#cache_table_map = 0
        call s:do_test_skk()
        call s:do_test_msime()
        call s:do_test_quickmatch()

        Diag 'let g:eskk#cache_table_map = 1'
        let g:eskk#cache_table_map = 1
        call s:do_test_skk()
        call s:do_test_msime()
        call s:do_test_quickmatch()
    finally
        let g:eskk#rom_input_style = rom_input_style
        let g:eskk#cache_table_map = cache_table_map
    endtry
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

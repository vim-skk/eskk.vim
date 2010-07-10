" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    call eskk#enable()
    OK eskk#is_enabled()

    let buftable = eskk#get_buftable()

    Is eskk#emulate_filter_keys('', 1), ''
    Is eskk#emulate_filter_keys('a', 1), 'あ'
    Is eskk#emulate_filter_keys('sa', 1), 'さ'
    Is eskk#emulate_filter_keys('cha', 1), 'ちゃ'
    Is eskk#emulate_filter_keys('kanji', 1), 'かんじ'
    Is eskk#emulate_filter_keys('kannji', 1), 'かんじ'
    Is eskk#emulate_filter_keys('kannnji', 1), 'かんんじ'
    Is eskk#emulate_filter_keys("kanjin\<CR>", 1), "かんじん\<CR>"
    Is eskk#emulate_filter_keys("kannjin\<CR>", 1), "かんじん\<CR>"
    Is eskk#emulate_filter_keys('kanjinn', 1), 'かんじん'
    Is eskk#emulate_filter_keys('kannjinn', 1), 'かんじん'
    " Is eskk#emulate_filter_keys("hoge\<BS>", 1), 'ほ'
    Is eskk#emulate_filter_keys("hoge\<C-h>", 1), 'ほ'
    " Is eskk#emulate_filter_keys("hoge\<BS>fuga", 1), 'ほふが'
    Is eskk#emulate_filter_keys("hoge\<C-h>fuga", 1), 'ほふが'
    Is eskk#emulate_filter_keys("a\<C-h>", 1), ""
    Is eskk#emulate_filter_keys("a\<C-h>\<C-h>", 1), "\<C-h>"
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

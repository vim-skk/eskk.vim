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

    Is eskk#emulate_filter_keys(''), ''
    Is eskk#emulate_filter_keys('a'), 'あ'
    Is eskk#emulate_filter_keys("s"), "s"
    Is eskk#emulate_filter_keys('sa'), 'さ'
    Is eskk#emulate_filter_keys('cha'), 'ちゃ'
    Is eskk#emulate_filter_keys('kanji'), 'かんじ'
    Is eskk#emulate_filter_keys('kannji'), 'かんじ'
    Is eskk#emulate_filter_keys('kannnji'), 'かんんじ'
    Is eskk#emulate_filter_keys("kanjin\<CR>"), "かんじん\<CR>"
    Is eskk#emulate_filter_keys("kannjin\<CR>"), "かんじん\<CR>"
    Is eskk#emulate_filter_keys('kanjinn'), 'かんじん'
    Is eskk#emulate_filter_keys('kannjinn'), 'かんじん'
    " Is eskk#emulate_filter_keys("hoge\<BS>"), 'ほ'
    Is eskk#emulate_filter_keys("hoge\<C-h>"), 'ほ'
    " Is eskk#emulate_filter_keys("hoge\<BS>fuga"), 'ほふが'
    Is eskk#emulate_filter_keys("hoge\<C-h>fuga"), 'ほふが'
    Is eskk#emulate_filter_keys("a\<C-h>"), ""
    Is eskk#emulate_filter_keys("a\<C-h>\<C-h>"), "\<C-h>"
    Is eskk#emulate_filter_keys(" \<C-h>"), ""
    Is eskk#emulate_filter_keys(" \<C-h>\<C-h>"), "\<C-h>"
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

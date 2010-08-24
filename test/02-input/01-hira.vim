" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    Is eskk#test#emulate_filter_keys(''), ''
    Is eskk#test#emulate_filter_keys('a'), 'あ'
    Is eskk#test#emulate_filter_keys("s"), "s"
    Is eskk#test#emulate_filter_keys('sa'), 'さ'
    Is eskk#test#emulate_filter_keys('cha'), 'ちゃ'
    Is eskk#test#emulate_filter_keys('kanji'), 'かんじ'
    Is eskk#test#emulate_filter_keys('kannji'), 'かんじ'
    Is eskk#test#emulate_filter_keys('kannnji'), 'かんんじ'
    Is eskk#test#emulate_filter_keys("kanjin\<CR>"), "かんじん\<CR>"
    Is eskk#test#emulate_filter_keys("kannjin\<CR>"), "かんじん\<CR>"
    Is eskk#test#emulate_filter_keys('kanjinn'), 'かんじん'
    Is eskk#test#emulate_filter_keys('kannjinn'), 'かんじん'
    " Is eskk#test#emulate_filter_keys("hoge\<BS>"), 'ほ'
    Is eskk#test#emulate_filter_keys("hoge\<C-h>"), 'ほ'
    " Is eskk#test#emulate_filter_keys("hoge\<BS>fuga"), 'ほふが'
    Is eskk#test#emulate_filter_keys("hoge\<C-h>fuga"), 'ほふが'
    Is eskk#test#emulate_filter_keys("a\<C-h>"), ""
    Is eskk#test#emulate_filter_keys("a\<C-h>\<C-h>"), "\<C-h>"
    Is eskk#test#emulate_filter_keys(" \<C-h>"), ""
    Is eskk#test#emulate_filter_keys(" \<C-h>\<C-h>"), "\<C-h>"
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

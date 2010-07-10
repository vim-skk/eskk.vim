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
    call buftable.clear_all()
    Is eskk#emulate_filter_keys('a'), 'あ'
    call buftable.clear_all()
    Is eskk#emulate_filter_keys('sa'), 'さ'
    call buftable.clear_all()
    Is eskk#emulate_filter_keys('cha'), 'ちゃ'
    call buftable.clear_all()
    Is eskk#emulate_filter_keys('kanji'), 'かんじ'
    call buftable.clear_all()
    Is eskk#emulate_filter_keys('kannji'), 'かんじ'
    call buftable.clear_all()
    Is eskk#emulate_filter_keys('kannnji'), 'かんんじ'
    call buftable.clear_all()
    Is eskk#emulate_filter_keys("kanjin\<CR>"), "かんじん\<CR>"
    call buftable.clear_all()
    Is eskk#emulate_filter_keys("kannjin\<CR>"), "かんじん\<CR>"
    call buftable.clear_all()
    Is eskk#emulate_filter_keys('kanjinn'), 'かんじん'
    call buftable.clear_all()
    Is eskk#emulate_filter_keys('kannjinn'), 'かんじん'
    call buftable.clear_all()
    " Is eskk#emulate_filter_keys("hoge\<BS>"), 'ほ'
    " call buftable.clear_all()
    Is eskk#emulate_filter_keys("hoge\<C-h>"), 'ほ'
    call buftable.clear_all()
    " Is eskk#emulate_filter_keys("hoge\<BS>fuga"), 'ほふが'
    " call buftable.clear_all()
    Is eskk#emulate_filter_keys("hoge\<C-h>fuga"), 'ほふが'
    call buftable.clear_all()
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

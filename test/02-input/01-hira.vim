" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    for [l, r] in [
    \   ['', ''],
    \   ['a', 'あ'],
    \   ['s', 's'],
    \   ['sa', 'さ'],
    \   ['cha', 'ちゃ'],
    \   ['kanji', 'かんじ'],
    \   ['kannji', 'かんじ'],
    \   ['kannnji', 'かんんじ'],
    \   ["kanjin\<CR>", "かんじん\<CR>"],
    \   ["kannjin\<CR>", "かんじん\<CR>"],
    \   ['kanjinn', "かんじん"],
    \   ['kannjinn', "かんじん"],
    \   ["hoge\<BS>", "ほ"],
    \   ["hoge\<C-h>", "ほ"],
    \   ["hoge\<BS>fuga", "ほふが"],
    \   ["hoge\<C-h>fuga", "ほふが"],
    \   ["a\<C-h>", ""],
    \   ["a\<C-h>\<C-h>", "\<C-h>"],
    \   [" \<C-h>", ""],
    \   [" \<C-h>\<C-h>", "\<C-h>"],
    \]
        Is eskk#test#emulate_filter_keys(l), r,
        \   string(l).' => '.string(r)
    endfor
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

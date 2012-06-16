" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:egg_like_newline()
    return g:eskk#egg_like_newline ? "\<CR>" : "\<CR>\<CR>"
endfunction

function! s:run()
    let save_eln = g:eskk#egg_like_newline
    try
        let g:eskk#egg_like_newline = 1
        call s:do_test()
        let g:eskk#egg_like_newline = 0
        call s:do_test()
    finally
        let g:eskk#egg_like_newline = save_eln
    endtry
endfunction

function! s:do_test()
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
    \   [";kanjin\<CR>", "かんじん" . (g:eskk#egg_like_newline ? "" : "\<CR>")],
    \   [";kannjin\<CR>", "かんじん" . (g:eskk#egg_like_newline ? "" : "\<CR>")],
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
    \   [" \<BS>", ""],
    \   [" \<BS>\<BS>", "\<C-h>"],
    \]
        Is eskk#test#emulate_filter_keys(l), r,
        \   string(l).' => '.string(r)
        Is eskk#test#emulate_filter_keys(l), r,
        \   string(l).' => '.string(r)
    endfor
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

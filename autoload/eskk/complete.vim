" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Load once {{{
if exists('s:loaded')
    finish
endif
let s:loaded = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}
runtime! plugin/eskk.vim

" Complete function.
function! eskk#complete#eskkcomplete(findstart, base) "{{{
    if a:findstart
        let buftable = eskk#get_buftable()
        let [mode, pos] = buftable.get_begin_pos()

        if mode !=# 'i'
            " XXX: What should I do?
        endif

        " :help getpos()
        return pos[2]
    endif

    return s:complete_kanji(a:base)
endfunction "}}}
function! s:complete_kanji(cur_keyword_str) "{{{
    " Get candidates.
    let list = []
    for candidate in eskk#dictionary#get_kanji(a:cur_keyword_str, 5)
        let yomigana = candidate[0]
        call add(list, {'word' : g:eskk_marker_henkan . yomigana, 'abbr' : yomigana, 'menu' : 'yomigana'})

        for kanji in candidate[1]
            call add(list, {
            \   'word': kanji.result,
            \   'abbr': (has_key(kanji, 'annotation') ? kanji.result . '; ' . kanji.annotation : kanji.result),
            \   'menu': 'kanji'
            \})
        endfor
    endfor

    return list
endfunction "}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

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
        let l = buftable.get_begin_pos()
        if empty(l)
            return -1
        endif
        let [mode, pos] = l
        if mode !=# 'i'
            return -1
        endif

        " :help getpos()
        return pos[2] - 1 + strlen(g:eskk_marker_henkan)
    endif

    return s:complete_kanji()
endfunction "}}}
function! s:complete_kanji() "{{{
    " Get candidates.
    let list = []
    let dict = eskk#get_dictionary()
    let buftable = eskk#get_buftable()
    for [yomigana, kanji_list] in dict.get_kanji(buftable)
        if yomigana != ''
            call add(list, {'word' : yomigana, 'abbr' : yomigana, 'menu' : 'yomigana'})
        endif

        for kanji in kanji_list
            call add(list, {
            \   'word': kanji.result,
            \   'abbr': (has_key(kanji, 'annotation') ? kanji.result . '; ' . kanji.annotation : kanji.result),
            \   'menu': 'kanji'
            \})
        endfor
    endfor

    return list
endfunction "}}}
function! eskk#complete#handle_special_key(char) "{{{
    " :help popupmenu-keys
    for c in [
    \   "<CR>",
    \   "<C-y>",
    \   "<C-l>",
    \   "<C-e>",
    \   "<PageUp>",
    \   "<PageDown>",
    \   "<Up>",
    \   "<Down>",
    \   "<Space>",
    \   "<Tab>",
    \]
        if a:char ==# eskk#util#eval_key(c)
            return c
        endif
    endfor

    if a:char ==# "\<C-h>" || a:char ==# "\<BS>"
        call eskk#get_buftable().do_backspace()
        return "<C-h>"
    endif

    return ''
endfunction "}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

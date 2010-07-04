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
function! eskk#complete#handle_special_key(stash) "{{{
    let char = a:stash.char
    " :help popupmenu-keys
    for [key, fn] in [
    \   ["<CR>", 's:do_enter'],
    \   ["<C-y>", 's:not_implemented'],
    \   ["<C-l>", 's:not_implemented'],
    \   ["<C-e>", 's:not_implemented'],
    \   ["<PageUp>", 's:not_implemented'],
    \   ["<PageDown>", 's:not_implemented'],
    \   ["<Up>", 's:not_implemented'],
    \   ["<Down>", 's:not_implemented'],
    \   ["<Space>", 's:not_implemented'],
    \   ["<Tab>", 's:not_implemented'],
    \   ["<C-h>", 's:do_backspace'],
    \   ["<BS>", 's:do_backspace'],
    \]
        if char ==# eskk#util#eval_key(key)
            return {fn}(a:stash)
        endif
    endfor

    return ''
endfunction "}}}
function! s:do_enter(stash) "{{{
    " Set inserted string by pum to buftable.
    let buftable = eskk#get_buftable()
    let [mode, pos] = buftable.get_begin_pos()
    call eskk#util#assert(mode ==# 'i')
    let filter_str = getline('.')[pos[2] - 1 + strlen(g:eskk_marker_henkan) : col('.') - 1]
    let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    call henkan_buf_str.set_matched('', filter_str)
    let okuri_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
    call okuri_buf_str.clear()

    call eskk#register_temp_event(
    \   'filter-redispatch-pre',
    \   'eskk#util#identity',
    \   [eskk#util#eval_key(eskk#get_nore_map('<C-y>'))]
    \)
    for key in g:eskk_compl_enter_send_keys
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [eskk#util#eval_key(eskk#get_named_map(key))]
        \)
    endfor
endfunction "}}}
function! s:do_backspace() "{{{
    call eskk#get_buftable().do_backspace()
    return "\<C-h>"
endfunction "}}}
function! s:not_implemented() "{{{
    throw eskk#internal_error(['eskk', 'complete'], 'not implemented')
endfunction "}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

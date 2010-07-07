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

function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID

" Variables {{{
let s:select_but_not_inserted = 0
" }}}

" Complete function.
function! eskk#complete#eskkcomplete(findstart, base) "{{{
    if a:findstart
        let buftable = eskk#get_buftable()
        let l = buftable.get_begin_pos()
        if empty(l)

            return -1
        endif
        let [mode, pos] = l
        let phase = buftable.get_henkan_phase()
        let do_complete = (mode ==# 'i')

        if !do_complete
            " Command line mode completion is not implemented.
            return -1
        endif

        call s:initialize_variables()
        " :help getpos()
        return pos[2] - 1 + strlen(g:eskk_marker_henkan)
    endif

    if eskk#get_mode() ==# 'ascii'
        " ASCII mode.
        return s:complete_ascii()
    else
        " Kanji mode.
        
        " Do not complete while inputting rom string.
        if a:base[-1] =~ '\a$'
            return []
        endif

        return s:complete_kanji()
    endif
endfunction "}}}
function! s:initialize_variables() "{{{
    let s:select_but_not_inserted = 0
endfunction "}}}
function! s:complete_ascii() "{{{
    " Get candidates.
    let list = []
    let dict = eskk#get_dictionary()
    let buftable = eskk#get_buftable()
    for [yomigana, kanji_list] in dict.get_ascii(buftable)
        " Add yomigana.
        if yomigana != ''
            call add(list, {'word' : yomigana, 'abbr' : yomigana, 'menu' : 'ascii'})
        endif

        " Add kanji.
        for kanji in kanji_list[: 1]
            call add(list, {
            \   'word': kanji.result,
            \   'abbr': (has_key(kanji, 'annotation') ? kanji.result . '; ' . kanji.annotation : kanji.result),
            \   'menu': 'kanji'
            \})
        endfor
    endfor

    return list
endfunction "}}}
function! s:complete_kanji() "{{{
    " Get candidates.
    let list = []
    let dict = eskk#get_dictionary()
    let buftable = eskk#get_buftable()
    for [yomigana, kanji_list] in dict.get_kanji(buftable)
        " Add yomigana.
        if yomigana != ''
            call add(list, {'word' : yomigana, 'abbr' : yomigana, 'menu' : 'yomigana'})
        endif

        " Add kanji.
        for kanji in kanji_list[: 1]
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
    \   ["<CR>", 's:do_enter_pre'],
    \   ["<C-y>", 's:close_pum_pre'],
    \   ["<C-l>", 's:identity'],
    \   ["<C-e>", 's:identity'],
    \   ["<PageUp>", 's:identity'],
    \   ["<PageDown>", 's:identity'],
    \   ["<Up>", 's:select_item'],
    \   ["<Down>", 's:select_item'],
    \   ["<Space>", 's:do_space'],
    \   ["<Tab>", 's:identity'],
    \   ["<C-h>", 's:identity'],
    \   ["<BS>", 's:identity'],
    \]
        if char ==# eskk#util#key2char(key)
            call {fn}(a:stash)
            call eskk#util#logf("pumvisible() = 1, Handled key '%s'.", key)
            return 1
        endif
    endfor

    "return 0
endfunction "}}}
function! s:close_pum_pre(stash) "{{{
    if s:select_but_not_inserted
        " Insert selected item.
        let a:stash.return = eskk#util#key2char(eskk#get_nore_map('<C-n><C-p>'))
        " Call `s:close_pum()` at next time.
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [eskk#util#key2char(eskk#get_named_map('<C-y>'))]
        \)
        let s:select_but_not_inserted = 0
    else
        call s:close_pum(a:stash)
    endif
endfunction "}}}
function! s:close_pum(stash) "{{{
    call s:set_selected_item()

    call eskk#register_temp_event(
    \   'filter-redispatch-pre',
    \   'eskk#util#identity',
    \   [eskk#util#key2char(eskk#get_nore_map('<C-y>'))]
    \)
endfunction "}}}
function! s:do_enter_pre(stash) "{{{
    if s:select_but_not_inserted
        " Insert selected item.
        let a:stash.return = eskk#util#key2char(eskk#get_nore_map('<C-n><C-p>'))
        " Call `s:close_pum()` at next time.
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [eskk#util#key2char(eskk#get_named_map('<CR>'))]
        \)
        let s:select_but_not_inserted = 0
    else
        call s:do_enter(a:stash)
    endif
endfunction "}}}
function! s:do_enter(stash) "{{{
    call s:set_selected_item()

    call eskk#register_temp_event(
    \   'filter-redispatch-pre',
    \   'eskk#util#identity',
    \   [eskk#util#key2char(eskk#get_nore_map('<C-y>'))]
    \)
    " FIXME:
    " When g:eskk_compl_enter_send_keys == ['<CR>', '<CR>']
    " unnecessary whitesace " " is inserted at the end of col.
    for key in g:eskk_compl_enter_send_keys
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [eskk#util#key2char(eskk#get_named_map(key))]
        \)
    endfor

    return ''
endfunction "}}}
function! s:select_item(stash) "{{{
    let s:select_but_not_inserted = 1
    let a:stash.return = a:stash.char
endfunction "}}}
function! s:do_space(stash) "{{{
    call s:set_selected_item()

    call eskk#register_temp_event(
    \   'filter-redispatch-pre',
    \   'eskk#util#identity',
    \   [eskk#util#key2char(eskk#get_nore_map('<C-y>'))]
    \)

    " FIXME:
    " When user selected kanji in completion, this mapping henkan kanji.
    call eskk#register_temp_event(
    \   'filter-redispatch-post',
    \   'eskk#util#identity',
    \   [eskk#util#key2char(eskk#get_named_map('<Space>'))]
    \)
endfunction "}}}
function! s:do_backspace(stash) "{{{
    let a:stash.return = eskk#util#key2char(eskk#get_nore_map('<C-h>'))
endfunction "}}}
function! s:identity(stash) "{{{
    let a:stash.return = a:stash.char
endfunction "}}}
function! s:set_selected_item() "{{{
    " Set selected item by pum to buftable.

    let buftable = eskk#get_buftable()
    let [mode, pos] = buftable.get_begin_pos()
    call eskk#util#assert(mode ==# 'i')

    let filter_str = getline('.')[pos[2] - 1 + strlen(g:eskk_marker_henkan) : col('.') - 1]
    call eskk#util#logf('Got selected item by pum: %s', string(filter_str))
    if filter_str =~# '[a-z]$'
        let [filter_str, rom_str] = [
        \   substitute(filter_str, '.$', '', ''),
        \   substitute(filter_str, '.*\(.\)$', '\1', '')
        \]
    else
        let rom_str = ''
    endif

    let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    call henkan_buf_str.clear()
    for char in split(filter_str, '\zs')
        call henkan_buf_str.push_matched('', char)
    endfor

    let okuri_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
    call okuri_buf_str.clear()
    call okuri_buf_str.set_rom_str(rom_str)

    call buftable.set_old_str(buftable.get_display_str())

    call s:initialize_variables()
endfunction "}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

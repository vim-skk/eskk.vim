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

        if eskk#get_mode() ==# 'ascii'
            return pos[2] - 1
        else
            return pos[2] - 1 + strlen(g:eskk_marker_henkan)
        endif
    endif

    if eskk#get_mode() ==# 'ascii'
        " ASCII mode.
        call eskk#util#log('eskk#complete#eskkcomplete(): ascii')
        return s:complete_ascii()
    elseif eskk#get_mode() ==# 'abbrev'
        " abbrev mode.
        call eskk#util#log('eskk#complete#eskkcomplete(): abbrev')
        return s:complete_abbrev()
    else
        " Kanji mode.
        call eskk#util#log('eskk#complete#eskkcomplete(): kanji')

        " Do not complete while inputting rom string.
        if a:base =~ '\a$'
            call eskk#util#log('eskk#complete#eskkcomplete(): kanji - skip.')
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
    let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    let okuri_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
    let key       = henkan_buf_str.get_matched_filter()
    let okuri     = okuri_buf_str.get_matched_filter()
    let okuri_rom = okuri_buf_str.get_matched_rom()
    for [yomigana, okuri_rom, kanji_list] in dict.search(key, okuri, okuri_rom)
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
function! s:complete_abbrev() "{{{
    " Get candidates.
    let list = []
    let dict = eskk#get_dictionary()
    let buftable = eskk#get_buftable()
    let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    let okuri_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
    let key       = henkan_buf_str.get_matched_filter()
    let okuri     = okuri_buf_str.get_matched_filter()
    let okuri_rom = okuri_buf_str.get_matched_rom()
    for [yomigana, okuri_rom, kanji_list] in dict.search(key, okuri, okuri_rom)
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
    if g:eskk_kata_convert_to_hira_at_completion && eskk#get_mode() ==# 'kata'
        let henkan_buf_str = buftable.filter_rom(
        \   g:eskk#buftable#HENKAN_PHASE_HENKAN,
        \   'rom_to_hira'
        \)
        let okuri_buf_str = buftable.filter_rom(
        \   g:eskk#buftable#HENKAN_PHASE_OKURI,
        \   'rom_to_hira'
        \)
    else
        let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
        let okuri_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
    endif
    let key       = henkan_buf_str.get_matched_filter()
    let okuri     = okuri_buf_str.get_matched_filter()
    let okuri_rom = okuri_buf_str.get_matched_rom()
    for [yomigana, okuri_rom, kanji_list] in dict.search(key, okuri, okuri_rom)
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
    call eskk#util#logf('eskk#complete#handle_special_key(): char = %s', char)

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
    \   ["<Tab>", 's:select_item'],
    \   ["<C-n>", 's:select_item'],
    \   ["<C-p>", 's:select_item'],
    \   ["<C-h>", 's:do_backspace'],
    \   ["<BS>", 's:do_backspace'],
    \]
        if char ==# eskk#util#key2char(key)
            call {fn}(a:stash)
            call eskk#util#logf("pumvisible() = 1, Handled key '%s'.", key)
            return 1
        endif
    endfor

    " Select item.
    call s:set_selected_item()
    
    if s:check_yomigana()
        return 1
    else
        call eskk#register_temp_event(
        \   'filter-redispatch-pre',
        \   'eskk#util#identity',
        \   [eskk#util#key2char(eskk#get_nore_map('<C-y>'))]
        \)
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [eskk#util#key2char(eskk#get_named_map('<CR>'))]
        \)
        " Postpone a:char process.
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [eskk#util#key2char(eskk#get_named_map(char))]
        \)
    endif

    " Not handled.
    return 0
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

    if s:check_yomigana()
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [eskk#util#key2char(eskk#get_named_map('<Space>'))]
        \)
    else
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [eskk#util#key2char(eskk#get_named_map('<CR>'))]
        \)
    endif
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
    let l = buftable.get_begin_pos()
    if empty(l)
        call eskk#util#log("warning: Can't get begin pos.")
        return
    endif
    let [mode, pos] = l
    call eskk#util#assert(mode ==# 'i')

    let filter_str = getline('.')[pos[2] - 1 + strlen(g:eskk_marker_henkan) : col('.') - 2]
    if filter_str =~# '[a-z]$'
        let [filter_str, rom_str] = [
        \   substitute(filter_str, '.$', '', ''),
        \   substitute(filter_str, '.*\(.\)$', '\1', '')
        \]
    else
        let rom_str = ''
    endif
    call eskk#util#logstrf('Got selected item by pum: filter_str = %s, rom_str = %s', filter_str, rom_str)

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
function! s:check_yomigana() "{{{
    let dict = eskk#get_dictionary()
    let buftable = eskk#get_buftable()
    let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    let key       = henkan_buf_str.get_matched_filter()
        
    if eskk#get_mode() ==# 'ascii'
        " ASCII mode.
        return key =~ '^[[:alnum:]-]\+$'
    elseif eskk#get_mode() ==# 'abbrev'
        " abbrev mode.
        call eskk#util#log('eskk#complete#eskkcomplete(): abbrev')
        return key =~ '^[[:alnum:]-]\+$'
    else
        " Kanji mode.
        return key =~ '^[あ-んー。！？]\+$'
    endif
endfunction "}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

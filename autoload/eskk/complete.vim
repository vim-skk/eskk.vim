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
let s:popup_func_table = {
    \   eskk#util#key2char("<CR>") : 's:do_enter_pre',
    \   eskk#util#key2char("<C-y>") : 's:close_pum_pre',
    \   eskk#util#key2char("<C-l>") : 's:identity',
    \   eskk#util#key2char("<C-e>") : 's:identity',
    \   eskk#util#key2char("<PageUp>") : 's:identity',
    \   eskk#util#key2char("<PageDown>") : 's:identity',
    \   eskk#util#key2char("<Up>") : 's:select_item',
    \   eskk#util#key2char("<Down>") : 's:select_item',
    \   eskk#util#key2char("<Space>") : 's:do_space',
    \   eskk#util#key2char("<Tab>") : 's:select_item',
    \   eskk#util#key2char("<C-n>") : 's:select_item',
    \   eskk#util#key2char("<C-p>") : 's:select_item',
    \   eskk#util#key2char("<C-h>") : 's:do_backspace',
    \   eskk#util#key2char("<BS>") : 's:do_backspace',
    \ }
" }}}

" Complete function.
function! eskk#complete#eskkcomplete(findstart, base) "{{{
    let eskk_mode = eskk#get_mode()
    if a:findstart
        let buftable_pos = s:get_buftable_pos()
        if empty(buftable_pos)
            return -1
        endif
        
        let [mode, pos] = buftable_pos
        if mode !=# 'i'
            " Command line mode completion is not implemented.
            return -1
        endif

        call s:initialize_variables()
        " :help getpos()

        if eskk_mode ==# 'ascii'
            return pos[2] - 1
        else
            return pos[2] - 1 + strlen(g:eskk_marker_henkan)
        endif
    endif

    if eskk_mode ==# 'ascii'
        " ASCII mode.
        call eskk#util#log('eskk#complete#eskkcomplete(): ascii')
        return s:complete(eskk_mode)
    elseif eskk_mode ==# 'abbrev'
        " abbrev mode.
        call eskk#util#log('eskk#complete#eskkcomplete(): abbrev')
        return s:complete(eskk_mode)
    elseif eskk_mode =~# 'hira\|kata'
        " Kanji mode.
        call eskk#util#log('eskk#complete#eskkcomplete(): kanji')

        " Do not complete while inputting rom string.
        if a:base =~ '\a$'
            call eskk#util#log('eskk#complete#eskkcomplete(): kanji - skip.')
            return []
        endif

        return s:complete(eskk_mode)
    else
        call eskk#util#warn('No completion supported.')
        return []
    endif
endfunction "}}}
function! s:initialize_variables() "{{{
    let s:select_but_not_inserted = 0
endfunction "}}}
function! s:complete(mode) "{{{
    " Get candidates.
    let list = []
    let dict = eskk#get_dictionary()
    let buftable = eskk#get_buftable()
    if g:eskk_kata_convert_to_hira_at_completion && a:mode ==# 'kata'
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

    let pos = s:get_buftable_pos()[1]
    let filter_str = getline('.')[pos[2] - 1 + strlen(g:eskk_marker_henkan) : col('.') - 2]
    let has_okuri = (filter_str =~ '^[あ-んー。！？]\+\*$') || okuri_rom != ''
    
    for [yomigana, okuri_rom, kanji_list] in dict.search(key, has_okuri, okuri, okuri_rom)
        " Add yomigana.
        if yomigana != ''
            call add(list, {'word' : yomigana, 'abbr' : yomigana, 'menu' : a:mode})
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

    if !empty(list)
        let inst = eskk#get_current_instance()
        let inst.has_started_completion = 1
    endif
    return list
endfunction "}}}

function! eskk#complete#handle_special_key(stash) "{{{
    let char = a:stash.char
    call eskk#util#logf('eskk#complete#handle_special_key(): char = %s', char)

    " Check popupmenu-keys
    if has_key(s:popup_func_table, char)
        call {s:popup_func_table[char]}(a:stash)
        return 0
    endif

    if s:check_yomigana()
        " Do filter.
        return 1
    endif
    
    " Select item.
    call s:set_selected_item()

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
    let pos = s:get_buftable_pos()[1]
    if pos[2] + strlen(g:eskk_marker_henkan) >= col('.')
        call s:close_pum(a:stash)
    endif
    let buftable = eskk#get_buftable()
    call buftable.do_backspace(a:stash)
endfunction "}}}
function! s:identity(stash) "{{{
    let a:stash.return = a:stash.char
endfunction "}}}
function! s:set_selected_item() "{{{
    " Set selected item by pum to buftable.

    let buftable = eskk#get_buftable()
    let pos = s:get_buftable_pos()[1]

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

    call buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    call buftable.set_old_str(buftable.get_display_str())

    call s:initialize_variables()
endfunction "}}}
function! s:check_yomigana() "{{{
    let buftable = eskk#get_buftable()
    let [mode, pos] = s:get_buftable_pos()
    let filter_str = getline('.')[pos[2] - 1 + strlen(g:eskk_marker_henkan) : col('.') - 2]

    if eskk#get_mode() ==# 'ascii'
        " ASCII mode.
        return filter_str =~ '^[[:alnum:]-]\+$'
    elseif eskk#get_mode() ==# 'abbrev'
        " abbrev mode.
        call eskk#util#log('eskk#complete#eskkcomplete(): abbrev')
        return filter_str =~ '^[[:alnum:]-]\+$'
    else
        " Kanji mode.
        return filter_str =~ '^[あ-んー。！？*]\+$'
    endif
endfunction "}}}
function! s:get_buftable_pos() "{{{
    let buftable = eskk#get_buftable()
    let l = buftable.get_begin_pos()
    if empty(l)
        call eskk#util#log("warning: Can't get begin pos.")
        return []
    endif
    let [mode, pos] = l
    call eskk#util#assert(mode ==# 'i')
    return [mode, pos]
endfunction "}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

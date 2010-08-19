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
let s:selected = 0
let s:inserted = 0
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
    \   eskk#util#key2char("<Tab>") : 's:select_insert_item',
    \   eskk#util#key2char("<C-n>") : 's:select_insert_item',
    \   eskk#util#key2char("<C-p>") : 's:select_insert_item',
    \   eskk#util#key2char("<C-h>") : 's:do_backspace',
    \   eskk#util#key2char("<BS>") : 's:do_backspace',
    \   eskk#util#key2char("<Esc>") : 's:do_escape',
    \ }
" }}}

" Complete function.
function! eskk#complete#eskkcomplete(findstart, base) "{{{
    let eskk_mode = eskk#get_mode()
    let buftable = eskk#get_buftable()
    let phase = buftable.get_henkan_phase()

    call eskk#util#logstrf('eskk#complete#handle_special_key(): findstart = %s, base = %s', a:findstart, a:base)

    if a:findstart
        if eskk_mode =~# 'hira\|kata'
        \   && !eskk#util#list_any(phase, [g:eskk#buftable#HENKAN_PHASE_HENKAN, g:eskk#buftable#HENKAN_PHASE_OKURI])
            return -1
        endif

        let [success, mode, pos] = s:get_buftable_pos()
        if !success
            return -1
        endif

        call s:initialize_variables()
        " :help getpos()

        return pos[2] - 1
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

        if !eskk#util#list_any(phase, [g:eskk#buftable#HENKAN_PHASE_HENKAN, g:eskk#buftable#HENKAN_PHASE_OKURI])
            return []
        endif
        if buftable.empty()
            return []
        endif
        " Do not complete while inputting rom string.
        if a:base =~ '\a$'
            call eskk#util#log('eskk#complete#eskkcomplete(): kanji - skip.')
            return []
        endif

        return s:complete(eskk_mode)
    else
        call eskk#util#log('warning: No completion supported.')
        return []
    endif
endfunction "}}}
function! s:initialize_variables() "{{{
    let s:selected = 0
    let s:inserted = 0
endfunction "}}}
function! s:complete(mode) "{{{
    " Get candidates.
    let list = []
    let dict = eskk#get_dictionary()
    let buftable = eskk#get_buftable()
    let is_katakana = g:eskk_kata_convert_to_hira_at_completion && a:mode ==# 'kata'
    
    if is_katakana
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

    let filter_str = s:get_buftable_str(0)
    let has_okuri = (filter_str =~ '^[あ-んー。！？]\+\*$') || okuri_rom != ''
    let marker = g:eskk_marker_popup . g:eskk_marker_henkan
    
    for [yomigana, okuri_rom, kanji_list] in dict.search(key, has_okuri, okuri, okuri_rom)
        if is_katakana
            call filter(kanji_list, 'stridx(v:val.result, ' . string(filter_str) . ') == 0')
        elseif len(kanji_list) > 2
            " Add yomigana.
            if yomigana != ''
                call add(list, {'word' : marker . yomigana, 'abbr' : yomigana, 'menu' : a:mode})
            endif
        endif

        " Add kanji.
        for kanji in kanji_list[: 1]
            call add(list, {
            \   'word': marker . kanji.result,
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
        call eskk#util#logf('%s -> %s', char, s:popup_func_table[char])
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
    if s:selected && !s:inserted
        " Insert selected item.
        let a:stash.return = eskk#util#key2char(eskk#get_nore_map('<C-n><C-p>'))
        " Call `s:close_pum()` at next time.
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [eskk#util#key2char(eskk#get_named_map('<C-y>'))]
        \)
        let s:selected = 0
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
    if s:selected && !s:inserted
        " Insert selected item.
        let a:stash.return = eskk#util#key2char(eskk#get_nore_map('<C-n><C-p>'))
        " Call `s:close_pum()` at next time.
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [eskk#util#key2char(eskk#get_named_map('<CR>'))]
        \)
        let s:selected = 0
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
    let s:selected = 1
    let a:stash.return = a:stash.char
endfunction "}}}
function! s:select_insert_item(stash) "{{{
    let s:selected = 1
    let s:inserted = 1
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
    let [success, _, pos] = s:get_buftable_pos()
    if !success
        return
    endif
    if pos[2] >= col('.')
        call s:close_pum(a:stash)
    endif
    let buftable = eskk#get_buftable()
    call buftable.do_backspace(a:stash)
endfunction "}}}
function! s:do_escape(stash) "{{{
    call s:set_selected_item()

    call eskk#register_temp_event(
    \   'filter-redispatch-post',
    \   'eskk#util#identity',
    \   [eskk#util#key2char(eskk#get_nore_map('<C-y>'))]
    \)
    call eskk#register_temp_event(
    \   'filter-redispatch-post',
    \   'eskk#util#identity',
    \   [eskk#util#key2char(eskk#get_named_map('<Esc>'))]
    \)
endfunction "}}}
function! s:identity(stash) "{{{
    let a:stash.return = a:stash.char
endfunction "}}}
function! s:set_selected_item() "{{{
    " Set selected item by pum to buftable.

    let buftable = eskk#get_buftable()
    let filter_str = s:get_buftable_str(0)
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
    " Do not rewrite anything.
    call buftable.set_old_str(s:get_buftable_str(1))

    call s:initialize_variables()
endfunction "}}}
function! s:check_yomigana() "{{{
    let filter_str = s:get_buftable_str(0)

    if eskk#get_mode() ==# 'ascii'
        " ASCII mode.
        return filter_str =~ '^[[:alnum:]-]\+$'
    elseif eskk#get_mode() ==# 'abbrev'
        " abbrev mode.
        call eskk#util#log('eskk#complete#eskkcomplete(): abbrev')
        return filter_str =~ '^[[:alnum:]-]\+$'
    else
        " Kanji mode.
        return filter_str =~ '^[ア-ンあ-んー。！？*]\+$'
    endif
endfunction "}}}
function! s:get_buftable_pos() "{{{
    let buftable = eskk#get_buftable()
    let l = buftable.get_begin_pos()
    if empty(l)
        call eskk#util#log("warning: Can't get begin pos.")
        return [0, 0, 0]
    endif
    let [mode, pos] = l
    if mode !=# 'i'
        return [0, mode, pos]
    endif
    return [1, mode, pos]
endfunction "}}}
function! s:get_buftable_str(with_marker) "{{{
    " TODO: Show warning if g:eskk_marker_popup
    " and g:eskk_marker_henkan are the same.
    " (where is the best place to show the warning?)

    " NOTE: getline('.') returns string without string after a:base
    " while matching the head of input string,
    " but eskk#complete#eskkcomplete() returns `pos[2] - 1`
    " it always does not match to input string
    " so getline('.') returns whole string.
    if col('.') == 1
        return ''
    endif
    let line = getline('.')[: col('.') - 2]
    let [success, _, pos] = s:get_buftable_pos()
    if !success
        call eskk#util#log('warning: s:get_buftable_pos() failed')
        return ''
    endif
    let begin = pos[2] - 1
    if !a:with_marker
        if line[begin : begin + strlen(g:eskk_marker_popup) - 1] == g:eskk_marker_popup
            let begin += strlen(g:eskk_marker_popup) + strlen(g:eskk_marker_henkan)
        elseif line[begin : begin + strlen(g:eskk_marker_henkan) - 1] == g:eskk_marker_henkan
            let begin += strlen(g:eskk_marker_henkan)
        else
            call eskk#util#assert(0, '404: marker not found')
        endif
    endif
    return strpart(line, begin)
endfunction "}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

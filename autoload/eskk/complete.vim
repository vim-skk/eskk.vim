" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8


" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID



" Variables
"
" The handlers for popup-menu's keys. (:help popupmenu-keys)
let s:POPUP_FUNC_TABLE = {}
" The handlers for all keys in each mode.
" used by eskk#complete#eskkcomplete().
let s:MODE_FUNC_TABLE = {}
" The previously completed candidates in each mode.
let s:completed_candidates = {}
" The flag whether a candidate is selected.
let s:completion_selected = 0
" The flag whether a candidate is inserted.
let s:completion_inserted = 0



" Complete function.
function! eskk#complete#eskkcomplete(findstart, base) "{{{
    " Complete function should not throw exception.
    try
        return s:eskkcomplete(a:findstart, a:base)
    catch
        redraw
        call eskk#error#log_exception('s:eskkcomplete()')
        if g:eskk#debug_out ==# 'file'
            call eskk#util#warn('s:eskkcomplete(): ' . v:exception)
        endif

        if a:findstart
            return -1
        else
            return s:skip_complete()
        endif
    endtry
endfunction "}}}
function! s:eskkcomplete(findstart, base) "{{{
    if a:findstart
        if !eskk#complete#can_find_start()
            return -1
        endif

        call s:initialize_variables()

        let [success, _, pos] = s:get_buftable_pos()
        call eskk#error#assert(success, "s:get_buftable_pos() must not fail")
        return pos[2] - 1
    endif

    return s:MODE_FUNC_TABLE[eskk#get_mode()](a:base)
endfunction "}}}
function! eskk#complete#can_find_start() "{{{
    if !has_key(s:MODE_FUNC_TABLE, eskk#get_mode())
        return 0
    endif

    if !s:has_marker()
        return 0
    endif

    let [success, mode, pos] = s:get_buftable_pos()
    if !success
        return 0
    endif

    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_buf_str(buftable.get_henkan_phase())
    if buftable.get_henkan_phase() ==# g:eskk#buftable#PHASE_HENKAN
    \   && buf_str.empty()
        return 0
    endif

    return 1
endfunction "}}}
function! eskk#complete#do_complete(base) "{{{
    let mode = eskk#get_mode()
    if has_key(s:MODE_FUNC_TABLE, mode)
        return s:MODE_FUNC_TABLE[mode](a:base)
    else
        return s:skip_complete()
    endif
endfunction "}}}

function! eskk#complete#_reset_completed_candidates() "{{{
    let s:completed_candidates = {}
endfunction "}}}
function! s:skip_complete() "{{{
    return s:get_completed_candidates(
    \   eskk#get_buftable().get_display_str(1, 0),
    \   []
    \)
endfunction "}}}
function! s:has_completed_candidates(display_str) "{{{
    let NOTFOUND = {}
    return s:get_completed_candidates(a:display_str, NOTFOUND) isnot NOTFOUND
endfunction "}}}
function! s:get_completed_candidates(display_str, else) "{{{
    let mode = eskk#get_mode()
    if !has_key(s:completed_candidates, mode)
        return a:else
    endif
    return get(
    \   s:completed_candidates[mode],
    \   a:display_str,
    \   a:else
    \)
endfunction "}}}
function! s:set_completed_candidates(display_str, candidates) "{{{
    if a:display_str == ''    " empty string cannot be a key of dictionary.
        return
    endif
    let mode = eskk#get_mode()
    if !has_key(s:completed_candidates, mode)
        let s:completed_candidates[mode] = {}
    endif
    let s:completed_candidates[mode][a:display_str] = a:candidates
endfunction "}}}

" s:MODE_FUNC_TABLE
function! s:MODE_FUNC_TABLE.hira(base) "{{{
    " Do not complete while inputting rom string.
    if a:base =~ '\a$'
        return s:skip_complete()
    endif
    let mb_str = eskk#get_buftable().get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN
    \).rom_pairs.get_filter()
    let length = eskk#util#mb_strlen(mb_str)
    if length < g:eskk#start_completion_length
        return s:skip_complete()
    endif

    return s:complete(eskk#get_mode(), a:base)
endfunction "}}}
let s:MODE_FUNC_TABLE.kata = s:MODE_FUNC_TABLE.hira
function! s:MODE_FUNC_TABLE.ascii(base) "{{{
    " ASCII mode.
    return s:complete("ascii", a:base)
endfunction "}}}
function! s:MODE_FUNC_TABLE.abbrev(base) "{{{
    " abbrev mode.
    return s:complete("abbrev", a:base)
endfunction "}}}

function! s:initialize_variables() "{{{
    let s:completion_selected = 0
    let s:completion_inserted = 0
endfunction "}}}
function! s:complete(mode, base) "{{{
    let buftable = eskk#get_buftable()
    let disp = buftable.get_display_str(1, 0)    " with marker, no rom_str.
    if s:has_completed_candidates(disp)
        return s:skip_complete()
    endif

    " Get candidates.
    let list = []
    let dict = eskk#get_skk_dict()

    if g:eskk#kata_convert_to_hira_at_completion
    \   && a:mode ==# 'kata'
        let [henkan_buf_str, okuri_buf_str] =
        \   buftable.convert_rom_pairs(
        \       [
        \           g:eskk#buftable#PHASE_HENKAN,
        \           g:eskk#buftable#PHASE_OKURI,
        \       ],
        \       eskk#get_mode_table('hira')
        \   )
    else
        let henkan_buf_str = buftable.get_buf_str(
        \   g:eskk#buftable#PHASE_HENKAN
        \)
        let okuri_buf_str = buftable.get_buf_str(
        \   g:eskk#buftable#PHASE_OKURI
        \)
    endif
    let key       = henkan_buf_str.rom_pairs.get_filter()
    let okuri     = okuri_buf_str.rom_pairs.get_filter()
    let okuri_rom = okuri_buf_str.rom_pairs.get_rom()

    let filter_str = s:get_buftable_str(0, a:base)
    let marker = g:eskk#marker_popup . g:eskk#marker_henkan

    try
        let s = dict.search(key, okuri, okuri_rom)
        if empty(s)
            return s:skip_complete()
        endif
    catch /^eskk: dictionary look up error:/
        return s:skip_complete()
    endtry

    let [yomigana, _, candidates] = s
    " call add(list, {
    " \   'word' : marker . yomigana,
    " \   'abbr' : yomigana,
    " \   'menu' : a:mode,
    " \})

    let do_list_okuri_candidates =
    \   buftable.get_henkan_phase() ==# g:eskk#buftable#PHASE_OKURI
    for c in candidates
        if do_list_okuri_candidates
            if c.has_okuri
                call add(list, {
                \   'word': marker . c.input,
                \   'abbr': (has_key(c, 'annotation') ?
                \               c.input . '; ' . c.annotation : c.input),
                \   'menu': 'kanji:okuri'
                \})
            endif
            continue
        endif

        call add(list, {
        \   'word': marker . c.input,
        \   'abbr': (has_key(c, 'annotation') ?
        \               c.input . '; ' . c.annotation : c.input),
        \   'menu': 'kanji'
        \})
    endfor

    if !empty(list)
        call s:set_completed_candidates(disp, list)
    endif
    return list
endfunction "}}}



" Handler for the key while popup displayed.
function! eskk#complete#handle_special_key(stash) "{{{
    if has_key(s:POPUP_FUNC_TABLE, a:stash.char)
        call call(s:POPUP_FUNC_TABLE[a:stash.char], [a:stash])
        return 0
    else
        return 1
    endif
endfunction "}}}

" s:POPUP_FUNC_TABLE (:help popupmenu-keys)
function! s:close_pum_pre(stash) "{{{
    if s:completion_selected && !s:completion_inserted
        " Insert selected item.
        let a:stash.return = "\<C-n>\<C-p>"
        " Call `s:close_pum()` at next time.
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#mappings#key2char',
        \   [eskk#mappings#get_filter_map('<C-y>')]
        \)
        let s:completion_selected = 0
    else
        call s:close_pum(a:stash)
    endif
endfunction "}}}
function! s:close_pum(stash) "{{{
    call s:set_selected_item()

    call eskk#register_temp_event(
    \   'filter-redispatch-pre',
    \   'eskk#mappings#key2char',
    \   [eskk#mappings#get_nore_map('<C-y>')]
    \)
endfunction "}}}
function! s:do_enter_pre(stash) "{{{
    if s:completion_selected && !s:completion_inserted
        " Insert selected item.
        let a:stash.return = "\<C-n>\<C-p>"
        " Call `s:close_pum()` at next time.
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#mappings#key2char',
        \   [eskk#mappings#get_filter_map('<CR>')]
        \)
        let s:completion_selected = 0
    else
        call s:do_enter(a:stash)
    endif
endfunction "}}}
function! s:do_enter(stash) "{{{
    call s:set_selected_item()

    call eskk#register_temp_event(
    \   'filter-redispatch-pre',
    \   'eskk#mappings#key2char',
    \   [eskk#mappings#get_nore_map('<C-y>')]
    \)
    call eskk#register_temp_event(
    \   'filter-redispatch-post',
    \   'eskk#mappings#key2char',
    \   [eskk#mappings#get_filter_map('<CR>')]
    \)
endfunction "}}}
function! s:select_item(stash) "{{{
    let s:completion_selected = 1
    let a:stash.return = a:stash.char
endfunction "}}}
function! s:do_tab(stash) "{{{
    call eskk#register_temp_event(
    \   'filter-redispatch-post',
    \   'eskk#mappings#key2char',
    \   [eskk#mappings#get_nore_map('<C-n>')]
    \)
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
    \   'eskk#mappings#key2char',
    \   [eskk#mappings#get_nore_map('<C-y>')]
    \)
    call eskk#register_temp_event(
    \   'filter-redispatch-post',
    \   'eskk#mappings#key2char',
    \   [eskk#mappings#get_filter_map('<Esc>')]
    \)
endfunction "}}}
function! s:identity(stash) "{{{
    let a:stash.return = a:stash.char
endfunction "}}}
function! s:cant_override(stash) "{{{
    throw eskk#internal_error(
    \   ['eskk', 'complete'],
    \   "This key should be overriden so never reach here."
    \)
endfunction "}}}
let s:POPUP_FUNC_TABLE = {
\   "\<CR>" : function('s:do_enter_pre'),
\   "\<C-y>" : function('s:close_pum_pre'),
\   "\<C-l>" : function('s:cant_override'),
\   "\<C-e>" : function('s:identity'),
\   "\<PageUp>" : function('s:identity'),
\   "\<PageDown>" : function('s:identity'),
\   "\<Up>" : function('s:select_item'),
\   "\<Down>" : function('s:select_item'),
\   "\<Tab>" : function('s:do_tab'),
\   "\<C-n>" : function('s:cant_override'),
\   "\<C-p>" : function('s:cant_override'),
\   "\<C-h>" : function('s:do_backspace'),
\   "\<BS>" : function('s:do_backspace'),
\   "\<Esc>" : function('s:do_escape'),
\}

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

    let henkan_buf_str = buftable.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN
    \)
    call henkan_buf_str.clear()
    for char in split(filter_str, '\zs')
        call henkan_buf_str.rom_pairs.push_one_pair('', char)
    endfor

    let okuri_buf_str = buftable.get_buf_str(
    \   g:eskk#buftable#PHASE_OKURI
    \)
    call okuri_buf_str.clear()
    call okuri_buf_str.rom_str.set(rom_str)

    call buftable.set_henkan_phase(g:eskk#buftable#PHASE_HENKAN)
    " Do not rewrite anything.
    call buftable.set_old_str(s:get_buftable_str(1))

    call s:initialize_variables()
endfunction "}}}
function! s:get_buftable_pos() "{{{
    let buftable = eskk#get_buftable()
    let l = buftable.get_begin_pos()
    if empty(l)
        call eskk#error#log("Can't get begin pos.")
        return [0, 0, 0]
    endif
    let [mode, pos] = l
    if mode !=# 'i'
        return [0, mode, pos]
    endif
    return [1, mode, pos]
endfunction "}}}
function! s:get_buftable_str(with_marker, ...) "{{{
    " NOTE: getline('.') returns string without string after a:base
    " while matching the head of input string,
    " but eskk#complete#eskkcomplete() returns `pos[2] - 1`
    " it always does not match to input string
    " so getline('.') returns whole string.
    if col('.') == 1
        return ''
    endif

    let [success, _, pos] = s:get_buftable_pos()
    if !success
        call eskk#error#log('s:get_buftable_pos() failed')
        return ''
    endif
    let begin = pos[2] - 1
    if a:0
        " Manual completion (not by neocomplcache).
        " a:1 is a:base.
        let line = getline('.')[: col('.') - 2] . a:1
    else
        let line = getline('.')[: col('.') - 2]
    endif

    if !a:with_marker && s:has_marker()
        if line[begin : begin + strlen(g:eskk#marker_popup) - 1]
        \   ==# g:eskk#marker_popup
            let begin += strlen(g:eskk#marker_popup)
            \               + strlen(g:eskk#marker_henkan)
        elseif line[begin : begin + strlen(g:eskk#marker_henkan) - 1]
        \   ==# g:eskk#marker_henkan
            let begin += strlen(g:eskk#marker_henkan)
        else
            call eskk#error#assert(0, '404: marker not found')
        endif
    endif

    return strpart(line, begin)
endfunction "}}}
function! s:has_marker() "{{{
    return
    \   eskk#get_mode() =~# 'hira\|kata'
    \   && eskk#util#list_has(
    \       [
    \           g:eskk#buftable#PHASE_HENKAN,
    \           g:eskk#buftable#PHASE_OKURI,
    \       ],
    \       eskk#get_buftable().get_henkan_phase(),
    \   )
endfunction "}}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

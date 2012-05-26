" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8


" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let g:eskk#version = str2nr(printf('%02d%02d%03d', 0, 5, 474))


function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunction s:SID


" See eskk#_initialize() for global variables.

" Variables {{{

" These variables are copied when starting new eskk instance.
" e.g.: Register word(s) recursively
"
" mode:
"   Current mode.
" buftable:
"   Buffer strings for inserted, filtered and so on.
" temp_event_hook_fn:
"   Temporary event handler functions/arguments.
" enabled:
"   True if s:eskk.enable() is called.
let s:eskk = {
\   'mode': '',
\   'begin_pos': [],
\   'buftable': {},
\   'temp_event_hook_fn': {},
\   'enabled': 0,
\   'formatoptions': 0,
\}



" NOTE: Following variables have global values between instances.

" s:Eskk instances.
let s:eskk_instances = []
" Index number for current instance.
let s:eskk_instance_id = 0
" Supported modes and their structures.
let s:available_modes = {}
" Event handler functions/arguments.
let s:event_hook_fn = {}
" Flag for `eskk#_initialize()`.
let s:INIT_YET   = 0
let s:INIT_DONE  = 1
let s:INIT_ABORT = 2
let s:initialization_state = s:INIT_YET
" SKK Dictionary (singleton)
let s:skk_dict = {}
" Mode and its table.
let s:mode_vs_table = {}
" All tables structures.
let s:table_defs = {}
" All special mappings.
let s:eskk_general_mappings = {}
let s:eskk_mappings = {
\   'disable': {'fn': eskk#util#get_local_func('handle_disable', s:SID_PREFIX)},
\   'kakutei': {'fn': eskk#util#get_local_func('handle_kakutei', s:SID_PREFIX)},
\   'sticky': {},
\   'backspace-key': {},
\   'escape-key': {},
\   'enter-key': {},
\   'tab': {},
\   'cancel': {},
\   'phase:henkan:henkan-key': {},
\   'phase:okuri:henkan-key': {},
\   'phase:henkan-select:choose-next': {},
\   'phase:henkan-select:choose-prev': {},
\   'phase:henkan-select:next-page': {},
\   'phase:henkan-select:prev-page': {},
\   'phase:henkan-select:escape': {},
\   'phase:henkan-select:delete-from-dict': {},
\   'mode:hira:toggle-hankata': {'fn': eskk#util#get_local_func('handle_toggle_hankata', s:SID_PREFIX)},
\   'mode:hira:ctrl-q-key': {'fn': eskk#util#get_local_func('handle_ctrl_q_key', s:SID_PREFIX)},
\   'mode:hira:toggle-kata': {'fn': eskk#util#get_local_func('handle_toggle_kata', s:SID_PREFIX)},
\   'mode:hira:q-key': {'fn': eskk#util#get_local_func('handle_q_key', s:SID_PREFIX)},
\   'mode:hira:l-key': {'fn': eskk#util#get_local_func('handle_l_key', s:SID_PREFIX)},
\   'mode:hira:to-ascii': {'fn': eskk#util#get_local_func('handle_to_ascii', s:SID_PREFIX)},
\   'mode:hira:to-zenei': {'fn': eskk#util#get_local_func('handle_to_zenei', s:SID_PREFIX)},
\   'mode:hira:to-abbrev': {'fn': eskk#util#get_local_func('handle_to_abbrev', s:SID_PREFIX)},
\   'mode:kata:toggle-hankata': {'fn': eskk#util#get_local_func('handle_toggle_hankata', s:SID_PREFIX)},
\   'mode:kata:ctrl-q-key': {'fn': eskk#util#get_local_func('handle_ctrl_q_key', s:SID_PREFIX)},
\   'mode:kata:toggle-kata': {'fn': eskk#util#get_local_func('handle_toggle_kata', s:SID_PREFIX)},
\   'mode:kata:q-key': {'fn': eskk#util#get_local_func('handle_q_key', s:SID_PREFIX)},
\   'mode:kata:l-key': {'fn': eskk#util#get_local_func('handle_l_key', s:SID_PREFIX)},
\   'mode:kata:to-ascii': {'fn': eskk#util#get_local_func('handle_to_ascii', s:SID_PREFIX)},
\   'mode:kata:to-zenei': {'fn': eskk#util#get_local_func('handle_to_zenei', s:SID_PREFIX)},
\   'mode:kata:to-abbrev': {'fn': eskk#util#get_local_func('handle_to_abbrev', s:SID_PREFIX)},
\   'mode:hankata:toggle-hankata': {'fn': eskk#util#get_local_func('handle_toggle_hankata', s:SID_PREFIX)},
\   'mode:hankata:ctrl-q-key': {'fn': eskk#util#get_local_func('handle_ctrl_q_key', s:SID_PREFIX)},
\   'mode:hankata:toggle-kata': {'fn': eskk#util#get_local_func('handle_toggle_kata', s:SID_PREFIX)},
\   'mode:hankata:q-key': {'fn': eskk#util#get_local_func('handle_q_key', s:SID_PREFIX)},
\   'mode:hankata:l-key': {'fn': eskk#util#get_local_func('handle_l_key', s:SID_PREFIX)},
\   'mode:hankata:to-ascii': {'fn': eskk#util#get_local_func('handle_to_ascii', s:SID_PREFIX)},
\   'mode:hankata:to-zenei': {'fn': eskk#util#get_local_func('handle_to_zenei', s:SID_PREFIX)},
\   'mode:hankata:to-abbrev': {'fn': eskk#util#get_local_func('handle_to_abbrev', s:SID_PREFIX)},
\   'mode:ascii:to-hira': {'fn': eskk#util#get_local_func('handle_toggle_hankata', s:SID_PREFIX)},
\   'mode:zenei:to-hira': {'fn': eskk#util#get_local_func('handle_toggle_hankata', s:SID_PREFIX)},
\   'mode:abbrev:henkan-key': {},
\}
" Keys used by only its mode.
let s:MODE_LOCAL_KEYS = {
\   'hira': [
\       'kakutei',
\       'disable',
\       'cancel',
\       'phase:henkan:henkan-key',
\       'phase:okuri:henkan-key',
\       'phase:henkan-select:choose-next',
\       'phase:henkan-select:choose-prev',
\       'phase:henkan-select:next-page',
\       'phase:henkan-select:prev-page',
\       'phase:henkan-select:escape',
\       'mode:hira:toggle-hankata',
\       'mode:hira:ctrl-q-key',
\       'mode:hira:toggle-kata',
\       'mode:hira:q-key',
\       'mode:hira:l-key',
\       'mode:hira:to-ascii',
\       'mode:hira:to-zenei',
\       'mode:hira:to-abbrev',
\   ],
\   'kata': [
\       'kakutei',
\       'disable',
\       'cancel',
\       'phase:henkan:henkan-key',
\       'phase:okuri:henkan-key',
\       'phase:henkan-select:choose-next',
\       'phase:henkan-select:choose-prev',
\       'phase:henkan-select:next-page',
\       'phase:henkan-select:prev-page',
\       'phase:henkan-select:escape',
\       'mode:kata:toggle-hankata',
\       'mode:kata:ctrl-q-key',
\       'mode:kata:toggle-kata',
\       'mode:kata:q-key',
\       'mode:kata:l-key',
\       'mode:kata:to-ascii',
\       'mode:kata:to-zenei',
\       'mode:kata:to-abbrev',
\   ],
\   'hankata': [
\       'kakutei',
\       'disable',
\       'cancel',
\       'phase:henkan:henkan-key',
\       'phase:okuri:henkan-key',
\       'phase:henkan-select:choose-next',
\       'phase:henkan-select:choose-prev',
\       'phase:henkan-select:next-page',
\       'phase:henkan-select:prev-page',
\       'phase:henkan-select:escape',
\       'mode:hankata:toggle-hankata',
\       'mode:hankata:ctrl-q-key',
\       'mode:hankata:toggle-kata',
\       'mode:hankata:q-key',
\       'mode:hankata:l-key',
\       'mode:hankata:to-ascii',
\       'mode:hankata:to-zenei',
\       'mode:hankata:to-abbrev',
\   ],
\   'ascii': [
\       'mode:ascii:to-hira',
\   ],
\   'zenei': [
\       'mode:zenei:to-hira',
\   ],
\}
" }}}



function! eskk#load() "{{{
    runtime! plugin/eskk.vim
endfunction "}}}



" Instance
function! s:eskk_new() "{{{
    return deepcopy(s:eskk, 1)
endfunction "}}}
function! eskk#get_current_instance() "{{{
    try
        return s:eskk_instances[s:eskk_instance_id]
    catch
        call eskk#logger#log_exception(
        \   'eskk#get_current_instance()')
        " Trap "E684: list index our of range ..."
        call eskk#initialize_instance()
        " This must not raise an error.
        return s:eskk_instances[s:eskk_instance_id]
    endtry
endfunction "}}}
function! eskk#initialize_instance() "{{{
    let s:eskk_instances = [s:eskk_new()]
    let s:eskk_instance_id = 0
endfunction "}}}
function! eskk#create_new_instance() "{{{
    " TODO: CoW
    if s:eskk_instance_id != len(s:eskk_instances) - 1
        throw eskk#internal_error(['eskk'], "mismatch values between s:eskk_instance_id and s:eskk_instances")
    endif

    " Create and push the instance.
    call add(s:eskk_instances, s:eskk_new())
    let s:eskk_instance_id += 1

    " Initialize instance.
    call eskk#enable()
endfunction "}}}
function! eskk#destroy_current_instance() "{{{
    if s:eskk_instance_id == 0
        throw eskk#internal_error(['eskk'], "No more instances.")
    endif
    if s:eskk_instance_id != len(s:eskk_instances) - 1
        throw eskk#internal_error(['eskk'], "mismatch values between s:eskk_instance_id and s:eskk_instances")
    endif

    " Destroy current instance.
    call remove(s:eskk_instances, s:eskk_instance_id)
    let s:eskk_instance_id -= 1
endfunction "}}}
function! eskk#get_buffer_instance() "{{{
    if !exists('b:eskk')
        let b:eskk = {}
    endif
    return b:eskk
endfunction "}}}


" s:eskk_mappings
function! s:handle_disable(stash) "{{{
    let phase = a:stash.buftable.get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
        call eskk#disable()
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_kakutei(stash) "{{{
    let buftable = a:stash.buftable
    let phase = buftable.get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_HENKAN
    \   || phase ==# g:eskk#buftable#PHASE_OKURI
    \   || phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        if !empty(buftable.get_display_str(0))
            call s:do_enter(a:stash)
            return 1
        endif
    endif
    return 0
endfunction "}}}
function! s:handle_toggle_hankata(stash) "{{{
    let phase = a:stash.buftable.get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'hankata' ? 'hira' : 'hankata')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_toggle_kata(stash) "{{{
    let phase = a:stash.buftable.get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'kata' ? 'hira' : 'kata')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_ctrl_q_key(stash) "{{{
    let phase = a:stash.buftable.get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_HENKAN
    \   || phase ==# g:eskk#buftable#PHASE_OKURI
        call s:do_ctrl_q_key(a:stash)
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_q_key(stash) "{{{
    let phase = a:stash.buftable.get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_HENKAN
    \   || phase ==# g:eskk#buftable#PHASE_OKURI
        call s:do_q_key(a:stash)
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_l_key(stash) "{{{
    let phase = a:stash.buftable.get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_HENKAN
    \   || phase ==# g:eskk#buftable#PHASE_OKURI
        call s:do_l_key(a:stash)
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_ascii(stash) "{{{
    let buftable = a:stash.buftable
    let phase = buftable.get_henkan_phase()
    let buf_str = buftable.get_current_buf_str()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
    \   && buf_str.rom_str.get() == ''
        call eskk#set_mode('ascii')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_zenei(stash) "{{{
    let buftable = a:stash.buftable
    let phase = buftable.get_henkan_phase()
    let buf_str = buftable.get_current_buf_str()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
    \   && buf_str.rom_str.get() == ''
        call eskk#set_mode('zenei')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_abbrev(stash) "{{{
    let phase = a:stash.buftable.get_henkan_phase()
    let buf_str = a:stash.buftable.get_current_buf_str()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
    \   && buf_str.rom_str.get() == ''
        call eskk#set_mode('abbrev')
        return 1
    endif
    return 0
endfunction "}}}



" Filter
" s:asym_filter {{{
function! s:asym_filter(stash) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let phase = buftable.get_henkan_phase()


    " Handle special mode-local mapping.
    for key in get(s:MODE_LOCAL_KEYS, eskk#get_mode(), [])
        if eskk#map#handle_special_lhs(char, key, a:stash)
            " Handled.
            return
        endif
    endfor


    " Handle specific characters.
    " These characters are handled regardless of current phase.
    if eskk#map#is_special_lhs(char, 'backspace-key')
        call s:do_backspace(a:stash)
        return
    elseif eskk#map#is_special_lhs(char, 'enter-key')
        call s:do_enter(a:stash)
        return
    elseif eskk#map#is_special_lhs(char, 'sticky')
        call s:do_sticky(a:stash)
        return
    elseif eskk#map#is_special_lhs(char, 'cancel')
        call s:do_cancel(a:stash)
        return
    elseif char =~# '^[A-Z]$'
    \   && !eskk#map#is_special_lhs(
    \          char, 'phase:henkan-select:delete-from-dict'
    \       )
        if phase !=# g:eskk#buftable#PHASE_NORMAL
        \   || buftable.get_current_buf_str().rom_str.empty()
            call s:do_sticky(a:stash)
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#map#key2char',
            \   [eskk#map#get_filter_map(tolower(char))]
            \)
            return
        else
            " NOTE: Assume "SAkujo" as "Sakujo".
            let stash = deepcopy(a:stash)
            let stash.char = tolower(stash.char)
            return s:asym_filter(stash)
        endif
    elseif eskk#map#is_special_lhs(char, 'escape-key')
        call s:do_escape(a:stash)
        return
    elseif eskk#map#is_special_lhs(char, 'tab')
        call s:do_tab(a:stash)
        return
    else
        " Fall through.
    endif


    " Handle other characters.
    if phase ==# g:eskk#buftable#PHASE_NORMAL
        return s:filter_rom(a:stash, eskk#get_current_mode_table())
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        if eskk#map#is_special_lhs(char, 'phase:henkan:henkan-key')
            call s:do_henkan(a:stash)
        else
            return s:filter_rom(a:stash, eskk#get_current_mode_table())
        endif
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        if eskk#map#is_special_lhs(char, 'phase:okuri:henkan-key')
            call s:do_henkan(a:stash)
        else
            return s:filter_rom(a:stash, eskk#get_current_mode_table())
        endif
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        if eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:choose-next'
        \)
            call buftable.choose_next_candidate(a:stash)
            return
        elseif eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:choose-prev'
        \)
            call buftable.choose_prev_candidate(a:stash)
            return
        elseif eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:delete-from-dict'
        \)
            let henkan_result = eskk#get_skk_dict().get_henkan_result()
            if !empty(henkan_result)
                let prev_buftable =
                \   deepcopy(henkan_result.buftable)
                if henkan_result.delete_from_dict()
                    call eskk#set_buftable(prev_buftable)
                else
                    " Fail to delete current candidate...
                    " push current candidate and
                    " back to normal phase.
                    call eskk#logger#warn(
                    \   'Failed to delete current candidate...'
                    \)
                    sleep 1

                    call buftable.push_kakutei_str(
                    \   buftable.get_display_str(0)
                    \)
                    call buftable.set_henkan_phase(
                    \   g:eskk#buftable#PHASE_NORMAL
                    \)
                endif
            endif
        else
            call s:do_enter(a:stash)
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#map#key2char',
            \   [eskk#map#get_filter_map(a:stash.char)]
            \)
        endif
    else
        throw eskk#internal_error(
        \   ['eskk'],
        \   "s:asym_filter() does not support phase " . phase . "."
        \)
    endif
endfunction "}}}

" For specific characters
function! s:do_backspace(stash) "{{{
    let buftable = a:stash.buftable
    if buftable.get_old_str() == ''
        call buftable.push_kakutei_str(
        \   eskk#map#key2char(
        \      eskk#map#get_special_key('backspace-key')
        \   )
        \)
        return
    endif

    let phase = buftable.get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        if g:eskk#delete_implies_kakutei
            " Enter normal phase and delete one character.
            let filter_str = eskk#util#mb_chop(buftable.get_display_str(0))
            call buftable.push_kakutei_str(filter_str)
            let henkan_select_buf_str = buftable.get_buf_str(
            \   g:eskk#buftable#PHASE_HENKAN_SELECT
            \)
            call henkan_select_buf_str.clear()

            call buftable.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
            return
        else
            " Leave henkan select or back to previous candidate if it exists.
            call buftable.choose_prev_candidate(a:stash)
            return
        endif
    endif

    let mode_st = eskk#get_current_mode_structure()
    if g:eskk#convert_at_exact_match
    \   && has_key(mode_st.temp, 'real_matched_pairs')

        let p = mode_st.temp.real_matched_pairs
        unlet mode_st.temp.real_matched_pairs

        if g:eskk#delete_implies_kakutei
            " Enter normal phase and delete one character.
            let filter_str = eskk#util#mb_chop(buftable.get_display_str(0))
            call buftable.push_kakutei_str(filter_str)
            let henkan_select_buf_str = buftable.get_buf_str(
            \   g:eskk#buftable#PHASE_HENKAN_SELECT
            \)
            call henkan_select_buf_str.clear()

            call buftable.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
            return
        else
            let filter_str = join(map(copy(p), 'v:val[1]'), '')
            let buf_str = buftable.get_buf_str(
            \   g:eskk#buftable#PHASE_HENKAN
            \)
            if filter_str ==# buf_str.rom_pairs.get_filter()
                " Fall through.
            else
                call buf_str.rom_pairs.set(p)
                return
            endif
        endif
    endif

    " Delete previous characters.
    for phase in buftable.get_lower_phases()
        let buf_str = buftable.get_buf_str(phase)
        if !buf_str.rom_str.empty()
            call buf_str.rom_str.pop()
            if buf_str.rom_str.empty()
            \   && !buf_str.rom_pairs.empty()
            \   && !get(buf_str.rom_pairs.get(-1)[2], 'converted')
                " Move rom_pairs data into rom_str.
                let pair = buf_str.rom_pairs.pop()
                call buf_str.rom_str.set(pair[0])
            endif
            break
        elseif !buf_str.rom_pairs.empty()
            call buf_str.rom_pairs.pop()
            break
        elseif buftable.get_marker(phase) != ''
            if !buftable.step_back_henkan_phase()
                let msg = "Normal phase's marker is empty, "
                \       . "and other phases *should* be able to change "
                \       . "current henkan phase."
                throw eskk#internal_error(['eskk', 'buftable'], msg)
            endif
            break
        endif
    endfor
endfunction "}}}
function! s:do_enter(stash) "{{{
    let buftable = a:stash.buftable
    let phase = buftable.get_henkan_phase()
    let enter_char =
    \   eskk#map#key2char(eskk#map#get_special_map('enter-key'))
    let undo_char  =
    \   eskk#map#key2char(eskk#map#key2char(eskk#map#get_nore_map('<C-g>u')))
    let dict = eskk#get_skk_dict()
    let henkan_result = dict.get_henkan_result()

    if phase ==# g:eskk#buftable#PHASE_NORMAL
        call buftable.convert_rom_str_inplace(phase)
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [enter_char]
        \)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        call buftable.convert_rom_str_inplace(phase)
        if get(g:eskk#set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [undo_char]
            \)
        endif

        if !empty(henkan_result)
            call henkan_result.update_rank()
        endif
        call buftable.kakutei(buftable.get_display_str(0))

    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        call buftable.convert_rom_str_inplace(
        \   [g:eskk#buftable#PHASE_HENKAN, phase]
        \)
        if get(g:eskk#set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [undo_char]
            \)
        endif

        if !empty(henkan_result)
            call henkan_result.update_rank()
        endif
        call buftable.kakutei(buftable.get_display_str(0))

    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        call buftable.convert_rom_str_inplace(phase)
        if get(g:eskk#set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [undo_char]
            \)
        endif

        if !empty(henkan_result)
            call henkan_result.update_rank()
        endif
        call buftable.kakutei(buftable.get_display_str(0))

    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! s:do_sticky(stash) "{{{
    let buftable = a:stash.buftable
    let phase   = buftable.get_henkan_phase()
    let buf_str = buftable.get_current_buf_str()

    " Convert rom_str if possible.
    call buftable.convert_rom_str_inplace([
    \   g:eskk#buftable#PHASE_HENKAN,
    \   g:eskk#buftable#PHASE_OKURI
    \])

    if phase ==# g:eskk#buftable#PHASE_NORMAL
        if !buf_str.rom_str.empty()
        \   || !buf_str.rom_pairs.empty()
            call buftable.convert_rom_str_inplace(phase)
            call buftable.push_kakutei_str(buftable.get_display_str(0))
            call buf_str.clear()
        endif
        if get(g:eskk#set_undo_point, 'sticky', 0) && mode() ==# 'i'
            call eskk#register_temp_event(
            \   'filter-redispatch-pre',
            \   'eskk#util#identity',
            \   [eskk#map#key2char(
            \       eskk#map#get_nore_map('<C-g>u')
            \   )]
            \)
        endif
        let buftable._set_begin_pos_at_rewrite = 1
        call buftable.set_henkan_phase(g:eskk#buftable#PHASE_HENKAN)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        if !buf_str.rom_str.empty()
        \   || !buf_str.rom_pairs.empty()
            call buftable.set_henkan_phase(g:eskk#buftable#PHASE_OKURI)
        endif
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        " nop
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        call s:do_enter(a:stash)
        call s:do_sticky(a:stash)
    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! s:do_cancel(stash) "{{{
    let buftable = a:stash.buftable
    call buftable.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
    call buftable.clear_all()
endfunction "}}}
function! s:do_escape(stash) "{{{
    let buftable = a:stash.buftable
    call buftable.convert_rom_str_inplace(
    \   buftable.get_henkan_phase()
    \)

    let kakutei_str = buftable.get_display_str(0)
    " NOTE: This function return value is not remapped.
    let esc = eskk#map#get_special_key('escape-key')
    call eskk#util#assert(esc != '', 'esc must not be empty string')
    call buftable.push_kakutei_str(kakutei_str . eskk#map#key2char(esc))
endfunction "}}}
function! s:do_tab(stash) "{{{
    let buftable = a:stash.buftable
    let buf_str  = buftable.get_current_buf_str()
    call buf_str.rom_str.append(s:get_tab_raw_str())
endfunction "}}}
function! s:get_tab_raw_str() "{{{
    return &l:expandtab ? repeat(' ', &tabstop) : "\<Tab>"
endfunction "}}}
function! s:do_henkan(stash, ...) "{{{
    let buftable = a:stash.buftable
    let convert_at_exact_match = a:0 ? a:1 : 0
    let phase = buftable.get_henkan_phase()

    if buftable.get_current_buf_str().empty()
        return
    endif

    if index(
    \   [g:eskk#buftable#PHASE_HENKAN,
    \       g:eskk#buftable#PHASE_OKURI],
    \   phase,
    \) ==# -1
        " TODO Add an error id like Vim
        call eskk#logger#warnf(
        \   "s:do_henkan() does not support phase %d.",
        \   phase
        \)
        return
    endif

    if eskk#get_mode() ==# 'abbrev'
        call s:do_henkan_abbrev(a:stash, convert_at_exact_match)
    else
        call s:do_henkan_other(a:stash, convert_at_exact_match)
    endif
endfunction "}}}
function! s:do_henkan_abbrev(stash, convert_at_exact_match) "{{{
    let buftable = a:stash.buftable
    let henkan_buf_str = buftable.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN
    \)
    let henkan_select_buf_str = buftable.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN_SELECT
    \)

    let rom_str = henkan_buf_str.rom_str.get()
    let dict = eskk#get_skk_dict()

    try
        let henkan_result = dict.refer(buftable, rom_str, '', '')
        let candidate = henkan_result.get_current_candidate()
        " No thrown exception. continue...

        call buftable.clear_all()
        if a:convert_at_exact_match
            call henkan_buf_str.rom_pairs.set_one_pair(rom_str, candidate, {'converted': 1})
        else
            call henkan_select_buf_str.rom_pairs.set_one_pair(rom_str, candidate, {'converted': 1})
            call buftable.set_henkan_phase(
            \   g:eskk#buftable#PHASE_HENKAN_SELECT
            \)
        endif
    catch /^eskk: dictionary look up error/
        " No candidates.
        let [input, hira, okuri] =
        \   dict.remember_word_prompt(
        \      dict.get_henkan_result()
        \   )
        if input != ''
            call buftable.kakutei(input . okuri)
        endif
    endtry
endfunction "}}}
function! s:do_henkan_other(stash, convert_at_exact_match) "{{{
    let buftable = a:stash.buftable
    let phase = buftable.get_henkan_phase()
    let henkan_buf_str = buftable.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN
    \)
    let okuri_buf_str = buftable.get_buf_str(
    \   g:eskk#buftable#PHASE_OKURI
    \)
    let henkan_select_buf_str = buftable.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN_SELECT
    \)

    if g:eskk#kata_convert_to_hira_at_henkan
    \   && eskk#get_mode() ==# 'kata'
        call buftable.convert_rom_all_inplace(
        \   [
        \       g:eskk#buftable#PHASE_HENKAN,
        \       g:eskk#buftable#PHASE_OKURI,
        \   ],
        \   eskk#get_mode_table('hira')
        \)
    endif

    " Convert rom_str if possible.
    call buftable.convert_rom_str_inplace([
    \   g:eskk#buftable#PHASE_HENKAN,
    \   g:eskk#buftable#PHASE_OKURI
    \])

    if g:eskk#fix_extra_okuri
    \   && !henkan_buf_str.rom_str.empty()
    \   && phase ==# g:eskk#buftable#PHASE_HENKAN
        call okuri_buf_str.rom_str.set(henkan_buf_str.rom_str.get())
        call henkan_buf_str.rom_str.clear()
        call buftable.set_henkan_phase(g:eskk#buftable#PHASE_OKURI)
        return
    endif

    let hira = henkan_buf_str.rom_pairs.get_filter()
    let okuri = okuri_buf_str.rom_pairs.get_filter()
    let okuri_rom = okuri_buf_str.rom_pairs.get_rom()
    let dict = eskk#get_skk_dict()

    " Clear phase henkan/okuri buffer string.
    " NOTE: I assume that `dict.refer()`
    " saves necessary strings even if I clear these.
    let henkan_matched_rom = henkan_buf_str.rom_pairs.get_rom()
    let okuri_matched_rom = okuri_buf_str.rom_pairs.get_rom()
    let rom_str = henkan_matched_rom . okuri_matched_rom
    try
        let henkan_result = dict.refer(buftable, hira, okuri, okuri_rom)
        let candidate = henkan_result.get_current_candidate()

        call buftable.clear_all()
        if a:convert_at_exact_match
            call henkan_buf_str.rom_pairs.set_one_pair(rom_str, candidate, {'converted': 1})
        else
            call henkan_select_buf_str.rom_pairs.set_one_pair(rom_str, candidate, {'converted': 1})
            call buftable.set_henkan_phase(
            \   g:eskk#buftable#PHASE_HENKAN_SELECT
            \)
            if g:eskk#kakutei_when_unique_candidate
            \   && !henkan_result.has_next()
                call buftable.kakutei(buftable.get_display_str(0))
            endif
        endif
    catch /^eskk: dictionary look up error/
        " No candidates.
        let [input, hira, okuri] =
        \   dict.remember_word_prompt(
        \      dict.get_henkan_result()
        \   )
        if input != ''
            call buftable.kakutei(input . okuri)
        endif
    endtry
endfunction "}}}
function! s:do_ctrl_q_key(stash) "{{{
    return s:convert_roms_and_kakutei(
    \   a:stash,
    \   (eskk#get_mode() ==# 'hira' ?
    \       eskk#get_mode_table('hankata') :
    \       eskk#get_mode_table('hira'))
    \)
endfunction "}}}
function! s:do_q_key(stash) "{{{
    return s:convert_roms_and_kakutei(
    \   a:stash,
    \   (eskk#get_mode() ==# 'hira' ?
    \       eskk#get_mode_table('kata') :
    \       eskk#get_mode_table('hira'))
    \)
endfunction "}}}
function! s:do_l_key(stash) "{{{
    " s:convert_roms_and_kakutei() does not convert rom_str
    " if it received empty dictionary.
    return s:convert_roms_and_kakutei(a:stash, {})
endfunction "}}}
function! s:convert_roms_and_kakutei(stash, table) "{{{
    let buftable = a:stash.buftable
    call buftable.convert_rom_str_inplace(
    \   buftable.get_henkan_phase()
    \)
    call buftable.convert_rom_all_inplace([
    \   g:eskk#buftable#PHASE_NORMAL,
    \   g:eskk#buftable#PHASE_HENKAN,
    \   g:eskk#buftable#PHASE_OKURI,
    \], a:table)
    call buftable.kakutei(buftable.get_display_str(0))
endfunction "}}}

" For other characters
function! s:filter_rom(stash, table) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let buf_str = buftable.get_current_buf_str()
    let rom_str = buf_str.rom_str.get() . char

    if a:table.has_n_candidates(rom_str, 2)
        " Has candidates but not match.
        return s:filter_rom_has_candidates(a:stash)
    elseif a:table.has_map(rom_str)
        " Match!
        return s:filter_rom_exact_match(a:stash, a:table)
    else
        " No candidates.
        return s:filter_rom_no_match(a:stash, a:table)
    endif
endfunction "}}}
function! s:filter_rom_exact_match(stash, table) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let buf_str = buftable.get_current_buf_str()
    let rom_str = buf_str.rom_str.get() . char
    let phase = buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#PHASE_NORMAL
    \   || phase ==# g:eskk#buftable#PHASE_HENKAN
        " Set filtered string.
        call buf_str.rom_pairs.push_one_pair(rom_str, a:table.get_map(rom_str), {'converted': 1})
        call buf_str.rom_str.clear()


        " Set rest string.
        "
        " NOTE:
        " rest must not have multibyte string.
        " rest is for rom string.
        let rest = a:table.get_rest(rom_str, -1)
        " Assumption: 'a:table.has_map(rest)' returns false here.
        if rest !=# -1
            " XXX:
            "     eskk#map#get_filter_map(char)
            " should
            "     eskk#map#get_filter_map(eskk#util#uneval_key(char))
            for rest_char in split(rest, '\zs')
                call eskk#register_temp_event(
                \   'filter-redispatch-post',
                \   'eskk#map#key2char',
                \   [eskk#map#get_filter_map(rest_char)]
                \)
            endfor
        endif

        if g:eskk#convert_at_exact_match
        \   && phase ==# g:eskk#buftable#PHASE_HENKAN
            let st = eskk#get_current_mode_structure()
            let henkan_buf_str = buftable.get_buf_str(
            \   g:eskk#buftable#PHASE_HENKAN
            \)
            if has_key(st.temp, 'real_matched_pairs')
                " Restore previous hiragana & push current to the tail.
                let p = henkan_buf_str.rom_pairs.pop()
                call henkan_buf_str.rom_pairs.set(
                \   st.temp.real_matched_pairs + [p]
                \)
            endif
            let st.temp.real_matched_pairs = henkan_buf_str.rom_pairs.get()

            call s:do_henkan(a:stash, 1)
        endif
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        " Enter phase henkan select with henkan.

        " XXX Write test and refactoring.
        "
        " Input: "SesSi"
        " Convert from:
        "   henkan buf str:
        "     filter str: "せ"
        "     rom str   : "s"
        "   okuri buf str:
        "     filter str: "し"
        "     rom str   : "si"
        " to:
        "   henkan buf str:
        "     filter str: "せっ"
        "     rom str   : ""
        "   okuri buf str:
        "     filter str: "し"
        "     rom str   : "si"
        " (http://d.hatena.ne.jp/tyru/20100320/eskk_rom_to_hira)
        let henkan_buf_str = buftable.get_buf_str(
        \   g:eskk#buftable#PHASE_HENKAN
        \)
        let okuri_buf_str = buftable.get_buf_str(
        \   g:eskk#buftable#PHASE_OKURI
        \)
        let henkan_select_buf_str = buftable.get_buf_str(
        \   g:eskk#buftable#PHASE_HENKAN_SELECT
        \)
        let henkan_rom = henkan_buf_str.rom_str.get()
        let okuri_rom  = okuri_buf_str.rom_str.get()
        if henkan_rom != '' && a:table.has_map(henkan_rom . okuri_rom[0])
            " Push "っ".
            let match_rom = henkan_rom . okuri_rom[0]
            call henkan_buf_str.rom_pairs.push_one_pair(
            \   match_rom,
            \   a:table.get_map(match_rom),
            \   {'converted': 1}
            \)
            " Push "s" to rom str.
            let rest = a:table.get_rest(henkan_rom . okuri_rom[0], -1)
            if rest !=# -1
                call okuri_buf_str.rom_str.set(
                \   rest . okuri_rom[1:]
                \)
            endif
        endif

        call eskk#util#assert(char != '', 'char must not be empty')
        call okuri_buf_str.rom_str.append(char)

        let has_rest = 0
        if a:table.has_map(okuri_buf_str.rom_str.get())
            call okuri_buf_str.rom_pairs.push_one_pair(
            \   okuri_buf_str.rom_str.get(),
            \   a:table.get_map(okuri_buf_str.rom_str.get()),
            \   {'converted': 1}
            \)
            let rest = a:table.get_rest(okuri_buf_str.rom_str.get(), -1)
            if rest !=# -1
                " XXX:
                "     eskk#map#get_filter_map(char)
                " should
                "     eskk#map#get_filter_map(eskk#util#uneval_key(char))
                for rest_char in split(rest, '\zs')
                    call eskk#register_temp_event(
                    \   'filter-redispatch-post',
                    \   'eskk#map#key2char',
                    \   [eskk#map#get_filter_map(rest_char)]
                    \)
                endfor
                let has_rest = 1
            endif
        endif

        call okuri_buf_str.rom_str.clear()

        call eskk#util#assert(!okuri_buf_str.rom_pairs.empty(),
        \                     'matched must not be empty.')
        " TODO `len(matched) == 1`: Do henkan at only the first time.

        if !has_rest && g:eskk#auto_henkan_at_okuri_match
            call s:do_henkan(a:stash)
        endif
    endif
endfunction "}}}
function! s:filter_rom_has_candidates(stash) "{{{
    let buf_str  = a:stash.buftable.get_current_buf_str()
    call buf_str.rom_str.append(a:stash.char)
endfunction "}}}
function! s:filter_rom_no_match(stash, table) "{{{
    let char = a:stash.char
    let buf_str = a:stash.buftable.get_current_buf_str()
    let rom_str_without_char = buf_str.rom_str.get()

    " TODO: Save previous (or more?) searched result
    " with map/candidates of rom_str.

    let NO_MAP = []
    let map = a:table.get_map(rom_str_without_char, NO_MAP)
    if map isnot NO_MAP
        " `rom_str_without_char` has the map but fail with `char`.
        " e.g.: rom_str is "nj" => "んj"
        call buf_str.rom_pairs.push_one_pair(rom_str_without_char, map, {'converted': 1})
        " *** FALLTHROUGH ***
    elseif empty(rom_str_without_char)
        " No candidates started with such a character `char`.
        " e.g.: rom_str is " ", "&"
        call buf_str.rom_pairs.push_one_pair(char, char)
        return
    else
        " `rom_str_without_char` has the candidate(s) but fail with `char`.
        if g:eskk#rom_input_style ==# 'skk'
            " rom_str is "zyk" => "k"
        elseif g:eskk#rom_input_style ==# 'msime'
            " rom_str is "zyk" => "zyk"
            call buf_str.rom_pairs.push_one_pair(
            \   rom_str_without_char, rom_str_without_char
            \)
        endif
        " *** FALLTHROUGH ***
    endif

    " Handle `char`.
    " TODO: Can do it recursively?
    unlet map
    let map = a:table.get_map(char, NO_MAP)
    if map isnot NO_MAP
        call buf_str.rom_pairs.push_one_pair(char, map, {'converted': 1})
        call buf_str.rom_str.clear()
    else
        call buf_str.rom_str.set(char)
    endif
endfunction "}}}

" }}}
function! s:ascii_filter(stash) "{{{
    let this = eskk#get_mode_structure('ascii')
    if eskk#map#is_special_lhs(
    \   a:stash.char, 'mode:ascii:to-hira'
    \)
        call eskk#set_mode('hira')
    else
        if a:stash.char !=# "\<BS>"
        \   && a:stash.char !=# "\<C-h>"
            if a:stash.char =~# '\w'
                if !has_key(
                \   this.temp, 'already_set_for_this_word'
                \)
                    " Set start col of word.
                    call eskk#set_begin_pos('.')
                    let this.temp.already_set_for_this_word = 1
                endif
            else
                if has_key(
                \   this.temp, 'already_set_for_this_word'
                \)
                    unlet this.temp.already_set_for_this_word
                endif
            endif
        endif

        if eskk#has_mode_table('ascii')
            if !has_key(this.temp, 'table')
                let this.temp.table = eskk#get_mode_table('ascii')
            endif
            call a:stash.buftable.push_kakutei_str(
            \   this.temp.table.get_map(
            \      a:stash.char, a:stash.char
            \   )
            \)
        else
            call a:stash.buftable.push_kakutei_str(a:stash.char)
        endif
    endif
endfunction "}}}
function! s:zenei_filter(stash) "{{{
    let this = eskk#get_mode_structure('zenei')
    if eskk#map#is_special_lhs(
    \   a:stash.char, 'mode:zenei:to-hira'
    \)
        call eskk#set_mode('hira')
    else
        if !has_key(this.temp, 'table')
            let this.temp.table = eskk#get_mode_table('zenei')
        endif
        call a:stash.buftable.push_kakutei_str(
        \   this.temp.table.get_map(
        \      a:stash.char, a:stash.char
        \   )
        \)
    endif
endfunction "}}}
function! s:abbrev_filter(stash) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let buf_str = buftable.get_current_buf_str()
    let phase = buftable.get_henkan_phase()

    " Handle special characters.
    " These characters are handled regardless of current phase.
    if eskk#map#is_special_lhs(char, 'backspace-key')
        if buf_str.rom_str.get() == ''
            " If backspace-key was pressed at empty string,
            " leave abbrev mode.
            " TODO: Back to previous mode?
            call eskk#set_mode('hira')
        else
            call s:do_backspace(a:stash)
        endif
        return
    elseif eskk#map#is_special_lhs(char, 'enter-key')
        call s:do_enter(a:stash)
        call eskk#set_mode('hira')
        return
    else
        " Fall through.
    endif

    " Handle other characters.
    if phase ==# g:eskk#buftable#PHASE_HENKAN
        if eskk#map#is_special_lhs(
        \   char, 'phase:henkan:henkan-key'
        \)
            call s:do_henkan(a:stash)
        else
            call buf_str.rom_str.append(char)
        endif
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        if eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:choose-next'
        \)
            call buftable.choose_next_candidate(a:stash)
            return
        elseif eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:choose-prev'
        \)
            call buftable.choose_prev_candidate(a:stash)
            return
        else
            call buftable.push_kakutei_str(
            \   buftable.get_display_str(0)
            \)
            call buftable.clear_all()
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#map#key2char',
            \   [eskk#map#get_filter_map(a:stash.char)]
            \)

            " Leave abbrev mode.
            " TODO: Back to previous mode?
            call eskk#set_mode('hira')
        endif
    else
        throw eskk#internal_error(
        \   ['eskk'],
        \   "'abbrev' mode does not support phase " . phase . "."
        \)
    endif
endfunction "}}}


" Initialization
function! eskk#_initialize() "{{{
    if s:initialization_state ==# s:INIT_DONE
    \   || s:initialization_state ==# s:INIT_ABORT
        return
    endif
    let s:initialization_state = s:INIT_ABORT

    " Validate Vim versions {{{
    function! s:validate_vim_version() "{{{
        let ok =
        \   v:version > 703
        \   || v:version == 703 && has('patch32')
        if !ok
            call eskk#logger#warn(
            \   "eskk.vim: warning: Your Vim is too old."
            \   . " Please use 7.3.32 at least."
            \)
            throw 'FINISH'
        endif
    endfunction "}}}

    try
        call s:validate_vim_version()
    catch /^FINISH\C$/
        " do not initialize eskk
        " if user doesn't fill requirements!
        return
    endtry
    " }}}

    " Create the first eskk instance. {{{
    call eskk#initialize_instance()
    " }}}

    " Create eskk augroup. {{{
    augroup eskk
        autocmd!
    augroup END
    " }}}

    " Throw "eskk-initialize-pre" autocmd event. {{{
    " NOTE: If no "User eskk-initialize-pre" events,
    " Vim complains like "No matching autocommands".
    autocmd eskk User eskk-initialize-pre :
    doautocmd User eskk-initialize-pre
    " }}}

    " Global Variables {{{

    " Debug
    call eskk#util#set_default('g:eskk#debug', 0)
    call eskk#util#set_default('g:eskk#debug_wait_ms', 0)
    call eskk#util#set_default('g:eskk#debug_out', 'both')
    call eskk#util#set_default('g:eskk#directory', '~/.eskk')

    " Dictionary
    for [s:varname, s:default] in [
    \   ['g:eskk#dictionary', {
    \       'path': "~/.skk-jisyo",
    \       'sorted': 0,
    \       'encoding': 'utf-8',
    \   }],
    \   ['g:eskk#large_dictionary', {
    \       'path': "/usr/local/share/skk/SKK-JISYO.L",
    \       'sorted': 1,
    \       'encoding': 'euc-jp',
    \   }],
    \]
        if exists(s:varname)
            if type({s:varname}) == type("")
                let s:default.path = {s:varname}
                unlet {s:varname}
                let {s:varname} = s:default
            elseif type({s:varname}) == type({})
                call extend({s:varname}, s:default, "keep")
            else
                call eskk#logger#warn(
                \   s:varname . "'s type is either String or Dictionary."
                \)
            endif
        else
            let {s:varname} = s:default
        endif
    endfor
    unlet! s:varname s:default

    call eskk#util#set_default('g:eskk#backup_dictionary', g:eskk#dictionary.path . '.BAK')
    call eskk#util#set_default('g:eskk#auto_save_dictionary_at_exit', 1)

    call eskk#util#set_default('g:eskk#dictionary_save_count', -1)

    " Henkan
    call eskk#util#set_default('g:eskk#select_cand_keys', "asdfjkl")
    call eskk#util#set_default('g:eskk#show_candidates_count', 4)
    call eskk#util#set_default('g:eskk#kata_convert_to_hira_at_henkan', 1)
    call eskk#util#set_default('g:eskk#kata_convert_to_hira_at_completion', 1)
    call eskk#util#set_default('g:eskk#show_annotation', 0)
    call eskk#util#set_default('g:eskk#kakutei_when_unique_candidate', 0)

    " Mappings
    call eskk#util#set_default('g:eskk#mapped_keys', eskk#get_default_mapped_keys())

    " Mode
    call eskk#util#set_default('g:eskk#initial_mode', 'hira')
    call eskk#util#set_default_dict('g:eskk#statusline_mode_strings', {'hira': 'あ', 'kata': 'ア', 'ascii': 'aA', 'zenei': 'ａ', 'hankata': 'ｧｱ', 'abbrev': 'aあ'})

    " Table
    call eskk#util#set_default('g:eskk#cache_table_map', 1)

    " Markers
    call eskk#util#set_default('g:eskk#marker_henkan', '▽')
    call eskk#util#set_default('g:eskk#marker_okuri', '*')
    call eskk#util#set_default('g:eskk#marker_henkan_select', '▼')
    call eskk#util#set_default('g:eskk#marker_jisyo_touroku', '?')
    call eskk#util#set_default('g:eskk#marker_popup', '◇')

    " Completion
    call eskk#util#set_default('g:eskk#enable_completion', 1)
    call eskk#util#set_default('g:eskk#max_candidates', 30)
    call eskk#util#set_default('g:eskk#start_completion_length', 3)
    call eskk#util#set_default('g:eskk#register_completed_word', 1)
    call eskk#util#set_default('g:eskk#egg_like_newline_completion', 0)

    " Cursor color
    call eskk#util#set_default('g:eskk#use_color_cursor', 1)
    " ascii: ivory4:#8b8b83, gray:#bebebe
    " hira: coral4:#8b3e2f, pink:#ffc0cb
    " kata: forestgreen:#228b22, green:#00ff00
    " abbrev: royalblue:#4169e1
    " zenei: gold:#ffd700
    call eskk#util#set_default_dict('g:eskk#cursor_color', {
    \   'ascii': ['#8b8b83', '#bebebe'],
    \   'hira': ['#8b3e2f', '#ffc0cb'],
    \   'kata': ['#228b22', '#00ff00'],
    \   'abbrev': '#4169e1',
    \   'zenei': '#ffd700',
    \})

    " Misc.
    call eskk#util#set_default('g:eskk#egg_like_newline', 0)
    call eskk#util#set_default('g:eskk#keep_state', 0)
    call eskk#util#set_default('g:eskk#keep_state_beyond_buffer', 0)
    call eskk#util#set_default('g:eskk#revert_henkan_style', 'okuri')
    call eskk#util#set_default('g:eskk#delete_implies_kakutei', 0)
    call eskk#util#set_default('g:eskk#rom_input_style', 'skk')
    call eskk#util#set_default('g:eskk#auto_henkan_at_okuri_match', 1)

    call eskk#util#set_default_dict('g:eskk#set_undo_point', {
    \   'sticky': 1,
    \   'kakutei': 1,
    \})

    call eskk#util#set_default('g:eskk#fix_extra_okuri', 1)
    call eskk#util#set_default('g:eskk#convert_at_exact_match', 0)
    " }}}

    " Check global variables values. {{{
    function! s:initialize_check_variables()
        if g:eskk#marker_henkan ==# g:eskk#marker_popup
            call eskk#logger#warn(
            \   'g:eskk#marker_henkan and g:eskk#marker_popup'
            \       . ' must be different.'
            \)
        endif
    endfunction
    call s:initialize_check_variables()
    " }}}

    " Set up g:eskk#directory. {{{
    function! s:initialize_set_up_eskk_directory()
        let dir = expand(g:eskk#directory)
        for d in [dir, eskk#util#join_path(dir, 'log')]
            if !isdirectory(d) && !eskk#util#mkdir_nothrow(d)
                call eskk#logger#logf("can't create directory '%s'.", d)
            endif
        endfor
    endfunction
    call s:initialize_set_up_eskk_directory()
    " }}}

    " g:eskk#keep_state {{{
    if g:eskk#keep_state
        autocmd eskk InsertEnter * call eskk#map#save_normal_keys()
        autocmd eskk InsertLeave * call eskk#map#restore_normal_keys()
    else
        autocmd eskk InsertLeave * call eskk#disable()
    endif
    " }}}

    " Default mappings - :EskkMap {{{
    call eskk#commands#define()

    " TODO: Separate to hira:disable, kata:disable, hankata:disable ?
    EskkMap -type=disable -unique <C-j>

    EskkMap -type=kakutei -unique <C-j>

    EskkMap -type=sticky -unique ;
    EskkMap -type=backspace-key -unique <C-h>
    EskkMap -type=enter-key -unique <CR>
    EskkMap -type=escape-key -unique <Esc>
    EskkMap -type=tab -unique <Tab>

    EskkMap -type=cancel -unique <C-g>

    EskkMap -type=phase:henkan:henkan-key -unique <Space>

    EskkMap -type=phase:okuri:henkan-key -unique <Space>

    EskkMap -type=phase:henkan-select:choose-next -unique <Space>
    EskkMap -type=phase:henkan-select:choose-prev -unique x

    EskkMap -type=phase:henkan-select:next-page -unique <Space>
    EskkMap -type=phase:henkan-select:prev-page -unique x

    EskkMap -type=phase:henkan-select:escape -unique <C-g>

    EskkMap -type=phase:henkan-select:delete-from-dict -unique X

    EskkMap -type=mode:hira:toggle-hankata -unique <C-q>
    EskkMap -type=mode:hira:ctrl-q-key -unique <C-q>
    EskkMap -type=mode:hira:toggle-kata -unique q
    EskkMap -type=mode:hira:q-key -unique q
    EskkMap -type=mode:hira:l-key -unique l
    EskkMap -type=mode:hira:to-ascii -unique l
    EskkMap -type=mode:hira:to-zenei -unique L
    EskkMap -type=mode:hira:to-abbrev -unique /

    EskkMap -type=mode:kata:toggle-hankata -unique <C-q>
    EskkMap -type=mode:kata:ctrl-q-key -unique <C-q>
    EskkMap -type=mode:kata:toggle-kata -unique q
    EskkMap -type=mode:kata:q-key -unique q
    EskkMap -type=mode:kata:l-key -unique l
    EskkMap -type=mode:kata:to-ascii -unique l
    EskkMap -type=mode:kata:to-zenei -unique L
    EskkMap -type=mode:kata:to-abbrev -unique /

    EskkMap -type=mode:hankata:toggle-hankata -unique <C-q>
    EskkMap -type=mode:hankata:ctrl-q-key -unique <C-q>
    EskkMap -type=mode:hankata:toggle-kata -unique q
    EskkMap -type=mode:hankata:q-key -unique q
    EskkMap -type=mode:hankata:l-key -unique l
    EskkMap -type=mode:hankata:to-ascii -unique l
    EskkMap -type=mode:hankata:to-zenei -unique L
    EskkMap -type=mode:hankata:to-abbrev -unique /

    EskkMap -type=mode:ascii:to-hira -unique <C-j>

    EskkMap -type=mode:zenei:to-hira -unique <C-j>

    EskkMap -type=mode:abbrev:henkan-key -unique <Space>

    EskkMap -remap -unique <C-^> <Plug>(eskk:toggle)

    EskkMap -remap <BS> <Plug>(eskk:filter:<C-h>)

    EskkMap -map-if="mode() ==# 'i'" -unique <Esc>
    " silent! EskkMap -map-if="mode() ==# 'i'" -unique <C-c>
    " }}}

    " Save dictionary if modified {{{
    if g:eskk#auto_save_dictionary_at_exit
        autocmd eskk VimLeavePre * EskkUpdateDictionary
    endif
    " }}}

    " Register builtin-modes. {{{
    function! s:initialize_builtin_modes()
        " 'ascii' mode {{{
        call eskk#register_mode_structure('ascii', {
        \   'filter': eskk#util#get_local_func('ascii_filter', s:SID_PREFIX),
        \})
        " }}}

        " 'zenei' mode {{{
        call eskk#register_event(
        \   'enter-mode-zenei',
        \   'eskk#set_begin_pos',
        \   ['.']
        \)
        call eskk#register_mode_structure('zenei', {
        \   'filter': eskk#util#get_local_func('zenei_filter', s:SID_PREFIX),
        \   'table': eskk#table#new_from_file('rom_to_zenei'),
        \})
        " }}}

        " 'hira' mode {{{
        call eskk#register_mode_structure('hira', {
        \   'filter': eskk#util#get_local_func('asym_filter', s:SID_PREFIX),
        \   'table': eskk#table#new_from_file('rom_to_hira'),
        \})
        " }}}

        " 'kata' mode {{{
        call eskk#register_mode_structure('kata', {
        \   'filter': eskk#util#get_local_func('asym_filter', s:SID_PREFIX),
        \   'table': eskk#table#new_from_file('rom_to_kata'),
        \})
        " }}}

        " 'hankata' mode {{{
        call eskk#register_mode_structure('hankata', {
        \   'filter': eskk#util#get_local_func('asym_filter', s:SID_PREFIX),
        \   'table': eskk#table#new_from_file('rom_to_hankata'),
        \})
        " }}}

        " 'abbrev' mode {{{
        let dict = {}

        let dict.filter = eskk#util#get_local_func('abbrev_filter', s:SID_PREFIX)
        let dict.init_phase = g:eskk#buftable#PHASE_HENKAN

        call eskk#register_event(
        \   'enter-mode-abbrev',
        \   'eskk#set_begin_pos',
        \   ['.']
        \)

        call eskk#register_mode_structure('abbrev', dict)
        " }}}
    endfunction
    call s:initialize_builtin_modes()
    " }}}

    " BufEnter: Restore global option value of &iminsert, &imsearch {{{
    if !g:eskk#keep_state_beyond_buffer
        execute 'autocmd eskk BufLeave *'
        \   'let [&g:iminsert, &g:imsearch] ='
        \   string([&g:iminsert, &g:imsearch])
    endif
    " }}}

    " InsertEnter: Clear buftable. {{{
    autocmd eskk InsertEnter * call eskk#get_buftable().reset()
    " }}}

    " InsertLeave: g:eskk#convert_at_exact_match {{{
    function! s:clear_real_matched_pairs() "{{{
        if !eskk#is_enabled() || eskk#get_mode() == ''
            return
        endif

        let st = eskk#get_current_mode_structure()
        if has_key(st.temp, 'real_matched_pairs')
            unlet st.temp.real_matched_pairs
        endif
    endfunction "}}}
    autocmd eskk InsertLeave * call s:clear_real_matched_pairs()
    " }}}

    " Event: enter-mode {{{
    call eskk#register_event(
    \   'enter-mode',
    \   'eskk#set_cursor_color',
    \   []
    \)

    function! s:initialize_clear_buftable()
        let buftable = eskk#get_buftable()
        call buftable.clear_all()
    endfunction
    call eskk#register_event(
    \   'enter-mode',
    \   eskk#util#get_local_func(
    \       'initialize_clear_buftable',
    \       s:SID_PREFIX
    \   ),
    \   []
    \)

    function! s:initialize_set_henkan_phase()
        let buftable = eskk#get_buftable()
        let st = eskk#get_current_mode_structure()
        call buftable.set_henkan_phase(
        \   (has_key(st, 'init_phase') ?
        \       st.init_phase
        \       : g:eskk#buftable#PHASE_NORMAL)
        \)
    endfunction
    call eskk#register_event(
    \   'enter-mode',
    \   eskk#util#get_local_func(
    \       'initialize_set_henkan_phase',
    \       s:SID_PREFIX
    \   ),
    \   []
    \)
    " }}}

    " InsertLeave: Restore &backspace value {{{
    " FIXME: Due to current implementation,
    " s:buftable.rewrite() assumes that &backspace contains "eol".
    if &l:backspace !~# '\<eol\>'
        setlocal backspace+=eol
        autocmd eskk InsertEnter * setlocal backspace+=eol
        autocmd eskk InsertLeave * setlocal backspace-=eol
    endif
    " }}}

    " Logging event {{{
    if g:eskk#debug
        " Should I create autoload/eskk/log.vim ?
        autocmd eskk CursorHold,VimLeavePre *
        \            call eskk#logger#write_debug_log_file()
    endif
    " }}}

    " Create internal mappings. {{{
    call eskk#map#map(
    \   'e',
    \   '<Plug>(eskk:_set_begin_pos)',
    \   '[eskk#set_begin_pos("."), ""][1]',
    \   'ic'
    \)
    call eskk#map#map(
    \   're',
    \   '<Plug>(eskk:_filter_redispatch_pre)',
    \   'join(eskk#throw_event("filter-redispatch-pre"), "")'
    \)
    call eskk#map#map(
    \   're',
    \   '<Plug>(eskk:_filter_redispatch_post)',
    \   'join(eskk#throw_event("filter-redispatch-post"), "")'
    \)
    " }}}

    " Reset s:completed_candidates in autoload/eskk/complete.vim {{{
    " s:completed_candidates should have non-empty value
    " only during insert-mode.
    autocmd eskk InsertLeave *
    \   call eskk#complete#_reset_completed_candidates()
    " }}}

    " Throw "eskk-initialize-post" autocmd event. {{{
    " NOTE: If no "User eskk-initialize-post" events,
    " Vim complains like "No matching autocommands".
    autocmd eskk User eskk-initialize-post :
    doautocmd User eskk-initialize-post
    " }}}

    " Save/Restore 'formatoptions'. {{{
    function! s:save_restore_formatoptions(enable)
        let inst = eskk#get_current_instance()
        if a:enable
            if type(inst.formatoptions) is type(0)
                let inst.formatoptions = &l:formatoptions
                let &l:formatoptions = ''
            endif
        else
            if type(inst.formatoptions) is type("")
                let &l:formatoptions = inst.formatoptions
                let inst.formatoptions = 0
            endif
        endif
    endfunction
    call eskk#register_event('enable-im', eskk#util#get_local_func('save_restore_formatoptions', s:SID_PREFIX), [1])
    call eskk#register_event('disable-im', eskk#util#get_local_func('save_restore_formatoptions', s:SID_PREFIX), [0])
    " }}}

    let s:initialization_state = s:INIT_DONE
endfunction "}}}
function! eskk#is_initialized() "{{{
    return s:initialization_state ==# s:INIT_DONE
endfunction "}}}

" Global variable function
function! eskk#get_default_mapped_keys() "{{{
    return split(
    \   'abcdefghijklmnopqrstuvwxyz'
    \  .'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    \  .'1234567890'
    \  .'!"#$%&''()'
    \  .',./;:]@[-^\'
    \  .'>?_+*}`{=~'
    \   ,
    \   '\zs'
    \) + [
    \   "<lt>",
    \   "<Bar>",
    \   "<Tab>",
    \   "<BS>",
    \   "<C-h>",
    \   "<CR>",
    \   "<Space>",
    \   "<C-q>",
    \   "<C-y>",
    \   "<C-e>",
    \   "<PageUp>",
    \   "<PageDown>",
    \   "<Up>",
    \   "<Down>",
    \   "<C-n>",
    \   "<C-p>",
    \   "<C-j>",
    \   "<C-g>",
    \]
endfunction "}}}

" Enable/Disable IM
function! eskk#is_enabled() "{{{
    return eskk#is_initialized()
    \   && eskk#get_current_instance().enabled
endfunction "}}}
function! eskk#toggle() "{{{
    if !eskk#is_initialized()
        call eskk#logger#warn('eskk is not initialized.')
        return ''
    endif
    return eskk#is_enabled() ? eskk#disable() : eskk#enable()
endfunction "}}}
function! eskk#enable() "{{{
    if !eskk#is_initialized()
        call eskk#logger#warn('eskk is not initialized.')
        return ''
    endif
    if eskk#is_enabled()
        return ''
    endif
    if exists('b:skk_on') && b:skk_on
        call eskk#logger#warn('skk.vim is enabled. please disable it.')
        return ''
    endif
    let inst = eskk#get_current_instance()

    call eskk#throw_event('enable-im')

    " Clear current variable states.
    let inst.mode = ''
    call eskk#get_buftable().reset()

    " Map all lang-mode keymappings.
    call eskk#map#map_all_keys()

    " Initialize mode.
    call eskk#set_mode(g:eskk#initial_mode)

    " Save previous omnifunc.
    if g:eskk#enable_completion
        let inst.omnifunc_save = &l:omnifunc
        let &l:omnifunc = 'eskk#complete#eskkcomplete'
    endif

    let inst.enabled = 1
    if mode() =~# '^[ic]$'
        " NOTE: Vim can't enter lang-mode immediately
        " in insert-mode or commandline-mode.
        " We have to use i_CTRL-^ .
        setlocal imsearch=-1
        redrawstatus
        return "\<C-^>"
    else
        setlocal iminsert=1 imsearch=-1
        redrawstatus
        return ''
    endif
endfunction "}}}
function! eskk#disable() "{{{
    if !eskk#is_initialized()
        call eskk#logger#warn('eskk is not initialized.')
        return ''
    endif
    if !eskk#is_enabled()
        return ''
    endif
    let inst = eskk#get_current_instance()

    call eskk#throw_event('disable-im')

    " Unmap all lang-mode keymappings.
    call eskk#map#unmap_all_keys()

    if has_key(inst, 'omnifunc_save')
        let &l:omnifunc = remove(inst, 'omnifunc_save')
    endif

    call eskk#unlock_neocomplcache()
    let inst.enabled = 0
    if mode() =~# '^[ic]$'
        " NOTE: Vim can't escape lang-mode immediately
        " in insert-mode or commandline-mode.
        " We have to use i_CTRL-^ .

        " In insert-mode, See eskk#filter() for disable handler.
        " This path is for only commandline-mode.
        redrawstatus
        let kakutei_str = eskk#get_buftable().generate_kakutei_str()
        return kakutei_str . "\<C-^>"
    else
        setlocal iminsert=0 imsearch=0
        redrawstatus
        return ''
    endif
endfunction "}}}

" Mode
function! eskk#set_mode(next_mode) "{{{
    let inst = eskk#get_current_instance()
    if !eskk#is_supported_mode(a:next_mode)
        call eskk#logger#log(
        \   "mode '" . a:next_mode . "' is not supported."
        \)
        call eskk#logger#log(
        \   's:available_modes = ' . string(s:available_modes)
        \)
        return
    endif

    call eskk#throw_event('leave-mode-' . inst.mode)
    call eskk#throw_event('leave-mode')

    " Change mode.
    let prev_mode = inst.mode
    let inst.mode = a:next_mode

    call eskk#throw_event('enter-mode-' . inst.mode)
    call eskk#throw_event('enter-mode')

    " For &statusline.
    redrawstatus
endfunction "}}}
function! eskk#get_mode() "{{{
    let inst = eskk#get_current_instance()
    return inst.mode
endfunction "}}}
function! eskk#is_supported_mode(mode) "{{{
    return has_key(s:available_modes, a:mode)
endfunction "}}}
function! eskk#register_mode_structure(mode, st) "{{{
    if !s:check_mode_structure(a:st)
        call eskk#util#warn('eskk#register_mode_structure(): a invalid structure was given!')
        return
    endif

    let s:available_modes[a:mode] = a:st
    let s:available_modes[a:mode].temp = {}

    if has_key(a:st, 'table')
        call eskk#register_mode_table(a:mode, a:st.table)
    endif
endfunction "}}}
function! s:check_mode_structure(st) "{{{
    " Check required keys.
    for key in ['filter']
        if !has_key(a:st, key)
            call eskk#logger#warn(
            \   "s:check_mode_structure(" . string(a:mode) . "): "
            \       . string(key) . " is not present in structure"
            \)
            return 0
        endif
    endfor

    " Check optional keys.
    if has_key(a:st, 'temp')
    \   && type(a:st.table) isnot type({})
        return 0
    endif
    if has_key(a:st, 'table')
    \   && type(a:st.table) isnot type({})
        return 0
    endif

    return 1
endfunction "}}}
function! eskk#get_current_mode_structure() "{{{
    return eskk#get_mode_structure(eskk#get_mode())
endfunction "}}}
function! eskk#get_mode_structure(mode) "{{{
    let inst = eskk#get_current_instance()
    if !eskk#is_supported_mode(a:mode)
        call eskk#logger#warn(
        \   "mode '" . a:mode . "' is not available."
        \)
    endif
    return s:available_modes[a:mode]
endfunction "}}}
function! eskk#has_mode_func(func_key) "{{{
    let inst = eskk#get_current_instance()
    let st = eskk#get_mode_structure(inst.mode)
    return has_key(st, a:func_key)
endfunction "}}}
function! eskk#call_mode_func(func_key, args, required) "{{{
    let inst = eskk#get_current_instance()
    let st = eskk#get_mode_structure(inst.mode)
    if !has_key(st, a:func_key)
        if a:required
            throw eskk#internal_error(
            \   ['eskk'],
            \   "Mode '" . inst.mode . "' does not have"
            \       . " required function key"
            \)
        endif
        return
    endif
    return call(st[a:func_key], a:args, st)
endfunction "}}}

" Mode/Table
function! eskk#has_current_mode_table() "{{{
    return eskk#has_mode_table(eskk#get_mode())
endfunction "}}}
function! eskk#has_mode_table(mode) "{{{
    return has_key(s:mode_vs_table, a:mode)
endfunction "}}}
function! eskk#get_current_mode_table() "{{{
    return eskk#get_mode_table(eskk#get_mode())
endfunction "}}}
function! eskk#get_mode_table(mode) "{{{
    return s:mode_vs_table[a:mode]
endfunction "}}}

" Table
function! eskk#has_table(table_name) "{{{
    return has_key(s:table_defs, a:table_name)
endfunction "}}}
function! eskk#get_all_registered_tables() "{{{
    return keys(s:table_defs)
endfunction "}}}
function! eskk#get_table(name) "{{{
    return s:table_defs[a:name]
endfunction "}}}
function! eskk#register_mode_table(mode, table) "{{{
    if !has_key(s:mode_vs_table, a:mode)
        call s:register_table(a:table)
        let s:mode_vs_table[a:mode] = a:table
    endif
endfunction "}}}
function! s:register_table(table) "{{{
    for base in a:table.get_base_tables()
        call s:register_table(base)
    endfor
    " s:register_table() MUST NOT allow to overwrite
    " already registered tables.
    " because it is harmful to be able to
    " rewrite base (derived) tables.
    let name = a:table.get_name()
    if !has_key(s:table_defs, name)
        let s:table_defs[name] = a:table
    endif
endfunction "}}}

" Begin pos
function! eskk#get_begin_pos() "{{{
    let inst = eskk#get_current_instance()
    return inst.begin_pos
endfunction "}}}
function! eskk#set_begin_pos(expr) "{{{
    let inst = eskk#get_current_instance()
    if mode() ==# 'i'
        let inst.begin_pos = getpos(a:expr)
    else
        call eskk#logger#logf("called eskk from mode '%s'.", mode())
    endif
endfunction "}}}

" Statusline
function! eskk#statusline(...) "{{{
    return eskk#is_enabled()
    \      ? printf(get(a:000, 0, '[eskk:%s]'),
    \               get(g:eskk#statusline_mode_strings,
    \                   eskk#get_current_instance().mode, '??'))
    \      : get(a:000, 1, '')
endfunction "}}}

" Dictionary
function! eskk#get_skk_dict() "{{{
    if empty(s:skk_dict)
        let s:skk_dict = eskk#dictionary#new(
        \   g:eskk#dictionary, g:eskk#large_dictionary
        \)
    endif
    return s:skk_dict
endfunction "}}}

" Buftable
function! eskk#get_buftable() "{{{
    let inst = eskk#get_current_instance()
    if empty(inst.buftable)
        let inst.buftable = eskk#buftable#new()
    endif
    return inst.buftable
endfunction "}}}
function! eskk#set_buftable(buftable) "{{{
    let inst = eskk#get_current_instance()
    call a:buftable.set_old_str(
    \   empty(inst.buftable) ? '' : inst.buftable.get_old_str()
    \)
    let inst.buftable = a:buftable
endfunction "}}}

" Event
function! eskk#register_event(event_names, Fn, head_args, ...) "{{{
    return s:register_event(
    \   s:event_hook_fn,
    \   a:event_names,
    \   a:Fn,
    \   a:head_args,
    \   (a:0 ? a:1 : -1)
    \)
endfunction "}}}
function! eskk#register_temp_event(event_names, Fn, head_args, ...) "{{{
    let inst = eskk#get_current_instance()
    return s:register_event(
    \   inst.temp_event_hook_fn,
    \   a:event_names,
    \   a:Fn,
    \   a:head_args,
    \   (a:0 ? a:1 : -1)
    \)
endfunction "}}}
function! s:register_event(st, event_names, Fn, head_args, inst) "{{{
    let event_names = type(a:event_names) == type([]) ?
    \                   a:event_names : [a:event_names]
    for name in event_names
        if !has_key(a:st, name)
            let a:st[name] = []
        endif
        call add(
        \   a:st[name],
        \   [a:Fn, a:head_args]
        \       + (type(a:inst) == type({}) ? [a:inst] : [])
        \)
    endfor
endfunction "}}}
function! eskk#throw_event(event_name) "{{{
    let inst = eskk#get_current_instance()
    let ret        = []
    let event      = get(s:event_hook_fn, a:event_name, [])
    let temp_event = get(inst.temp_event_hook_fn, a:event_name, [])
    let all_events = event + temp_event
    if empty(all_events)
        return []
    endif

    while !empty(all_events)
        call add(ret, call('call', remove(all_events, 0)))
    endwhile

    " Clear temporary hooks.
    let inst.temp_event_hook_fn[a:event_name] = []

    return ret
endfunction "}}}
function! eskk#has_event(event_name) "{{{
    let inst = eskk#get_current_instance()
    return
    \   !empty(get(s:event_hook_fn, a:event_name, []))
    \   || !empty(get(inst.temp_event_hook_fn, a:event_name, []))
endfunction "}}}

" Filter
function! eskk#filter(char) "{{{
    let inst = eskk#get_current_instance()
    let buftable = eskk#get_buftable()
    let stash = {
    \   'char': a:char,
    \   'buftable': buftable,
    \}

    " Check irregular circumstance.
    if !eskk#is_supported_mode(inst.mode)
        " Detect fatal error. disable eskk...
        return s:force_disable_eskk(
        \   stash,
        \   eskk#util#build_error(
        \       ['eskk'],
        \       ['current mode is not supported: '
        \           . string(inst.mode)]
        \   )
        \)
    endif

    call eskk#throw_event('filter-begin')
    call buftable.set_old_str(buftable.get_display_str())

    try
        let do_filter = 1
        if g:eskk#enable_completion
        \&& pumvisible() && mode() ==# 'i'
            try
                let do_filter = eskk#complete#handle_special_key(stash)
            catch
                call eskk#logger#log_exception(
                \   'eskk#complete#handle_special_key()'
                \)
            endtry
        endif

        if do_filter
            call eskk#call_mode_func('filter', [stash], 1)
        endif
        if !eskk#is_enabled()
            " NOTE: Vim can't escape lang-mode immediately
            " in insert-mode or commandline-mode.
            " We have to use i_CTRL-^ .
            let kakutei_str = buftable.generate_kakutei_str()
            return kakutei_str . "\<C-^>"
        endif

        " NOTE: `buftable` may become invalid reference
        " because `eskk#call_mode_func()` may call `eskk#set_buftable()`.
        return
        \   (eskk#has_event('filter-redispatch-pre') ?
        \       "\<Plug>(eskk:_filter_redispatch_pre)" : '')
        \   . buftable.rewrite()
        \   . (eskk#has_event('filter-redispatch-post') ?
        \       "\<Plug>(eskk:_filter_redispatch_post)" : '')

    catch
        " Detect fatal error. disable eskk...
        return s:force_disable_eskk(
        \   stash,
        \   eskk#util#build_error(
        \       ['eskk'],
        \       ['main routine raised an error: '.v:exception]
        \   )
        \)

    finally
        if buftable.get_henkan_phase() ==# g:eskk#buftable#PHASE_NORMAL
            call buftable.get_current_buf_str().rom_pairs.clear()
        endif
    endtry
endfunction "}}}
function! s:force_disable_eskk(stash, error) "{{{
    " FIXME: It may cause inconsistency
    " to eskk status and lang options.
    " TODO: detect lang options and follow the status.
    setlocal iminsert=0 imsearch=0

    call eskk#logger#write_error_log_file(
    \   a:stash, a:error,
    \)
    sleep 1

    " Vim does not disable IME
    " when changing the value of &iminsert and/or &imsearch.
    " so do it manually.
    call eskk#map#map('b', '<Plug>(eskk:_reenter_insert_mode)', '<esc>i')
    return "\<Plug>(eskk:_reenter_insert_mode)"
endfunction "}}}

" g:eskk#use_color_cursor
function! eskk#set_cursor_color() "{{{
    " From s:SkkSetCursorColor() of skk.vim

    if !has('gui_running') || !g:eskk#use_color_cursor
        return
    endif

    let eskk_mode = eskk#get_mode()
    if !has_key(g:eskk#cursor_color, eskk_mode)
        return
    endif

    let color = g:eskk#cursor_color[eskk_mode]
    if type(color) == type([]) && len(color) >= 2
        execute 'highlight lCursor guibg=' . color[&background ==# 'light' ? 0 : 1]
    elseif type(color) == type("") && color != ''
        execute 'highlight lCursor guibg=' . color
    endif
endfunction "}}}

" Mapping
function! eskk#_get_eskk_mappings() "{{{
    return s:eskk_mappings
endfunction "}}}
function! eskk#_get_eskk_general_mappings() "{{{
    return s:eskk_general_mappings
endfunction "}}}

" Misc.
function! eskk#unlock_neocomplcache() "{{{
    if eskk#is_neocomplcache_locked()
        NeoComplCacheUnlock
    endif
endfunction "}}}
function! eskk#is_neocomplcache_locked() "{{{
    return
    \   g:eskk#enable_completion
    \   && exists('g:loaded_neocomplcache')
    \   && exists(':NeoComplCacheUnlock')
    \   && neocomplcache#is_locked()
endfunction "}}}

" Exceptions
function! eskk#internal_error(from, ...) "{{{
    return eskk#util#build_error(a:from, ['internal error'] + a:000)
endfunction "}}}

call eskk#_initialize()

" To indicate that eskk has been loaded.
" Avoid many many autoload bugs, use plain global variable here.
let g:loaded_autoload_eskk = 1


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

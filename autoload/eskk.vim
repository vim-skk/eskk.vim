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
delfunction s:SID


" See eskk#_initialize() for global variables.

" Variables {{{

" These variables are copied when starting new eskk instance.
" e.g.: Register word(s) recursively
"
" mode:
"   Current mode.
" preedit:
"   Buffer strings for inserted, filtered and so on.
let s:eskk = {
\   'mode': '',
\   'preedit': {},
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
\   'enable': {'fn': eskk#util#get_local_func('handle_enable', s:SID_PREFIX)},
\   'toggle': {'fn': eskk#util#get_local_func('handle_toggle', s:SID_PREFIX)},
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
\       'enable',
\       'toggle',
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
\       'enable',
\       'toggle',
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
\       'enable',
\       'toggle',
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
\   'abbrev': [
\       'cancel',
\   ],
\}
" The number of 'eskk#filter()' was called.
let s:filter_count = 0
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
    if s:eskk_instance_id != len(s:eskk_instances) - 1
        throw eskk#internal_error(['eskk'], "mismatch values between s:eskk_instance_id and s:eskk_instances")
    endif

    " Deactivate a current instance.
    call eskk#disable()

    " Create and push a new instance.
    call add(s:eskk_instances, s:eskk_new())
    let s:eskk_instance_id += 1

    " Activate the new instance.
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
    let phase = a:stash.preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_NORMAL
        call eskk#disable()
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_enable(stash) "{{{
    let phase = a:stash.preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_NORMAL
        call eskk#enable()
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_toggle(stash) "{{{
    let phase = a:stash.preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_NORMAL
        call eskk#toggle()
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_kakutei(stash) "{{{
    let preedit = a:stash.preedit
    let phase = preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_HENKAN
    \   || phase ==# g:eskk#preedit#PHASE_OKURI
    \   || phase ==# g:eskk#preedit#PHASE_HENKAN_SELECT
        call s:do_enter_egglike(a:stash)
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_toggle_hankata(stash) "{{{
    let phase = a:stash.preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'hankata' ? 'hira' : 'hankata')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_toggle_kata(stash) "{{{
    let phase = a:stash.preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'kata' ? 'hira' : 'kata')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_ctrl_q_key(stash) "{{{
    let phase = a:stash.preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_HENKAN
    \   || phase ==# g:eskk#preedit#PHASE_OKURI
        call s:do_ctrl_q_key(a:stash)
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_q_key(stash) "{{{
    let phase = a:stash.preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_HENKAN
    \   || phase ==# g:eskk#preedit#PHASE_OKURI
        call s:do_q_key(a:stash)
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_l_key(stash) "{{{
    let phase = a:stash.preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_HENKAN
    \   || phase ==# g:eskk#preedit#PHASE_OKURI
        call s:do_l_key(a:stash)
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_ascii(stash) "{{{
    let preedit = a:stash.preedit
    let phase = preedit.get_henkan_phase()
    let buf_str = preedit.get_current_buf_str()
    if phase ==# g:eskk#preedit#PHASE_NORMAL
    \   && buf_str.rom_str.get() == ''
        call eskk#set_mode('ascii')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_zenei(stash) "{{{
    let preedit = a:stash.preedit
    let phase = preedit.get_henkan_phase()
    let buf_str = preedit.get_current_buf_str()
    if phase ==# g:eskk#preedit#PHASE_NORMAL
    \   && buf_str.rom_str.get() == ''
        call eskk#set_mode('zenei')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_abbrev(stash) "{{{
    let phase = a:stash.preedit.get_henkan_phase()
    let buf_str = a:stash.preedit.get_current_buf_str()
    if phase ==# g:eskk#preedit#PHASE_NORMAL
    \   && buf_str.rom_str.get() == ''
        call eskk#set_mode('abbrev')
        return 1
    endif
    return 0
endfunction "}}}
function! s:is_mode_local_char(char, type) "{{{
    " NOTE: This function must not show error
    " when `s:eskk_mappings[a:type]` does not exist.
    return has_key(s:eskk_mappings, a:type)
    \   && has_key(s:eskk_mappings[a:type], 'lhs')
    \   && eskk#util#key2char(s:eskk_mappings[a:type].lhs) ==# a:char
endfunction "}}}
function! s:handle_mode_local_char(char, type, stash) "{{{
    return s:is_mode_local_char(a:char, a:type)
    \   && has_key(s:eskk_mappings, a:type)
    \   && has_key(s:eskk_mappings[a:type], 'fn')
    \   && call(s:eskk_mappings[a:type].fn, [a:stash])
endfunction "}}}



" Filter
" s:asym_filter {{{
function! s:asym_filter(stash) "{{{
    let char = a:stash.char
    let preedit = a:stash.preedit
    let phase = preedit.get_henkan_phase()


    " Handle popupmenu-keys.
    if g:eskk#enable_completion &&
    \   mode() ==# 'i' && pumvisible()
    \   && phase is g:eskk#preedit#PHASE_HENKAN
    \   && s:handle_popupmenu_keys(a:stash)
        " Handled.
        return
    endif


    " Handle special mode-local mapping.
    for type in get(s:MODE_LOCAL_KEYS, eskk#get_mode(), [])
        if s:handle_mode_local_char(char, type, a:stash)
            " Handled.
            return
        endif
    endfor


    " Handle specific characters.
    " These characters are handled regardless of current phase.
    if char ==# "\<C-h>"
        call s:do_backspace(a:stash)
        return
    elseif char ==# "\<CR>"
        call s:do_enter(a:stash)
        return
    elseif char ==# ';'
        call s:do_sticky(a:stash)
        return
    elseif char ==# "\<C-g>"
        call s:do_cancel(a:stash)
        return
    elseif char ==# "\<Esc>"
        call s:do_escape(a:stash)
        return
    endif


    " Handle other characters.
    if phase ==# g:eskk#preedit#PHASE_NORMAL
        return s:filter_rom(a:stash, eskk#get_current_mode_table())
    elseif phase ==# g:eskk#preedit#PHASE_HENKAN
        if char ==# ' '
            call s:do_henkan(a:stash)
        else
            return s:filter_rom(a:stash, eskk#get_current_mode_table())
        endif
    elseif phase ==# g:eskk#preedit#PHASE_OKURI
        if char ==# ' '
            call s:do_henkan(a:stash)
        else
            return s:filter_rom(a:stash, eskk#get_current_mode_table())
        endif
    elseif phase ==# g:eskk#preedit#PHASE_HENKAN_SELECT
        if char ==# ' '
            call preedit.choose_next_candidate(a:stash)
            return
        elseif char ==# 'x'
            call preedit.choose_prev_candidate(a:stash)
            return
        elseif char ==# 'X'
            let henkan_result = eskk#get_skk_dict().get_henkan_result()
            if !empty(henkan_result)
                let prev_preedit =
                \   deepcopy(henkan_result.preedit)
                if henkan_result.delete_from_dict()
                    call eskk#set_preedit(prev_preedit)
                else
                    " Fail to delete current candidate...
                    " push current candidate and
                    " back to normal phase.
                    call eskk#logger#warn(
                    \   'Failed to delete current candidate...'
                    \)
                    sleep 1

                    call preedit.push_kakutei_str(
                    \   preedit.get_display_str(0)
                    \)
                    call preedit.set_henkan_phase(
                    \   g:eskk#preedit#PHASE_NORMAL
                    \)
                endif
            endif
        else
            call s:do_enter_egglike(a:stash)
            call preedit.push_filter_queue(char)
        endif
    else
        throw eskk#internal_error(
        \   ['eskk'],
        \   "s:asym_filter() does not support phase " . phase . "."
        \)
    endif
endfunction "}}}

" For specific characters

" Handle popupmenu-keys. (:help popupmenu-keys)
" If return value is 1, eskk does not filter a char.
" If return value is 0, eskk processes and insert a string.
function! s:handle_popupmenu_keys(stash) "{{{
    let preedit = a:stash.preedit
    let char = a:stash.char

    let inserted_str = preedit.get_inserted_str()
    let selected_default = inserted_str ==# preedit.get_display_str()
    let noinsert = &completeopt =~# 'noinsert'

    " NOTE: Do not call s:kakutei_pum() on 'selected_default ==# 1'.

    if char ==# "\<CR>" || char ==# "\<Tab>"
        if char ==# "\<Tab>" && g:eskk#tab_select_completion
            " Select next candidate
            call preedit.push_filter_pre_char("\<C-n>")
            return 1
        endif

        " Close popup and insert 'char'.
        if selected_default && !noinsert
            call s:do_enter_egglike(a:stash)
            call s:close_pum(a:stash)
        else
            call s:kakutei_pum(a:stash)
        endif
        return 0
    elseif char ==# "\<Space>"
        if selected_default
            if noinsert
                call preedit.push_filter_pre_char("\<C-e>")
            endif
            call s:close_pum(a:stash)
        else
            call s:kakutei_pum(a:stash)
        endif
        return 0
    elseif char ==# "\<BS>" || char ==# "\<C-h>"
        if !selected_default
            call s:kakutei_pum(a:stash)
        endif
        return 0
    elseif char ==# "\<C-y>"
        if selected_default
            call s:close_pum(a:stash)
        else
            call s:kakutei_pum(a:stash)
        endif
        return 1
    elseif char ==# "\<C-e>"
        let disp = preedit.get_display_str(0)
        call preedit.reset()
        call preedit.set_old_str(inserted_str)
        call preedit.kakutei(disp)
        return 1
    elseif char ==# "\<PageUp>" || char ==# "\<PageDown>"
    \   || char ==# "\<Up>"     || char ==# "\<Down>"
    \   || char ==# "\<C-n>"    || char ==# "\<C-p>"
        call preedit.push_filter_pre_char(char)
        return 1
    endif

    " Let filter function process the character.
    if !selected_default
        call s:kakutei_pum(a:stash)
    endif
    return 0
endfunction "}}}
function! s:kakutei_pum(stash) "{{{
    " Let Preedit not rewrite a buffer.
    " (eskk abandons a management of preedit)
    call a:stash.preedit.reset()
    " Close popup.
    call s:close_pum(a:stash)
endfunction "}}}
function! s:close_pum(stash) "{{{
    " Close popup.
    call a:stash.preedit.push_filter_pre_char("\<C-y>")
endfunction "}}}
function! s:do_backspace(stash) "{{{
    let preedit = a:stash.preedit
    if preedit.get_old_str() == ''
        call preedit.push_kakutei_str("\<C-h>")
        return
    endif

    let phase = preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_HENKAN_SELECT
        if g:eskk#delete_implies_kakutei
            " Enter normal phase and delete one character.
            let filter_str = eskk#util#mb_chop(preedit.get_display_str(0))
            call preedit.push_kakutei_str(filter_str)
            let henkan_select_buf_str = preedit.get_buf_str(
            \   g:eskk#preedit#PHASE_HENKAN_SELECT
            \)
            call henkan_select_buf_str.clear()

            call preedit.set_henkan_phase(g:eskk#preedit#PHASE_NORMAL)
            return
        else
            " Leave henkan select or back to previous candidate if it exists.
            call preedit.choose_prev_candidate(a:stash)
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
            let filter_str = eskk#util#mb_chop(preedit.get_display_str(0))
            call preedit.push_kakutei_str(filter_str)
            let henkan_select_buf_str = preedit.get_buf_str(
            \   g:eskk#preedit#PHASE_HENKAN_SELECT
            \)
            call henkan_select_buf_str.clear()

            call preedit.set_henkan_phase(g:eskk#preedit#PHASE_NORMAL)
            return
        else
            let filter_str = join(map(copy(p), 'v:val[1]'), '')
            let buf_str = preedit.get_buf_str(
            \   g:eskk#preedit#PHASE_HENKAN
            \)
            if filter_str !=# buf_str.rom_pairs.get_filter()
                call buf_str.rom_pairs.set(p)
                return
            endif
        endif
    endif

    " Delete previous characters.
    for phase in preedit.get_lower_phases()
        let buf_str = preedit.get_buf_str(phase)
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
        elseif preedit.get_marker(phase) != ''
            if !preedit.step_back_henkan_phase()
                let msg = "Normal phase's marker is empty, "
                \       . "and other phases *should* be able to change "
                \       . "current henkan phase."
                throw eskk#internal_error(['eskk', 'preedit'], msg)
            endif
            break
        endif
    endfor
endfunction "}}}
function! s:do_enter(stash) "{{{
    let times = s:get_enter_repeat_times(a:stash)
    for _ in range(times)
        call s:do_enter_egglike(a:stash)
    endfor
endfunction "}}}
function! s:get_enter_repeat_times(stash) "{{{
    if mode() ==# 'i' && pumvisible()
        " if mode() ==# 'i' && pumvisible() && a:stash.char ==# "\<CR>" ,
        " s:handle_popupmenu_keys() already closed pum.
        return g:eskk#egg_like_newline_completion ? 0 : 1
    endif
    let phase = a:stash.preedit.get_henkan_phase()
    if phase ==# g:eskk#preedit#PHASE_HENKAN
    \   || phase ==# g:eskk#preedit#PHASE_OKURI
    \   || phase ==# g:eskk#preedit#PHASE_HENKAN_SELECT
        return g:eskk#egg_like_newline ? 1 : 2
    endif
    " Default is <CR> once.
    return 1
endfunction "}}}
function! s:do_enter_egglike(stash) "{{{
    let preedit = a:stash.preedit
    let phase = preedit.get_henkan_phase()
    let undo_char = "\<C-g>u"
    let dict = eskk#get_skk_dict()
    let henkan_result = dict.get_henkan_result()

    if phase ==# g:eskk#preedit#PHASE_NORMAL
        call preedit.convert_rom_str_inplace(phase)
        call preedit.kakutei(preedit.get_display_str(0) . "\<CR>")
    elseif phase ==# g:eskk#preedit#PHASE_HENKAN
        call preedit.convert_rom_str_inplace(phase)
        if get(g:eskk#set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call preedit.push_filter_post_char(undo_char)
        endif

        if !empty(henkan_result)
            call henkan_result.update_rank()
        endif
        call preedit.kakutei(preedit.get_display_str(0))

    elseif phase ==# g:eskk#preedit#PHASE_OKURI
        call preedit.convert_rom_str_inplace(
        \   [g:eskk#preedit#PHASE_HENKAN, phase]
        \)
        if get(g:eskk#set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call preedit.push_filter_post_char(undo_char)
        endif

        if !empty(henkan_result)
            call henkan_result.update_rank()
        endif
        call preedit.kakutei(preedit.get_display_str(0))

    elseif phase ==# g:eskk#preedit#PHASE_HENKAN_SELECT
        call preedit.convert_rom_str_inplace(phase)
        if get(g:eskk#set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call preedit.push_filter_post_char(undo_char)
        endif

        if !empty(henkan_result)
            call henkan_result.update_rank()
        endif
        call preedit.kakutei(preedit.get_display_str(0))

    else
        throw eskk#internal_error(['eskk', 'preedit'])
    endif
endfunction "}}}
function! s:do_sticky(stash) "{{{
    let preedit = a:stash.preedit
    let phase   = preedit.get_henkan_phase()
    let buf_str = preedit.get_current_buf_str()

    " Convert rom_str if possible.
    call preedit.convert_rom_str_inplace([
    \   g:eskk#preedit#PHASE_HENKAN,
    \   g:eskk#preedit#PHASE_OKURI
    \])

    if phase ==# g:eskk#preedit#PHASE_NORMAL
        if !buf_str.rom_str.empty()
        \   || !buf_str.rom_pairs.empty()
            call preedit.convert_rom_str_inplace(phase)
            call preedit.push_kakutei_str(preedit.get_display_str(0))
            call buf_str.clear()
        endif
        if get(g:eskk#set_undo_point, 'sticky', 0) && mode() ==# 'i'
            call preedit.push_filter_pre_char("\<C-g>u")
        endif
        call preedit.set_begin_col(col('.'))
        call preedit.set_henkan_phase(g:eskk#preedit#PHASE_HENKAN)
    elseif phase ==# g:eskk#preedit#PHASE_HENKAN
        if !buf_str.rom_str.empty()
        \   || !buf_str.rom_pairs.empty()
            call preedit.set_henkan_phase(g:eskk#preedit#PHASE_OKURI)
        endif
    elseif phase ==# g:eskk#preedit#PHASE_OKURI
        " nop
    elseif phase ==# g:eskk#preedit#PHASE_HENKAN_SELECT
        call s:do_enter_egglike(a:stash)
        call s:do_sticky(a:stash)
        " Fix begin col which was set by s:do_sticky().
        " "▼漢字" => "漢字" (by s:do_enter_egglike())
        let begin_col = preedit.get_begin_col()
        call eskk#util#assert(begin_col ># 0, 'begin_col ># 0')
        call preedit.set_begin_col(begin_col - strlen(g:eskk#marker_henkan_select))
    else
        throw eskk#internal_error(['eskk', 'preedit'])
    endif
endfunction "}}}
function! s:do_cancel(stash) "{{{
    let preedit = a:stash.preedit
    if mode() ==# 'c'
        call preedit.push_filter_pre_char("\<Esc>")
    else
        call preedit.set_henkan_phase(g:eskk#preedit#PHASE_NORMAL)
        call preedit.clear_all()
    endif
endfunction "}}}
function! s:do_escape(stash) "{{{
    let preedit = a:stash.preedit
    call preedit.convert_rom_str_inplace(
    \   preedit.get_henkan_phase()
    \)

    if g:eskk#rom_input_style ==# 'skk'
        let with_rom_str = 0
    elseif g:eskk#rom_input_style ==# 'msime'
        let with_rom_str = 1
    else
        throw eskk#internal_error(
        \   ['eskk'],
        \   "invalid g:eskk#rom_input_style value. (" . g:eskk#rom_input_style . ")"
        \)
    endif
    let kakutei_str = preedit.get_display_str(0, with_rom_str)
    call preedit.kakutei(kakutei_str . "\<Esc>")
endfunction "}}}
function! s:do_henkan(stash, ...) "{{{
    let preedit = a:stash.preedit
    let convert_at_exact_match = a:0 ? a:1 : 0
    let phase = preedit.get_henkan_phase()

    if preedit.get_current_buf_str().empty()
        return
    endif

    if phase isnot g:eskk#preedit#PHASE_HENKAN
    \   && phase isnot g:eskk#preedit#PHASE_OKURI
        return
    endif

    if eskk#get_mode() ==# 'abbrev'
        call s:do_henkan_abbrev(a:stash, convert_at_exact_match)
    else
        call s:do_henkan_other(a:stash, convert_at_exact_match)
    endif
endfunction "}}}
function! s:do_henkan_abbrev(stash, convert_at_exact_match) "{{{
    let preedit = a:stash.preedit
    let henkan_buf_str = preedit.get_buf_str(
    \   g:eskk#preedit#PHASE_HENKAN
    \)
    let henkan_select_buf_str = preedit.get_buf_str(
    \   g:eskk#preedit#PHASE_HENKAN_SELECT
    \)

    let rom_str = henkan_buf_str.rom_str.get()
    let dict = eskk#get_skk_dict()

    try
        let henkan_result = dict.refer(preedit, rom_str, '', '')
        let candidate = henkan_result.get_current_candidate()
        " No thrown exception. continue...

        call preedit.clear_all()
        if a:convert_at_exact_match
            call henkan_buf_str.rom_pairs.set_one_pair(rom_str, candidate, {'converted': 1})
        else
            call henkan_select_buf_str.rom_pairs.set_one_pair(rom_str, candidate, {'converted': 1})
            call preedit.set_henkan_phase(
            \   g:eskk#preedit#PHASE_HENKAN_SELECT
            \)
        endif
    catch /^eskk: dictionary look up error/
        " No candidates.
        let result =
        \   dict.remember_word_prompt_hr(
        \      dict.get_henkan_result()
        \   )
        let [input, okuri] = [result[0], result[2]]
        if input != ''
            call preedit.kakutei(input . okuri)
        endif
    endtry
endfunction "}}}
function! s:do_henkan_other(stash, convert_at_exact_match) "{{{
    let preedit = a:stash.preedit
    let phase = preedit.get_henkan_phase()

    " NOTE:
    " Preedit.convert_rom_all_inplace() sets a new reference not a value.
    " This makes all reference values of
    " Preedit.get_buf_str()'s return values invalid.
    if g:eskk#kata_convert_to_hira_at_henkan
    \   && eskk#get_mode() ==# 'kata'
        call preedit.convert_rom_all_inplace(
        \   [
        \       g:eskk#preedit#PHASE_HENKAN,
        \       g:eskk#preedit#PHASE_OKURI,
        \   ],
        \   eskk#get_mode_table('hira')
        \)
    endif

    let henkan_buf_str = preedit.get_buf_str(
    \   g:eskk#preedit#PHASE_HENKAN
    \)
    let okuri_buf_str = preedit.get_buf_str(
    \   g:eskk#preedit#PHASE_OKURI
    \)
    let henkan_select_buf_str = preedit.get_buf_str(
    \   g:eskk#preedit#PHASE_HENKAN_SELECT
    \)

    " Convert rom_str if possible.
    call preedit.convert_rom_str_inplace([
    \   g:eskk#preedit#PHASE_HENKAN,
    \   g:eskk#preedit#PHASE_OKURI
    \])

    if g:eskk#fix_extra_okuri
    \   && !henkan_buf_str.rom_str.empty()
    \   && phase ==# g:eskk#preedit#PHASE_HENKAN
        call okuri_buf_str.rom_str.set(henkan_buf_str.rom_str.get())
        call henkan_buf_str.rom_str.clear()
        call preedit.set_henkan_phase(g:eskk#preedit#PHASE_OKURI)
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
        let henkan_result = dict.refer(preedit, hira, okuri, okuri_rom)
        let candidate = henkan_result.get_current_candidate()

        call preedit.clear_all()
        if a:convert_at_exact_match
            call henkan_buf_str.rom_pairs.set_one_pair(rom_str, candidate, {'converted': 1})
        else
            call henkan_select_buf_str.rom_pairs.set_one_pair(rom_str, candidate, {'converted': 1})
            call preedit.set_henkan_phase(
            \   g:eskk#preedit#PHASE_HENKAN_SELECT
            \)
            if g:eskk#kakutei_when_unique_candidate
            \   && !henkan_result.has_next()
                call preedit.kakutei(preedit.get_display_str(0))
            endif
        endif
    catch /^eskk: dictionary look up error/
        " No candidates.
        let [input, hira, okuri] =
        \   dict.remember_word_prompt_hr(
        \      dict.get_henkan_result()
        \   )
        if input != ''
            call preedit.kakutei(input . okuri)
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
    let preedit = a:stash.preedit
    call preedit.convert_rom_str_inplace(
    \   preedit.get_henkan_phase()
    \)
    call preedit.convert_rom_all_inplace([
    \   g:eskk#preedit#PHASE_NORMAL,
    \   g:eskk#preedit#PHASE_HENKAN,
    \   g:eskk#preedit#PHASE_OKURI,
    \], a:table)
    call preedit.kakutei(preedit.get_display_str(0))
endfunction "}}}

" For other characters
function! s:filter_rom(stash, table) "{{{
    let char = a:stash.char
    let preedit = a:stash.preedit
    let buf_str = preedit.get_current_buf_str()
    let rom_str = buf_str.rom_str.get() . char

    if preedit.get_henkan_phase() is g:eskk#preedit#PHASE_OKURI
        return s:filter_rom_okuri(a:stash, a:table)
    elseif a:table.has_n_candidates(rom_str, 2)
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
function! s:filter_rom_okuri(stash, table) "{{{
    " Input #1: "SesS"
    " Convert from:
    "   char: "s"
    "   henkan buf str:
    "     filter str: "せ"
    "     rom str   : "s"
    "   okuri buf str:
    "     filter str: ""
    "     rom str   : ""
    " Convert to:
    "   henkan buf str:
    "     filter str: "せっ"
    "     rom str   : ""
    "   okuri buf str:
    "     filter str: ""
    "     rom str   : "s"
    " (http://d.hatena.ne.jp/tyru/20100320/eskk_rom_to_hira)
    "
    " Input #2: "KikO"
    " Convert from:
    "   char: "o"
    "   henkan buf str:
    "     filter str: "き"
    "     rom str   : "k"
    "   okuri buf str:
    "     filter str: ""
    "     rom str   : ""
    " Convert to:
    "   henkan buf str:
    "     filter str: "き"
    "     rom str   : ""
    "   okuri buf str:
    "     filter str: "こ"
    "     rom str   : ""

    let char = a:stash.char
    let preedit = a:stash.preedit
    let henkan_buf_str = preedit.get_buf_str(
    \   g:eskk#preedit#PHASE_HENKAN
    \)
    let okuri_buf_str = preedit.get_buf_str(
    \   g:eskk#preedit#PHASE_OKURI
    \)
    let rom_str = henkan_buf_str.rom_str.get() . char
    " Input #1.
    if !henkan_buf_str.rom_str.empty()
    \   && okuri_buf_str.rom_str.empty()
    \   && a:table.has_map(rom_str)
        call henkan_buf_str.rom_str.clear()
        call henkan_buf_str.rom_pairs.push_one_pair(
        \   rom_str,
        \   a:table.get_map(rom_str),
        \   {'converted': 1}
        \)
        let rest = a:table.get_rest(rom_str, -1)
        if rest !=# -1
            call okuri_buf_str.rom_str.set(rest)
        elseif g:eskk#fix_extra_okuri
            " Input #2.
            call okuri_buf_str.rom_pairs.push(
            \   henkan_buf_str.rom_pairs.pop()
            \)
            if g:eskk#auto_henkan_at_okuri_match
            \   && a:table.has_map(okuri_buf_str.rom_str.get() . char)
                call s:do_henkan(a:stash)
            endif
        endif

        return
    endif

    let rom_str = okuri_buf_str.rom_str.get() . char
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
    let preedit = a:stash.preedit
    let buf_str = preedit.get_current_buf_str()
    let rom_str = buf_str.rom_str.get() . char
    let phase = preedit.get_henkan_phase()

    if phase ==# g:eskk#preedit#PHASE_NORMAL
    \   || phase ==# g:eskk#preedit#PHASE_HENKAN
        " Set filtered string.
        call buf_str.rom_pairs.push_one_pair(rom_str, a:table.get_map(rom_str), {'converted': 1})
        call buf_str.rom_str.clear()


        " Queueing rest string.
        "
        " NOTE:
        " rest must not have multibyte string.
        " rest is for rom string.
        let rest = a:table.get_rest(rom_str, -1)
        " Assumption: 'a:table.has_map(rest)' returns false here.
        if rest !=# -1
            for rest_char in split(rest, '\zs')
                call preedit.push_filter_queue(rest_char)
            endfor
        endif

        if g:eskk#convert_at_exact_match
        \   && phase ==# g:eskk#preedit#PHASE_HENKAN
            let st = eskk#get_current_mode_structure()
            let henkan_buf_str = preedit.get_buf_str(
            \   g:eskk#preedit#PHASE_HENKAN
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
    elseif phase ==# g:eskk#preedit#PHASE_OKURI
        call eskk#util#assert(
        \   a:table.has_map(rom_str),
        \   'a:table.has_map(rom_str) ==# 1')

        call buf_str.rom_str.clear()

        call buf_str.rom_pairs.push_one_pair(
        \   rom_str,
        \   a:table.get_map(rom_str),
        \   {'converted': 1}
        \)
        let rest = a:table.get_rest(rom_str, -1)
        if rest !=# -1
            for rest_char in split(rest, '\zs')
                call preedit.push_filter_queue(rest_char)
            endfor
        elseif g:eskk#auto_henkan_at_okuri_match
            call s:do_henkan(a:stash)
        endif
    endif
endfunction "}}}
function! s:filter_rom_has_candidates(stash) "{{{
    let buf_str  = a:stash.preedit.get_current_buf_str()
    call buf_str.rom_str.append(a:stash.char)
endfunction "}}}
function! s:filter_rom_no_match(stash, table) "{{{
    let char = a:stash.char
    let buf_str = a:stash.preedit.get_current_buf_str()
    let rom_str_without_char = buf_str.rom_str.get()

    let NO_MAP = []
    let map = a:table.get_map(rom_str_without_char, NO_MAP)
    if map isnot NO_MAP
        " `rom_str_without_char` had the map at previous eskk#filter().
        " but fail at `char`.
        " e.g.: rom_str is "nj" => "んj"
        call buf_str.rom_pairs.push_one_pair(rom_str_without_char, map, {'converted': 1})
        " *** FALLTHROUGH ***
    elseif empty(rom_str_without_char)
        " No candidates started with such a character `char`.
        " e.g.: rom_str is " ", "&"
        call buf_str.rom_pairs.push_one_pair(char, char)
        return
    else
        " `rom_str_without_char` had the candidate(s) at previous eskk#filter().
        " but fail at `char`.
        if g:eskk#rom_input_style ==# 'skk'
            " rom_str is "zyk" => "k"
        elseif g:eskk#rom_input_style ==# 'msime'
            " rom_str is "zyk" => "zyk"
            call buf_str.rom_pairs.push_one_pair(
            \   rom_str_without_char, rom_str_without_char
            \)
        else
            throw eskk#internal_error(
            \   ['eskk'],
            \   "invalid g:eskk#rom_input_style value. (" . g:eskk#rom_input_style . ")"
            \)
        endif
        " *** FALLTHROUGH ***
    endif

    " Handle `char`.
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
    if a:stash.char ==# "\<C-j>"
        call eskk#set_mode('hira')
    else
        if eskk#has_mode_table('ascii')
            if !has_key(this.temp, 'table')
                let this.temp.table = eskk#get_mode_table('ascii')
            endif
            call a:stash.preedit.push_kakutei_str(
            \   this.temp.table.get_map(
            \      a:stash.char, a:stash.char
            \   )
            \)
        else
            call a:stash.preedit.push_kakutei_str(a:stash.char)
        endif
    endif
endfunction "}}}
function! s:zenei_filter(stash) "{{{
    let this = eskk#get_mode_structure('zenei')
    if a:stash.char ==# "\<C-j>"
        call eskk#set_mode('hira')
    else
        if !has_key(this.temp, 'table')
            let this.temp.table = eskk#get_mode_table('zenei')
        endif
        call a:stash.preedit.push_kakutei_str(
        \   this.temp.table.get_map(
        \      a:stash.char, a:stash.char
        \   )
        \)
    endif
endfunction "}}}
function! s:abbrev_filter(stash) "{{{
    let char = a:stash.char
    let preedit = a:stash.preedit
    let buf_str = preedit.get_current_buf_str()
    let phase = preedit.get_henkan_phase()

    " Handle special characters.
    " These characters are handled regardless of current phase.
    if char ==# "\<C-g>"
        call s:do_cancel(a:stash)
        call eskk#set_mode('hira')
        return
    elseif char ==# "\<C-h>"
        if buf_str.rom_str.get() == ''
            " If backspace-key was pressed at empty string,
            " leave abbrev mode.
            call eskk#set_mode('hira')
        else
            call s:do_backspace(a:stash)
        endif
        return
    elseif char ==# "\<CR>"
        call s:do_enter_egglike(a:stash)
        call eskk#set_mode('hira')
        return
    endif

    " Handle other characters.
    if phase ==# g:eskk#preedit#PHASE_HENKAN
        if char ==# ' '
            call s:do_henkan(a:stash)
        else
            call buf_str.rom_str.append(char)
        endif
    elseif phase ==# g:eskk#preedit#PHASE_HENKAN_SELECT
        if char ==# ' '
            call preedit.choose_next_candidate(a:stash)
            return
        elseif char ==# 'x'
            call preedit.choose_prev_candidate(a:stash)
            return
        else
            call preedit.push_kakutei_str(
            \   preedit.get_display_str(0)
            \)
            call preedit.clear_all()
            call preedit.push_filter_queue(char)

            " Leave abbrev mode.
            call eskk#set_mode('hira')
        endif
    else
        throw eskk#internal_error(
        \   ['eskk'],
        \   "'abbrev' mode does not support phase " . phase . "."
        \)
    endif
endfunction "}}}

" Preprocessor
function! s:asym_prefilter(stash) "{{{
    let char = a:stash.char
    " 'X' is phase:henkan-select:delete-from-dict
    " 'L' is mode:{hira,kata,hankata}:to-zenei
    if char ==# 'X' || char ==# 'L'
        return [char]
    elseif char =~# '^[A-Z]$'
        " Treat uppercase "A" in "SAkujo" as lowercase.
        "
        " Assume "SAkujo" as "Sakujo":
        "   S => phase: 0, rom_str: '', rom_pairs: ''
        "   A => phase: 1, rom_str: 's', rom_pairs: ''
        "               (!buf_str.rom_str.empty() && buf_str.rom_pairs.empty())
        "   k => phase: 1, rom_str: '', rom_pairs: ['さ', 'sa', {'converted': 1}]
        "   u => phase: 1, rom_str: 'k', rom_pairs: ['さ', 'sa', {'converted': 1}]
        let buf_str = a:stash.preedit.get_current_buf_str()
        if !buf_str.rom_str.empty() && buf_str.rom_pairs.empty()
            return [tolower(char)]
        else
            return [';', tolower(char)]
        endif
    elseif char ==# "\<BS>"
        return ["\<C-h>"]
    else
        return [char]
    endif
endfunction "}}}
function! s:abbrev_prefilter(stash) "{{{
    let char = a:stash.char
    if char ==# "\<BS>"
        return ["\<C-h>"]
    else
        return [char]
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
    if v:version < 703 || v:version == 703 && !has('patch32')
        call eskk#logger#warn(
        \   "eskk.vim: warning: Your Vim is too old."
        \   . " Please use 7.3.32 at least."
        \)
        " do not initialize eskk
        " if user doesn't fill requirements!
        return
    endif
    " }}}

    " Create the first eskk instance. {{{
    call eskk#initialize_instance()
    " }}}

    " Create eskk augroup. {{{
    augroup eskk
        autocmd!
    augroup END
    " }}}

    " Global Variables (do setup before eskk-initialize-pre) {{{

    " Debug
    call eskk#util#set_default('g:eskk#log_cmdline_level',
    \   get(g:, 'eskk#debug', 0) ? 2 : 0)
    call eskk#util#set_default('g:eskk#log_file_level',
    \   get(g:, 'eskk#debug', 0) ? 2 : 0)
    call eskk#util#set_default('g:eskk#debug_wait_ms', 0)
    call eskk#util#set_default('g:eskk#directory', '~/.eskk')

    if exists('g:eskk#server') && !has('channel') && !eskk#util#has_vimproc()
        call eskk#logger#warn(
        \   "eskk.vim: warning: cannot use skkserv " .
        \   "because vimproc is not installed."
        \)
        let g:eskk#server = {}
    else
        call eskk#util#set_default('g:eskk#server', {})
    endif

    " Dictionary
    for [varname, default] in [
    \   ['g:eskk#dictionary', {
    \       'path': expand("~/.skk-jisyo"),
    \       'sorted': 0,
    \       'encoding': 'utf-8',
    \   }],
    \   ['g:eskk#large_dictionary', {
    \       'path': "/usr/local/share/skk/SKK-JISYO.L",
    \       'sorted': 1,
    \       'encoding': 'euc-jp',
    \   }],
    \]
        if exists(varname)
            if type({varname}) == type("")
                let default.path = {varname}
                unlet {varname}
                let {varname} = default
            elseif type({varname}) == type({})
                call extend({varname}, default, "keep")
            else
                call eskk#logger#warn(
                \   varname . "'s type is either String or Dictionary."
                \)
            endif
        else
            let {varname} = default
        endif
        let {varname}.path = expand({varname}.path)
    endfor

    " Show warning if dictionary does not exist.
    for dict in [g:eskk#dictionary, g:eskk#large_dictionary]
        if !filereadable(dict.path)
            call eskk#logger#warnf(
            \   "Cannot read SKK dictionary: %s", dict.path
            \)
            sleep 1
        endif
    endfor


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

    " Markers
    call eskk#util#set_default('g:eskk#marker_henkan', '▽')
    call eskk#util#set_default('g:eskk#marker_okuri', '*')
    call eskk#util#set_default('g:eskk#marker_henkan_select', '▼')
    call eskk#util#set_default('g:eskk#marker_jisyo_touroku', '?')

    " Completion
    call eskk#util#set_default('g:eskk#enable_completion', 1)
    call eskk#util#set_default('g:eskk#max_candidates', 30)
    call eskk#util#set_default('g:eskk#start_completion_length', 3)
    call eskk#util#set_default('g:eskk#register_completed_word', 1)
    call eskk#util#set_default('g:eskk#egg_like_newline_completion', 0)
    call eskk#util#set_default('g:eskk#tab_select_completion', 0)

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

    " Lua
    call eskk#util#set_default('g:eskk#disable_if_lua', 0)

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

    " Throw "eskk-initialize-pre" autocmd event. {{{
    " NOTE: If no "User eskk-initialize-pre" events,
    " Vim complains like "No matching autocommands".
    if exists('#User#eskk-initialize-pre')
        doautocmd User eskk-initialize-pre
    endif
    " }}}

    " Set up g:eskk#directory. {{{
    function! s:initialize_set_up_eskk_directory()
        let dir = eskk#util#join_path(expand(g:eskk#directory), 'log')
        call eskk#util#mkdir_nothrow(dir, 'p')
        if !isdirectory(dir)
            call eskk#logger#write_error_log_file(
            \       {}, printf("can't create directory '%s'.", dir))
        endif
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

    EskkMap -type=kakutei <C-j>

    EskkMap -type=sticky ;
    EskkMap -type=general Q ;
    EskkMap -type=backspace-key <C-h>
    EskkMap -type=enter-key <CR>
    EskkMap -type=escape-key <Esc>
    EskkMap -type=tab <Tab>

    EskkMap -type=cancel <C-g>

    EskkMap -type=phase:henkan:henkan-key <Space>

    EskkMap -type=phase:okuri:henkan-key <Space>

    EskkMap -type=phase:henkan-select:choose-next <Space>
    EskkMap -type=phase:henkan-select:choose-prev x

    EskkMap -type=phase:henkan-select:next-page <Space>
    EskkMap -type=phase:henkan-select:prev-page x

    EskkMap -type=phase:henkan-select:escape <C-g>

    EskkMap -type=phase:henkan-select:delete-from-dict X

    EskkMap -type=mode:hira:toggle-hankata <C-q>
    EskkMap -type=mode:hira:ctrl-q-key <C-q>
    EskkMap -type=mode:hira:toggle-kata q
    EskkMap -type=mode:hira:q-key q
    EskkMap -type=mode:hira:l-key l
    EskkMap -type=mode:hira:to-ascii l
    EskkMap -type=mode:hira:to-zenei L
    EskkMap -type=mode:hira:to-abbrev /

    EskkMap -type=mode:kata:toggle-hankata <C-q>
    EskkMap -type=mode:kata:ctrl-q-key <C-q>
    EskkMap -type=mode:kata:toggle-kata q
    EskkMap -type=mode:kata:q-key q
    EskkMap -type=mode:kata:l-key l
    EskkMap -type=mode:kata:to-ascii l
    EskkMap -type=mode:kata:to-zenei L
    EskkMap -type=mode:kata:to-abbrev /

    EskkMap -type=mode:hankata:toggle-hankata <C-q>
    EskkMap -type=mode:hankata:ctrl-q-key <C-q>
    EskkMap -type=mode:hankata:toggle-kata q
    EskkMap -type=mode:hankata:q-key q
    EskkMap -type=mode:hankata:l-key l
    EskkMap -type=mode:hankata:to-ascii l
    EskkMap -type=mode:hankata:to-zenei L
    EskkMap -type=mode:hankata:to-abbrev /

    EskkMap -type=mode:ascii:to-hira <C-j>

    EskkMap -type=mode:zenei:to-hira <C-j>

    EskkMap -type=mode:abbrev:henkan-key <Space>
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
        \   'filter': eskk#util#get_local_funcref('ascii_filter', s:SID_PREFIX),
        \})
        " }}}

        " 'zenei' mode {{{
        call eskk#register_mode_structure('zenei', {
        \   'filter': eskk#util#get_local_funcref('zenei_filter', s:SID_PREFIX),
        \   'table': eskk#table#new_from_file('rom_to_zenei'),
        \})
        " }}}

        " 'hira' mode {{{
        call eskk#register_mode_structure('hira', {
        \   'filter': eskk#util#get_local_funcref('asym_filter', s:SID_PREFIX),
        \   'prefilter': eskk#util#get_local_funcref('asym_prefilter', s:SID_PREFIX),
        \   'table': eskk#table#new_from_file('rom_to_hira'),
        \})
        " }}}

        " 'kata' mode {{{
        call eskk#register_mode_structure('kata', {
        \   'filter': eskk#util#get_local_funcref('asym_filter', s:SID_PREFIX),
        \   'prefilter': eskk#util#get_local_funcref('asym_prefilter', s:SID_PREFIX),
        \   'table': eskk#table#new_from_file('rom_to_kata'),
        \})
        " }}}

        " 'hankata' mode {{{
        call eskk#register_mode_structure('hankata', {
        \   'filter': eskk#util#get_local_funcref('asym_filter', s:SID_PREFIX),
        \   'prefilter': eskk#util#get_local_funcref('asym_prefilter', s:SID_PREFIX),
        \   'table': eskk#table#new_from_file('rom_to_hankata'),
        \})
        " }}}

        " 'abbrev' mode {{{
        let dict = {}

        let dict.prefilter = eskk#util#get_local_funcref('abbrev_prefilter', s:SID_PREFIX)
        let dict.filter = eskk#util#get_local_funcref('abbrev_filter', s:SID_PREFIX)
        let dict.init_phase = g:eskk#preedit#PHASE_HENKAN

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

    " InsertEnter: Clear preedit. {{{
    function! s:reset_preedit()
        " avoid :call bug when chained by dot after function call.
        let preedit = eskk#get_preedit()
        call preedit.reset()
    endfunction
    autocmd eskk InsertEnter * call s:reset_preedit()
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

    " InsertLeave: Restore &backspace value {{{
    " NOTE: Due to current implementation,
    " s:preedit.rewrite() assumes that &backspace contains "eol".
    if &l:backspace !~# '\<eol\>'
        setlocal backspace+=eol
        autocmd eskk InsertEnter * setlocal backspace+=eol
        autocmd eskk InsertLeave * setlocal backspace-=eol
    endif
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
    if exists('#User#eskk-initialize-post')
        doautocmd User eskk-initialize-post
    endif
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
    autocmd eskk InsertLeave * call s:save_restore_formatoptions(0)
    " }}}

    " Log startup/shutdown info. {{{
    call eskk#logger#debug('----- eskk.vim was started. -----')
    autocmd eskk VimLeavePre *
    \       call eskk#logger#debug('----- Vim is exiting... -----')
    " }}}

    " Flush log. {{{
    " NOTE: This auto-command must be at the end of eskk#_initialize().
    autocmd eskk CursorHold,VimLeavePre *
    \            call eskk#logger#write_debug_log_file()
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
    \   "<Esc>",
    \]
endfunction "}}}

" Enable/Disable IM
function! eskk#is_enabled() "{{{
    return eskk#is_initialized()
    \   && &iminsert is 1
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
        " Initialize mode.
        call eskk#set_mode(g:eskk#initial_mode)
        return ''
    endif
    if exists('b:skk_on') && b:skk_on
        call eskk#logger#warn('skk.vim is enabled. please disable it.')
        return ''
    endif

    if exists('#User#eskk-enable-pre')
        doautocmd User eskk-enable-pre
    endif
    let inst = eskk#get_current_instance()

    call s:save_restore_formatoptions(1)

    " Clear current variable states.
    let inst.mode = ''
    let preedit = eskk#get_preedit()
    call preedit.reset()

    " Map all lang-mode keymappings.
    call eskk#map#map_all_keys()

    " Initialize mode.
    call eskk#set_mode(g:eskk#initial_mode)

    " Save previous omnifunc.
    if g:eskk#enable_completion
        let inst.omnifunc_save = &l:omnifunc
        let &l:omnifunc = 'eskk#complete#eskkcomplete'
    endif

    if mode() =~# '^[ic]$'
        " NOTE: Vim can't enter lang-mode immediately
        " in insert-mode or commandline-mode.
        " We have to use i_CTRL-^ .
        setlocal iminsert=1 imsearch=1
        redrawstatus
        let ret = "\<C-^>"
    else
        setlocal iminsert=1 imsearch=1
        redrawstatus
        let ret = ''
    endif
    if exists('#User#eskk-enable-post')
        doautocmd User eskk-enable-post
    endif
    return ret
endfunction "}}}
function! eskk#disable() "{{{
    if !eskk#is_initialized()
        call eskk#logger#warn('eskk is not initialized.')
        return ''
    endif
    if !eskk#is_enabled()
        return ''
    endif

    if exists('#User#eskk-disable-pre')
        doautocmd User eskk-disable-pre
    endif
    let inst = eskk#get_current_instance()

    call s:save_restore_formatoptions(0)

    " Unmap all lang-mode keymappings.
    call eskk#map#unmap_all_keys()

    if has_key(inst, 'omnifunc_save')
        let &l:omnifunc = remove(inst, 'omnifunc_save')
    elseif &l:omnifunc ==# 'eskk#complete#eskkcomplete'
        let &l:omnifunc = ''
    endif

    if mode() =~# '^[ic]$'
        " NOTE: Vim can't escape lang-mode immediately
        " in insert-mode or commandline-mode.
        " We have to use i_CTRL-^ .
        setlocal iminsert=0 imsearch=0
        redrawstatus
        let kakutei_str = eskk#get_preedit().generate_kakutei_str()
        let ret = kakutei_str . "\<C-^>"
    else
        setlocal iminsert=0 imsearch=0
        redrawstatus
        let ret = ''
    endif
    if exists('#User#eskk-disable-post')
        doautocmd User eskk-disable-post
    endif
    return ret
endfunction "}}}

" Mode
function! eskk#set_mode(next_mode) "{{{
    let inst = eskk#get_current_instance()
    if !eskk#is_supported_mode(a:next_mode)
        call eskk#logger#warn(
        \   "mode '" . a:next_mode . "' is not supported."
        \)
        call eskk#logger#warn(
        \   's:available_modes = ' . string(s:available_modes)
        \)
        return
    endif
    " Change mode.
    let inst.mode = a:next_mode
    " Set cursor color.
    call eskk#set_cursor_color()
    " Clear preedit.
    let preedit = eskk#get_preedit()
    call preedit.clear_all()
    " Set initial henkan phase.
    let st = eskk#get_current_mode_structure()
    call preedit.set_henkan_phase(
    \   (has_key(st, 'init_phase') ?
    \       st.init_phase
    \       : g:eskk#preedit#PHASE_NORMAL)
    \)
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
    if !s:check_mode_structure(a:mode, a:st)
        call eskk#util#warn('eskk#register_mode_structure(): a invalid structure was given!')
        return
    endif

    let s:available_modes[a:mode] = a:st
    let s:available_modes[a:mode].temp = {}

    if has_key(a:st, 'table')
        call eskk#register_mode_table(a:mode, a:st.table)
    endif
endfunction "}}}
function! s:check_mode_structure(mode, st) "{{{
    " Check required keys.
    for key in ['filter']
        if !has_key(a:st, key)
            call eskk#logger#warn(
            \   "s:check_mode_structure(): "
            \       . string(a:mode) . ": "
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
    if !eskk#is_supported_mode(a:mode)
        call eskk#logger#warn(
        \   "mode '" . a:mode . "' is not available."
        \)
    endif
    return s:available_modes[a:mode]
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

" Preedit
function! eskk#get_preedit() "{{{
    let inst = eskk#get_current_instance()
    if empty(inst.preedit)
        let inst.preedit = eskk#preedit#new()
    endif
    return inst.preedit
endfunction "}}}
function! eskk#set_preedit(preedit) "{{{
    let inst = eskk#get_current_instance()
    call a:preedit.set_old_str(
    \   empty(inst.preedit) ? '' : inst.preedit.get_old_str()
    \)
    let inst.preedit = a:preedit
endfunction "}}}

" Filter
function! eskk#filter(char) "{{{
    try
        let inst = eskk#get_current_instance()
        let st = eskk#get_mode_structure(inst.mode)
        let preedit = eskk#get_preedit()
        let stash = {
        \   'char': a:char,
        \   'preedit': preedit,
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

        " Log pressed char.
        call eskk#logger#debug('eskk#filter(): char = ' . string(a:char))

        " Detect invalid rewrite; which means
        " preedit's display string and
        " inserted string in buffer are not same.
        let old_str = preedit.get_display_str()

        " FIXME: Disable temporarily.
        " if mode() ==# 'i'
        "     let colidx = col('.')-2
        "     let inserted_str = getline('.')[colidx-strlen(old_str)+1 : colidx]
        "     if preedit.get_henkan_phase() > g:eskk#preedit#PHASE_NORMAL &&
        "     \   old_str !=# inserted_str
        "         call eskk#logger#warn('invalid rewrite of buffer was detected.'
        "         \                   . ' reset preedit status...: '
        "         \                   . string([old_str, inserted_str]))
        "         for l in preedit.dump()
        "             call eskk#logger#info(l)
        "         endfor
        "
        "         sleep 1
        "         call preedit.reset()
        "         return ''
        "     endif
        " endif

        " Set old display string. (it is used by Preedit.rewrite())
        call preedit.set_old_str(old_str)

        " Push a pressed character.
        for c in has_key(st, 'prefilter') ?
        \           st.prefilter(stash) : [a:char]
            call preedit.push_filter_queue(c)
        endfor

        while 1
            " Do loop until queue becomes empty.
            " NOTE: `preedit` may be changed from previous call.
            " so get it every loop.
            let preedit = eskk#get_preedit()
            if preedit.empty_filter_queue()
                break
            endif

            " Convert `stash.char` and make modifications to preedit.
            let stash.char = preedit.shift_filter_queue()
            " NOTE: `inst` (e.g., `inst.mode`) and `st`
            " may be changed from previous call.
            " so get it every loop.
            let inst = eskk#get_current_instance()
            let st = eskk#get_mode_structure(inst.mode)
            call st.filter(stash)

            " If eskk is disabled by user input,
            " disable lang-mode and escape eskk#filter().
            if !eskk#is_enabled()
                " NOTE: Vim can't escape lang-mode immediately
                " in insert-mode or commandline-mode.
                " We have to use i_CTRL-^ .
                let kakutei_str = preedit.generate_kakutei_str()
                return kakutei_str . "\<C-^>"
            endif
        endwhile

        " NOTE: `preedit` may become invalid reference
        " because `st.filter(stash)` may call `eskk#set_preedit()`.
        return eskk#get_preedit().rewrite()

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
        " In normal phase, clear rom_pairs each time.
        if preedit.get_henkan_phase() ==# g:eskk#preedit#PHASE_NORMAL
            let cur_buf_str = preedit.get_current_buf_str()
            call cur_buf_str.rom_pairs.clear()
        endif
        " Set old string. (it is used by Preedit.rewrite())
        call preedit.set_old_str(preedit.get_display_str())
        " Write debug log file each time 100 keys were pressed.
        let s:filter_count += 1
        if s:filter_count >=# 100
            call eskk#logger#write_debug_log_file()
            let s:filter_count = 0
        endif
    endtry
endfunction "}}}
function! s:force_disable_eskk(stash, error) "{{{
    call eskk#disable()

    call eskk#logger#write_error_log_file(
    \   a:stash, a:error,
    \)
    sleep 1

    " Vim does not disable IME
    " when changing the value of &iminsert and/or &imsearch.
    " so do it manually.
    return "\<Esc>i"
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

" Lua
function! eskk#has_if_lua() abort "{{{
    return !g:eskk#disable_if_lua && has('lua')
endfunction "}}}

" Mapping
function! eskk#_get_eskk_mappings() "{{{
    return s:eskk_mappings
endfunction "}}}
function! eskk#_get_eskk_general_mappings() "{{{
    return s:eskk_general_mappings
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

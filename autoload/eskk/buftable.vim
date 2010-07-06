" vim:foldmethod=marker:fen:
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
" Normal
let eskk#buftable#HENKAN_PHASE_NORMAL = 0
lockvar eskk#buftable#HENKAN_PHASE_NORMAL
" Choosing henkan candidates.
let eskk#buftable#HENKAN_PHASE_HENKAN = 1
lockvar eskk#buftable#HENKAN_PHASE_HENKAN
" Waiting for okurigana.
let eskk#buftable#HENKAN_PHASE_OKURI = 2
lockvar eskk#buftable#HENKAN_PHASE_OKURI
" Choosing henkan candidates.
let eskk#buftable#HENKAN_PHASE_HENKAN_SELECT = 3
lockvar eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
" }}}

" Functions {{{
" s:buffer_string {{{
let s:buffer_string = {'_rom_str': '', '_matched_pairs': []}

function! s:buffer_string_new() "{{{
    return deepcopy(s:buffer_string)
endfunction "}}}


function! s:buffer_string.reset() dict "{{{
    for k in keys(s:buffer_string)
        if has_key(self, k)
            let self[k] = deepcopy(s:buffer_string[k])
        endif
    endfor
endfunction "}}}


function! s:buffer_string.get_rom_str() dict "{{{
    return self._rom_str
endfunction "}}}
function! s:buffer_string.set_rom_str(str) dict "{{{
    let self._rom_str = a:str
endfunction "}}}
function! s:buffer_string.push_rom_str(str) dict "{{{
    call self.set_rom_str(self.get_rom_str() . a:str)
endfunction "}}}
function! s:buffer_string.pop_rom_str() dict "{{{
    let s = self.get_rom_str()
    call self.set_rom_str(strpart(s, 0, strlen(s) - 1))
endfunction "}}}
function! s:buffer_string.clear_rom_str() dict "{{{
    let self._rom_str = ''
endfunction "}}}


function! s:buffer_string.get_matched() dict "{{{
    return self._matched_pairs
endfunction "}}}
function! s:buffer_string.get_matched_rom() dict "{{{
    return join(map(copy(self._matched_pairs), 'v:val[0]'), '')
endfunction "}}}
function! s:buffer_string.get_matched_filter() dict "{{{
    return join(map(copy(self._matched_pairs), 'v:val[1]'), '')
endfunction "}}}
function! s:buffer_string.set_matched(rom_str, filter_str) dict "{{{
    let self._matched_pairs = [[a:rom_str, a:filter_str]]
endfunction "}}}
function! s:buffer_string.push_matched(rom_str, filter_str) dict "{{{
    call add(self._matched_pairs, [a:rom_str, a:filter_str])
endfunction "}}}
function! s:buffer_string.pop_matched() dict "{{{
    if !empty(self._matched_pairs)
        call remove(self._matched_pairs, -1)
    endif
endfunction "}}}
function! s:buffer_string.clear_matched() dict "{{{
    let self._matched_pairs = []
endfunction "}}}


function! s:buffer_string.get_input_rom() dict "{{{
    return self.get_matched_rom() . self.get_rom_str()
endfunction "}}}


function! s:buffer_string.clear() dict "{{{
    call self.clear_rom_str()
    call self.clear_matched()
endfunction "}}}


lockvar s:buffer_string
" }}}
" s:buftable {{{
let s:buftable = {
\   '_table': [
\       s:buffer_string_new(),
\       s:buffer_string_new(),
\       s:buffer_string_new(),
\       s:buffer_string_new(),
\       s:buffer_string_new(),
\   ],
\   '_kakutei_str': '',
\   '_old_str': '',
\   '_begin_pos': [],
\   '_henkan_phase': g:eskk#buftable#HENKAN_PHASE_NORMAL,
\}

" FIXME
" - Current implementation depends on &backspace
" when inserted string has newline.


function! eskk#buftable#new() "{{{
    return deepcopy(s:buftable)
endfunction "}}}


function! s:buftable.reset() dict "{{{
    for k in keys(s:buftable)
        if has_key(self, k)
            let self[k] = deepcopy(s:buftable[k])
        endif
    endfor
endfunction "}}}


function! s:buftable.get_buf_str(henkan_phase) dict "{{{
    call s:validate_table_idx(self._table, a:henkan_phase)
    return self._table[a:henkan_phase]
endfunction "}}}
function! s:buftable.get_current_buf_str() dict "{{{
    return self.get_buf_str(self._henkan_phase)
endfunction "}}}


" Rewrite old string, Insert new string.
function! s:buftable.set_old_str(str) dict "{{{
    let self._old_str = a:str
endfunction "}}}
function! s:buftable.get_old_str() dict "{{{
    return self._old_str
endfunction "}}}
" Return inserted string.
" Inserted string contains "\<Plug>(eskk:internal:backspace-key)"
" to delete old characters.
function! s:buftable.rewrite() dict "{{{
    let [old, new] = [self._old_str, self.get_display_str()]

    let kakutei = self._kakutei_str
    let self._kakutei_str = ''

    call eskk#util#logf('old string = %s', string(old))
    call eskk#util#logf('kakutei string = %s', string(kakutei))
    call eskk#util#logf('new display string = %s', string(new))

    let bs = repeat("\<Plug>(eskk:internal:backspace-key)", eskk#util#mb_strlen(old))

    " TODO Rewrite mininum string as possible
    " when old or new string become too long.
    let inserted_str = kakutei . new
    if inserted_str == ''
        return bs
    else
        execute
        \   eskk#get_map_command(0)
        \   '<buffer>'
        \   '<Plug>(eskk:internal:_inserted)'
        \   eskk#util#str2map(inserted_str)
        return bs . "\<Plug>(eskk:internal:_inserted)"
    endif
endfunction "}}}

function! s:buftable.get_display_str(...) dict "{{{
    let with_marker = a:0 != 0 ? a:1 : 1
    let phase = self._henkan_phase

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        return s:get_normal_display_str(self)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        return s:get_okuri_display_str(self, with_marker)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        return s:get_henkan_display_str(self, with_marker)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        return s:get_henkan_select_display_str(self, with_marker)
    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! s:get_normal_display_str(this) "{{{
    let buf_str = a:this.get_buf_str(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    return
    \   buf_str.get_matched_filter()
    \   . buf_str.get_rom_str()
endfunction "}}}
function! s:get_okuri_display_str(this, with_marker) "{{{
    let buf_str = a:this.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
    return
    \   s:get_henkan_display_str(a:this, a:with_marker)
    \   . (a:with_marker ?
    \       a:this.get_marker(g:eskk#buftable#HENKAN_PHASE_OKURI)
    \       : '')
    \   . buf_str.get_matched_filter()
    \   . buf_str.get_rom_str()
endfunction "}}}
function! s:get_henkan_display_str(this, with_marker) "{{{
    let buf_str = a:this.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    return
    \   (a:with_marker ?
    \       a:this.get_marker(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    \       : '')
    \   . buf_str.get_matched_filter()
    \   . buf_str.get_rom_str()
endfunction "}}}
function! s:get_henkan_select_display_str(this, with_marker) "{{{
    let buf_str = a:this.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
    return
    \   (a:with_marker ?
    \       a:this.get_marker(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
    \       : '')
    \   . buf_str.get_matched_filter()
    \   . buf_str.get_rom_str()
endfunction "}}}


" self._henkan_phase
function! s:buftable.get_henkan_phase() dict "{{{
    return self._henkan_phase
endfunction "}}}
function! s:buftable.set_henkan_phase(henkan_phase) dict "{{{
    call s:validate_table_idx(self._table, a:henkan_phase)

    call eskk#throw_event('leave-phase-' . self.get_phase_name(self._henkan_phase))
    let self._henkan_phase = a:henkan_phase
    call eskk#throw_event('enter-phase-' . self.get_phase_name(self._henkan_phase))
endfunction "}}}


function! s:buftable.get_phase_name(phase) dict "{{{
    return [
    \   'normal',
    \   'henkan',
    \   'okuri',
    \   'henkan-select',
    \   'jisyo-touroku',
    \][a:phase]
endfunction "}}}


function! s:buftable.get_lower_phases() dict "{{{
    return reverse(range(g:eskk#buftable#HENKAN_PHASE_NORMAL, self._henkan_phase))
endfunction "}}}
function! s:buftable.get_all_phases() dict "{{{
    return range(
    \   g:eskk#buftable#HENKAN_PHASE_NORMAL,
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
    \)
endfunction "}}}


function! s:buftable.get_marker(henkan_phase) dict "{{{
    let table = [
    \    '',
    \    g:eskk_marker_henkan,
    \    g:eskk_marker_okuri,
    \    g:eskk_marker_henkan_select,
    \    g:eskk_marker_jisyo_touroku,
    \]
    call s:validate_table_idx(table, a:henkan_phase)
    return table[a:henkan_phase]
endfunction "}}}
function! s:buftable.get_current_marker() "{{{
    return self.get_marker(self.get_henkan_phase())
endfunction "}}}


function! s:buftable.push_kakutei_str(str) dict "{{{
    let self._kakutei_str .= a:str
endfunction "}}}

function! s:buftable.do_enter(stash) dict "{{{
    let normal_buf_str        = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    let henkan_buf_str        = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    let okuri_buf_str         = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
    let henkan_select_buf_str = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
    let phase = self.get_henkan_phase()
    let enter_char = eskk#util#eval_key('<Plug>(eskk:internal:enter-key)')
    let undo_char  = eskk#util#eval_key('<Plug>(eskk:internal:undo-key)')

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        if normal_buf_str.get_rom_str() != ''
            call self.push_kakutei_str(normal_buf_str.get_rom_str())
            call normal_buf_str.clear()
            call eskk#register_temp_event('filter-redispatch-post', 'eskk#util#identity', [enter_char])
        else
            let a:stash.return = enter_char
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        if get(g:eskk_set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event('filter-redispatch-post', 'eskk#util#identity', [undo_char])
        endif

        call self.push_kakutei_str(self.get_display_str(0))
        call self.clear_all()

        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        if get(g:eskk_set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event('filter-redispatch-post', 'eskk#util#identity', [undo_char])
        endif

        call self.push_kakutei_str(self.get_display_str(0))
        call self.clear_all()

        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        if get(g:eskk_set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event('filter-redispatch-post', 'eskk#util#identity', [undo_char])
        endif

        call self.push_kakutei_str(self.get_display_str(0))
        call self.clear_all()

        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    else
        throw eskk#internal_error(['eskk'])
    endif
endfunction "}}}
function! s:buftable.do_backspace(stash, ...) dict "{{{
    let done_for_group = a:0 ? a:1 : 1

    if self.get_old_str() == ''
        let a:stash.return = eskk#util#eval_key('<Plug>(eskk:internal:backspace-key)')
        return
    endif

    let phase = self.get_henkan_phase()
    if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        if g:eskk_delete_implies_kakutei
            " Enter normal phase and delete one character.
            let filter_str = eskk#util#mb_chop(self.get_display_str(0))
            call self.push_kakutei_str(filter_str)
            let henkan_select_buf_str = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
            call henkan_select_buf_str.clear()

            call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
            return
        else
            " Leave henkan select or back to previous candidate if it exists.
            call self.choose_prev_candidate(a:stash)
            return
        endif
    endif

    " Build backspaces to delete previous characters.
    for phase in self.get_lower_phases()
        let buf_str = self.get_buf_str(phase)
        if buf_str.get_rom_str() != ''
            call buf_str.pop_rom_str()
            break
        elseif !empty(buf_str.get_matched())
            if done_for_group
                call buf_str.pop_matched()
            else
                let m = buf_str.get_matched()
                call eskk#util#assert(len(m) == 1)
                let [rom, filter] = m[0]
                call buf_str.set_matched(rom, eskk#util#mb_chop(filter))

                " `rom` is empty string,
                " Because currently this is called only by
                " `s:do_backspace()` in `autoload/eskk/complete.vim`.
                call eskk#util#assert(rom == '')
            endif
            break
        elseif self.get_marker(phase) != ''
            if !self.step_back_henkan_phase()
                let msg = "Normal phase's marker is empty, "
                \       . "and other phases *should* be able to change "
                \       . "current henkan phase."
                throw eskk#internal_error(['eskk'], msg)
            endif
            break
        endif
    endfor
endfunction "}}}
function! s:buftable.choose_next_candidate(stash) dict "{{{
    return s:get_next_candidate(self, a:stash, 1)
endfunction "}}}
function! s:buftable.choose_prev_candidate(stash) dict "{{{
    return s:get_next_candidate(self, a:stash, 0)
endfunction "}}}
function! s:get_next_candidate(self, stash, next) "{{{
    let self = a:self
    let cur_buf_str = self.get_current_buf_str()
    let henkan_result = eskk#get_prev_henkan_result()
    let prev_buftable = henkan_result.buftable
    let rom_str = cur_buf_str.get_matched_rom()

    call eskk#util#assert(self.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT, "current phase is henkan select phase.")

    if henkan_result[a:next ? 'advance' : 'back']()
        let candidate = henkan_result.get_candidate()
        call eskk#util#assert(type(candidate) == type(""), "henkan_result.get_candidate()'s return value is String.")

        " Set candidate.
        " FIXME:
        " Do not set with `rom_str`.
        " Get henkan_result's buftable
        " and get matched rom str(s).
        call cur_buf_str.set_matched(rom_str, candidate)
    else
        " No more candidates.
        if a:next
            " Register new word when it advanced or backed current result index,
            " And tried to step at last candidates but failed.
            let input = eskk#get_dictionary().register_word(henkan_result)
            call cur_buf_str.set_matched(rom_str, input)
        else
            " Restore previous buftable state

            let revert_style = eskk#util#option_value(
            \   g:eskk_revert_henkan_style,
            \   ['okuri-one', 'okuri', 'delete-okuri', 'concat-okuri'],
            \   1
            \)

            let henkan_buf_str = prev_buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
            let okuri_buf_str = prev_buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
            let okuri_rom_str = okuri_buf_str.get_matched_rom()

            if revert_style ==# 'okuri-one'
                " "▼書く" => "▽か*k"
                if okuri_rom_str != ''
                    call okuri_buf_str.set_rom_str(okuri_rom_str[0])
                    call okuri_buf_str.clear_matched()
                endif
            elseif revert_style ==# 'okuri'
                " "▼書く" => "▽か*く"
            elseif revert_style ==# 'delete-okuri'
                " "▼書く" => "▽か"
                if okuri_rom_str != ''
                    " Clear roms of `okuri_buf_str`.
                    call okuri_buf_str.clear()
                    call prev_buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN)
                endif
            elseif revert_style ==# 'concat-okuri'
                " "▼書く" => "▽かく"
                if okuri_rom_str != ''
                    " Copy roms of `okuri_buf_str` to `henkan_buf_str`.
                    for okuri_matched in okuri_buf_str.get_matched()
                        call henkan_buf_str.push_matched(okuri_matched[0], okuri_matched[1])
                    endfor
                    " Clear roms of `okuri_buf_str`.
                    call okuri_buf_str.clear()
                    call prev_buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN)
                endif
            else
                throw eskk#internal_error(['eskk', 'mode', 'builtin'], "This will never be reached")
            endif

            call eskk#set_buftable(prev_buftable)
        endif
    endif
endfunction "}}}
function! s:buftable.do_sticky(stash) dict "{{{
    let step    = 0
    let phase   = self.get_henkan_phase()
    let buf_str = self.get_current_buf_str()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        if buf_str.get_rom_str() != '' || buf_str.get_matched_filter() != ''
            call self.push_kakutei_str(self.get_display_str(0))
        endif
        if get(g:eskk_set_undo_point, 'sticky', 0) && mode() ==# 'i'
            let undo_char = eskk#util#eval_key('<Plug>(eskk:internal:undo-key)')
            call eskk#register_temp_event('filter-redispatch-pre', 'eskk#util#identity', [undo_char])
        endif
        call self.set_begin_pos('.')
        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN)
        let step = 1
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        if buf_str.get_rom_str() != '' || buf_str.get_matched_filter() != ''
            call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_OKURI)
            let step = 1
        else
            let step = 0
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        let step = 0
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        call self.do_enter(a:stash)
        call self.do_sticky(a:stash)

        let step = 1
    else
        throw eskk#internal_error(['eskk'])
    endif

    return step ? self.get_current_marker() : ''
endfunction "}}}
function! s:buftable.step_back_henkan_phase() dict "{{{
    let phase   = self.get_henkan_phase()
    let buf_str = self.get_current_buf_str()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        call buf_str.clear()
        let okuri_buf_str = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
        call self.set_henkan_phase(
        \   !empty(okuri_buf_str.get_matched()) ?
        \       g:eskk#buftable#HENKAN_PHASE_OKURI
        \       : g:eskk#buftable#HENKAN_PHASE_HENKAN
        \)
        return 1
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        call buf_str.clear()
        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN)
        return 1    " stepped.
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        call buf_str.clear()
        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
        return 1    " stepped.
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        return 0    " failed.
    else
        throw eskk#internal_error(['eskk'])
    endif
endfunction "}}}
function! s:buftable.do_henkan(stash) dict "{{{
    let phase = self.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \ || phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        if g:eskk_kata_convert_to_hira_at_henkan && eskk#get_mode() ==# 'kata'
            let table = eskk#table#get_table('rom_to_hira')
            call s:filter_rom_again(self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN), table)
            call s:filter_rom_again(self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI), table)
        endif

        " Convert rom_str if possible.
        let table = eskk#table#get_table(eskk#get_current_mode_table())
        for phase in [g:eskk#buftable#HENKAN_PHASE_HENKAN, g:eskk#buftable#HENKAN_PHASE_OKURI]
            let buf_str = self.get_buf_str(phase)
            let rom_str = buf_str.get_rom_str()
            if table.has_map(rom_str)
                call buf_str.push_matched(rom_str, table.get_map_to(rom_str))
            endif
        endfor

        call eskk#set_henkan_result(eskk#get_dictionary().refer(self))

        " Enter henkan select phase.
        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)

        " Clear phase henkan/okuri buffer string.
        " Assumption: `eskk#get_dictionary().refer()` saves necessary strings.
        let henkan_buf_str = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
        let henkan_matched_rom = henkan_buf_str.get_matched_rom()
        call henkan_buf_str.clear()

        let okuri_buf_str = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
        let okuri_matched_rom = okuri_buf_str.get_matched_rom()
        call okuri_buf_str.clear()

        let candidate = eskk#get_prev_henkan_result().get_candidate()

        let buf_str = self.get_current_buf_str()
        let rom_str = henkan_matched_rom . okuri_matched_rom
        if type(candidate) == type("")
            " Set candidate.
            call buf_str.push_matched(rom_str, candidate)
        else
            " No candidates.
            let input = eskk#get_dictionary().register_word(eskk#get_prev_henkan_result())
            call buf_str.push_matched(rom_str, input)
        endif
    else
        let msg = printf("s:buftable.do_henkan() does not support phase %d.", phase)
        throw eskk#internal_error(['eskk', 'mode', 'builtin'], msg)
    endif
endfunction "}}}
function! s:filter_rom_again(buf_str, table) "{{{
    let buf_str = a:buf_str
    let table   = a:table

    let matched = buf_str.get_matched()
    call buf_str.clear_matched()
    for [rom_str, filter_str] in matched
        if table.has_map(rom_str)
            call buf_str.push_matched(
            \   rom_str,
            \   table.get_map_to(rom_str)
            \)
        else
            call buf_str.push_matched(
            \   rom_str,
            \   rom_str,
            \)
        endif
    endfor
endfunction "}}}
function! s:buftable.do_ctrl_q_key() dict "{{{
    return s:convert_again_with_table(self, eskk#table#get_table(eskk#get_mode() ==# 'hira' ? 'rom_to_hankata' : 'rom_to_hira'))
endfunction "}}}
function! s:buftable.do_q_key() dict "{{{
    return s:convert_again_with_table(self, eskk#table#get_table(eskk#get_mode() ==# 'hira' ? 'rom_to_kata' : 'rom_to_hira'))
endfunction "}}}
function! s:convert_again_with_table(self, table) "{{{
    let self = a:self

    " Convert rom_str if possible.
    let table = eskk#table#get_table(eskk#get_current_mode_table())
    for phase in [g:eskk#buftable#HENKAN_PHASE_HENKAN, g:eskk#buftable#HENKAN_PHASE_OKURI]
        let buf_str = self.get_buf_str(phase)
        let rom_str = buf_str.get_rom_str()
        if table.has_map(rom_str)
            call buf_str.push_matched(rom_str, table.get_map_to(rom_str))
        endif
    endfor

    let cur_buf_str = self.get_current_buf_str()

    let normal_buf_str = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    let henkan_buf_str = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    let okuri_buf_str  = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)

    for cur_buf_str in [henkan_buf_str, okuri_buf_str]
        for m in cur_buf_str.get_matched()
            call normal_buf_str.push_matched(m[0], a:table.get_map_to(m[0]))
        endfor
    endfor

    call henkan_buf_str.clear()
    call okuri_buf_str.clear()

    call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)

    function! s:finalize()
        let self = eskk#get_buftable()
        if self.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
            let cur_buf_str = self.get_current_buf_str()
            call cur_buf_str.clear_matched()
        endif
    endfunction

    call eskk#register_temp_event(
    \   'filter-begin',
    \   eskk#util#get_local_func('finalize', s:SID_PREFIX),
    \   []
    \)
endfunction "}}}


function! s:buftable.clear_all() dict "{{{
    for phase in self.get_all_phases()
        let buf_str = self.get_buf_str(phase)
        call buf_str.clear()
    endfor
endfunction "}}}


function! s:buftable.get_begin_pos() dict "{{{
    return self._begin_pos
endfunction "}}}
function! s:buftable.set_begin_pos(expr) dict "{{{
    if mode() ==# 'i'
        let self._begin_pos = ['i', getpos(a:expr)]
    elseif mode() ==# 'c'
        let self._begin_pos = ['c', getcmdpos()]
    else
        call eskk#util#warnf("warning: called eskk from mode '%s'.", mode())
    endif
endfunction "}}}


function! s:buftable.dump() dict "{{{
    let lines = []
    call add(lines, printf('current phase:%d', self._henkan_phase))
    call add(lines, printf('begin pos: %s', string(self.get_begin_pos())))
    for phase in self.get_all_phases()
        let buf_str = self.get_buf_str(phase)
        call add(lines, printf('phase:%d', phase))
        call add(lines, printf('rom_str: %s', string(buf_str.get_rom_str())))
        call add(lines, printf('matched pairs: %s', string(buf_str.get_matched())))
    endfor
    return lines
endfunction "}}}


function! s:validate_table_idx(table, henkan_phase) "{{{
    if !eskk#util#has_idx(a:table, a:henkan_phase)
        throw eskk#out_of_idx_error(["eskk", "buftable"])
    endif
endfunction "}}}


lockvar s:buftable
" }}}
" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID

" Constants {{{
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


function! s:buffer_string.reset() "{{{
    for k in keys(s:buffer_string)
        if has_key(self, k)
            let self[k] = deepcopy(s:buffer_string[k])
        endif
    endfor
endfunction "}}}


function! s:buffer_string.get_rom_str() "{{{
    return self._rom_str
endfunction "}}}
function! s:buffer_string.set_rom_str(str) "{{{
    let self._rom_str = a:str
endfunction "}}}
function! s:buffer_string.push_rom_str(str) "{{{
    call self.set_rom_str(self.get_rom_str() . a:str)
endfunction "}}}
function! s:buffer_string.pop_rom_str() "{{{
    let s = self.get_rom_str()
    call self.set_rom_str(strpart(s, 0, strlen(s) - 1))
endfunction "}}}
function! s:buffer_string.clear_rom_str() "{{{
    let self._rom_str = ''
endfunction "}}}


function! s:buffer_string.get_matched() "{{{
    return self._matched_pairs
endfunction "}}}
function! s:buffer_string.get_matched_rom() "{{{
    return join(map(copy(self._matched_pairs), 'v:val[0]'), '')
endfunction "}}}
function! s:buffer_string.get_matched_filter() "{{{
    return join(map(copy(self._matched_pairs), 'v:val[1]'), '')
endfunction "}}}
function! s:buffer_string.set_matched(rom_str, filter_str) "{{{
    let self._matched_pairs = [[a:rom_str, a:filter_str]]
endfunction "}}}
function! s:buffer_string.set_multiple_matched(m) "{{{
    let self._matched_pairs = a:m
endfunction "}}}
function! s:buffer_string.push_matched(rom_str, filter_str) "{{{
    call add(self._matched_pairs, [a:rom_str, a:filter_str])
endfunction "}}}
function! s:buffer_string.pop_matched() "{{{
    if empty(self._matched_pairs)
        return []
    endif
    return remove(self._matched_pairs, -1)
endfunction "}}}
function! s:buffer_string.clear_matched() "{{{
    let self._matched_pairs = []
endfunction "}}}


function! s:buffer_string.get_input_rom() "{{{
    return self.get_matched_rom() . self.get_rom_str()
endfunction "}}}


function! s:buffer_string.empty() "{{{
    return self.get_rom_str() == ''
    \   && empty(self.get_matched())
endfunction "}}}


function! s:buffer_string.clear() "{{{
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
\   '_set_begin_pos_at_rewrite': 0,
\}


function! eskk#buftable#new() "{{{
    return deepcopy(s:buftable)
endfunction "}}}


function! s:buftable.reset() "{{{
    for k in keys(s:buftable)
        if has_key(self, k)
            let self[k] = deepcopy(s:buftable[k])
        endif
    endfor
endfunction "}}}


function! s:buftable.get_buf_str(henkan_phase) "{{{
    call s:validate_table_idx(self._table, a:henkan_phase)
    return self._table[a:henkan_phase]
endfunction "}}}
function! s:buftable.get_current_buf_str() "{{{
    return self.get_buf_str(self._henkan_phase)
endfunction "}}}


function! s:buftable.set_old_str(str) "{{{
    let self._old_str = a:str
endfunction "}}}
function! s:buftable.get_old_str() "{{{
    return self._old_str
endfunction "}}}

" Rewrite old string, Insert new string.
"
" FIXME
" - Current implementation depends on &backspace
" when inserted string has newline.
"
" TODO Rewrite mininum string as possible
" when old or new string become too long.
function! s:buftable.rewrite() "{{{
    let [old, new] = [self._old_str, self.get_display_str()]

    let kakutei = self._kakutei_str
    let self._kakutei_str = ''

    let set_begin_pos =
    \   self._set_begin_pos_at_rewrite
    \   && self._henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    let self._set_begin_pos_at_rewrite = 0

    if set_begin_pos
        " 1. Delete current string
        " 2. Set begin pos
        " 3. Insert new string

        if kakutei != ''
            call eskk#mappings#map(
            \   'b',
            \   '<Plug>(eskk:_inserted_kakutei)',
            \   eskk#util#str2map(kakutei)
            \)
        endif
        if new != ''
            call eskk#mappings#map(
            \   'b',
            \   '<Plug>(eskk:_inserted_new)',
            \   eskk#util#str2map(new)
            \)
        endif

        return
        \   self.make_remove_bs()
        \   . (kakutei != '' ? "\<Plug>(eskk:_inserted_kakutei)" : '')
        \   . "\<Plug>(eskk:_set_begin_pos)"
        \   . (new != '' ? "\<Plug>(eskk:_inserted_new)" : '')
    else
        let inserted_str = kakutei . new
        if old ==# inserted_str
            return ''
        elseif inserted_str == ''
            return self.make_remove_bs()
        elseif inserted_str != '' && stridx(old, inserted_str) == 0
            " When inserted_str == "foo", old == "foobar"
            " Insert Remove "bar"
            return repeat(
            \   eskk#util#key2char(
            \       eskk#mappings#get_special_map("backspace-key")
            \   ),
            \   eskk#util#mb_strlen(old)
            \       - eskk#util#mb_strlen(inserted_str)
            \)
        elseif old != '' && stridx(inserted_str, old) == 0
            " When inserted_str == "foobar", old == "foo"
            " Insert "bar".
            call eskk#mappings#map(
            \   'b',
            \   '<Plug>(eskk:_inserted)',
            \   eskk#util#str2map(strpart(inserted_str, strlen(old)))
            \)
            return "\<Plug>(eskk:_inserted)"
        else
            " Simplest algorithm.
            " Delete current string, and insert new string.
            call eskk#mappings#map(
            \   'b',
            \   '<Plug>(eskk:_inserted)',
            \   eskk#util#str2map(inserted_str)
            \)
            return self.make_remove_bs() . "\<Plug>(eskk:_inserted)"
        endif
    endif
endfunction "}}}
function! s:buftable.make_remove_bs() "{{{
    let old = self._old_str
    return repeat(
    \   eskk#util#key2char(eskk#mappings#get_special_map("backspace-key")),
    \   eskk#util#mb_strlen(old),
    \)
endfunction "}}}

function! s:buftable.has_changed() "{{{
    let kakutei = self._kakutei_str
    if kakutei != ''
        return 1
    endif

    let [old, new] = [self._old_str, self.get_display_str()]
    let inserted_str = kakutei . new
    if old !=# inserted_str
        return 1
    endif

    return 0
endfunction "}}}

function! s:buftable.get_display_str(...) "{{{
    let with_marker = a:0 != 0 ? a:1 : 1
    let phase = self._henkan_phase

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        return s:get_normal_display_str(self)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        return s:get_henkan_display_str(self, with_marker)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        return s:get_okuri_display_str(self, with_marker)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        return s:get_henkan_select_display_str(self, with_marker)
    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! s:get_normal_display_str(this) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_NORMAL
    \)
    return
    \   buf_str.get_matched_filter()
    \   . buf_str.get_rom_str()
endfunction "}}}
function! s:get_henkan_display_str(this, with_marker) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN
    \)
    return
    \   (a:with_marker ?
    \       a:this.get_marker(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    \       : '')
    \   . buf_str.get_matched_filter()
    \   . buf_str.get_rom_str()
endfunction "}}}
function! s:get_okuri_display_str(this, with_marker) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_OKURI
    \)
    return
    \   s:get_henkan_display_str(a:this, a:with_marker)
    \   . (a:with_marker ?
    \       a:this.get_marker(g:eskk#buftable#HENKAN_PHASE_OKURI)
    \       : '')
    \   . buf_str.get_matched_filter()
    \   . buf_str.get_rom_str()
endfunction "}}}
function! s:get_henkan_select_display_str(this, with_marker) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
    \)
    return
    \   (a:with_marker ?
    \       a:this.get_marker(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
    \       : '')
    \   . buf_str.get_matched_filter()
    \   . buf_str.get_rom_str()
endfunction "}}}


" self._henkan_phase
function! s:buftable.get_henkan_phase() "{{{
    return self._henkan_phase
endfunction "}}}
function! s:buftable.set_henkan_phase(henkan_phase) "{{{
    if a:henkan_phase ==# self._henkan_phase
        call eskk#util#log(
        \   'tried to change into same phase (' . a:henkan_phase . ').'
        \)
        return
    endif

    call s:validate_table_idx(self._table, a:henkan_phase)

    call eskk#throw_event(
    \   'leave-phase-' . self.get_phase_name(self._henkan_phase)
    \)
    let self._henkan_phase = a:henkan_phase
    call eskk#throw_event(
    \   'enter-phase-' . self.get_phase_name(self._henkan_phase)
    \)
endfunction "}}}


function! s:buftable.get_phase_name(phase) "{{{
    return [
    \   'normal',
    \   'henkan',
    \   'okuri',
    \   'henkan-select',
    \   'jisyo-touroku',
    \][a:phase]
endfunction "}}}


function! s:buftable.get_lower_phases() "{{{
    return reverse(range(
    \   g:eskk#buftable#HENKAN_PHASE_NORMAL,
    \   self._henkan_phase
    \))
endfunction "}}}
function! s:buftable.get_all_phases() "{{{
    return range(
    \   g:eskk#buftable#HENKAN_PHASE_NORMAL,
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
    \)
endfunction "}}}


function! s:buftable.get_marker(henkan_phase) "{{{
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


function! s:buftable.push_kakutei_str(str) "{{{
    let self._kakutei_str .= a:str
endfunction "}}}

function! s:buftable.do_enter(stash) "{{{
    let phase = a:stash.phase
    let enter_char =
    \   eskk#util#key2char(eskk#mappings#get_special_map('enter-key'))
    let undo_char  =
    \   eskk#util#key2char(eskk#mappings#get_special_map('undo-key'))
    let dict = eskk#get_skk_dict()
    let henkan_result = dict.get_henkan_result()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call self.convert_rom_str([phase])
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [enter_char]
        \)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        call self.convert_rom_str([phase])
        if get(g:eskk_set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [undo_char]
            \)
        endif

        call self.push_kakutei_str(self.get_display_str(0))
        call self.clear_all()

        if !empty(henkan_result)
            call henkan_result.update_candidate()
        endif

        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        call self.convert_rom_str(
        \   [g:eskk#buftable#HENKAN_PHASE_HENKAN, phase]
        \)
        if get(g:eskk_set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [undo_char]
            \)
        endif

        call self.push_kakutei_str(self.get_display_str(0))
        call self.clear_all()

        if !empty(henkan_result)
            call henkan_result.update_candidate()
        endif

        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        call self.convert_rom_str([phase])
        if get(g:eskk_set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [undo_char]
            \)
        endif

        if !empty(henkan_result)
            call henkan_result.update_candidate()
        endif

        call self.push_kakutei_str(self.get_display_str(0))
        call self.clear_all()

        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    else
        throw eskk#internal_error(['eskk'])
    endif
endfunction "}}}
function! s:buftable.do_backspace(stash, ...) "{{{
    let done_for_group = a:0 ? a:1 : 1

    if self.get_old_str() == ''
        let a:stash.return = eskk#util#key2char(
        \   eskk#mappings#get_special_key('backspace-key')
        \)
        return
    endif

    let phase = self.get_henkan_phase()
    if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        if g:eskk_delete_implies_kakutei
            " Enter normal phase and delete one character.
            let filter_str = eskk#util#mb_chop(self.get_display_str(0))
            call self.push_kakutei_str(filter_str)
            let henkan_select_buf_str = self.get_buf_str(
            \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
            \)
            call henkan_select_buf_str.clear()

            call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
            return
        else
            " Leave henkan select or back to previous candidate if it exists.
            call self.choose_prev_candidate(a:stash)
            return
        endif
    endif

    let mode_st = eskk#get_current_mode_structure()
    if g:eskk_convert_at_exact_match
    \   && has_key(mode_st.sandbox, 'real_matched_pairs')

        let p = mode_st.sandbox.real_matched_pairs
        unlet mode_st.sandbox.real_matched_pairs

        if g:eskk_delete_implies_kakutei
            " Enter normal phase and delete one character.
            let filter_str = eskk#util#mb_chop(self.get_display_str(0))
            call self.push_kakutei_str(filter_str)
            let henkan_select_buf_str = self.get_buf_str(
            \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
            \)
            call henkan_select_buf_str.clear()

            call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
            return
        else
            let filter_str = join(map(copy(p), 'v:val[1]'), '')
            let buf_str = self.get_buf_str(
            \   g:eskk#buftable#HENKAN_PHASE_HENKAN
            \)
            if filter_str ==# buf_str.get_matched_filter()
                " Fall through.
            else
                call buf_str.set_multiple_matched(p)
                return
            endif
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
                let p = buf_str.pop_matched()
                if empty(p)
                    continue
                endif
                " ["tyo", "ちょ"] => ["tyo", "ち"]
                if eskk#util#mb_strlen(p[1]) !=# 1
                    call buf_str.push_matched(p[0], eskk#util#mb_chop(p[1]))
                endif
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
function! s:buftable.choose_next_candidate(stash) "{{{
    return s:get_next_candidate(self, a:stash, 1)
endfunction "}}}
function! s:buftable.choose_prev_candidate(stash) "{{{
    return s:get_next_candidate(self, a:stash, 0)
endfunction "}}}
function! s:get_next_candidate(self, stash, next) "{{{
    let self = a:self
    let cur_buf_str = self.get_current_buf_str()
    let dict = eskk#get_skk_dict()
    let henkan_result = dict.get_henkan_result()
    let prev_buftable = henkan_result.buftable
    let rom_str = cur_buf_str.get_matched_rom()

    call eskk#util#assert(
    \   self.get_henkan_phase()
    \       ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT,
    \   "current phase is henkan select phase."
    \)

    if henkan_result[a:next ? 'forward' : 'back']()
        let candidate = henkan_result.get_candidate()

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
            let [input, hira, okuri] = dict.register_word(
            \   dict.get_henkan_result()
            \)
            if input != ''
                call self.clear_all()
                call self.push_kakutei_str(input . okuri)
                call self.set_henkan_phase(
                \   g:eskk#buftable#HENKAN_PHASE_NORMAL
                \)
            endif
        else
            " Restore previous buftable state
            let henkan_buf_str = prev_buftable.get_buf_str(
            \   g:eskk#buftable#HENKAN_PHASE_HENKAN
            \)
            let okuri_buf_str = prev_buftable.get_buf_str(
            \   g:eskk#buftable#HENKAN_PHASE_OKURI
            \)
            let okuri_rom_str = okuri_buf_str.get_matched_rom()
            if g:eskk_revert_henkan_style ==# 'okuri-one'
                " "▼書く" => "▽か*k"
                if okuri_rom_str != ''
                    call okuri_buf_str.set_rom_str(okuri_rom_str[0])
                    call okuri_buf_str.clear_matched()
                endif
            elseif g:eskk_revert_henkan_style ==# 'okuri'
                " "▼書く" => "▽か*く"
            elseif g:eskk_revert_henkan_style ==# 'delete-okuri'
                " "▼書く" => "▽か"
                if okuri_rom_str != ''
                    " Clear roms of `okuri_buf_str`.
                    call okuri_buf_str.clear()
                    call prev_buftable.set_henkan_phase(
                    \   g:eskk#buftable#HENKAN_PHASE_HENKAN
                    \)
                endif
            elseif g:eskk_revert_henkan_style ==# 'concat-okuri'
                " "▼書く" => "▽かく"
                if okuri_rom_str != ''
                    " Copy roms of `okuri_buf_str` to `henkan_buf_str`.
                    for okuri_matched in okuri_buf_str.get_matched()
                        call henkan_buf_str.push_matched(
                        \   okuri_matched[0],
                        \   okuri_matched[1]
                        \)
                    endfor
                    " Clear roms of `okuri_buf_str`.
                    call okuri_buf_str.clear()
                    call prev_buftable.set_henkan_phase(
                    \   g:eskk#buftable#HENKAN_PHASE_HENKAN
                    \)
                endif
            else
                throw eskk#internal_error(
                \   ['eskk', 'mode', 'builtin'],
                \   "This will never be reached"
                \)
            endif

            call eskk#set_buftable(prev_buftable)
        endif
    endif
endfunction "}}}
function! s:buftable.do_sticky(stash) "{{{
    let step    = 0
    let phase   = self.get_henkan_phase()
    let buf_str = self.get_current_buf_str()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        if buf_str.get_rom_str() != ''
        \   || buf_str.get_matched_filter() != ''
            call self.convert_rom_str([phase])
            call self.push_kakutei_str(self.get_display_str(0))
            call buf_str.clear()
        endif
        if get(g:eskk_set_undo_point, 'sticky', 0) && mode() ==# 'i'
            let undo_char = eskk#util#key2char(
            \   eskk#mappings#get_special_map('undo-key')
            \)
            call eskk#register_temp_event(
            \   'filter-redispatch-pre',
            \   'eskk#util#identity',
            \   [undo_char]
            \)
        endif
        let self._set_begin_pos_at_rewrite = 1
        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN)
        let step = 1
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        if g:eskk_ignore_continuous_sticky
        \   && empty(buf_str.get_matched())
            let step = 0
        elseif buf_str.get_rom_str() != ''
        \   || buf_str.get_matched_filter() != ''
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
function! s:buftable.step_back_henkan_phase() "{{{
    let phase   = self.get_henkan_phase()
    let buf_str = self.get_current_buf_str()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        call buf_str.clear()
        let okuri_buf_str = self.get_buf_str(
        \   g:eskk#buftable#HENKAN_PHASE_OKURI
        \)
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
function! s:buftable.do_henkan(stash, ...) "{{{
    let convert_at_exact_match = a:0 ? a:1 : 0
    let phase = a:stash.phase
    let eskk_mode = a:stash.mode

    if !eskk#util#list_any(
    \   phase,
    \   [g:eskk#buftable#HENKAN_PHASE_HENKAN,
    \       g:eskk#buftable#HENKAN_PHASE_OKURI]
    \)
        " TODO Add an error id like Vim
        call eskk#util#warnf(
        \   "s:buftable.do_henkan() does not support phase %d.",
        \   phase
        \)
        return
    endif

    if eskk_mode ==# 'abbrev'
        call self.do_henkan_abbrev(a:stash, convert_at_exact_match)
    else
        call self.do_henkan_other(a:stash, convert_at_exact_match)
    endif
endfunction "}}}
function! s:buftable.do_henkan_abbrev(stash, convert_at_exact_match) "{{{
    let henkan_buf_str = self.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN
    \)
    let henkan_select_buf_str = self.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
    \)

    let rom_str = henkan_buf_str.get_rom_str()
    let dict = eskk#get_skk_dict()
    call dict.refer(self, rom_str, '', '')

    try
        let candidate = dict.get_henkan_result().get_candidate()
        " No exception throwed. continue...

        call self.clear_all()
        if a:convert_at_exact_match
            call henkan_buf_str.set_matched(rom_str, candidate)
        else
            call henkan_select_buf_str.set_matched(rom_str, candidate)
            call self.set_henkan_phase(
            \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
            \)
        endif
    catch /^eskk: dictionary look up error:/
        " No candidates.
        let [input, hira, okuri] = dict.register_word(
        \   dict.get_henkan_result()
        \)
        if input != ''
            call self.clear_all()
            call self.push_kakutei_str(input . okuri)
            call self.set_henkan_phase(
            \   g:eskk#buftable#HENKAN_PHASE_NORMAL
            \)
        endif
    endtry
endfunction "}}}
function! s:buftable.do_henkan_other(stash, convert_at_exact_match) "{{{
    let phase = a:stash.phase
    let eskk_mode = a:stash.mode
    let henkan_buf_str = self.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN
    \)
    let okuri_buf_str = self.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_OKURI
    \)
    let henkan_select_buf_str = self.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
    \)

    if g:eskk_kata_convert_to_hira_at_henkan && eskk_mode ==# 'kata'
        call self.filter_rom_inplace(
        \   g:eskk#buftable#HENKAN_PHASE_HENKAN,
        \   'rom_to_hira'
        \)
        call self.filter_rom_inplace(
        \   g:eskk#buftable#HENKAN_PHASE_OKURI,
        \   'rom_to_hira'
        \)
    endif

    " Convert rom_str if possible.
    call self.convert_rom_str([
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN,
    \   g:eskk#buftable#HENKAN_PHASE_OKURI
    \])

    if g:eskk_fix_extra_okuri
    \   && henkan_buf_str.get_rom_str() != ''
    \   && phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        call okuri_buf_str.set_rom_str(henkan_buf_str.get_rom_str())
        call henkan_buf_str.clear_rom_str()
        call self.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_OKURI)
        return
    endif

    let hira = henkan_buf_str.get_matched_filter()
    let okuri = okuri_buf_str.get_matched_filter()
    let okuri_rom = okuri_buf_str.get_matched_rom()
    let dict = eskk#get_skk_dict()
    call dict.refer(self, hira, okuri, okuri_rom)

    " Clear phase henkan/okuri buffer string.
    " NOTE: I assume that `dict.refer()`
    " saves necessary strings even if I clear these.
    let henkan_matched_rom = henkan_buf_str.get_matched_rom()
    let okuri_matched_rom = okuri_buf_str.get_matched_rom()
    let rom_str = henkan_matched_rom . okuri_matched_rom
    try
        let candidate = dict.get_henkan_result().get_candidate()
        " No exception throwed. continue...

        call self.clear_all()
        if a:convert_at_exact_match
            call henkan_buf_str.set_matched(rom_str, candidate)
        else
            call henkan_select_buf_str.set_matched(rom_str, candidate)
            call self.set_henkan_phase(
            \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
            \)
        endif
    catch /^eskk: dictionary look up error:/
        " No candidates.
        let [input, hira, okuri] = dict.register_word(
        \   dict.get_henkan_result()
        \)
        if input != ''
            call self.clear_all()
            call self.push_kakutei_str(input . okuri)
            call self.set_henkan_phase(
            \   g:eskk#buftable#HENKAN_PHASE_NORMAL
            \)
        endif
    endtry
endfunction "}}}
function! s:buftable.do_ctrl_q_key() "{{{
    let table_name = eskk#get_mode() ==# 'hira' ?
    \                   'rom_to_hankata' : 'rom_to_hira'
    return s:convert_again_with_table(
    \   self,
    \   eskk#create_table(table_name)
    \)
endfunction "}}}
function! s:buftable.do_q_key() "{{{
    let table_name = eskk#get_mode() ==# 'hira' ?
    \                   'rom_to_kata' : 'rom_to_hira'
    return s:convert_again_with_table(
    \   self,
    \   eskk#create_table(table_name)
    \)
endfunction "}}}
function! s:buftable.do_l_key() "{{{
    return s:convert_again_with_table(self, {})
endfunction "}}}
function! s:buftable.do_escape(stash) "{{{
    let kakutei_str = self.generate_kakutei_str()

    " NOTE: This function return value is not remapped.
    let esc = eskk#mappings#get_special_key('escape-key')
    call eskk#util#assert(esc != '')

    let a:stash.return = kakutei_str . eskk#util#key2char(esc)
endfunction "}}}
function! s:buftable.do_tab(stash) "{{{
    call a:stash.buf_str.push_rom_str(eskk#util#get_tab_raw_str())
endfunction "}}}

" TODO: These functions are very similar. Refactoring them.
function! s:buftable.convert_rom_str(phases) "{{{
    if eskk#has_current_mode_table()
        if g:eskk_kata_convert_to_hira_at_henkan
        \   && eskk#get_mode() ==# 'kata'
            let table = eskk#create_table('rom_to_hira')
        else
            let table = eskk#create_table(eskk#get_current_mode_table())
        endif
        for buf_str in map(a:phases, 'self.get_buf_str(v:val)')
            let rom_str = buf_str.get_rom_str()
            if table.has_map(rom_str)
                call buf_str.push_matched(
                \   rom_str,
                \   table.get_map(rom_str)
                \)
                call buf_str.clear_rom_str()
            endif
        endfor
    endif
endfunction "}}}
function! s:buftable.filter_rom_inplace(phase, table_name) "{{{
    let phase = a:phase
    let table = eskk#create_table(a:table_name)
    let buf_str = self.get_buf_str(phase)

    let matched = buf_str.get_matched()
    call buf_str.clear_matched()
    for [rom_str, filter_str] in matched
        call buf_str.push_matched(
        \   rom_str,
        \   table.get_map(rom_str, rom_str)
        \)
    endfor
    return buf_str
endfunction "}}}
function! s:buftable.filter_rom(phase, table_name) "{{{
    let phase = a:phase
    let table = eskk#create_table(a:table_name)
    let buf_str = deepcopy(self.get_buf_str(phase), 1)

    let matched = buf_str.get_matched()
    call buf_str.clear_matched()
    for [rom_str, filter_str] in matched
        call buf_str.push_matched(
        \   rom_str,
        \   table.get_map(rom_str, rom_str)
        \)
    endfor
    return buf_str
endfunction "}}}
function! s:convert_again_with_table(self, table) "{{{
    let self = a:self

    " Convert rom_str if possible.
    call self.convert_rom_str([
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN,
    \   g:eskk#buftable#HENKAN_PHASE_OKURI
    \])

    let cur_buf_str = self.get_current_buf_str()

    let normal_buf_str = self.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_NORMAL
    \)
    let henkan_buf_str = self.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_HENKAN
    \)
    let okuri_buf_str = self.get_buf_str(
    \   g:eskk#buftable#HENKAN_PHASE_OKURI
    \)

    for cur_buf_str in [henkan_buf_str, okuri_buf_str]
        for m in cur_buf_str.get_matched()
            call normal_buf_str.push_matched(
            \   m[0],
            \   (empty(a:table) ?
            \       m[0] : a:table.get_map(m[0], m[1]))
            \)
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

    " Update dictionary.
    let dict = eskk#get_skk_dict()
    let henkan_result = dict.get_henkan_result()
    if !empty(henkan_result)
      call henkan_result.update_candidate()
    endif
endfunction "}}}

function! s:buftable.clear_all() "{{{
    for phase in self.get_all_phases()
        let buf_str = self.get_buf_str(phase)
        call buf_str.clear()
    endfor
endfunction "}}}

function! s:buftable.remove_display_str() "{{{
    let current_str = self.get_display_str()

    " NOTE: This function return value is not remapped.
    let bs = eskk#mappings#get_special_key('backspace-key')
    call eskk#util#assert(bs != '')

    return repeat(
    \   eskk#util#key2char(bs),
    \   eskk#util#mb_strlen(current_str)
    \)
endfunction "}}}
function! s:buftable.generate_kakutei_str() "{{{
    return self.remove_display_str() . self.get_display_str(0)
endfunction "}}}

function! s:buftable.get_begin_pos() "{{{
    return self._begin_pos
endfunction "}}}
function! s:buftable.set_begin_pos(expr) "{{{
    if mode() ==# 'i'
        let self._begin_pos = ['i', getpos(a:expr)]
    elseif mode() ==# 'c'
        let self._begin_pos = ['c', getcmdpos()]
    else
        call eskk#util#logf("called eskk from mode '%s'.", mode())
    endif
endfunction "}}}


function! s:buftable.empty() "{{{
    for buf_str in map(
    \   self.get_all_phases(),
    \   'self.get_buf_str(v:val)'
    \)
        if !buf_str.empty()
            return 0
        endif
    endfor
    return 1
endfunction "}}}


function! s:buftable.dump() "{{{
    let lines = []
    call add(lines, 'current phase: ' . self._henkan_phase)
    call add(lines, 'begin pos: ' . string(self.get_begin_pos()))
    for phase in self.get_all_phases()
        let buf_str = self.get_buf_str(phase)
        call add(lines, 'phase: ' . phase)
        call add(lines, 'rom_str: ' . string(buf_str.get_rom_str()))
        call add(lines, 'matched pairs: ' . string(buf_str.get_matched()))
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

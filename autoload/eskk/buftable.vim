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

" Constants {{{
" 0: Normal
" 1: Choosing henkan candidates.
" 2: Waiting for okurigana.
" 3: Choosing henkan candidates.
let [
\   eskk#buftable#PHASE_NORMAL,
\   eskk#buftable#PHASE_HENKAN,
\   eskk#buftable#PHASE_OKURI,
\   eskk#buftable#PHASE_HENKAN_SELECT
\] = range(4)
" }}}

" Functions {{{

" s:RomStr {{{

function! s:RomStr_get() dict "{{{
    return self._str
endfunction "}}}
function! s:RomStr_set(str) dict "{{{
    let self._str = a:str
endfunction "}}}
function! s:RomStr_append(str) dict "{{{
    let self._str .= a:str
endfunction "}}}
function! s:RomStr_chop() dict "{{{
    let s = self._str
    let s = strpart(s, 0, strlen(s) - 1)
    let self._str = s
endfunction "}}}
function! s:RomStr_clear() dict "{{{
    let self._str = ''
endfunction "}}}
function! s:RomStr_empty() dict "{{{
    return self._str ==# ''
endfunction "}}}

let s:RomStr = {
\   '_str': '',
\
\   'get': eskk#util#get_local_funcref('RomStr_get', s:SID_PREFIX),
\   'set': eskk#util#get_local_funcref('RomStr_set', s:SID_PREFIX),
\   'append': eskk#util#get_local_funcref('RomStr_append', s:SID_PREFIX),
\   'chop': eskk#util#get_local_funcref('RomStr_chop', s:SID_PREFIX),
\   'clear': eskk#util#get_local_funcref('RomStr_clear', s:SID_PREFIX),
\   'empty': eskk#util#get_local_funcref('RomStr_empty', s:SID_PREFIX),
\}
" }}}

" s:RomPairs {{{

function! s:RomPairs_get() dict "{{{
    return copy(self._pairs)
endfunction "}}}
function! s:RomPairs_get_rom() dict "{{{
    return join(map(copy(self._pairs), 'v:val[0]'), '')
endfunction "}}}
function! s:RomPairs_get_filter() dict "{{{
    return join(map(copy(self._pairs), 'v:val[1]'), '')
endfunction "}}}
function! s:RomPairs_set(list_pairs) dict "{{{
    let self._pairs = a:list_pairs
endfunction "}}}
function! s:RomPairs_set_one_pair(rom_str, filter_str) dict "{{{
    let pair = [a:rom_str, a:filter_str]
    let self._pairs = [pair]
endfunction "}}}
function! s:RomPairs_push_one_pair(rom_str, filter_str) dict "{{{
    let pair = [a:rom_str, a:filter_str]
    let self._pairs += [pair]
endfunction "}}}
function! s:RomPairs_pop() dict "{{{
    if empty(self._pairs)
        return ''
    else
        return remove(self._pairs, -1)
    endif
endfunction "}}}
function! s:RomPairs_clear() dict "{{{
    let self._pairs = []
endfunction "}}}
function! s:RomPairs_empty() dict "{{{
    return empty(self._pairs)
endfunction "}}}

let s:RomPairs = {
\   '_pairs': [],
\
\   'get': eskk#util#get_local_funcref('RomPairs_get', s:SID_PREFIX),
\   'get_rom': eskk#util#get_local_funcref('RomPairs_get_rom', s:SID_PREFIX),
\   'get_filter': eskk#util#get_local_funcref('RomPairs_get_filter', s:SID_PREFIX),
\   'set': eskk#util#get_local_funcref('RomPairs_set', s:SID_PREFIX),
\   'set_one_pair': eskk#util#get_local_funcref('RomPairs_set_one_pair', s:SID_PREFIX),
\   'push_one_pair': eskk#util#get_local_funcref('RomPairs_push_one_pair', s:SID_PREFIX),
\   'pop': eskk#util#get_local_funcref('RomPairs_pop', s:SID_PREFIX),
\   'clear': eskk#util#get_local_funcref('RomPairs_clear', s:SID_PREFIX),
\   'empty': eskk#util#get_local_funcref('RomPairs_empty', s:SID_PREFIX),
\}

" }}}



" s:BufferString {{{
function! s:BufferString_get_input_rom() dict "{{{
    return self.rom_pairs.get_rom() . self.rom_str.get()
endfunction "}}}

function! s:BufferString_empty() dict "{{{
    return self.rom_str.empty()
    \   && self.rom_pairs.empty()
endfunction "}}}

function! s:BufferString_clear() dict "{{{
    call self.rom_str.clear()
    call self.rom_pairs.clear()
endfunction "}}}


let s:BufferString = {
\   'rom_str': s:RomStr,
\   'rom_pairs': s:RomPairs,
\
\   'get_input_rom': eskk#util#get_local_funcref('BufferString_get_input_rom', s:SID_PREFIX),
\   'empty': eskk#util#get_local_funcref('BufferString_empty', s:SID_PREFIX),
\   'clear': eskk#util#get_local_funcref('BufferString_clear', s:SID_PREFIX),
\}
unlet s:RomStr s:RomPairs
" }}}

" s:Buftable {{{

function! eskk#buftable#new() "{{{
    return deepcopy(s:Buftable)
endfunction "}}}

function! s:Buftable_reset() dict "{{{
    let obj = deepcopy(s:Buftable)
    for k in keys(obj)
        let self[k] = obj[k]
    endfor
endfunction "}}}

function! s:Buftable_get_buf_str(henkan_phase) dict "{{{
    call s:validate_table_idx(self._table, a:henkan_phase)
    return self._table[a:henkan_phase]
endfunction "}}}
function! s:Buftable_get_current_buf_str() dict "{{{
    return self.get_buf_str(self._henkan_phase)
endfunction "}}}
function! s:Buftable_set_buf_str(henkan_phase, buf_str) dict "{{{
    call s:validate_table_idx(self._table, a:henkan_phase)
    let self._table[a:henkan_phase] = a:buf_str
endfunction "}}}


function! s:Buftable_set_old_str(str) dict "{{{
    let self._old_str = a:str
endfunction "}}}
function! s:Buftable_get_old_str() dict "{{{
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
function! s:Buftable_rewrite() dict "{{{
    let [old, new] = [self._old_str, self.get_display_str()]

    let kakutei = self._kakutei_str
    let self._kakutei_str = ''

    let set_begin_pos =
    \   self._set_begin_pos_at_rewrite
    \   && self._henkan_phase ==# g:eskk#buftable#PHASE_HENKAN
    let self._set_begin_pos_at_rewrite = 0

    let inst = eskk#get_buffer_instance()
    if set_begin_pos
        " 1. Delete current string
        " 2. Set begin pos
        " 3. Insert new string

        if kakutei != ''
            let inst.inserted_kakutei = kakutei
            call eskk#map#map(
            \   'be',
            \   '<Plug>(eskk:expr:_inserted_kakutei)',
            \   'eskk#get_buffer_instance().inserted_kakutei'
            \)
        endif
        if new != ''
            let inst.inserted_new = new
            call eskk#map#map(
            \   'be',
            \   '<Plug>(eskk:expr:_inserted_new)',
            \   'eskk#get_buffer_instance().inserted_new'
            \)
        endif

        return
        \   self.make_remove_bs()
        \   . (kakutei != '' ? "\<Plug>(eskk:expr:_inserted_kakutei)" : '')
        \   . "\<Plug>(eskk:_set_begin_pos)"
        \   . (new != '' ? "\<Plug>(eskk:expr:_inserted_new)" : '')
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
            \   eskk#map#key2char(
            \       eskk#map#get_special_map("backspace-key")
            \   ),
            \   eskk#util#mb_strlen(old)
            \       - eskk#util#mb_strlen(inserted_str)
            \)
        elseif old != '' && stridx(inserted_str, old) == 0
            " When inserted_str == "foobar", old == "foo"
            " Insert "bar".
            let inst.inserted =
            \   strpart(inserted_str, strlen(old))
            call eskk#map#map(
            \   'be',
            \   '<Plug>(eskk:expr:_inserted)',
            \   'eskk#get_buffer_instance().inserted'
            \)
            return "\<Plug>(eskk:expr:_inserted)"
        else
            " Delete current string, and insert new string.
            let inst = eskk#get_buffer_instance()
            let inst.inserted = inserted_str
            call eskk#map#map(
            \   'be',
            \   '<Plug>(eskk:expr:_inserted)',
            \   'eskk#get_buffer_instance().inserted'
            \)
            return self.make_remove_bs() . "\<Plug>(eskk:expr:_inserted)"
        endif
    endif
endfunction "}}}
function! s:Buftable_make_remove_bs() dict "{{{
    return repeat(
    \   eskk#map#key2char(eskk#map#get_special_map("backspace-key")),
    \   eskk#util#mb_strlen(self._old_str),
    \)
endfunction "}}}

function! s:Buftable_has_changed() dict "{{{
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

function! s:Buftable_get_display_str(...) dict "{{{
    let with_marker  = get(a:000, 0, 1)
    let with_rom_str = get(a:000, 1, 1)
    let phase = self._henkan_phase

    if phase ==# g:eskk#buftable#PHASE_NORMAL
        return s:get_normal_display_str(self, with_rom_str)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        return s:get_henkan_display_str(self, with_marker, with_rom_str)
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        return s:get_okuri_display_str(self, with_marker, with_rom_str)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        return s:get_henkan_select_display_str(self, with_marker, with_rom_str)
    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! s:get_normal_display_str(this, with_rom_str) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_NORMAL
    \)
    return
    \   buf_str.rom_pairs.get_filter()
    \   . (a:with_rom_str ? buf_str.rom_str.get() : '')
endfunction "}}}
function! s:get_henkan_display_str(this, with_marker, with_rom_str) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN
    \)
    return
    \   (a:with_marker ?
    \       a:this.get_marker(g:eskk#buftable#PHASE_HENKAN)
    \       : '')
    \   . buf_str.rom_pairs.get_filter()
    \   . (a:with_rom_str ? buf_str.rom_str.get() : '')
endfunction "}}}
function! s:get_okuri_display_str(this, with_marker, with_rom_str) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_OKURI
    \)
    return
    \   s:get_henkan_display_str(a:this, a:with_marker, a:with_rom_str)
    \   . (a:with_marker ?
    \       a:this.get_marker(g:eskk#buftable#PHASE_OKURI)
    \       : '')
    \   . buf_str.rom_pairs.get_filter()
    \   . (a:with_rom_str ? buf_str.rom_str.get() : '')
endfunction "}}}
function! s:get_henkan_select_display_str(this, with_marker, with_rom_str) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN_SELECT
    \)
    return
    \   (a:with_marker ?
    \       a:this.get_marker(g:eskk#buftable#PHASE_HENKAN_SELECT)
    \       : '')
    \   . buf_str.rom_pairs.get_filter()
    \   . (a:with_rom_str ? buf_str.rom_str.get() : '')
endfunction "}}}


function! s:Buftable_get_henkan_phase() dict "{{{
    return self._henkan_phase
endfunction "}}}
function! s:Buftable_set_henkan_phase(henkan_phase) dict "{{{
    if a:henkan_phase ==# self._henkan_phase
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


function! s:Buftable_get_phase_name(phase) dict "{{{
    return [
    \   'normal',
    \   'henkan',
    \   'okuri',
    \   'henkan-select',
    \   'jisyo-touroku',
    \][a:phase]
endfunction "}}}


function! s:Buftable_get_lower_phases() dict "{{{
    return reverse(range(
    \   g:eskk#buftable#PHASE_NORMAL,
    \   self._henkan_phase
    \))
endfunction "}}}
function! s:Buftable_get_all_phases() dict "{{{
    return range(
    \   g:eskk#buftable#PHASE_NORMAL,
    \   g:eskk#buftable#PHASE_HENKAN_SELECT
    \)
endfunction "}}}


function! s:Buftable_get_marker(henkan_phase) dict "{{{
    let table = [
    \    '',
    \    g:eskk#marker_henkan,
    \    g:eskk#marker_okuri,
    \    g:eskk#marker_henkan_select,
    \    g:eskk#marker_jisyo_touroku,
    \]
    call s:validate_table_idx(table, a:henkan_phase)
    return table[a:henkan_phase]
endfunction "}}}
function! s:Buftable_get_current_marker() dict "{{{
    return self.get_marker(self.get_henkan_phase())
endfunction "}}}


function! s:Buftable_push_kakutei_str(str) dict "{{{
    let self._kakutei_str .= a:str
endfunction "}}}

function! s:Buftable_do_enter(stash) dict "{{{
    let phase = self.get_henkan_phase()
    let enter_char =
    \   eskk#map#key2char(eskk#map#get_special_map('enter-key'))
    let undo_char  =
    \   eskk#map#key2char(eskk#map#key2char(eskk#map#get_nore_map('<C-g>u')))
    let dict = eskk#get_skk_dict()
    let henkan_result = dict.get_henkan_result()

    if phase ==# g:eskk#buftable#PHASE_NORMAL
        call self.convert_rom_str_inplace(phase)
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [enter_char]
        \)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        call self.convert_rom_str_inplace(phase)
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
        call self.kakutei(self.get_display_str(0))

    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        call self.convert_rom_str_inplace(
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
        call self.kakutei(self.get_display_str(0))

    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        call self.convert_rom_str_inplace(phase)
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
        call self.kakutei(self.get_display_str(0))

    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! s:Buftable_do_backspace(stash) dict "{{{
    if self.get_old_str() == ''
        let a:stash.return = eskk#map#key2char(
        \   eskk#map#get_special_key('backspace-key')
        \)
        return
    endif

    let phase = self.get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        if g:eskk#delete_implies_kakutei
            " Enter normal phase and delete one character.
            let filter_str = eskk#util#mb_chop(self.get_display_str(0))
            call self.push_kakutei_str(filter_str)
            let henkan_select_buf_str = self.get_buf_str(
            \   g:eskk#buftable#PHASE_HENKAN_SELECT
            \)
            call henkan_select_buf_str.clear()

            call self.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
            return
        else
            " Leave henkan select or back to previous candidate if it exists.
            call self.choose_prev_candidate(a:stash)
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
            let filter_str = eskk#util#mb_chop(self.get_display_str(0))
            call self.push_kakutei_str(filter_str)
            let henkan_select_buf_str = self.get_buf_str(
            \   g:eskk#buftable#PHASE_HENKAN_SELECT
            \)
            call henkan_select_buf_str.clear()

            call self.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
            return
        else
            let filter_str = join(map(copy(p), 'v:val[1]'), '')
            let buf_str = self.get_buf_str(
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

    " Build backspaces to delete previous characters.
    for phase in self.get_lower_phases()
        let buf_str = self.get_buf_str(phase)
        if !buf_str.rom_str.empty()
            call buf_str.rom_str.chop()
            break
        elseif !empty(buf_str.rom_pairs.get())
            let p = buf_str.rom_pairs.pop()
            if empty(p)
                continue
            endif
            " ["tyo", "ちょ"] => ["tyo", "ち"]
            if eskk#util#mb_strlen(p[1]) !=# 1
                call buf_str.rom_pairs.push_one_pair(p[0], eskk#util#mb_chop(p[1]))
            endif
            break
        elseif self.get_marker(phase) != ''
            if !self.step_back_henkan_phase()
                let msg = "Normal phase's marker is empty, "
                \       . "and other phases *should* be able to change "
                \       . "current henkan phase."
                throw eskk#internal_error(['eskk', 'buftable'], msg)
            endif
            break
        endif
    endfor
endfunction "}}}
function! s:Buftable_choose_next_candidate(stash) dict "{{{
    return s:get_next_candidate(self, a:stash, 1)
endfunction "}}}
function! s:Buftable_choose_prev_candidate(stash) dict "{{{
    return s:get_next_candidate(self, a:stash, 0)
endfunction "}}}
function! s:get_next_candidate(this, stash, next) "{{{
    let cur_buf_str = a:this.get_current_buf_str()
    let dict = eskk#get_skk_dict()
    let henkan_result = dict.get_henkan_result()
    let prev_buftable = henkan_result.buftable
    let rom_str = cur_buf_str.rom_pairs.get_rom()

    call eskk#util#assert(
    \   a:this.get_henkan_phase()
    \       ==# g:eskk#buftable#PHASE_HENKAN_SELECT,
    \   "current phase is henkan select phase."
    \)

    if henkan_result[a:next ? 'forward' : 'back']()
        let candidate = henkan_result.get_current_candidate()

        " Set candidate.
        " FIXME:
        " Do not set with `rom_str`.
        " Get henkan_result's buftable
        " and get matched rom str(s).
        call cur_buf_str.rom_pairs.set_one_pair(rom_str, candidate)
    else
        " No more candidates.
        if a:next
            " Register new word when it advanced or backed current result index,
            " And tried to step at last candidates but failed.
            let [input, hira, okuri] =
            \   dict.remember_word_prompt(
            \      dict.get_henkan_result()
            \   )
            if input != ''
                call a:this.kakutei(input . okuri)
            endif
        else
            " Restore previous buftable state
            let henkan_buf_str = prev_buftable.get_buf_str(
            \   g:eskk#buftable#PHASE_HENKAN
            \)
            let okuri_buf_str = prev_buftable.get_buf_str(
            \   g:eskk#buftable#PHASE_OKURI
            \)
            let okuri_rom_str = okuri_buf_str.rom_pairs.get_rom()
            if g:eskk#revert_henkan_style ==# 'okuri-one'
                " "▼書く" => "▽か*k"
                if okuri_rom_str != ''
                    call okuri_buf_str.rom_str.set(okuri_rom_str[0])
                    call okuri_buf_str.rom_pairs.clear()
                endif
            elseif g:eskk#revert_henkan_style ==# 'okuri'
                " "▼書く" => "▽か*く"
            elseif g:eskk#revert_henkan_style ==# 'delete-okuri'
                " "▼書く" => "▽か"
                if okuri_rom_str != ''
                    " Clear roms of `okuri_buf_str`.
                    call okuri_buf_str.clear()
                    call prev_buftable.set_henkan_phase(
                    \   g:eskk#buftable#PHASE_HENKAN
                    \)
                endif
            elseif g:eskk#revert_henkan_style ==# 'concat-okuri'
                " "▼書く" => "▽かく"
                if okuri_rom_str != ''
                    " Copy roms of `okuri_buf_str` to `henkan_buf_str`.
                    for okuri_matched in okuri_buf_str.rom_pairs.get()
                        call henkan_buf_str.rom_pairs.push_one_pair(
                        \   okuri_matched[0],
                        \   okuri_matched[1]
                        \)
                    endfor
                    " Clear roms of `okuri_buf_str`.
                    call okuri_buf_str.clear()
                    call prev_buftable.set_henkan_phase(
                    \   g:eskk#buftable#PHASE_HENKAN
                    \)
                endif
            else
                throw eskk#internal_error(
                \   ['eskk', 'buftable'],
                \   "This will never be reached"
                \)
            endif

            call eskk#set_buftable(prev_buftable)
        endif
    endif
endfunction "}}}
function! s:Buftable_do_sticky(stash) dict "{{{
    let phase   = self.get_henkan_phase()
    let buf_str = self.get_current_buf_str()

    " Convert rom_str if possible.
    call self.convert_rom_str_inplace([
    \   g:eskk#buftable#PHASE_HENKAN,
    \   g:eskk#buftable#PHASE_OKURI
    \])

    if phase ==# g:eskk#buftable#PHASE_NORMAL
        if !buf_str.rom_str.empty()
        \   || !buf_str.rom_pairs.empty()
            call self.convert_rom_str_inplace(phase)
            call self.push_kakutei_str(self.get_display_str(0))
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
        let self._set_begin_pos_at_rewrite = 1
        call self.set_henkan_phase(g:eskk#buftable#PHASE_HENKAN)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        if !buf_str.rom_str.empty()
        \   || !buf_str.rom_pairs.empty()
            call self.set_henkan_phase(g:eskk#buftable#PHASE_OKURI)
        endif
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        " nop
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        call self.do_enter(a:stash)
        call self.do_sticky(a:stash)
    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! s:Buftable_step_back_henkan_phase() dict "{{{
    let phase   = self.get_henkan_phase()
    let buf_str = self.get_current_buf_str()

    if phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        call buf_str.clear()
        let okuri_buf_str = self.get_buf_str(
        \   g:eskk#buftable#PHASE_OKURI
        \)
        call self.set_henkan_phase(
        \   !empty(okuri_buf_str.rom_pairs.get()) ?
        \       g:eskk#buftable#PHASE_OKURI
        \       : g:eskk#buftable#PHASE_HENKAN
        \)
        return 1
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        call buf_str.clear()
        call self.set_henkan_phase(g:eskk#buftable#PHASE_HENKAN)
        return 1    " stepped.
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        call buf_str.clear()
        call self.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
        return 1    " stepped.
    elseif phase ==# g:eskk#buftable#PHASE_NORMAL
        return 0    " failed.
    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! s:Buftable_do_henkan(stash, ...) dict "{{{
    let convert_at_exact_match = a:0 ? a:1 : 0
    let phase = self.get_henkan_phase()

    if self.get_current_buf_str().empty()
        return
    endif

    if index(
    \   [g:eskk#buftable#PHASE_HENKAN,
    \       g:eskk#buftable#PHASE_OKURI],
    \   phase,
    \) ==# -1
        " TODO Add an error id like Vim
        call eskk#logger#warnf(
        \   "s:buftable.do_henkan() does not support phase %d.",
        \   phase
        \)
        return
    endif

    if eskk#get_mode() ==# 'abbrev'
        call self.do_henkan_abbrev(a:stash, convert_at_exact_match)
    else
        call self.do_henkan_other(a:stash, convert_at_exact_match)
    endif
endfunction "}}}
function! s:Buftable_do_henkan_abbrev(stash, convert_at_exact_match) dict "{{{
    let henkan_buf_str = self.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN
    \)
    let henkan_select_buf_str = self.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN_SELECT
    \)

    let rom_str = henkan_buf_str.rom_str.get()
    let dict = eskk#get_skk_dict()

    try
        let henkan_result = dict.refer(self, rom_str, '', '')
        let candidate = henkan_result.get_current_candidate()
        " No thrown exception. continue...

        call self.clear_all()
        if a:convert_at_exact_match
            call henkan_buf_str.rom_pairs.set_one_pair(rom_str, candidate)
        else
            call henkan_select_buf_str.rom_pairs.set_one_pair(rom_str, candidate)
            call self.set_henkan_phase(
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
            call self.kakutei(input . okuri)
        endif
    endtry
endfunction "}}}
function! s:Buftable_do_henkan_other(stash, convert_at_exact_match) dict "{{{
    let phase = self.get_henkan_phase()
    let henkan_buf_str = self.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN
    \)
    let okuri_buf_str = self.get_buf_str(
    \   g:eskk#buftable#PHASE_OKURI
    \)
    let henkan_select_buf_str = self.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN_SELECT
    \)

    if g:eskk#kata_convert_to_hira_at_henkan
    \   && eskk#get_mode() ==# 'kata'
        call self.convert_rom_pairs_inplace(
        \   [
        \       g:eskk#buftable#PHASE_HENKAN,
        \       g:eskk#buftable#PHASE_OKURI,
        \   ],
        \   eskk#get_mode_table('hira')
        \)
    endif

    " Convert rom_str if possible.
    call self.convert_rom_str_inplace([
    \   g:eskk#buftable#PHASE_HENKAN,
    \   g:eskk#buftable#PHASE_OKURI
    \])

    if g:eskk#fix_extra_okuri
    \   && !henkan_buf_str.rom_str.empty()
    \   && phase ==# g:eskk#buftable#PHASE_HENKAN
        call okuri_buf_str.rom_str.set(henkan_buf_str.rom_str.get())
        call henkan_buf_str.rom_str.clear()
        call self.set_henkan_phase(g:eskk#buftable#PHASE_OKURI)
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
        let henkan_result = dict.refer(self, hira, okuri, okuri_rom)
        let candidate = henkan_result.get_current_candidate()

        call self.clear_all()
        if a:convert_at_exact_match
            call henkan_buf_str.rom_pairs.set_one_pair(rom_str, candidate)
        else
            call henkan_select_buf_str.rom_pairs.set_one_pair(rom_str, candidate)
            call self.set_henkan_phase(
            \   g:eskk#buftable#PHASE_HENKAN_SELECT
            \)
            if g:eskk#kakutei_when_unique_candidate
            \   && !henkan_result.has_next()
                call self.kakutei(self.get_display_str(0))
            endif
        endif
    catch /^eskk: dictionary look up error/
        " No candidates.
        let [input, hira, okuri] =
        \   dict.remember_word_prompt(
        \      dict.get_henkan_result()
        \   )
        if input != ''
            call self.kakutei(input . okuri)
        endif
    endtry
endfunction "}}}
function! s:Buftable_do_ctrl_q_key() dict "{{{
    return s:convert_roms_and_kakutei(
    \   self,
    \   (eskk#get_mode() ==# 'hira' ?
    \       eskk#get_mode_table('hankata') :
    \       eskk#get_mode_table('hira'))
    \)
endfunction "}}}
function! s:Buftable_do_q_key() dict "{{{
    return s:convert_roms_and_kakutei(
    \   self,
    \   (eskk#get_mode() ==# 'hira' ?
    \       eskk#get_mode_table('kata') :
    \       eskk#get_mode_table('hira'))
    \)
endfunction "}}}
function! s:Buftable_do_l_key() dict "{{{
    " s:convert_roms_and_kakutei() does not convert rom_str
    " if it received empty dictionary.
    return s:convert_roms_and_kakutei(self, {})
endfunction "}}}
function! s:Buftable_do_escape(stash) dict "{{{
    call self.convert_rom_str_inplace(
    \   self.get_henkan_phase()
    \)

    let kakutei_str = self.generate_kakutei_str()
    " NOTE: This function return value is not remapped.
    let esc = eskk#map#get_special_key('escape-key')
    call eskk#util#assert(esc != '', 'esc must not be empty string')
    let a:stash.return = kakutei_str . eskk#map#key2char(esc)
endfunction "}}}
function! s:Buftable_do_tab(stash) dict "{{{
    let buf_str = self.get_current_buf_str()
    call buf_str.rom_str.append(s:get_tab_raw_str())
endfunction "}}}
function! s:get_tab_raw_str() "{{{
    return &l:expandtab ? repeat(' ', &tabstop) : "\<Tab>"
endfunction "}}}

" Convert rom_str and move it to rom_pairs.
function! s:Buftable_convert_rom_str_inplace(phases, ...) dict "{{{
    let table = a:0 ? a:1 : s:get_current_table()
    let phases = type(a:phases) == type([]) ?
    \               a:phases : [a:phases]
    for buf_str in map(phases, 'self.get_buf_str(v:val)')
        let rom_str = buf_str.rom_str.get()
        if table.has_map(rom_str)
            " "n" => "ん"
            call buf_str.rom_pairs.push_one_pair(
            \   rom_str,
            \   table.get_map(rom_str)
            \)
            call buf_str.rom_str.clear()
        endif
    endfor
endfunction "}}}
" Convert rom_pairs and store it to rom_pairs itself.
" If a:table is empty, do not convert rom_str
" (Leave rom_str as rom_str)
function! s:Buftable_convert_rom_pairs_inplace(phases, ...) dict "{{{
    let table = a:0 ? a:1 : s:get_current_table()
    let phases = type(a:phases) == type([]) ?
    \               a:phases : [a:phases]
    for p in phases
        let buf_str = self.convert_rom_pairs(p, table)
        call self.set_buf_str(p, buf_str)
    endfor
endfunction "}}}
" Convert rom_pairs and return it.
" If a:table is empty, do not convert rom_str
" (Leave rom_str as rom_str)
function! s:Buftable_convert_rom_pairs(phases, ...) dict "{{{
    let table = a:0 ? a:1 : s:get_current_table()
    let phases = type(a:phases) == type([]) ?
    \               a:phases : [a:phases]
    let r = []
    for p in phases
        let buf_str = deepcopy(self.get_buf_str(p), 1)
        let matched = buf_str.rom_pairs.get()
        call buf_str.rom_pairs.clear()
        for [rom_str, filter_str] in matched
            call buf_str.rom_pairs.push_one_pair(
            \   rom_str,
            \   (!empty(table) ?
            \       table.get_map(rom_str, rom_str) :
            \       rom_str)
            \)
        endfor
        call add(r, buf_str)
    endfor
    return type(a:phases) == type([]) ? r : r[0]
endfunction "}}}
function! s:get_current_table() "{{{
    if g:eskk#kata_convert_to_hira_at_henkan
    \   && eskk#get_mode() ==# 'kata'
        return eskk#get_mode_table('hira')
    else
        return eskk#get_current_mode_table()
    endif
endfunction "}}}
function! s:convert_roms_and_kakutei(this, table) "{{{
    call a:this.convert_rom_pairs_inplace([
    \   g:eskk#buftable#PHASE_NORMAL,
    \   g:eskk#buftable#PHASE_HENKAN,
    \   g:eskk#buftable#PHASE_OKURI,
    \], a:table)
    call a:this.kakutei(a:this.get_display_str(0))
endfunction "}}}

function! s:Buftable_kakutei(str) dict "{{{
    if a:str !=# ''
        call self.push_kakutei_str(a:str)
    endif
    call self.clear_all()
    call self.set_henkan_phase(
    \   g:eskk#buftable#PHASE_NORMAL
    \)
endfunction "}}}

function! s:Buftable_clear_all() dict "{{{
    for phase in self.get_all_phases()
        let buf_str = self.get_buf_str(phase)
        call buf_str.clear()
    endfor
endfunction "}}}

function! s:Buftable_remove_display_str() dict "{{{
    let current_str = self.get_display_str()

    " NOTE: This function return value is not remapped.
    let bs = eskk#map#get_special_key('backspace-key')
    call eskk#util#assert(bs != '', 'bs must not be empty string')

    return repeat(
    \   eskk#map#key2char(bs),
    \   eskk#util#mb_strlen(current_str)
    \)
endfunction "}}}
function! s:Buftable_generate_kakutei_str() dict "{{{
    return self.remove_display_str() . self.get_display_str(0)
endfunction "}}}


function! s:Buftable_empty() dict "{{{
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


function! s:Buftable_dump() dict "{{{
    let lines = []
    call add(lines, 'current phase: ' . self._henkan_phase)
    for phase in self.get_all_phases()
        let buf_str = self.get_buf_str(phase)
        call add(lines, 'phase: ' . phase)
        call add(lines, 'rom_str: ' . string(buf_str.rom_str.get()))
        call add(lines, 'matched pairs: ' . string(buf_str.rom_pairs.get()))
    endfor
    return lines
endfunction "}}}


function! s:validate_table_idx(table, henkan_phase) "{{{
    if !eskk#util#has_idx(a:table, a:henkan_phase)
        throw eskk#buftable#invalid_henkan_phase_value_error(a:henkan_phase)
    endif
endfunction "}}}
function! eskk#buftable#invalid_henkan_phase_value_error(henkan_phase) "{{{
    return eskk#util#build_error(
    \   ["eskk", "buftable"],
    \   ["invalid henkan phase value '" . a:henkan_phase . "'"]
    \)
endfunction "}}}


let s:Buftable = {
\   '_table': [
\       deepcopy(s:BufferString),
\       deepcopy(s:BufferString),
\       deepcopy(s:BufferString),
\       deepcopy(s:BufferString),
\       deepcopy(s:BufferString),
\   ],
\   '_kakutei_str': '',
\   '_old_str': '',
\   '_begin_pos': [],
\   '_henkan_phase': g:eskk#buftable#PHASE_NORMAL,
\   '_set_begin_pos_at_rewrite': 0,
\
\   'reset': eskk#util#get_local_funcref('Buftable_reset', s:SID_PREFIX),
\   'get_buf_str': eskk#util#get_local_funcref('Buftable_get_buf_str', s:SID_PREFIX),
\   'get_current_buf_str': eskk#util#get_local_funcref('Buftable_get_current_buf_str', s:SID_PREFIX),
\   'set_buf_str': eskk#util#get_local_funcref('Buftable_set_buf_str', s:SID_PREFIX),
\   'set_old_str': eskk#util#get_local_funcref('Buftable_set_old_str', s:SID_PREFIX),
\   'get_old_str': eskk#util#get_local_funcref('Buftable_get_old_str', s:SID_PREFIX),
\   'rewrite': eskk#util#get_local_funcref('Buftable_rewrite', s:SID_PREFIX),
\   'make_remove_bs': eskk#util#get_local_funcref('Buftable_make_remove_bs', s:SID_PREFIX),
\   'has_changed': eskk#util#get_local_funcref('Buftable_has_changed', s:SID_PREFIX),
\   'get_display_str': eskk#util#get_local_funcref('Buftable_get_display_str', s:SID_PREFIX),
\   'get_henkan_phase': eskk#util#get_local_funcref('Buftable_get_henkan_phase', s:SID_PREFIX),
\   'set_henkan_phase': eskk#util#get_local_funcref('Buftable_set_henkan_phase', s:SID_PREFIX),
\   'get_phase_name': eskk#util#get_local_funcref('Buftable_get_phase_name', s:SID_PREFIX),
\   'get_lower_phases': eskk#util#get_local_funcref('Buftable_get_lower_phases', s:SID_PREFIX),
\   'get_all_phases': eskk#util#get_local_funcref('Buftable_get_all_phases', s:SID_PREFIX),
\   'get_marker': eskk#util#get_local_funcref('Buftable_get_marker', s:SID_PREFIX),
\   'get_current_marker': eskk#util#get_local_funcref('Buftable_get_current_marker', s:SID_PREFIX),
\   'push_kakutei_str': eskk#util#get_local_funcref('Buftable_push_kakutei_str', s:SID_PREFIX),
\   'do_enter': eskk#util#get_local_funcref('Buftable_do_enter', s:SID_PREFIX),
\   'do_backspace': eskk#util#get_local_funcref('Buftable_do_backspace', s:SID_PREFIX),
\   'choose_next_candidate': eskk#util#get_local_funcref('Buftable_choose_next_candidate', s:SID_PREFIX),
\   'choose_prev_candidate': eskk#util#get_local_funcref('Buftable_choose_prev_candidate', s:SID_PREFIX),
\   'do_sticky': eskk#util#get_local_funcref('Buftable_do_sticky', s:SID_PREFIX),
\   'step_back_henkan_phase': eskk#util#get_local_funcref('Buftable_step_back_henkan_phase', s:SID_PREFIX),
\   'do_henkan': eskk#util#get_local_funcref('Buftable_do_henkan', s:SID_PREFIX),
\   'do_henkan_abbrev': eskk#util#get_local_funcref('Buftable_do_henkan_abbrev', s:SID_PREFIX),
\   'do_henkan_other': eskk#util#get_local_funcref('Buftable_do_henkan_other', s:SID_PREFIX),
\   'do_ctrl_q_key': eskk#util#get_local_funcref('Buftable_do_ctrl_q_key', s:SID_PREFIX),
\   'do_q_key': eskk#util#get_local_funcref('Buftable_do_q_key', s:SID_PREFIX),
\   'do_l_key': eskk#util#get_local_funcref('Buftable_do_l_key', s:SID_PREFIX),
\   'do_escape': eskk#util#get_local_funcref('Buftable_do_escape', s:SID_PREFIX),
\   'do_tab': eskk#util#get_local_funcref('Buftable_do_tab', s:SID_PREFIX),
\   'convert_rom_str_inplace': eskk#util#get_local_funcref('Buftable_convert_rom_str_inplace', s:SID_PREFIX),
\   'convert_rom_pairs_inplace': eskk#util#get_local_funcref('Buftable_convert_rom_pairs_inplace', s:SID_PREFIX),
\   'convert_rom_pairs': eskk#util#get_local_funcref('Buftable_convert_rom_pairs', s:SID_PREFIX),
\   'kakutei': eskk#util#get_local_funcref('Buftable_kakutei', s:SID_PREFIX),
\   'clear_all': eskk#util#get_local_funcref('Buftable_clear_all', s:SID_PREFIX),
\   'remove_display_str': eskk#util#get_local_funcref('Buftable_remove_display_str', s:SID_PREFIX),
\   'generate_kakutei_str': eskk#util#get_local_funcref('Buftable_generate_kakutei_str', s:SID_PREFIX),
\   'empty': eskk#util#get_local_funcref('Buftable_empty', s:SID_PREFIX),
\   'dump': eskk#util#get_local_funcref('Buftable_dump', s:SID_PREFIX),
\}

" }}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

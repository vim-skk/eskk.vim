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
\   g:eskk#preedit#PHASE_NORMAL,
\   g:eskk#preedit#PHASE_HENKAN,
\   g:eskk#preedit#PHASE_OKURI,
\   g:eskk#preedit#PHASE_HENKAN_SELECT
\] = range(4)
" }}}


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
function! s:RomStr_pop() dict "{{{
    if self._str ==# ''
        return ''
    endif
    " self._str only contains ascii character,
    " so strlen(self._str) is safe.
    let [self._str, c] = [self._str[:-2], self._str[strlen(self._str)-1]]
    return c
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
\   'pop': eskk#util#get_local_funcref('RomStr_pop', s:SID_PREFIX),
\   'clear': eskk#util#get_local_funcref('RomStr_clear', s:SID_PREFIX),
\   'empty': eskk#util#get_local_funcref('RomStr_empty', s:SID_PREFIX),
\}
" }}}

" s:RomPairs {{{

function! s:RomPairs_get(...) dict "{{{
    return copy(a:0 ? self._pairs[a:1] : self._pairs)
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
function! s:RomPairs_set_one_pair(rom_str, filter_str, ...) dict "{{{
    let pair = [a:rom_str, a:filter_str]
    \           + (a:0 && type(a:1) is type({}) ? [a:1] : [{}])
    let self._pairs = [pair]
endfunction "}}}
function! s:RomPairs_push(pair) dict "{{{
        let self._pairs += [pair]
endfunction "}}}
function! s:RomPairs_push_one_pair(rom_str, filter_str, ...) dict "{{{
    let pair = [a:rom_str, a:filter_str]
    \           + (a:0 && type(a:1) is type({}) ? [a:1] : [{}])
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
\   'push': eskk#util#get_local_funcref('RomPairs_push', s:SID_PREFIX),
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

" s:Preedit {{{

function! eskk#preedit#new() "{{{
    return deepcopy(s:Preedit)
endfunction "}}}

function! s:Preedit_reset() dict "{{{
    let obj = deepcopy(s:Preedit)
    for k in keys(obj)
        let self[k] = obj[k]
    endfor
endfunction "}}}

function! s:Preedit_get_buf_str(henkan_phase) dict "{{{
    call s:validate_table_idx(self._table, a:henkan_phase)
    return self._table[a:henkan_phase]
endfunction "}}}
function! s:Preedit_get_current_buf_str() dict "{{{
    return self.get_buf_str(self._henkan_phase)
endfunction "}}}
function! s:Preedit_set_buf_str(henkan_phase, buf_str) dict "{{{
    call s:validate_table_idx(self._table, a:henkan_phase)
    let self._table[a:henkan_phase] = a:buf_str
endfunction "}}}


function! s:Preedit_set_old_str(str) dict "{{{
    let self._old_str = a:str
endfunction "}}}
function! s:Preedit_get_old_str() dict "{{{
    return self._old_str
endfunction "}}}

function! s:Preedit_get_inserted_str() dict "{{{
    if self.get_old_str() ==# ''
        return ''
    endif
    let begin = self.get_begin_col() - 1
    let end   = begin + strlen(self.get_old_str()) - 1
    " FIXME: while completion, somethies getline('.') lacks a:base string.
    return getline('.')[begin : end]
endfunction "}}}

" Remove a old string, Insert a new string.
"
" NOTE: Current implementation depends on &backspace
" when inserted string has newline.
function! s:Preedit_rewrite() dict "{{{
    let [bs_num, inserted] =
    \   call('s:calculate_rewrite', [], self)
    let self._kakutei_str = ''

    if inserted !=# ''
        let inst = eskk#get_buffer_instance()
        let inst.inserted = inserted
        call eskk#map#map(
        \   'be',
        \   '<Plug>(eskk:expr:_inserted)',
        \   'eskk#get_buffer_instance().inserted'
        \)
    endif
    let bs = eskk#map#key2char(
    \           eskk#map#get_special_map("backspace-key"))
    let filter =
    \   repeat(bs, bs_num)
    \   . (inserted !=# '' ? "\<Plug>(eskk:expr:_inserted)" : '')

    let filter_pre = self._filter_pre
    let self._filter_pre = ''
    let filter_post = self._filter_post
    let self._filter_post = ''

    return filter_pre . filter . filter_post
endfunction "}}}
function! s:calculate_rewrite() dict "{{{
    let old = self._old_str
    let new = self._kakutei_str . self.get_display_str()


    if old ==# new
        return [0, '']
    elseif new == ''
        return [eskk#util#mb_strlen(old), '']
    elseif old == ''
        " Insert a new string.
        return [0, new]
    elseif stridx(old, new) == 0
        " When new == "foo", old == "foobar"
        " Remove "bar".
        let bs_num =
        \   eskk#util#mb_strlen(old)
        \       - eskk#util#mb_strlen(new)
        return [bs_num, '']
    elseif stridx(new, old) == 0
        " When new == "foobar", old == "foo"
        " Insert "bar".
        return [0, strpart(new, strlen(old))]
    else
        let idx = eskk#util#diffidx(old, new)
        if idx != -1
            " When new == "foobar", old == "fool"
            " Insert "<BS>bar".

            " Remove common string.
            let old = strpart(old, idx)
            let new = strpart(new, idx)
            let bs = eskk#map#key2char(
            \           eskk#map#get_special_map("backspace-key"))
            return [eskk#util#mb_strlen(old), new]
        else
            " Delete current string, and insert new string.
            return [eskk#util#mb_strlen(old), new]
        endif
    endif
endfunction "}}}

function! s:Preedit_get_display_str(...) dict "{{{
    let with_marker  = get(a:000, 0, 1)
    let with_rom_str = get(a:000, 1, 1)
    let phase = self._henkan_phase

    if phase ==# g:eskk#preedit#PHASE_NORMAL
        return s:get_normal_display_str(self, with_rom_str)
    elseif phase ==# g:eskk#preedit#PHASE_HENKAN
        return s:get_henkan_display_str(self, with_marker, with_rom_str)
    elseif phase ==# g:eskk#preedit#PHASE_OKURI
        return s:get_okuri_display_str(self, with_marker, with_rom_str)
    elseif phase ==# g:eskk#preedit#PHASE_HENKAN_SELECT
        return s:get_henkan_select_display_str(self, with_marker, with_rom_str)
    else
        throw eskk#internal_error(['eskk', 'preedit'])
    endif
endfunction "}}}
function! s:get_normal_display_str(this, with_rom_str) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#preedit#PHASE_NORMAL
    \)
    return
    \   buf_str.rom_pairs.get_filter()
    \   . (a:with_rom_str ? buf_str.rom_str.get() : '')
endfunction "}}}
function! s:get_henkan_display_str(this, with_marker, with_rom_str) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#preedit#PHASE_HENKAN
    \)
    return
    \   (a:with_marker ?
    \       a:this.get_marker(g:eskk#preedit#PHASE_HENKAN)
    \       : '')
    \   . buf_str.rom_pairs.get_filter()
    \   . (a:with_rom_str ? buf_str.rom_str.get() : '')
endfunction "}}}
function! s:get_okuri_display_str(this, with_marker, with_rom_str) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#preedit#PHASE_OKURI
    \)
    return
    \   s:get_henkan_display_str(a:this, a:with_marker, a:with_rom_str)
    \   . (a:with_marker ?
    \       a:this.get_marker(g:eskk#preedit#PHASE_OKURI)
    \       : '')
    \   . buf_str.rom_pairs.get_filter()
    \   . (a:with_rom_str ? buf_str.rom_str.get() : '')
endfunction "}}}
function! s:get_henkan_select_display_str(this, with_marker, with_rom_str) "{{{
    let buf_str = a:this.get_buf_str(
    \   g:eskk#preedit#PHASE_HENKAN_SELECT
    \)
    return
    \   (a:with_marker ?
    \       a:this.get_marker(g:eskk#preedit#PHASE_HENKAN_SELECT)
    \       : '')
    \   . buf_str.rom_pairs.get_filter()
    \   . (a:with_rom_str ? buf_str.rom_str.get() : '')
endfunction "}}}


function! s:Preedit_get_henkan_phase() dict "{{{
    return self._henkan_phase
endfunction "}}}
function! s:Preedit_set_henkan_phase(henkan_phase) dict "{{{
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


function! s:Preedit_get_phase_name(phase) dict "{{{
    return [
    \   'normal',
    \   'henkan',
    \   'okuri',
    \   'henkan-select',
    \   'jisyo-touroku',
    \][a:phase]
endfunction "}}}


function! s:Preedit_get_lower_phases() dict "{{{
    return reverse(range(
    \   g:eskk#preedit#PHASE_NORMAL,
    \   self._henkan_phase
    \))
endfunction "}}}
function! s:Preedit_get_all_phases() dict "{{{
    return range(
    \   g:eskk#preedit#PHASE_NORMAL,
    \   g:eskk#preedit#PHASE_HENKAN_SELECT
    \)
endfunction "}}}


function! s:Preedit_get_marker(henkan_phase) dict "{{{
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
function! s:Preedit_get_current_marker() dict "{{{
    return self.get_marker(self.get_henkan_phase())
endfunction "}}}


function! s:Preedit_push_kakutei_str(str) dict "{{{
    let self._kakutei_str .= a:str
endfunction "}}}

function! s:Preedit_choose_next_candidate(stash) dict "{{{
    return s:get_next_candidate(self, a:stash, 1)
endfunction "}}}
function! s:Preedit_choose_prev_candidate(stash) dict "{{{
    return s:get_next_candidate(self, a:stash, 0)
endfunction "}}}
function! s:get_next_candidate(this, stash, next) "{{{
    let cur_buf_str = a:this.get_current_buf_str()
    let dict = eskk#get_skk_dict()
    let henkan_result = dict.get_henkan_result()
    let prev_preedit = henkan_result.preedit
    let rom_str = cur_buf_str.rom_pairs.get_rom()

    call eskk#util#assert(
    \   a:this.get_henkan_phase()
    \       ==# g:eskk#preedit#PHASE_HENKAN_SELECT,
    \   "current phase is henkan select phase."
    \)

    if henkan_result[a:next ? 'forward' : 'back']()
        let candidate = henkan_result.get_current_candidate()

        " Set candidate.
        " FIXME:
        " Do not set with `rom_str`.
        " Get henkan_result's preedit
        " and get matched rom str(s).
        call cur_buf_str.rom_pairs.set_one_pair(rom_str, candidate, {'converted': 1})
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
            " Restore previous preedit state
            let henkan_buf_str = prev_preedit.get_buf_str(
            \   g:eskk#preedit#PHASE_HENKAN
            \)
            let okuri_buf_str = prev_preedit.get_buf_str(
            \   g:eskk#preedit#PHASE_OKURI
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
                    call prev_preedit.set_henkan_phase(
                    \   g:eskk#preedit#PHASE_HENKAN
                    \)
                endif
            elseif g:eskk#revert_henkan_style ==# 'concat-okuri'
                " "▼書く" => "▽かく"
                if okuri_rom_str != ''
                    " Copy roms of `okuri_buf_str` to `henkan_buf_str`.
                    for okuri_matched in okuri_buf_str.rom_pairs.get()
                        call call(henkan_buf_str.rom_pairs.push_one_pair, okuri_matched)
                    endfor
                    " Clear roms of `okuri_buf_str`.
                    call okuri_buf_str.clear()
                    call prev_preedit.set_henkan_phase(
                    \   g:eskk#preedit#PHASE_HENKAN
                    \)
                endif
            else
                throw eskk#internal_error(
                \   ['eskk', 'preedit'],
                \   "This will never be reached"
                \)
            endif

            call eskk#set_preedit(prev_preedit)
        endif
    endif
endfunction "}}}
function! s:Preedit_step_back_henkan_phase() dict "{{{
    let phase   = self.get_henkan_phase()
    let buf_str = self.get_current_buf_str()

    if phase ==# g:eskk#preedit#PHASE_HENKAN_SELECT
        call buf_str.clear()
        let okuri_buf_str = self.get_buf_str(
        \   g:eskk#preedit#PHASE_OKURI
        \)
        call self.set_henkan_phase(
        \   !okuri_buf_str.rom_pairs.empty() ?
        \       g:eskk#preedit#PHASE_OKURI
        \       : g:eskk#preedit#PHASE_HENKAN
        \)
        return 1
    elseif phase ==# g:eskk#preedit#PHASE_OKURI
        call buf_str.clear()
        call self.set_henkan_phase(g:eskk#preedit#PHASE_HENKAN)
        return 1    " stepped.
    elseif phase ==# g:eskk#preedit#PHASE_HENKAN
        call buf_str.clear()
        call self.set_henkan_phase(g:eskk#preedit#PHASE_NORMAL)
        return 1    " stepped.
    elseif phase ==# g:eskk#preedit#PHASE_NORMAL
        return 0    " failed.
    else
        throw eskk#internal_error(['eskk', 'preedit'])
    endif
endfunction "}}}


" Convert rom_str and move it to rom_pairs.
function! s:Preedit_convert_rom_str_inplace(phases, ...) dict "{{{
    let table = a:0 ? a:1 : s:get_current_table()
    if empty(table)
        return
    endif

    let phases = type(a:phases) == type([]) ?
    \               a:phases : [a:phases]
    for buf_str in map(phases, 'self.get_buf_str(v:val)')
        let rom_str = buf_str.rom_str.get()
        if table.has_map(rom_str)
            " "n" => "ん"
            call buf_str.rom_pairs.push_one_pair(
            \   rom_str,
            \   table.get_map(rom_str),
            \   {'converted': 1}
            \)
            call buf_str.rom_str.clear()
        endif
    endfor
endfunction "}}}
" Convert *rom_str in rom_pairs* and store it to rom_pairs itself.
" If a:table is empty, do not convert rom_str
function! s:Preedit_convert_rom_all_inplace(phases, ...) dict "{{{
    let table = a:0 ? a:1 : s:get_current_table()
    let phases = type(a:phases) == type([]) ?
    \               a:phases : [a:phases]
    for p in phases
        let buf_str = self.convert_rom_all(p, table)
        call self.set_buf_str(p, buf_str)
    endfor
endfunction "}}}
" Convert *rom_str in rom_pairs* and return it.
" If a:table is empty, do not convert rom_str in rom_pairs.
function! s:Preedit_convert_rom_all(phases, ...) dict "{{{
    let table = a:0 ? a:1 : s:get_current_table()
    let phases = type(a:phases) == type([]) ?
    \               a:phases : [a:phases]
    let r = []
    for p in phases
        let buf_str = deepcopy(self.get_buf_str(p), 1)
        let matched = buf_str.rom_pairs.get()
        call buf_str.rom_pairs.clear()
        for [rom_str; _] in matched
            call buf_str.rom_pairs.push_one_pair(
            \   rom_str,
            \   (!empty(table) ?
            \       table.get_map(rom_str, rom_str) :
            \       rom_str),
            \   {'converted': 1}
            \)
        endfor
        call add(r, buf_str)
    endfor
    return type(a:phases) == type([]) ? r : r[0]
endfunction "}}}
function! s:get_current_table() "{{{
    if eskk#get_mode() ==# 'abbrev'
        return {}
    elseif g:eskk#kata_convert_to_hira_at_henkan
    \   && eskk#get_mode() ==# 'kata'
        return eskk#get_mode_table('hira')
    else
        return eskk#get_current_mode_table()
    endif
endfunction "}}}

function! s:Preedit_kakutei(str) dict "{{{
    if a:str !=# ''
        call self.push_kakutei_str(a:str)
    endif
    call self.clear_all()
    call self.set_henkan_phase(
    \   g:eskk#preedit#PHASE_NORMAL
    \)
endfunction "}}}

function! s:Preedit_clear_all() dict "{{{
    for phase in self.get_all_phases()
        let buf_str = self.get_buf_str(phase)
        call buf_str.clear()
    endfor
endfunction "}}}

function! s:Preedit_remove_display_str() dict "{{{
    let current_str = self.get_display_str()

    " NOTE: This function return value is not remapped.
    let bs = eskk#map#get_special_key('backspace-key')
    call eskk#util#assert(bs != '', 'bs must not be empty string')

    return repeat(
    \   eskk#map#key2char(bs),
    \   eskk#util#mb_strlen(current_str)
    \)
endfunction "}}}
function! s:Preedit_generate_kakutei_str() dict "{{{
    return self.remove_display_str() . self.get_display_str(0)
endfunction "}}}


function! s:Preedit_empty() dict "{{{
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


function! s:Preedit_empty_filter_queue() dict "{{{
    return empty(self._filter_queue)
endfunction
function! s:Preedit_push_filter_queue(char) dict "{{{
    call add(self._filter_queue, a:char)
endfunction "}}}
function! s:Preedit_shift_filter_queue() dict "{{{
    return remove(self._filter_queue, 0)
endfunction "}}}


function! s:Preedit_push_filter_pre_char(char) dict "{{{
    let self._filter_pre .= a:char
endfunction "}}}
function! s:Preedit_push_filter_post_char(char) dict "{{{
    let self._filter_post .= a:char
endfunction "}}}


" XXX: begin col of when?
" 1. before eskk#filter()
" 2. during eskk#filter()
" 3. after eskk#filter() (neocomplcache)
function! s:Preedit_set_begin_col(col) dict "{{{
    let self._begin_col = a:col
endfunction "}}}
function! s:Preedit_get_begin_col() dict "{{{
    if self._henkan_phase is g:eskk#preedit#PHASE_NORMAL
        throw eskk#util#build_error(
        \   ['eskk', 'preedit'],
        \   'internal error: Preedit.get_begin_col()'
        \       . ' must not be called in normal phase.'
        \)
    endif
    if self._begin_col <=# 0
        throw eskk#util#build_error(
        \   ['eskk', 'preedit'],
        \   'internal error: begin col is invalid.'
        \)
    endif
    return self._begin_col
endfunction "}}}


function! s:Preedit_dump() dict "{{{
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
        throw eskk#preedit#invalid_henkan_phase_value_error(a:henkan_phase)
    endif
endfunction "}}}
function! eskk#preedit#invalid_henkan_phase_value_error(henkan_phase) "{{{
    return eskk#util#build_error(
    \   ["eskk", "preedit"],
    \   ["invalid henkan phase value '" . a:henkan_phase . "'"]
    \)
endfunction "}}}


let s:Preedit = {
\   '_table': [
\       deepcopy(s:BufferString),
\       deepcopy(s:BufferString),
\       deepcopy(s:BufferString),
\       deepcopy(s:BufferString),
\   ],
\   '_kakutei_str': '',
\   '_old_str': '',
\   '_begin_col': -1,
\   '_henkan_phase': g:eskk#preedit#PHASE_NORMAL,
\   '_filter_queue': [],
\   '_filter_pre': '',
\   '_filter_post': '',
\
\   'reset': eskk#util#get_local_funcref('Preedit_reset', s:SID_PREFIX),
\   'get_buf_str': eskk#util#get_local_funcref('Preedit_get_buf_str', s:SID_PREFIX),
\   'get_current_buf_str': eskk#util#get_local_funcref('Preedit_get_current_buf_str', s:SID_PREFIX),
\   'set_buf_str': eskk#util#get_local_funcref('Preedit_set_buf_str', s:SID_PREFIX),
\   'set_old_str': eskk#util#get_local_funcref('Preedit_set_old_str', s:SID_PREFIX),
\   'get_old_str': eskk#util#get_local_funcref('Preedit_get_old_str', s:SID_PREFIX),
\   'get_inserted_str': eskk#util#get_local_funcref('Preedit_get_inserted_str', s:SID_PREFIX),
\   'rewrite': eskk#util#get_local_funcref('Preedit_rewrite', s:SID_PREFIX),
\   'get_display_str': eskk#util#get_local_funcref('Preedit_get_display_str', s:SID_PREFIX),
\   'get_henkan_phase': eskk#util#get_local_funcref('Preedit_get_henkan_phase', s:SID_PREFIX),
\   'set_henkan_phase': eskk#util#get_local_funcref('Preedit_set_henkan_phase', s:SID_PREFIX),
\   'get_phase_name': eskk#util#get_local_funcref('Preedit_get_phase_name', s:SID_PREFIX),
\   'get_lower_phases': eskk#util#get_local_funcref('Preedit_get_lower_phases', s:SID_PREFIX),
\   'get_all_phases': eskk#util#get_local_funcref('Preedit_get_all_phases', s:SID_PREFIX),
\   'get_marker': eskk#util#get_local_funcref('Preedit_get_marker', s:SID_PREFIX),
\   'get_current_marker': eskk#util#get_local_funcref('Preedit_get_current_marker', s:SID_PREFIX),
\   'push_kakutei_str': eskk#util#get_local_funcref('Preedit_push_kakutei_str', s:SID_PREFIX),
\   'choose_next_candidate': eskk#util#get_local_funcref('Preedit_choose_next_candidate', s:SID_PREFIX),
\   'choose_prev_candidate': eskk#util#get_local_funcref('Preedit_choose_prev_candidate', s:SID_PREFIX),
\   'step_back_henkan_phase': eskk#util#get_local_funcref('Preedit_step_back_henkan_phase', s:SID_PREFIX),
\   'convert_rom_str_inplace': eskk#util#get_local_funcref('Preedit_convert_rom_str_inplace', s:SID_PREFIX),
\   'convert_rom_all_inplace': eskk#util#get_local_funcref('Preedit_convert_rom_all_inplace', s:SID_PREFIX),
\   'convert_rom_all': eskk#util#get_local_funcref('Preedit_convert_rom_all', s:SID_PREFIX),
\   'kakutei': eskk#util#get_local_funcref('Preedit_kakutei', s:SID_PREFIX),
\   'clear_all': eskk#util#get_local_funcref('Preedit_clear_all', s:SID_PREFIX),
\   'remove_display_str': eskk#util#get_local_funcref('Preedit_remove_display_str', s:SID_PREFIX),
\   'generate_kakutei_str': eskk#util#get_local_funcref('Preedit_generate_kakutei_str', s:SID_PREFIX),
\   'empty': eskk#util#get_local_funcref('Preedit_empty', s:SID_PREFIX),
\   'empty_filter_queue': eskk#util#get_local_funcref('Preedit_empty_filter_queue', s:SID_PREFIX),
\   'push_filter_queue': eskk#util#get_local_funcref('Preedit_push_filter_queue', s:SID_PREFIX),
\   'shift_filter_queue': eskk#util#get_local_funcref('Preedit_shift_filter_queue', s:SID_PREFIX),
\   'push_filter_pre_char': eskk#util#get_local_funcref('Preedit_push_filter_pre_char', s:SID_PREFIX),
\   'push_filter_post_char': eskk#util#get_local_funcref('Preedit_push_filter_post_char', s:SID_PREFIX),
\   'get_begin_col': eskk#util#get_local_funcref('Preedit_get_begin_col', s:SID_PREFIX),
\   'set_begin_col': eskk#util#get_local_funcref('Preedit_set_begin_col', s:SID_PREFIX),
\   'dump': eskk#util#get_local_funcref('Preedit_dump', s:SID_PREFIX),
\}

" }}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

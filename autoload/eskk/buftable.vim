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
let s:VICE_OPTIONS = {'generate_stub': 1, 'auto_clone_method': 1}
" s:BufferString {{{
let s:BufferString = vice#class('BufferString', s:SID_PREFIX, s:VICE_OPTIONS)


let s:RomStr = vice#class('RomStr', s:SID_PREFIX, s:VICE_OPTIONS)
call s:RomStr.property('_str', '')
function! {s:RomStr.method('get')}(this) "{{{
    return a:this._str.get()
endfunction "}}}
function! {s:RomStr.method('set')}(this, str) "{{{
    return a:this._str.set(a:str)
endfunction "}}}
function! {s:RomStr.method('append')}(this, str) "{{{
    return a:this._str.set(a:this._str.get() . a:str)
endfunction "}}}
function! {s:RomStr.method('chop')}(this) "{{{
    let s = a:this._str.get()
    return a:this._str.set(strpart(s, 0, strlen(s) - 1))
endfunction "}}}
function! {s:RomStr.method('clear')}(this) "{{{
    return a:this._str.set('')
endfunction "}}}
function! {s:RomStr.method('empty')}(this) "{{{
    return a:this._str.get() ==# ''
endfunction "}}}

call s:BufferString.attribute('rom_str', s:RomStr.new())
unlet s:RomStr


let s:RomPairs = vice#class('RomPairs', s:SID_PREFIX, s:VICE_OPTIONS)
call s:RomPairs.property('_pairs', [])
function! {s:RomPairs.method('get')}(this) "{{{
    return a:this._pairs.get()
endfunction "}}}
function! {s:RomPairs.method('get_rom')}(this) "{{{
    return join(map(copy(a:this._pairs.get()), 'v:val[0]'), '')
endfunction "}}}
function! {s:RomPairs.method('get_filter')}(this) "{{{
    return join(map(copy(a:this._pairs.get()), 'v:val[1]'), '')
endfunction "}}}
function! {s:RomPairs.method('set')}(this, list_pairs) "{{{
    return a:this._pairs.set(a:list_pairs)
endfunction "}}}
function! {s:RomPairs.method('set_one_pair')}(this, rom_str, filter_str) "{{{
    let pair = [a:rom_str, a:filter_str]
    return a:this._pairs.set([pair])
endfunction "}}}
function! {s:RomPairs.method('push_one_pair')}(this, rom_str, filter_str) "{{{
    let pair = [a:rom_str, a:filter_str]
    return a:this._pairs.set(a:this._pairs.get() + [pair])
endfunction "}}}
function! {s:RomPairs.method('pop')}(this) "{{{
    let p = a:this._pairs.get()
    if empty(p)
        return []
    else
        let r = remove(p, -1)
        call a:this._pairs.set(p)
        return r
    endif
endfunction "}}}
function! {s:RomPairs.method('clear')}(this) "{{{
    call a:this._pairs.set([])
endfunction "}}}
function! {s:RomPairs.method('empty')}(this) "{{{
    return empty(a:this._pairs.get())
endfunction "}}}

call s:BufferString.attribute('rom_pairs', s:RomPairs.new())
unlet s:RomPairs


function! {s:BufferString.method('get_input_rom')}(this) "{{{
    return a:this.rom_pairs.get_rom() . a:this.rom_str.get()
endfunction "}}}

function! {s:BufferString.method('empty')}(this) "{{{
    return a:this.rom_str.empty()
    \   && a:this.rom_pairs.empty()
endfunction "}}}

function! {s:BufferString.method('clear')}(this) "{{{
    call a:this.rom_str.clear()
    call a:this.rom_pairs.clear()
endfunction "}}}

" for memory, store object instead of object factory (class).
let s:BufferString = s:BufferString.new()
" }}}
" s:Buftable {{{
let s:Buftable = vice#class('Buftable', s:SID_PREFIX, s:VICE_OPTIONS)

call s:Buftable.attribute(
\   '_table',
\   [
\       s:BufferString.clone(),
\       s:BufferString.clone(),
\       s:BufferString.clone(),
\       s:BufferString.clone(),
\       s:BufferString.clone(),
\   ]
\)
call s:Buftable.attribute(
\   '_kakutei_str',
\   ''
\)
call s:Buftable.attribute(
\   '_old_str',
\   ''
\)
call s:Buftable.attribute(
\   '_begin_pos',
\   []
\)
call s:Buftable.attribute(
\   '_henkan_phase',
\   g:eskk#buftable#PHASE_NORMAL
\)
call s:Buftable.attribute(
\   '_set_begin_pos_at_rewrite',
\   0
\)


function! eskk#buftable#new() "{{{
    return s:Buftable.clone()
endfunction "}}}

function! {s:Buftable.method('reset')}(this) "{{{
    let obj = s:Buftable.clone()
    for k in keys(obj)
        let a:this[k] = obj[k]
    endfor
endfunction "}}}

function! {s:Buftable.method('get_buf_str')}(this, henkan_phase) "{{{
    call s:validate_table_idx(a:this._table, a:henkan_phase)
    return a:this._table[a:henkan_phase]
endfunction "}}}
function! {s:Buftable.method('get_current_buf_str')}(this) "{{{
    return a:this.get_buf_str(a:this._henkan_phase)
endfunction "}}}
function! {s:Buftable.method('set_buf_str')}(this, henkan_phase, buf_str) "{{{
    call s:validate_table_idx(a:this._table, a:henkan_phase)
    let a:this._table[a:henkan_phase] = a:buf_str
endfunction "}}}


function! {s:Buftable.method('set_old_str')}(this, str) "{{{
    let a:this._old_str = a:str
endfunction "}}}
function! {s:Buftable.method('get_old_str')}(this) "{{{
    return a:this._old_str
endfunction "}}}

" Rewrite old string, Insert new string.
"
" FIXME
" - Current implementation depends on &backspace
" when inserted string has newline.
"
" TODO Rewrite mininum string as possible
" when old or new string become too long.
function! {s:Buftable.method('rewrite')}(this) "{{{
    let [old, new] = [a:this._old_str, a:this.get_display_str()]

    let kakutei = a:this._kakutei_str
    let a:this._kakutei_str = ''

    let set_begin_pos =
    \   a:this._set_begin_pos_at_rewrite
    \   && a:this._henkan_phase ==# g:eskk#buftable#PHASE_HENKAN
    let a:this._set_begin_pos_at_rewrite = 0

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
        \   a:this.make_remove_bs()
        \   . (kakutei != '' ? "\<Plug>(eskk:expr:_inserted_kakutei)" : '')
        \   . "\<Plug>(eskk:_set_begin_pos)"
        \   . (new != '' ? "\<Plug>(eskk:expr:_inserted_new)" : '')
    else
        let inserted_str = kakutei . new
        if old ==# inserted_str
            return ''
        elseif inserted_str == ''
            return a:this.make_remove_bs()
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
            return a:this.make_remove_bs() . "\<Plug>(eskk:expr:_inserted)"
        endif
    endif
endfunction "}}}
function! {s:Buftable.method('make_remove_bs')}(this) "{{{
    return repeat(
    \   eskk#map#key2char(eskk#map#get_special_map("backspace-key")),
    \   eskk#util#mb_strlen(a:this._old_str),
    \)
endfunction "}}}

function! {s:Buftable.method('has_changed')}(this) "{{{
    let kakutei = a:this._kakutei_str
    if kakutei != ''
        return 1
    endif

    let [old, new] = [a:this._old_str, a:this.get_display_str()]
    let inserted_str = kakutei . new
    if old !=# inserted_str
        return 1
    endif

    return 0
endfunction "}}}

function! {s:Buftable.method('get_display_str')}(this, ...) "{{{
    let with_marker  = get(a:000, 0, 1)
    let with_rom_str = get(a:000, 1, 1)
    let phase = a:this._henkan_phase

    if phase ==# g:eskk#buftable#PHASE_NORMAL
        return s:get_normal_display_str(a:this, with_rom_str)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        return s:get_henkan_display_str(a:this, with_marker, with_rom_str)
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        return s:get_okuri_display_str(a:this, with_marker, with_rom_str)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        return s:get_henkan_select_display_str(a:this, with_marker, with_rom_str)
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


" self._henkan_phase
function! {s:Buftable.method('get_henkan_phase')}(this) "{{{
    return a:this._henkan_phase
endfunction "}}}
function! {s:Buftable.method('set_henkan_phase')}(this, henkan_phase) "{{{
    if a:henkan_phase ==# a:this._henkan_phase
        return
    endif

    call s:validate_table_idx(a:this._table, a:henkan_phase)

    call eskk#throw_event(
    \   'leave-phase-' . a:this.get_phase_name(a:this._henkan_phase)
    \)
    let a:this._henkan_phase = a:henkan_phase
    call eskk#throw_event(
    \   'enter-phase-' . a:this.get_phase_name(a:this._henkan_phase)
    \)
endfunction "}}}


function! {s:Buftable.method('get_phase_name')}(this, phase) "{{{
    return [
    \   'normal',
    \   'henkan',
    \   'okuri',
    \   'henkan-select',
    \   'jisyo-touroku',
    \][a:phase]
endfunction "}}}


function! {s:Buftable.method('get_lower_phases')}(this) "{{{
    return reverse(range(
    \   g:eskk#buftable#PHASE_NORMAL,
    \   a:this._henkan_phase
    \))
endfunction "}}}
function! {s:Buftable.method('get_all_phases')}(this) "{{{
    return range(
    \   g:eskk#buftable#PHASE_NORMAL,
    \   g:eskk#buftable#PHASE_HENKAN_SELECT
    \)
endfunction "}}}


function! {s:Buftable.method('get_marker')}(this, henkan_phase) "{{{
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
function! {s:Buftable.method('get_current_marker')}(this) "{{{
    return a:this.get_marker(a:this.get_henkan_phase())
endfunction "}}}


function! {s:Buftable.method('push_kakutei_str')}(this, str) "{{{
    let a:this._kakutei_str .= a:str
endfunction "}}}

function! {s:Buftable.method('do_enter')}(this, stash) "{{{
    let phase = a:this.get_henkan_phase()
    let enter_char =
    \   eskk#map#key2char(eskk#map#get_special_map('enter-key'))
    let undo_char  =
    \   eskk#map#key2char(eskk#map#key2char(eskk#map#get_nore_map('<C-g>u')))
    let dict = eskk#get_skk_dict()
    let henkan_result = dict.get_henkan_result()

    if phase ==# g:eskk#buftable#PHASE_NORMAL
        call a:this.convert_rom_str_inplace(phase)
        call eskk#register_temp_event(
        \   'filter-redispatch-post',
        \   'eskk#util#identity',
        \   [enter_char]
        \)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        call a:this.convert_rom_str_inplace(phase)
        if get(g:eskk#set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [undo_char]
            \)
        endif

        call a:this.push_kakutei_str(a:this.get_display_str(0))
        call a:this.clear_all()

        if !empty(henkan_result)
            call henkan_result.update_candidate()
        endif

        call a:this.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        call a:this.convert_rom_str_inplace(
        \   [g:eskk#buftable#PHASE_HENKAN, phase]
        \)
        if get(g:eskk#set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [undo_char]
            \)
        endif

        call a:this.push_kakutei_str(a:this.get_display_str(0))
        call a:this.clear_all()

        if !empty(henkan_result)
            call henkan_result.update_candidate()
        endif

        call a:this.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        call a:this.convert_rom_str_inplace(phase)
        if get(g:eskk#set_undo_point, 'kakutei', 0) && mode() ==# 'i'
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [undo_char]
            \)
        endif

        if !empty(henkan_result)
            call henkan_result.update_candidate()
        endif

        call a:this.push_kakutei_str(a:this.get_display_str(0))
        call a:this.clear_all()

        call a:this.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! {s:Buftable.method('do_backspace')}(this, stash) "{{{
    if a:this.get_old_str() == ''
        let a:stash.return = eskk#map#key2char(
        \   eskk#map#get_special_key('backspace-key')
        \)
        return
    endif

    let phase = a:this.get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        if g:eskk#delete_implies_kakutei
            " Enter normal phase and delete one character.
            let filter_str = eskk#util#mb_chop(a:this.get_display_str(0))
            call a:this.push_kakutei_str(filter_str)
            let henkan_select_buf_str = a:this.get_buf_str(
            \   g:eskk#buftable#PHASE_HENKAN_SELECT
            \)
            call henkan_select_buf_str.clear()

            call a:this.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
            return
        else
            " Leave henkan select or back to previous candidate if it exists.
            call a:this.choose_prev_candidate(a:stash)
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
            let filter_str = eskk#util#mb_chop(a:this.get_display_str(0))
            call a:this.push_kakutei_str(filter_str)
            let henkan_select_buf_str = a:this.get_buf_str(
            \   g:eskk#buftable#PHASE_HENKAN_SELECT
            \)
            call henkan_select_buf_str.clear()

            call a:this.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
            return
        else
            let filter_str = join(map(copy(p), 'v:val[1]'), '')
            let buf_str = a:this.get_buf_str(
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
    for phase in a:this.get_lower_phases()
        let buf_str = a:this.get_buf_str(phase)
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
        elseif a:this.get_marker(phase) != ''
            if !a:this.step_back_henkan_phase()
                let msg = "Normal phase's marker is empty, "
                \       . "and other phases *should* be able to change "
                \       . "current henkan phase."
                throw eskk#internal_error(['eskk', 'buftable'], msg)
            endif
            break
        endif
    endfor
endfunction "}}}
function! {s:Buftable.method('choose_next_candidate')}(this, stash) "{{{
    return s:get_next_candidate(a:this, a:stash, 1)
endfunction "}}}
function! {s:Buftable.method('choose_prev_candidate')}(this, stash) "{{{
    return s:get_next_candidate(a:this, a:stash, 0)
endfunction "}}}
function! s:get_next_candidate(this, stash, next) "{{{
    let cur_buf_str = a:this.get_current_buf_str()
    let dict = eskk#get_skk_dict()
    let henkan_result = dict.get_henkan_result()
    let prev_buftable = henkan_result.buftable
    let rom_str = cur_buf_str.rom_pairs.get_rom()

    call eskk#error#assert(
    \   a:this.get_henkan_phase()
    \       ==# g:eskk#buftable#PHASE_HENKAN_SELECT,
    \   "current phase is henkan select phase."
    \)

    if henkan_result[a:next ? 'forward' : 'back']()
        let candidate = henkan_result.get_candidate()

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
                call a:this.clear_all()
                call a:this.push_kakutei_str(input . okuri)
                call a:this.set_henkan_phase(
                \   g:eskk#buftable#PHASE_NORMAL
                \)
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
function! {s:Buftable.method('do_sticky')}(this, stash) "{{{
    let phase   = a:this.get_henkan_phase()
    let buf_str = a:this.get_current_buf_str()

    " Convert rom_str if possible.
    call a:this.convert_rom_str_inplace([
    \   g:eskk#buftable#PHASE_HENKAN,
    \   g:eskk#buftable#PHASE_OKURI
    \])

    if phase ==# g:eskk#buftable#PHASE_NORMAL
        if !buf_str.rom_str.empty()
        \   || !buf_str.rom_pairs.empty()
            call a:this.convert_rom_str_inplace(phase)
            call a:this.push_kakutei_str(a:this.get_display_str(0))
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
        let a:this._set_begin_pos_at_rewrite = 1
        call a:this.set_henkan_phase(g:eskk#buftable#PHASE_HENKAN)
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        if !buf_str.rom_str.empty()
        \   || !buf_str.rom_pairs.empty()
            call a:this.set_henkan_phase(g:eskk#buftable#PHASE_OKURI)
        endif
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        " nop
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        call a:this.do_enter(a:stash)
        call a:this.do_sticky(a:stash)
    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! {s:Buftable.method('step_back_henkan_phase')}(this) "{{{
    let phase   = a:this.get_henkan_phase()
    let buf_str = a:this.get_current_buf_str()

    if phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        call buf_str.clear()
        let okuri_buf_str = a:this.get_buf_str(
        \   g:eskk#buftable#PHASE_OKURI
        \)
        call a:this.set_henkan_phase(
        \   !empty(okuri_buf_str.rom_pairs.get()) ?
        \       g:eskk#buftable#PHASE_OKURI
        \       : g:eskk#buftable#PHASE_HENKAN
        \)
        return 1
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        call buf_str.clear()
        call a:this.set_henkan_phase(g:eskk#buftable#PHASE_HENKAN)
        return 1    " stepped.
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        call buf_str.clear()
        call a:this.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)
        return 1    " stepped.
    elseif phase ==# g:eskk#buftable#PHASE_NORMAL
        return 0    " failed.
    else
        throw eskk#internal_error(['eskk', 'buftable'])
    endif
endfunction "}}}
function! {s:Buftable.method('do_henkan')}(this, stash, ...) "{{{
    let convert_at_exact_match = a:0 ? a:1 : 0
    let phase = a:this.get_henkan_phase()

    if a:this.get_current_buf_str().empty()
        return
    endif

    if index(
    \   [g:eskk#buftable#PHASE_HENKAN,
    \       g:eskk#buftable#PHASE_OKURI],
    \   phase,
    \) ==# -1
        " TODO Add an error id like Vim
        call eskk#util#warnf(
        \   "s:buftable.do_henkan() does not support phase %d.",
        \   phase
        \)
        return
    endif

    if eskk#get_mode() ==# 'abbrev'
        call a:this.do_henkan_abbrev(a:stash, convert_at_exact_match)
    else
        call a:this.do_henkan_other(a:stash, convert_at_exact_match)
    endif
endfunction "}}}
function! {s:Buftable.method('do_henkan_abbrev')}(this, stash, convert_at_exact_match) "{{{
    let henkan_buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN
    \)
    let henkan_select_buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN_SELECT
    \)

    let rom_str = henkan_buf_str.rom_str.get()
    let dict = eskk#get_skk_dict()
    call dict.refer(a:this, rom_str, '', '')

    try
        let candidate = dict.get_henkan_result().get_candidate()
        " No thrown exception. continue...

        call a:this.clear_all()
        if a:convert_at_exact_match
            call henkan_buf_str.rom_pairs.set_one_pair(rom_str, candidate)
        else
            call henkan_select_buf_str.rom_pairs.set_one_pair(rom_str, candidate)
            call a:this.set_henkan_phase(
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
            call a:this.clear_all()
            call a:this.push_kakutei_str(input . okuri)
            call a:this.set_henkan_phase(
            \   g:eskk#buftable#PHASE_NORMAL
            \)
        endif
    endtry
endfunction "}}}
function! {s:Buftable.method('do_henkan_other')}(this, stash, convert_at_exact_match) "{{{
    let phase = a:this.get_henkan_phase()
    let henkan_buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN
    \)
    let okuri_buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_OKURI
    \)
    let henkan_select_buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN_SELECT
    \)

    if g:eskk#kata_convert_to_hira_at_henkan
    \   && eskk#get_mode() ==# 'kata'
        call a:this.convert_rom_pairs_inplace(
        \   [
        \       g:eskk#buftable#PHASE_HENKAN,
        \       g:eskk#buftable#PHASE_OKURI,
        \   ],
        \   eskk#get_mode_table('hira')
        \)
    endif

    " Convert rom_str if possible.
    call a:this.convert_rom_str_inplace([
    \   g:eskk#buftable#PHASE_HENKAN,
    \   g:eskk#buftable#PHASE_OKURI
    \])

    if g:eskk#fix_extra_okuri
    \   && !henkan_buf_str.rom_str.empty()
    \   && phase ==# g:eskk#buftable#PHASE_HENKAN
        call okuri_buf_str.rom_str.set(henkan_buf_str.rom_str.get())
        call henkan_buf_str.rom_str.clear()
        call a:this.set_henkan_phase(g:eskk#buftable#PHASE_OKURI)
        return
    endif

    let hira = henkan_buf_str.rom_pairs.get_filter()
    let okuri = okuri_buf_str.rom_pairs.get_filter()
    let okuri_rom = okuri_buf_str.rom_pairs.get_rom()
    let dict = eskk#get_skk_dict()
    call dict.refer(a:this, hira, okuri, okuri_rom)

    " Clear phase henkan/okuri buffer string.
    " NOTE: I assume that `dict.refer()`
    " saves necessary strings even if I clear these.
    let henkan_matched_rom = henkan_buf_str.rom_pairs.get_rom()
    let okuri_matched_rom = okuri_buf_str.rom_pairs.get_rom()
    let rom_str = henkan_matched_rom . okuri_matched_rom
    try
        " .get_candidate() may throw dictionary look up exception.
        let hr = dict.get_henkan_result()
        let candidate = hr.get_candidate()

        call a:this.clear_all()
        if a:convert_at_exact_match
            call henkan_buf_str.rom_pairs.set_one_pair(rom_str, candidate)
        else
            call henkan_select_buf_str.rom_pairs.set_one_pair(rom_str, candidate)
            call a:this.set_henkan_phase(
            \   g:eskk#buftable#PHASE_HENKAN_SELECT
            \)
            if g:eskk#kakutei_when_unique_candidate && !hr.has_next()
                call a:this.push_kakutei_str(
                \   a:this.get_display_str(0)
                \)
                call a:this.clear_all()
                call a:this.set_henkan_phase(
                \   g:eskk#buftable#PHASE_NORMAL
                \)
            endif
        endif
    catch /^eskk: dictionary look up error/
        " No candidates.
        let [input, hira, okuri] =
        \   dict.remember_word_prompt(
        \      dict.get_henkan_result()
        \   )
        if input != ''
            call a:this.clear_all()
            call a:this.push_kakutei_str(input . okuri)
            call a:this.set_henkan_phase(
            \   g:eskk#buftable#PHASE_NORMAL
            \)
        endif
    endtry
endfunction "}}}
function! {s:Buftable.method('do_ctrl_q_key')}(this) "{{{
    return s:convert_again_with_table(
    \   a:this,
    \   (eskk#get_mode() ==# 'hira' ?
    \       eskk#get_mode_table('hankata') :
    \       eskk#get_mode_table('hira'))
    \)
endfunction "}}}
function! {s:Buftable.method('do_q_key')}(this) "{{{
    return s:convert_again_with_table(
    \   a:this,
    \   (eskk#get_mode() ==# 'hira' ?
    \       eskk#get_mode_table('kata') :
    \       eskk#get_mode_table('hira'))
    \)
endfunction "}}}
function! {s:Buftable.method('do_l_key')}(this) "{{{
    return s:convert_again_with_table(a:this, {})
endfunction "}}}
function! {s:Buftable.method('do_escape')}(this, stash) "{{{
    call a:this.convert_rom_str_inplace(
    \   a:this.get_henkan_phase()
    \)

    let kakutei_str = a:this.generate_kakutei_str()
    " NOTE: This function return value is not remapped.
    let esc = eskk#map#get_special_key('escape-key')
    call eskk#error#assert(esc != '', 'esc must not be empty string')
    let a:stash.return = kakutei_str . eskk#map#key2char(esc)
endfunction "}}}
function! {s:Buftable.method('do_tab')}(this, stash) "{{{
    let buf_str = a:this.get_current_buf_str()
    call buf_str.rom_str.append(s:get_tab_raw_str())
endfunction "}}}
function! s:get_tab_raw_str() "{{{
    return &l:expandtab ? repeat(' ', &tabstop) : "\<Tab>"
endfunction "}}}

function! {s:Buftable.method('convert_rom_str_inplace')}(this, phases, ...) "{{{
    let table = a:0 ? a:1 : s:get_current_table()
    let phases = type(a:phases) == type([]) ?
    \               a:phases : [a:phases]
    for buf_str in map(phases, 'a:this.get_buf_str(v:val)')
        let rom_str = buf_str.rom_str.get()
        if table.has_map(rom_str)
            call buf_str.rom_pairs.push_one_pair(
            \   rom_str,
            \   table.get_map(rom_str)
            \)
            call buf_str.rom_str.clear()
        endif
    endfor
endfunction "}}}
function! {s:Buftable.method('convert_rom_pairs_inplace')}(this, phases, ...) "{{{
    let table = a:0 ? a:1 : s:get_current_table()
    let phases = type(a:phases) == type([]) ?
    \               a:phases : [a:phases]
    for p in phases
        let buf_str = a:this.convert_rom_pairs(p, table)
        call a:this.set_buf_str(p, buf_str)
    endfor
endfunction "}}}
function! {s:Buftable.method('convert_rom_pairs')}(this, phases, ...) "{{{
    let table = a:0 ? a:1 : s:get_current_table()
    let phases = type(a:phases) == type([]) ?
    \               a:phases : [a:phases]
    let r = []
    for p in phases
        let buf_str = deepcopy(a:this.get_buf_str(p), 1)
        let matched = buf_str.rom_pairs.get()
        call buf_str.rom_pairs.clear()
        for [rom_str, filter_str] in matched
            call buf_str.rom_pairs.push_one_pair(
            \   rom_str,
            \   table.get_map(rom_str, rom_str)
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
function! s:convert_again_with_table(this, table) "{{{
    " Convert rom_str if possible.
    call a:this.convert_rom_str_inplace([
    \   g:eskk#buftable#PHASE_HENKAN,
    \   g:eskk#buftable#PHASE_OKURI
    \])

    let cur_buf_str = a:this.get_current_buf_str()

    let normal_buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_NORMAL
    \)
    let henkan_buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_HENKAN
    \)
    let okuri_buf_str = a:this.get_buf_str(
    \   g:eskk#buftable#PHASE_OKURI
    \)

    for cur_buf_str in [henkan_buf_str, okuri_buf_str]
        for m in cur_buf_str.rom_pairs.get()
            call normal_buf_str.rom_pairs.push_one_pair(
            \   m[0],
            \   (empty(a:table) ?
            \       m[0] : a:table.get_map(m[0], m[1]))
            \)
        endfor
    endfor

    call henkan_buf_str.clear()
    call okuri_buf_str.clear()

    call a:this.set_henkan_phase(g:eskk#buftable#PHASE_NORMAL)

    function! s:finalize()
        let a:this = eskk#get_buftable()
        if a:this.get_henkan_phase() ==# g:eskk#buftable#PHASE_NORMAL
            let cur_buf_str = a:this.get_current_buf_str()
            call cur_buf_str.rom_pairs.clear()
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

function! {s:Buftable.method('clear_all')}(this) "{{{
    for phase in a:this.get_all_phases()
        let buf_str = a:this.get_buf_str(phase)
        call buf_str.clear()
    endfor
endfunction "}}}

function! {s:Buftable.method('remove_display_str')}(this) "{{{
    let current_str = a:this.get_display_str()

    " NOTE: This function return value is not remapped.
    let bs = eskk#map#get_special_key('backspace-key')
    call eskk#error#assert(bs != '', 'bs must not be empty string')

    return repeat(
    \   eskk#map#key2char(bs),
    \   eskk#util#mb_strlen(current_str)
    \)
endfunction "}}}
function! {s:Buftable.method('generate_kakutei_str')}(this) "{{{
    return a:this.remove_display_str() . a:this.get_display_str(0)
endfunction "}}}

function! {s:Buftable.method('get_begin_pos')}(this) "{{{
    return a:this._begin_pos
endfunction "}}}
function! {s:Buftable.method('set_begin_pos')}(this, expr) "{{{
    if mode() ==# 'i'
        let a:this._begin_pos = ['i', getpos(a:expr)]
    elseif mode() ==# 'c'
        let a:this._begin_pos = ['c', getcmdpos()]
    else
        call eskk#error#logf("called eskk from mode '%s'.", mode())
    endif
endfunction "}}}


function! {s:Buftable.method('empty')}(this) "{{{
    for buf_str in map(
    \   a:this.get_all_phases(),
    \   'a:this.get_buf_str(v:val)'
    \)
        if !buf_str.empty()
            return 0
        endif
    endfor
    return 1
endfunction "}}}


function! {s:Buftable.method('dump')}(this) "{{{
    let lines = []
    call add(lines, 'current phase: ' . a:this._henkan_phase)
    call add(lines, 'begin pos: ' . string(a:this.get_begin_pos()))
    for phase in a:this.get_all_phases()
        let buf_str = a:this.get_buf_str(phase)
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
    return eskk#error#build_error(
    \   ["eskk", "buftable"],
    \   ["invalid henkan phase value '" . a:henkan_phase . "'"]
    \)
endfunction "}}}

" for memory, store object instead of object factory (class).
let s:Buftable = s:Buftable.new()
" }}}

" :unlet for memory.
" Those classes' methods/properties are copied already.
unlet s:BufferString
" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

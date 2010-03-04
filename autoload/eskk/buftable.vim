" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" For global variables.
runtime! plugin/eskk.vim

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
" Choosing henkan candidates.
let eskk#buftable#HENKAN_PHASE_JISYO_TOUROKU = 4
lockvar eskk#buftable#HENKAN_PHASE_JISYO_TOUROKU

let s:BS = "\<BS>"
lockvar s:BS
" }}}

" Functions {{{
" s:buffer_string {{{
let s:buffer_string = {'_pos': [], '_rom_str': '', '_filter_str': ''}

func! s:buffer_string_new() "{{{
    return deepcopy(s:buffer_string)
endfunc "}}}


func! s:buffer_string.reset() dict "{{{
    for k in keys(s:buftable)
        if has_key(self, k)
            let self[k] = deepcopy(s:buftable[k])
        endif
    endfor
endfunc "}}}

func! s:buffer_string.set_pos(expr) dict "{{{
    let self._pos = getpos(a:expr)
endfunc "}}}
func! s:buffer_string.get_pos() dict "{{{
    return self._pos
endfunc "}}}


func! s:buffer_string.get_rom_str() dict "{{{
    return self._rom_str
endfunc "}}}
func! s:buffer_string.set_rom_str(str) dict "{{{
    let self._rom_str = a:str
endfunc "}}}
func! s:buffer_string.push_rom_str(str) dict "{{{
    call self.set_rom_str(self.get_rom_str() . a:str)
endfunc "}}}
func! s:buffer_string.pop_rom_str() dict "{{{
    let s = self.get_rom_str()
    call self.set_rom_str(strpart(s, 0, strlen(s) - 1))
endfunc "}}}
func! s:buffer_string.clear_rom_str() dict "{{{
    let self._rom_str = ''
endfunc "}}}


func! s:buffer_string.get_filter_str() dict "{{{
    return self._filter_str
endfunc "}}}
func! s:buffer_string.set_filter_str(str) dict "{{{
    let self._filter_str = a:str
endfunc "}}}
func! s:buffer_string.push_filter_str(str) dict "{{{
    call self.set_filter_str(self.get_filter_str() . a:str)
endfunc "}}}
func! s:buffer_string.pop_filter_str() dict "{{{
    let s = self.get_filter_str()
    call self.set_filter_str(eskk#util#mb_chop(s))
endfunc "}}}
func! s:buffer_string.clear_filter_str() dict "{{{
    let self._filter_str = ''
endfunc "}}}


func! s:buffer_string.empty() dict "{{{
    return self._rom_str == '' && self._filter_str == ''
endfunc "}}}

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
\   '_old_str': '',
\   '_henkan_phase': g:eskk#buftable#HENKAN_PHASE_NORMAL,
\}

" FIXME
" - Current implementation depends on &backspace
" when inserted string has newline.


func! eskk#buftable#new() "{{{
    return deepcopy(s:buftable)
endfunc "}}}


func! s:buftable.reset() dict "{{{
    for k in keys(s:buftable)
        if has_key(self, k)
            let self[k] = deepcopy(s:buftable[k])
        endif
    endfor
endfunc "}}}

" This is called from dispatch function.
func! s:buftable.finalize() dict "{{{
    if self._henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        let buf_str = self.get_buf_str(g:eskk#buftable#HENKAN_PHASE_NORMAL)
        call buf_str.clear_filter_str()
    endif
endfunc "}}}


func! s:buftable.get_buf_str(henkan_phase) dict "{{{
    call s:validate_table_idx(self._table, a:henkan_phase, "eskk: buftable:")
    return self._table[a:henkan_phase]
endfunc "}}}
func! s:buftable.get_current_buf_str() dict "{{{
    return self.get_buf_str(self._henkan_phase)
endfunc "}}}


" Rewrite old string, Insert new string.
func! s:buftable.set_old_str(str) dict "{{{
    let self._old_str = a:str
endfunc "}}}
func! s:buftable.get_old_str() dict "{{{
    return self._old_str
endfunc "}}}
" Return inserted string.
" Inserted string contains "\<BS>"
" to delete old characters.
func! s:buftable.rewrite() dict "{{{
    " TODO Rewrite mininum string as possible.
    let bs = repeat(s:BS, eskk#util#mb_strlen(self._old_str))
    return bs . self.get_display_str()
endfunc "}}}
func! s:buftable.get_display_str() dict "{{{
    let ret = ''
    for phase in self.get_lower_phases()
        let buf_str = self.get_buf_str(phase)
        " 1. marker string
        " 2. filter string
        " 3. rom string
        let ret .= s:get_marker(phase)
        let ret .= buf_str.get_filter_str()
        let ret .= buf_str.get_rom_str()
    endfor
    return ret
endfunc "}}}


" self._henkan_phase
func! s:buftable.get_henkan_phase() dict "{{{
    return self._henkan_phase
endfunc "}}}
" TODO フィルタ関数実行中はいじれないようにする？
func! s:buftable.set_henkan_phase(henkan_phase) dict "{{{
    call s:validate_table_idx(self._table, a:henkan_phase, "eskk: buftable:")
    let self.henkan_phase = a:henkan_phase
endfunc "}}}
" TODO
" func! s:buftable.step_henkan_phase() dict "{{{
"     call self.set_henkan_phase(self._henkan_phase + 1)
" endfunc "}}}


func! s:buftable.get_lower_phases() dict "{{{
    return reverse(range(g:eskk#buftable#HENKAN_PHASE_NORMAL, self._henkan_phase))
endfunc "}}}
func! s:buftable.get_lower_buf_str() dict "{{{
    return map(self.get_lower_phases(), 'self.get_buf_str(v:val)')
endfunc "}}}
func! s:buftable.get_all_phases() dict "{{{
    return range(
    \   g:eskk#buftable#HENKAN_PHASE_NORMAL,
    \   g:eskk#buftable#HENKAN_PHASE_JISYO_TOUROKU
    \)
endfunc "}}}
func! s:buftable.get_all_buf_str() dict "{{{
    return self._table
endfunc "}}}


func! s:buftable.empty() dict "{{{
    for i in self._table
        if !i.empty()
            return 0
        endif
    endfor
    return 1
endfunc "}}}


func! s:validate_table_idx(table, henkan_phase, msg) "{{{
    if !eskk#util#has_idx(a:table, a:henkan_phase)
        throw eskk#error#out_of_idx("eskk: buftable:")
    endif
endfunc "}}}
func! s:get_marker(henkan_phase) "{{{
    let table = [
    \    '',
    \    g:eskk_marker_henkan,
    \    g:eskk_marker_okuri,
    \    g:eskk_marker_henkan_select,
    \    g:eskk_marker_jisyo_touroku,
    \]
    call s:validate_table_idx(table, a:henkan_phase, "eskk: buftable:")
    " if a:henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    "     throw ''
    " endif
    return table[a:henkan_phase]
endfunc "}}}


lockvar s:buftable
" }}}
" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

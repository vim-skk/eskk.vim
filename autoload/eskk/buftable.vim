" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

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
" }}}

" Functions {{{
" s:buffer_string {{{
let s:buffer_string = {'pos': [], 'rom_str': '', 'filtered_str': ''}

func! s:buffer_string_new() "{{{
    return deepcopy(s:buffer_string)
endfunc "}}}


func! s:buffer_string.set_expr_pos(expr) dict "{{{
    let self.pos = getpos(a:expr)
endfunc "}}}


func! s:buffer_string.get_rom_str() dict "{{{
    return self.rom_str
endfunc "}}}

func! s:buffer_string.set_rom_str(str) dict "{{{
    let self.rom_str = a:str
endfunc "}}}


func! s:buffer_string.get_filtered_str(str) dict "{{{
    return self.filtered_str
endfunc "}}}

func! s:buffer_string.set_filtered_str(str) dict "{{{
    let self.filtered_str = a:str
endfunc "}}}


lockvar s:buffer_string
" }}}
" s:buftable {{{
" 'table' and 'marker_table' should have same elems.
let s:buftable = {
\   'table': [
\       s:buffer_string_new(),
\       s:buffer_string_new(),
\       s:buffer_string_new(),
\       s:buffer_string_new(),
\       s:buffer_string_new(),
\   ],
\   'marker_table': [
\       '',
\       g:eskk_marker_henkan,
\       g:eskk_marker_okuri,
\       g:eskk_marker_henkan_select,
\       g:eskk_marker_jisyo_touroku,
\   ],
\   'henkan_phase': g:eskk#buftable#HENKAN_PHASE_NORMAL,
\}

func! eskk#buftable#new() "{{{
    return deepcopy(s:buftable)
endfunc "}}}


func! s:buftable.get_table(henkan_phase) dict "{{{
    call s:validate_henkan_phase(self.table, a:henkan_phase, "eskk: buftable:")
    return self.table[a:henkan_phase]
endfunc "}}}

func! s:buftable.get_current_table() dict "{{{
    return self.get_table(self.henkan_phase)
endfunc "}}}


func! s:buftable.get_marker_table(henkan_phase) dict "{{{
    call s:validate_henkan_phase(self.table, a:henkan_phase, "eskk: buftable:")
    return self.marker_table[a:henkan_phase]
endfunc "}}}

func! s:buftable.get_current_table() dict "{{{
    return self.get_marker_table(self.henkan_phase)
endfunc "}}}


func! s:buftable.set_henkan_phase(henkan_phase) dict "{{{
    call s:validate_henkan_phase(self.table, a:henkan_phase, "eskk: buftable:")
    let self.henkan_phase = a:henkan_phase
endfunc "}}}

func! s:buftable.step_henkan_phase() dict "{{{
    call self.set_henkan_phase(self.henkan_phase + 1)
endfunc "}}}


func! s:is_correct_henkan_phase(table, henkan_phase) "{{{
    return eskk#util#has_idx(a:table, a:henkan_phase)
endfunc "}}}

func! s:validate_henkan_phase(table, henkan_phase, msg) "{{{
    if !s:is_correct_henkan_phase(a:table, a:henkan_phase)
        throw eskk#error#out_of_idx("eskk: buftable:")
    endif
endfunc "}}}


lockvar s:buftable
" }}}
" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

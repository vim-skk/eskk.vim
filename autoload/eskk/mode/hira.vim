" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Variables {{{

let eskk#mode#hira#handle_all_keys = 0
let s:BS = "\<C-h>"

" }}}


" Functions {{{

" Filter functions

func! eskk#mode#hira#filter_main(char, from, henkan_phase, henkan_count) "{{{
    if a:henkan_phase ==# g:eskk#HENKAN_PHASE_NORMAL
        return s:filter_rom_to_hira(a:char, a:from, a:henkan_count)
    elseif a:henkan_phase ==# g:eskk#HENKAN_PHASE_OKURI
        " TODO
    elseif a:henkan_phase ==# g:eskk#HENKAN_PHASE_HENKAN
        " TODO
    endif
endfunc "}}}

func! s:filter_rom_to_hira(char, from, henkan_count) "{{{
    let orig_rom_str_buf = eskk#get_current_buf()
    let rom_str_buf = orig_rom_str_buf . a:char
    call eskk#set_current_buf(rom_str_buf)

    let def = g:eskk#table#rom_to_hira#definition
    if has_key(def, rom_str_buf)
        let rest = get(def[rom_str_buf], 'rest', '')
        try
            let bs = repeat(s:BS, eskk#util#mb_strlen(orig_rom_str_buf))
            return bs . def[rom_str_buf].map_to . rest
        finally
            call eskk#set_current_buf(rest)
        endtry
    elseif eskk#table#has_candidates('rom_to_hira', orig_rom_str_buf)
        return a:char
    else
        call eskk#set_current_buf(
        \   strpart(
        \      orig_rom_str_buf,
        \      0,
        \      strlen(orig_rom_str_buf) - 1
        \   ) . a:char
        \)
        return s:BS . a:char
    endif
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

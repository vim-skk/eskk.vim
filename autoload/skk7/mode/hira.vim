" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Variables {{{

let skk7#mode#hira#handle_all_keys = 0
let s:BS = "\<C-h>"

" }}}


" Functions {{{

" Each mode must have 'load()' function
" to check if its mode exists.
func! skk7#mode#hira#load() "{{{
endfunc "}}}

" This function will be called from autoload/skk7.vim.
func! skk7#mode#hira#initialize() "{{{
endfunc "}}}

func! skk7#mode#hira#enable(again) "{{{
    if !a:again
        return skk7#dispatch_key('', skk7#from_mode('hira'))
    else
        call skk7#mode#hira#initialize()
        return ''
    endif
endfunc "}}}



" Callbacks

func! skk7#mode#hira#cb_im_enter() "{{{
    call skk7#mode#hira#initialize()
endfunc "}}}



" Filter functions

func! skk7#mode#hira#filter_main(char, from, henkan_phase, henkan_count) "{{{
    if a:henkan_phase ==# g:skk7#HENKAN_PHASE_NORMAL
        return s:filter_rom_to_hira(a:char, a:from, a:henkan_count)
    elseif a:henkan_phase ==# g:skk7#HENKAN_PHASE_OKURI
        " TODO
    elseif a:henkan_phase ==# g:skk7#HENKAN_PHASE_HENKAN
        " TODO
    endif
endfunc "}}}

func! s:filter_rom_to_hira(char, from, henkan_count) "{{{
    let orig_rom_str_buf = skk7#get_current_buf()
    let rom_str_buf = orig_rom_str_buf . a:char
    call skk7#set_current_buf(rom_str_buf)

    let def = skk7#table#rom_to_hira#get_definition()
    if has_key(def, rom_str_buf)
        let rest = get(def[rom_str_buf], 'rest', '')
        try
            let bs = repeat(s:BS, skk7#util#mb_strlen(orig_rom_str_buf))
            return bs . def[rom_str_buf].map_to . rest
        finally
            call skk7#set_current_buf(rest)
        endtry
    elseif skk7#table#has_candidates('rom_to_hira', orig_rom_str_buf)
        return a:char
    else
        call skk7#set_current_buf(
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

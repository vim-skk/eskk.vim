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

    " TODO Handle special keys registered in a:maptable.

    return s:filter_rom_to_hira(a:char, a:from, a:buftable, a:maptable)
endfunc "}}}

func! s:filter_rom_to_hira(char, from, buftable, maptable) "{{{
    let buf_str = a:buftable.get_current_buf_str()
    let rom_str = buf_str.get_rom_str()

    if eskk#table#has_map('rom_to_hira', rom_str)
        " Match!
        call eskk#util#log('match!')

        call buf_str.set_filtered_str(
        \   eskk#table#get_map('rom_to_hira', rom_str)
        \)
        call buf_str.flush_filtered_str()

        " Assumption: 'eskk#table#has_map(def, rest)' is false
        let rest = eskk#table#get_rest('rom_to_hira', rom_str, '')
        call buf_str.set_filtered_str(rest)

        return

    elseif eskk#table#has_candidates('rom_to_hira', rom_str)
        " Has candidates but not match.
        call eskk#util#log('wait for a next key.')
        call buf_str.set_filtered_str(rom_str)
        return

    else
        " No candidates.
        " Remove rom_str[-2].
        call eskk#util#log('no candidates.')
        call eskk#util#assert(
        \   strlen(rom_str) >= 2,
        \   "'rom_str' must have at least 2 characters"
        \)
        call buf_str.set_filtered_str(
        \   strpart(rom_str, 0, strlen(rom_str) - 2)
        \       . strpart(rom_str, strlen(rom_str) - 1)
        \)
        return
    endif
endfunc "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

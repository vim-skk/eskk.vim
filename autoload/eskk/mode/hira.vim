" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Mode options {{{
let eskk#mode#hira#handle_all_keys = 0
" }}}

" Functions {{{

" Callback
function! eskk#mode#hira#cb_handle_key(...) "{{{
    return 0
endfunction "}}}

" Filter functions
function! eskk#mode#hira#filter_main(stash) "{{{
    " TODO Handle special keys registered in a:maptable.

    let henkan_phase = a:stash.buftable.get_henkan_phase()
    if henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        return s:filter_rom_to_hira(a:stash)
    else
        return eskk#default_filter(a:stash)
    endif
endfunction "}}}
function! s:filter_rom_to_hira(stash) "{{{
    let char = a:stash.key_info.char
    let buf_str = a:stash.buftable.get_current_buf_str()
    let rom_str = buf_str.get_rom_str() . char

    if eskk#table#has_map('rom_to_hira', rom_str)
        " Match!
        call eskk#util#log('match!')

        call buf_str.set_filter_str(
        \   eskk#table#get_map_to('rom_to_hira', rom_str)
        \)
        call buf_str.clear_rom_str()

        " Assumption: 'eskk#table#has_map(def, rest)' returns false.
        let rest = eskk#table#get_rest('rom_to_hira', rom_str, -1)
        if rest !=# -1
            call add(a:stash.opt.redispatch_keys, rest)
        endif
        return

    elseif eskk#table#has_candidates('rom_to_hira', rom_str)
        " Has candidates but not match.
        call eskk#util#log('wait for a next key.')
        call buf_str.push_rom_str(char)
        return

    else
        " No candidates.
        " Remove rom_str[-2].
        call eskk#util#log('no candidates.')
        call buf_str.pop_rom_str()
        return
    endif
endfunction "}}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

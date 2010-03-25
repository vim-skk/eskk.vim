" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Variables {{{
let s:rom_to_hira = eskk#table#new('rom_to_hira')
" }}}

" Functions {{{

" :help <SID>
function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}

" Callback
function! eskk#mode#hira#cb_handle_key(...) "{{{
    return 0
endfunction "}}}

" Filter functions
function! eskk#mode#hira#filter(stash) "{{{
    " TODO Handle special keys registered in maptable.

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

    if s:rom_to_hira.has_map(rom_str)
        " Match!
        call eskk#util#logf('%s - match!', rom_str)

        " Set filtered string.
        call buf_str.set_filter_str(
        \   s:rom_to_hira.get_map_to(rom_str)
        \)
        call buf_str.clear_rom_str()

        " Set rest string.
        "
        " NOTE:
        " rest must not have multibyte string.
        " rest is for rom string.
        let rest = s:rom_to_hira.get_rest(rom_str, -1)
        " Assumption: 's:rom_to_hira.has_map(rest)' returns false here.
        if rest !=# -1
            call add(a:stash.option.redispatch_keys, rest)
        endif

        " Clear filtered string when eskk#filter_key()'s finalizing.
        let s:buftable = a:stash.buftable
        function! s:finalize()
            if s:buftable._henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
                let buf_str = s:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_NORMAL)
                call buf_str.clear_filter_str()
            endif
        endfunction

        call add(
        \   a:stash.option.finalize_fn,
        \   eskk#util#get_local_func('finalize', s:SID())
        \)

        return

    elseif s:rom_to_hira.has_candidates(rom_str)
        " Has candidates but not match.
        call eskk#util#logf('%s - wait for a next key.', rom_str)
        call buf_str.push_rom_str(char)
        return

    else
        " No candidates.
        " Remove rom_str[-2].
        call eskk#util#logf('%s - no candidates.', rom_str)
        call buf_str.pop_rom_str()
        return
    endif
endfunction "}}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

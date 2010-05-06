" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Variables {{{
let s:rom_to_hira = eskk#table#new('rom_to_hira')
let s:rom_to_kata = eskk#table#new('rom_to_kata')
let s:current_table = s:rom_to_hira

let s:skk_dict = eskk#dictionary#new([g:eskk_dictionary, g:eskk_large_dictionary])
let s:current_henkan_result = {}
" }}}

" Functions {{{

function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}

function! eskk#mode#hira#cb_handle_key(stash) "{{{
    return 0
endfunction "}}}

function! eskk#mode#hira#hook_fn_do_lmap_hira() "{{{
    lmap <buffer> q <Plug>(eskk:mode:hira:convert/switch-to-kata)
    lmap <buffer> l <Plug>(eskk:mode:hira:to-ascii)
    lmap <buffer> L <Plug>(eskk:mode:hira:to-zenei)
endfunction "}}}
function! eskk#mode#hira#hook_fn_do_lmap_kata() "{{{
    lmap <buffer> q <Plug>(eskk:mode:hira:convert/switch-to-kata)
    lmap <buffer> l <Plug>(eskk:mode:hira:to-ascii)
    lmap <buffer> L <Plug>(eskk:mode:hira:to-zenei)
endfunction "}}}
function! eskk#mode#hira#hook_fn_set_rom_to_hira_table() "{{{
    let s:current_table = s:rom_to_hira
endfunction "}}}
function! eskk#mode#hira#hook_fn_set_rom_to_kata_table() "{{{
    let s:current_table = s:rom_to_kata
endfunction "}}}

function! eskk#mode#hira#do_q_key(again, stash) "{{{
    if !a:again
        return eskk#call_via_filter('eskk#mode#hira#do_q_key', [1])
    else
        let buf_str = a:stash.buftable.get_current_buf_str()
        let phase = a:stash.buftable.get_henkan_phase()

        if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
            call buf_str.clear_rom_str()
            call buf_str.clear_filter_str()

            " Toggle current table.
            let s:current_table = (s:current_table is s:rom_to_hira ? s:rom_to_kata : s:rom_to_hira)
        else
        endif
    endif
endfunction "}}}

function! s:finalize() "{{{
    if eskk#get_buftable().get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        let buf_str = eskk#get_buftable().get_current_buf_str()
        call buf_str.clear_filter_str()
    endif
endfunction "}}}


function! eskk#mode#hira#filter(stash) "{{{
    let char = a:stash.char
    let henkan_phase = a:stash.buftable.get_henkan_phase()

    if henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        return s:filter_rom_to_hira(a:stash)
    elseif henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        if eskk#is_henkan_key(char)
            return s:henkan_key(a:stash)
            " Assert a:stash.buftable.get_henkan_phase() == g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        else
            return s:filter_rom_to_hira(a:stash)
        endif
    elseif henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        return s:filter_rom_to_hira(a:stash)
    elseif henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        if eskk#is_henkan_key(char)
            return s:henkan_key(a:stash)
        else
            " Leave phase henkan select
            " unless char is one of some specific characters.
            call a:stash.buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
            " Move henkan select buffer string to normal.
            call a:stash.buftable.move_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT, g:eskk#buftable#HENKAN_PHASE_NORMAL)

            return s:filter_rom_to_hira(a:stash)
        endif
    else
        return eskk#default_filter(a:stash)
    endif
endfunction "}}}

function s:henkan_key(stash) "{{{
    call eskk#util#log('henkan!')

    let phase = a:stash.buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \ || phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        " Enter henkan select phase.
        call a:stash.buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)

        let s:current_henkan_result = s:skk_dict.refer(a:stash.buftable)

        " Clear phase henkan/okuri buffer string.
        " Assumption: `s:skk_dict.refer()` saves necessary strings.
        let henkan_buf_str = a:stash.buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
        call henkan_buf_str.clear_rom_str()
        call henkan_buf_str.clear_filter_str()
        let okuri_buf_str = a:stash.buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
        call okuri_buf_str.clear_rom_str()
        call okuri_buf_str.clear_filter_str()

        let buf_str = a:stash.buftable.get_current_buf_str()
        let candidate = s:current_henkan_result.get_next()

        if type(candidate) == type("")
            " Set candidate.
            call buf_str.set_filter_str(candidate)
        else
            " No candidates.
            " TODO Jisyo touroku
            throw eskk#not_implemented_error(['eskk', 'mode', 'hira'], "jisyo touroku has not been implemented yet.")
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        let buf_str = a:stash.buftable.get_current_buf_str()
        let candidate = s:current_henkan_result.get_next()
        if type(candidate) == type("")
            " Set candidate.
            call buf_str.set_filter_str(candidate)
        else
            throw eskk#never_reached_error(['eskk', 'mode', 'hira'])
        endif
    else
        let msg = printf("s:henkan_key() does not support phase %d.", phase)
        throw eskk#internal_error(['eskk', 'mode', 'hira'], msg)
    endif
endfunction "}}}
function! s:filter_rom_to_hira(stash) "{{{
    let char = a:stash.char
    let buf_str = a:stash.buftable.get_current_buf_str()
    let rom_str = buf_str.get_rom_str() . char
    let phase = a:stash.buftable.get_henkan_phase()
    let buftable = a:stash.buftable

    call eskk#util#logf('mode hira - char = %s, rom_str = %s', string(char), string(rom_str))

    if s:current_table.has_map(rom_str)
        " Match!
        call eskk#util#logf('%s - match!', rom_str)

        if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        \   || phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
            " Set filtered string.
            call buf_str.push_filter_str(
            \   s:current_table.get_map_to(rom_str)
            \)
            call buf_str.clear_rom_str()

            " Set rest string.
            "
            " NOTE:
            " rest must not have multibyte string.
            " rest is for rom string.
            let rest = s:current_table.get_rest(rom_str, -1)
            " Assumption: 's:current_table.has_map(rest)' returns false here.
            if rest !=# -1
                let a:stash.option.redispatch_chars += split(rest, '\zs')
            endif

            " Clear filtered string when eskk#filter()'s finalizing.
            call add(
            \   a:stash.option.finalize_fn,
            \   eskk#util#get_local_func('finalize', s:SID())
            \)
        elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
            " Enter phase henkan select with henkan.

            " Input: "SesSi"
            " Convert from:
            "   henkan buf str:
            "     filter str: "せ"
            "     rom str   : "s"
            "   okuri buf str:
            "     filter str: "し"
            "     rom str   : "si"
            " to:
            "   henkan buf str:
            "     filter str: "せっ"
            "     rom str   : ""
            "   okuri buf str:
            "     filter str: "し"
            "     rom str   : "si"
            " (http://d.hatena.ne.jp/tyru/20100320/eskk_rom_to_hira)
            let henkan_buf_str        = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
            let okuri_buf_str         = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
            let henkan_select_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
            let henkan_rom = henkan_buf_str.get_rom_str()
            let okuri_rom  = okuri_buf_str.get_rom_str()
            if henkan_rom != '' && s:current_table.has_map(henkan_rom . okuri_rom[0])
                " Push "っ".
                call henkan_buf_str.push_filter_str(
                \   s:current_table.get_map_to(henkan_rom . okuri_rom[0])
                \)
                " Push "s" to rom str.
                let rest = s:current_table.get_rest(henkan_rom . okuri_rom[0], -1)
                if rest !=# -1
                    call okuri_buf_str.set_rom_str(
                    \   rest . okuri_rom[1:]
                    \)
                endif
            endif

            call okuri_buf_str.push_rom_str(char)
            if s:current_table.has_map(okuri_buf_str.get_rom_str())
                call okuri_buf_str.push_filter_str(
                \   s:current_table.get_map_to(okuri_buf_str.get_rom_str())
                \)
                let rest = s:current_table.get_rest(okuri_buf_str.get_rom_str(), -1)
                if rest !=# -1
                    let a:stash.option.redispatch_chars += split(rest, '\zs')
                endif
            endif

            call s:henkan_key(a:stash)
        endif

        return

    elseif s:current_table.has_candidates(rom_str)
        " Has candidates but not match.
        call eskk#util#logf('%s - wait for a next key.', rom_str)
        call buf_str.push_rom_str(char)
        return

    else
        " No candidates.
        " Remove rom_str[-2].
        call eskk#util#logf('%s - no candidates.', rom_str)
        if strlen(rom_str) == 1
            call buf_str.clear_rom_str()
            let a:stash.option.return = rom_str
        else
            call buf_str.pop_rom_str()
            call buf_str.push_rom_str(char)
        endif
        return
    endif
endfunction "}}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

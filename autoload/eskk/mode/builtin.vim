" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Load once {{{
if exists('s:loaded')
    finish
endif
let s:loaded = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID


" Asymmetric built-in modes. {{{

" Variables {{{
let s:rom_to_hira   = eskk#table#new('rom_to_hira')
let s:rom_to_kata   = eskk#table#new('rom_to_kata')
let s:current_table = s:rom_to_hira

let s:skk_dict = eskk#dictionary#new([g:eskk_dictionary, g:eskk_large_dictionary])
let s:current_henkan_result = {}

let s:henkan_rom_str_list = []
" }}}



function! eskk#mode#builtin#asym_cb_handle_key(stash) "{{{
    return 0
endfunction "}}}

function! eskk#mode#builtin#hook_fn_do_lmap_hira(do_map) "{{{
    if a:do_map
        call eskk#map_temp_key('q', '<Plug>(eskk:mode:hira:convert/switch-to-kata)')
        call eskk#map_temp_key('l', '<Plug>(eskk:mode:hira:to-ascii)')
        call eskk#map_temp_key('L', '<Plug>(eskk:mode:hira:to-zenei)')
    else
        call eskk#map_temp_key_restore('q')
        call eskk#map_temp_key_restore('l')
        call eskk#map_temp_key_restore('L')
    endif
endfunction "}}}
function! eskk#mode#builtin#hook_fn_do_lmap_kata() "{{{
    lmap <buffer> q <Plug>(eskk:mode:hira:convert/switch-to-kata)
    lmap <buffer> l <Plug>(eskk:mode:hira:to-ascii)
    lmap <buffer> L <Plug>(eskk:mode:hira:to-zenei)
endfunction "}}}
function! eskk#mode#builtin#hook_fn_do_lmap_zenei() "{{{
    lmap <buffer> <C-j> <Plug>(eskk:mode:zenei:to-hira)
endfunction "}}}
function! eskk#mode#builtin#set_rom_to_hira_table() "{{{
    let s:current_table = s:rom_to_hira
endfunction "}}}
function! eskk#mode#builtin#set_rom_to_kata_table() "{{{
    let s:current_table = s:rom_to_kata
endfunction "}}}
function! eskk#mode#builtin#clear_henkan_rom_str_list() "{{{
    let s:henkan_rom_str_list = []
endfunction "}}}

function! eskk#mode#builtin#do_q_key(stash) "{{{
    let buf_str = a:stash.buftable.get_current_buf_str()
    let phase = a:stash.buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        " Toggle current table.
        call eskk#set_mode(eskk#get_mode() ==# 'hira' ? 'kata' : 'hira')
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \   || phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI

        let normal_buf_str = a:stash.buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_NORMAL)
        let henkan_buf_str = a:stash.buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
        let okuri_buf_str  = a:stash.buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)

        call henkan_buf_str.clear()
        call okuri_buf_str.clear()

        call a:stash.buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)

        let to_table = (s:current_table is s:rom_to_hira ? s:rom_to_kata : s:rom_to_hira)
        let prev_table = s:current_table
        let s:current_table = to_table
        try
            for char in s:henkan_rom_str_list
                let a:stash.char = char
                call s:filter_rom_to_hira(a:stash)
            endfor
        finally
            let s:henkan_rom_str_list = []
            let s:current_table = prev_table
        endtry
    else
        throw eskk#internal_error(['eskk', 'mode', 'hira'])
    endif
endfunction "}}}

function! eskk#mode#builtin#do_lmap_non_egg_like_newline(do_map) "{{{
    if a:do_map
        call eskk#util#log("Map *non* egg like newline...")
        call eskk#map_temp_key('<CR>', '<Plug>(eskk:filter:<CR>)<Plug>(eskk:filter:<CR>)')
    else
        call eskk#util#log("Restore *non* egg like newline...")
        call eskk#register_temp_event('filter-begin', 'eskk#map_temp_key_restore', ['<CR>'])
    endif
endfunction "}}}

function! s:finalize() "{{{
    if eskk#get_buftable().get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        let buf_str = eskk#get_buftable().get_current_buf_str()
        call buf_str.clear_filter_str()
    endif
endfunction "}}}


function! eskk#mode#builtin#asym_filter(stash) "{{{
    let char = a:stash.char
    let henkan_phase = a:stash.buftable.get_henkan_phase()

    if henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        return s:filter_rom_to_hira(a:stash)
    elseif henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        call add(s:henkan_rom_str_list, char)
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
            call a:stash.buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
            " Move henkan select buffer string to normal.
            call a:stash.buftable.move_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT, g:eskk#buftable#HENKAN_PHASE_NORMAL)

            return s:filter_rom_to_hira(a:stash)
        endif
    else
        return eskk#default_filter(a:stash)
    endif
endfunction "}}}

function! s:henkan_key(stash) "{{{
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
            call eskk#register_temp_event(
            \   'filter-finalize',
            \   eskk#util#get_local_func('finalize', s:SID_PREFIX),
            \   []
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


" Symmetric built-in modes. {{{

" Variables {{{
let s:rom_to_ascii  = {}
let s:rom_to_zenei  = eskk#table#new('rom_to_zenei')
let s:current_table = s:rom_to_ascii
" }}}



function! eskk#mode#builtin#sym_cb_handle_key(stash) "{{{
    let c = a:stash.char
    return c =~# '^[a-zA-Z0-9]$'
    \   || c =~# '^[\-^\\!"#$%&''()=~|]$'
    \   || c =~# '^[@\[;:\],./`{+*}<>?_]$'
endfunction "}}}

function! eskk#mode#builtin#hook_fn_do_lmap_ascii() "{{{
    lmap <buffer> <C-j> <Plug>(eskk:mode:ascii:to-hira)
endfunction "}}}
function! eskk#mode#builtin#hook_fn_do_lmap_zenei() "{{{
    lmap <buffer> <C-j> <Plug>(eskk:mode:zenei:to-hira)
endfunction "}}}
function! eskk#mode#builtin#set_rom_to_ascii_table() "{{{
    let s:current_table = s:rom_to_ascii
endfunction "}}}
function! eskk#mode#builtin#set_rom_to_zenei_table() "{{{
    let s:current_table = s:rom_to_zenei
endfunction "}}}

" Filter function
function! eskk#mode#builtin#sym_filter(stash) "{{{
    if s:current_table is s:rom_to_ascii
        call eskk#default_filter(a:stash)
    else
        let c = a:stash.char
        if s:current_table.has_map(c)
            let a:stash.option.return = s:current_table.get_map_to(c)
        else
            call eskk#default_filter(a:stash)
        endif
    endif
endfunction "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

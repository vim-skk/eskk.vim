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
runtime! plugin/eskk.vim


function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID

let s:stash = eskk#get_mutable_stash(['mode', 'builtin'])

" Asymmetric built-in modes. {{{

" Variables {{{
call s:stash.init('current_henkan_result', {})
" }}}



function! eskk#mode#builtin#do_ctrl_q_key(stash) "{{{
    let buftable = eskk#get_buftable()
    let phase = buftable.get_henkan_phase()

    " TODO
endfunction "}}}
function! eskk#mode#builtin#do_q_key(stash) "{{{
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()

    let normal_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    let okuri_buf_str  = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)

    let filter_str = henkan_buf_str.get_filter_str()

    call henkan_buf_str.clear()
    call okuri_buf_str.clear()

    call buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)

    let table = (a:table_name ==# 'rom_to_hira' ? s:get_table_lazy('hira_to_kata') : s:get_table_lazy('kata_to_hira'))
    for wchar in split(filter_str, '\zs')
        call normal_buf_str.push_filter_str(table.get_map_to(wchar, wchar))
    endfor

    function! s:finalize()
        let buftable = eskk#get_buftable()
        if buftable.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
            let buf_str = buftable.get_current_buf_str()
            call buf_str.clear_filter_str()
        endif
    endfunction

    call eskk#register_temp_event(
    \   'filter-begin',
    \   eskk#util#get_local_func('finalize', s:SID_PREFIX),
    \   []
    \)
endfunction "}}}
function! s:get_table_lazy(table_name) "{{{
    let varname = 's:' . a:table_name
    if exists(varname)
        return {varname}
    else
        let {varname} = eskk#table#new(a:table_name)
        return {varname}
    endif
endfunction "}}}

function! eskk#mode#builtin#do_lmap_non_egg_like_newline(do_map) "{{{
    if a:do_map
        if !eskk#has_temp_key('<CR>')
            call eskk#util#log("Map *non* egg like newline...: <CR> => <Plug>(eskk:filter:<CR>)<Plug>(eskk:filter:<CR>)")
            call eskk#set_up_temp_key('<CR>', '<Plug>(eskk:filter:<CR>)<Plug>(eskk:filter:<CR>)')
        endif
    else
        call eskk#util#log("Restore *non* egg like newline...: <CR>")
        call eskk#register_temp_event('filter-begin', 'eskk#set_up_temp_key_restore', ['<CR>'])
    endif
endfunction "}}}

function! s:henkan_key(stash) "{{{
    call eskk#util#log('henkan!')

    let buftable = eskk#get_buftable()
    let phase = buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \ || phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        if g:eskk_kata_convert_to_hira_at_henkan && eskk#get_mode() ==# 'kata'
            let table = s:get_table_lazy('kata_to_hira')
            let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
            let filter_str = henkan_buf_str.get_filter_str()
            call henkan_buf_str.clear_filter_str()
            for wchar in split(filter_str, '\zs')
                call henkan_buf_str.push_filter_str(table.get_map_to(wchar, wchar))
            endfor
            let okuri_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
            let filter_str = okuri_buf_str.get_filter_str()
            call okuri_buf_str.clear_filter_str()
            for wchar in split(filter_str, '\zs')
                call okuri_buf_str.push_filter_str(table.get_map_to(wchar, wchar))
            endfor
        endif

        let s:current_henkan_result = eskk#get_dictionary().refer(buftable)

        " Enter henkan select phase.
        call buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)

        " Clear phase henkan/okuri buffer string.
        " Assumption: `eskk#get_dictionary().refer()` saves necessary strings.
        let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
        call henkan_buf_str.clear_rom_str()
        call henkan_buf_str.clear_filter_str()
        let okuri_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
        call okuri_buf_str.clear_rom_str()
        call okuri_buf_str.clear_filter_str()

        let buf_str = buftable.get_current_buf_str()
        let candidate = s:current_henkan_result.get_candidate()

        if type(candidate) == type("")
            " Set candidate.
            call buf_str.set_filter_str(candidate)
        else
            " No candidates.
            let input = eskk#get_dictionary().register_word(s:current_henkan_result)
            call buf_str.set_filter_str(input)
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        throw eskk#internal_error(['eskk', 'mode', 'builtin'])
    else
        let msg = printf("s:henkan_key() does not support phase %d.", phase)
        throw eskk#internal_error(['eskk', 'mode', 'builtin'], msg)
    endif
endfunction "}}}
function! s:get_next_candidate(stash, next) "{{{
    let buftable = eskk#get_buftable()
    let cur_buf_str = buftable.get_current_buf_str()

    if s:current_henkan_result[a:next ? 'advance' : 'back']()
        let candidate = s:current_henkan_result.get_candidate()
        call eskk#util#assert(type(candidate) == type(""))

        " Set candidate.
        call cur_buf_str.set_filter_str(candidate)
    else
        " No more candidates.
        if a:next
            " Register new word when it advanced or backed current result index,
            " And tried to step at last candidates but failed.
            let input = eskk#get_dictionary().register_word(s:current_henkan_result)
            call cur_buf_str.set_filter_str(input)
        else
            " Restore previous buftable state

            let buftable = s:current_henkan_result._buftable

            let revert_style = eskk#util#option_value(
            \   g:eskk_revert_henkan_style,
            \   ['eskk', 'aquaskk', 'skk'],
            \   0
            \)
            if revert_style ==# 'eskk'
                " "▼書く" => "▽か*k"
                let okuri_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
                if okuri_buf_str.get_rom_str() != ''
                    call okuri_buf_str.set_rom_str(okuri_buf_str.get_rom_str()[0])
                    call okuri_buf_str.clear_filter_str()
                endif
            elseif revert_style ==# 'aquaskk'
                " "▼書く" => "▽か"
                let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
                let okuri_buf_str  = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
                if okuri_buf_str.get_rom_str() != ''
                    call henkan_buf_str.clear_rom_str()
                    call okuri_buf_str.clear_rom_str()
                    call okuri_buf_str.clear_filter_str()
                    call buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN)
                endif
            elseif revert_style ==# 'skk'
                " "▼書く" => "▽かく"
                let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
                let okuri_buf_str  = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
                if okuri_buf_str.get_rom_str() != ''
                    call henkan_buf_str.push_filter_str(okuri_buf_str.get_filter_str())
                    call henkan_buf_str.clear_rom_str()
                    call okuri_buf_str.clear_rom_str()
                    call okuri_buf_str.clear_filter_str()
                    call buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN)
                endif
            else
                throw eskk#internal_error(['eskk', 'mode', 'builtin'])
            endif

            call eskk#set_buftable(buftable)
        endif
    endif
endfunction "}}}

function! s:generate_map_list(str, tail, ...) "{{{
    let str = a:str
    let result = a:0 != 0 ? a:1 : []
    " NOTE: `str` must come to empty string.
    if str == ''
        return result
    else
        call add(result, str)
        " a:tail is true, Delete tail one character.
        " a:tail is false, Delete first one character.
        return s:generate_map_list(
        \   (a:tail ? strpart(str, 0, strlen(str) - 1) : strpart(str, 1)),
        \   a:tail,
        \   result
        \)
    endif
endfunction "}}}
function! s:get_matched_and_rest(table, rom_str, tail) "{{{
    " For e.g., if table has map "n" to "ん" and "j" to none.
    " rom_str(a:tail is true): "nj" => [["ん"], "j"]
    " rom_str(a:tail is false): "nj" => [[], "nj"]

    let matched = []
    let rest = a:rom_str
    while 1
        let counter = 0
        let has_map_str = -1
        for str in s:generate_map_list(rest, a:tail)
            let counter += 1
            if a:table.has_map(str)
                let has_map_str = str
                break
            endif
        endfor
        if has_map_str ==# -1
            return [matched, rest]
        endif
        call add(matched, a:table.get_map_to(has_map_str))
        if a:tail
            " Delete first `has_map_str` bytes.
            let rest = strpart(rest, strlen(has_map_str))
        else
            " Delete last `has_map_str` bytes.
            let rest = strpart(rest, 0, strlen(rest) - strlen(has_map_str))
        endif
    endwhile
endfunction "}}}

function! s:filter_rom(stash, table_name) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()
    let rom_str = buf_str.get_rom_str() . char
    let table = s:get_table_lazy(a:table_name)
    let match_exactly  = table.has_map(rom_str)
    let candidates     = table.get_candidates(rom_str)

    call eskk#util#logf('char = %s, rom_str = %s', string(char), string(rom_str))
    call eskk#util#logf('candidates = %s', string(candidates))

    if match_exactly
        call eskk#util#assert(!empty(candidates))
    endif

    if match_exactly && len(candidates) == 1
        " Match!
        call eskk#util#logf('%s - match!', rom_str)
        return s:filter_rom_exact_match(a:stash, table)

    elseif !empty(candidates)
        " Has candidates but not match.
        call eskk#util#logf('%s - wait for a next key.', rom_str)
        return s:filter_rom_has_candidates(a:stash)

    else
        " No candidates.
        call eskk#util#logf('%s - no candidates.', rom_str)
        return s:filter_rom_no_match(a:stash, table)
    endif
endfunction "}}}
function! s:filter_rom_exact_match(stash, table) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()
    let rom_str = buf_str.get_rom_str() . char
    let phase = buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   || phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        " Set filtered string.
        call buf_str.push_filter_str(
        \   a:table.get_map_to(rom_str)
        \)
        call buf_str.clear_rom_str()


        " Set rest string.
        "
        " NOTE:
        " rest must not have multibyte string.
        " rest is for rom string.
        let rest = a:table.get_rest(rom_str, -1)
        " Assumption: 'a:table.has_map(rest)' returns false here.
        if rest !=# -1
            " XXX:
            "     eskk#get_named_map(char)
            " should
            "     eskk#get_named_map(eskk#util#uneval_key(char))
            for rest_char in split(rest, '\zs')
                call eskk#register_temp_event(
                \   'filter-redispatch',
                \   'eskk#util#eval_key',
                \   [eskk#get_named_map(rest_char)]
                \)
            endfor
        endif


        " Clear filtered string when eskk#filter()'s finalizing.
        function! s:finalize()
            let buftable = eskk#get_buftable()
            if buftable.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
                let buf_str = buftable.get_current_buf_str()
                call buf_str.clear_filter_str()
            endif
        endfunction

        call eskk#register_temp_event(
        \   'filter-begin',
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
        if henkan_rom != '' && a:table.has_map(henkan_rom . okuri_rom[0])
            " Push "っ".
            call henkan_buf_str.push_filter_str(
            \   a:table.get_map_to(henkan_rom . okuri_rom[0])
            \)
            " Push "s" to rom str.
            let rest = a:table.get_rest(henkan_rom . okuri_rom[0], -1)
            if rest !=# -1
                call okuri_buf_str.set_rom_str(
                \   rest . okuri_rom[1:]
                \)
            endif
        endif

        call eskk#util#assert(char != '')
        call okuri_buf_str.push_rom_str(char)

        if a:table.has_map(okuri_buf_str.get_rom_str())
            call okuri_buf_str.push_filter_str(
            \   a:table.get_map_to(okuri_buf_str.get_rom_str())
            \)
            let rest = a:table.get_rest(okuri_buf_str.get_rom_str(), -1)
            if rest !=# -1
                " XXX:
                "     eskk#get_named_map(char)
                " should
                "     eskk#get_named_map(eskk#util#uneval_key(char))
                for rest_char in split(rest, '\zs')
                    call eskk#register_temp_event(
                    \   'filter-redispatch',
                    \   'eskk#util#eval_key',
                    \   [eskk#get_named_map(rest_char)]
                    \)
                endfor
            endif
        endif

        call s:henkan_key(a:stash)
    endif
endfunction "}}}
function! s:filter_rom_has_candidates(stash) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()

    " NOTE: This will be run in all phases.
    call buf_str.push_rom_str(char)
endfunction "}}}
function! s:filter_rom_no_match(stash, table) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()
    let rom_str_without_char = buf_str.get_rom_str()
    let rom_str = rom_str_without_char . char
    let input_style = eskk#util#option_value(g:eskk_rom_input_style, ['skk', 'msime', 'quickmatch'], 0)

    let [matched_map_list, rest] = s:get_matched_and_rest(a:table, rom_str, 1)
    if empty(matched_map_list)
        if input_style ==# 'skk'
            if rest ==# char
                let a:stash.return = char
            else
                let rest = strpart(rest, 0, strlen(rest) - 2) . char
                call buf_str.set_rom_str(rest)
            endif
        else
            let [matched_map_list, rest2] = s:get_matched_and_rest(a:table, rom_str, 0)
            if empty(matched_map_list)
                call buf_str.set_rom_str(rest2)
            else
                call buf_str.push_filter_str(rest2)
                for matched in matched_map_list
                    call buf_str.push_filter_str(matched)
                endfor
                call buf_str.clear_rom_str()
            endif
        endif
    else
        for matched in matched_map_list
            call buf_str.push_filter_str(matched)
        endfor
        call buf_str.set_rom_str(rest)
    endif
endfunction "}}}



function! eskk#mode#builtin#asym_filter(stash, table_name) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let henkan_phase = buftable.get_henkan_phase()


    " In order not to change current buftable old string.
    call eskk#lock_old_str()
    try
        " Handle special characters.
        " These characters are handled regardless of current phase.
        if char ==# "\<BS>" || char ==# "\<C-h>"
            call buftable.do_backspace(a:stash)
            return
        elseif char ==# "\<CR>"
            call buftable.do_enter(a:stash)
            return
        elseif eskk#is_sticky_key(char)
            call eskk#sticky_key(a:stash)
            return
        elseif eskk#is_big_letter(char)
            call eskk#sticky_key(a:stash)
            call eskk#register_temp_event('filter-redispatch', 'eskk#filter', [tolower(char)])
            return
        else
            " Fall through.
        endif
    finally
        call eskk#unlock_old_str()
    endtry


    " Handle special mode-local mapping.
    let cur_mode = eskk#get_mode()
    let toggle_hankata = printf('mode:%s:toggle-hankata', cur_mode)
    let ctrl_q_key = printf('mode:%s:ctrl-q-key', cur_mode)
    let toggle_kata = printf('mode:%s:toggle-kata', cur_mode)
    let q_key = printf('mode:%s:q-key', cur_mode)
    let to_ascii = printf('mode:%s:to-ascii', cur_mode)
    let to_zenei = printf('mode:%s:to-zenei', cur_mode)

    if eskk#is_special_lhs(char, toggle_hankata)
    \   && phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'hankata' ? 'hira' : 'hankata')
        return
    elseif eskk#is_special_lhs(char, ctrl_q_key)
    \   && (phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \       || phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI)
        call eskk#mode#builtin#do_ctrl_q_key(a:stash)
        return
    elseif eskk#is_special_lhs(char, toggle_kata)
    \   && phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'kata' ? 'hira' : 'kata')
        return
    elseif eskk#is_special_lhs(char, q_key)
    \   && (phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \       || phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI)
        call eskk#mode#builtin#do_q_key(a:stash)
        return
    elseif eskk#is_special_lhs(char, to_ascii)
    \   && phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call eskk#set_mode('ascii')
        return
    elseif eskk#is_special_lhs(char, to_zenei)
    \   && phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call eskk#set_mode('zenei')
        return
    else
        " Fall through.
    endif


    " Handle other characters.
    if henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        return s:filter_rom(a:stash, a:table_name)
    elseif henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        if eskk#is_henkan_key(char)
            return s:henkan_key(a:stash)
            call eskk#util#assert(buftable.get_henkan_phase() == g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
        else
            return s:filter_rom(a:stash, a:table_name)
        endif
    elseif henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        return s:filter_rom(a:stash, a:table_name)
    elseif henkan_phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        if eskk#is_special_lhs(char, 'henkan-select:choose-next')
            return s:get_next_candidate(a:stash, 1)
        elseif eskk#is_special_lhs(char, 'henkan-select:choose-prev')
            return s:get_next_candidate(a:stash, 0)
        else
            call buftable.push_kakutei_str(buftable.get_display_str(0))
            call eskk#register_temp_event('filter-redispatch', 'eskk#filter', [a:stash.char])

            call buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
        endif
    else
        let msg = printf("eskk#mode#builtin#asym_filter() does not support phase %d.", henkan_phase)
        throw eskk#internal_error(['eskk'], msg)
    endif
endfunction "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8


" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let g:eskk#version = str2nr(printf('%02d%02d%03d', 0, 5, 347))


function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunction s:SID


" See eskk#_initialize() for global variables.

" Variables {{{

" These variables are copied when starting new eskk instance.
" e.g.: Register word(s) recursively
"
" mode:
"   Current mode.
" buftable:
"   Buffer strings for inserted, filtered and so on.
" has_locked_old_str:
"   Lock current diff old string?
" temp_event_hook_fn:
"   Temporary event handler functions/arguments.
" enabled:
"   True if s:eskk.enable() is called.
let s:eskk = {
\   'mode': '',
\   'buftable': {},
\   'has_locked_old_str': 0,
\   'temp_event_hook_fn': {},
\   'enabled': 0,
\}



" NOTE: Following variables have global values between instances.

" s:Eskk instances.
let s:eskk_instances = []
" Index number for current instance.
let s:eskk_instance_id = 0
" Supported modes and their structures.
let s:available_modes = {}
" Event handler functions/arguments.
let s:event_hook_fn = {}
" Flag for `eskk#_initialize()`.
let s:INIT_YET   = 0
let s:INIT_DONE  = 1
let s:INIT_ABORT = 2
let s:initialization_state = s:INIT_YET
" SKK Dictionary (singleton)
let s:skk_dict = {}
" Mode and its table.
let s:mode_vs_table = {}
" All tables structures.
let s:table_defs = {}
" All special mappings eskk knows.
" `special` means "they don't have something to do with mappings Vim knows."
let s:eskk_mappings = {
\   'general': {},
\   'sticky': {},
\   'backspace-key': {},
\   'escape-key': {},
\   'enter-key': {},
\   'tab': {},
\   'phase:henkan:henkan-key': {},
\   'phase:okuri:henkan-key': {},
\   'phase:henkan-select:choose-next': {},
\   'phase:henkan-select:choose-prev': {},
\   'phase:henkan-select:next-page': {},
\   'phase:henkan-select:prev-page': {},
\   'phase:henkan-select:escape': {},
\   'phase:henkan-select:delete-from-dict': {},
\   'mode:hira:toggle-hankata': {'fn': 's:handle_toggle_hankata'},
\   'mode:hira:ctrl-q-key': {'fn': 's:handle_ctrl_q_key'},
\   'mode:hira:toggle-kata': {'fn': 's:handle_toggle_kata'},
\   'mode:hira:q-key': {'fn': 's:handle_q_key'},
\   'mode:hira:l-key': {'fn': 's:handle_l_key'},
\   'mode:hira:to-ascii': {'fn': 's:handle_to_ascii'},
\   'mode:hira:to-zenei': {'fn': 's:handle_to_zenei'},
\   'mode:hira:to-abbrev': {'fn': 's:handle_to_abbrev'},
\   'mode:kata:toggle-hankata': {'fn': 's:handle_toggle_hankata'},
\   'mode:kata:ctrl-q-key': {'fn': 's:handle_ctrl_q_key'},
\   'mode:kata:toggle-kata': {'fn': 's:handle_toggle_kata'},
\   'mode:kata:q-key': {'fn': 's:handle_q_key'},
\   'mode:kata:l-key': {'fn': 's:handle_l_key'},
\   'mode:kata:to-ascii': {'fn': 's:handle_to_ascii'},
\   'mode:kata:to-zenei': {'fn': 's:handle_to_zenei'},
\   'mode:kata:to-abbrev': {'fn': 's:handle_to_abbrev'},
\   'mode:hankata:toggle-hankata': {'fn': 's:handle_toggle_hankata'},
\   'mode:hankata:ctrl-q-key': {'fn': 's:handle_ctrl_q_key'},
\   'mode:hankata:toggle-kata': {'fn': 's:handle_toggle_kata'},
\   'mode:hankata:q-key': {'fn': 's:handle_q_key'},
\   'mode:hankata:l-key': {'fn': 's:handle_l_key'},
\   'mode:hankata:to-ascii': {'fn': 's:handle_to_ascii'},
\   'mode:hankata:to-zenei': {'fn': 's:handle_to_zenei'},
\   'mode:hankata:to-abbrev': {'fn': 's:handle_to_abbrev'},
\   'mode:ascii:to-hira': {'fn': 's:handle_toggle_hankata'},
\   'mode:zenei:to-hira': {'fn': 's:handle_toggle_hankata'},
\   'mode:abbrev:henkan-key': {},
\}
" }}}



function! eskk#load() "{{{
    runtime! plugin/eskk.vim
endfunction "}}}

if !exists('g:__eskk_now_reloading')
    function! eskk#reload() "{{{
        let scripts = []
        let scripts += eskk#util#get_loaded_scripts('\C'.'/autoload/eskk/\S\+\.vim$')
        let scripts += eskk#util#get_loaded_scripts('\C'.'/autoload/eskk\.vim$')
        unlet! g:__eskk_now_reloading
        for script in sort(scripts)    " Make :source order consistent
            let g:__eskk_now_reloading = 1
            try
                source `=script`
            catch
                call eskk#util#warnf('[%s] at [%s]', v:exception, v:throwpoint)
            finally
                unlet g:__eskk_now_reloading
            endtry
        endfor
    endfunction "}}}
endif



" Instance
function! s:eskk_new() "{{{
    return deepcopy(s:eskk, 1)
endfunction "}}}
function! eskk#get_current_instance() "{{{
    try
        return s:eskk_instances[s:eskk_instance_id]
    catch
        call eskk#error#log_exception(
        \   'eskk#get_current_instance()')
        " Trap "E684: list index our of range ..."
        call eskk#initialize_instance()
        " This must not raise an error.
        return s:eskk_instances[s:eskk_instance_id]
    endtry
endfunction "}}}
function! eskk#initialize_instance() "{{{
    let s:eskk_instances = [s:eskk_new()]
    let s:eskk_instance_id = 0
endfunction "}}}
function! eskk#create_new_instance() "{{{
    " TODO: CoW
    if s:eskk_instance_id != len(s:eskk_instances) - 1
        throw eskk#internal_error(['eskk'], "mismatch values between s:eskk_instance_id and s:eskk_instances")
    endif

    " Create and push the instance.
    call add(s:eskk_instances, s:eskk_new())
    let s:eskk_instance_id += 1

    " Initialize instance.
    call eskk#enable(0)
endfunction "}}}
function! eskk#destroy_current_instance() "{{{
    if s:eskk_instance_id == 0
        throw eskk#internal_error(['eskk'], "No more instances.")
    endif
    if s:eskk_instance_id != len(s:eskk_instances) - 1
        throw eskk#internal_error(['eskk'], "mismatch values between s:eskk_instance_id and s:eskk_instances")
    endif

    " Destroy current instance.
    call remove(s:eskk_instances, s:eskk_instance_id)
    let s:eskk_instance_id -= 1
endfunction "}}}
function! eskk#get_buffer_instance() "{{{
    if !exists('b:eskk')
        let b:eskk = {}
    endif
    return b:eskk
endfunction "}}}

" Filter
" s:asym_filter {{{
function! s:asym_filter(stash) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let phase = buftable.get_henkan_phase()


    " Handle special mode-local mapping.
    let cur_mode = eskk#get_mode()
    let toggle_hankata = printf('mode:%s:toggle-hankata', cur_mode)
    let ctrl_q_key = printf('mode:%s:ctrl-q-key', cur_mode)
    let toggle_kata = printf('mode:%s:toggle-kata', cur_mode)
    let q_key = printf('mode:%s:q-key', cur_mode)
    let l_key = printf('mode:%s:l-key', cur_mode)
    let to_ascii = printf('mode:%s:to-ascii', cur_mode)
    let to_zenei = printf('mode:%s:to-zenei', cur_mode)
    let to_abbrev = printf('mode:%s:to-abbrev', cur_mode)

    for key in [
    \   toggle_hankata,
    \   ctrl_q_key,
    \   toggle_kata,
    \   q_key,
    \   l_key,
    \   to_ascii,
    \   to_zenei,
    \   to_abbrev
    \]
        if eskk#map#handle_special_lhs(char, key, a:stash)
            " Handled.
            return
        endif
    endfor


    " In order not to change current buftable old string.
    call eskk#lock_old_str()
    try
        " Handle special characters.
        " These characters are handled regardless of current phase.
        if eskk#map#is_special_lhs(char, 'backspace-key')
            call buftable.do_backspace(a:stash)
            return
        elseif eskk#map#is_special_lhs(char, 'enter-key')
            call buftable.do_enter(a:stash)
            return
        elseif eskk#map#is_special_lhs(char, 'sticky')
            call buftable.do_sticky(a:stash)
            return
        elseif char =~# '^[A-Z]$'
        \   && !eskk#map#is_special_lhs(
        \          char, 'phase:henkan-select:delete-from-dict'
        \       )
            if buftable.get_current_buf_str().rom_str.empty()
                call buftable.do_sticky(a:stash)
                call eskk#register_temp_event(
                \   'filter-redispatch-post',
                \   'eskk#map#key2char',
                \   [eskk#map#get_filter_map(tolower(char))]
                \)
                return
            else
                " NOTE: Assume "SAkujo" as "Sakujo".
                let stash = deepcopy(a:stash)
                let stash.char = tolower(stash.char)
                return s:asym_filter(stash)
            endif
        elseif eskk#map#is_special_lhs(char, 'escape-key')
            call buftable.do_escape(a:stash)
            return
        elseif eskk#map#is_special_lhs(char, 'tab')
            call buftable.do_tab(a:stash)
            return
        else
            " Fall through.
        endif
    finally
        call eskk#unlock_old_str()
    endtry


    " Handle other characters.
    if phase ==# g:eskk#buftable#PHASE_NORMAL
        return s:filter_rom(a:stash, eskk#get_current_mode_table())
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN
        if eskk#map#is_special_lhs(char, 'phase:henkan:henkan-key')
            call buftable.do_henkan(a:stash)
        else
            return s:filter_rom(a:stash, eskk#get_current_mode_table())
        endif
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        if eskk#map#is_special_lhs(char, 'phase:okuri:henkan-key')
            call buftable.do_henkan(a:stash)
        else
            return s:filter_rom(a:stash, eskk#get_current_mode_table())
        endif
    elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
        if eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:choose-next'
        \)
            call buftable.choose_next_candidate(a:stash)
            return
        elseif eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:choose-prev'
        \)
            call buftable.choose_prev_candidate(a:stash)
            return
        elseif eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:delete-from-dict'
        \)
            let henkan_result = eskk#get_skk_dict().get_henkan_result()
            if !empty(henkan_result)
                call henkan_result.delete_from_dict()

                call buftable.push_kakutei_str(buftable.get_display_str(0))
                call buftable.set_henkan_phase(
                \   g:eskk#buftable#PHASE_NORMAL
                \)
            endif
        else
            call buftable.do_enter(a:stash)
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#map#key2char',
            \   [eskk#map#get_filter_map(a:stash.char)]
            \)
        endif
    else
        throw eskk#internal_error(
        \   ['eskk'],
        \   "s:asym_filter() does not support phase " . phase . "."
        \)
    endif
endfunction "}}}

function! s:filter_rom(stash, table) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()
    let rom_str = buf_str.rom_str.get() . char

    if a:table.has_n_candidates(rom_str, 2)
        " Has candidates but not match.
        return s:filter_rom_has_candidates(a:stash)
    elseif a:table.has_map(rom_str)
        " Match!
        return s:filter_rom_exact_match(a:stash, a:table)
    else
        " No candidates.
        return s:filter_rom_no_match(a:stash, a:table)
    endif
endfunction "}}}
function! s:filter_rom_exact_match(stash, table) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()
    let rom_str = buf_str.rom_str.get() . char
    let phase = buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#PHASE_NORMAL
    \   || phase ==# g:eskk#buftable#PHASE_HENKAN
        " Set filtered string.
        call buf_str.rom_pairs.push_one_pair(rom_str, a:table.get_map(rom_str))
        call buf_str.rom_str.clear()


        " Set rest string.
        "
        " NOTE:
        " rest must not have multibyte string.
        " rest is for rom string.
        let rest = a:table.get_rest(rom_str, -1)
        " Assumption: 'a:table.has_map(rest)' returns false here.
        if rest !=# -1
            " XXX:
            "     eskk#map#get_filter_map(char)
            " should
            "     eskk#map#get_filter_map(eskk#util#uneval_key(char))
            for rest_char in split(rest, '\zs')
                call eskk#register_temp_event(
                \   'filter-redispatch-post',
                \   'eskk#map#key2char',
                \   [eskk#map#get_filter_map(rest_char)]
                \)
            endfor
        endif


        call eskk#register_temp_event(
        \   'filter-begin',
        \   eskk#util#get_local_func('clear_buffer_string', s:SID_PREFIX),
        \   [g:eskk#buftable#PHASE_NORMAL]
        \)

        if g:eskk#convert_at_exact_match
        \   && phase ==# g:eskk#buftable#PHASE_HENKAN
            let st = eskk#get_current_mode_structure()
            let henkan_buf_str = buftable.get_buf_str(
            \   g:eskk#buftable#PHASE_HENKAN
            \)
            if has_key(st.temp, 'real_matched_pairs')
                " Restore previous hiragana & push current to the tail.
                let p = henkan_buf_str.rom_pairs.pop()
                call henkan_buf_str.rom_pairs.set(
                \   st.temp.real_matched_pairs + [p]
                \)
            endif
            let st.temp.real_matched_pairs = henkan_buf_str.rom_pairs.get()

            call buftable.do_henkan(a:stash, 1)
        endif
    elseif phase ==# g:eskk#buftable#PHASE_OKURI
        " Enter phase henkan select with henkan.

        " XXX Write test and refactoring.
        "
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
        let henkan_buf_str = buftable.get_buf_str(
        \   g:eskk#buftable#PHASE_HENKAN
        \)
        let okuri_buf_str = buftable.get_buf_str(
        \   g:eskk#buftable#PHASE_OKURI
        \)
        let henkan_select_buf_str = buftable.get_buf_str(
        \   g:eskk#buftable#PHASE_HENKAN_SELECT
        \)
        let henkan_rom = henkan_buf_str.rom_str.get()
        let okuri_rom  = okuri_buf_str.rom_str.get()
        if henkan_rom != '' && a:table.has_map(henkan_rom . okuri_rom[0])
            " Push "っ".
            let match_rom = henkan_rom . okuri_rom[0]
            call henkan_buf_str.rom_pairs.push_one_pair(
            \   match_rom,
            \   a:table.get_map(match_rom)
            \)
            " Push "s" to rom str.
            let rest = a:table.get_rest(henkan_rom . okuri_rom[0], -1)
            if rest !=# -1
                call okuri_buf_str.rom_str.set(
                \   rest . okuri_rom[1:]
                \)
            endif
        endif

        call eskk#error#assert(char != '', 'char must not be empty')
        call okuri_buf_str.rom_str.append(char)

        let has_rest = 0
        if a:table.has_map(okuri_buf_str.rom_str.get())
            call okuri_buf_str.rom_pairs.push_one_pair(
            \   okuri_buf_str.rom_str.get(),
            \   a:table.get_map(okuri_buf_str.rom_str.get())
            \)
            let rest = a:table.get_rest(okuri_buf_str.rom_str.get(), -1)
            if rest !=# -1
                " XXX:
                "     eskk#map#get_filter_map(char)
                " should
                "     eskk#map#get_filter_map(eskk#util#uneval_key(char))
                for rest_char in split(rest, '\zs')
                    call eskk#register_temp_event(
                    \   'filter-redispatch-post',
                    \   'eskk#map#key2char',
                    \   [eskk#map#get_filter_map(rest_char)]
                    \)
                endfor
                let has_rest = 1
            endif
        endif

        call okuri_buf_str.rom_str.clear()

        let matched = okuri_buf_str.rom_pairs.get()
        call eskk#error#assert(!empty(matched), 'matched must not be empty.')
        " TODO `len(matched) == 1`: Do henkan at only the first time.

        if !has_rest && g:eskk#auto_henkan_at_okuri_match
            call buftable.do_henkan(a:stash)
        endif
    endif
endfunction "}}}
function! s:filter_rom_has_candidates(stash) "{{{
    let buftable = eskk#get_buftable()
    let buf_str  = buftable.get_current_buf_str()
    call buf_str.rom_str.append(a:stash.char)
endfunction "}}}
function! s:filter_rom_no_match(stash, table) "{{{
    let char = a:stash.char
    let buf_str = eskk#get_buftable().get_current_buf_str()
    let rom_str_without_char = buf_str.rom_str.get()

    " TODO: Save previous (or more?) searched result
    " with map/candidates of rom_str.

    let NO_MAP = []
    let map = a:table.get_map(rom_str_without_char, NO_MAP)
    if map isnot NO_MAP
        " `rom_str_without_char` has the map but fail with `char`.
        " e.g.: rom_str is "nj" => "んj"
        call buf_str.rom_pairs.push_one_pair(rom_str_without_char, map)
        " *** FALLTHROUGH ***
    elseif empty(rom_str_without_char)
        " No candidates started with such a character `char`.
        " e.g.: rom_str is " ", "&"
        call buf_str.rom_pairs.push_one_pair(char, char)
        return
    else
        " `rom_str_without_char` has the candidate(s) but fail with `char`.
        if g:eskk#rom_input_style ==# 'skk'
            " rom_str is "zyk" => "k"
        elseif g:eskk#rom_input_style ==# 'msime'
            " rom_str is "zyk" => "zyk"
            call buf_str.rom_pairs.push_one_pair(
            \   rom_str_without_char, rom_str_without_char
            \)
        endif
        " *** FALLTHROUGH ***
    endif

    " Handle `char`.
    " TODO: Can do it recursively?
    unlet map
    let map = a:table.get_map(char, NO_MAP)
    if map isnot NO_MAP
        call buf_str.rom_pairs.push_one_pair(char, map)
        call buf_str.rom_str.clear()
    else
        call buf_str.rom_str.set(char)
    endif
endfunction "}}}
" Clear filtered string when eskk#filter()'s finalizing.
function! s:clear_buffer_string(phase) "{{{
    let buftable = eskk#get_buftable()
    if buftable.get_henkan_phase() ==# a:phase
        let buf_str = buftable.get_current_buf_str()
        call buf_str.rom_pairs.clear()
    endif
endfunction "}}}

" }}}

" Initialization
function! eskk#_initialize() "{{{
    if s:initialization_state ==# s:INIT_DONE
    \   || s:initialization_state ==# s:INIT_ABORT
        return
    endif
    let s:initialization_state = s:INIT_ABORT

    " Check if prereq libs' versions {{{
    function! s:validate_vim_version() "{{{
        let ok =
        \   v:version > 703
        \   || v:version == 703 && has('patch32')
        if !ok
            echohl WarningMsg
            echomsg "eskk.vim: warning: Your Vim is too old."
            \       "Please use 7.3.32 at least."
            echohl None

            throw 'FINISH'
        endif
    endfunction "}}}

    try
        call s:validate_vim_version()
    catch /^FINISH\C$/
        " do not initialize eskk
        " if user doesn't fill requirements!
        return
    endtry
    " }}}

    " Create the first eskk instance. {{{
    call eskk#initialize_instance()
    " }}}

    " Create eskk augroup. {{{
    augroup eskk
        autocmd!
    augroup END
    " }}}

    " Create "eskk-initialize-pre" autocmd event. {{{
    " If no "User eskk-initialize-pre" events,
    " Vim complains like "No matching autocommands".
    autocmd eskk User eskk-initialize-pre :

    " Throw eskk-initialize-pre event.
    doautocmd User eskk-initialize-pre
    " }}}

    " Global Variables {{{

    " Debug
    call eskk#util#set_default('g:eskk#debug', 0)
    call eskk#util#set_default('g:eskk#debug_wait_ms', 0)
    call eskk#util#set_default('g:eskk#debug_out', 'both')
    call eskk#util#set_default('g:eskk#directory', '~/.eskk')

    " Dictionary
    for [s:varname, s:default] in [
    \   ['g:eskk#dictionary', {
    \       'path': "~/.skk-jisyo",
    \       'sorted': 0,
    \       'encoding': 'utf-8',
    \   }],
    \   ['g:eskk#large_dictionary', {
    \       'path': "/usr/local/share/skk/SKK-JISYO.L",
    \       'sorted': 1,
    \       'encoding': 'euc-jp',
    \   }],
    \]
        if exists(s:varname)
            if type({s:varname}) == type("")
                let s:default.path = {s:varname}
                unlet {s:varname}
                let {s:varname} = s:default
            elseif type({s:varname}) == type({})
                call extend({s:varname}, s:default, "keep")
            else
                call eskk#util#warn(
                \   s:varname . "'s type is either String or Dictionary."
                \)
            endif
        else
            let {s:varname} = s:default
        endif
    endfor
    unlet! s:varname s:default

    call eskk#util#set_default('g:eskk#backup_dictionary', g:eskk#dictionary.path . '.BAK')
    call eskk#util#set_default('g:eskk#auto_save_dictionary_at_exit', 1)

    call eskk#util#set_default('g:eskk#dictionary_save_count', -1)

    " Henkan
    call eskk#util#set_default('g:eskk#select_cand_keys', "asdfjkl")
    call eskk#util#set_default('g:eskk#show_candidates_count', 4)
    call eskk#util#set_default('g:eskk#kata_convert_to_hira_at_henkan', 1)
    call eskk#util#set_default('g:eskk#kata_convert_to_hira_at_completion', 1)
    call eskk#util#set_default('g:eskk#show_annotation', 0)
    call eskk#util#set_default('g:eskk#kakutei_when_unique_candidate', 0)

    " Mappings
    call eskk#util#set_default('g:eskk#mapped_keys', eskk#get_default_mapped_keys())

    " Mode
    call eskk#util#set_default('g:eskk#initial_mode', 'hira')

    if !exists('g:eskk#statusline_mode_strings')
        let g:eskk#statusline_mode_strings =  {'hira': 'あ', 'kata': 'ア', 'ascii': 'aA', 'zenei': 'ａ', 'hankata': 'ｧｱ', 'abbrev': 'aあ'}
    endif

    " Table
    call eskk#util#set_default('g:eskk#cache_table_map', 1)

    " Markers
    call eskk#util#set_default('g:eskk#marker_henkan', '▽')
    call eskk#util#set_default('g:eskk#marker_okuri', '*')
    call eskk#util#set_default('g:eskk#marker_henkan_select', '▼')
    call eskk#util#set_default('g:eskk#marker_jisyo_touroku', '?')
    call eskk#util#set_default('g:eskk#marker_popup', '#')

    " Completion
    call eskk#util#set_default('g:eskk#enable_completion', 1)
    call eskk#util#set_default('g:eskk#max_candidates', 30)
    call eskk#util#set_default('g:eskk#start_completion_length', 3)

    " Cursor color
    call eskk#util#set_default('g:eskk#use_color_cursor', 1)

    if !exists('g:eskk#cursor_color')
        " ascii: ivory4:#8b8b83, gray:#bebebe
        " hira: coral4:#8b3e2f, pink:#ffc0cb
        " kata: forestgreen:#228b22, green:#00ff00
        " abbrev: royalblue:#4169e1
        " zenei: gold:#ffd700
        let g:eskk#cursor_color = {
        \   'ascii': ['#8b8b83', '#bebebe'],
        \   'hira': ['#8b3e2f', '#ffc0cb'],
        \   'kata': ['#228b22', '#00ff00'],
        \   'abbrev': '#4169e1',
        \   'zenei': '#ffd700',
        \}
    endif

    " Misc.
    call eskk#util#set_default('g:eskk#egg_like_newline', 0)
    call eskk#util#set_default('g:eskk#keep_state', 0)
    call eskk#util#set_default('g:eskk#keep_state_beyond_buffer', 0)
    call eskk#util#set_default('g:eskk#revert_henkan_style', 'okuri')
    call eskk#util#set_default('g:eskk#delete_implies_kakutei', 0)
    call eskk#util#set_default('g:eskk#rom_input_style', 'skk')
    call eskk#util#set_default('g:eskk#auto_henkan_at_okuri_match', 1)

    if !exists("g:eskk#set_undo_point")
        let g:eskk#set_undo_point = {
        \   'sticky': 1,
        \   'kakutei': 1,
        \}
    endif

    call eskk#util#set_default('g:eskk#fix_extra_okuri', 1)
    call eskk#util#set_default('g:eskk#convert_at_exact_match', 0)
    " }}}

    " Set up g:eskk#directory. {{{
    function! s:initialize_set_up_eskk_directory()
        let dir = expand(g:eskk#directory)
        for d in [dir, eskk#util#join_path(dir, 'log')]
            if !isdirectory(d) && !eskk#util#mkdir_nothrow(d)
                call eskk#error#logf("can't create directory '%s'.", d)
            endif
        endfor
    endfunction
    call s:initialize_set_up_eskk_directory()
    " }}}

    " Egg like newline {{{
    if !g:eskk#egg_like_newline
        " Default behavior is `egg like newline`.
        " Turns it to `Non egg like newline` during henkan phase.
        call eskk#map#disable_egg_like_newline()
    endif
    " }}}

    " g:eskk#keep_state {{{
    if g:eskk#keep_state
        autocmd eskk InsertEnter * call eskk#map#save_normal_keys()
        autocmd eskk InsertLeave * call eskk#map#restore_normal_keys()
    else
        autocmd eskk InsertLeave * call eskk#disable()
    endif
    " }}}

    " Default mappings - :EskkMap {{{
    call eskk#commands#define()

    EskkMap -type=sticky -unique ;
    EskkMap -type=backspace-key -unique <C-h>
    EskkMap -type=enter-key -unique <CR>
    EskkMap -type=escape-key -unique <Esc>
    EskkMap -type=tab -unique <Tab>

    EskkMap -type=phase:henkan:henkan-key -unique <Space>

    EskkMap -type=phase:okuri:henkan-key -unique <Space>

    EskkMap -type=phase:henkan-select:choose-next -unique <Space>
    EskkMap -type=phase:henkan-select:choose-prev -unique x

    EskkMap -type=phase:henkan-select:next-page -unique <Space>
    EskkMap -type=phase:henkan-select:prev-page -unique x

    EskkMap -type=phase:henkan-select:escape -unique <C-g>

    EskkMap -type=phase:henkan-select:delete-from-dict -unique X

    EskkMap -type=mode:hira:toggle-hankata -unique <C-q>
    EskkMap -type=mode:hira:ctrl-q-key -unique <C-q>
    EskkMap -type=mode:hira:toggle-kata -unique q
    EskkMap -type=mode:hira:q-key -unique q
    EskkMap -type=mode:hira:l-key -unique l
    EskkMap -type=mode:hira:to-ascii -unique l
    EskkMap -type=mode:hira:to-zenei -unique L
    EskkMap -type=mode:hira:to-abbrev -unique /

    EskkMap -type=mode:kata:toggle-hankata -unique <C-q>
    EskkMap -type=mode:kata:ctrl-q-key -unique <C-q>
    EskkMap -type=mode:kata:toggle-kata -unique q
    EskkMap -type=mode:kata:q-key -unique q
    EskkMap -type=mode:kata:l-key -unique l
    EskkMap -type=mode:kata:to-ascii -unique l
    EskkMap -type=mode:kata:to-zenei -unique L
    EskkMap -type=mode:kata:to-abbrev -unique /

    EskkMap -type=mode:hankata:toggle-hankata -unique <C-q>
    EskkMap -type=mode:hankata:ctrl-q-key -unique <C-q>
    EskkMap -type=mode:hankata:toggle-kata -unique q
    EskkMap -type=mode:hankata:q-key -unique q
    EskkMap -type=mode:hankata:l-key -unique l
    EskkMap -type=mode:hankata:to-ascii -unique l
    EskkMap -type=mode:hankata:to-zenei -unique L
    EskkMap -type=mode:hankata:to-abbrev -unique /

    EskkMap -type=mode:ascii:to-hira -unique <C-j>

    EskkMap -type=mode:zenei:to-hira -unique <C-j>

    EskkMap -type=mode:abbrev:henkan-key -unique <Space>

    EskkMap -remap -unique <C-^> <Plug>(eskk:toggle)

    EskkMap -remap <BS> <Plug>(eskk:filter:<C-h>)

    EskkMap -map-if="mode() ==# 'i'" -unique <Esc>
    " silent! EskkMap -map-if="mode() ==# 'i'" -unique <C-c>
    " }}}

    " Map temporary key to keys to use in that mode {{{
    call eskk#register_event(
    \   'enter-mode',
    \   'eskk#map#map_mode_local_keys',
    \   []
    \)
    " }}}

    " Save dictionary if modified {{{
    if g:eskk#auto_save_dictionary_at_exit
        autocmd eskk VimLeavePre * EskkUpdateDictionary
    endif
    " }}}

    " Register builtin-modes. {{{
    function! s:initialize_builtin_modes()
        function! s:set_current_to_begin_pos() "{{{
            call eskk#get_buftable().set_begin_pos('.')
        endfunction "}}}


        " 'ascii' mode {{{
        let dict = {}

        function! dict.filter(stash)
            let this = eskk#get_mode_structure('ascii')
            if eskk#map#is_special_lhs(
            \   a:stash.char, 'mode:ascii:to-hira'
            \)
                call eskk#set_mode('hira')
            else
                if a:stash.char !=# "\<BS>"
                \   && a:stash.char !=# "\<C-h>"
                    if a:stash.char =~# '\w'
                        if !has_key(
                        \   this.temp, 'already_set_for_this_word'
                        \)
                            " Set start col of word.
                            call s:set_current_to_begin_pos()
                            let this.temp.already_set_for_this_word = 1
                        endif
                    else
                        if has_key(
                        \   this.temp, 'already_set_for_this_word'
                        \)
                            unlet this.temp.already_set_for_this_word
                        endif
                    endif
                endif

                if eskk#has_mode_table('ascii')
                    if !has_key(this.temp, 'table')
                        let this.temp.table = eskk#get_mode_table('ascii')
                    endif
                    let a:stash.return = this.temp.table.get_map(
                    \   a:stash.char, a:stash.char
                    \)
                else
                    let a:stash.return = a:stash.char
                endif
            endif
        endfunction

        call eskk#register_mode_structure('ascii', dict)
        " }}}

        " 'zenei' mode {{{
        let dict = {}

        function! dict.filter(stash)
            let this = eskk#get_mode_structure('zenei')
            if eskk#map#is_special_lhs(
            \   a:stash.char, 'mode:zenei:to-hira'
            \)
                call eskk#set_mode('hira')
            else
                if !has_key(this.temp, 'table')
                    let this.temp.table = eskk#get_mode_table('zenei')
                endif
                let a:stash.return = this.temp.table.get_map(
                \   a:stash.char, a:stash.char
                \)
            endif
        endfunction

        call eskk#register_event(
        \   'enter-mode-abbrev',
        \   eskk#util#get_local_func(
        \       'set_current_to_begin_pos',
        \       s:SID_PREFIX
        \   ),
        \   []
        \)

        call eskk#register_mode_structure('zenei', dict)
        " }}}

        " 'hira' mode {{{
        call eskk#register_mode_handler(
        \   'hira',
        \   eskk#util#get_local_func('asym_filter', s:SID_PREFIX)
        \)
        " }}}

        " 'kata' mode {{{
        call eskk#register_mode_handler(
        \   'kata',
        \   eskk#util#get_local_func('asym_filter', s:SID_PREFIX)
        \)
        " }}}

        " 'hankata' mode {{{
        call eskk#register_mode_handler(
        \   'hankata',
        \   eskk#util#get_local_func('asym_filter', s:SID_PREFIX)
        \)
        " }}}

        " 'abbrev' mode {{{
        let dict = {}

        function! dict.filter(stash) "{{{
            let char = a:stash.char
            let buftable = eskk#get_buftable()
            let this = eskk#get_mode_structure('abbrev')
            let buf_str = buftable.get_current_buf_str()
            let phase = buftable.get_henkan_phase()

            " Handle special characters.
            " These characters are handled regardless of current phase.
            if eskk#map#is_special_lhs(char, 'backspace-key')
                if buf_str.rom_str.get() == ''
                    " If backspace-key was pressed at empty string,
                    " leave abbrev mode.
                    " TODO: Back to previous mode?
                    call eskk#set_mode('hira')
                else
                    call buftable.do_backspace(a:stash)
                endif
                return
            elseif eskk#map#is_special_lhs(char, 'enter-key')
                call buftable.do_enter(a:stash)
                call eskk#set_mode('hira')
                return
            else
                " Fall through.
            endif

            " Handle other characters.
            if phase ==# g:eskk#buftable#PHASE_HENKAN
                if eskk#map#is_special_lhs(
                \   char, 'phase:henkan:henkan-key'
                \)
                    call buftable.do_henkan(a:stash)
                else
                    call buf_str.rom_str.append(char)
                endif
            elseif phase ==# g:eskk#buftable#PHASE_HENKAN_SELECT
                if eskk#map#is_special_lhs(
                \   char, 'phase:henkan-select:choose-next'
                \)
                    call buftable.choose_next_candidate(a:stash)
                    return
                elseif eskk#map#is_special_lhs(
                \   char, 'phase:henkan-select:choose-prev'
                \)
                    call buftable.choose_prev_candidate(a:stash)
                    return
                else
                    call buftable.push_kakutei_str(
                    \   buftable.get_display_str(0)
                    \)
                    call buftable.clear_all()
                    call eskk#register_temp_event(
                    \   'filter-redispatch-post',
                    \   'eskk#map#key2char',
                    \   [eskk#map#get_filter_map(a:stash.char)]
                    \)

                    " Leave abbrev mode.
                    " TODO: Back to previous mode?
                    call eskk#set_mode('hira')
                endif
            else
                throw eskk#internal_error(
                \   ['eskk'],
                \   "'abbrev' mode does not support phase " . phase . "."
                \)
            endif
        endfunction "}}}
        function! dict.get_init_phase() "{{{
            return g:eskk#buftable#PHASE_HENKAN
        endfunction "}}}
        function! dict.get_supported_phases() "{{{
            return [
            \   g:eskk#buftable#PHASE_HENKAN,
            \   g:eskk#buftable#PHASE_HENKAN_SELECT,
            \]
        endfunction "}}}

        call eskk#register_event(
        \   'enter-mode-abbrev',
        \   eskk#util#get_local_func(
        \       'set_current_to_begin_pos',
        \       s:SID_PREFIX
        \   ),
        \   []
        \)

        call eskk#register_mode_structure('abbrev', dict)
        " }}}
    endfunction
    call s:initialize_builtin_modes()
    " }}}

    " BufEnter: Map keys if enabled. {{{
    function! s:initialize_map_all_keys_if_enabled()
        if eskk#is_enabled()
            call eskk#map#map_all_keys()
        endif
    endfunction
    autocmd eskk BufEnter * call s:initialize_map_all_keys_if_enabled()
    " }}}

    " BufEnter: Restore global option value of &iminsert, &imsearch {{{
    if !g:eskk#keep_state_beyond_buffer
        execute 'autocmd eskk BufLeave *'
        \   'let [&g:iminsert, &g:imsearch] ='
        \   string([&g:iminsert, &g:imsearch])
    endif
    " }}}

    " InsertEnter: Clear buftable. {{{
    autocmd eskk InsertEnter * call eskk#get_buftable().reset()
    " }}}

    " InsertLeave: g:eskk#convert_at_exact_match {{{
    function! s:clear_real_matched_pairs() "{{{
        if !eskk#is_enabled() || eskk#get_mode() == ''
            return
        endif

        let st = eskk#get_current_mode_structure()
        if has_key(st.temp, 'real_matched_pairs')
            unlet st.temp.real_matched_pairs
        endif
    endfunction "}}}
    autocmd eskk InsertLeave * call s:clear_real_matched_pairs()
    " }}}

    " Event: enter-mode {{{
    call eskk#register_event(
    \   'enter-mode',
    \   'eskk#set_cursor_color',
    \   []
    \)

    function! s:initialize_clear_buftable()
        let buftable = eskk#get_buftable()
        call buftable.clear_all()
    endfunction
    call eskk#register_event(
    \   'enter-mode',
    \   eskk#util#get_local_func(
    \       'initialize_clear_buftable',
    \       s:SID_PREFIX
    \   ),
    \   []
    \)

    function! s:initialize_set_henkan_phase()
        let buftable = eskk#get_buftable()
        call buftable.set_henkan_phase(
        \   (eskk#has_mode_func('get_init_phase') ?
        \       eskk#call_mode_func('get_init_phase', [], 0)
        \       : g:eskk#buftable#PHASE_NORMAL)
        \)
    endfunction
    call eskk#register_event(
    \   'enter-mode',
    \   eskk#util#get_local_func(
    \       'initialize_set_henkan_phase',
    \       s:SID_PREFIX
    \   ),
    \   []
    \)
    " }}}

    " InsertLeave: Restore &backspace value {{{
    " FIXME: Due to current implementation,
    " s:buftable.rewrite() assumes that &backspace contains "eol".
    if &l:backspace !~# '\<eol\>'
        let saved_backspace = &l:backspace
        setlocal backspace+=eol
        autocmd eskk InsertEnter * setlocal backspace+=eol
        execute 'autocmd eskk InsertLeave *'
        \   'let &l:backspace = '.string(saved_backspace)
    endif
    " }}}

    " Check some variables values. {{{
    function! s:initialize_check_variables()
        if g:eskk#marker_henkan ==# g:eskk#marker_popup
            call eskk#util#warn(
            \   'g:eskk#marker_henkan and g:eskk#marker_popup'
            \       . ' must be different.'
            \)
        endif
    endfunction
    call s:initialize_check_variables()
    " }}}

    " Logging event {{{
    if g:eskk#debug
        " Should I create autoload/eskk/log.vim ?
        autocmd eskk CursorHold,VimLeavePre *
        \            call eskk#error#write_debug_log_file()
    endif
    " }}}

    " Create internal mappings. {{{
    call eskk#map#map(
    \   'e',
    \   '<Plug>(eskk:_set_begin_pos)',
    \   '[eskk#get_buftable().set_begin_pos("."), ""][1]',
    \   'ic'
    \)
    call eskk#map#map(
    \   're',
    \   '<Plug>(eskk:_filter_redispatch_pre)',
    \   'join(eskk#throw_event("filter-redispatch-pre"), "")'
    \)
    call eskk#map#map(
    \   're',
    \   '<Plug>(eskk:_filter_redispatch_post)',
    \   'join(eskk#throw_event("filter-redispatch-post"), "")'
    \)
    " }}}

    " Reset s:completed_candidates in autoload/eskk/complete.vim {{{
    " s:completed_candidates should have non-empty value
    " only during insert-mode.
    autocmd eskk InsertLeave *
    \   call eskk#complete#_reset_completed_candidates()
    " }}}

    " Set up s:mode_vs_table. {{{
    function! s:set_up_mode_use_tables() "{{{
        " NOTE: "hira_to_kata" and "kata_to_hira" are not used.
        for [mode, table] in items({
        \   'hira': eskk#table#new_from_file('rom_to_hira'),
        \   'kata': eskk#table#new_from_file('rom_to_kata'),
        \   'zenei': eskk#table#new_from_file('rom_to_zenei'),
        \   'hankata': eskk#table#new_from_file('rom_to_hankata'),
        \})
            call eskk#register_mode_table(mode, table)
        endfor
    endfunction "}}}
    call s:set_up_mode_use_tables()
    " }}}

    " Create "eskk-initialize-post" autocmd event. {{{
    " If no "User eskk-initialize-post" events,
    " Vim complains like "No matching autocommands".
    autocmd eskk User eskk-initialize-post :

    " Throw eskk-initialize-post event.
    doautocmd User eskk-initialize-post
    " }}}

    let s:initialization_state = s:INIT_DONE
endfunction "}}}
function! eskk#is_initialized() "{{{
    return s:initialization_state ==# s:INIT_DONE
endfunction "}}}

" Global variable function
function! eskk#get_default_mapped_keys() "{{{
    return split(
    \   'abcdefghijklmnopqrstuvwxyz'
    \  .'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    \  .'1234567890'
    \  .'!"#$%&''()'
    \  .',./;:]@[-^\'
    \  .'>?_+*}`{=~'
    \   ,
    \   '\zs'
    \) + [
    \   "<lt>",
    \   "<Bar>",
    \   "<Tab>",
    \   "<BS>",
    \   "<C-h>",
    \   "<CR>",
    \   "<Space>",
    \   "<C-q>",
    \   "<C-y>",
    \   "<C-e>",
    \   "<PageUp>",
    \   "<PageDown>",
    \   "<Up>",
    \   "<Down>",
    \   "<C-n>",
    \   "<C-p>",
    \]
endfunction "}}}

" Enable/Disable IM
function! eskk#is_enabled() "{{{
    return eskk#is_initialized()
    \   && eskk#get_current_instance().enabled
endfunction "}}}
function! eskk#enable(...) "{{{
    if !eskk#is_initialized()
        echohl WarningMsg
        echomsg 'eskk is not initialized.'
        echohl None
        return ''
    endif

    let inst = eskk#get_current_instance()
    let do_map = a:0 != 0 ? a:1 : 1

    if eskk#is_enabled()
        return ''
    endif

    if mode() ==# 'c'
        let &l:iminsert = 1
    endif

    call eskk#throw_event('enable-im')

    " Clear current variable states.
    let inst.mode = ''
    call eskk#get_buftable().reset()

    " Set up Mappings.
    if do_map
        call eskk#map#map_all_keys()
    endif

    call eskk#set_mode(g:eskk#initial_mode)

    " If skk.vim exists and enabled, disable it.
    let disable_skk_vim = ''
    if exists('g:skk_version') && exists('b:skk_on') && b:skk_on
        let disable_skk_vim = substitute(SkkDisable(), "\<C-^>", '', '')
    endif

    if g:eskk#enable_completion
        let inst.omnifunc_save = &l:omnifunc
        let &l:omnifunc = 'eskk#complete#eskkcomplete'
    endif

    let inst.enabled = 1
    if mode() =~# '^[ic]$'
        return disable_skk_vim . "\<C-^>"
    else
        return s:enable_im()
    endif
endfunction "}}}
function! eskk#disable() "{{{
    if !eskk#is_initialized()
        echohl WarningMsg
        echomsg 'eskk is not initialized.'
        echohl None
        return ''
    endif

    let inst = eskk#get_current_instance()
    let do_unmap = a:0 != 0 ? a:1 : 0

    if !eskk#is_enabled()
        return ''
    endif

    if mode() ==# 'c'
        return "\<C-^>"
    endif

    call eskk#throw_event('disable-im')

    if do_unmap
        call eskk#map#unmap_all_keys()
    endif

    if g:eskk#enable_completion && has_key(inst, 'omnifunc_save')
        let &l:omnifunc = inst.omnifunc_save
    endif

    call eskk#unlock_neocomplcache()

    let inst.enabled = 0

    if mode() =~# '^[ic]$'
        let buftable = eskk#get_buftable()
        return buftable.generate_kakutei_str() . "\<C-^>"
    else
        return s:disable_im()
    endif
endfunction "}}}
function! eskk#toggle() "{{{
    if !eskk#is_initialized()
        echohl WarningMsg
        echomsg 'eskk is not initialized.'
        echohl None
        return ''
    endif
    return eskk#{eskk#is_enabled() ? 'disable' : 'enable'}()
endfunction "}}}
function! s:enable_im() "{{{
    let &l:iminsert = s:map_exists_mode_of('l') ? 1 : 2
    let &l:imsearch = &l:iminsert
    
    return ''
endfunction "}}}
function! s:map_exists_mode_of(mode) "{{{
    let out = eskk#util#redir_english(a:mode . 'map')
    return index(split(out, '\n'), 'No mapping found') ==# -1
endfunction "}}}
function! s:disable_im() "{{{
    let &l:iminsert = 0
    let &l:imsearch = 0
    
    return ''
endfunction "}}}

" Mode
function! eskk#set_mode(next_mode) "{{{
    let inst = eskk#get_current_instance()
    if !eskk#is_supported_mode(a:next_mode)
        call eskk#error#log(
        \   "mode '" . a:next_mode . "' is not supported."
        \)
        call eskk#error#log(
        \   's:available_modes = ' . string(s:available_modes)
        \)
        return
    endif

    call eskk#throw_event('leave-mode-' . inst.mode)
    call eskk#throw_event('leave-mode')

    " Change mode.
    let prev_mode = inst.mode
    let inst.mode = a:next_mode

    call eskk#throw_event('enter-mode-' . inst.mode)
    call eskk#throw_event('enter-mode')

    " For &statusline.
    redrawstatus
endfunction "}}}
function! eskk#get_mode() "{{{
    let inst = eskk#get_current_instance()
    return inst.mode
endfunction "}}}
function! eskk#is_supported_mode(mode) "{{{
    return has_key(s:available_modes, a:mode)
endfunction "}}}
function! eskk#register_mode_structure(mode, st) "{{{
    if s:check_mode_structure(a:st)
        let s:available_modes[a:mode] = a:st
        let s:available_modes[a:mode].temp = {}
    endif
endfunction "}}}
function! eskk#register_mode_handler(mode, handler) "{{{
    " even if a:handler does not have "dict" attribute,
    " Vim does not complain with calling a:handler
    " with dict like `call(a:handler, [], {})`.
    " cf. eskk#call_mode_func()
    return eskk#register_mode_structure(a:mode, {'filter': a:handler})
endfunction "}}}
function! s:check_mode_structure(st) "{{{
    " 'temp' will be added by eskk#register_mode_structure().
    for key in ['filter'] " + ['temp']
        if !has_key(a:st, key)
            call eskk#util#warn(
            \   "s:check_mode_structure(" . string(a:mode) . "): "
            \       . string(key) . " is not present in structure"
            \)
            return 0
        endif
    endfor
    return 1
endfunction "}}}
function! eskk#get_current_mode_structure() "{{{
    return eskk#get_mode_structure(eskk#get_mode())
endfunction "}}}
function! eskk#get_mode_structure(mode) "{{{
    let inst = eskk#get_current_instance()
    if !eskk#is_supported_mode(a:mode)
        call eskk#util#warn(
        \   "mode '" . a:mode . "' is not available."
        \)
    endif
    return s:available_modes[a:mode]
endfunction "}}}
function! eskk#has_mode_func(func_key) "{{{
    let inst = eskk#get_current_instance()
    let st = eskk#get_mode_structure(inst.mode)
    return has_key(st, a:func_key)
endfunction "}}}
function! eskk#call_mode_func(func_key, args, required) "{{{
    let inst = eskk#get_current_instance()
    let st = eskk#get_mode_structure(inst.mode)
    if !has_key(st, a:func_key)
        if a:required
            throw eskk#internal_error(
            \   ['eskk'],
            \   "Mode '" . inst.mode . "' does not have"
            \       . " required function key"
            \)
        endif
        return
    endif
    return call(st[a:func_key], a:args, st)
endfunction "}}}

" Mode/Table
function! eskk#has_current_mode_table() "{{{
    return eskk#has_mode_table(eskk#get_mode())
endfunction "}}}
function! eskk#has_mode_table(mode) "{{{
    return has_key(s:mode_vs_table, a:mode)
endfunction "}}}
function! eskk#get_current_mode_table() "{{{
    return eskk#get_mode_table(eskk#get_mode())
endfunction "}}}
function! eskk#get_mode_table(mode) "{{{
    return s:mode_vs_table[a:mode]
endfunction "}}}

" Table
function! eskk#has_table(table_name) "{{{
    return has_key(s:table_defs, a:table_name)
endfunction "}}}
function! eskk#get_all_registered_tables() "{{{
    return keys(s:table_defs)
endfunction "}}}
function! eskk#get_table(name) "{{{
    return s:table_defs[a:name]
endfunction "}}}
function! eskk#register_table(table) "{{{
    for base in a:table.get_base_tables()
        call eskk#register_table(base)
    endfor
    " eskk#register_table() MUST NOT allow to overwrite
    " already registered tables.
    " because it is harmful to be able to
    " rewrite base (derived) tables. (what will happen? I don't know)
    let name = a:table.get_name()
    if !has_key(s:table_defs, name)
        let s:table_defs[name] = a:table
    endif
endfunction "}}}
function! eskk#register_mode_table(mode, table) "{{{
    if !has_key(s:mode_vs_table, a:mode)
        call eskk#register_table(a:table)
        let s:mode_vs_table[a:mode] = a:table
    endif
endfunction "}}}

" Statusline
function! eskk#statusline(...) "{{{
    return eskk#is_enabled()
    \      ? printf(get(a:000, 0, '[eskk:%s]'),
    \               get(g:eskk#statusline_mode_strings,
    \                   eskk#get_current_instance().mode, '??'))
    \      : get(a:000, 1, '')
endfunction "}}}

" Dictionary
function! eskk#get_skk_dict() "{{{
    if empty(s:skk_dict)
        let s:skk_dict = eskk#dictionary#new(
        \   g:eskk#dictionary, g:eskk#large_dictionary
        \)
    endif
    return s:skk_dict
endfunction "}}}

" Buftable
function! eskk#get_buftable() "{{{
    let inst = eskk#get_current_instance()
    if empty(inst.buftable)
        let inst.buftable = eskk#buftable#new()
    endif
    return inst.buftable
endfunction "}}}
function! eskk#set_buftable(buftable) "{{{
    let inst = eskk#get_current_instance()
    call a:buftable.set_old_str(
    \   empty(inst.buftable) ? '' : inst.buftable.get_old_str()
    \)
    let inst.buftable = a:buftable
endfunction "}}}

" Event
function! eskk#register_event(event_names, Fn, head_args, ...) "{{{
    return s:register_event(
    \   s:event_hook_fn,
    \   a:event_names,
    \   a:Fn,
    \   a:head_args,
    \   (a:0 ? a:1 : -1)
    \)
endfunction "}}}
function! eskk#register_temp_event(event_names, Fn, head_args, ...) "{{{
    let inst = eskk#get_current_instance()
    return s:register_event(
    \   inst.temp_event_hook_fn,
    \   a:event_names,
    \   a:Fn,
    \   a:head_args,
    \   (a:0 ? a:1 : -1)
    \)
endfunction "}}}
function! s:register_event(st, event_names, Fn, head_args, inst) "{{{
    let event_names = type(a:event_names) == type([]) ?
    \                   a:event_names : [a:event_names]
    for name in event_names
        if !has_key(a:st, name)
            let a:st[name] = []
        endif
        call add(
        \   a:st[name],
        \   [a:Fn, a:head_args]
        \       + (type(a:inst) == type({}) ? [a:inst] : [])
        \)
    endfor
endfunction "}}}
function! eskk#throw_event(event_name) "{{{
    let inst = eskk#get_current_instance()
    let ret        = []
    let event      = get(s:event_hook_fn, a:event_name, [])
    let temp_event = get(inst.temp_event_hook_fn, a:event_name, [])
    let all_events = event + temp_event
    if empty(all_events)
        return []
    endif

    while !empty(all_events)
        call add(ret, call('call', remove(all_events, 0)))
    endwhile

    " Clear temporary hooks.
    let inst.temp_event_hook_fn[a:event_name] = []

    return ret
endfunction "}}}
function! eskk#has_event(event_name) "{{{
    let inst = eskk#get_current_instance()
    return
    \   !empty(get(s:event_hook_fn, a:event_name, []))
    \   || !empty(get(inst.temp_event_hook_fn, a:event_name, []))
endfunction "}}}

" Locking diff old string
function! eskk#lock_old_str() "{{{
    let inst = eskk#get_current_instance()
    let inst.has_locked_old_str = 1
endfunction "}}}
function! eskk#unlock_old_str() "{{{
    let inst = eskk#get_current_instance()
    let inst.has_locked_old_str = 0
endfunction "}}}

" Filter
function! eskk#filter(char) "{{{
    let inst = eskk#get_current_instance()

    " Check irregular circumstance.
    if !eskk#is_supported_mode(inst.mode)
        call eskk#error#write_error_log_file(
        \   a:char,
        \   eskk#error#build_error(
        \       ['eskk'],
        \       ['current mode is not supported: '
        \           . string(inst.mode)]
        \   )
        \)
        return a:char
    endif


    call eskk#throw_event('filter-begin')

    let buftable = eskk#get_buftable()
    let stash = {
    \   'char': a:char,
    \   'return': 0,
    \}

    if !inst.has_locked_old_str
        call buftable.set_old_str(buftable.get_display_str())
    endif

    try
        let do_filter = 1
        if g:eskk#enable_completion && pumvisible()
            try
                let do_filter = eskk#complete#handle_special_key(stash)
            catch
                call eskk#error#log_exception(
                \   'eskk#complete#handle_special_key()'
                \)
            endtry
        endif

        if do_filter
            call eskk#call_mode_func('filter', [stash], 1)
        endif
        return s:rewrite_string(stash.return)

    catch
        call eskk#error#write_error_log_file(a:char)
        return a:char

    finally
        call eskk#throw_event('filter-finalize')
    endtry
endfunction "}}}
function! s:rewrite_string(return_string) "{{{
    let redispatch_pre = ''
    if eskk#has_event('filter-redispatch-pre')
        let redispatch_pre =
        \   "\<Plug>(eskk:_filter_redispatch_pre)"
    endif

    let redispatch_post = ''
    if eskk#has_event('filter-redispatch-post')
        let redispatch_post =
        \   "\<Plug>(eskk:_filter_redispatch_post)"
    endif

    if type(a:return_string) == type("")
        let buf_inst = eskk#get_buffer_instance()
        let buf_inst.return_string = a:return_string
        call eskk#map#map(
        \   'be',
        \   '<Plug>(eskk:expr:_return_string)',
        \   'eskk#get_buffer_instance().return_string'
        \)
        let string = "\<Plug>(eskk:expr:_return_string)"
    else
        let string = eskk#get_buftable().rewrite()
    endif
    return
    \   redispatch_pre
    \   . string
    \   . redispatch_post
endfunction "}}}

" g:eskk#use_color_cursor
function! eskk#set_cursor_color() "{{{
    " From s:SkkSetCursorColor() of skk.vim

    if !has('gui_running') || !g:eskk#use_color_cursor
        return
    endif

    let eskk_mode = eskk#get_mode()
    if !has_key(g:eskk#cursor_color, eskk_mode)
        return
    endif

    let color = g:eskk#cursor_color[eskk_mode]
    if type(color) == type([]) && len(color) >= 2
        execute 'highlight lCursor guibg=' . color[&background ==# 'light' ? 0 : 1]
    elseif type(color) == type("") && color != ''
        execute 'highlight lCursor guibg=' . color
    endif
endfunction "}}}

" Mapping
function! eskk#_get_eskk_mappings() "{{{
    return s:eskk_mappings
endfunction "}}}

" Misc.
function! eskk#unlock_neocomplcache() "{{{
    if eskk#is_neocomplcache_locked()
        NeoComplCacheUnlock
    endif
endfunction "}}}
function! eskk#is_neocomplcache_locked() "{{{
    return
    \   g:eskk#enable_completion
    \   && exists('g:loaded_neocomplcache')
    \   && exists(':NeoComplCacheUnlock')
    \   && neocomplcache#is_locked()
endfunction "}}}

" Exceptions
function! eskk#internal_error(from, ...) "{{{
    return eskk#error#build_error(a:from, ['internal error'] + a:000)
endfunction "}}}

call eskk#_initialize()

" To indicate that eskk has been loaded.
" Avoid many many autoload bugs, use plain global variable here.
let g:loaded_autoload_eskk = 1


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Global Variables {{{

let g:eskk#version = str2nr(printf('%2d%02d%03d', 0, 4, 45))

" Debug
if !exists('g:eskk#debug')
    let g:eskk#debug = 0
endif

if !exists('g:eskk#debug_wait_ms')
    let g:eskk#debug_wait_ms = 0
endif

if !exists('g:eskk#debug_stdout')
    let g:eskk#debug_stdout = "file"
endif

if !exists('g:eskk#directory')
    let g:eskk#directory = '~/.eskk'
endif

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

if !exists("g:eskk#backup_dictionary")
    let g:eskk#backup_dictionary = g:eskk#dictionary.path . ".BAK"
endif

if !exists("g:eskk#auto_save_dictionary_at_exit")
    let g:eskk#auto_save_dictionary_at_exit = 1
endif

" Henkan
if !exists("g:eskk#select_cand_keys")
  let g:eskk#select_cand_keys = "asdfjkl"
endif

if !exists("g:eskk#show_candidates_count")
  let g:eskk#show_candidates_count = 4
endif

if !exists("g:eskk#kata_convert_to_hira_at_henkan")
  let g:eskk#kata_convert_to_hira_at_henkan = 1
endif

if !exists("g:eskk#kata_convert_to_hira_at_completion")
  let g:eskk#kata_convert_to_hira_at_completion = 1
endif

if !exists("g:eskk#show_annotation")
  let g:eskk#show_annotation = 0
endif

" Mappings
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
if !exists('g:eskk#mapped_keys')
    let g:eskk#mapped_keys = eskk#get_default_mapped_keys()
endif

" Mode
if !exists('g:eskk#initial_mode')
    let g:eskk#initial_mode = 'hira'
endif

if !exists('g:eskk#statusline_mode_strings')
    let g:eskk#statusline_mode_strings =  {'hira': 'あ', 'kata': 'ア', 'ascii': 'aA', 'zenei': 'ａ', 'hankata': 'ｧｱ', 'abbrev': 'aあ'}
endif

function! s:set_up_mode_use_tables() "{{{
    " NOTE: "hira_to_kata" and "kata_to_hira" are not used.
    let default = {
    \   'hira': eskk#table#create_from_file('rom_to_hira'),
    \   'kata': eskk#table#create_from_file('rom_to_kata'),
    \   'zenei': eskk#table#create_from_file('rom_to_zenei'),
    \   'hankata': eskk#table#create_from_file('rom_to_hankata'),
    \}

    if !exists('g:eskk#mode_use_tables')
        let g:eskk#mode_use_tables =  default
    else
        call extend(g:eskk#mode_use_tables, default, 'keep')
    endif
endfunction "}}}
call s:set_up_mode_use_tables()

" Table
if !exists('g:eskk#cache_table_map')
    let g:eskk#cache_table_map = 1
endif

if !exists('g:eskk#cache_table_candidates')
    let g:eskk#cache_table_candidates = 1
endif

" Markers
if !exists("g:eskk#marker_henkan")
    let g:eskk#marker_henkan = '▽'
endif

if !exists("g:eskk#marker_okuri")
    let g:eskk#marker_okuri = '*'
endif

if !exists("g:eskk#marker_henkan_select")
    let g:eskk#marker_henkan_select = '▼'
endif

if !exists("g:eskk#marker_jisyo_touroku")
    let g:eskk#marker_jisyo_touroku = '?'
endif

if !exists("g:eskk#marker_popup")
    let g:eskk#marker_popup = '#'
endif

" Completion
if !exists('g:eskk#enable_completion')
    let g:eskk#enable_completion = 1
endif

if !exists('g:eskk#max_candidates')
    let g:eskk#max_candidates = 30
endif

" Cursor color
if !exists('g:eskk#use_color_cursor')
    let g:eskk#use_color_cursor = 1
endif

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
if !exists("g:eskk#egg_like_newline")
    let g:eskk#egg_like_newline = 0
endif

if !exists("g:eskk#keep_state")
    let g:eskk#keep_state = 0
endif

if !exists('g:eskk#keep_state_beyond_buffer')
    let g:eskk#keep_state_beyond_buffer = 0
endif

if !exists("g:eskk#revert_henkan_style")
    let g:eskk#revert_henkan_style = 'okuri'
endif

if !exists("g:eskk#delete_implies_kakutei")
    let g:eskk#delete_implies_kakutei = 0
endif

if !exists("g:eskk#rom_input_style")
    let g:eskk#rom_input_style = 'skk'
endif

if !exists("g:eskk#auto_henkan_at_okuri_match")
    let g:eskk#auto_henkan_at_okuri_match = 1
endif

if !exists("g:eskk#set_undo_point")
    let g:eskk#set_undo_point = {
    \   'sticky': 1,
    \   'kakutei': 1,
    \}
endif

if !exists("g:eskk#context_control")
    let g:eskk#context_control = []
endif

if !exists("g:eskk#fix_extra_okuri")
    let g:eskk#fix_extra_okuri = 1
endif

if !exists('g:eskk#ignore_continuous_sticky')
    let g:eskk#ignore_continuous_sticky = 1
endif

if !exists('g:eskk#convert_at_exact_match')
    let g:eskk#convert_at_exact_match = 0
endif

" }}}


function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID



" Variables {{{

" mode:
"   Current mode.
" buftable:
"   Buffer strings for inserted, filtered and so on.
" is_locked_old_str:
"   Lock current diff old string?
" temp_event_hook_fn:
"   Temporary event handler functions/arguments.
" enabled:
"   True if s:eskk.enable() is called.
" enabled_mode:
"   Vim's mode() return value when calling eskk#enable().
" mutable_stash:
"   Stash for instance-local variables. See `s:mutable_stash`.
" has_started_completion:
"   completion has been started from eskk.
let s:eskk = {
\   'mode': '',
\   'buftable': {},
\   'is_locked_old_str': 0,
\   'temp_event_hook_fn': {},
\   'enabled': 0,
\   'mutable_stash': {},
\   'has_started_completion': 0,
\   'prev_im_options': {},
\   'prev_normal_keys': {},
\   'completion_selected': 0,
\   'completion_inserted': 0,
\}



" NOTE: Following variables are non-local (global) between instances.

" Supported modes and their structures.
let s:available_modes = {}
" Event handler functions/arguments.
let s:event_hook_fn = {}
" For eskk#register_map(), eskk#unregister_map().
let s:key_handler = {}
" Global values of &iminsert, &imsearch.
let s:saved_im_options = []
" Global values of &backspace.
let s:saved_backspace = -1
" Flag for `s:initialize()`.
let s:is_initialized = 0
" Last command's string. See eskk#jump_one_char().
let s:last_jump_cmd = -1
let s:last_jump_char = -1
" SKK Dictionary (singleton)
let s:skk_dict = {}
" Cached table instances.
" Tables are created by eskk#create_table().
let s:cached_tables = {}
" Cached table mappings.
" See eskk#_get_cached_maps() and `autoload/eskk/table.vim`.
let s:cached_maps = {}
let s:cached_candidates = {}
" All tables structures.
let s:table_defs = {}
" }}}



function! eskk#load() "{{{
    runtime! plugin/eskk.vim
endfunction "}}}



" Instance
function! s:eskk_new() "{{{
    return deepcopy(s:eskk, 1)
endfunction "}}}
function! s:get_inst_namespace() "{{{
    return g:eskk#keep_state_beyond_buffer ? s: : b:
endfunction "}}}
function! s:exists_instance() "{{{
    let scope = g:eskk#keep_state_beyond_buffer ? 's:' : 'b:'
    return exists(scope . 'eskk_instances')
endfunction "}}}
function! eskk#get_current_instance() "{{{
    let ns = s:get_inst_namespace()
    if !s:exists_instance()
        let ns.eskk_instances = [s:eskk_new()]
        " Index number for current instance.
        let ns.eskk_instance_id = 0
    endif
    return ns.eskk_instances[ns.eskk_instance_id]
endfunction "}}}
function! eskk#create_new_instance() "{{{
    " TODO: CoW

    " Create instance.
    let inst = s:eskk_new()
    let ns = s:get_inst_namespace()
    call add(ns.eskk_instances, inst)
    let ns.eskk_instance_id += 1

    " Initialize instance.
    call eskk#enable(0)

    return inst
endfunction "}}}
function! eskk#destroy_current_instance() "{{{
    let ns = s:get_inst_namespace()

    if ns.eskk_instance_id == 0
        throw eskk#internal_error(['eskk'], "No more instances.")
    endif

    " Destroy current instance.
    call remove(ns.eskk_instances, ns.eskk_instance_id)
    let ns.eskk_instance_id -= 1
endfunction "}}}

" s:mutable_stash "{{{
let s:mutable_stash = {}

" Same structure as `s:eskk.mutable_stash`,
" but this is set by `s:mutable_stash.init()`.
let s:stash_prototype = {}


" Constructor
function! eskk#get_mutable_stash(namespace) "{{{
    let obj = deepcopy(s:mutable_stash, 1)
    let obj.namespace = join(a:namespace, '-')
    return obj
endfunction "}}}


" This a:value will be set when new eskk instances are created.
function! s:mutable_stash.init(varname, value) "{{{
    if !has_key(s:stash_prototype, self.namespace)
        let s:stash_prototype[self.namespace] = {}
    endif

    if !has_key(s:stash_prototype[self.namespace], a:varname)
        let s:stash_prototype[self.namespace][a:varname] = a:value
    else
        throw eskk#internal_error(['eskk'])
    endif
endfunction "}}}

function! s:mutable_stash.get(varname) "{{{
    let inst = eskk#get_current_instance()
    if !has_key(inst.mutable_stash, self.namespace)
        let inst.mutable_stash[self.namespace] = {}
    endif

    if has_key(inst.mutable_stash[self.namespace], a:varname)
        return inst.mutable_stash[self.namespace][a:varname]
    else
        " Find prototype for this variable.
        " These prototypes are set by `s:mutable_stash.init()`.
        if !has_key(s:stash_prototype, self.namespace)
            let s:stash_prototype[self.namespace] = {}
        endif

        if has_key(s:stash_prototype[self.namespace], a:varname)
            return s:stash_prototype[self.namespace][a:varname]
        else
            " No more stash.
            throw eskk#internal_error(['eskk'])
        endif
    endif
endfunction "}}}

function! s:mutable_stash.set(varname, value) "{{{
    let inst = eskk#get_current_instance()
    if !has_key(inst.mutable_stash, self.namespace)
        let inst.mutable_stash[self.namespace] = {}
    endif

    let inst.mutable_stash[self.namespace][a:varname] = a:value
endfunction "}}}
" }}}

" Filter
" s:asym_filter {{{
let s:asym_filter = {'table': {}}

function! eskk#create_asym_filter(table_name) "{{{
    let obj = deepcopy(s:asym_filter)
    let obj.table = eskk#create_table(a:table_name)
    return obj
endfunction "}}}

function! s:asym_filter.filter(stash) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let phase = a:stash.phase


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
        if eskk#mappings#handle_special_lhs(char, key, a:stash)
            " Handled.
            return
        endif
    endfor


    " In order not to change current buftable old string.
    call eskk#lock_old_str()
    try
        " Handle special characters.
        " These characters are handled regardless of current phase.
        if eskk#mappings#is_special_lhs(char, 'backspace-key')
            call buftable.do_backspace(a:stash)
            return
        elseif eskk#mappings#is_special_lhs(char, 'enter-key')
            call buftable.do_enter(a:stash)
            return
        elseif eskk#mappings#is_special_lhs(char, 'sticky')
            call buftable.do_sticky(a:stash)
            return
        elseif char =~# '^[A-Z]$'
            if !eskk#mappings#is_special_lhs(
            \   char, 'phase:henkan-select:delete-from-dict'
            \)
                call buftable.do_sticky(a:stash)
                call eskk#register_temp_event(
                \   'filter-redispatch-post',
                \   'eskk#util#key2char',
                \   [eskk#mappings#get_filter_map(tolower(char))]
                \)
                return
            endif
        elseif eskk#mappings#is_special_lhs(char, 'escape-key')
            call buftable.do_escape(a:stash)
            return
        elseif eskk#mappings#is_special_lhs(char, 'tab')
            call buftable.do_tab(a:stash)
            return
        else
            " Fall through.
        endif
    finally
        call eskk#unlock_old_str()
    endtry


    " Handle other characters.
    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        return s:filter_rom(a:stash, self.table)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        if eskk#mappings#is_special_lhs(char, 'phase:henkan:henkan-key')
            call buftable.do_henkan(a:stash)
        else
            return s:filter_rom(a:stash, self.table)
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        if eskk#mappings#is_special_lhs(char, 'phase:okuri:henkan-key')
            call buftable.do_henkan(a:stash)
        else
            return s:filter_rom(a:stash, self.table)
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        if eskk#mappings#is_special_lhs(
        \   char, 'phase:henkan-select:choose-next'
        \)
            call buftable.choose_next_candidate(a:stash)
            return
        elseif eskk#mappings#is_special_lhs(
        \   char, 'phase:henkan-select:choose-prev'
        \)
            call buftable.choose_prev_candidate(a:stash)
            return
        elseif eskk#mappings#is_special_lhs(
        \   char, 'phase:henkan-select:delete-from-dict'
        \)
            let henkan_result = eskk#get_skk_dict().get_henkan_result()
            if !empty(henkan_result)
                call henkan_result.delete_from_dict()

                call buftable.push_kakutei_str(buftable.get_display_str(0))
                call buftable.set_henkan_phase(
                \   g:eskk#buftable#HENKAN_PHASE_NORMAL
                \)
            endif
        else
            call buftable.do_enter(a:stash)
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#key2char',
            \   [eskk#mappings#get_filter_map(a:stash.char)]
            \)
        endif
    else
        throw eskk#internal_error(
        \   ['eskk'],
        \   "s:asym_filter.filter() does not support phase " . phase . "."
        \)
    endif
endfunction "}}}

function! s:filter_rom(stash, table) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let buf_str = a:stash.buf_str
    let rom_str = buf_str.get_rom_str() . char
    let match_exactly  = a:table.has_map(rom_str)
    let candidates     = a:table.get_candidates(rom_str, 2, [])

    if match_exactly
        call eskk#util#assert(!empty(candidates))
    endif

    if match_exactly && len(candidates) == 1
        " Match!
        return s:filter_rom_exact_match(a:stash, a:table)

    elseif !empty(candidates)
        " Has candidates but not match.
        return s:filter_rom_has_candidates(a:stash)

    else
        " No candidates.
        return s:filter_rom_no_match(a:stash, a:table)
    endif
endfunction "}}}
function! s:filter_rom_exact_match(stash, table) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let buf_str = a:stash.buf_str
    let rom_str = buf_str.get_rom_str() . char
    let phase = a:stash.phase

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   || phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        " Set filtered string.
        call buf_str.push_matched(rom_str, a:table.get_map(rom_str))
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
            "     eskk#mappings#get_filter_map(char)
            " should
            "     eskk#mappings#get_filter_map(eskk#util#uneval_key(char))
            for rest_char in split(rest, '\zs')
                call eskk#register_temp_event(
                \   'filter-redispatch-post',
                \   'eskk#util#key2char',
                \   [eskk#mappings#get_filter_map(rest_char)]
                \)
            endfor
        endif


        call eskk#register_temp_event(
        \   'filter-begin',
        \   eskk#util#get_local_func('clear_buffer_string', s:SID_PREFIX),
        \   [g:eskk#buftable#HENKAN_PHASE_NORMAL]
        \)

        if g:eskk#convert_at_exact_match
        \   && phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
            let st = eskk#get_current_mode_structure()
            let henkan_buf_str = buftable.get_buf_str(
            \   g:eskk#buftable#HENKAN_PHASE_HENKAN
            \)
            if has_key(st.sandbox, 'real_matched_pairs')
                " Restore previous hiragana & push current to the tail.
                let p = henkan_buf_str.pop_matched()
                call henkan_buf_str.set_multiple_matched(
                \   st.sandbox.real_matched_pairs + [p]
                \)
            endif
            let st.sandbox.real_matched_pairs = henkan_buf_str.get_matched()

            call buftable.do_henkan(a:stash, 1)
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
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
        \   g:eskk#buftable#HENKAN_PHASE_HENKAN
        \)
        let okuri_buf_str = buftable.get_buf_str(
        \   g:eskk#buftable#HENKAN_PHASE_OKURI
        \)
        let henkan_select_buf_str = buftable.get_buf_str(
        \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        \)
        let henkan_rom = henkan_buf_str.get_rom_str()
        let okuri_rom  = okuri_buf_str.get_rom_str()
        if henkan_rom != '' && a:table.has_map(henkan_rom . okuri_rom[0])
            " Push "っ".
            let match_rom = henkan_rom . okuri_rom[0]
            call henkan_buf_str.push_matched(
            \   match_rom,
            \   a:table.get_map(match_rom)
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

        let has_rest = 0
        if a:table.has_map(okuri_buf_str.get_rom_str())
            call okuri_buf_str.push_matched(
            \   okuri_buf_str.get_rom_str(),
            \   a:table.get_map(okuri_buf_str.get_rom_str())
            \)
            let rest = a:table.get_rest(okuri_buf_str.get_rom_str(), -1)
            if rest !=# -1
                " XXX:
                "     eskk#mappings#get_filter_map(char)
                " should
                "     eskk#mappings#get_filter_map(eskk#util#uneval_key(char))
                for rest_char in split(rest, '\zs')
                    call eskk#register_temp_event(
                    \   'filter-redispatch-post',
                    \   'eskk#util#key2char',
                    \   [eskk#mappings#get_filter_map(rest_char)]
                    \)
                endfor
                let has_rest = 1
            endif
        endif

        call okuri_buf_str.clear_rom_str()

        let matched = okuri_buf_str.get_matched()
        call eskk#util#assert(!empty(matched))
        " TODO `len(matched) == 1`: Do henkan at only the first time.

        if !has_rest && g:eskk#auto_henkan_at_okuri_match
            call buftable.do_henkan(a:stash)
        endif
    endif
endfunction "}}}
function! s:filter_rom_has_candidates(stash) "{{{
    " NOTE: This will be run in all phases.
    call a:stash.buf_str.push_rom_str(a:stash.char)
endfunction "}}}
function! s:filter_rom_no_match(stash, table) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let buf_str = a:stash.buf_str
    let rom_str_without_char = buf_str.get_rom_str()
    let rom_str = rom_str_without_char . char

    let [matched_map_list, rest] =
    \   s:get_matched_and_rest(a:table, rom_str, 1)
    if empty(matched_map_list)
        if g:eskk#rom_input_style ==# 'skk'
            if rest ==# char
                let a:stash.return = char
            else
                let rest = strpart(rest, 0, strlen(rest) - 2) . char
                call buf_str.set_rom_str(rest)
            endif
        else
            let [matched_map_list, head_no_match] =
            \   s:get_matched_and_rest(a:table, rom_str, 0)
            if empty(matched_map_list)
                call buf_str.set_rom_str(head_no_match)
            else
                for char in split(head_no_match, '\zs')
                    call buf_str.push_matched(char, char)
                endfor
                for matched in matched_map_list
                    if a:table.has_rest(matched)
                        call eskk#register_temp_event(
                        \   'filter-redispatch-post',
                        \   'eskk#util#key2char',
                        \   [eskk#mappings#get_filter_map(
                        \       a:table.get_rest(matched)
                        \   )]
                        \)
                    endif
                    call buf_str.push_matched(
                    \   matched, a:table.get_map(matched)
                    \)
                endfor
                call buf_str.clear_rom_str()
            endif
        endif
    else
        for matched in matched_map_list
            call buf_str.push_matched(matched, a:table.get_map(matched))
        endfor
        call buf_str.set_rom_str(rest)
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
        let list = s:generate_map_list(rest, a:tail)
        for str in list
            let counter += 1
            if a:table.has_map(str)
                let has_map_str = str
                break
            endif
        endfor
        if has_map_str ==# -1
            return [matched, rest]
        endif
        call add(matched, has_map_str)
        if a:tail
            " Delete first `has_map_str` bytes.
            let rest = strpart(rest, strlen(has_map_str))
        else
            " Delete last `has_map_str` bytes.
            let rest = strpart(rest, 0, strlen(rest) - strlen(has_map_str))
        endif
    endwhile
endfunction "}}}
" Clear filtered string when eskk#filter()'s finalizing.
function! s:clear_buffer_string(phase) "{{{
    let buftable = eskk#get_buftable()
    if buftable.get_henkan_phase() ==# a:phase
        let buf_str = buftable.get_current_buf_str()
        call buf_str.clear_matched()
    endif
endfunction "}}}

" }}}

" Initialization
function! s:initialize() "{{{
    " Set up g:eskk#directory. {{{
    function! s:initialize_set_up_eskk_directory()
        let dir = expand(g:eskk#directory)
        for d in [dir, eskk#util#join_path(dir, 'log')]
            if !isdirectory(d) && !eskk#util#mkdir_nothrow(d)
                call eskk#util#logf("can't create directory '%s'.", d)
            endif
        endfor
    endfunction
    call s:initialize_set_up_eskk_directory()
    " }}}

    " Create eskk augroup. {{{
    augroup eskk
        autocmd!
    augroup END
    " }}}

    " Egg-like-newline {{{
    function! s:do_lmap_non_egg_like_newline(do_map) "{{{
        if a:do_map
            if !eskk#mappings#has_temp_key('<CR>')
                call eskk#mappings#set_up_temp_key(
                \   '<CR>',
                \   '<Plug>(eskk:filter:<CR>)<Plug>(eskk:filter:<CR>)'
                \)
            endif
        else
            call eskk#register_temp_event(
            \   'filter-begin',
            \   'eskk#mappings#set_up_temp_key_restore',
            \   ['<CR>']
            \)
        endif
    endfunction "}}}
    if !g:eskk#egg_like_newline
        " Default behavior is `egg like newline`.
        " Turns it to `Non egg like newline` during henkan phase.
        call eskk#register_event(
        \   [
        \       'enter-phase-henkan',
        \       'enter-phase-okuri',
        \       'enter-phase-henkan-select'
        \   ],
        \   eskk#util#get_local_func(
        \       'do_lmap_non_egg_like_newline',
        \       s:SID_PREFIX
        \   ),
        \   [1]
        \)
        call eskk#register_event(
        \   'enter-phase-normal',
        \   eskk#util#get_local_func(
        \       'do_lmap_non_egg_like_newline',
        \       s:SID_PREFIX
        \   ),
        \   [0]
        \)
    endif
    " }}}

    " InsertLeave: g:eskk#keep_state {{{
    if g:eskk#keep_state
        autocmd eskk InsertEnter * call eskk#mappings#do_insert_enter()
        autocmd eskk InsertLeave * call eskk#mappings#do_insert_leave()
    else
        autocmd eskk InsertLeave * call eskk#disable()
    endif
    " }}}

    " Default mappings - :EskkMap {{{
    silent! EskkMap -type=sticky -unique ;
    silent! EskkMap -type=backspace-key -unique <C-h>
    silent! EskkMap -type=enter-key -unique <CR>
    silent! EskkMap -type=escape-key -unique <Esc>
    silent! EskkMap -type=undo-key -unique <C-g>u
    silent! EskkMap -type=tab -unique <Tab>

    silent! EskkMap -type=phase:henkan:henkan-key -unique <Space>

    silent! EskkMap -type=phase:okuri:henkan-key -unique <Space>

    silent! EskkMap -type=phase:henkan-select:choose-next -unique <Space>
    silent! EskkMap -type=phase:henkan-select:choose-prev -unique x

    silent! EskkMap -type=phase:henkan-select:next-page -unique <Space>
    silent! EskkMap -type=phase:henkan-select:prev-page -unique x

    silent! EskkMap -type=phase:henkan-select:escape -unique <C-g>

    silent! EskkMap -type=phase:henkan-select:delete-from-dict -unique X

    silent! EskkMap -type=mode:hira:toggle-hankata -unique <C-q>
    silent! EskkMap -type=mode:hira:ctrl-q-key -unique <C-q>
    silent! EskkMap -type=mode:hira:toggle-kata -unique q
    silent! EskkMap -type=mode:hira:q-key -unique q
    silent! EskkMap -type=mode:hira:l-key -unique l
    silent! EskkMap -type=mode:hira:to-ascii -unique l
    silent! EskkMap -type=mode:hira:to-zenei -unique L
    silent! EskkMap -type=mode:hira:to-abbrev -unique /

    silent! EskkMap -type=mode:kata:toggle-hankata -unique <C-q>
    silent! EskkMap -type=mode:kata:ctrl-q-key -unique <C-q>
    silent! EskkMap -type=mode:kata:toggle-kata -unique q
    silent! EskkMap -type=mode:kata:q-key -unique q
    silent! EskkMap -type=mode:kata:l-key -unique l
    silent! EskkMap -type=mode:kata:to-ascii -unique l
    silent! EskkMap -type=mode:kata:to-zenei -unique L
    silent! EskkMap -type=mode:kata:to-abbrev -unique /

    silent! EskkMap -type=mode:hankata:toggle-hankata -unique <C-q>
    silent! EskkMap -type=mode:hankata:ctrl-q-key -unique <C-q>
    silent! EskkMap -type=mode:hankata:toggle-kata -unique q
    silent! EskkMap -type=mode:hankata:q-key -unique q
    silent! EskkMap -type=mode:hankata:l-key -unique l
    silent! EskkMap -type=mode:hankata:to-ascii -unique l
    silent! EskkMap -type=mode:hankata:to-zenei -unique L
    silent! EskkMap -type=mode:hankata:to-abbrev -unique /

    silent! EskkMap -type=mode:ascii:to-hira -unique <C-j>

    silent! EskkMap -type=mode:zenei:to-hira -unique <C-j>

    silent! EskkMap -type=mode:abbrev:henkan-key -unique <Space>

    silent! EskkMap -remap -unique <C-^> <Plug>(eskk:toggle)

    silent! EskkMap -remap <BS> <Plug>(eskk:filter:<C-h>)

    silent! EskkMap -map-if="mode() ==# 'i'" -unique <Esc>
    silent! EskkMap -map-if="mode() ==# 'i'" -unique <C-c>
    " }}}

    " Map temporary key to keys to use in that mode {{{
    call eskk#register_event(
    \   'enter-mode',
    \   'eskk#mappings#map_mode_local_keys',
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
        call eskk#register_mode('ascii')
        let dict = eskk#get_mode_structure('ascii')

        function! dict.filter(stash)
            let this = eskk#get_mode_structure('ascii')
            if eskk#mappings#is_special_lhs(
            \   a:stash.char, 'mode:ascii:to-hira'
            \)
                call eskk#set_mode('hira')
            else
                if a:stash.char !=# "\<BS>"
                \   && a:stash.char !=# "\<C-h>"
                    if a:stash.char =~# '\w'
                        if !has_key(
                        \   this.sandbox, 'already_set_for_this_word'
                        \)
                            " Set start col of word.
                            call s:set_current_to_begin_pos()
                            let this.sandbox.already_set_for_this_word = 1
                        endif
                    else
                        if has_key(
                        \   this.sandbox, 'already_set_for_this_word'
                        \)
                            unlet this.sandbox.already_set_for_this_word
                        endif
                    endif
                endif

                if eskk#has_mode_table('ascii')
                    if !has_key(this.sandbox, 'table')
                        let this.sandbox.table =
                        \   s:table_defs[eskk#get_mode_table('ascii')]
                    endif
                    let a:stash.return = this.sandbox.table.get_map(
                    \   a:stash.char, a:stash.char
                    \)
                else
                    let a:stash.return = a:stash.char
                endif
            endif
        endfunction

        call eskk#validate_mode_structure('ascii')
        " }}}

        " 'zenei' mode {{{
        call eskk#register_mode('zenei')
        let dict = eskk#get_mode_structure('zenei')

        function! dict.filter(stash)
            let this = eskk#get_mode_structure('zenei')
            if eskk#mappings#is_special_lhs(
            \   a:stash.char, 'mode:zenei:to-hira'
            \)
                call eskk#set_mode('hira')
            else
                if !has_key(this.sandbox, 'table')
                    let this.sandbox.table =
                    \   s:table_defs[eskk#get_mode_table('zenei')]
                endif
                let a:stash.return = this.sandbox.table.get_map(
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

        call eskk#validate_mode_structure('zenei')
        " }}}

        " 'hira' mode {{{
        call eskk#register_mode('hira')
        let dict = eskk#get_mode_structure('hira')

        call extend(
        \   dict,
        \   eskk#create_asym_filter(eskk#get_mode_table('hira'))
        \)

        call eskk#validate_mode_structure('hira')
        " }}}

        " 'kata' mode {{{
        call eskk#register_mode('kata')
        let dict = eskk#get_mode_structure('kata')

        call extend(
        \   dict,
        \   eskk#create_asym_filter(eskk#get_mode_table('kata'))
        \)

        call eskk#validate_mode_structure('kata')
        " }}}

        " 'hankata' mode {{{
        call eskk#register_mode('hankata')
        let dict = eskk#get_mode_structure('hankata')

        call extend(
        \   dict,
        \   eskk#create_asym_filter(eskk#get_mode_table('hankata'))
        \)

        call eskk#validate_mode_structure('hankata')
        " }}}

        " 'abbrev' mode {{{
        call eskk#register_mode('abbrev')
        let dict = eskk#get_mode_structure('abbrev')

        function! dict.filter(stash) "{{{
            let char = a:stash.char
            let buftable = eskk#get_buftable()
            let this = eskk#get_mode_structure('abbrev')
            let buf_str = buftable.get_current_buf_str()
            let phase = buftable.get_henkan_phase()

            " Handle special characters.
            " These characters are handled regardless of current phase.
            if eskk#mappings#is_special_lhs(char, 'backspace-key')
                if buf_str.get_rom_str() == ''
                    " If backspace-key was pressed at empty string,
                    " leave abbrev mode.
                    " TODO: Back to previous mode?
                    call eskk#set_mode('hira')
                else
                    call buftable.do_backspace(a:stash)
                endif
                return
            elseif eskk#mappings#is_special_lhs(char, 'enter-key')
                call buftable.do_enter(a:stash)
                call eskk#set_mode('hira')
                return
            else
                " Fall through.
            endif

            " Handle other characters.
            if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
                if eskk#mappings#is_special_lhs(
                \   char, 'phase:henkan:henkan-key'
                \)
                    call buftable.do_henkan(a:stash)
                else
                    call buf_str.push_rom_str(char)
                endif
            elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
                if eskk#mappings#is_special_lhs(
                \   char, 'phase:henkan-select:choose-next'
                \)
                    call buftable.choose_next_candidate(a:stash)
                    return
                elseif eskk#mappings#is_special_lhs(
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
                    \   'eskk#util#key2char',
                    \   [eskk#mappings#get_filter_map(a:stash.char)]
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
            return g:eskk#buftable#HENKAN_PHASE_HENKAN
        endfunction "}}}
        function! dict.get_supported_phases() "{{{
            return [
            \   g:eskk#buftable#HENKAN_PHASE_HENKAN,
            \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT,
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

        call eskk#validate_mode_structure('abbrev')
        " }}}
    endfunction
    call s:initialize_builtin_modes()
    " }}}

    " Register builtin-tables. {{{
    function! s:initialize_use_tables()
        let tabletmpl = {}    " dummy object
        function! tabletmpl.init()
            call self.add_from_dict(eskk#table#{self.name}#load())
        endfunction
        for table in values(g:eskk#mode_use_tables)
            let table.init = tabletmpl.init
            let s:table_defs[table.name] = table
        endfor
    endfunction
    call s:initialize_use_tables()
    " }}}

    " BufEnter: Map keys if enabled. {{{
    function! s:initialize_map_all_keys_if_enabled()
        if eskk#is_enabled()
            call eskk#mappings#map_all_keys()
        endif
    endfunction
    autocmd eskk BufEnter * call s:initialize_map_all_keys_if_enabled()
    " }}}

    " BufEnter: Restore global option value of &iminsert, &imsearch {{{
    function! s:restore_im_options() "{{{
        if empty(s:saved_im_options)
            return
        endif
        let [&g:iminsert, &g:imsearch] = s:saved_im_options
    endfunction "}}}

    if !g:eskk#keep_state_beyond_buffer
        autocmd eskk BufLeave * call s:restore_im_options()
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
        if has_key(st.sandbox, 'real_matched_pairs')
            unlet st.sandbox.real_matched_pairs
        endif
    endfunction "}}}
    autocmd eskk InsertLeave * call s:clear_real_matched_pairs()
    " }}}

    " s:saved_im_options {{{
    call eskk#util#assert(empty(s:saved_im_options))
    let s:saved_im_options = [&g:iminsert, &g:imsearch]
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
        \       : g:eskk#buftable#HENKAN_PHASE_NORMAL)
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
        let s:saved_backspace = &l:backspace
        setlocal backspace+=eol
        autocmd eskk InsertEnter * setlocal backspace+=eol
        autocmd eskk InsertLeave * let &l:backspace = s:saved_backspace
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

    " neocomplcache {{{
    function! s:initialize_neocomplcache()
        function! s:initialize_neocomplcache_unlock()
            if eskk#is_neocomplcache_locked()
                NeoComplCacheUnlock
            endif
            return ''
        endfunction
        call eskk#mappings#map(
        \   'e',
        \   '<Plug>(eskk:_neocomplcache_unlock)',
        \   eskk#util#get_local_func(
        \       'initialize_neocomplcache_unlock',
        \       s:SID_PREFIX
        \   ) . '()',
        \   eskk#mappings#get_map_modes() . 'n'
        \)
    endfunction
    call s:initialize_neocomplcache()
    " }}}

    " Completion {{{
    function! s:initialize_completion()
        call eskk#mappings#map(
        \   'e',
        \   '<Plug>(eskk:_do_complete)',
        \   'pumvisible() ? "" : "\<C-x>\<C-o>\<C-p>"'
        \)
    endfunction
    call s:initialize_completion()
    " }}}


    " Create "eskk-initialize" autocmd event.
    " If no "User eskk-initialize" events,
    " Vim complains like "No matching autocommands".
    autocmd eskk User eskk-initialize :

    " Throw eskk-initialize event.
    doautocmd User eskk-initialize
endfunction "}}}
function! eskk#is_initialized() "{{{
    return s:is_initialized
endfunction "}}}

" Enable/Disable IM
function! eskk#is_enabled() "{{{
    return eskk#get_current_instance().enabled
endfunction "}}}
function! eskk#enable(...) "{{{
    let self = eskk#get_current_instance()
    let do_map = a:0 != 0 ? a:1 : 1

    if eskk#is_enabled()
        return ''
    endif

    if mode() ==# 'c'
        let &l:iminsert = 1
    endif

    if !s:is_initialized
        call s:initialize()
        let s:is_initialized = 1
    endif

    call eskk#throw_event('enable-im')

    " Clear current variable states.
    let self.mode = ''
    call eskk#get_buftable().reset()

    " Set up Mappings.
    if do_map
        call eskk#mappings#map_all_keys()
    endif

    call eskk#set_mode(g:eskk#initial_mode)

    " If skk.vim exists and enabled, disable it.
    let disable_skk_vim = ''
    if exists('g:skk_version') && exists('b:skk_on') && b:skk_on
        let disable_skk_vim = substitute(SkkDisable(), "\<C-^>", '', '')
    endif

    if g:eskk#enable_completion
        let self.omnifunc_save = &l:omnifunc
        let &l:omnifunc = 'eskk#complete#eskkcomplete'
    endif

    let self.enabled = 1
    let self.enabled_mode = mode()

    if self.enabled_mode =~# '^[ic]$'
        return disable_skk_vim . "\<C-^>"
    else
        return eskk#enable_im()
    endif
endfunction "}}}
function! eskk#disable() "{{{
    let self = eskk#get_current_instance()
    let do_unmap = a:0 != 0 ? a:1 : 0

    if !eskk#is_enabled()
        return ''
    endif

    if mode() ==# 'c'
        return "\<C-^>"
    endif

    call eskk#throw_event('disable-im')

    if do_unmap
        call eskk#mappings#unmap_all_keys()
    endif

    if g:eskk#enable_completion && has_key(self, 'omnifunc_save')
        let &l:omnifunc = self.omnifunc_save
    endif

    if eskk#is_neocomplcache_locked()
        NeoComplCacheUnlock
    endif

    let self.enabled = 0

    if mode() =~# '^[ic]$'
        let buftable = eskk#get_buftable()
        return buftable.generate_kakutei_str() . "\<C-^>"
    else
        return eskk#disable_im()
    endif
endfunction "}}}
function! eskk#toggle() "{{{
    return eskk#{eskk#is_enabled() ? 'disable' : 'enable'}()
endfunction "}}}
function! eskk#enable_im() "{{{
    let save_lang = v:lang
    lang messages C
    try
        redir => output
        silent lmap
        redir END
    finally
        execute 'lang messages' save_lang
    endtry
    let defined_langmap = (output !~# '^\n*No mapping found\n*$')

    " :help i_CTRL-^
    let &l:iminsert = defined_langmap ? 1 : 2
    let &l:imsearch = &l:iminsert
    
    return ''
endfunction "}}}
function! eskk#disable_im() "{{{
    let save_lang = v:lang
    lang messages C
    try
        redir => output
        silent lmap
        redir END
    finally
        execute 'lang messages' save_lang
    endtry
    let defined_langmap = (output !~# '^\n*No mapping found\n*$')

    let &l:iminsert = 0
    let &l:imsearch = 0
    
    return ''
endfunction "}}}

" Mode
function! eskk#set_mode(next_mode) "{{{
    let self = eskk#get_current_instance()
    if !eskk#is_supported_mode(a:next_mode)
        call eskk#util#log(
        \   "mode '" . a:next_mode . "' is not supported."
        \)
        call eskk#util#log(
        \   's:available_modes = ' . string(s:available_modes)
        \)
        return
    endif

    call eskk#throw_event('leave-mode-' . self.mode)
    call eskk#throw_event('leave-mode')

    " Change mode.
    let prev_mode = self.mode
    let self.mode = a:next_mode

    call eskk#throw_event('enter-mode-' . self.mode)
    call eskk#throw_event('enter-mode')

    " For &statusline.
    redrawstatus
endfunction "}}}
function! eskk#get_mode() "{{{
    let self = eskk#get_current_instance()
    return self.mode
endfunction "}}}
function! eskk#is_supported_mode(mode) "{{{
    return has_key(s:available_modes, a:mode)
endfunction "}}}
function! eskk#register_mode(mode) "{{{
    let s:available_modes[a:mode] = extend(
    \   (a:0 ? a:1 : {}),
    \   {'sandbox': {}},
    \   'keep'
    \)
endfunction "}}}
function! eskk#validate_mode_structure(mode) "{{{
    " It should be recommended to call
    " this function at the end of mode register.

    let self = eskk#get_current_instance()
    let st = eskk#get_mode_structure(a:mode)

    for key in ['filter', 'sandbox']
        if !has_key(st, key)
            throw eskk#user_error(
            \   ['eskk'],
            \   "eskk#register_mode(" . string(a:mode) . "): "
            \       . string(key) . " is not present in structure"
            \)
        endif
    endfor
endfunction "}}}
function! eskk#get_current_mode_structure() "{{{
    return eskk#get_mode_structure(eskk#get_mode())
endfunction "}}}
function! eskk#get_mode_structure(mode) "{{{
    let self = eskk#get_current_instance()
    if !eskk#is_supported_mode(a:mode)
        throw eskk#user_error(
        \   ['eskk'],
        \   "mode '" . a:mode . "' is not available."
        \)
    endif
    return s:available_modes[a:mode]
endfunction "}}}
function! eskk#has_mode_func(func_key) "{{{
    let self = eskk#get_current_instance()
    let st = eskk#get_mode_structure(self.mode)
    return has_key(st, a:func_key)
endfunction "}}}
function! eskk#call_mode_func(func_key, args, required) "{{{
    let self = eskk#get_current_instance()
    let st = eskk#get_mode_structure(self.mode)
    if !has_key(st, a:func_key)
        if a:required
            let msg = printf()
            throw eskk#internal_error(
            \   ['eskk'],
            \   "Mode '" . self.mode . "' does not have"
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
    return has_key(g:eskk#mode_use_tables, a:mode)
endfunction "}}}
function! eskk#get_current_mode_table() "{{{
    return eskk#get_mode_table(eskk#get_mode())
endfunction "}}}
function! eskk#get_mode_table(mode) "{{{
    return g:eskk#mode_use_tables[a:mode].name
endfunction "}}}
function! eskk#create_table(table_name) "{{{
    if has_key(s:cached_tables, a:table_name)
        return s:cached_tables[a:table_name]
    endif

    " Cache under s:cached_tables.
    let s:cached_tables[a:table_name] = eskk#table#new(a:table_name)
    return s:cached_tables[a:table_name]
endfunction "}}}

function! eskk#_get_cached_maps() "{{{
    return s:cached_maps
endfunction "}}}
function! eskk#_get_cached_candidates() "{{{
    return s:cached_candidates
endfunction "}}}
function! eskk#_get_table_defs() "{{{
    return s:table_defs
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
    let self = eskk#get_current_instance()
    if empty(self.buftable)
        let self.buftable = eskk#buftable#new()
    endif
    return self.buftable
endfunction "}}}
function! eskk#set_buftable(buftable) "{{{
    let self = eskk#get_current_instance()
    call a:buftable.set_old_str(
    \   empty(self.buftable) ? '' : self.buftable.get_old_str()
    \)
    let self.buftable = a:buftable
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
    let self = eskk#get_current_instance()
    return s:register_event(
    \   self.temp_event_hook_fn,
    \   a:event_names,
    \   a:Fn,
    \   a:head_args,
    \   (a:0 ? a:1 : -1)
    \)
endfunction "}}}
function! s:register_event(st, event_names, Fn, head_args, self) "{{{
    let event_names = type(a:event_names) == type([]) ?
    \                   a:event_names : [a:event_names]
    for name in event_names
        if !has_key(a:st, name)
            let a:st[name] = []
        endif
        call add(
        \   a:st[name],
        \   [a:Fn, a:head_args]
        \       + (a:self !=# -1 ? [a:self] : [])
        \)
    endfor
endfunction "}}}
function! eskk#throw_event(event_name) "{{{
    let self = eskk#get_current_instance()
    let ret        = []
    let event      = get(s:event_hook_fn, a:event_name, [])
    let temp_event = get(self.temp_event_hook_fn, a:event_name, [])
    let all_events = event + temp_event
    if empty(all_events)
        return []
    endif

    while !empty(all_events)
        let call_args = remove(all_events, 0)
        if g:eskk#debug
            redir => output
            silent execute 'function' call_args[0]
            redir END
        endif
        call add(ret, call('call', call_args))
    endwhile

    " Clear temporary hooks.
    let self.temp_event_hook_fn[a:event_name] = []

    return ret
endfunction "}}}
function! eskk#has_event(event_name) "{{{
    let self = eskk#get_current_instance()
    return
    \   !empty(get(s:event_hook_fn, a:event_name, []))
    \   || !empty(get(self.temp_event_hook_fn, a:event_name, []))
endfunction "}}}

" Key handler
function! eskk#register_map(map, Fn, args, force) "{{{
    let map = eskk#util#key2char(a:map)
    if has_key(s:key_handler, map) && !a:force
        return
    endif
    let s:key_handler[map] = [a:Fn, a:args]
endfunction "}}}
function! eskk#unregister_map(map, Fn, args) "{{{
    let map = eskk#util#key2char(a:map)
    if has_key(s:key_handler, map)
        unlet s:key_handler[map]
    endif
endfunction "}}}

" Locking diff old string
function! eskk#lock_old_str() "{{{
    let self = eskk#get_current_instance()
    let self.is_locked_old_str = 1
endfunction "}}}
function! eskk#unlock_old_str() "{{{
    let self = eskk#get_current_instance()
    let self.is_locked_old_str = 0
endfunction "}}}

" Filter
function! eskk#filter(char) "{{{
    let self = eskk#get_current_instance()

    " Check irregular circumstance.
    if !eskk#is_supported_mode(self.mode)
        call eskk#util#log('current mode is not supported: ' . self.mode)
        sleep 1
    endif


    call eskk#throw_event('filter-begin')

    let buftable = eskk#get_buftable()
    let stash = {
    \   'char': a:char,
    \   'return': 0,
    \
    \   'buftable': buftable,
    \   'phase': buftable.get_henkan_phase(),
    \   'buf_str': buftable.get_current_buf_str(),
    \   'mode': eskk#get_mode(),
    \}

    if !self.is_locked_old_str
        call buftable.set_old_str(buftable.get_display_str())
    endif

    try
        let do_filter = 1
        if eskk#complete#completing()
            try
                let do_filter = eskk#complete#handle_special_key(stash)
            catch
                call eskk#util#log_exception(
                \   'eskk#complete#handle_special_key()'
                \)
            endtry
        else
            let self.has_started_completion = 0
        endif

        if do_filter
            call s:call_filter_fn(stash)
        endif
        return s:rewrite_string(stash.return)

    catch
        call s:write_error_log_file(a:char)
        return a:char

    finally
        call eskk#throw_event('filter-finalize')
    endtry
endfunction "}}}
function! s:call_filter_fn(stash) "{{{
    let filter_args = [a:stash]
    let cur_buf_str = a:stash.buftable.get_current_buf_str()
    let rom = cur_buf_str.get_input_rom() . a:stash.char
    if has_key(s:key_handler, rom)
        " Call eskk#register_map()'s handlers.
        let [Fn, args] = s:key_handler[rom]
        call call(Fn, filter_args + args)
    else
        call eskk#call_mode_func('filter', filter_args, 1)
    endif
endfunction "}}}
function! s:rewrite_string(return_string) "{{{
    let redispatch_pre = ''
    if eskk#has_event('filter-redispatch-pre')
        call eskk#mappings#map(
        \   'rbe',
        \   '<Plug>(eskk:_filter_redispatch_pre)',
        \   'join(eskk#throw_event("filter-redispatch-pre"), "")'
        \)
        let redispatch_pre = "\<Plug>(eskk:_filter_redispatch_pre)"
    endif

    let redispatch_post = ''
    if eskk#has_event('filter-redispatch-post')
        call eskk#mappings#map(
        \   'rbe',
        \   '<Plug>(eskk:_filter_redispatch_post)',
        \   'join(eskk#throw_event("filter-redispatch-post"), "")'
        \)
        let redispatch_post = "\<Plug>(eskk:_filter_redispatch_post)"
    endif

    let completion_enabled =
    \   g:eskk#enable_completion
    \   && exists('g:loaded_neocomplcache')
    \   && !neocomplcache#is_locked()
    if completion_enabled
        NeoComplCacheLock
    endif

    if type(a:return_string) == type("")
        call eskk#mappings#map(
        \   'b',
        \   '<Plug>(eskk:_return_string)',
        \   eskk#util#str2map(a:return_string)
        \)
        let string = "\<Plug>(eskk:_return_string)"
    else
        let string = eskk#get_buftable().rewrite()
    endif
    return
    \   redispatch_pre
    \   . string
    \   . redispatch_post
    \   . (completion_enabled ?
    \       "\<Plug>(eskk:_neocomplcache_unlock)" .
    \           (eskk#complete#can_find_start() ?
    \               "\<Plug>(eskk:_do_complete)" :
    \               '') :
    \       '')
endfunction "}}}
function! s:write_error_log_file(char) "{{{
    let lines = []
    call add(lines, '--- g:eskk#version ---')
    call add(lines, printf('g:eskk#version = %s', string(g:eskk#version)))
    call add(lines, '--- g:eskk#version ---')

    call add(lines, '--- char ---')
    call add(lines, printf('char: %s(%d)', string(a:char), char2nr(a:char)))
    call add(lines, printf('mode(): %s', mode()))
    call add(lines, '--- char ---')

    call add(lines, '')

    call add(lines, '--- exception ---')
    if v:exception =~# '^eskk:'
        call add(lines, 'exception type: eskk exception')
        call add(lines, printf('v:exception: %s', v:exception))
    else
        call add(lines, 'exception type: Vim internal error')
        call add(lines, printf('v:exception: %s', v:exception))
    endif
    call add(lines, printf('v:throwpoint: %s', v:throwpoint))

    call add(lines, '')

    let arg = {
    \   'snr_funcname': '<SNR>\d\+_\w\+',
    \   'autoload_funcname': '[\w#]\+',
    \   'global_funcname': '[A-Z]\w*',
    \   'lines': lines,
    \}
    let o = {}

    function o['a'](arg)
        let a:arg.stacktrace =
        \   matchstr(v:throwpoint, '\C'.'^function \zs\S\+\ze, ')
        return a:arg.stacktrace != ''
    endfunction

    function o['b'](arg)
        let a:arg.funcname = get(split(a:arg.stacktrace, '\.\.'), -1, '')
        return a:arg.funcname != ''
    endfunction

    function o['c'](arg)
        try
            return exists('*' . a:arg.funcname)
        catch    " E129: Function name required
            " but "s:" prefixed function also raises this error.
            return a:arg.funcname =~# a:arg.snr_funcname ? 1 : 0
        endtry
    endfunction

    function o['d'](arg)
        redir => output
        silent execute 'function' a:arg.funcname
        redir END

        let a:arg.lines += split(output, '\n')
    endfunction

    for k in sort(keys(o))
        if !o[k](arg)
            break
        endif
    endfor
    call add(lines, '--- exception ---')

    call add(lines, '')

    call add(lines, '--- buftable ---')
    let lines += eskk#get_buftable().dump()
    call add(lines, '--- buftable ---')

    call add(lines, '')

    call add(lines, "--- Vim's :version ---")
    redir => output
    silent version
    redir END
    let lines += split(output, '\n')
    call add(lines, "--- Vim's :version ---")

    call add(lines, '')
    call add(lines, '')

    if executable('uname')
        call add(lines, "--- Operating System ---")
        call add(lines, printf('"uname -a" = %s', system('uname -a')))
        call add(lines, "--- Operating System ---")
        call add(lines, '')
    endif

    call add(lines, '--- feature-list ---')
    call add(lines, 'gui_running = '.has('gui_running'))
    call add(lines, 'unix = '.has('unix'))
    call add(lines, 'mac = '.has('mac'))
    call add(lines, 'macunix = '.has('macunix'))
    call add(lines, 'win16 = '.has('win16'))
    call add(lines, 'win32 = '.has('win32'))
    call add(lines, 'win64 = '.has('win64'))
    call add(lines, 'win32unix = '.has('win32unix'))
    call add(lines, 'win95 = '.has('win95'))
    call add(lines, 'amiga = '.has('amiga'))
    call add(lines, 'beos = '.has('beos'))
    call add(lines, 'dos16 = '.has('dos16'))
    call add(lines, 'dos32 = '.has('dos32'))
    call add(lines, 'os2 = '.has('macunix'))
    call add(lines, 'qnx = '.has('qnx'))
    call add(lines, 'vms = '.has('vms'))
    call add(lines, '--- feature-list ---')

    call add(lines, '')
    call add(lines, '')

    call add(lines, "Please report this error to author.")
    call add(lines, "`:help eskk` to see author's e-mail address.")



    let log_file = expand(
    \   eskk#util#join_path(
    \       g:eskk#directory,
    \       'log', 'error' . strftime('-%Y-%m-%d-%H%M%S') . '.log'
    \   )
    \)
    let write_success = 0
    try
        call writefile(lines, log_file)
        let write_success = 1
    catch
        call eskk#util#logf("Cannot write to log file '%s'.", log_file)
    endtry

    let save_cmdheight = &cmdheight
    setlocal cmdheight=3
    try
        call eskk#util#warnf(
        \   "Error!! See %s and report to author.",
        \   (write_success ? string(log_file) : ':messages')
        \)
        sleep 500m
    finally
        let &cmdheight = save_cmdheight
    endtry
endfunction "}}}

" g:eskk#context_control
function! eskk#handle_context() "{{{
    for control in g:eskk#context_control
        if eval(control.rule)
            call call(control.fn, [])
        endif
    endfor
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

" <Plug>(eskk:alpha-t), <Plug>(eskk:alpha-f), ...
function! eskk#jump_one_char(cmd, ...) "{{{
    if a:cmd !=? 't' && a:cmd !=? 'f'
        return
    endif
    let is_t = a:cmd ==? 't'
    let is_forward = eskk#util#is_lower(a:cmd)
    let s:last_jump_cmd = a:cmd

    if a:0 == 0
        let char = eskk#util#getchar()
        let s:last_jump_char = char
    else
        let char = a:1
    endif

    if is_forward
        if col('.') == col('$')
            return
        endif
        let rest_line = getline('.')[col('.') :]
        let idx = stridx(rest_line, char)
        if idx != -1
            call cursor(line('.'), col('.') + idx + 1 - is_t)
        endif
    else
        if col('.') == 1
            return
        endif
        let rest_line = getline('.')[: col('.') - 2]
        let idx = strridx(rest_line, char)
        if idx != -1
            call cursor(line('.'), idx + 1 + is_t)
        endif
    endif
endfunction "}}}
function! eskk#repeat_last_jump(cmd) "{{{
    if a:cmd !=# ',' && a:cmd !=# ';'
        return
    endif
    if type(s:last_jump_cmd) == type("")
    \   && type(s:last_jump_char) == type("")
        return
    endif

    if a:cmd ==# ','
        let s:last_jump_char = s:invert_direction(s:last_jump_char)
    endif
    call eskk#jump_one_char(s:last_jump_cmd, s:last_jump_char)
endfunction "}}}
function! s:invert_direction(cmd) "{{{
    return eskk#util#is_lower(a:cmd) ? toupper(a:cmd) : tolower(a:cmd)
endfunction "}}}

" Misc.
function! eskk#is_neocomplcache_locked() "{{{
    return
    \   g:eskk#enable_completion
    \   && exists('g:loaded_neocomplcache')
    \   && exists(':NeoComplCacheUnlock')
    \   && neocomplcache#is_locked()
endfunction "}}}

" Exceptions
function! s:build_error(from, msg) "{{{
    return 'eskk: ' . join(a:msg, ': ') . ' at ' . join(a:from, '#')
endfunction "}}}

function! eskk#internal_error(from, ...) "{{{
    return s:build_error(a:from, ['internal error'] + a:000)
endfunction "}}}
function! eskk#dictionary_look_up_error(from, ...) "{{{
    return s:build_error(a:from, ['dictionary look up error'] + a:000)
endfunction "}}}
function! eskk#out_of_idx_error(from, ...) "{{{
    return s:build_error(a:from, ['out of index'] + a:000)
endfunction "}}}
function! eskk#parse_error(from, ...) "{{{
    return s:build_error(a:from, ['parse error'] + a:000)
endfunction "}}}
function! eskk#assertion_failure_error(from, ...) "{{{
    " This is only used from eskk#util#assert().
    return s:build_error(a:from, ['assertion failed'] + a:000)
endfunction "}}}
function! eskk#user_error(from, msg) "{{{
    " Return simple message.
    " TODO Omit a:from to simplify message?
    return printf('%s: %s', join(a:from, ': '), a:msg)
endfunction "}}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

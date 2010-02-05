" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" FIXME
" - 言語モードにしてからインサートモードを抜けて
"   またインサートモードになった時にまだ有効になっている件


" Variables {{{

let s:skk7_mode = ''
let s:skk7_state = ''

let s:special_keys = {}

" この他の変数はs:initialize_im_enter()を参照。

" }}}


" Initialize {{{

func! skk7#init_keys() "{{{
    call skk7#util#log("initializing skk7...")

    " Register built-in modes.
    for [key, mode] in g:skk7_registered_modes
        call skk7#register_mode(key, mode)
    endfor

    " Register Mappings.
    call s:set_up_mappings()
endfunc "}}}

func! s:initialize_im_enter() "{{{
    " 変換フェーズになってからまだ変換されていない文字列
    let s:filter_buf_str = ''
    " 上の文字列のフィルタがかけられた版
    let s:filter_filtered_str = ''
    " 変換フェーズになってからまた変換フェーズになった場合の文字 (0文字か1文字)
    let s:filter_buf_char = ''
    " 変換キーが押された回数
    let s:filter_henkan_count = 0
    " 変換フェーズかどうか
    let s:filter_is_henkan_phase = 0
    " 非同期なフィルタの実行がサポートされているかどうか
    let s:filter_is_async = 0
endfunc "}}}


func! s:set_up_mappings() "{{{
    for char in s:get_all_chars()
        " XXX: '<silent>' sometimes causes strange bug...
        call s:execute_map('l',
        \             '<buffer><expr><silent>',
        \             1,
        \             char,
        \             printf('<SID>dispatch_key(%s)', string(char)))
    endfor
endfunc "}}}

func! s:get_all_chars() "{{{
    return split(
    \   'abcdefghijklmnopqrstuvwxyz'
    \  .'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    \  .'1234567890'
    \  .'!"#$%&''()'
    \  .',./;:]@[-^\'
    \  .'<>?_+*}`{=~'
    \   ,
    \   '\zs'
    \) + [
    \   "<Bar>",
    \   "<Tab>",
    \   "<BS>",
    \   "<Insert>",
    \   "<Home>",
    \   "<PageUp>",
    \   "<Delete>",
    \   "<End>",
    \   "<PageDown>",
    \]
endfunc "}}}

func! s:execute_map(modes, options, remap_p, lhs, rhs) "{{{
    for mode in split(a:modes, '\zs')
        execute printf('%s%smap', mode, (a:remap_p ? 'nore' : ''))
        \       a:options
        \       a:lhs
        \       a:rhs
    endfor
endfunc "}}}

" }}}


" Functions {{{

" Autoload functions {{{

func! skk7#is_enabled() "{{{
    return &iminsert == 1
endfunc "}}}

func! skk7#enable() "{{{
    if skk7#is_enabled()
        return ''
    endif

    call s:initialize_im_enter()

    " TODO
    " Save previous mode/state.
    call skk7#set_mode(g:skk7_initial_mode)
    let s:skk7_state = 'main'

    let cb_im_enter = printf('skk7#mode#%s#cb_im_enter', s:skk7_mode)
    call skk7#util#call_if_exists(cb_im_enter, [], 'no throw')

    return "\<C-^>"
endfunc "}}}

func! skk7#sticky_key() "{{{
    if !skk7#is_henkan_phase()
        call skk7#set_henkan_phase(1)
        return g:skk7_marker_white
    else
        return ''
    endif
endfunc "}}}

func! skk7#register_mode(key, mode) "{{{
    " TODO Force mapping?
    call s:maptable_map_modechange_key(a:key, a:mode, 0)

    " TODO Lazy loading?
    call skk7#mode#{a:mode}#initialize()
endfunc "}}}

func! skk7#current_filter() "{{{
    return skk7#filter_fmt(s:skk7_mode, s:skk7_state)
endfunc "}}}

func! skk7#filter_fmt(mode, state) "{{{
    return printf('skk7#mode#%s#filter_%s', a:mode, a:state)
endfunc "}}}

" NOTE: skk7#is_henkan_phase() がtrueの時、s:filter_buf_str は ''
func! skk7#is_henkan_phase() "{{{
    return s:filter_is_henkan_phase
endfunc "}}}

func! skk7#is_async() "{{{
    return s:filter_is_async
endfunc "}}}

func! skk7#set_mode(next_mode) "{{{
    let cb_mode_leave = printf('skk7#mode#%s#cb_mode_leave', s:skk7_mode)
    call skk7#util#call_if_exists(cb_mode_leave, [a:next_mode], "no throw")

    let prev_mode = s:skk7_mode
    let s:skk7_mode = a:next_mode

    let cb_mode_enter = printf('skk7#mode#%s#cb_mode_enter', s:skk7_mode)
    call skk7#util#call_if_exists(cb_mode_enter, [prev_mode], "no throw")
endfunc "}}}

func! skk7#set_state(state) "{{{
    let s:skk7_state = a:state
endfunc "}}}

func! skk7#set_henkan_phase(cond) "{{{
    let s:filter_is_henkan_phase = a:cond
endfunc "}}}

func! skk7#is_modechange_key(char) "{{{
    return skk7#is_special_key(a:char)
    \   && s:special_keys[a:char].type ==# 'modechange'
endfunc "}}}

func! skk7#is_sticky_key(char) "{{{
    " mapmode-lを優先的に探す
    return skk7#is_special_key(a:char)
    \   && s:special_keys[a:char].type ==# 'sticky'
endfunc "}}}

func! skk7#is_big_letter(char) "{{{
    return a:char =~# '^[A-Z]$'
endfunc "}}}

func! skk7#is_special_key(char) "{{{
    return has_key(s:special_keys, a:char)
endfunc "}}}

" }}}

" For s:special_keys. {{{

" Map key.
func! s:maptable_map_key(from_key, map_st, force) "{{{
    " If:
    " - s:special_keys DOES NOT has a:from_key.
    " - Or, s:special_keys HAS a:from_key but a:force is true.
    if !(has_key(s:special_keys, a:from_key) && !a:force)
        let s:special_keys[a:from_key] = a:map_st
    endif
endfunc "}}}


func! s:maptable_is_supported_type(type) "{{{
    return exists('*' . s:maptable_get_type_func(a:type))
endfunc "}}}

func! s:maptable_get_type_func(type) "{{{
    return printf('s:maptable_create_%s_key', a:type)
endfunc "}}}


func! s:maptable_create_detected_type(type, args) "{{{
    call skk7#util#logf('type = %s, args = %s', a:type, string(a:args))
    if s:maptable_is_supported_type(a:type)
        return call(s:maptable_get_type_func(a:type), a:args)
    else
        throw printf("skk7: unknown type '%s'.", a:type)
    endif
endfunc "}}}


" Create modechange key's structure.
func! s:maptable_create_modechange_key(mode) "{{{
    return {
    \   'type': 'modechange',
    \   'mode': a:mode,
    \}
endfunc "}}}

" Map modechange key.
func! s:maptable_map_modechange_key(key, mode, force) "{{{
    call s:maptable_map_key(a:key, s:maptable_create_modechange_key(a:mode), a:force)
endfunc "}}}


" Create sticky key's structure.
func! s:maptable_create_sticky_key() "{{{
    return {'type': 'sticky'}
endfunc "}}}

" Map sticky key.
func! s:maptable_map_sticky_key(key) "{{{
    call s:maptable_map_key(a:key, s:maptable_create_sticky_key(), a:force)
endfunc "}}}

" }}}

" Dispatch functions {{{

" ここからフィルタ用関数にディスパッチする
func! s:dispatch_key(char, ...) "{{{
    let [capital_p] = skk7#util#get_args(a:000, 0)

    if s:handle_special_key_p(a:char)
        return s:handle_special_keys(a:char)
    else
        return s:handle_filter(a:char)
    endif

    " TODO 補完

endfunc "}}}

" モード切り替えなどの特殊なキーを実行するかどうか
func! s:handle_special_key_p(char) "{{{
    let cb_now_working = printf('skk7#mode#%s#cb_now_working', s:skk7_mode)

    return
    \   skk7#is_special_key(a:char)
    \   && s:filter_buf_str ==# ''
    \   && !skk7#util#call_if_exists(cb_now_working, [a:char], 0)
endfunc "}}}

" モード切り替えなどの特殊なキーを実行する
func! s:handle_special_keys(char) "{{{
    " TODO Priority

    if skk7#is_modechange_key(a:char)
        " モード変更
        call skk7#set_mode(s:special_keys[a:char].mode)
        return ''
    elseif skk7#is_sticky_key(a:char)
        return skk7#sticky_key()
    elseif skk7#is_big_letter(a:char)
        return skk7#sticky_key() . s:dispatch_key(tolower(a:char), 1)
    else
        call skk7#util#internal_error()
    endif
endfunc "}}}

func! s:handle_filter(char) "{{{
    let filtered = ''
    try
        let current_filter = skk7#current_filter()
        if skk7#util#is_callable(current_filter)
            let filtered = {current_filter}(
            \   a:char,
            \   s:filter_buf_str,
            \   s:filter_filtered_str,
            \   s:filter_buf_char,
            \   s:filter_henkan_count
            \)
        else
            let cb_no_filter = printf('skk7#mode#%s#cb_no_filter', s:skk7_mode)
            if skk7#util#is_callable(cb_no_filter)
                call {cb_no_filter}()
            else
                call skk7#mode#_default#cb_no_filter()
            endif
            " ローマ字のまま返す
            return a:char
        endif
    catch /^skk7:/
        call skk7#util#warnf(v:exception)
        " ローマ字のまま返す
        return a:char
    endtry

    return filtered
endfunc "}}}

" }}}

" For macro. {{{

func! skk7#define_macro() "{{{
    command!
    \   -buffer -nargs=+ -bang
    \   Skk7Map
    \   call s:cmd_map(<q-args>, "<bang>")
    " command!
    " \   -buffer -nargs=+ -bang
    " \   Skk7MapSticky
    " \   call s:cmd_map(<q-args>, "<bang>")
    " command!
    " \   -buffer -nargs=+ -bang
    " \   Skk7MapMode
    " \   call s:cmd_map(<q-args>, "<bang>")
endfunc "}}}

func! s:parse_arg(arg) "{{{
    let arg = a:arg
    let opt_regex = '-\(\w\+\)=\(\S\+\)'

    " Parse options.
    let opt = {}
    while arg != ''
        let arg = s:skip_spaces(arg)
        let [a, arg] = s:get_arg(arg)

        let m = matchlist(a, opt_regex)
        if !empty(m)
            " a is option.
            let [opt_name, opt_value] = m[1:2]
            if opt_name ==# 'type'
                let opt.types = split(opt_value, ',')
            else
                throw printf("skk7: Skk7Map: unknown '%s' option.", opt_name)
            endif
        else
            let arg = s:unget_arg(arg, a)
            break
        endif
    endwhile

    " Parse arguments.
    let lhs_rhs = []
    while arg != ''
        let arg = s:skip_spaces(arg)
        let [a, arg] = s:get_arg(arg)
        call add(lhs_rhs, a)
    endwhile
    if len(lhs_rhs) != 2
        call skk7#util#logf('lhs_rhs = %s', string(lhs_rhs))
        throw 'skk7: Skk7Map [-type=...] lhs rhs'
    endif

    return lhs_rhs + [get(opt, 'types', [])]
endfunc "}}}

func! s:cmd_map(arg, bang) "{{{
    try
        let [lhs, rhs, types] = s:parse_arg(a:arg)
        for t in types
            call s:do_macro_map(t, lhs, rhs, (a:bang != '' ? 1 : 0))
        endfor
    catch /^skk7:/
        call skk7#util#warn(v:exception)
    endtry
endfunc "}}}

func! skk7#map(types, lhs, rhs, ...) "{{{
    let force = a:0 != 0 ? a:1 : 0
    for t in type(a:types) == type([]) ? a:types : [a:types]
        call s:do_macro_map(t, a:lhs, a:rhs, force)
    endfor
endfunc "}}}

func! s:do_macro_map(type, lhs, rhs, force) "{{{
    call s:maptable_map_key(
    \   a:lhs,
    \   s:maptable_create_detected_type(
    \       a:type,
    \       (a:rhs != '' ? [a:rhs] : [])
    \   ),
    \   a:force
    \)
endfunc "}}}

" }}}

" }}}


" Autocmd {{{

augroup skk7-augroup
    autocmd!

    autocmd InsertEnter * call s:autocmd_insert_enter()
augroup END

func! s:autocmd_insert_enter() "{{{
    call skk7#set_henkan_phase(0)
endfunc "}}}

" }}}


call skk7#init_keys()
" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

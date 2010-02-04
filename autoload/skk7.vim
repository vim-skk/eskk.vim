" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" TODO
" - <C-^>が押された場合何が起きるか
"
" FIXME
" - 言語モードにしてからインサートモードを抜けて
"   またインサートモードになった時にまだ有効になっている件
" - 言語モードになっている時、<C-j>を押すと'0'が挿入されてしまう


" Variables {{{

let s:skk7_mode = ''
let s:skk7_state = ''

let s:mode_change_keys = {}

" この他の変数はs:initialize_im_enter()を参照。

" }}}


" Initialize {{{

func! s:initialize_once() "{{{
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


" Handlers.

func! s:set_up_mappings() "{{{
    for char in s:get_all_chars()
        " XXX: '<silent>' sometimes causes strange bug...
        call s:do_map('l',
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

func! s:do_map(modes, options, remap_p, lhs, rhs) "{{{
    for mode in split(a:modes, '\zs')
        execute printf('%s%smap', mode, (a:remap_p ? 'nore' : ''))
        \       a:options
        \       a:lhs
        \       a:rhs
    endfor
endfunc "}}}

" }}}


" Functions {{{

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
    call s:call_if_exists(cb_im_enter, [], 'no throw')

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

func! skk7#escape_key() "{{{
    return ''
endfunc "}}}

func! skk7#register_mode(key, mode) "{{{
    let s:mode_change_keys[a:key] = a:mode
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

" NOTE: 必要ないかも
func! skk7#set_mode(next_mode) "{{{
    let cb_mode_leave = printf('skk7#mode#%s#cb_mode_leave', s:skk7_mode)
    call s:call_if_exists(cb_mode_leave, [a:next_mode], "no throw")

    let prev_mode = s:skk7_mode
    let s:skk7_mode = a:next_mode

    let cb_mode_enter = printf('skk7#mode#%s#cb_mode_enter', s:skk7_mode)
    call s:call_if_exists(cb_mode_enter, [prev_mode], "no throw")
endfunc "}}}

func! skk7#set_state(state) "{{{
    let s:skk7_state = a:state
endfunc "}}}

func! skk7#set_henkan_phase(cond) "{{{
    let s:filter_is_henkan_phase = a:cond
endfunc "}}}

func! skk7#is_mode_change_key(char) "{{{
    return has_key(s:mode_change_keys, a:char)
endfunc "}}}

func! skk7#is_sticky_key(char) "{{{
    " mapmode-lを優先的に探す
    return maparg(a:char, 'lic') ==# '<Plug>(skk7-sticky-key)'
endfunc "}}}

func! skk7#is_escape_key(char) "{{{
    " mapmode-lを優先的に探す
    return maparg(a:char, 'lic') ==# '<Plug>(skk7-escape-key)'
endfunc "}}}

func! skk7#is_big_letter(char) "{{{
    return a:char =~# '^[A-Z]$'
endfunc "}}}

func! skk7#is_special_key(char) "{{{
    return
    \   skk7#is_mode_change_key(a:char)
    \   || skk7#is_sticky_key(a:char)
    \   || skk7#is_big_letter(a:char)
endfunc "}}}


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
    \   && !s:call_if_exists(cb_now_working, [a:char], 0)
endfunc "}}}

" モード切り替えなどの特殊なキーを実行する
func! s:handle_special_keys(char) "{{{
    if skk7#is_mode_change_key(a:char)
        " モード変更
        call skk7#set_mode(s:mode_change_keys[a:char])
        return ''
    elseif skk7#is_sticky_key(a:char)
        return skk7#sticky_key()
    elseif skk7#is_escape_key(a:char)
        return skk7#escape_key()
    elseif skk7#is_big_letter(a:char)
        return skk7#sticky_key() . s:dispatch_key(tolower(a:char), 1)
    else
        call skk7#util#internal_error()
    endif
endfunc "}}}

func! s:handle_filter(char) "{{{
    let filtered = ''
    try
        if exists('*' . skk7#current_filter())
            let filtered = {skk7#current_filter()}(
            \   s:filter_buf_str,
            \   s:filter_filtered_str,
            \   s:filter_buf_char,
            \   a:char,
            \   s:filter_henkan_count
            \)
        else
            if exists('*' . printf('skk7#mode#%s#cb_no_filter', s:skk7_mode))
                call skk7#mode#{s:skk7_mode}#cb_no_filter()
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


" Saving &options. {{{

" この変数は次の関数からのみ操作される
let s:saved_options = {}

func! s:option_has(optname) "{{{
    return has_key(s:saved_options, a:optname)
endfunc "}}}

func! s:is_option(optname) "{{{
    return exists('&' . a:optname)
endfunc "}}}

func! s:option_get(optname, ...) "{{{
    if s:option_has(a:optname)
        return s:saved_options[a:optname]
    elseif a:0 == 1
        return a:1
    else
        throw printf("skk7: no saved option '%s'.", a:optname)
    endif
endfunc "}}}

func! s:option_save(optname, ...) "{{{
    let bufexpr = a:0 == 0 ? '%' : a:1

    if !s:is_option(a:optname)
        throw printf("skk7: '%s' is not valid option name.", a:optname)
    endif
    let s:saved_options[a:optname] = getbufvar(bufexpr, a:optname)
endfunc "}}}

func! s:option_restore_all(...) "{{{
    for o in keys(s:saved_options)
        call call('s:option_restore', [o] + a:000)
    endfor
endfunc "}}}

func! s:option_restore(optname, ...) "{{{
    let clear_p = a:0 != 0 ? a:1 : 1

    let val = s:option_get(a:optname)
    call skk7#util#logf("restoring option '%s': (%s) => (%s)",
    \           a:optname,
    \           getbufvar('%', '&' . a:optname),
    \           val)
    call setbufvar('%', a:optname, val)
    if clear_p
        call s:option_clear()
    endif
endfunc "}}}

func! s:option_clear() "{{{
    let s:saved_options = {}
endfunc "}}}
" }}}


" Utility functions. {{{

func! s:current_mode() "{{{
    return 'skk7#mode#' . s:skk7_mode
endfunc "}}}

" a:func is string.
" arg 3 is not for 'self'.
func! s:call_if_exists(func, args, ...) "{{{
    if s:is_callable(a:func)
        return call(a:func, a:args)
    elseif a:0 != 0
        return a:1
    else
        throw printf("skk7: no such function '%s'.", a:func)
    endif
endfunc "}}}

" a:func is string.
func! s:is_callable(func) "{{{
    return exists('*' . a:func)
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


call s:initialize_once()
" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

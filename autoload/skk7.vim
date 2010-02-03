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

" }}}


" Functions {{{

func! skk7#is_enabled() "{{{
    return &iminsert == 1
endfunc "}}}

func! skk7#enable() "{{{
    if skk7#is_enabled()
        return
    endif

    " TODO
    " Save previous mode/state.
    let s:skk7_mode = g:skk7_initial_mode
    let s:skk7_state = 'main'

    return "\<C-^>"
endfunc "}}}


" Initialize {{{

func! s:initialize() "{{{
    call skk7#util#log("initializing skk7...")

    " Register built-in modes.
    for [key, mode] in g:skk7_registered_modes
        call skk7#register_mode(key, mode)
    endfor

    " Register Mappings.
    call s:set_up_mappings()
endfunc "}}}


" Handlers.

func! s:set_up_mappings() "{{{
    for char in s:get_all_chars()
        " XXX: '<silent>' sometimes causes strange bug...
        call s:do_map('l',
        \             '<buffer><expr><silent>',
        \             1,
        \             char,
        \             printf('<SID>do_filter(%s)', string(char)))
    endfor
endfunc "}}}

func! s:get_all_chars() "{{{
    return split(g:skk7_mapped_chars, '\zs')
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


" API functions for filter. {{{

func! skk7#register_mode(key, mode) "{{{
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
" func! skk7#set_mode(mode) "{{{
"     let s:skk7_mode = a:mode
" endfunc "}}}

func! skk7#set_state(state) "{{{
    let s:skk7_state = a:state
endfunc "}}}

func! skk7#set_henkan_phase(cond) "{{{
    let s:filter_is_henkan_phase = a:cond
endfunc "}}}

" }}}


" ここからフィルタ用関数にディスパッチする
func! s:do_filter(char) "{{{
    let filtered = ''

    " TODO
    " モードの切り替え

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
    return 'skk7#mode#%s' . s:skk7_mode
endfunc "}}}

" }}}

" }}}


call s:initialize()
" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

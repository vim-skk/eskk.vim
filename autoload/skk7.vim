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

let skk7#FROM_KEY_MAP = 'map'
let skk7#FROM_STICKY_KEY_MAP = 'sticky'
let skk7#FROM_BIG_LETTER = 'big'
let skk7#FROM_MODECHANGE_KEY_MAP = 'mode'

" この他の変数はs:initialize_im_enter()を参照。

" }}}


" Initialize {{{

func! skk7#init_keys() "{{{
    call skk7#util#log("initializing skk7...")

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
        \   '<buffer><expr><silent>',
        \   1,
        \   char,
        \   printf(
        \       'skk7#dispatch_key(%s, %s)',
        \       string(char),
        \       string(g:skk7#FROM_KEY_MAP)))
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

" Utility functions {{{

func! s:get_mode_func(func_str) "{{{
    return printf('skk7#mode#%s#%s', skk7#get_mode(), a:func_str)
endfunc "}}}

" }}}

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

    call skk7#util#call_if_exists(s:get_mode_func('cb_im_enter'), [], 'no throw')

    return "\<C-^>"
endfunc "}}}


func! skk7#sticky_key(again) "{{{
    if !a:again
        return skk7#dispatch_key('', g:skk7#FROM_STICKY_KEY_MAP)
    else
        if !skk7#is_henkan_phase()
            call skk7#set_henkan_phase(1)
            return g:skk7_marker_white
        else
            return ''
        endif
    endif
endfunc "}}}


func! skk7#current_filter() "{{{
    return s:get_mode_func('filter_' . s:skk7_state)
endfunc "}}}

" NOTE: skk7#is_henkan_phase() がtrueの時、s:filter_buf_str は ''
func! skk7#is_henkan_phase() "{{{
    return s:filter_is_henkan_phase
endfunc "}}}

func! skk7#is_async() "{{{
    return s:filter_is_async
endfunc "}}}

func! skk7#set_mode(next_mode) "{{{
    if !skk7#is_supported_mode(a:next_mode)
        call skk7#util#warnf("mode '%s' is not supported.", a:next_mode)
        return
    endif

    call skk7#util#call_if_exists(
    \   s:get_mode_func('cb_mode_leave'),
    \   [a:next_mode],
    \   "no throw"
    \)

    let prev_mode = s:skk7_mode
    let s:skk7_mode = a:next_mode

    call skk7#util#call_if_exists(
    \   s:get_mode_func('cb_mode_enter'),
    \   [prev_mode],
    \   "no throw"
    \)

    " For &statusline.
    redrawstatus
endfunc "}}}

func! skk7#get_mode() "{{{
    return s:skk7_mode
endfunc "}}}

func! skk7#is_supported_mode(mode) "{{{
    let varname = 'g:loaded_skk7_mode_' . a:mode
    return exists(varname) && {varname}
endfunc "}}}

func! skk7#set_state(state) "{{{
    let s:skk7_state = a:state
endfunc "}}}

func! skk7#set_henkan_phase(cond) "{{{
    let s:filter_is_henkan_phase = a:cond
endfunc "}}}


func! skk7#from_mode(mode) "{{{
    return g:skk7#FROM_MODECHANGE_KEY_MAP . a:mode
endfunc "}}}

func! skk7#get_mode_from(from) "{{{
    return strpart(a:sig, strlen(g:skk7#FROM_MODECHANGE_KEY_MAP))
endfunc "}}}

func! skk7#is_modechange_key(char, from) "{{{
    return stridx(a:from, g:skk7#FROM_MODECHANGE_KEY_MAP) == 0
endfunc "}}}

func! skk7#is_sticky_key(char, from) "{{{
    return a:from ==# g:skk7#FROM_STICKY_KEY_MAP
endfunc "}}}

func! skk7#is_big_letter(char, from) "{{{
    return a:char =~# '^[A-Z]$'
endfunc "}}}

func! skk7#is_special_key(char, from) "{{{
    return skk7#is_modechange_key(a:char, a:from)
    \   || skk7#is_sticky_key(a:char, a:from)
    \   || skk7#is_big_letter(a:char, a:from)
endfunc "}}}

" }}}

" Dispatch functions {{{

" ここからフィルタ用関数にディスパッチする
func! skk7#dispatch_key(char, from) "{{{
    if s:handle_special_key_p(a:char, a:from)
        return s:handle_special_keys(a:char, a:from)
    else
        return s:handle_filter(a:char)
    endif

    " TODO 補完

endfunc "}}}

" モード切り替えなどの特殊なキーを実行するかどうか
func! s:handle_special_key_p(char, from) "{{{
    " TODO cb_now_workingは必須にするつもりなので
    " call_if_exists()で呼び出さなくてもいい

    return
    \   skk7#is_special_key(a:char, a:from)
    \   && s:filter_buf_str ==# ''
    \   && !skk7#util#call_if_exists(
    \           s:get_mode_func('cb_now_working'),
    \           [a:char],
    \           0
    \       )
endfunc "}}}

" モード切り替えなどの特殊なキーを実行する
func! s:handle_special_keys(char, from) "{{{
    " TODO Priority

    if skk7#is_modechange_key(a:char, a:from)
        " モード変更
        call skk7#set_mode(skk7#get_mode_from(a:from))
        return ''
    elseif skk7#is_sticky_key(a:char, a:from)
        return skk7#sticky_key(1)
    elseif skk7#is_big_letter(a:char, a:from)
        return skk7#sticky_key(1)
        \    . skk7#dispatch_key(tolower(a:char), g:skk7#FROM_BIG_LETTER)
    else
        call skk7#util#internal_error()
    endif
endfunc "}}}

func! s:handle_filter(char) "{{{
    try
        " TODO フィルタ関数の文字列以外の戻り値に対応

        let current_filter = skk7#current_filter()
        let filtered = {current_filter}(
        \   a:char,
        \   s:filter_buf_str,
        \   s:filter_filtered_str,
        \   s:filter_buf_char,
        \   s:filter_henkan_count
        \)
        return filtered

    catch /^E117:/    " 未知の関数です
        let cb_no_filter = s:get_mode_func('cb_no_filter')
        if skk7#util#is_callable(cb_no_filter)
            call {cb_no_filter}()
        else
            call skk7#mode#cb_no_filter()
        endif
        " ローマ字のまま返す
        return a:char

    catch
        call skk7#util#warnf(v:exception)
        " ローマ字のまま返す
        return a:char
    endtry
endfunc "}}}

" }}}


" Commands {{{

" :Skk7SetMode {{{

command!
\   -nargs=?
\   Skk7SetMode
\   call s:cmd_set_mode(<f-args>)

func! s:cmd_set_mode(...) "{{{
    if a:0 != 0
        if skk7#is_supported_mode(a:1)
            call skk7#set_mode(a:1)
        else
            call skk7#util#warnf("mode '%s' is not supported.", a:1)
            return
        endif
    endif
    echo skk7#get_mode()
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

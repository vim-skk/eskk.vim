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

" Constants

let skk7#FROM_KEY_MAP = 'map'
let skk7#FROM_STICKY_KEY_MAP = 'sticky'
let skk7#FROM_BIG_LETTER = 'big'
let skk7#FROM_MODECHANGE_KEY_MAP = 'mode'

" Normal
let skk7#HENKAN_PHASE_NORMAL = 0
" Choosing henkan candidates.
let skk7#HENKAN_PHASE_HENKAN = 1
" Waiting for okurigana.
let skk7#HENKAN_PHASE_OKURI = 2



" 現在のモード
let s:skk7_mode = ''
" 非同期なフィルタの実行がサポートされているかどうか
let s:filter_is_async = 0
" 特殊なキーと、asciiモードなどで挿入する文字
let s:maptable = skk7#maptable#new()

" }}}


" Initialize {{{

func! s:initialize_variables() "{{{
    " NOTE: Do not initialize s:maptable.

    call skk7#util#log('initializing variables...')
    let s:skk7_mode = ''
    call s:initialize_buffer_table()
endfunc "}}}

func! s:initialize_buffer_table() "{{{
    " 変換フェーズでない状態で入力され、まだ確定していない文字列
    let g:skk7#henkan_buf_table = ['', '', '']
    " 変換キーが押された回数
    let s:henkan_count = 0
    " 現在の変換フェーズ
    let s:henkan_phase = g:skk7#HENKAN_PHASE_NORMAL
endfunc "}}}


func! s:set_up_mappings() "{{{
    call skk7#util#log('set up mappings...')

    for char in s:get_all_chars()
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

    call skk7#init_keys()
    call skk7#util#call_if_exists(s:get_mode_func('cb_im_enter'), [], 'no throw')
    return "\<C-^>"
endfunc "}}}

func! skk7#disable() "{{{
    if !skk7#is_enabled()
        return ''
    endif

    call skk7#util#call_if_exists(s:get_mode_func('cb_im_leave'), [], 'no throw')
    return "\<C-^>"
endfunc "}}}

func! skk7#toggle() "{{{
    if skk7#is_enabled()
        return skk7#disable()
    else
        return skk7#enable()
    endif
endfunc "}}}


func! skk7#init_keys() "{{{
    call skk7#util#log("<Plug>(skk7-init-keys)")

    " Clear current variable states.
    call s:initialize_variables()

    " Register Mappings.
    lmapclear <buffer>
    call s:set_up_mappings()

    " TODO
    " Save previous mode/state.
    call skk7#set_mode(g:skk7_initial_mode)
endfunc "}}}

func! skk7#sticky_key(again) "{{{
    call skk7#util#log("<Plug>(skk7-sticky-key)")

    if !a:again
        return skk7#dispatch_key('', g:skk7#FROM_STICKY_KEY_MAP)
    else
        let henkan_phase = skk7#get_henkan_phase()
        let advance_p =
        \   skk7#util#has_idx(g:skk7#henkan_buf_table, henkan_phase + 1)
        \   && skk7#get_current_buf() !=# ''

        if advance_p
            call skk7#set_henkan_phase(henkan_phase + 1)
            return g:skk7_marker_white
        else
            return ''
        endif
    endif
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

    call s:initialize_buffer_table()

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


func! skk7#get_henkan_buf(henkan_phase) "{{{
    return g:skk7#henkan_buf_table[a:henkan_phase]
endfunc "}}}


func! skk7#get_current_buf() "{{{
    return g:skk7#henkan_buf_table[skk7#get_henkan_phase()]
endfunc "}}}

func! skk7#set_current_buf(str) "{{{
    let g:skk7#henkan_buf_table[skk7#get_henkan_phase()] = a:str
endfunc "}}}


func! skk7#get_henkan_phase() "{{{
    return s:henkan_phase
endfunc "}}}

" TODO フィルタ関数実行中はいじれないようにする？
func! skk7#set_henkan_phase(henkan_phase) "{{{
    if skk7#util#has_idx(s:henkan_phase, a:henkan_phase)
        let s:henkan_phase = a:henkan_phase
    else
        call skk7#util#internal_error()
    endif
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

func! skk7#is_backspace_key(char, from) "{{{
    return a:char ==# "\<BS>" || a:char ==# "\<C-h>"
endfunc "}}}

func! skk7#is_special_key(char, from) "{{{
    return skk7#is_modechange_key(a:char, a:from)
    \   || skk7#is_sticky_key(a:char, a:from)
    \   || skk7#is_big_letter(a:char, a:from)
    \   || skk7#is_backspace_key(a:char, a:from)
endfunc "}}}


func! skk7#get_registered_modes() "{{{
    let prefix = 'loaded_skk7_mode_'
    return map(
    \   filter(
    \      keys(g:),
    \      'stridx(v:val, prefix) == 0'
    \   ),
    \   'strpart(v:val, strlen(prefix))'
    \)
endfunc "}}}


func! skk7#mapclear(...) "{{{
    let [local_mode] = skk7#util#get_args(a:000, '')
    return s:maptable.mapclear(local_mode)
endfunc "}}}

func! skk7#unmap(lhs, ...) "{{{
    let [local_mode] = skk7#util#get_args(a:000, '')
    return s:maptable.unmap(a:lhs, local_mode)
endfunc "}}}

func! skk7#map(lhs, rhs, ...) "{{{
    let [local_mode, force] = skk7#util#get_args(a:000, '', 0)
    return s:maptable.map(a:lhs, a:rhs, local_mode, force)
endfunc "}}}

func! skk7#maparg(lhs, ...) "{{{
    let [local_mode] = skk7#util#get_args(a:000, '')
    return s:maptable.maparg(a:lhs, local_mode)
endfunc "}}}

func! skk7#mapcheck(lhs, ...) "{{{
    let [local_mode] = skk7#util#get_args(a:000, '')
    return s:maptable.mapcheck(a:lhs, local_mode)
endfunc "}}}

" TODO
" func! skk7#hasmapto(rhs, ...) "{{{
"     let [local_mode] = skk7#util#get_args(a:000, '')
"     return s:maptable.hasmapto(a:rhs, local_mode)
" endfunc "}}}


" }}}

" Dispatch functions {{{

" ここからフィルタ用関数にディスパッチする
func! skk7#dispatch_key(char, from) "{{{
    if !skk7#is_supported_mode(s:skk7_mode)
        call skk7#init_keys()
    endif

    if s:handle_special_key_p(a:char, a:from)
        return s:handle_special_keys(a:char, a:from)
    else
        return s:handle_filter(a:char, a:from)
    endif

    " TODO 補完

endfunc "}}}

" モード切り替えなどの特殊なキーを実行するかどうか
func! s:handle_special_key_p(char, from) "{{{
    return
    \   !g:skk7#mode#{skk7#get_mode()}#handle_all_keys
    \   && skk7#is_special_key(a:char, a:from)
    \   && g:skk7#henkan_buf_table[skk7#get_henkan_phase()] ==# ''
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

    elseif skk7#is_backspace_key(a:char, a:from)
        call skk7#set_current_buf(
        \   skk7#util#mb_chop(skk7#get_current_buf())
        \)
        return "\<BS>"

    else
        call skk7#util#internal_error()
    endif
endfunc "}}}

" フィルタ用関数のディスパッチ
func! s:handle_filter(char, from) "{{{
    " TODO
    " - フィルタ関数の文字列以外の戻り値に対応

    try
        let filtered = {s:get_mode_func('filter_main')}(
        \   a:char,
        \   a:from,
        \   skk7#get_henkan_phase(),
        \   s:henkan_count
        \)
        return filtered

    catch
        " TODO 現在のモードで最初の一回だけv:exceptionを表示

        call s:initialize_buffer_table()
        " ローマ字のまま返す
        return a:char
    endtry
endfunc "}}}

" }}}


runtime plugin/skk7.vim
call skk7#init_keys()

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

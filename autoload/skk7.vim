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


" Constants {{{

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

" }}}
" See s:initialize_once() for Variables.


" Initialize {{{

func! s:initialize_once() "{{{
    " FIXME:
    " 1. On gVim, in Linux(ubuntu)
    "   This message will appear as 'Error'.
    " 2. But on Vim(CUI), in Linux(ubuntu)
    "   This message will appear
    "   as just message with WarningMsg
    "   (this is desired behavior).
    " 3. On gVim or Vim(CUI), in Windows
    "   Same as 2.
    call skk7#util#log('Initialize variables...')

    " 現在のモード
    let s:skk7_mode = ''
    " 非同期なフィルタの実行がサポートされているかどうか
    let s:filter_is_async = 0
    " 特殊なキーと、asciiモードなどで挿入する文字
    let s:maptable = skk7#maptable#new()
    " サポートしているモード
    let s:available_modes = []

    call s:initialize_buffer_table()
endfunc "}}}

func! s:reset_variables() "{{{
    call skk7#util#log('reset variables...')

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

func! s:set_up() "{{{
    " Clear current variable states.
    call s:reset_variables()

    " Register Mappings.
    call s:set_up_mappings()

    " TODO
    " Save previous mode/state.
    call skk7#set_mode(g:skk7_initial_mode)
endfunc "}}}


func! s:set_up_mappings() "{{{
    call skk7#util#log('set up mappings...')

    for char in s:get_all_chars()
        call s:execute_map(
        \   'l',
        \   '<buffer><expr><silent>',
        \   0,
        \   char,
        \   printf(
        \       'skk7#dispatch_key(%s)',
        \       string(char)))
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
        execute printf('%s%smap', mode, (a:remap_p ? '' : 'nore'))
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

    call s:set_up()
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


" This is for emergency use.
func! skk7#init_keys() "{{{
    call skk7#util#log("<Plug>(skk7-init-keys)")

    " Clear current variable states.
    call s:reset_variables()

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
        return skk7#dispatch_key('')
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
    return !empty(filter(copy(s:available_modes), 'v:val ==# a:mode'))
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
        throw skk7#error#internal_error('skk7:')
    endif
endfunc "}}}


func! skk7#is_special_key(char) "{{{
    " skk7#maparg()'s 3 arg is '',
    " because a:char is already evaled.
    return skk7#maparg(a:char, '', '')
    \   || a:char =~# '^[A-Z]$'
    \   || a:char ==# "\<BS>"
    \   || a:char ==# "\<C-h>"
    \   || a:char ==# "\<Enter>"
endfunc "}}}


func! skk7#register_mode(mode) "{{{
    call add(s:available_modes, a:mode)
    let fmt = 'lnoremap <expr> <Plug>(skk7-mode-to-%s) skk7#set_mode(%s)'
    execute printf(fmt, a:mode, string(a:mode))
endfunc "}}}

func! skk7#get_registered_modes() "{{{
    return s:available_modes
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
    " TODO Map a:lhs also in Vim's mapping table.
    return s:maptable.map(a:lhs, a:rhs, local_mode, force)
endfunc "}}}

func! skk7#maparg(lhs, ...) "{{{
    let [local_mode, options] = skk7#util#get_args(a:000, '', 'e')
    return s:maptable.maparg(a:lhs, local_mode, options)
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
func! skk7#dispatch_key(char) "{{{
    if !skk7#is_supported_mode(s:skk7_mode)
        call skk7#util#warn('current mode is empty! please call skk7#init_keys()...')
        sleep 1
    endif

    return s:handle_filter(a:char)
endfunc "}}}

" フィルタ用関数のディスパッチ
func! s:handle_filter(char) "{{{
    try
        let filtered = {s:get_mode_func('filter_main')}(
        \   a:char,
        \   '',
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
call s:initialize_once()

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" FIXME
" - 言語モードにしてからインサートモードを抜けて
"   またインサートモードになった時にまだ有効になっている件


" Constants {{{

let eskk#FROM_KEY_MAP = 'map'
let eskk#FROM_STICKY_KEY_MAP = 'sticky'
let eskk#FROM_BIG_LETTER = 'big'
let eskk#FROM_MODECHANGE_KEY_MAP = 'mode'

" Normal
let eskk#HENKAN_PHASE_NORMAL = 0
" Choosing henkan candidates.
let eskk#HENKAN_PHASE_HENKAN = 1
" Waiting for okurigana.
let eskk#HENKAN_PHASE_OKURI = 2

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
    " call eskk#util#log('Initialize variables...')

    " 現在のモード
    let s:eskk_mode = ''
    " 非同期なフィルタの実行がサポートされているかどうか
    let s:filter_is_async = 0
    " 特殊なキーと、asciiモードなどで挿入する文字
    let s:map = eskk#map#new()
    " サポートしているモード
    let s:available_modes = []

    call s:initialize_buffer_table()
endfunc "}}}

func! s:reset_variables() "{{{
    call eskk#util#log('reset variables...')

    let s:eskk_mode = ''
    call s:initialize_buffer_table()
endfunc "}}}

func! s:initialize_buffer_table() "{{{
    " 変換フェーズでない状態で入力され、まだ確定していない文字列
    let g:eskk#henkan_buf_table = ['', '', '']
    " 変換キーが押された回数
    let s:henkan_count = 0
    " 現在の変換フェーズ
    let s:henkan_phase = g:eskk#HENKAN_PHASE_NORMAL
endfunc "}}}

func! s:set_up() "{{{
    " Clear current variable states.
    call s:reset_variables()

    " Register Mappings.
    call s:set_up_mappings()

    " TODO
    " Save previous mode/state.
    call eskk#set_mode(g:eskk_initial_mode)
endfunc "}}}


func! s:set_up_mappings() "{{{
    call eskk#util#log('set up mappings...')

    for char in s:get_all_chars()
        call eskk#track_key(char)
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

func! eskk#track_key(char) "{{{
    call s:execute_map(
    \   'l',
    \   '<buffer><expr><silent>',
    \   0,
    \   a:char,
    \   printf(
    \       'eskk#filter_key(%s)',
    \       string(a:char)))
endfunc "}}}

" }}}

" Utility functions {{{

func! s:get_mode_func(func_str) "{{{
    return printf('eskk#mode#%s#%s', eskk#get_mode(), a:func_str)
endfunc "}}}

" }}}

" Autoload functions {{{

func! eskk#is_enabled() "{{{
    return &iminsert == 1
endfunc "}}}

func! eskk#enable() "{{{
    if eskk#is_enabled()
        return ''
    endif

    call s:set_up()
    call eskk#util#call_if_exists(s:get_mode_func('cb_im_enter'), [], 'no throw')
    return "\<C-^>"
endfunc "}}}

func! eskk#disable() "{{{
    if !eskk#is_enabled()
        return ''
    endif

    call eskk#util#call_if_exists(s:get_mode_func('cb_im_leave'), [], 'no throw')
    return "\<C-^>"
endfunc "}}}

func! eskk#toggle() "{{{
    if eskk#is_enabled()
        return eskk#disable()
    else
        return eskk#enable()
    endif
endfunc "}}}


" This is for emergency use.
func! eskk#init_keys() "{{{
    call eskk#util#log("<Plug>(eskk-init-keys)")

    " Clear current variable states.
    call s:reset_variables()

    " Register Mappings.
    lmapclear <buffer>
    call s:set_up_mappings()

    " TODO
    " Save previous mode/state.
    call eskk#set_mode(g:eskk_initial_mode)
endfunc "}}}

func! eskk#sticky_key(again) "{{{
    call eskk#util#log("<Plug>(eskk-sticky-key)")

    if !a:again
        return eskk#filter_key('')
    else
        let henkan_phase = eskk#get_henkan_phase()
        let advance_p =
        \   eskk#util#has_idx(g:eskk#henkan_buf_table, henkan_phase + 1)
        \   && eskk#get_current_buf() !=# ''

        if advance_p
            call eskk#set_henkan_phase(henkan_phase + 1)
            return g:eskk_marker_white
        else
            return ''
        endif
    endif
endfunc "}}}


func! eskk#is_async() "{{{
    return s:filter_is_async
endfunc "}}}

func! eskk#set_mode(next_mode) "{{{
    if !eskk#is_supported_mode(a:next_mode)
        call eskk#util#warnf("mode '%s' is not supported.", a:next_mode)
        return
    endif

    call eskk#util#call_if_exists(
    \   s:get_mode_func('cb_mode_leave'),
    \   [a:next_mode],
    \   "no throw"
    \)

    let prev_mode = s:eskk_mode
    let s:eskk_mode = a:next_mode

    call s:initialize_buffer_table()

    call eskk#util#call_if_exists(
    \   s:get_mode_func('cb_mode_enter'),
    \   [prev_mode],
    \   "no throw"
    \)

    " For &statusline.
    redrawstatus
endfunc "}}}

func! eskk#get_mode() "{{{
    return s:eskk_mode
endfunc "}}}

func! eskk#is_supported_mode(mode) "{{{
    return !empty(filter(copy(s:available_modes), 'v:val ==# a:mode'))
endfunc "}}}


func! eskk#get_henkan_buf(henkan_phase) "{{{
    return g:eskk#henkan_buf_table[a:henkan_phase]
endfunc "}}}


func! eskk#get_current_buf() "{{{
    return g:eskk#henkan_buf_table[eskk#get_henkan_phase()]
endfunc "}}}

func! eskk#set_current_buf(str) "{{{
    let g:eskk#henkan_buf_table[eskk#get_henkan_phase()] = a:str
endfunc "}}}


func! eskk#get_henkan_phase() "{{{
    return s:henkan_phase
endfunc "}}}

" TODO フィルタ関数実行中はいじれないようにする？
func! eskk#set_henkan_phase(henkan_phase) "{{{
    if eskk#util#has_idx(s:henkan_phase, a:henkan_phase)
        let s:henkan_phase = a:henkan_phase
    else
        throw eskk#error#internal_error('eskk:')
    endif
endfunc "}}}


func! eskk#is_special_key(char) "{{{
    " eskk#maparg()'s 3 arg is '',
    " because a:char is already evaled.
    return eskk#maparg(a:char, '', '')
    \   || a:char =~# '^[A-Z]$'
    \   || a:char ==# "\<BS>"
    \   || a:char ==# "\<C-h>"
    \   || a:char ==# "\<Enter>"
endfunc "}}}


func! eskk#register_mode(mode) "{{{
    call add(s:available_modes, a:mode)
    let fmt = 'lnoremap <expr> <Plug>(eskk-mode-to-%s) eskk#set_mode(%s)'
    execute printf(fmt, a:mode, string(a:mode))
endfunc "}}}

func! eskk#get_registered_modes() "{{{
    return s:available_modes
endfunc "}}}


func! eskk#mapclear(...) "{{{
    let [local_mode] = eskk#util#get_args(a:000, '')
    return s:map.mapclear(local_mode)
endfunc "}}}

func! eskk#unmap(lhs, ...) "{{{
    let [local_mode] = eskk#util#get_args(a:000, '')
    return s:map.unmap(a:lhs, local_mode)
endfunc "}}}

func! eskk#map(lhs, rhs, ...) "{{{
    let [local_mode, force] = eskk#util#get_args(a:000, '', 0)
    " TODO Map a:lhs also in Vim's mapping table.
    return s:map.map(a:lhs, a:rhs, local_mode, force)
endfunc "}}}

func! eskk#maparg(lhs, ...) "{{{
    let [local_mode, options] = eskk#util#get_args(a:000, '', 'e')
    return s:map.maparg(a:lhs, local_mode, options)
endfunc "}}}

func! eskk#mapcheck(lhs, ...) "{{{
    let [local_mode] = eskk#util#get_args(a:000, '')
    return s:map.mapcheck(a:lhs, local_mode)
endfunc "}}}

" TODO
" func! eskk#hasmapto(rhs, ...) "{{{
"     let [local_mode] = eskk#util#get_args(a:000, '')
"     return s:map.hasmapto(a:rhs, local_mode)
" endfunc "}}}

" }}}

" Dispatch functions {{{

func! eskk#filter_key(char) "{{{
    if !eskk#is_supported_mode(s:eskk_mode)
        call eskk#util#warn('current mode is empty! please call eskk#init_keys()...')
        sleep 1
    endif

    " TODO
    " Dispatch function processes backspace
    " even if current buffer string is not empty.

    return s:handle_filter(a:char)
endfunc "}}}

" フィルタ用関数のディスパッチ
func! s:handle_filter(char) "{{{
    try
        let filtered = {s:get_mode_func('filter_main')}(
        \   a:char,
        \   '',
        \   eskk#get_henkan_phase(),
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


runtime! plugin/eskk.vim
call s:initialize_once()

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

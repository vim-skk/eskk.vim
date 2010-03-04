" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

runtime! plugin/eskk.vim

" Constants {{{
let eskk#FROM_KEY_MAP = 'map'
let eskk#FROM_STICKY_KEY_MAP = 'sticky'
let eskk#FROM_BIG_LETTER = 'big'
let eskk#FROM_MODECHANGE_KEY_MAP = 'mode'

let eskk#KEY_TYPE_UNKNOWN = 0
let eskk#KEY_TYPE_STICKY_KEY = 1
let eskk#KEY_TYPE_BIG_LETTER = 2

let s:BS = "\<BS>"
" }}}
" See s:initialize_once() for Variables.

" FIXME
" 1. Enable lang mode
" 2. Leave insert mode
" 3. Enter insert mode.
" Lang mode is still enabled.
"
" TODO
" - Trap CursorMovedI and
" -- s:buftable.reset()
" -- rewrite current displayed string.

" Functions {{{

" Initialize
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

    " Current mode.
    let s:eskk_mode = ''
    " Async support?
    let s:filter_is_async = 0
    " Database of mappings.
    let s:map = eskk#map#new()
    " Supported modes.
    let s:available_modes = []
    " Buffer strings for inserted, filtered, and so on.
    let s:buftable = eskk#buftable#new()
endfunc "}}}
func! s:reset_variables() "{{{
    call eskk#util#log('reset variables...')

    let s:eskk_mode = ''
    call s:buftable.reset()
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

    for key in g:eskk_mapped_key
        call eskk#track_key(key)
    endfor
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
    \       'eskk#filter_key(eskk#create_key_info(%s))',
    \       string(a:char)))
endfunc "}}}



" Utility functions
func! s:get_mode_func(func_str) "{{{
    return printf('eskk#mode#%s#%s', eskk#get_mode(), a:func_str)
endfunc "}}}



" Autoload functions
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
func! eskk#sticky_key(again, key_info) "{{{
    call eskk#util#log("<Plug>(eskk-sticky-key)")

    if !a:again
        return eskk#filter_key(eskk#create_key_info_from_type(g:eskk#KEY_TYPE_STICKY_KEY))
    else
        if s:buftable.step_henkan_phase()
            return s:buftable.get_current_marker()
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

    call s:buftable.reset()

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



" Dispatch functions
func! eskk#filter_key(key_info) "{{{
    call eskk#util#logf('a:key_info.char = %s(%d)', a:key_info.char, char2nr(a:key_info.char))
    call eskk#util#logf('a:key_info.type = %d', a:key_info.type)
    if !eskk#is_supported_mode(s:eskk_mode)
        call eskk#util#warn('current mode is empty! please call eskk#init_keys()...')
        sleep 1
    endif

    let opt = {
    \   'redispatch_keys': [],
    \   'return': 0,
    \}
    let filter_args = [
    \   a:key_info,
    \   opt,
    \   s:buftable,
    \   s:map,
    \]
    call s:buftable.set_old_str(s:buftable.get_display_str())

    try
        " TODO If mode hopes not to be processed by default filter
        if eskk#has_default_filter(a:key_info)
            call eskk#util#log('calling eskk#default_filter()...')
            call call('eskk#default_filter', filter_args)
        else
            call eskk#util#log('calling filter function...')
            call call(s:get_mode_func('filter_main'), filter_args)
        endif

        if type(opt.return) == type("")
            return opt.return
        else
            let str = s:buftable.rewrite()
            let rest = join(map(opt.redispatch_keys, 'eskk#filter_key(v:val)'), '')
            return str . rest
        endif

    catch
        " TODO Show v:exception only once in current mode.
        call eskk#util#warn('!!!!!!!!!!!!!! error !!!!!!!!!!!!!!')
        call eskk#util#warn('--- buftable ---')
        for phase in s:buftable.get_all_phases()
            let buf_str = s:buftable.get_buf_str(phase)
            call eskk#util#warnf('phase:%d', phase)
            call eskk#util#warnf('pos: %s', string(buf_str.get_pos()))
            call eskk#util#warnf('rom_str: %s', buf_str.get_rom_str())
            call eskk#util#warnf('filter_str: %s', buf_str.get_filter_str())
        endfor
        call eskk#util#warn('--- key_info ---')
        call eskk#util#warnf('char: %s', a:key_info.char)
        call eskk#util#warnf('type: %d', a:key_info.type)
        call eskk#util#warn('--- exception ---')
        call eskk#util#warnf('v:exception: %s', v:exception)
        call eskk#util#warnf('v:throwpoint: %s', v:throwpoint)
        call eskk#util#warn('!!!!!!!!!!!!!! error !!!!!!!!!!!!!!')

        call s:buftable.reset()
        return a:key_info.char

    finally
        call s:buftable.finalize()
    endtry
endfunc "}}}
func! eskk#create_key_info(char) "{{{
    return {
    \   'char': a:char,
    \   'type': s:get_key_type(a:char)
    \}
endfunc "}}}
func! s:get_key_type(char) "{{{
    let maparg = tolower(maparg(a:char, 'l'))
    if maparg =~# '<plug>(eskk-sticky-key)'
        return g:eskk#KEY_TYPE_STICKY_KEY
    elseif a:char =~# '^[A-Z]$'.'\C'
        return g:eskk#KEY_TYPE_BIG_LETTER
    else
        return g:eskk#KEY_TYPE_UNKNOWN
    endif
endfunc "}}}
func! eskk#has_default_filter(key_info) "{{{
    let [char, type] = [a:key_info.char, a:key_info.type]
    return char ==# "\<BS>"
    \   || char ==# "\<C-h>"
    \   || char ==# "\<CR>"
    \   || type ==# g:eskk#KEY_TYPE_STICKY_KEY
    \   || type ==# g:eskk#KEY_TYPE_BIG_LETTER
endfunc "}}}
func! eskk#default_filter(key_info, opt, buftable, maptable) "{{{
    let [char, type] = [a:key_info.char, a:key_info.type]
    if char ==# "\<BS>" || char ==# "\<C-h>"
        call s:do_backspace(a:key_info, a:opt, a:buftable, a:maptable)
    elseif char ==# "\<CR>"
        call s:do_enter(a:key_info, a:opt, a:buftable, a:maptable)
    elseif type ==# g:eskk#KEY_TYPE_STICKY_KEY
        return eskk#sticky_key(1, a:key_info)
    elseif type ==# g:eskk#KEY_TYPE_BIG_LETTER
        return eskk#sticky_key(1, a:key_info)
        \    . eskk#filter_key(eskk#create_key_info(tolower(char)))
    endif
endfunc "}}}
func! s:do_backspace(key_info, opt, buftable, ...) "{{{
    if a:buftable.get_old_str() == ''
        let a:opt.return = s:BS
    else
        " Build backspaces to delete previous characters.
        for buf_str in a:buftable.get_lower_buf_str()
            if buf_str.get_rom_str() != ''
                call buf_str.pop_rom_str()
                break
            elseif buf_str.get_filter_str() != ''
                call buf_str.pop_filter_str()
                break
            endif
        endfor
    endif
endfunc "}}}
func! s:do_enter(key_info, opt, buftable, ...) "{{{
    let phase = s:buftable.get_henkan_phase()
    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call a:buftable.reset()
    else
        throw eskk#error#not_implemented('eskk:')
    endif
endfunc "}}}
" }}}

call s:initialize_once()

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

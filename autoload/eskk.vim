" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

runtime! plugin/eskk.vim

" Variables {{{
let s:sticky_key_char = ''
let s:henkan_key_char = ''

" Current mode.
let s:eskk_mode = ''
" Async support?
let s:filter_is_async = 0
" Supported modes.
let s:available_modes = []
" Buffer strings for inserted, filtered and so on.
let s:buftable = eskk#buftable#new()
" }}}

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
function! s:set_up() "{{{
    call eskk#util#log('setting up eskk...')

    " Clear current variable states.
    let s:eskk_mode = ''
    call s:buftable.reset()

    " Register Mappings.
    call s:set_up_mappings()

    " TODO
    " Save previous mode/state.
    call eskk#set_mode(g:eskk_initial_mode)
endfunction "}}}
function! s:set_up_mappings() "{{{
    call eskk#util#log('set up mappings...')

    for key in g:eskk_mapped_key
        call eskk#map_key(key)
    endfor
endfunction "}}}
function! s:execute_map(modes, options, remap_p, lhs, rhs) "{{{
    for mode in split(a:modes, '\zs')
        execute printf('%s%smap', mode, (a:remap_p ? '' : 'nore'))
        \       '<buffer>' . a:options
        \       a:lhs
        \       a:rhs
    endfor
endfunction "}}}
function! eskk#map_key(char) "{{{
    call s:execute_map(
    \   'l',
    \   '<buffer><expr><silent>',
    \   0,
    \   a:char,
    \   printf(
    \       'eskk#filter_key(%s)',
    \       string(a:char)))
endfunction "}}}



" Utility functions
function! s:get_mode_func(func_str) "{{{
    return printf('eskk#mode#%s#%s', eskk#get_mode(), a:func_str)
endfunction "}}}



" Autoload functions
function! eskk#is_enabled() "{{{
    return &iminsert == 1
endfunction "}}}
function! eskk#enable() "{{{
    if eskk#is_enabled()
        return ''
    endif

    call s:set_up()
    call eskk#util#call_if_exists(s:get_mode_func('cb_im_enter'), [], 'no throw')
    return "\<C-^>"
endfunction "}}}
function! eskk#disable() "{{{
    if !eskk#is_enabled()
        return ''
    endif

    call eskk#util#call_if_exists(s:get_mode_func('cb_im_leave'), [], 'no throw')
    return "\<C-^>"
endfunction "}}}
function! eskk#toggle() "{{{
    if eskk#is_enabled()
        return eskk#disable()
    else
        return eskk#enable()
    endif
endfunction "}}}

" Sticky key
function! eskk#get_sticky_char() "{{{
    if s:sticky_key_char != ''
        return s:sticky_key_char
    endif

    redir => output
    silent lmap <buffer>
    redir END

    for line in split(output, '\n')
        let info = eskk#util#parse_map(line)
        if info.rhs ==? '<plug>(eskk-sticky-key)'
            let s:sticky_key_char = info.lhs
            return s:sticky_key_char
        endif
    endfor

    return ''
endfunction "}}}
function! eskk#sticky_key(again, stash) "{{{
    call eskk#util#log("<Plug>(eskk-sticky-key)")

    if !a:again
        return eskk#filter_key(eskk#get_sticky_char())
    else
        if s:step_henkan_phase(s:buftable)
            return s:buftable.get_current_marker()
        else
            return ''
        endif
    endif
endfunction "}}}
function! s:step_henkan_phase(buftable) "{{{
    let phase = a:buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call a:buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_HENKAN)
        return 1    " stepped.
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        call a:buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_OKURI)
        return 1    " stepped.
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        return 0    " failed.
    else
        throw eskk#internal_error('eskk:', '')
    endif
endfunction "}}}
function! eskk#is_sticky_key(char) "{{{
    let maparg = tolower(maparg(a:char, 'l'))
    return maparg ==# '<plug>(eskk-sticky-key)'
endfunction "}}}

" Henkan key
function! eskk#henkan_key(again) "{{{
    call eskk#util#log("<Plug>(eskk-henkan-key)")

    if !a:again
        return eskk#filter_key(eskk#get_henkan_key())
    else
    endif
endfunction "}}}
function! eskk#get_henkan_key() "{{{
    if s:henkan_key_char != ''
        return s:henkan_key_char
    endif

    redir => output
    silent lmap <buffer>
    redir END

    for line in split(output, '\n')
        let info = eskk#util#parse_map(line)
        if info.rhs ==? '<plug>(eskk-henkan-key)'
            let s:henkan_key_char = info.lhs
            return s:henkan_key_char
        endif
    endfor

    return ''
endfunction "}}}
function! eskk#is_henkan_key(char) "{{{
    let maparg = tolower(maparg(a:char, 'l'))
    return maparg ==# '<plug>(eskk-henkan-key)'
endfunction "}}}

" Big letter keys
function! eskk#is_big_letter(char) "{{{
    return a:char =~# '^[A-Z]$'
endfunction "}}}

function! eskk#is_async() "{{{
    return s:filter_is_async
endfunction "}}}
function! eskk#set_mode(next_mode) "{{{
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
endfunction "}}}
function! eskk#get_mode() "{{{
    return s:eskk_mode
endfunction "}}}
function! eskk#is_supported_mode(mode) "{{{
    return !empty(filter(copy(s:available_modes), 'v:val ==# a:mode'))
endfunction "}}}

function! eskk#register_mode(mode) "{{{
    call add(s:available_modes, a:mode)
    let fmt = 'lnoremap <expr> <Plug>(eskk-mode-to-%s) eskk#set_mode(%s)'
    execute printf(fmt, a:mode, string(a:mode))
endfunction "}}}
function! eskk#get_registered_modes() "{{{
    return s:available_modes
endfunction "}}}



" Dispatch functions
function! eskk#filter_key(char) "{{{
    call eskk#util#logf('a:char = %s(%d)', a:char, char2nr(a:char))
    if !eskk#is_supported_mode(s:eskk_mode)
        call eskk#util#warn('current mode is empty!')
        sleep 1
    endif

    let opt = {
    \   'redispatch_keys': [],
    \   'return': 0,
    \   'finalize_fn': [],
    \}
    let filter_args = [{
    \   'char': a:char,
    \   'option': opt,
    \   'buftable': s:buftable,
    \}]
    call s:buftable.set_old_str(s:buftable.get_display_str())

    try
        let let_me_handle = call(s:get_mode_func('cb_handle_key'), filter_args)
        call eskk#util#log('current mode handles key:'.let_me_handle)

        if !let_me_handle && eskk#has_default_filter(a:char)
            call eskk#util#log('calling eskk#default_filter()...')
            call call('eskk#default_filter', filter_args)
        else
            call eskk#util#log('calling filter function...')
            call call(s:get_mode_func('filter'), filter_args)
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
        "
        " sleep 1
        "
        call eskk#util#warn('!!!!!!!!!!!!!! error !!!!!!!!!!!!!!')
        call eskk#util#warn('--- exception ---')
        call eskk#util#warnf('v:exception: %s', v:exception)
        call eskk#util#warnf('v:throwpoint: %s', v:throwpoint)
        call eskk#util#warn('--- buftable ---')
        for phase in s:buftable.get_all_phases()
            let buf_str = s:buftable.get_buf_str(phase)
            call eskk#util#warnf('phase:%d', phase)
            call eskk#util#warnf('pos: %s', string(buf_str.get_pos()))
            call eskk#util#warnf('rom_str: %s', buf_str.get_rom_str())
            call eskk#util#warnf('filter_str: %s', buf_str.get_filter_str())
        endfor
        call eskk#util#warn('--- char ---')
        call eskk#util#warnf('char: %s', a:char)
        call eskk#util#warn('!!!!!!!!!!!!!! error !!!!!!!!!!!!!!')

        call s:buftable.reset()
        return a:char

    finally
        for Fn in opt.finalize_fn
            call call(Fn, [])
        endfor
    endtry
endfunction "}}}
function! eskk#has_default_filter(char) "{{{
    let maparg = tolower(maparg(a:char, 'l'))
    return a:char ==# "\<BS>"
    \   || a:char ==# "\<C-h>"
    \   || a:char ==# "\<CR>"
    \   || eskk#is_henkan_key(a:char)
    \   || eskk#is_sticky_key(a:char)
    \   || eskk#is_big_letter(a:char)
endfunction "}}}
function! eskk#default_filter(stash) "{{{
    call eskk#util#log('eskk#default_filter()')

    let char = a:stash.char
    " TODO Changing priority?

    if char ==# "\<BS>" || char ==# "\<C-h>"
        call s:do_backspace(a:stash)
    elseif char ==# "\<CR>"
        call s:do_enter(a:stash)
    elseif eskk#is_henkan_key(char)
        return eskk#henkan_key(1, a:stash)
    elseif eskk#is_sticky_key(char)
        return eskk#sticky_key(1, a:stash)
    elseif eskk#is_big_letter(char)
        return eskk#sticky_key(1, a:stash)
        \    . eskk#filter_key(tolower(char))
    else
        let a:stash.option.return = a:stash.char
    endif
endfunction "}}}
function! s:do_backspace(stash) "{{{
    let [opt, buftable] = [a:stash.option, a:stash.buftable]
    if buftable.get_old_str() == ''
        let opt.return = "\<BS>"
    else
        " Build backspaces to delete previous characters.
        for buf_str in buftable.get_lower_buf_str()
            if buf_str.get_rom_str() != ''
                call buf_str.pop_rom_str()
                break
            elseif buf_str.get_filter_str() != ''
                call buf_str.pop_filter_str()
                break
            endif
        endfor
    endif
endfunction "}}}
function! s:do_enter(stash) "{{{
    let buftable = a:stash.buftable
    let phase = buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call buftable.reset()
    else
        throw eskk#not_implemented_error('eskk:')
    endif
endfunction "}}}



" Errors
function! s:make_error(what, from, ...) "{{{
    if a:0 == 0
        return join([a:from, a:what], ' ')
    else
        return join([a:from, a:what . ':', a:1], ' ')
    endif
endfunction "}}}

function! eskk#internal_error(from, ...) "{{{
    return call('s:make_error', ['internal error', a:from] + a:000)
endfunction "}}}
function! eskk#not_implemented_error(from, ...) "{{{
    return call('s:make_error', ['not implemented', a:from] + a:000)
endfunction "}}}
function! eskk#never_reached_error(from, ...) "{{{
    return call('s:make_error', ['this block will be never reached', a:from] + a:000)
endfunction "}}}
function! eskk#out_of_idx_error(from, ...) "{{{
    return call('s:make_error', ['out of index', a:from] + a:000)
endfunction "}}}
function! eskk#parse_error(from, ...) "{{{
    return call('s:make_error', [':map parse error', a:from] + a:000)
endfunction "}}}
function! eskk#assertion_failure_error(from, ...) "{{{
    " This is only used from eskk#util#assert().
    return call('s:make_error', ['assertion failed', a:from] + a:000)
endfunction "}}}
function! eskk#user_error(from, msg) "{{{
    " Return simple message.
    return printf('%s: %s', a:from, a:msg)
endfunction "}}}
" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

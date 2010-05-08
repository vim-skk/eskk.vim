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
" Supported modes.
let s:available_modes = {}
" Buffer strings for inserted, filtered and so on.
let s:buftable = eskk#buftable#new()
" Lock current diff old string?
let s:lock_old_str = 0
" Event handler functions/arguments.
let s:event_hook_fn = {}
" }}}

" Write timestamp to debug file {{{
if g:eskk_debug && exists('g:eskk_debug_file') && filereadable(expand(g:eskk_debug_file))
    call writefile(['', printf('--- %s ---', strftime('%c')), ''], expand(g:eskk_debug_file))
endif
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

" Initialize/Mappings
function! s:is_no_map_key(key) "{{{
    let char = eskk#util#eval_key(a:key)

    return eskk#is_henkan_key(char)
    \   || eskk#is_sticky_key(char)
    \   || maparg(char, 'l') =~? '^<plug>(eskk:\S\+)$'
endfunction "}}}
function! eskk#map_key(key) "{{{
    " Assumption: a:key must be '<Bar>' not '|'.

    if s:is_no_map_key(a:key)
        return
    endif

    " Save current a:key mapping
    "
    " TODO Check if a:key is buffer local.
    " Because if it is not buffer local,
    " there is no necessity to stash current a:key.
    " if maparg(a:key, 'l') != ''
    "     execute
    "     \   'lnoremap'
    "     \   s:stash_lang_key_map(a:key)
    "     \   maparg(a:key, 'l')
    " endif

    " Map a:key.
    let named_key = s:map_named_key(a:key)
    execute
    \   'lmap'
    \   '<buffer>'
    \   a:key
    \   named_key
endfunction "}}}
function! eskk#unmap_key(key) "{{{
    " Assumption: a:key must be '<Bar>' not '|'.

    if s:is_no_map_key(a:key)
        return
    endif

    " Unmap a:key.
    execute
    \   'lunmap'
    \   '<buffer>'
    \   a:key

    " TODO Restore buffer local mapping.

endfunction "}}}
function! s:stash_lang_key_map(key) "{{{
    return printf('<Plug>(eskk:prevmap:%s)', a:key)
endfunction "}}}
function! s:map_named_key(key) "{{{
    " NOTE:
    " a:key is escaped. So when a:key is '<C-a>', return value is
    "   `<Plug>(eskk:filter:<C-a>)`
    " not
    "   `<Plug>(eskk:filter:^A)` (^A is control character)

    let lhs = printf('<Plug>(eskk:filter:%s)', a:key)
    if maparg(lhs, 'l') != ''
        return lhs
    endif

    " XXX: :lmap can't remap. It's possibly Vim's bug.
    " So I also prepare :noremap! mappings.
    " execute
    " \   'lmap'
    " \   '<expr>'
    " \   lhs
    " \   printf('eskk#filter(%s)', string(a:key))
    execute
    \   'map!'
    \   '<expr>'
    \   lhs
    \   printf('eskk#filter(%s)', string(a:key))

    return lhs
endfunction "}}}

function! eskk#default_mapped_keys() "{{{
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
    \]
endfunction "}}}



" Utility functions
function! s:call_mode_func(func_key, args, required) "{{{
    let st = eskk#get_mode_structure(s:eskk_mode)
    if !has_key(st, a:func_key)
        if a:required
            let msg = printf("Mode '%s' does not have required function key", s:eskk_mode)
            throw eskk#internal_error(['eskk'], msg)
        endif
        return
    endif
    return call(st[a:func_key], a:args, st)
endfunction "}}}
function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID



" Enable/Disable IM
function! eskk#is_enabled() "{{{
    return &iminsert != 0
endfunction "}}}
function! eskk#enable() "{{{
    if eskk#is_enabled()
        return ''
    endif
    call eskk#util#log('enabling eskk...')

    " Clear current variable states.
    let s:eskk_mode = ''
    call s:buftable.reset()

    " Set up Mappings.
    lmapclear <buffer>
    for key in g:eskk_mapped_key
        call eskk#map_key(key)
    endfor

    " TODO Save previous mode/state.
    call eskk#set_mode(g:eskk_initial_mode)

    call s:call_mode_func('cb_im_enter', [], 0)
    return "\<C-^>"
endfunction "}}}
function! eskk#disable() "{{{
    if !eskk#is_enabled()
        return ''
    endif
    call eskk#util#log('disabling eskk...')

    for key in g:eskk_mapped_key
        call eskk#unmap_key(key)
    endfor

    call s:call_mode_func('cb_im_leave', [], 0)
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
function! eskk#get_sticky_key() "{{{
    if s:sticky_key_char != ''
        return s:sticky_key_char
    endif

    redir => output
    silent lmap
    redir END

    for line in split(output, '\n')
        let info = eskk#util#parse_map(line)
        if info.rhs ==? '<plug>(eskk:sticky-key)'
            let s:sticky_key_char = info.lhs
            return s:sticky_key_char
        endif
    endfor

    call eskk#util#log('failed to get sticky character...')
    return ''
endfunction "}}}
function! eskk#get_sticky_char() "{{{
    return eskk#util#eval_key(eskk#get_sticky_key())
endfunction "}}}
function! eskk#sticky_key(again, stash) "{{{
    call eskk#util#log("<Plug>(eskk:sticky-key)")

    if !a:again
        return eskk#filter(eskk#get_sticky_char())
    else
        let buftable = a:stash.buftable
        if buftable.step_henkan_phase()
            call eskk#util#logf("Succeeded to step to next henkan phase. (current: %d)", buftable.get_henkan_phase())
            return buftable.get_current_marker()
        else
            call eskk#util#logf("Failed to step to next henkan phase. (current: %d)", buftable.get_henkan_phase())
            return ''
        endif
    endif
endfunction "}}}
function! eskk#is_sticky_key(char) "{{{
    return maparg(a:char, 'l') ==? '<plug>(eskk:sticky-key)'
endfunction "}}}

" Henkan key
function! eskk#get_henkan_key() "{{{
    if s:henkan_key_char != ''
        return s:henkan_key_char
    endif

    redir => output
    silent lmap
    redir END

    for line in split(output, '\n')
        let info = eskk#util#parse_map(line)
        if info.rhs ==? '<plug>(eskk:henkan-key)'
            let s:henkan_key_char = info.lhs
            return s:henkan_key_char
        endif
    endfor

    call eskk#util#log('failed to get henkan character...')
    return ''
endfunction "}}}
function! eskk#get_henkan_char() "{{{
    return eskk#util#eval_key(eskk#get_henkan_key())
endfunction "}}}
function! eskk#is_henkan_key(char) "{{{
    return maparg(a:char, 'l') ==? '<plug>(eskk:henkan-key)'
endfunction "}}}

" Big letter keys
function! eskk#is_big_letter(char) "{{{
    return a:char =~# '^[A-Z]$'
endfunction "}}}

" Escape key
function! eskk#escape_key() "{{{
    let bs_len = eskk#util#mb_strlen(s:buftable.get_display_str())
    call s:buftable.reset()
    return repeat("\<BS>", bs_len) . "\<Esc>"
endfunction "}}}

" Mode
function! eskk#set_mode(next_mode) "{{{
    if !eskk#is_supported_mode(a:next_mode)
        call eskk#util#warnf("mode '%s' is not supported.", a:next_mode)
        call eskk#util#dump_log('s:available_modes', s:available_modes)
        return
    endif

    call eskk#throw_event('leave-mode-' . s:eskk_mode)

    " Change mode.
    let prev_mode = s:eskk_mode
    let s:eskk_mode = a:next_mode

    " Reset buftable.
    call s:buftable.reset()

    " cb_mode_enter
    call s:call_mode_func('cb_mode_enter', [s:eskk_mode], 0)

    call eskk#throw_event('enter-mode-' . s:eskk_mode)

    " For &statusline.
    redrawstatus
endfunction "}}}
function! eskk#get_mode() "{{{
    return s:eskk_mode
endfunction "}}}
function! eskk#is_supported_mode(mode) "{{{
    return has_key(s:available_modes, a:mode)
endfunction "}}}
function! eskk#register_mode(mode, ...) "{{{
    let mode_self = a:0 != 0 ? a:1 : {}
    let s:available_modes[a:mode] = extend(mode_self, eskk#get_default_mode_structure(), 'force')
endfunction "}}}
function! eskk#validate_mode_structure(mode) "{{{
    " It should be good to call this function at the end of mode register.

    let st = eskk#get_mode_structure(a:mode)

    for key in ['filter', 'cb_handle_key']
        if !has_key(st, key)
            throw eskk#user_error(['eskk'], printf("eskk#register_mode(%s): %s is not present in structure", string(a:mode), string(key)))
        endif
    endfor
endfunction "}}}
function! eskk#get_default_mode_structure() "{{{
    return {}
endfunction "}}}
function! eskk#get_mode_structure(mode) "{{{
    if !eskk#is_supported_mode(a:mode)
        throw eskk#user_error(['eskk'], printf("mode '%s' is not available.", a:mode))
    endif
    return s:available_modes[a:mode]
endfunction "}}}

" Buftable
function! eskk#get_buftable() "{{{
    return s:buftable
endfunction "}}}
function! eskk#rewrite() "{{{
    return s:buftable.rewrite()
endfunction "}}}

" Event
function! eskk#register_event(event_name, Fn, args) "{{{
    if !has_key(s:event_hook_fn, a:event_name)
        let s:event_hook_fn[a:event_name] = []
    endif
    call add(s:event_hook_fn[a:event_name], [a:Fn, a:args])
endfunction "}}}
function! eskk#throw_event(event_name) "{{{
    for [Fn, args] in get(s:event_hook_fn, a:event_name, [])
        call call(Fn, args)
        unlet Fn
    endfor
endfunction "}}}

" Locking diff old string
function! eskk#lock_old_str() "{{{
    let s:lock_old_str = 1
endfunction "}}}
function! eskk#unlock_old_str() "{{{
    let s:lock_old_str = 0
endfunction "}}}



" Dispatch functions
function! eskk#filter(char) "{{{
    return s:filter(a:char, 's:filter_body_call_mode_or_default_filter', [])
endfunction "}}}
function! eskk#call_via_filter(Fn, head_args, ...) "{{{
    let char = a:0 != 0 ? a:1 : ''
    return s:filter(char, a:Fn, a:head_args)
endfunction "}}}
function! s:filter(char, Fn, head_args) "{{{
    call eskk#util#logf('a:char = %s(%d)', a:char, char2nr(a:char))
    if !eskk#is_supported_mode(s:eskk_mode)
        call eskk#util#warn('current mode is empty!')
        sleep 1
    endif

    let opt = {
    \   'redispatch_chars': [],
    \   'return': 0,
    \   'finalize_fn': [],
    \}
    let filter_args = [{
    \   'char': a:char,
    \   'option': opt,
    \   'buftable': s:buftable,
    \}]
    if !s:lock_old_str
        call s:buftable.set_old_str(s:buftable.get_display_str())
    endif

    try
        call call(a:Fn, a:head_args + filter_args)

        if type(opt.return) == type("")
            return opt.return
        else
            " XXX:
            "     s:map_named_key(char)
            " should
            "     s:map_named_key(eskk#util#uneval_key(char))

            return
            \   eskk#rewrite()
            \   . join(map(opt.redispatch_chars, 'eskk#util#eval_key(s:map_named_key(v:val))'), '')
        endif

    catch
        " TODO Show v:exception only once in current mode.
        " TODO Or open another buffer for showing this annoying messages.
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
            call eskk#util#warnf('rom_str: %s', string(buf_str.get_rom_str()))
            call eskk#util#warnf('filter_str: %s', string(buf_str.get_filter_str()))
        endfor
        call eskk#util#warn('--- char ---')
        call eskk#util#warnf('char: %s', a:char)
        call eskk#util#warn('!!!!!!!!!!!!!! error !!!!!!!!!!!!!!')

        return eskk#escape_key() . a:char

    finally
        for Fn in opt.finalize_fn
            call call(Fn, [])
        endfor
    endtry
endfunction "}}}
function! s:filter_body_call_mode_or_default_filter(stash) "{{{
    let let_me_handle = s:call_mode_func('cb_handle_key', [a:stash], 1)
    call eskk#util#log('current mode handles key?:'.let_me_handle)

    if !let_me_handle && eskk#has_default_filter(a:stash.char)
        call eskk#util#log('calling eskk#default_filter()...')
        call call('eskk#default_filter', [a:stash])
    else
        call eskk#util#log('calling filter function...')
        call s:call_mode_func('filter', [a:stash], 1)
    endif
endfunction "}}}
function! eskk#has_default_filter(char) "{{{
    let maparg = tolower(maparg(a:char, 'l'))
    return a:char ==# "\<BS>"
    \   || a:char ==# "\<C-h>"
    \   || a:char ==# "\<CR>"
    \   || eskk#is_sticky_key(a:char)
    \   || eskk#is_big_letter(a:char)
endfunction "}}}
function! eskk#default_filter(stash) "{{{
    let char = a:stash.char
    " TODO Changing priority?

    call eskk#lock_old_str()
    try
        if char ==# "\<BS>" || char ==# "\<C-h>"
            call s:do_backspace(a:stash)
        elseif char ==# "\<CR>"
            call s:do_enter(a:stash)
        elseif eskk#is_sticky_key(char)
            return eskk#sticky_key(1, a:stash)
        elseif eskk#is_big_letter(char)
            return eskk#sticky_key(1, a:stash)
            \    . eskk#filter(tolower(char))
        else
            let a:stash.option.return = a:stash.char
        endif
    finally
        call eskk#unlock_old_str()
    endtry
endfunction "}}}
function! s:do_backspace(stash) "{{{
    let [opt, buftable] = [a:stash.option, a:stash.buftable]
    if buftable.get_old_str() == ''
        let opt.return = "\<BS>"
    else
        " Build backspaces to delete previous characters.
        for phase in buftable.get_lower_phases()
            let buf_str = buftable.get_buf_str(phase)
            if buf_str.get_rom_str() != ''
                call buf_str.pop_rom_str()
                break
            elseif buf_str.get_filter_str() != ''
                call buf_str.pop_filter_str()
                break
            elseif buftable.get_marker(phase) != ''
                if !buftable.step_back_henkan_phase()
                    let msg = "Normal phase's marker is empty, "
                    \       . "and other phases *should* be able to change "
                    \       . "current henkan phase."
                    throw eskk#internal_error(['eskk'], msg)
                endif
                break
            endif
        endfor
    endif
endfunction "}}}
function! s:do_enter(stash) "{{{
    call eskk#util#log("s:do_enter()")

    let buftable = a:stash.buftable
    let normal_buf_str        = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    let henkan_buf_str        = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    let okuri_buf_str         = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
    let henkan_select_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
    let phase = buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        let a:stash.option.return = "\<CR>"
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        call buftable.move_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN, g:eskk#buftable#HENKAN_PHASE_NORMAL)

        function! s:finalize()
            if s:buftable.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
                let buf_str = eskk#get_buftable().get_current_buf_str()
                call buf_str.clear_filter_str()
            endif
        endfunction
        call add(
        \   a:stash.option.finalize_fn,
        \   eskk#util#get_local_func('finalize', s:SID_PREFIX)
        \)

        call buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        call buftable.move_buf_str([g:eskk#buftable#HENKAN_PHASE_HENKAN, g:eskk#buftable#HENKAN_PHASE_OKURI], g:eskk#buftable#HENKAN_PHASE_NORMAL)

        function! s:finalize()
            if s:buftable.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
                let buf_str = eskk#get_buftable().get_current_buf_str()
                call buf_str.clear_filter_str()
            endif
        endfunction
        call add(
        \   a:stash.option.finalize_fn,
        \   eskk#util#get_local_func('finalize', s:SID_PREFIX)
        \)

        call buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        call buftable.move_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT, g:eskk#buftable#HENKAN_PHASE_NORMAL)

        function! s:finalize()
            if s:buftable.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
                let buf_str = eskk#get_buftable().get_current_buf_str()
                call buf_str.clear_filter_str()
            endif
        endfunction
        call add(
        \   a:stash.option.finalize_fn,
        \   eskk#util#get_local_func('finalize', s:SID_PREFIX)
        \)

        call buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
    else
        throw eskk#not_implemented_error(['eskk'])
    endif
endfunction "}}}



" Errors
function! s:build_error(from, msg) "{{{
    return join(a:from, ': ') . ' - ' . join(a:msg, ': ')
endfunction "}}}

function! eskk#internal_error(from, ...) "{{{
    return s:build_error(a:from, ['internal error'] + a:000)
endfunction "}}}
function! eskk#not_implemented_error(from, ...) "{{{
    return s:build_error(a:from, ['not implemented'] + a:000)
endfunction "}}}
function! eskk#never_reached_error(from, ...) "{{{
    return s:build_error(a:from, ['this block will be never reached'] + a:000)
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
" }}}


" Auto commands {{{
augroup eskk
    autocmd!
    autocmd InsertLeave * call s:buftable.reset()
augroup END
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

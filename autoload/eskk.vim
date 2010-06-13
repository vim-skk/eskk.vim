" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/eskk.vim' about the license.

" Load once {{{
if exists('s:loaded')
    finish
endif
let s:loaded = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}
runtime! plugin/eskk.vim

augroup eskk
autocmd!

" Variables {{{
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
" True if eskk#enable() is called.
let s:enabled = 0
" Temporary mappings while eskk.vim is on.
let s:map = {
\   'general': {},
\   'sticky': {},
\   'henkan': {},
\   'escape': {},
\   'henkan-select:choose-next': {},
\   'henkan-select:choose-prev': {},
\}
" }}}

" Functions {{{

function! eskk#load() "{{{
    runtime! plugin/eskk.vim
endfunction "}}}



" Initialize/Mappings
function! eskk#map_key(key, ...) "{{{
    if a:0
        return s:map_key(a:key, s:mapopt_chars2dict(a:1))
    else
        return s:map_key(a:key, s:create_default_mapopt())
    endif
endfunction "}}}
function! s:map_key(key, raw_options) "{{{
    " Assumption: a:key must be '<Bar>' not '|'.

    " Map a:key.
    let named_key = s:map_named_key(a:key)
    execute
    \   'lmap'
    \   '<buffer>' . s:mapopt_dict2raw(a:raw_options)
    \   a:key
    \   named_key
endfunction "}}}
function! eskk#map_temp_key(lhs, rhs) "{{{
    " Assumption: a:lhs must be '<Bar>' not '|'.

    " Save current a:lhs mapping.
    if maparg(a:lhs, 'l') != ''
        " TODO Check if a:lhs is buffer local.
        call eskk#util#log('Save temp key: ' . maparg(a:lhs, 'l'))
        execute
        \   'lmap'
        \   '<buffer>'
        \   s:temp_key_map(a:lhs)
        \   maparg(a:lhs, 'l')
    endif

    " Map a:lhs.
    execute
    \   'lmap'
    \   '<buffer>'
    \   a:lhs
    \   a:rhs
endfunction "}}}
function! eskk#map_temp_key_restore(lhs) "{{{
    let temp_key = s:temp_key_map(a:lhs)
    let saved_rhs = maparg(temp_key, 'l')

    if saved_rhs != ''
        call eskk#util#log('Restore saved temp key: ' . saved_rhs)
        execute 'lunmap <buffer>' temp_key
        execute 'lmap <buffer>' a:lhs saved_rhs
    else
        call eskk#util#logf("warning: called eskk#map_temp_key_restore() but no '%s' key is stashed.", a:lhs)
        call eskk#map_key(a:lhs)
    endif
endfunction "}}}
function! eskk#unmap_key(key) "{{{
    " Assumption: a:key must be '<Bar>' not '|'.

    " Unmap a:key.
    execute
    \   'lunmap'
    \   '<buffer>'
    \   a:key

    " TODO Restore buffer local mapping?
endfunction "}}}
function! s:temp_key_map(key) "{{{
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

function! eskk#map(type, options, lhs, rhs) "{{{
    return s:map_raw_options(a:type, s:mapopt_chars2dict(a:options), a:lhs, a:rhs, 'eskk#map()')
endfunction "}}}
function! s:map_raw_options(type, raw_options, lhs, rhs, from) "{{{
    let lhs = a:lhs
    if lhs == ''
        echoerr "lhs must not be empty string."
        return
    endif
    if !has_key(s:map, a:type)
        echoerr "eskk#map(): unknown type: " . a:type
        return
    endif
    let type_st = s:map[a:type]

    if a:type ==# 'general'
        if has_key(type_st, lhs) && a:raw_options.unique
            echoerr printf("%s: Already mapped to '%s'.", a:from, lhs)
            return
        endif
        let type_st[lhs] = {
        \   'options': a:raw_options,
        \   'rhs': a:rhs
        \}
    else
        let type_st.options = a:raw_options
        let type_st.lhs = lhs
    endif
endfunction "}}}
function! s:mapopt_chars2dict(options) "{{{
    let opt = s:create_default_mapopt()
    for c in split(a:options, '\zs')
        if c ==# 'b'
            let opt.buffer = 1
        elseif c ==# 'e'
            let opt.expr = 1
        elseif c ==# 's'
            let opt.silent = 1
        elseif c ==# 'u'
            let opt.unique = 1
        elseif c ==# 'r'
            let opt.remap = 1
        endif
    endfor
    return opt
endfunction "}}}
function! s:mapopt_dict2raw(options) "{{{
    let ret = ''
    for [key, val] in items(a:options)
        if key ==# 'remap'
            continue
        endif
        if val
            let ret .= printf('<%s>', key)
        endif
    endfor
    return ret
endfunction "}}}
function! s:create_default_mapopt() "{{{
    return {
    \   'buffer': 0,
    \   'expr': 0,
    \   'silent': 0,
    \   'unique': 0,
    \   'remap': 0,
    \}
endfunction "}}}

function! s:skip_white(args) "{{{
    return substitute(a:args, '^\s*', '', '')
endfunction "}}}
function! s:parse_one_arg_from_q_args(args) "{{{
    let arg = s:skip_white(a:args)
    let head = matchstr(arg, '^.\{-}[^\\]\ze\([ \t]\|$\)')
    let rest = strpart(arg, strlen(head))
    return [head, rest]
endfunction "}}}
function! s:parse_options(args) "{{{
    let args = a:args
    let type = 'general'
    let opt = s:create_default_mapopt()
    let opt.noremap = 0

    while !empty(args)
        let [a, rest] = s:parse_one_arg_from_q_args(args)
        if a[0] !=# '-'
            break
        endif
        let args = rest

        if a ==# '--'
            break
        elseif a[0] ==# '-'
            if a[1:] ==# 'expr'
                let opt.expr = 1
            elseif a[1:] ==# 'noremap'
                let opt.noremap = 1
            elseif a[1:] ==# 'buffer'
                let opt.buffer = 1
            elseif a[1:] ==# 'silent'
                let opt.silent = 1
            elseif a[1:] ==# 'special'
                let opt.special = 1
            elseif a[1:] ==# 'script'
                let opt.script = 1
            elseif a[1:] ==# 'unique'
                let opt.unique = 1
            elseif a[1:4] ==# 'type'
                if a =~# '^-type='
                    " TODO Allow -type="..." style?
                    " But I don't suppose that -type's argument cotains whitespaces.
                    let type = substitute(a, '^-type=', '', '')
                else
                    throw eskk#parse_error(['eskk'], "-type must be '-type=...' style.")
                endif
            else
                throw eskk#parse_error(['eskk'], printf("unknown option '%s'.", a))
            endif
        endif
    endwhile

    let opt.remap = !opt.noremap
    call remove(opt, 'noremap')
    return [opt, type, args]
endfunction "}}}
function! eskk#_cmd_eskk_map(args) "{{{
    let [options, type, args] = s:parse_options(a:args)

    let args = s:skip_white(args)
    let [lhs, args] = s:parse_one_arg_from_q_args(args)

    let args = s:skip_white(args)
    if args == ''
        call s:map_raw_options(type, options, lhs, '', 'EskkMap')
        return
    endif

    call s:map_raw_options(type, options, lhs, args, 'EskkMap')
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
    return s:enabled
endfunction "}}}
function! eskk#enable() "{{{
    if eskk#is_enabled()
        return ''
    endif
    call eskk#util#log('enabling eskk...')

    " If skk.vim exists and enabled, disable it.
    let disable_skk_vim = exists('g:skk_version') ? SkkDisable() : ''


    " Clear current variable states.
    let s:eskk_mode = ''
    call s:buftable.reset()


    " Set up Mappings.
    lmapclear <buffer>

    for key in g:eskk_mapped_key
        call eskk#map_key(key)
    endfor

    for [key, opt] in items(s:map.general)
        if opt.rhs == ''
            call eskk#map_key(key, opt.unique)
        else
            execute
            \   printf('l%smap', (opt.options.remap ? '' : 'nore'))
            \   '<buffer>' . s:mapopt_dict2raw(opt.options)
            \   key
            \   opt.rhs
        endif
    endfor


    " TODO Save previous mode/state.
    call eskk#set_mode(g:eskk_initial_mode)

    call s:call_mode_func('cb_im_enter', [], 0)

    let s:enabled = 1
    return disable_skk_vim . "\<C-^>"
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

    let s:enabled = 0

    let kakutei_str = eskk#kakutei_str()
    call s:buftable.reset()
    return kakutei_str . "\<C-^>"
endfunction "}}}
function! eskk#toggle() "{{{
    if eskk#is_enabled()
        return eskk#disable()
    else
        return eskk#enable()
    endif
endfunction "}}}

" Manipulate display string.
function! eskk#remove_display_str() "{{{
    let current_str = s:buftable.get_display_str()
    return repeat("\<C-h>", eskk#util#mb_strlen(current_str))
endfunction "}}}
function! eskk#kakutei_str() "{{{
    return eskk#remove_display_str() . s:buftable.get_display_str(0)
endfunction "}}}

" Sticky key
function! eskk#get_sticky_key() "{{{
    return s:map.sticky.lhs
endfunction "}}}
function! eskk#get_sticky_char() "{{{
    return eskk#util#eval_key(eskk#get_sticky_key())
endfunction "}}}
function! eskk#is_sticky_key(char) "{{{
    " TODO Cache result of eskk#util#eval_key() ?
    return eskk#util#eval_key(s:map.sticky.lhs) ==# a:char
endfunction "}}}
function! eskk#sticky_key(stash) "{{{
    let buftable = a:stash.buftable
    if buftable.step_henkan_phase()
        call eskk#util#logf("eskk#sticky_key(): Succeeded to step to next henkan phase. (current: %d)", buftable.get_henkan_phase())
        return buftable.get_current_marker()
    else
        call eskk#util#logf("eskk#sticky_key(): Failed to step to next henkan phase. (current: %d)", buftable.get_henkan_phase())
        return ''
    endif
endfunction "}}}

" Henkan key
function! eskk#get_henkan_key() "{{{
    return s:map.henkan.lhs
endfunction "}}}
function! eskk#get_henkan_char() "{{{
    return eskk#util#eval_key(eskk#get_henkan_key())
endfunction "}}}
function! eskk#is_henkan_key(char) "{{{
    " TODO Cache result of eskk#util#eval_key() ?
    return eskk#util#eval_key(s:map.henkan.lhs) ==# a:char
endfunction "}}}

" Big letter keys
function! eskk#is_big_letter(char) "{{{
    return a:char =~# '^[A-Z]$'
endfunction "}}}

" Escape key
function! eskk#escape_key() "{{{
    let kakutei_str = eskk#kakutei_str()
    call s:buftable.reset()
    return kakutei_str . "\<Esc>"
endfunction "}}}

" Mode
function! eskk#set_mode(next_mode) "{{{
    call eskk#util#logf("mode change: %s => %s", s:eskk_mode, a:next_mode)
    if !eskk#is_supported_mode(a:next_mode)
        call eskk#util#warnf("mode '%s' is not supported.", a:next_mode)
        call eskk#util#warnf('s:available_modes = %s', string(s:available_modes))
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
    let s:available_modes[a:mode] = mode_self
endfunction "}}}
function! eskk#validate_mode_structure(mode) "{{{
    " It should be good to call this function at the end of mode register.

    let st = eskk#get_mode_structure(a:mode)

    for key in ['filter']
        if !has_key(st, key)
            throw eskk#user_error(['eskk'], printf("eskk#register_mode(%s): %s is not present in structure", string(a:mode), string(key)))
        endif
    endfor
endfunction "}}}
function! eskk#get_mode_structure(mode) "{{{
    if !eskk#is_supported_mode(a:mode)
        throw eskk#user_error(['eskk'], printf("mode '%s' is not available.", a:mode))
    endif
    return s:available_modes[a:mode]
endfunction "}}}

" Statusline
function! eskk#get_stl() "{{{
    " TODO Add these strings to each mode structure.
    let mode_str = {'hira': 'あ', 'kata': 'ア', 'ascii': 'a', 'zenei': 'ａ'}
    return eskk#is_enabled() ? printf('[eskk:%s]', get(mode_str, s:eskk_mode, '??')) : ''
endfunction "}}}

" Buftable
function! eskk#get_buftable() "{{{
    return s:buftable
endfunction "}}}
function! eskk#rewrite() "{{{
    return s:buftable.rewrite()
endfunction "}}}

" Event
function! eskk#register_event(event_names, Fn, head_args) "{{{
    return s:register_event(a:event_names, a:Fn, a:head_args, 0)
endfunction "}}}
function! eskk#register_temp_event(event_names, Fn, head_args) "{{{
    return s:register_event(a:event_names, a:Fn, a:head_args, 1)
endfunction "}}}
function! s:register_event(event_names, Fn, head_args, is_temporary) "{{{
    for name in (type(a:event_names) == type([]) ? a:event_names : [a:event_names])
        if !has_key(s:event_hook_fn, name)
            let s:event_hook_fn[name] = []
        endif
        call add(s:event_hook_fn[name], [a:Fn, a:head_args, a:is_temporary])
    endfor
endfunction "}}}
function! eskk#throw_event(event_name) "{{{
    call eskk#util#log("Do event - " . a:event_name)

    let list = get(s:event_hook_fn, a:event_name, [])
    let len = len(list)
    let i = 0

    while i < len
        let [Fn, args, is_temporary] = list[i]
        if is_temporary
            call remove(list, i)
        endif
        call call(Fn, args)

        let i += 1
        unlet Fn
    endwhile
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
    \}
    let filter_args = [{
    \   'char': a:char,
    \   'option': opt,
    \   'buftable': s:buftable,
    \}]

    if !s:lock_old_str
        call s:buftable.set_old_str(s:buftable.get_display_str())
    endif

    call s:buftable.get_current_buf_str().push_phase_str(a:char)

    call eskk#throw_event('filter-begin')

    try
        call call(a:Fn, a:head_args + filter_args)

        if type(opt.return) == type("")
            return opt.return
        else
            " XXX:
            "     s:map_named_key(char)
            " should
            "     s:map_named_key(eskk#util#uneval_key(char))

            " TODO: Do not remap.
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
        call s:buftable.dump_print()
        call eskk#util#warn('--- char ---')
        call eskk#util#warnf('char: %s', a:char)
        call eskk#util#warn('!!!!!!!!!!!!!! error !!!!!!!!!!!!!!')

        return eskk#escape_key() . a:char

    finally
        call eskk#throw_event('filter-finalize')
    endtry
endfunction "}}}
function! s:filter_body_call_mode_or_default_filter(stash) "{{{
    call s:call_mode_func('filter', [a:stash], 1)
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

" Write timestamp to debug file {{{
if g:eskk_debug && exists('g:eskk_debug_file') && filereadable(expand(g:eskk_debug_file))
    call writefile(['', printf('--- %s ---', strftime('%c')), ''], expand(g:eskk_debug_file))
endif
" }}}
" Egg-like-newline {{{
if !g:eskk_egg_like_newline
    function! s:register_egg_like_newline_event()
        " Default behavior is `egg like newline`.
        " Turns it to `Non egg like newline` during henkan phase.
        call eskk#register_event('enter-phase-henkan-select', 'eskk#mode#builtin#do_lmap_non_egg_like_newline', [1])
        call eskk#register_event('enter-phase-normal', 'eskk#mode#builtin#do_lmap_non_egg_like_newline', [0])
    endfunction
    autocmd VimEnter * call s:register_egg_like_newline_event()
endif
" }}}
" InsertLeave {{{
function! s:autocmd_insert_leave() "{{{
    call s:buftable.reset()

    if !g:eskk_keep_state && eskk#is_enabled()
        let disable = eskk#disable()
        noautocmd execute 'normal! i' . disable
    endif
endfunction "}}}
autocmd InsertLeave * call s:autocmd_insert_leave()
" }}}
" Default mappings - :EskkMap {{{
function! s:do_default_mappings() "{{{
    EskkMap -type=sticky -unique ;
    EskkMap -type=henkan -unique <Space>
    EskkMap -type=escape -unique <Esc>
    EskkMap -type=henkan-select:choose-next -unique <Space>
    EskkMap -type=henkan-select:choose-prev -unique x
endfunction "}}}
autocmd VimEnter * call s:do_default_mappings()
" }}}

augroup END

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

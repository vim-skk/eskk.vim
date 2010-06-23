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

function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID

augroup eskk
autocmd!

" s:eskk {{{
" mode: Current mode.
" buftable: Buffer strings for inserted, filtered and so on.
" is_locked_old_str: Lock current diff old string?
" temp_event_hook_fn: Temporary event handler functions/arguments.
" enabled: True if s:eskk.enable() is called.
let s:eskk = {
\   'mode': '',
\   'buftable': eskk#buftable#new(),
\   'is_locked_old_str': 0,
\   'temp_event_hook_fn': {},
\   'enabled': 0,
\   'stash': {},
\   'added_words': [],
\   'prev_henkan_result': {},
\}

function! s:eskk_new() "{{{
    return deepcopy(s:eskk, 1)
endfunction "}}}

" Enable/Disable IM
function! s:eskk.enable(...) dict "{{{
    let do_map = a:0 != 0 ? a:1 : 1

    if self.is_enabled()
        return ''
    endif
    call eskk#util#log('enabling eskk...')

    " If skk.vim exists and enabled, disable it.
    let disable_skk_vim = ''
    if exists('g:skk_version') && exists('b:skk_on') && b:skk_on
        let disable_skk_vim = SkkDisable()
    endif


    " Clear current variable states.
    let self.mode = ''
    call self.buftable.reset()


    " Set up Mappings.
    if do_map
        call self.map_all_keys()
    endif


    " TODO Save previous mode/state.
    call self.set_mode(g:eskk_initial_mode)

    call self.call_mode_func('cb_im_enter', [], 0)

    let self.enabled = 1
    return disable_skk_vim . "\<C-^>"
endfunction "}}}
function! s:eskk.disable(...) dict "{{{
    let do_unmap = a:0 != 0 ? a:1 : 0

    if !self.is_enabled()
        return ''
    endif
    call eskk#util#log('disabling eskk...')

    if do_unmap
        call self.unmap_all_keys()
    endif

    call self.call_mode_func('cb_im_leave', [], 0)

    let self.enabled = 0

    let kakutei_str = eskk#kakutei_str()
    call self.buftable.reset()
    return kakutei_str . "\<C-^>"
endfunction "}}}
function! s:eskk.toggle() dict "{{{
    return self[self.is_enabled() ? 'disable' : 'enable']()
endfunction "}}}
function! s:eskk.is_enabled() dict "{{{
    return self.enabled
endfunction "}}}

" Mappings
function! s:eskk.map_all_keys(...) dict "{{{
    if has_key(s:has_mapped, bufnr('%'))
        return
    endif


    lmapclear <buffer>

    " Map mapped keys.
    for key in g:eskk_mapped_key
        call call('eskk#set_up_key', [key] + a:000)
    endfor

    " Map escape key.
    execute
    \   'lmap'
    \   '<buffer><expr>' . (a:0 ? s:mapopt_chars2raw(a:1) : '')
    \   s:map.escape.lhs
    \   'eskk#escape_key()'

    " Map `:EskkMap -general` keys.
    for [key, opt] in items(s:map.general)
        if opt.rhs == ''
            call s:map_key(key, opt.options)
        else
            execute
            \   printf('l%smap', (opt.options.remap ? '' : 'nore'))
            \   '<buffer>' . s:mapopt_dict2raw(opt.options)
            \   key
            \   opt.rhs
        endif
    endfor

    call eskk#util#assert(!has_key(s:has_mapped, bufnr('%')))
    let s:has_mapped[bufnr('%')] = 1
endfunction "}}}
function! s:eskk.unmap_all_keys() dict "{{{
    if !has_key(s:has_mapped, bufnr('%'))
        return
    endif

    for key in g:eskk_mapped_key
        call eskk#unmap_key(key)
    endfor

    unlet s:has_mapped[bufnr('%')]
endfunction "}}}

" Manipulate display string.
function! s:eskk.remove_display_str() dict "{{{
    let current_str = self.buftable.get_display_str()
    return repeat("\<Plug>(eskk:_delete-char)", eskk#util#mb_strlen(current_str))
endfunction "}}}
function! s:eskk.kakutei_str() dict "{{{
    return self.remove_display_str() . self.buftable.get_display_str(0)
endfunction "}}}

" Big letter keys
function! s:eskk.is_big_letter(char) dict "{{{
    return a:char =~# '^[A-Z]$'
endfunction "}}}

" Escape key
function! s:eskk.escape_key() dict "{{{
    let kakutei_str = self.kakutei_str()
    call self.buftable.reset()
    return kakutei_str . "\<Plug>(eskk:internal:escape-key)"
endfunction "}}}

" Mode
function! s:eskk.set_mode(next_mode) dict "{{{
    call eskk#util#logf("mode change: %s => %s", self.mode, a:next_mode)
    if !self.is_supported_mode(a:next_mode)
        call eskk#util#warnf("mode '%s' is not supported.", a:next_mode)
        call eskk#util#warnf('s:available_modes = %s', string(s:available_modes))
        return
    endif

    call self.throw_event('leave-mode-' . self.mode)

    " Change mode.
    let prev_mode = self.mode
    let self.mode = a:next_mode

    " Reset buftable.
    call self.buftable.reset()

    " cb_mode_enter
    call self.call_mode_func('cb_mode_enter', [self.mode], 0)

    call self.throw_event('enter-mode-' . self.mode)

    " For &statusline.
    redrawstatus
endfunction "}}}
function! s:eskk.get_mode() dict "{{{
    return self.mode
endfunction "}}}
function! s:eskk.is_supported_mode(mode) dict "{{{
    return has_key(s:available_modes, a:mode)
endfunction "}}}
function! s:eskk.register_mode(mode, ...) dict "{{{
    let s:available_modes[a:mode] = extend(
    \   (a:0 ? a:1 : {}),
    \   {'sandbox': {}},
    \   'keep'
    \)
endfunction "}}}
function! s:eskk.validate_mode_structure(mode) dict "{{{
    " It should be good to call this function at the end of mode register.

    let st = self.get_mode_structure(a:mode)

    for key in ['filter', 'sandbox']
        if !has_key(st, key)
            throw eskk#user_error(['eskk'], printf("eskk#register_mode(%s): %s is not present in structure", string(a:mode), string(key)))
        endif
    endfor
endfunction "}}}
function! s:eskk.get_mode_structure(mode) dict "{{{
    if !self.is_supported_mode(a:mode)
        throw eskk#user_error(['eskk'], printf("mode '%s' is not available.", a:mode))
    endif
    return s:available_modes[a:mode]
endfunction "}}}
function! s:eskk.call_mode_func(func_key, args, required) dict "{{{
    let st = self.get_mode_structure(self.mode)
    if !has_key(st, a:func_key)
        if a:required
            let msg = printf("Mode '%s' does not have required function key", self.mode)
            throw eskk#internal_error(['eskk'], msg)
        endif
        return
    endif
    return call(st[a:func_key], a:args, st)
endfunction "}}}

" Statusline
function! s:eskk.get_stl() dict "{{{
    return self.is_enabled() ? printf('[eskk:%s]', get(g:eskk_statusline_mode_strings, self.mode, '??')) : ''
endfunction "}}}

" Buftable
function! s:eskk.get_buftable() dict "{{{
    return self.buftable
endfunction "}}}
function! s:eskk.set_buftable(buftable) dict "{{{
    call a:buftable.set_old_str(self.buftable.get_old_str())
    let self.buftable = a:buftable
endfunction "}}}
function! s:eskk.rewrite() dict "{{{
    return self.buftable.rewrite()
endfunction "}}}

" Event
function! s:eskk.register_event(event_names, Fn, head_args) dict "{{{
    let args = [s:event_hook_fn, a:event_names, a:Fn, a:head_args, (a:0 ? a:1 : -1)]
    return call('s:register_event', args)
endfunction "}}}
function! s:eskk.register_temp_event(event_names, Fn, head_args, ...) dict "{{{
    let args = [self.temp_event_hook_fn, a:event_names, a:Fn, a:head_args, (a:0 ? a:1 : -1)]
    return call('s:register_event', args)
endfunction "}}}
function! s:register_event(st, event_names, Fn, head_args, self) "{{{
    for name in (type(a:event_names) == type([]) ? a:event_names : [a:event_names])
        if !has_key(a:st, name)
            let a:st[name] = []
        endif
        call add(a:st[name], [a:Fn, a:head_args] + (a:self !=# -1 ? [a:self] : []))
    endfor
endfunction "}}}
function! s:eskk.has_events(event_name) dict "{{{
    return
    \   has_key(s:event_hook_fn, a:event_name)
    \   || has_key(self.temp_event_hook_fn, a:event_name)
endfunction "}}}
function! s:eskk.throw_event(event_name) dict "{{{
    call eskk#util#log("Do event - " . a:event_name)

    let ret        = []
    let event      = get(s:event_hook_fn, a:event_name, [])
    let temp_event = get(self.temp_event_hook_fn, a:event_name, [])
    for call_args in event + temp_event
        call add(ret, call('call', call_args))
    endfor

    " Clear temporary hooks.
    let self.temp_event_hook_fn[a:event_name] = []

    return ret
endfunction "}}}

" Henkan result
function! s:eskk.get_henkan_result() dict "{{{
    return self.prev_henkan_result
endfunction "}}}
function! s:eskk.set_henkan_result(henkan_result) dict "{{{
    let self.prev_henkan_result = a:henkan_result
endfunction "}}}

" Locking diff old string
function! s:eskk.lock_old_str() dict "{{{
    let self.is_locked_old_str = 1
endfunction "}}}
function! s:eskk.unlock_old_str() dict "{{{
    let self.is_locked_old_str = 0
endfunction "}}}

" Dispatch functions
function! s:eskk.filter(char) dict "{{{
    return s:filter(self, a:char, 's:filter_body_call_mode_or_default_filter', [self])
endfunction "}}}
function! s:eskk.call_via_filter(Fn, tail_args, ...) dict "{{{
    let char = a:0 != 0 ? a:1 : ''
    return s:filter(self, char, a:Fn, a:tail_args)
endfunction "}}}
function! s:filter(self, char, Fn, tail_args) "{{{
    let self = a:self

    call eskk#util#logf('a:char = %s(%d)', a:char, char2nr(a:char))
    if !self.is_supported_mode(self.mode)
        call eskk#util#warn('current mode is empty!')
        sleep 1
    endif


    call self.throw_event('filter-begin')

    let filter_args = [{
    \   'char': a:char,
    \   'return': 0,
    \}]

    if !self.is_locked_old_str
        call self.buftable.set_old_str(self.buftable.get_display_str())
    endif

    try
        call call(a:Fn, filter_args + a:tail_args)

        let ret_str = filter_args[0].return
        if type(ret_str) == type("")
            return ret_str
        else
            if self.has_events('filter-redispatch')
                " NOTE: Because of Vim's bug, `:lmap` can't remap to `:lmap`.
                map! <buffer><expr> <Plug>(eskk:_filter_redispatch) join(eskk#throw_event("filter-redispatch"))
                return
                \   self.rewrite()
                \   . "\<Plug>(eskk:_filter_redispatch)"
            else
                return self.rewrite()
            endif
        endif

    catch
        let lines = []
        call add(lines, '!!!!!!!!!!!!!! error !!!!!!!!!!!!!!')
        call add(lines, '--- exception ---')
        call add(lines, printf('v:exception: %s', v:exception))
        call add(lines, printf('v:throwpoint: %s', v:throwpoint))
        call add(lines, '--- buftable ---')
        let lines += self.buftable.dump()
        call add(lines, '--- char ---')
        call add(lines, printf('char: %s', a:char))
        call add(lines, '!!!!!!!!!!!!!! error !!!!!!!!!!!!!!')
        call add(lines, '')
        call add(lines, "Please report this error to author.")
        call add(lines, "`:help eskk` to see author's e-mail address.")

        let log_file = expand(g:eskk_error_log_file)
        call writefile(lines, log_file)

        call eskk#util#warnf(
        \   "Error has occurred!! Please see '%s' to check and please report to plugin author.",
        \   log_file
        \)

        return self.escape_key() . a:char

    finally
        call self.throw_event('filter-finalize')
    endtry
endfunction "}}}
function! s:filter_body_call_mode_or_default_filter(stash, self) "{{{
    call a:self.call_mode_func('filter', [a:stash], 1)
endfunction "}}}

" Misc.

" s:map related functions.
" TODO Move this to s:map
function! s:eskk.is_special_lhs(char, type) dict "{{{
    " NOTE: This function must not show error when `s:map[a:type]` does not exist.
    return has_key(s:map, a:type)
    \   && eskk#util#eval_key(s:map[a:type].lhs) ==# a:char
endfunction "}}}
function! s:eskk.get_special_key(type) dict "{{{
    if has_key(s:map, a:type)
        return s:map[a:type].lhs
    else
        throw eskk#internal_error(['eskk'], "Unknown map type: " . a:type)
    endif
endfunction "}}}
function! s:eskk.handle_special_lhs(char, type, stash) dict "{{{
    return
    \   self.is_special_lhs(a:char, a:type)
    \   && has_key(s:map_fn, a:type)
    \   && call(s:map_fn[a:type], [a:stash])
endfunction "}}}

lockvar s:eskk
" }}}

" Variables {{{

" These instances are created, destroyed
" at word-register mode.
let s:eskk_instances = [s:eskk_new()]
" Index number of s:eskk_instances for current instance.
let s:instance_id = 0

" NOTE: Following variables are non-local between instances.

" Supported modes and their structures.
let s:available_modes = {}
" Database for misc. keys.
let s:map = {
\   'general': {},
\   'sticky': {},
\   'escape': {},
\   'phase:henkan:henkan-key': {},
\   'phase:okuri:henkan-key': {},
\   'phase:henkan-select:choose-next': {},
\   'phase:henkan-select:choose-prev': {},
\   'phase:henkan-select:next-page': {},
\   'phase:henkan-select:prev-page': {},
\   'phase:henkan-select:escape': {},
\   'mode:hira:toggle-hankata': {},
\   'mode:hira:ctrl-q-key': {},
\   'mode:hira:toggle-kata': {},
\   'mode:hira:q-key': {},
\   'mode:hira:to-ascii': {},
\   'mode:hira:to-zenei': {},
\   'mode:kata:toggle-hankata': {},
\   'mode:kata:ctrl-q-key': {},
\   'mode:kata:toggle-kata': {},
\   'mode:kata:q-key': {},
\   'mode:kata:to-ascii': {},
\   'mode:kata:to-zenei': {},
\   'mode:hankata:toggle-hankata': {},
\   'mode:hankata:ctrl-q-key': {},
\   'mode:hankata:toggle-kata': {},
\   'mode:hankata:q-key': {},
\   'mode:hankata:to-ascii': {},
\   'mode:hankata:to-zenei': {},
\   'mode:ascii:to-hira': {},
\   'mode:zenei:to-hira': {},
\}
" TODO s:map should contain this info.
" Keys used by only its mode.
let s:mode_local_keys = {
\   'hira': [
\       'phase:henkan:henkan-key',
\       'phase:okuri:henkan-key',
\       'phase:henkan-select:choose-next',
\       'phase:henkan-select:choose-prev',
\       'phase:henkan-select:next-page',
\       'phase:henkan-select:prev-page',
\       'phase:henkan-select:escape',
\       'mode:hira:toggle-hankata',
\       'mode:hira:ctrl-q-key',
\       'mode:hira:toggle-kata',
\       'mode:hira:q-key',
\       'mode:hira:to-ascii',
\       'mode:hira:to-zenei',
\   ],
\   'kata': [
\       'phase:henkan:henkan-key',
\       'phase:okuri:henkan-key',
\       'phase:henkan-select:choose-next',
\       'phase:henkan-select:choose-prev',
\       'phase:henkan-select:next-page',
\       'phase:henkan-select:prev-page',
\       'phase:henkan-select:escape',
\       'mode:kata:toggle-hankata',
\       'mode:kata:ctrl-q-key',
\       'mode:kata:toggle-kata',
\       'mode:kata:q-key',
\       'mode:kata:to-ascii',
\       'mode:kata:to-zenei',
\   ],
\   'hankata': [
\       'phase:henkan:henkan-key',
\       'phase:okuri:henkan-key',
\       'phase:henkan-select:choose-next',
\       'phase:henkan-select:choose-prev',
\       'phase:henkan-select:next-page',
\       'phase:henkan-select:prev-page',
\       'phase:henkan-select:escape',
\       'mode:hankata:toggle-hankata',
\       'mode:hankata:ctrl-q-key',
\       'mode:hankata:toggle-kata',
\       'mode:hankata:q-key',
\       'mode:hankata:to-ascii',
\       'mode:hankata:to-zenei',
\   ],
\   'ascii': [
\       'mode:ascii:to-hira',
\   ],
\   'zenei': [
\       'mode:zenei:to-hira',
\   ],
\}
" TODO s:map should contain this info.
function! eskk#handle_toggle_hankata(stash) "{{{
    if eskk#get_buftable().get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'hankata' ? 'hira' : 'hankata')
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_toggle_kata(stash) "{{{
    if eskk#get_buftable().get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'kata' ? 'hira' : 'kata')
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_ctrl_q_key(stash) "{{{
    let buftable = eskk#get_buftable()
    let phase    = buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \   || phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        call buftable.do_ctrl_q_key()
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_q_key(stash) "{{{
    let buftable = eskk#get_buftable()
    let phase    = buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \   || phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        call buftable.do_q_key()
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_to_ascii(stash) "{{{
    let buftable = eskk#get_buftable()
    if buftable.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_NORMAL).get_rom_str() == ''
        call eskk#set_mode('ascii')
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_to_zenei(stash) "{{{
    let buftable = eskk#get_buftable()
    if buftable.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_NORMAL).get_rom_str() == ''
        call eskk#set_mode('zenei')
        return 1
    endif
    return 0
endfunction "}}}
let s:map_fn = {
\   'mode:hira:toggle-hankata': 'eskk#handle_toggle_hankata',
\   'mode:hira:ctrl-q-key': 'eskk#handle_ctrl_q_key',
\   'mode:hira:toggle-kata': 'eskk#handle_toggle_kata',
\   'mode:hira:q-key': 'eskk#handle_q_key',
\   'mode:hira:to-ascii': 'eskk#handle_to_ascii',
\   'mode:hira:to-zenei': 'eskk#handle_to_zenei',
\
\   'mode:kata:toggle-hankata': 'eskk#handle_toggle_hankata',
\   'mode:kata:ctrl-q-key': 'eskk#handle_ctrl_q_key',
\   'mode:kata:toggle-kata': 'eskk#handle_toggle_kata',
\   'mode:kata:q-key': 'eskk#handle_q_key',
\   'mode:kata:to-ascii': 'eskk#handle_to_ascii',
\   'mode:kata:to-zenei': 'eskk#handle_to_zenei',
\
\   'mode:hankata:toggle-hankata': 'eskk#handle_toggle_hankata',
\   'mode:hankata:ctrl-q-key': 'eskk#handle_ctrl_q_key',
\   'mode:hankata:toggle-kata': 'eskk#handle_toggle_kata',
\   'mode:hankata:q-key': 'eskk#handle_q_key',
\   'mode:hankata:to-ascii': 'eskk#handle_to_ascii',
\   'mode:hankata:to-zenei': 'eskk#handle_to_zenei',
\
\
\}
" Same structure as `s:eskk.stash`, but this is set by `s:mutable_stash.init()`.
let s:stash_prototype = {}
" Event handler functions/arguments.
let s:event_hook_fn = {}
" `s:eskk.map_all_keys()` and `s:eskk.unmap_all_keys()` toggle this value.
let s:has_mapped = {}
" SKK dicionary.
let s:skk_dict = eskk#dictionary#new(g:eskk_dictionary, g:eskk_large_dictionary, s:eskk_instances[s:instance_id].added_words)
" }}}

" Functions {{{

function! eskk#load() "{{{
    runtime! plugin/eskk.vim
endfunction "}}}



" These mapping functions actually map key using ":lmap".
function! eskk#set_up_key(key, ...) "{{{
    if a:0
        return s:map_key(a:key, s:mapopt_chars2dict(a:1))
    else
        return s:map_key(a:key, s:create_default_mapopt())
    endif
endfunction "}}}
function! s:map_key(key, options) "{{{
    " Assumption: a:key must be '<Bar>' not '|'.

    " Map a:key.
    let named_key = eskk#get_named_map(a:key)
    execute
    \   'lmap'
    \   '<buffer>' . s:mapopt_dict2raw(a:options)
    \   a:key
    \   named_key
endfunction "}}}
function! eskk#set_up_temp_key(lhs, ...) "{{{
    " Assumption: a:lhs must be '<Bar>' not '|'.

    " Save current a:lhs mapping.
    let save_lhs = s:temp_key_map(a:lhs)
    let save_rhs = maparg(a:lhs, 'l')
    if save_rhs != '' && maparg(save_lhs) == ''
        " TODO Check if a:lhs is buffer local.
        call eskk#util#log('Save temp key: ' . maparg(a:lhs, 'l'))
        execute
        \   'lmap'
        \   '<buffer>'
        \   save_lhs
        \   save_rhs
    endif

    if a:0
        execute
        \   'lmap'
        \   '<buffer>'
        \   a:lhs
        \   a:1
    else
        call eskk#set_up_key(a:lhs)
    endif
endfunction "}}}
function! eskk#set_up_temp_key_restore(lhs) "{{{
    let temp_key = s:temp_key_map(a:lhs)
    let saved_rhs = maparg(temp_key, 'l')

    if saved_rhs != ''
        call eskk#util#log('Restore saved temp key: ' . saved_rhs)
        execute 'lunmap <buffer>' temp_key
        execute 'lmap <buffer>' a:lhs saved_rhs
    else
        call eskk#util#logf("warning: called eskk#set_up_temp_key_restore() but no '%s' key is stashed.", a:lhs)
        call eskk#set_up_key(a:lhs)
    endif
endfunction "}}}
function! eskk#has_temp_key(lhs) "{{{
    let temp_key = s:temp_key_map(a:lhs)
    let saved_rhs = maparg(temp_key, 'l')
    return saved_rhs != ''
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
function! eskk#get_named_map(key) "{{{
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

" eskk#map()
function! eskk#map(type, options, lhs, rhs) "{{{
    return s:create_map(eskk#get_current_instance(), a:type, s:mapopt_chars2dict(a:options), a:lhs, a:rhs, 'eskk#map()')
endfunction "}}}
function! s:create_map(self, type, options, lhs, rhs, from) "{{{
    let self = a:self
    let lhs = a:lhs
    let rhs = a:rhs

    if !has_key(s:map, a:type)
        call eskk#util#warnf('%s: unknown type: %s', a:from, a:type)
        return
    endif
    let type_st = s:map[a:type]

    if a:type ==# 'general'
        if lhs == ''
            call eskk#util#warn("lhs must not be empty string.")
            return
        endif
        if has_key(type_st, lhs) && a:options.unique
            call eskk#util#warnf("%s: Already mapped to '%s'.", a:from, lhs)
            return
        endif
        let type_st[lhs] = {
        \   'options': a:options,
        \   'rhs': rhs
        \}
    else
        if a:options.unique && has_key(type_st, 'lhs')
            call eskk#util#warnf('%s: -unique is specified and mapping already exists. skip.', a:type)
            return
        endif
        let type_st.options = a:options
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
function! s:mapopt_chars2raw(options) "{{{
    return s:mapopt_dict2raw(s:mapopt_chars2dict(a:options))
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

" :EskkMap - Ex command for eskk#map()
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
        call s:create_map(eskk#get_current_instance(), type, options, lhs, '', 'EskkMap')
        return
    endif

    call s:create_map(eskk#get_current_instance(), type, options, lhs, args, 'EskkMap')
endfunction "}}}


" Manipulate eskk instances.
function! eskk#get_current_instance() "{{{
    return s:eskk_instances[s:instance_id]
endfunction "}}}
function! eskk#create_new_instance() "{{{
    " TODO: CoW

    " Create instance.
    let inst = s:eskk_new()
    call add(s:eskk_instances, inst)
    let s:instance_id += 1

    " Initialize instance.
    call inst.enable(0)

    " Update s:skk_dict. Assign current instance's `added_words`.
    let s:skk_dict._added_words = inst.added_words

    return inst
endfunction "}}}
function! eskk#destroy_current_instance() "{{{
    if s:instance_id == 0
        throw eskk#internal_error(['eskk'], "No more instances.")
    endif

    " Destroy current instance.
    call remove(s:eskk_instances, s:instance_id)
    let s:instance_id -= 1

    " Update s:skk_dict. Assign current instance's `added_words`.
    let s:skk_dict._added_words = s:eskk_instances[s:instance_id].added_words
endfunction "}}}
function! eskk#get_mutable_stash(namespace) "{{{
    let obj = deepcopy(s:mutable_stash, 1)
    let obj.namespace = join(a:namespace, '-')
    return obj
endfunction "}}}

" s:mutable_stash "{{{
let s:mutable_stash = {}

" NOTE: Constructor is eskk#get_mutable_stash().

" This a:value will be set when new eskk instances are created.
function! s:mutable_stash.init(varname, value) dict "{{{
    call eskk#util#logf("s:mutable_stash - Initialize %s with %s.", a:varname, string(a:value))

    if !has_key(s:stash_prototype, self.namespace)
        let s:stash_prototype[self.namespace] = {}
    endif

    if !has_key(s:stash_prototype[self.namespace], a:varname)
        let s:stash_prototype[self.namespace][a:varname] = a:value
    else
        throw eskk#internal_error(['eskk'])
    endif
endfunction "}}}

function! s:mutable_stash.get(varname) dict "{{{
    call eskk#util#logf("s:mutable_stash - Get %s.", a:varname)

    let inst = eskk#get_current_instance()
    if !has_key(inst.stash, self.namespace)
        let inst.stash[self.namespace] = {}
    endif

    if has_key(inst.stash[self.namespace], a:varname)
        return inst.stash[self.namespace][a:varname]
    else
        " Find prototype for this variable.
        " These prototypes are set by `s:mutable_stash.init()`.
        if !has_key(s:stash_prototype, self.namespace)
            let s:stash_prototype[self.namespace] = {}
        endif

        if has_key(s:stash_prototype[self.namespace], a:varname)
            return s:stash_prototype[self.namespace][a:varname]
        else
            " No more stash.
            throw eskk#internal_error(['eskk'])
        endif
    endif
endfunction "}}}

function! s:mutable_stash.set(varname, value) dict "{{{
    call eskk#util#logf("s:mutable_stash - Set %s '%s'.", a:varname, string(a:value))

    let inst = eskk#get_current_instance()
    if !has_key(inst.stash, self.namespace)
        let inst.stash[self.namespace] = {}
    endif

    let inst.stash[self.namespace][a:varname] = a:value
endfunction "}}}

lockvar s:mutable_stash
" }}}


" Getter for scope-local variables.
function! eskk#get_dictionary() "{{{
    return s:skk_dict
endfunction "}}}


" Dictionary
function! eskk#update_dictionary() "{{{
    call eskk#get_dictionary().update_dictionary()
endfunction "}}}


" Filter
function! eskk#asym_filter(stash, table_name) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let phase = buftable.get_henkan_phase()


    " Handle special mode-local mapping.
    let cur_mode = eskk#get_mode()
    let toggle_hankata = printf('mode:%s:toggle-hankata', cur_mode)
    let ctrl_q_key = printf('mode:%s:ctrl-q-key', cur_mode)
    let toggle_kata = printf('mode:%s:toggle-kata', cur_mode)
    let q_key = printf('mode:%s:q-key', cur_mode)
    let to_ascii = printf('mode:%s:to-ascii', cur_mode)
    let to_zenei = printf('mode:%s:to-zenei', cur_mode)

    for key in [toggle_hankata, ctrl_q_key, toggle_kata, q_key, to_ascii, to_zenei]
        if eskk#handle_special_lhs(char, key, a:stash)
            " Handled.
            call eskk#util#logf("Handled '%s' key.", key)
            return
        endif
    endfor


    " In order not to change current buftable old string.
    call eskk#lock_old_str()
    try
        " Handle special characters.
        " These characters are handled regardless of current phase.
        if char ==# "\<BS>" || char ==# "\<C-h>"
            call buftable.do_backspace(a:stash)
            return
        elseif char ==# "\<CR>"
            call buftable.do_enter(a:stash)
            return
        elseif eskk#is_special_lhs(char, 'sticky')
            call buftable.do_sticky(a:stash)
            return
        elseif eskk#is_big_letter(char)
            call buftable.do_sticky(a:stash)
            call eskk#register_temp_event('filter-redispatch', 'eskk#filter', [tolower(char)])
            return
        else
            " Fall through.
        endif
    finally
        call eskk#unlock_old_str()
    endtry


    " Handle other characters.
    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        return s:filter_rom(a:stash, a:table_name)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        if eskk#is_special_lhs(char, 'phase:henkan:henkan-key')
            return buftable.do_henkan(a:stash)
            call eskk#util#assert(buftable.get_henkan_phase() == g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
        else
            return s:filter_rom(a:stash, a:table_name)
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        if eskk#is_special_lhs(char, 'phase:okuri:henkan-key')
            return buftable.do_henkan(a:stash)
            call eskk#util#assert(buftable.get_henkan_phase() == g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
        else
            return s:filter_rom(a:stash, a:table_name)
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        if eskk#is_special_lhs(char, 'phase:henkan-select:choose-next')
            call buftable.choose_next_candidate(a:stash)
            return
        elseif eskk#is_special_lhs(char, 'phase:henkan-select:choose-prev')
            call buftable.choose_prev_candidate(a:stash)
            return
        else
            call buftable.push_kakutei_str(buftable.get_display_str(0))
            call eskk#register_temp_event('filter-redispatch', 'eskk#filter', [a:stash.char])

            call buftable.set_henkan_phase(g:eskk#buftable#HENKAN_PHASE_NORMAL)
        endif
    else
        let msg = printf("eskk#asym_filter() does not support phase %d.", phase)
        throw eskk#internal_error(['eskk'], msg)
    endif
endfunction "}}}
function! s:generate_map_list(str, tail, ...) "{{{
    let str = a:str
    let result = a:0 != 0 ? a:1 : []
    " NOTE: `str` must come to empty string.
    if str == ''
        return result
    else
        call add(result, str)
        " a:tail is true, Delete tail one character.
        " a:tail is false, Delete first one character.
        return s:generate_map_list(
        \   (a:tail ? strpart(str, 0, strlen(str) - 1) : strpart(str, 1)),
        \   a:tail,
        \   result
        \)
    endif
endfunction "}}}
function! s:get_matched_and_rest(table, rom_str, tail) "{{{
    " For e.g., if table has map "n" to "ん" and "j" to none.
    " rom_str(a:tail is true): "nj" => [["ん"], "j"]
    " rom_str(a:tail is false): "nj" => [[], "nj"]

    let matched = []
    let rest = a:rom_str
    while 1
        let counter = 0
        let has_map_str = -1
        for str in s:generate_map_list(rest, a:tail)
            let counter += 1
            if a:table.has_map(str)
                let has_map_str = str
                break
            endif
        endfor
        if has_map_str ==# -1
            return [matched, rest]
        endif
        call add(matched, has_map_str)
        if a:tail
            " Delete first `has_map_str` bytes.
            let rest = strpart(rest, strlen(has_map_str))
        else
            " Delete last `has_map_str` bytes.
            let rest = strpart(rest, 0, strlen(rest) - strlen(has_map_str))
        endif
    endwhile
endfunction "}}}
function! s:filter_rom(stash, table_name) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()
    let rom_str = buf_str.get_rom_str() . char
    let table = eskk#util#get_table_lazy(a:table_name)
    let match_exactly  = table.has_map(rom_str)
    let candidates     = table.get_candidates(rom_str)

    call eskk#util#logf('char = %s, rom_str = %s', string(char), string(rom_str))
    call eskk#util#logf('candidates = %s', string(candidates))

    if match_exactly
        call eskk#util#assert(!empty(candidates))
    endif

    if match_exactly && len(candidates) == 1
        " Match!
        call eskk#util#logf('%s - match!', rom_str)
        return s:filter_rom_exact_match(a:stash, table)

    elseif !empty(candidates)
        " Has candidates but not match.
        call eskk#util#logf('%s - wait for a next key.', rom_str)
        return s:filter_rom_has_candidates(a:stash)

    else
        " No candidates.
        call eskk#util#logf('%s - no candidates.', rom_str)
        return s:filter_rom_no_match(a:stash, table)
    endif
endfunction "}}}
function! s:filter_rom_exact_match(stash, table) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()
    let rom_str = buf_str.get_rom_str() . char
    let phase = buftable.get_henkan_phase()

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   || phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        " Set filtered string.
        call buf_str.push_matched(rom_str, a:table.get_map_to(rom_str))
        call buf_str.clear_rom_str()


        " Set rest string.
        "
        " NOTE:
        " rest must not have multibyte string.
        " rest is for rom string.
        let rest = a:table.get_rest(rom_str, -1)
        " Assumption: 'a:table.has_map(rest)' returns false here.
        if rest !=# -1
            " XXX:
            "     eskk#get_named_map(char)
            " should
            "     eskk#get_named_map(eskk#util#uneval_key(char))
            for rest_char in split(rest, '\zs')
                call eskk#register_temp_event(
                \   'filter-redispatch',
                \   'eskk#util#eval_key',
                \   [eskk#get_named_map(rest_char)]
                \)
            endfor
        endif


        " Clear filtered string when eskk#filter()'s finalizing.
        function! s:finalize()
            let buftable = eskk#get_buftable()
            if buftable.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
                let buf_str = buftable.get_current_buf_str()
                call buf_str.clear_matched()
            endif
        endfunction

        call eskk#register_temp_event(
        \   'filter-begin',
        \   eskk#util#get_local_func('finalize', s:SID_PREFIX),
        \   []
        \)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        " Enter phase henkan select with henkan.

        " Input: "SesSi"
        " Convert from:
        "   henkan buf str:
        "     filter str: "せ"
        "     rom str   : "s"
        "   okuri buf str:
        "     filter str: "し"
        "     rom str   : "si"
        " to:
        "   henkan buf str:
        "     filter str: "せっ"
        "     rom str   : ""
        "   okuri buf str:
        "     filter str: "し"
        "     rom str   : "si"
        " (http://d.hatena.ne.jp/tyru/20100320/eskk_rom_to_hira)
        let henkan_buf_str        = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
        let okuri_buf_str         = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
        let henkan_select_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT)
        let henkan_rom = henkan_buf_str.get_rom_str()
        let okuri_rom  = okuri_buf_str.get_rom_str()
        if henkan_rom != '' && a:table.has_map(henkan_rom . okuri_rom[0])
            " Push "っ".
            let match_rom = henkan_rom . okuri_rom[0]
            call henkan_buf_str.push_matched(
            \   match_rom,
            \   a:table.get_map_to(match_rom)
            \)
            " Push "s" to rom str.
            let rest = a:table.get_rest(henkan_rom . okuri_rom[0], -1)
            if rest !=# -1
                call okuri_buf_str.set_rom_str(
                \   rest . okuri_rom[1:]
                \)
            endif
        endif

        call eskk#util#assert(char != '')
        call okuri_buf_str.push_rom_str(char)

        if a:table.has_map(okuri_buf_str.get_rom_str())
            call okuri_buf_str.push_matched(
            \   okuri_buf_str.get_rom_str(),
            \   a:table.get_map_to(okuri_buf_str.get_rom_str())
            \)
            let rest = a:table.get_rest(okuri_buf_str.get_rom_str(), -1)
            if rest !=# -1
                " XXX:
                "     eskk#get_named_map(char)
                " should
                "     eskk#get_named_map(eskk#util#uneval_key(char))
                for rest_char in split(rest, '\zs')
                    call eskk#register_temp_event(
                    \   'filter-redispatch',
                    \   'eskk#util#eval_key',
                    \   [eskk#get_named_map(rest_char)]
                    \)
                endfor
            endif
        endif

        call okuri_buf_str.clear_rom_str()

        if g:eskk_auto_henkan_at_okuri_match
            call buftable.do_henkan(a:stash)
        endif
    endif
endfunction "}}}
function! s:filter_rom_has_candidates(stash) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()

    " NOTE: This will be run in all phases.
    call buf_str.push_rom_str(char)
endfunction "}}}
function! s:filter_rom_no_match(stash, table) "{{{
    let char = a:stash.char
    let buftable = eskk#get_buftable()
    let buf_str = buftable.get_current_buf_str()
    let rom_str_without_char = buf_str.get_rom_str()
    let rom_str = rom_str_without_char . char
    let input_style = eskk#util#option_value(g:eskk_rom_input_style, ['skk', 'msime', 'quickmatch'], 0)

    let [matched_map_list, rest] = s:get_matched_and_rest(a:table, rom_str, 1)
    if empty(matched_map_list)
        if input_style ==# 'skk'
            if rest ==# char
                let a:stash.return = char
            else
                let rest = strpart(rest, 0, strlen(rest) - 2) . char
                call buf_str.set_rom_str(rest)
            endif
        else
            let [matched_map_list, head_no_match] = s:get_matched_and_rest(a:table, rom_str, 0)
            if empty(matched_map_list)
                call buf_str.set_rom_str(head_no_match)
            else
                for char in split(head_no_match, '\zs')
                    call buf_str.push_matched(char, char)
                endfor
                for matched in matched_map_list
                    call buf_str.push_matched(matched, a:table.get_map_to(matched))
                endfor
                call buf_str.clear_rom_str()
            endif
        endif
    else
        for matched in matched_map_list
            call buf_str.push_matched(matched, a:table.get_map_to(matched))
        endfor
        call buf_str.set_rom_str(rest)
    endif
endfunction "}}}


" Stubs for current eskk instance. {{{

" Enable/Disable IM
function! eskk#is_enabled() "{{{
    let self = eskk#get_current_instance()
    return call(self.is_enabled, [], self)
endfunction "}}}
function! eskk#enable() "{{{
    let self = eskk#get_current_instance()
    return call(self.enable, [], self)
endfunction "}}}
function! eskk#disable() "{{{
    let self = eskk#get_current_instance()
    return call(self.disable, [], self)
endfunction "}}}
function! eskk#toggle() "{{{
    let self = eskk#get_current_instance()
    return call(self.toggle, [], self)
endfunction "}}}

function! eskk#is_special_lhs(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.is_special_lhs, a:000, self)
endfunction "}}}
function! eskk#get_special_key(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.get_special_key, a:000, self)
endfunction "}}}
function! eskk#handle_special_lhs(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.handle_special_lhs, a:000, self)
endfunction "}}}

" Mappings
function! eskk#map_all_keys(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.map_all_keys, a:000, self)
endfunction "}}}
function! eskk#unmap_all_keys(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.unmap_all_keys, a:000, self)
endfunction "}}}

" Manipulate display string.
function! eskk#remove_display_str(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.remove_display_str, a:000, self)
endfunction "}}}
function! eskk#kakutei_str(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.kakutei_str, a:000, self)
endfunction "}}}

" Big letter keys
function! eskk#is_big_letter(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.is_big_letter, a:000, self)
endfunction "}}}

" Escape key
function! eskk#escape_key(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.escape_key, a:000, self)
endfunction "}}}

" Mode
function! eskk#set_mode(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.set_mode, a:000, self)
endfunction "}}}
function! eskk#get_mode(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.get_mode, a:000, self)
endfunction "}}}
function! eskk#is_supported_mode(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.is_supported_mode, a:000, self)
endfunction "}}}
function! eskk#register_mode(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.register_mode, a:000, self)
endfunction "}}}
function! eskk#validate_mode_structure(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.validate_mode_structure, a:000, self)
endfunction "}}}
function! eskk#get_mode_structure(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.get_mode_structure, a:000, self)
endfunction "}}}

" Statusline
function! eskk#get_stl(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.get_stl, a:000, self)
endfunction "}}}

" Buftable
function! eskk#get_buftable(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.get_buftable, a:000, self)
endfunction "}}}
function! eskk#set_buftable(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.set_buftable, a:000, self)
endfunction "}}}
function! eskk#rewrite(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.rewrite, a:000, self)
endfunction "}}}

" Event
function! eskk#register_event(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.register_event, a:000, self)
endfunction "}}}
function! eskk#register_temp_event(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.register_temp_event, a:000, self)
endfunction "}}}
function! eskk#throw_event(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.throw_event, a:000, self)
endfunction "}}}

" Henkan result
function! eskk#get_henkan_result(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.get_henkan_result, a:000, self)
endfunction "}}}
function! eskk#set_henkan_result(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.set_henkan_result, a:000, self)
endfunction "}}}

" Locking diff old string
function! eskk#lock_old_str(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.lock_old_str, a:000, self)
endfunction "}}}
function! eskk#unlock_old_str(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.unlock_old_str, a:000, self)
endfunction "}}}

" Filter
function! eskk#filter(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.filter, a:000, self)
endfunction "}}}
function! eskk#call_via_filter(...) "{{{
    let self = eskk#get_current_instance()
    return call(self.call_via_filter, a:000, self)
endfunction "}}}

" }}}

" }}}

" Exceptions {{{
function! s:build_error(from, msg) "{{{
    return join(a:from, ': ') . ' - ' . join(a:msg, ': ')
endfunction "}}}
function! eskk#get_exception_message(error_str) "{{{
    " Get only `a:msg` of s:build_error().
    let s = a:error_str
    let s = substitute(s, '^.\{-} - ', '', '')
    return s
endfunction "}}}

function! eskk#internal_error(from, ...) "{{{
    return s:build_error(a:from, ['internal error'] + a:000)
endfunction "}}}
function! eskk#dictionary_look_up_error(from, ...) "{{{
    return s:build_error(a:from, ['dictionary look up error'] + a:000)
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
    function! eskk#do_lmap_non_egg_like_newline(do_map) "{{{
        if a:do_map
            if !eskk#has_temp_key('<CR>')
                call eskk#util#log("Map *non* egg like newline...: <CR> => <Plug>(eskk:filter:<CR>)<Plug>(eskk:filter:<CR>)")
                call eskk#set_up_temp_key('<CR>', '<Plug>(eskk:filter:<CR>)<Plug>(eskk:filter:<CR>)')
            endif
        else
            call eskk#util#log("Restore *non* egg like newline...: <CR>")
            call eskk#register_temp_event('filter-begin', 'eskk#set_up_temp_key_restore', ['<CR>'])
        endif
    endfunction "}}}
    function! s:register_egg_like_newline_event()
        let self = eskk#get_current_instance()

        " Default behavior is `egg like newline`.
        " Turns it to `Non egg like newline` during henkan phase.
        call self.register_event(['enter-phase-henkan', 'enter-phase-okuri', 'enter-phase-henkan-select'], 'eskk#do_lmap_non_egg_like_newline', [1])
        call self.register_event('enter-phase-normal', 'eskk#do_lmap_non_egg_like_newline', [0])
    endfunction
    call s:register_egg_like_newline_event()
endif
" }}}
" InsertLeave {{{
function! s:autocmd_insert_leave() "{{{
    let self = eskk#get_current_instance()
    call self.buftable.reset()

    if !g:eskk_keep_state && self.is_enabled()
        let disable = self.disable()
        noautocmd execute 'normal! i' . disable
    endif
endfunction "}}}
autocmd InsertLeave * call s:autocmd_insert_leave()
" }}}
" Default mappings - :EskkMap {{{
function! s:do_default_mappings() "{{{
    silent EskkMap -type=sticky -unique ;
    silent EskkMap -type=henkan -unique <Space>
    silent EskkMap -type=escape -unique <Esc>

    silent EskkMap -type=phase:henkan:henkan-key -unique <Space>

    silent EskkMap -type=phase:okuri:henkan-key -unique <Space>

    silent EskkMap -type=phase:henkan-select:choose-next -unique <Space>
    silent EskkMap -type=phase:henkan-select:choose-prev -unique x

    silent EskkMap -type=phase:henkan-select:next-page -unique <Space>
    silent EskkMap -type=phase:henkan-select:prev-page -unique x

    silent EskkMap -type=phase:henkan-select:escape -unique <C-g>

    silent EskkMap -type=mode:hira:toggle-hankata -unique <C-q>
    silent EskkMap -type=mode:hira:ctrl-q-key -unique <C-q>
    silent EskkMap -type=mode:hira:toggle-kata -unique q
    silent EskkMap -type=mode:hira:q-key -unique q
    silent EskkMap -type=mode:hira:to-ascii -unique l
    silent EskkMap -type=mode:hira:to-zenei -unique L

    silent EskkMap -type=mode:kata:toggle-hankata -unique <C-q>
    silent EskkMap -type=mode:kata:ctrl-q-key -unique <C-q>
    silent EskkMap -type=mode:kata:toggle-kata -unique q
    silent EskkMap -type=mode:kata:q-key -unique q
    silent EskkMap -type=mode:kata:to-ascii -unique l
    silent EskkMap -type=mode:kata:to-zenei -unique L

    silent EskkMap -type=mode:hankata:toggle-hankata -unique <C-q>
    silent EskkMap -type=mode:hankata:ctrl-q-key -unique <C-q>
    silent EskkMap -type=mode:hankata:toggle-kata -unique q
    silent EskkMap -type=mode:hankata:q-key -unique q
    silent EskkMap -type=mode:hankata:to-ascii -unique l
    silent EskkMap -type=mode:hankata:to-zenei -unique L

    silent EskkMap -type=mode:ascii:to-hira -unique <C-j>

    silent EskkMap -type=mode:zenei:to-hira -unique <C-j>
endfunction "}}}
call s:do_default_mappings()
" }}}
" Map temporary key to keys to use in that mode {{{
function! eskk#map_mode_local_keys() "{{{
    let mode = eskk#get_mode()

    if has_key(s:mode_local_keys, mode)
        for key in s:mode_local_keys[mode]
            let real_key = eskk#get_special_key(key)
            call eskk#set_up_temp_key(real_key)
            call eskk#register_temp_event('leave-mode-' . mode, 'eskk#set_up_temp_key_restore', [real_key])
        endfor
    endif
endfunction "}}}
call eskk#register_event(['enter-mode-hira', 'enter-mode-kata', 'enter-mode-ascii', 'enter-mode-zenei'], 'eskk#map_mode_local_keys', [])
" }}}
" Save dictionary if modified {{{
if g:eskk_auto_save_dictionary_at_exit
    autocmd VimLeavePre * call eskk#update_dictionary()
endif
" }}}
" Register builtin-modes. {{{

" 'ascii' mode {{{
call eskk#register_mode('ascii')
let dict = eskk#get_mode_structure('ascii')

function! dict.filter(stash)
    if eskk#is_special_lhs(a:stash.char, 'mode:ascii:to-hira')
        call eskk#set_mode('hira')
    else
        if has_key(g:eskk_mode_use_tables, 'ascii')
            if !has_key(self.sandbox, 'table')
                let self.sandbox.table = eskk#table#new(g:eskk_mode_use_tables.ascii)
            endif
            let a:stash.return = self.sandbox.table.get_map_to(a:stash.char, a:stash.char)
        else
            let a:stash.return = a:stash.char
        endif
    endif
endfunction

call eskk#validate_mode_structure('ascii')
" }}}

" 'zenei' mode {{{
call eskk#register_mode('zenei')
let dict = eskk#get_mode_structure('zenei')

function! dict.filter(stash)
    if eskk#is_special_lhs(a:stash.char, 'mode:zenei:to-hira')
        call eskk#set_mode('hira')
    else
        if !has_key(self.sandbox, 'table')
            let self.sandbox.table = eskk#table#new(g:eskk_mode_use_tables.zenei)
        endif
        let a:stash.return = self.sandbox.table.get_map_to(a:stash.char, a:stash.char)
    endif
endfunction

call eskk#validate_mode_structure('zenei')
" }}}

" 'hira' mode {{{
call eskk#register_mode('hira')
let dict = eskk#get_mode_structure('hira')

function! dict.filter(...)
    return call('eskk#asym_filter', a:000 + [g:eskk_mode_use_tables.hira])
endfunction

call eskk#validate_mode_structure('hira')
" }}}

" 'kata' mode {{{
call eskk#register_mode('kata')
let dict = eskk#get_mode_structure('kata')

function! dict.filter(...)
    return call('eskk#asym_filter', a:000 + [g:eskk_mode_use_tables.kata])
endfunction

call eskk#validate_mode_structure('kata')
" }}}

" 'hankata' mode {{{
call eskk#register_mode('hankata')
let dict = eskk#get_mode_structure('hankata')

function! dict.filter(...)
    return call('eskk#asym_filter', a:000 + [g:eskk_mode_use_tables.hankata])
endfunction

call eskk#validate_mode_structure('hankata')
" }}}

unlet dict

" }}}
" Map keys when BufEnter {{{
function! s:map_all_keys_if_enabled() "{{{
    if eskk#is_enabled()
        call eskk#map_all_keys()
    endif
endfunction "}}}
autocmd InsertEnter * call s:map_all_keys_if_enabled()
" }}}

augroup END

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

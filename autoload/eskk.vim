" vim:foldmethod=marker:fen:sw=4:sts=4
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

" s:eskk {{{
" mode:
"   Current mode.
" _buftable:
"   Buffer strings for inserted, filtered and so on.
" is_locked_old_str:
"   Lock current diff old string?
" temp_event_hook_fn:
"   Temporary event handler functions/arguments.
" enabled:
"   True if s:eskk.enable() is called.
" enabled_mode:
"   Vim's mode() return value when calling eskk#enable().
" stash:
"   Stash for instance-local variables. See `s:mutable_stash`.
" prev_henkan_result:
"   Previous henkan result.
"   See `s:henkan_result` in `autoload/eskk/dictionary.vim`.
" has_started_completion:
"   completion has been started from eskk.
let s:eskk = {
\   'mode': '',
\   '_buftable': {},
\   'is_locked_old_str': 0,
\   'temp_event_hook_fn': {},
\   'enabled': 0,
\   'stash': {},
\   'prev_henkan_result': {},
\   'has_started_completion': 0,
\}

function! s:eskk_new() "{{{
    return deepcopy(s:eskk, 1)
endfunction "}}}

lockvar s:eskk
" }}}

" Variables {{{

" NOTE: Following variables are non-local between instances.

" Supported modes and their structures.
let s:available_modes = {}
" Database for misc. keys.
let s:map = {
\   'general': {},
\   'sticky': {},
\   'backspace-key': {},
\   'escape-key': {},
\   'enter-key': {},
\   'undo-key': {},
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
\   'mode:hira:to-abbrev': {},
\   'mode:kata:toggle-hankata': {},
\   'mode:kata:ctrl-q-key': {},
\   'mode:kata:toggle-kata': {},
\   'mode:kata:q-key': {},
\   'mode:kata:to-ascii': {},
\   'mode:kata:to-zenei': {},
\   'mode:kata:to-abbrev': {},
\   'mode:hankata:toggle-hankata': {},
\   'mode:hankata:ctrl-q-key': {},
\   'mode:hankata:toggle-kata': {},
\   'mode:hankata:q-key': {},
\   'mode:hankata:to-ascii': {},
\   'mode:hankata:to-zenei': {},
\   'mode:hankata:to-abbrev': {},
\   'mode:ascii:to-hira': {},
\   'mode:zenei:to-hira': {},
\   'mode:abbrev:henkan-key': {},
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
\       'mode:hira:to-abbrev',
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
\       'mode:kata:to-abbrev',
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
\       'mode:hankata:to-abbrev',
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
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'hankata' ? 'hira' : 'hankata')
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_toggle_kata(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'kata' ? 'hira' : 'kata')
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_ctrl_q_key(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \   || a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        call a:stash.buftable.do_ctrl_q_key()
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_q_key(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \   || a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        call a:stash.buftable.do_q_key()
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_to_ascii(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && a:stash.buf_str.get_rom_str() == ''
        call eskk#set_mode('ascii')
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_to_zenei(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && a:stash.buf_str.get_rom_str() == ''
        call eskk#set_mode('zenei')
        return 1
    endif
    return 0
endfunction "}}}
function! eskk#handle_to_abbrev(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && a:stash.buf_str.get_rom_str() == ''
        call eskk#set_mode('abbrev')
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
\   'mode:hira:to-abbrev': 'eskk#handle_to_abbrev',
\
\   'mode:kata:toggle-hankata': 'eskk#handle_toggle_hankata',
\   'mode:kata:ctrl-q-key': 'eskk#handle_ctrl_q_key',
\   'mode:kata:toggle-kata': 'eskk#handle_toggle_kata',
\   'mode:kata:q-key': 'eskk#handle_q_key',
\   'mode:kata:to-ascii': 'eskk#handle_to_ascii',
\   'mode:kata:to-zenei': 'eskk#handle_to_zenei',
\   'mode:kata:to-abbrev': 'eskk#handle_to_abbrev',
\
\   'mode:hankata:toggle-hankata': 'eskk#handle_toggle_hankata',
\   'mode:hankata:ctrl-q-key': 'eskk#handle_ctrl_q_key',
\   'mode:hankata:toggle-kata': 'eskk#handle_toggle_kata',
\   'mode:hankata:q-key': 'eskk#handle_q_key',
\   'mode:hankata:to-ascii': 'eskk#handle_to_ascii',
\   'mode:hankata:to-zenei': 'eskk#handle_to_zenei',
\   'mode:hankata:to-abbrev': 'eskk#handle_to_abbrev',
\
\
\}
" Same structure as `s:eskk.stash`, but this is set by `s:mutable_stash.init()`.
let s:stash_prototype = {}
" Event handler functions/arguments.
let s:event_hook_fn = {}
" `eskk#map_all_keys()` and `eskk#unmap_all_keys()` toggle this value.
let s:has_mapped = {}
" SKK dicionary.
let s:skk_dict = {}
" For eskk#register_map(), eskk#unregister_map().
let s:key_handler = {}
" Global values of &iminsert, &imsearch.
let s:saved_im_options = []
" Global values of &backspace.
let s:saved_backspace = -1
" Flag for `s:initialize()`.
let s:is_initialized = 0
" Last command's string. See eskk#jump_one_char().
let s:last_jump_cmd = -1
let s:last_jump_char = -1
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
    execute
    \   'lmap'
    \   '<buffer>' . s:mapopt_dict2raw(a:options)
    \   a:key
    \   eskk#get_named_map(a:key)
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
    " FIXME: Rename this to eskk#get_filter_map()
    "
    " NOTE:
    " a:key is escaped. So when a:key is '<C-a>', return value is
    "   `<Plug>(eskk:filter:<C-a>)`
    " not
    "   `<Plug>(eskk:filter:^A)` (^A is control character)

    let lhs = printf('<Plug>(eskk:filter:%s)', a:key)
    if maparg(lhs, 'l') != ''
        return lhs
    endif

    execute
    \   eskk#get_map_command()
    \   '<expr>'
    \   lhs
    \   printf('eskk#filter(%s)', string(a:key))

    return lhs
endfunction "}}}
function! eskk#get_nore_map(key, ...) "{{{
    " NOTE:
    " a:key is escaped. So when a:key is '<C-a>', return value is
    "   `<Plug>(eskk:filter:<C-a>)`
    " not
    "   `<Plug>(eskk:filter:^A)` (^A is control character)

    let [rhs, key] = [a:key, a:key]
    let key = eskk#util#str2map(key)

    let lhs = printf('<Plug>(eskk:noremap:%s)', key)
    if maparg(lhs, 'l') != ''
        return lhs
    endif

    execute
    \   eskk#get_map_command(0)
    \   (a:0 ? s:mapopt_chars2raw(a:1) : '')
    \   lhs
    \   rhs

    return lhs
endfunction "}}}
function! eskk#get_map_command(...) "{{{
    " XXX: :lmap can't remap to :lmap. It's Vim's bug.
    "   http://groups.google.com/group/vim_dev/browse_thread/thread/17a1273eb82d682d/
    " So I use :map! mappings for 'fallback' of :lmap.

    let remap = a:0 ? a:1 : 1
    return remap ? 'map!' : 'noremap!'
endfunction "}}}
function! eskk#get_map_modes() "{{{
    " XXX: :lmap can't remap to :lmap. It's Vim's bug.
    "   http://groups.google.com/group/vim_dev/browse_thread/thread/17a1273eb82d682d/
    " So I use :map! mappings for 'fallback' of :lmap.

    return 'ic'
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
        if key ==# 'remap' || key ==# 'map-if'
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
    \   'map-if': '1',
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
function! s:parse_string_from_q_args(args) "{{{
    let arg = s:skip_white(a:args)
    if arg =~# '^[''"]'    " If arg is string-ish, just eval(it).
        let pat = (arg =~# "^'" ? '^\(''\).\{-}[^''\\]\1' : '^\("\).\{-}[^\\]\1')
        let m = matchstr(arg, pat.'\C')
        let rest = strpart(arg, strlen(m))
        return [eval(m), rest]
    else
        return s:parse_one_arg_from_q_args(a:args)
    endif
endfunction "}}}
function! s:parse_options_get_optargs(args) "{{{
    let OPT_CHARS = '[A-Za-z0-9\-]'
    let a = s:skip_white(a:args)

    if a[0] !=# '-'
        return ['--', '', a]
    endif
    if a ==# '--'
        let rest = s:parse_one_arg_from_q_args(a)[1]
        return ['--', '', rest]
    endif
    let a = a[1:]
    if a !~# '^'.OPT_CHARS.'\+'
        throw eskk#parse_error(['eskk'], ":EskkMap argument's key must be word.")
    endif

    if a =~# '^'.OPT_CHARS.'\+='    " key has a value.
        let [m, optname; _] = matchlist(a, '^\('.OPT_CHARS.'\+\)='.'\C')
        let rest = strpart(a, strlen(m))
        let [value, rest] = s:parse_string_from_q_args(rest)
        return [optname, value, rest]
    else
        let m = matchstr(a, '^'.OPT_CHARS.'\+'.'\C')
        let rest = strpart(a, strlen(m))
        return [m, 1, rest]
    endif
endfunction "}}}
function! s:parse_options(args) "{{{
    let args = a:args
    let type = 'general'
    let opt = s:create_default_mapopt()
    let opt.noremap = 0

    while args != ''
        let [optname, value, args] = s:parse_options_get_optargs(args)
        if optname ==# '--'
            break
        endif
        if optname ==# 'type'
            let type = value
        elseif has_key(opt, optname)
            let opt[optname] = value
        else
            throw eskk#parse_error(['eskk'], printf("unknown option '%s'.", optname))
        endif
    endwhile

    let opt.remap = !remove(opt, 'noremap')
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
function! s:get_inst_namespace() "{{{
    return g:eskk_keep_state_beyond_buffer ? s: : b:
endfunction "}}}
function! s:exists_instance() "{{{
    let varname = (g:eskk_keep_state_beyond_buffer ? 's' : 'b') . ':eskk_instances'
    return exists(varname)
endfunction "}}}
function! eskk#get_current_instance() "{{{
    let ns = s:get_inst_namespace()
    if !s:exists_instance()
        let ns.eskk_instances = [s:eskk_new()]
        " Index number for current instance in s:eskk_instances.
        let ns.eskk_instance_id = 0
    endif
    return ns.eskk_instances[ns.eskk_instance_id]
endfunction "}}}
function! eskk#create_new_instance() "{{{
    " TODO: CoW

    " Create instance.
    let inst = s:eskk_new()
    let ns = s:get_inst_namespace()
    call add(ns.eskk_instances, inst)
    let ns.eskk_instance_id += 1

    call eskk#util#logf('Create instance: %d => %d', ns.eskk_instance_id - 1, ns.eskk_instance_id)

    " Initialize instance.
    call eskk#enable(0)

    return inst
endfunction "}}}
function! eskk#destroy_current_instance() "{{{
    let ns = s:get_inst_namespace()

    if ns.eskk_instance_id == 0
        throw eskk#internal_error(['eskk'], "No more instances.")
    endif

    " Destroy current instance.
    call remove(ns.eskk_instances, ns.eskk_instance_id)
    let ns.eskk_instance_id -= 1

    call eskk#util#logf('Destroy instance: %d => %d', ns.eskk_instance_id + 1, ns.eskk_instance_id)
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
    if empty(s:skk_dict)
        let s:skk_dict = eskk#dictionary#new(g:eskk_dictionary, g:eskk_large_dictionary)
    endif
    return s:skk_dict
endfunction "}}}


" Dictionary
function! eskk#update_dictionary() "{{{
    call eskk#get_dictionary().update_dictionary()
endfunction "}}}
function! eskk#forget_registered_words() "{{{
    call eskk#get_dictionary().forget_registered_words()
endfunction "}}}


" Filter
" s:asym_filter {{{
let s:asym_filter = {'table': {}}

function! eskk#create_asym_filter(table_name) "{{{
    let obj = deepcopy(s:asym_filter)
    let obj.table = eskk#table#new(a:table_name)
    return obj
endfunction "}}}

function! s:asym_filter.filter(stash) dict "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let phase = a:stash.phase


    " Handle special mode-local mapping.
    let cur_mode = eskk#get_mode()
    let toggle_hankata = printf('mode:%s:toggle-hankata', cur_mode)
    let ctrl_q_key = printf('mode:%s:ctrl-q-key', cur_mode)
    let toggle_kata = printf('mode:%s:toggle-kata', cur_mode)
    let q_key = printf('mode:%s:q-key', cur_mode)
    let to_ascii = printf('mode:%s:to-ascii', cur_mode)
    let to_zenei = printf('mode:%s:to-zenei', cur_mode)
    let to_abbrev = printf('mode:%s:to-abbrev', cur_mode)

    for key in [toggle_hankata, ctrl_q_key, toggle_kata, q_key, to_ascii, to_zenei, to_abbrev]
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
        if eskk#is_special_lhs(char, 'backspace-key')
            call buftable.do_backspace(a:stash)
            return
        elseif eskk#is_special_lhs(char, 'enter-key')
            call buftable.do_enter(a:stash)
            return
        elseif eskk#is_special_lhs(char, 'sticky')
            call buftable.do_sticky(a:stash)
            return
        elseif eskk#is_big_letter(char)
            call buftable.do_sticky(a:stash)
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [eskk#util#key2char(eskk#get_named_map(tolower(char)))]
            \)
            return
        else
            " Fall through.
        endif
    finally
        call eskk#unlock_old_str()
    endtry


    " Handle other characters.
    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        return s:filter_rom(a:stash, self.table)
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        if eskk#is_special_lhs(char, 'phase:henkan:henkan-key')
            call buftable.do_henkan(a:stash)
        else
            return s:filter_rom(a:stash, self.table)
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        if eskk#is_special_lhs(char, 'phase:okuri:henkan-key')
            call buftable.do_henkan(a:stash)
        else
            return s:filter_rom(a:stash, self.table)
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT
        if eskk#is_special_lhs(char, 'phase:henkan-select:choose-next')
            call buftable.choose_next_candidate(a:stash)
            return
        elseif eskk#is_special_lhs(char, 'phase:henkan-select:choose-prev')
            call buftable.choose_prev_candidate(a:stash)
            return
        else
            call buftable.do_enter(a:stash)
            call eskk#register_temp_event(
            \   'filter-redispatch-post',
            \   'eskk#util#identity',
            \   [eskk#util#key2char(eskk#get_named_map(a:stash.char))]
            \)
        endif
    else
        let msg = printf("s:asym_filter.filter() does not support phase %d.", phase)
        throw eskk#internal_error(['eskk'], msg)
    endif
endfunction "}}}

function! s:filter_rom(stash, table) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let buf_str = a:stash.buf_str
    let rom_str = buf_str.get_rom_str() . char
    let match_exactly  = a:table.has_map(rom_str)
    let candidates     = a:table.get_candidates(rom_str, 2, [])

    if g:eskk_debug
        call eskk#util#logf('char = %s, rom_str = %s', string(char), string(rom_str))
        call eskk#util#logf('candidates = %s', string(candidates))
    endif

    if match_exactly
        call eskk#util#assert(!empty(candidates))
    endif

    if match_exactly && len(candidates) == 1
        " Match!
        call eskk#util#logf('%s - match!', rom_str)
        return s:filter_rom_exact_match(a:stash, a:table)

    elseif !empty(candidates)
        " Has candidates but not match.
        call eskk#util#logf('%s - wait for a next key.', rom_str)
        return s:filter_rom_has_candidates(a:stash)

    else
        " No candidates.
        call eskk#util#logf('%s - no candidates.', rom_str)
        return s:filter_rom_no_match(a:stash, a:table)
    endif
endfunction "}}}
function! s:filter_rom_exact_match(stash, table) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let buf_str = a:stash.buf_str
    let rom_str = buf_str.get_rom_str() . char
    let phase = a:stash.phase

    if phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   || phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
        " Set filtered string.
        call buf_str.push_matched(rom_str, a:table.get_map(rom_str))
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
                \   'filter-redispatch-post',
                \   'eskk#util#key2char',
                \   [eskk#get_named_map(rest_char)]
                \)
            endfor
        endif


        call eskk#register_temp_event(
        \   'filter-begin',
        \   eskk#util#get_local_func('clear_filtered_string', s:SID_PREFIX),
        \   []
        \)

        if g:eskk_convert_at_exact_match
        \   && phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
            let st = eskk#get_current_mode_structure()
            let henkan_buf_str = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
            if has_key(st.sandbox, 'real_matched_pairs')
                " Restore previous hiragana & push current to the tail.
                let p = henkan_buf_str.pop_matched()
                call henkan_buf_str.set_multiple_matched(st.sandbox.real_matched_pairs + [p])
            endif
            let st.sandbox.real_matched_pairs = henkan_buf_str.get_matched()

            call buftable.do_henkan(a:stash, 1)
        endif
    elseif phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        " Enter phase henkan select with henkan.

        " XXX Write test and refactoring.
        "
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
            \   a:table.get_map(match_rom)
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

        let has_rest = 0
        if a:table.has_map(okuri_buf_str.get_rom_str())
            call okuri_buf_str.push_matched(
            \   okuri_buf_str.get_rom_str(),
            \   a:table.get_map(okuri_buf_str.get_rom_str())
            \)
            let rest = a:table.get_rest(okuri_buf_str.get_rom_str(), -1)
            if rest !=# -1
                " XXX:
                "     eskk#get_named_map(char)
                " should
                "     eskk#get_named_map(eskk#util#uneval_key(char))
                for rest_char in split(rest, '\zs')
                    call eskk#register_temp_event(
                    \   'filter-redispatch-post',
                    \   'eskk#util#key2char',
                    \   [eskk#get_named_map(rest_char)]
                    \)
                endfor
                let has_rest = 1
            endif
        endif

        call okuri_buf_str.clear_rom_str()

        let matched = okuri_buf_str.get_matched()
        call eskk#util#assert(!empty(matched))
        " TODO `len(matched) == 1`: Do henkan at only the first time.

        if !has_rest && g:eskk_auto_henkan_at_okuri_match
            call buftable.do_henkan(a:stash)
        endif
    endif
endfunction "}}}
function! s:filter_rom_has_candidates(stash) "{{{
    " NOTE: This will be run in all phases.
    call a:stash.buf_str.push_rom_str(a:stash.char)
endfunction "}}}
function! s:filter_rom_no_match(stash, table) "{{{
    let char = a:stash.char
    let buftable = a:stash.buftable
    let buf_str = a:stash.buf_str
    let rom_str_without_char = buf_str.get_rom_str()
    let rom_str = rom_str_without_char . char
    let input_style = eskk#util#option_value(g:eskk_rom_input_style, ['skk', 'msime', 'quickmatch'], 0)

    let [matched_map_list, rest] = s:get_matched_and_rest(a:table, rom_str, 1)
    call eskk#util#logstrf('matched_map_list = %s, rest = %s', matched_map_list, rest)
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
            call eskk#util#logstrf('matched_map_list = %s, head_no_match = %s', matched_map_list, head_no_match)
            if empty(matched_map_list)
                call buf_str.set_rom_str(head_no_match)
            else
                for char in split(head_no_match, '\zs')
                    call buf_str.push_matched(char, char)
                endfor
                for matched in matched_map_list
                    if a:table.has_rest(matched)
                        call eskk#register_temp_event(
                        \   'filter-redispatch-post',
                        \   'eskk#util#identity',
                        \   [eskk#util#key2char(eskk#get_named_map(a:table.get_rest(matched)))]
                        \)
                    endif
                    call buf_str.push_matched(matched, a:table.get_map(matched))
                endfor
                call buf_str.clear_rom_str()
            endif
        endif
    else
        for matched in matched_map_list
            call buf_str.push_matched(matched, a:table.get_map(matched))
        endfor
        call buf_str.set_rom_str(rest)
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
        let list = s:generate_map_list(rest, a:tail)
        for str in list
            let counter += 1
            if a:table.has_map(str)
                call eskk#util#logstrf('s:generate_map_list(%s, %d) = %s', rest, a:tail, list)
                call eskk#util#logstrf('found! - %s has map', str)
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
" Clear filtered string when eskk#filter()'s finalizing.
function! s:clear_filtered_string() "{{{
    let buftable = eskk#get_buftable()
    if buftable.get_henkan_phase() ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        let buf_str = buftable.get_current_buf_str()
        call buf_str.clear_matched()
    endif
endfunction "}}}

" }}}



" Enable/Disable IM
function! eskk#is_enabled() "{{{
    return eskk#get_current_instance().enabled
endfunction "}}}
function! eskk#enable(...) "{{{
    let self = eskk#get_current_instance()
    let do_map = a:0 != 0 ? a:1 : 1

    if eskk#is_enabled()
        return ''
    endif
    call eskk#util#log('')
    call eskk#util#log('enabling eskk...')

    if mode() ==# 'c'
        let &l:iminsert = 1
    endif

    if !s:is_initialized
        call s:initialize()
        let s:is_initialized = 1
    endif

    call eskk#throw_event('enable-im')

    " Clear current variable states.
    let self.mode = ''
    call eskk#get_buftable().reset()

    " Set up Mappings.
    if do_map
        call eskk#map_all_keys()
    endif

    call eskk#set_mode(g:eskk_initial_mode)

    " If skk.vim exists and enabled, disable it.
    let disable_skk_vim = ''
    if exists('g:skk_version') && exists('b:skk_on') && b:skk_on
        let disable_skk_vim = substitute(SkkDisable(), "\<C-^>", '', '')
    endif

    if g:eskk_enable_completion
        let self.omnifunc_save = &l:omnifunc
        let &l:omnifunc = 'eskk#complete#eskkcomplete'
    endif

    let self.enabled = 1
    let self.enabled_mode = mode()

    if self.enabled_mode =~# '^[ic]$'
        return disable_skk_vim . "\<C-^>"
    else
        return eskk#emulate_toggle_im()
    endif
endfunction "}}}
function! eskk#disable() "{{{
    let self = eskk#get_current_instance()
    let do_unmap = a:0 != 0 ? a:1 : 0

    if !eskk#is_enabled()
        return ''
    endif
    call eskk#util#log('')
    call eskk#util#log('disabling eskk...')

    if mode() ==# 'c'
        return "\<C-^>"
    endif

    call eskk#throw_event('disable-im')

    if do_unmap
        call eskk#unmap_all_keys()
    endif

    if g:eskk_enable_completion && has_key(self, 'omnifunc_save')
        let &l:omnifunc = self.omnifunc_save
    endif

    let self.enabled = 0

    let kakutei_str = eskk#kakutei_str()

    if mode() =~# '^[ic]$'
        return kakutei_str . "\<C-^>"
    else
        return eskk#emulate_toggle_im()
    endif
endfunction "}}}
function! eskk#toggle() "{{{
    return eskk#{eskk#is_enabled() ? 'disable' : 'enable'}()
endfunction "}}}
function! eskk#emulate_toggle_im() "{{{
    let save_lang = v:lang
    lang messages C
    try
        redir => output
        silent lmap
        redir END
    finally
        execute 'lang messages' save_lang
    endtry
    let defined_langmap = (output !~# '^\n*No mapping found\n*$')

    " :help i_CTRL-^
    if defined_langmap
        if &l:iminsert ==# 1
            let &l:iminsert = 0
        else
            let &l:iminsert = 1
        endif
    else
        if &l:iminsert ==# 2
            let &l:iminsert = 0
        else
            let &l:iminsert = 2
        endif
    endif

    " :help c_CTRL-^
    if &l:imsearch ==# -1
        let &l:imsearch = &l:iminsert
    elseif defined_langmap
        if &l:imsearch ==# 1
            let &l:imsearch = 0
        else
            let &l:imsearch = 1
        endif
    else
        if &l:imsearch ==# 2
            let &l:imsearch = 0
        else
            let &l:imsearch = 2
        endif
    endif
    return ''
endfunction "}}}

function! eskk#is_special_lhs(char, type) "{{{
    " NOTE: This function must not show error when `s:map[a:type]` does not exist.
    return has_key(s:map, a:type)
    \   && eskk#util#key2char(s:map[a:type].lhs) ==# a:char
endfunction "}}}
function! eskk#get_special_key(type) "{{{
    if has_key(s:map, a:type)
        return s:map[a:type].lhs
    else
        throw eskk#internal_error(['eskk'], "Unknown map type: " . a:type)
    endif
endfunction "}}}
function! eskk#get_special_map(type) "{{{
    if has_key(s:map, a:type)
        let map = printf('<Plug>(eskk:internal:_noremap_%s)', a:type)
        if maparg(map) == ''
            " Not to remap.
            execute
            \   eskk#get_map_command(0)
            \   map
            \   s:map[a:type].lhs
        endif
        return map
    else
        throw eskk#internal_error(['eskk'], "Unknown map type: " . a:type)
    endif
endfunction "}}}
function! eskk#handle_special_lhs(char, type, stash) "{{{
    return
    \   eskk#is_special_lhs(a:char, a:type)
    \   && has_key(s:map_fn, a:type)
    \   && call(s:map_fn[a:type], [a:stash])
endfunction "}}}

" Mappings
function! eskk#map_all_keys(...) "{{{
    let self = eskk#get_current_instance()
    if has_key(s:has_mapped, bufnr('%'))
        return
    endif


    lmapclear <buffer>

    " Map mapped keys.
    for key in g:eskk_mapped_keys
        call call('eskk#set_up_key', [key] + a:000)
    endfor

    " Map `:EskkMap -general` keys.
    for [key, opt] in items(s:map.general)
        if !eval(opt.options['map-if'])
            continue
        endif
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
function! eskk#unmap_all_keys() "{{{
    let self = eskk#get_current_instance()
    if !has_key(s:has_mapped, bufnr('%'))
        return
    endif

    for key in g:eskk_mapped_keys
        call eskk#unmap_key(key)
    endfor

    unlet s:has_mapped[bufnr('%')]
endfunction "}}}

" Manipulate display string.
function! eskk#remove_display_str() "{{{
    let current_str = eskk#get_buftable().get_display_str()

    " NOTE: This function return value is not remapped.
    let bs = eskk#get_special_key('backspace-key')
    call eskk#util#assert(bs != '')

    return repeat(eskk#util#key2char(bs), eskk#util#mb_strlen(current_str))
endfunction "}}}
function! eskk#kakutei_str() "{{{
    return eskk#remove_display_str() . eskk#get_buftable().get_display_str(0)
endfunction "}}}

" Big letter keys
function! eskk#is_big_letter(char) "{{{
    return a:char =~# '^[A-Z]$'
endfunction "}}}

" Escape key
function! eskk#escape_key() "{{{
    let kakutei_str = eskk#kakutei_str()

    " NOTE: This function return value is not remapped.
    let esc = eskk#get_special_key('escape-key')
    call eskk#util#assert(esc != '')

    return kakutei_str . eskk#util#key2char(esc)
endfunction "}}}

" Mode
function! eskk#set_mode(next_mode) "{{{
    let self = eskk#get_current_instance()
    call eskk#util#logf("mode change: %s => %s", self.mode, a:next_mode)
    if !eskk#is_supported_mode(a:next_mode)
        call eskk#util#warnf("mode '%s' is not supported.", a:next_mode)
        call eskk#util#warnf('s:available_modes = %s', string(s:available_modes))
        return
    endif

    call eskk#throw_event('leave-mode-' . self.mode)
    call eskk#throw_event('leave-mode')

    " Change mode.
    let prev_mode = self.mode
    let self.mode = a:next_mode

    call eskk#throw_event('enter-mode-' . self.mode)
    call eskk#throw_event('enter-mode')

    " For &statusline.
    redrawstatus
endfunction "}}}
function! eskk#get_mode() "{{{
    let self = eskk#get_current_instance()
    return self.mode
endfunction "}}}
function! eskk#is_supported_mode(mode) "{{{
    return has_key(s:available_modes, a:mode)
endfunction "}}}
function! eskk#register_mode(mode) "{{{
    let s:available_modes[a:mode] = extend(
    \   (a:0 ? a:1 : {}),
    \   {'sandbox': {}},
    \   'keep'
    \)
endfunction "}}}
function! eskk#validate_mode_structure(mode) "{{{
    " It should be recommended to call this function at the end of mode register.

    let self = eskk#get_current_instance()
    let st = eskk#get_mode_structure(a:mode)

    for key in ['filter', 'sandbox']
        if !has_key(st, key)
            throw eskk#user_error(['eskk'], printf("eskk#register_mode(%s): %s is not present in structure", string(a:mode), string(key)))
        endif
    endfor
endfunction "}}}
function! eskk#get_current_mode_structure() "{{{
    return eskk#get_mode_structure(eskk#get_mode())
endfunction "}}}
function! eskk#get_mode_structure(mode) "{{{
    let self = eskk#get_current_instance()
    if !eskk#is_supported_mode(a:mode)
        throw eskk#user_error(['eskk'], printf("mode '%s' is not available.", a:mode))
    endif
    return s:available_modes[a:mode]
endfunction "}}}
function! eskk#has_mode_func(func_key) "{{{
    let self = eskk#get_current_instance()
    let st = eskk#get_mode_structure(self.mode)
    return has_key(st, a:func_key)
endfunction "}}}
function! eskk#call_mode_func(func_key, args, required) "{{{
    let self = eskk#get_current_instance()
    let st = eskk#get_mode_structure(self.mode)
    if !has_key(st, a:func_key)
        if a:required
            let msg = printf("Mode '%s' does not have required function key", self.mode)
            throw eskk#internal_error(['eskk'], msg)
        endif
        return
    endif
    return call(st[a:func_key], a:args, st)
endfunction "}}}

function! eskk#has_current_mode_table() "{{{
    return eskk#has_mode_table(eskk#get_mode())
endfunction "}}}
function! eskk#has_mode_table(mode) "{{{
    return has_key(g:eskk_mode_use_tables, a:mode)
endfunction "}}}
function! eskk#get_current_mode_table() "{{{
    return eskk#get_mode_table(eskk#get_mode())
endfunction "}}}
function! eskk#get_mode_table(mode) "{{{
    return g:eskk_mode_use_tables[a:mode]
endfunction "}}}

" Statusline
function! eskk#get_stl() "{{{
    let self = eskk#get_current_instance()
    return eskk#is_enabled() ? printf('[eskk:%s]', get(g:eskk_statusline_mode_strings, self.mode, '??')) : ''
endfunction "}}}

" Buftable
function! eskk#get_buftable() "{{{
    let self = eskk#get_current_instance()
    if empty(self._buftable)
        let self._buftable = eskk#buftable#new()
    endif
    return self._buftable
endfunction "}}}
function! eskk#set_buftable(buftable) "{{{
    let self = eskk#get_current_instance()
    call a:buftable.set_old_str(
    \   empty(self._buftable) ? '' : self._buftable.get_old_str()
    \)
    let self._buftable = a:buftable
endfunction "}}}

" Event
function! eskk#register_event(event_names, Fn, head_args, ...) "{{{
    let args = [s:event_hook_fn, a:event_names, a:Fn, a:head_args, (a:0 ? a:1 : -1)]
    return call('s:register_event', args)
endfunction "}}}
function! eskk#register_temp_event(event_names, Fn, head_args, ...) "{{{
    let self = eskk#get_current_instance()
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
function! eskk#throw_event(event_name) "{{{
    call eskk#util#log("Do event - " . a:event_name)

    let self = eskk#get_current_instance()
    let ret        = []
    let event      = get(s:event_hook_fn, a:event_name, [])
    let temp_event = get(self.temp_event_hook_fn, a:event_name, [])
    let all_events = event + temp_event
    if empty(all_events)
        return []
    endif

    while !empty(all_events)
        let call_args = remove(all_events, 0)
        call add(ret, call('call', call_args))
    endwhile

    " Clear temporary hooks.
    let self.temp_event_hook_fn[a:event_name] = []

    return ret
endfunction "}}}
function! eskk#has_event(event_name) "{{{
    let self = eskk#get_current_instance()
    return
    \   !empty(get(s:event_hook_fn, a:event_name, []))
    \   || !empty(get(self.temp_event_hook_fn, a:event_name, []))
endfunction "}}}

function! eskk#register_map(map, Fn, args, force) "{{{
    let map = eskk#util#key2char(a:map)
    if has_key(s:key_handler, map) && !a:force
        return
    endif
    let s:key_handler[map] = [a:Fn, a:args]
endfunction "}}}
function! eskk#unregister_map(map, Fn, args) "{{{
    let map = eskk#util#key2char(a:map)
    if has_key(s:key_handler, map)
        unlet s:key_handler[map]
    endif
endfunction "}}}

" Henkan result
function! eskk#get_prev_henkan_result() "{{{
    let self = eskk#get_current_instance()
    return self.prev_henkan_result
endfunction "}}}
function! eskk#set_henkan_result(henkan_result) "{{{
    let self = eskk#get_current_instance()
    let self.prev_henkan_result = a:henkan_result
endfunction "}}}

" Locking diff old string
function! eskk#lock_old_str() "{{{
    let self = eskk#get_current_instance()
    let self.is_locked_old_str = 1
endfunction "}}}
function! eskk#unlock_old_str() "{{{
    let self = eskk#get_current_instance()
    let self.is_locked_old_str = 0
endfunction "}}}

" Filter
function! eskk#filter(char) "{{{
    call eskk#util#log('')    " for readability.
    let self = eskk#get_current_instance()
    return s:filter(self, a:char)
endfunction "}}}
function! s:filter(self, char) "{{{
    let self = a:self
    let buftable = eskk#get_buftable()

    if g:eskk_debug
        call eskk#util#logf('a:char = %s(%d)', a:char, char2nr(a:char))
        " Check irregular circumstance.
        if !eskk#is_supported_mode(self.mode)
            call eskk#util#warn('current mode is not supported: ' . self.mode)
            sleep 1
        endif
    endif


    call eskk#throw_event('filter-begin')

    let stash = {
    \   'char': a:char,
    \   'return': 0,
    \
    \   'buftable': buftable,
    \   'phase': buftable.get_henkan_phase(),
    \   'buf_str': buftable.get_current_buf_str(),
    \   'mode': eskk#get_mode(),
    \}

    if !self.is_locked_old_str
        call buftable.set_old_str(buftable.get_display_str())
    endif

    try
        let do_filter = 1
        if g:eskk_enable_completion && pumvisible() && self.has_started_completion
            let do_filter = eskk#complete#handle_special_key(stash)
        else
            let self.has_started_completion = 0
        endif

        if do_filter
            call s:call_filter_fn(stash)
        endif
        return s:rewrite_string(stash.return)

    catch
        call s:write_error_log_file(v:exception, v:throwpoint, a:char)
        return eskk#escape_key() . a:char

    finally
        call eskk#throw_event('filter-finalize')
    endtry
endfunction "}}}
function! s:call_filter_fn(stash) "{{{
    let filter_args = [a:stash]
    let rom = a:stash.buftable.get_current_buf_str().get_input_rom() . a:stash.char
    if has_key(s:key_handler, rom)
        " Call eskk#register_map()'s handlers.
        let [Fn, args] = s:key_handler[rom]
        call call(Fn, filter_args + args)
    else
        call eskk#call_mode_func('filter', filter_args, 1)
    endif
endfunction "}}}
function! s:rewrite_string(return_string) "{{{
    let redispatch_pre = ''
    if eskk#has_event('filter-redispatch-pre')
        execute
        \   eskk#get_map_command()
        \   '<buffer><expr>'
        \   '<Plug>(eskk:_filter_redispatch_pre)'
        \   'join(eskk#throw_event("filter-redispatch-pre"), "")'
        let redispatch_pre = "\<Plug>(eskk:_filter_redispatch_pre)"
    endif

    let redispatch_post = ''
    if eskk#has_event('filter-redispatch-post')
        execute
        \   eskk#get_map_command()
        \   '<buffer><expr>'
        \   '<Plug>(eskk:_filter_redispatch_post)'
        \   'join(eskk#throw_event("filter-redispatch-post"), "")'
        let redispatch_post = "\<Plug>(eskk:_filter_redispatch_post)"
    endif

    return
    \   redispatch_pre
    \   . (type(a:return_string) == type("") ? a:return_string : eskk#get_buftable().rewrite())
    \   . redispatch_post
endfunction "}}}
function! s:write_error_log_file(v_exception, v_throwpoint, char) "{{{
    let lines = []
    call add(lines, '--- g:eskk_version ---')
    call add(lines, printf('g:eskk_version = %s', string(g:eskk_version)))
    call add(lines, '--- g:eskk_version ---')
    call add(lines, '--- char ---')
    call add(lines, printf('char: %s(%d)', string(a:char), char2nr(a:char)))
    call add(lines, printf('mode(): %s', mode()))
    call add(lines, '--- char ---')
    call add(lines, '')
    call add(lines, '--- exception ---')
    if a:v_exception =~# '^eskk:'
        call add(lines, 'exception type: eskk exception')
        call add(lines, printf('v:exception: %s', eskk#get_exception_message(a:v_exception)))
    else
        call add(lines, 'exception type: Vim internal error')
        call add(lines, printf('v:exception: %s', a:v_exception))
    endif
    call add(lines, printf('v:throwpoint: %s', a:v_throwpoint))
    call add(lines, '--- exception ---')
    call add(lines, '')
    call add(lines, '--- buftable ---')
    let lines += eskk#get_buftable().dump()
    call add(lines, '--- buftable ---')
    call add(lines, '')
    call add(lines, "--- Vim's :version ---")
    redir => output
    silent version
    redir END
    let lines += split(output, '\n')
    call add(lines, "--- Vim's :version ---")
    call add(lines, '')
    call add(lines, '')
    if executable('uname')
        call add(lines, "--- Operating System ---")
        call add(lines, printf('"uname -a" = %s', system('uname -a')))
        call add(lines, "--- Operating System ---")
        call add(lines, '')
    endif
    call add(lines, '--- feature-list ---')
    call add(lines, 'gui_running = '.has('gui_running'))
    call add(lines, 'unix = '.has('unix'))
    call add(lines, 'mac = '.has('mac'))
    call add(lines, 'macunix = '.has('macunix'))
    call add(lines, 'win16 = '.has('win16'))
    call add(lines, 'win32 = '.has('win32'))
    call add(lines, 'win64 = '.has('win64'))
    call add(lines, 'win32unix = '.has('win32unix'))
    call add(lines, 'win95 = '.has('win95'))
    call add(lines, 'amiga = '.has('amiga'))
    call add(lines, 'beos = '.has('beos'))
    call add(lines, 'dos16 = '.has('dos16'))
    call add(lines, 'dos32 = '.has('dos32'))
    call add(lines, 'os2 = '.has('macunix'))
    call add(lines, 'qnx = '.has('qnx'))
    call add(lines, 'vms = '.has('vms'))
    call add(lines, '--- feature-list ---')
    call add(lines, '')
    call add(lines, '')
    call add(lines, "Please report this error to author.")
    call add(lines, "`:help eskk` to see author's e-mail address.")

    let log_file = expand(g:eskk_error_log_file)
    let write_success = 0
    try
        call writefile(lines, log_file)
        let write_success = 1
    catch
        for l in lines
            call eskk#util#warn(l)
        endfor
    endtry

    let save_cmdheight = &cmdheight
    setlocal cmdheight=3
    try
        call eskk#util#warnf(
        \   "Error has occurred!! Please see %s to check and please report to plugin author.",
        \   (write_success ? string(log_file) : ':messages')
        \)
        sleep 500m
    finally
        let &cmdheight = save_cmdheight
    endtry
endfunction "}}}

" For test
function! eskk#emulate_filter_keys(chars, ...) "{{{
    " This function is written almost for the tests.
    " But maybe this is useful
    " when someone (not me) tries to emulate keys? :)

    let clear_buftable = a:0 ? a:1 : 1
    let ret = ''
    let plug = strtrans("\<Plug>")
    let mapmode = eskk#get_map_modes()[0:0]
    for c in split(a:chars, '\zs')
        let r = eskk#filter(c)
        let r = eskk#util#remove_all_ctrl_chars(r, "\<Plug>")

        " Remove `<Plug>(eskk:_filter_redispatch_pre)` beforehand.
        let pre = ''
        if r =~# '(eskk:_filter_redispatch_pre)'
            let pre = maparg('<Plug>(eskk:_filter_redispatch_pre)', mapmode)
            let r = substitute(r, '(eskk:_filter_redispatch_pre)', '', '')
        endif

        " Remove `<Plug>(eskk:_filter_redispatch_post)` beforehand.
        let post = ''
        if r =~# '(eskk:_filter_redispatch_post)'
            let post = maparg('<Plug>(eskk:_filter_redispatch_post)', mapmode)
            let r = substitute(r, '(eskk:_filter_redispatch_post)', '', '')
        endif

        " Expand <Plug> mappings.
        let r = substitute(r, '(eskk:[^()]\+)', '\=eskk#util#key2char(eskk#util#do_remap("<Plug>".submatch(0), mapmode))', 'g')

        let [r, ret] = s:emulate_backspace(r, ret)

        " Handle `<Plug>(eskk:_filter_redispatch_pre)`.
        if pre != ''
            let _ = eval(pre)
            let _ = eskk#util#remove_all_ctrl_chars(r, "\<Plug>")
            let [_, ret] = s:emulate_filter_char(_, ret)
            let _ = substitute(_, '(eskk:[^()]\+)', '\=eskk#util#key2char(eskk#util#do_remap("<Plug>".submatch(0), mapmode))', 'g')
            let ret .= _
            let ret .= eskk#util#do_remap(eval(pre), mapmode)
        endif

        " Handle rewritten text.
        let ret .= r

        " Handle `<Plug>(eskk:_filter_redispatch_post)`.
        if post != ''
            let _ = eval(post)
            let _ = eskk#util#remove_all_ctrl_chars(_, "\<Plug>")
            let [_, ret] = s:emulate_filter_char(_, ret)
            let _ = substitute(_, '(eskk:[^()]\+)', '\=eskk#util#key2char(eskk#util#do_remap("<Plug>".submatch(0), mapmode))', 'g')
            let ret .= _
        endif
    endfor

    " For convenience.
    if clear_buftable
        let buftable = eskk#get_buftable()
        call buftable.clear_all()
    endif

    return ret
endfunction "}}}
function! s:emulate_backspace(str, cur_ret) "{{{
    let r = a:str
    let ret = a:cur_ret
    for bs in ["\<BS>", "\<C-h>"]
        while 1
            let [r, pos] = eskk#util#remove_ctrl_char(r, bs)
            if pos ==# -1
                break
            endif
            if pos ==# 0
                if ret == ''
                    let r = bs . r
                    break
                else
                    let ret = eskk#util#mb_chop(ret)
                endif
            else
                let before = strpart(r, 0, pos)
                let after = strpart(r, pos)
                let before = eskk#util#mb_chop(before)
                let r = before . after
            endif
        endwhile
    endfor
    return [r, ret]
endfunction "}}}
function! s:emulate_filter_char(str, cur_ret) "{{{
    let r = a:str
    let ret = a:cur_ret
    while 1
        let pat = '(eskk:filter:\([^()]*\))'.'\C'
        let m = matchlist(r, pat)
        if empty(m)
            break
        endif
        let char = m[1]
        let r = substitute(r, pat, '', '')
        let _ = eskk#emulate_filter_keys(char, 0)
        let [_, ret] = s:emulate_backspace(_, ret)
        let r .= _
    endwhile
    return [r, ret]
endfunction "}}}


" g:eskk_context_control
function! eskk#handle_context() "{{{
    for control in g:eskk_context_control
        if eval(control.rule)
            call call(control.fn, [])
        endif
    endfor
endfunction "}}}


" g:eskk_use_color_cursor
function! eskk#set_cursor_color() "{{{
    " From s:SkkSetCursorColor() of skk.vim

    if has('gui_running') && g:eskk_use_color_cursor
        let color = get(g:eskk_cursor_color, eskk#get_mode(), '')
        if type(color) == type([]) && len(color) >= 2
            execute 'highlight lCursor guibg=' . color[&background ==# 'light' ? 0 : 1]
        elseif type(color) == type("") && color != ''
            execute 'highlight lCursor guibg=' . color
        endif
    endif
endfunction "}}}


" <Plug>(eskk:alpha-t), <Plug>(eskk:alpha-f)
function! eskk#jump_one_char(cmd, ...) "{{{
    if a:cmd !=? 't' && a:cmd !=? 'f'
        return
    endif
    let is_t = a:cmd ==? 't'
    let is_forward = eskk#util#is_lower(a:cmd)
    let s:last_jump_cmd = a:cmd

    if a:0 == 0
        let char = eskk#util#getchar()
        let s:last_jump_char = char
    else
        let char = a:1
    endif

    if is_forward
        if col('.') == col('$')
            return
        endif
        let rest_line = getline('.')[col('.') :]
        let idx = stridx(rest_line, char)
        if idx != -1
            call cursor(line('.'), col('.') + idx + 1 - is_t)
        endif
    else
        if col('.') == 1
            return
        endif
        let rest_line = getline('.')[: col('.') - 2]
        let idx = strridx(rest_line, char)
        if idx != -1
            call cursor(line('.'), idx + 1 + is_t)
        endif
    endif
endfunction "}}}
function! eskk#repeat_last_jump(cmd) "{{{
    if a:cmd !=# ',' && a:cmd !=# ';'
        return
    endif
    if type(s:last_jump_cmd) == type("")
    \   && type(s:last_jump_char) == type("")
        return
    endif

    if a:cmd ==# ','
        let s:last_jump_char = s:invert_direction(s:last_jump_char)
    endif
    call eskk#jump_one_char(s:last_jump_cmd, s:last_jump_char)
endfunction "}}}
function! s:invert_direction(cmd) "{{{
    return eskk#util#is_lower(a:cmd) ? toupper(a:cmd) : tolower(a:cmd)
endfunction "}}}

" }}}

" Exceptions {{{
function! s:build_error(from, msg) "{{{
    return 'eskk: ' . join(a:msg, ': ') . ' at ' . join(a:from, '#')
endfunction "}}}
function! eskk#get_exception_message(error_str) "{{{
    " Get only `a:msg` of s:build_error().
    let s = a:error_str
    let s = substitute(s, '^eskk: ', '', '')
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

function! s:initialize() "{{{
    " Create eskk augroup. {{{
    augroup eskk
        autocmd!
    augroup END
    " }}}

    " Write timestamp to debug file {{{
    call eskk#util#log('')

    call eskk#util#log(repeat('-', 80))

    call eskk#util#log(strftime('%c'))

    let lface = "( ._.) <"
    let v = printf(" g:eskk_version = %s /", string(g:eskk_version))
    call eskk#util#log(repeat(' ', strlen(lface)).' '.repeat('-', strlen(v) - 1))
    call eskk#util#log(lface.v)
    call eskk#util#log(repeat(' ', strlen(lface)).repeat('-', strlen(v) - 1))

    let rface = "> ('-' )"
    let v = printf("/ v:version = %s ", string(v:version))
    call eskk#util#log(' '.repeat('-', strlen(v) - 1))
    call eskk#util#log(v.rface)
    call eskk#util#log(repeat('-', strlen(v) - 1))

    call eskk#util#log('')
    let n = eskk#util#rand(3)
    if n ==# 0
        call eskk#util#log("e = extended,enhanced,environment,...enlightenment?")
    elseif n ==# 1
        call eskk#util#log('SKK = I')
        call eskk#util#log('e * SKK = Inf.')
    else
        call eskk#util#log("( '-')                  ('-' )")
        call eskk#util#log('(/ *_*)/******************(*_* )*********')
    endif

    call eskk#util#log(repeat('-', 80))

    call eskk#util#log('')
    call eskk#util#log('')
    " }}}

    " Egg-like-newline {{{
    function! s:do_lmap_non_egg_like_newline(do_map) "{{{
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
    if !g:eskk_egg_like_newline
        " Default behavior is `egg like newline`.
        " Turns it to `Non egg like newline` during henkan phase.
        call eskk#register_event(['enter-phase-henkan', 'enter-phase-okuri', 'enter-phase-henkan-select'], eskk#util#get_local_func('do_lmap_non_egg_like_newline', s:SID_PREFIX), [1])
        call eskk#register_event('enter-phase-normal', eskk#util#get_local_func('do_lmap_non_egg_like_newline', s:SID_PREFIX), [0])
    endif
    " }}}

    " InsertLeave: g:eskk_keep_state: eskk#disable() {{{
    if !g:eskk_keep_state
        autocmd eskk InsertLeave * call eskk#disable()
    endif
    " }}}

    " Default mappings - :EskkMap {{{
    silent! EskkMap -unique <C-^> <Plug>(eskk:toggle)

    silent! EskkMap -type=sticky -unique ;
    silent! EskkMap -type=backspace-key -unique <C-h>
    silent! EskkMap -type=enter-key -unique <CR>
    silent! EskkMap -type=escape-key -unique <Esc>
    silent! EskkMap -type=undo-key -unique <C-g>u

    silent! EskkMap -type=phase:henkan:henkan-key -unique <Space>

    silent! EskkMap -type=phase:okuri:henkan-key -unique <Space>

    silent! EskkMap -type=phase:henkan-select:choose-next -unique <Space>
    silent! EskkMap -type=phase:henkan-select:choose-prev -unique x

    silent! EskkMap -type=phase:henkan-select:next-page -unique <Space>
    silent! EskkMap -type=phase:henkan-select:prev-page -unique x

    silent! EskkMap -type=phase:henkan-select:escape -unique <C-g>

    silent! EskkMap -type=mode:hira:toggle-hankata -unique <C-q>
    silent! EskkMap -type=mode:hira:ctrl-q-key -unique <C-q>
    silent! EskkMap -type=mode:hira:toggle-kata -unique q
    silent! EskkMap -type=mode:hira:q-key -unique q
    silent! EskkMap -type=mode:hira:to-ascii -unique l
    silent! EskkMap -type=mode:hira:to-zenei -unique L
    silent! EskkMap -type=mode:hira:to-abbrev -unique /

    silent! EskkMap -type=mode:kata:toggle-hankata -unique <C-q>
    silent! EskkMap -type=mode:kata:ctrl-q-key -unique <C-q>
    silent! EskkMap -type=mode:kata:toggle-kata -unique q
    silent! EskkMap -type=mode:kata:q-key -unique q
    silent! EskkMap -type=mode:kata:to-ascii -unique l
    silent! EskkMap -type=mode:kata:to-zenei -unique L
    silent! EskkMap -type=mode:kata:to-abbrev -unique /

    silent! EskkMap -type=mode:hankata:toggle-hankata -unique <C-q>
    silent! EskkMap -type=mode:hankata:ctrl-q-key -unique <C-q>
    silent! EskkMap -type=mode:hankata:toggle-kata -unique q
    silent! EskkMap -type=mode:hankata:q-key -unique q
    silent! EskkMap -type=mode:hankata:to-ascii -unique l
    silent! EskkMap -type=mode:hankata:to-zenei -unique L
    silent! EskkMap -type=mode:hankata:to-abbrev -unique /

    silent! EskkMap -type=mode:ascii:to-hira -unique <C-j>

    silent! EskkMap -type=mode:zenei:to-hira -unique <C-j>

    silent! EskkMap -type=mode:abbrev:henkan-key -unique <Space>

    silent! EskkMap <BS> <Plug>(eskk:filter:<C-h>)

    silent! EskkMap -expr -noremap -map-if="mode() ==# 'i'" -unique <Esc> eskk#escape_key()
    silent! EskkMap -expr -noremap -map-if="mode() ==# 'i'" -unique <C-c> eskk#escape_key()
    " }}}

    " Map temporary key to keys to use in that mode {{{
    function! s:map_mode_local_keys() "{{{
        let mode = eskk#get_mode()

        if has_key(s:mode_local_keys, mode)
            for key in s:mode_local_keys[mode]
                let real_key = eskk#get_special_key(key)
                call eskk#set_up_temp_key(real_key)
                call eskk#register_temp_event('leave-mode-' . mode, 'eskk#set_up_temp_key_restore', [real_key])
            endfor
        endif
    endfunction "}}}
    call eskk#register_event('enter-mode', eskk#util#get_local_func('map_mode_local_keys', s:SID_PREFIX), [])
    " }}}

    " Save dictionary if modified {{{
    if g:eskk_auto_save_dictionary_at_exit
        autocmd eskk VimLeavePre * call eskk#update_dictionary()
    endif
    " }}}

    " Register builtin-modes. {{{
    call eskk#util#log('Registering builtin modes...')

    function! s:set_current_to_begin_pos() "{{{
        call eskk#get_buftable().set_begin_pos('.')
    endfunction "}}}


    " 'ascii' mode {{{
    call eskk#register_mode('ascii')
    let dict = eskk#get_mode_structure('ascii')

    function! dict.filter(stash)
        let this = eskk#get_mode_structure('ascii')
        if eskk#is_special_lhs(a:stash.char, 'mode:ascii:to-hira')
            call eskk#set_mode('hira')
        else
            if a:stash.char !=# "\<BS>"
            \   && a:stash.char !=# "\<C-h>"
                if a:stash.char =~# '\w'
                    if !has_key(this.sandbox, 'already_set_for_this_word')
                        " Set start col of word.
                        call s:set_current_to_begin_pos()
                        let this.sandbox.already_set_for_this_word = 1
                    endif
                else
                    if has_key(this.sandbox, 'already_set_for_this_word')
                        unlet this.sandbox.already_set_for_this_word
                    endif
                endif
            endif

            if has_key(g:eskk_mode_use_tables, 'ascii')
                if !has_key(this.sandbox, 'table')
                    let this.sandbox.table = eskk#table#new(g:eskk_mode_use_tables.ascii)
                endif
                let a:stash.return = this.sandbox.table.get_map(a:stash.char, a:stash.char)
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
        let this = eskk#get_mode_structure('zenei')
        if eskk#is_special_lhs(a:stash.char, 'mode:zenei:to-hira')
            call eskk#set_mode('hira')
        else
            if !has_key(this.sandbox, 'table')
                let this.sandbox.table = eskk#table#new(g:eskk_mode_use_tables.zenei)
            endif
            let a:stash.return = this.sandbox.table.get_map(a:stash.char, a:stash.char)
        endif
    endfunction

    call eskk#register_event(
    \   'enter-mode-abbrev',
    \   eskk#util#get_local_func('set_current_to_begin_pos', s:SID_PREFIX),
    \   []
    \)

    call eskk#validate_mode_structure('zenei')
    " }}}

    " 'hira' mode {{{
    call eskk#register_mode('hira')
    let dict = eskk#get_mode_structure('hira')

    call extend(dict, eskk#create_asym_filter(g:eskk_mode_use_tables.hira))

    call eskk#validate_mode_structure('hira')
    " }}}

    " 'kata' mode {{{
    call eskk#register_mode('kata')
    let dict = eskk#get_mode_structure('kata')

    call extend(dict, eskk#create_asym_filter(g:eskk_mode_use_tables.kata))

    call eskk#validate_mode_structure('kata')
    " }}}

    " 'hankata' mode {{{
    call eskk#register_mode('hankata')
    let dict = eskk#get_mode_structure('hankata')

    call extend(dict, eskk#create_asym_filter(g:eskk_mode_use_tables.hankata))

    call eskk#validate_mode_structure('hankata')
    " }}}

    " 'abbrev' mode {{{
    call eskk#register_mode('abbrev')
    let dict = eskk#get_mode_structure('abbrev')

    function! dict.filter(stash) "{{{
        let char = a:stash.char
        let buftable = eskk#get_buftable()
        let this = eskk#get_mode_structure('abbrev')
        let buf_str = buftable.get_current_buf_str()
        let phase = buftable.get_henkan_phase()

        " Handle special characters.
        " These characters are handled regardless of current phase.
        if eskk#is_special_lhs(char, 'backspace-key')
            if buf_str.get_rom_str() == ''
                " If backspace-key was pressed at empty string,
                " leave abbrev mode.
                " TODO: Back to previous mode?
                call eskk#set_mode('hira')
            else
                call buftable.do_backspace(a:stash)
            endif
            return
        elseif eskk#is_special_lhs(char, 'enter-key')
            call buftable.do_enter(a:stash)
            call eskk#set_mode('hira')
            return
        else
            " Fall through.
        endif

        " Handle other characters.
        if phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
            if eskk#is_special_lhs(char, 'phase:henkan:henkan-key')
                call buftable.do_henkan(a:stash)
            else
                call buf_str.push_rom_str(char)
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
                call buftable.clear_all()
                call eskk#register_temp_event(
                \   'filter-redispatch-post',
                \   'eskk#util#identity',
                \   [eskk#util#key2char(eskk#get_named_map(a:stash.char))]
                \)

                " Leave abbrev mode.
                " TODO: Back to previous mode?
                call eskk#set_mode('hira')
            endif
        else
            let msg = printf("'abbrev' mode does not support phase %d.", phase)
            throw eskk#internal_error(['eskk'], msg)
        endif
    endfunction "}}}
    function! dict.get_init_phase() "{{{
        return g:eskk#buftable#HENKAN_PHASE_HENKAN
    endfunction "}}}
    function! dict.get_supported_phases() "{{{
        return [
        \   g:eskk#buftable#HENKAN_PHASE_HENKAN,
        \   g:eskk#buftable#HENKAN_PHASE_HENKAN_SELECT,
        \]
    endfunction "}}}

    call eskk#register_event(
    \   'enter-mode-abbrev',
    \   eskk#util#get_local_func('set_current_to_begin_pos', s:SID_PREFIX),
    \   []
    \)

    call eskk#validate_mode_structure('abbrev')
    " }}}
    " }}}

    " Register builtin-tables. {{{
    call eskk#util#log('Registering builtin tables...')
    " NOTE: "hira_to_kata" and "kata_to_hira" are not used.
    let tables = eskk#table#get_all_tables()
    call eskk#util#logstrf('tables = %s', tables)
    let tabletmpl = {}    " dummy object
    function! tabletmpl.init() dict
        call self.add_from_dict(eskk#table#{self.name}#load())
    endfunction
    for name in tables
        let table = eskk#table#create(name)
        let table.init = tabletmpl.init
        call table.register()
    endfor
    " }}}

    " BufEnter: Map keys if enabled. {{{
    autocmd eskk BufEnter * if eskk#is_enabled() | call eskk#map_all_keys() | endif
    " }}}

    " BufEnter: Restore global option value of &iminsert, &imsearch {{{
    function! s:restore_im_options() "{{{
        if empty(s:saved_im_options)
            return
        endif
        let [&g:iminsert, &g:imsearch] = s:saved_im_options
    endfunction "}}}

    if !g:eskk_keep_state_beyond_buffer
        autocmd eskk BufLeave * call s:restore_im_options()
    endif
    " }}}

    " InsertEnter: Clear buftable. {{{
    autocmd eskk InsertEnter * call eskk#get_buftable().reset()
    " }}}

    " InsertLeave: g:eskk_convert_at_exact_match {{{
    function! s:clear_real_matched_pairs() "{{{
        if !eskk#is_enabled() || eskk#get_mode() == ''
            return
        endif

        let st = eskk#get_current_mode_structure()
        if has_key(st.sandbox, 'real_matched_pairs')
            unlet st.sandbox.real_matched_pairs
        endif
    endfunction "}}}
    autocmd eskk InsertLeave * call s:clear_real_matched_pairs()
    " }}}

    " s:saved_im_options {{{
    call eskk#util#assert(empty(s:saved_im_options))
    let s:saved_im_options = [&g:iminsert, &g:imsearch]
    " }}}

    " Event: enter-mode {{{
    call eskk#register_event(
    \   'enter-mode',
    \   'eskk#set_cursor_color',
    \   []
    \)

    function! s:initialize_clear_buftable()
        let buftable = eskk#get_buftable()
        call buftable.clear_all()
    endfunction
    call eskk#register_event(
    \   'enter-mode',
    \   eskk#util#get_local_func('initialize_clear_buftable', s:SID_PREFIX),
    \   []
    \)

    function! s:initialize_set_henkan_phase()
        let buftable = eskk#get_buftable()
        call buftable.set_henkan_phase(
        \   (eskk#has_mode_func('get_init_phase') ?
        \       eskk#call_mode_func('get_init_phase', [], 0)
        \       : g:eskk#buftable#HENKAN_PHASE_NORMAL)
        \)
    endfunction
    call eskk#register_event(
    \   'enter-mode',
    \   eskk#util#get_local_func('initialize_set_henkan_phase', s:SID_PREFIX),
    \   []
    \)
    " }}}

    " InsertLeave: Restore &backspace value {{{
    " NOTE: Due to current implementation,
    " s:buftable.rewrite() assumes that &backspace contains "eol".
    if &l:backspace !~# '\<eol\>'
        let s:saved_backspace = &l:backspace
        setlocal backspace+=eol
        autocmd eskk InsertEnter * setlocal backspace+=eol
        autocmd eskk InsertLeave * let &l:backspace = s:saved_backspace
    endif
    " }}}

    " Create <Plug>(eskk:internal:set-begin-pos) {{{
    noremap! <expr> <Plug>(eskk:internal:set-begin-pos) [eskk#get_buftable().set_begin_pos('.'), ''][1]
    " }}}
endfunction "}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

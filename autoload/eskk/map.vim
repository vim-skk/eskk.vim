" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID


let s:prev_normal_keys = {}
let s:has_setup_mode_local_keys = 0


function! s:handle_toggle_hankata(stash) "{{{
    let phase = eskk#get_buftable().get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'hankata' ? 'hira' : 'hankata')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_toggle_kata(stash) "{{{
    let phase = eskk#get_buftable().get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'kata' ? 'hira' : 'kata')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_ctrl_q_key(stash) "{{{
    let phase = eskk#get_buftable().get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_HENKAN
    \   || phase ==# g:eskk#buftable#PHASE_OKURI
        call eskk#get_buftable().do_ctrl_q_key()
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_q_key(stash) "{{{
    let phase = eskk#get_buftable().get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_HENKAN
    \   || phase ==# g:eskk#buftable#PHASE_OKURI
        call eskk#get_buftable().do_q_key()
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_l_key(stash) "{{{
    let phase = eskk#get_buftable().get_henkan_phase()
    if phase ==# g:eskk#buftable#PHASE_HENKAN
    \   || phase ==# g:eskk#buftable#PHASE_OKURI
        call eskk#get_buftable().do_l_key()
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_ascii(stash) "{{{
    let buftable = eskk#get_buftable()
    let phase = buftable.get_henkan_phase()
    let buf_str = buftable.get_current_buf_str()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
    \   && buf_str.rom_str.get() == ''
        call eskk#set_mode('ascii')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_zenei(stash) "{{{
    let buftable = eskk#get_buftable()
    let phase = buftable.get_henkan_phase()
    let buf_str = buftable.get_current_buf_str()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
    \   && buf_str.rom_str.get() == ''
        call eskk#set_mode('zenei')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_abbrev(stash) "{{{
    let buftable = eskk#get_buftable()
    let phase = eskk#get_buftable().get_henkan_phase()
    let buf_str = buftable.get_current_buf_str()
    if phase ==# g:eskk#buftable#PHASE_NORMAL
    \   && buf_str.rom_str.get() == ''
        call eskk#set_mode('abbrev')
        return 1
    endif
    return 0
endfunction "}}}

" Keys used by only its mode.
let s:MODE_LOCAL_KEYS = {
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


" Utilities

function! s:split_to_keys(lhs)  "{{{
    " From arpeggio.vim
    "
    " Assumption: Special keys such as <C-u>
    " are escaped with < and >, i.e.,
    " a:lhs doesn't directly contain any escape sequences.
    return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfunction "}}}
function! eskk#map#key2char(key) "{{{
    if stridx(a:key, '<') ==# -1    " optimization
        return a:key
    endif
    return join(
    \   map(
    \       s:split_to_keys(a:key),
    \       'v:val =~ "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val'
    \   ),
    \   ''
    \)
endfunction "}}}

" FIXME: Make a class for these functions.
function! s:create_default_mapopt() "{{{
    return {
    \   'buffer': 0,
    \   'expr': 0,
    \   'silent': 0,
    \   'unique': 0,
    \   'noremap': 1,
    \   'map-if': '1',
    \}
endfunction "}}}

function! eskk#map#get_map_modes() "{{{
    " XXX: :lmap can't remap to :lmap. It's Vim's bug.
    "   http://groups.google.com/group/vim_dev/browse_thread/thread/17a1273eb82d682d/
    " So I use :map! mappings for 'fallback' of :lmap.

    return 'ic'
endfunction "}}}
function! eskk#map#get_filter_map(key) "{{{
    " NOTE:
    " a:key is escaped. So when a:key is '<C-a>', return value is
    "   `<Plug>(eskk:filter:<C-a>)`
    " not
    "   `<Plug>(eskk:filter:^A)` (^A is control character)

    let lhs = printf('<Plug>(eskk:filter:%s)', a:key)
    if maparg(lhs, eskk#map#get_map_modes()) != ''
        return lhs
    endif

    call eskk#map#map('re', lhs, 'eskk#filter(' . string(a:key) . ')')

    return lhs
endfunction "}}}
function! eskk#map#get_nore_map(key, ...) "{{{
    " NOTE:
    " a:key is escaped. So when a:key is '<C-a>', return value is
    "   `<Plug>(eskk:filter:<C-a>)`
    " not
    "   `<Plug>(eskk:filter:^A)` (^A is control character)

    let [rhs, key] = [a:key, a:key]

    let lhs = printf('<Plug>(eskk:noremap:%s)', key)
    if maparg(lhs, 'icl') != ''
        return lhs
    endif

    let options = a:0 ? substitute(a:1, 'r', '', 'g') : ''
    call eskk#map#map(options, lhs, rhs)

    return lhs
endfunction "}}}

function! eskk#map#map(options, lhs, rhs, ...) "{{{
    if a:lhs == '' || a:rhs == ''
        call eskk#error#logstrf(
        \   'lhs or rhs is empty: lhs = %s, rhs = %s',
        \   a:lhs,
        \   a:rhs
        \)
        return
    endif

    let dict = eskk#util#mapopt_chars2dict(a:options)
    let modes = a:0 ? a:1 : eskk#map#get_map_modes()
    for mode in split(modes, '\zs')
        let mapcmd = eskk#util#get_map_command(mode, dict, a:lhs, a:rhs)
        try
            execute mapcmd
        catch
            call eskk#error#log_exception(mapcmd)
        endtry
    endfor
endfunction "}}}
function! eskk#map#unmap(options, lhs, modes) "{{{
    if a:lhs == ''
        call eskk#error#logstrf('lhs is empty: lhs = %s', a:lhs)
        return
    endif

    let dict = eskk#util#mapopt_chars2dict(a:options)
    for mode in split(a:modes, '\zs')
        let mapcmd = eskk#util#get_unmap_command(mode, dict, a:lhs)
        try
            execute mapcmd
        catch
            call eskk#error#log_exception(mapcmd)
        endtry
    endfor
endfunction "}}}
function! eskk#map#map_from_maparg_dict(dict) "{{{
    " FIXME: mapopt dict should follow maparg()'s dict.

    if empty(a:dict)
        " The mapping does not exist.
        return
    endif

    let lhs = a:dict.lhs
    let rhs = a:dict.rhs
    let options = ''
    for [from, to] in items({
    \   'silent': 's',
    \   'expr': 'e',
    \   'buffer': 'b',
    \})
        let options .= a:dict[from] ? to : ''
    endfor
    let options .= a:dict.noremap ? '' : 'r'
    let modes = a:dict.mode
    return eskk#map#map(options, lhs, rhs, modes)
endfunction "}}}

function! eskk#map#set_up_key(key, ...) "{{{
    call eskk#map#map(
    \   'rb' . (a:0 ? a:1 : ''),
    \   a:key,
    \   eskk#map#get_filter_map(a:key),
    \   'l'
    \)
endfunction "}}}
function! eskk#map#set_up_temp_key(lhs, ...) "{{{
    " Assumption: a:lhs must be '<Bar>' not '|'.

    " Save current a:lhs mapping.
    let save_lhs = s:temp_key_map(a:lhs)
    let save_rhs = maparg(a:lhs, 'l')
    if save_rhs != '' && maparg(save_lhs) == ''
        " TODO Check if a:lhs is buffer local.
        call eskk#map#map('rb', save_lhs, save_rhs, 'l')
    endif

    if a:0
        call eskk#map#map('rb', a:lhs, a:1, 'l')
    else
        call eskk#map#set_up_key(a:lhs)
    endif
endfunction "}}}
function! eskk#map#set_up_temp_key_restore(lhs) "{{{
    let temp_key   = s:temp_key_map(a:lhs)
    let saved_rhs  = maparg(temp_key, 'l')
    let inst       = eskk#get_current_instance()

    if saved_rhs != ''
        call eskk#map#unmap('b', temp_key, 'l')
        call eskk#map#map('rb', a:lhs, saved_rhs, 'l')
    elseif s:has_setup_mode_local_keys
        " Show error only first time.
        call eskk#error#logf(
        \   "called eskk#map#set_up_temp_key_restore()"
        \       . " but no '%s' key is stashed.",
        \   a:lhs
        \)
        call eskk#map#set_up_key(a:lhs)
        let s:has_setup_mode_local_keys = 0
    endif
endfunction "}}}
function! eskk#map#has_temp_key(lhs) "{{{
    let temp_key = s:temp_key_map(a:lhs)
    let saved_rhs = maparg(temp_key, 'l')
    return saved_rhs != ''
endfunction "}}}
function! s:temp_key_map(key) "{{{
    return printf('<Plug>(eskk:prevmap:%s)', a:key)
endfunction "}}}

function! eskk#map#map_mode_local_keys() "{{{
    let mode = eskk#get_mode()

    let real_keys = []
    for key in get(s:MODE_LOCAL_KEYS, mode, [])
        let sp_key = eskk#map#get_special_key(key)
        call eskk#map#set_up_temp_key(sp_key)
        call add(real_keys, sp_key)
    endfor

    call eskk#register_temp_event(
    \   'leave-mode-' . mode,
    \   eskk#util#get_local_func(
    \       'unmap_mode_local_keys',
    \       s:SID_PREFIX
    \   ),
    \   [real_keys]
    \)
endfunction "}}}
function! s:unmap_mode_local_keys(real_keys) "{{{
    let inst = eskk#get_current_instance()
    for key in a:real_keys
        call eskk#map#set_up_temp_key_restore(key)
    endfor
    let s:has_setup_mode_local_keys = 1
endfunction "}}}


" g:eskk#keep_state
function! eskk#map#save_normal_keys() "{{{
    let s:prev_normal_keys = s:save_normal_keys()
    call s:unmap_normal_keys()
endfunction "}}}
function! eskk#map#restore_normal_keys() "{{{
    call s:restore_normal_keys(s:prev_normal_keys)
    let s:prev_normal_keys = {}
    call s:map_normal_keys()
endfunction "}}}
function! s:get_normal_keys() "{{{
    return split('iIaAoOcCsSR', '\zs')
endfunction "}}}
function! s:map_normal_keys() "{{{
    " From s:SkkMapNormal() in plugin/skk.vim

    let calling_hook_fn =
    \   eskk#util#get_local_func('do_normal_key', s:SID_PREFIX)
    \   . '(%s,' . &l:iminsert . ',' . &l:imsearch . ')'
    for key in s:get_normal_keys()
        call eskk#map#map('seb', key, printf(calling_hook_fn, string(key)), 'n')
    endfor
endfunction "}}}
function! s:do_normal_key(key, iminsert, imsearch) "{{{
    let &l:iminsert = a:iminsert
    let &l:imsearch = a:imsearch
    return a:key
endfunction "}}}
function! s:unmap_normal_keys() "{{{
    for key in s:get_normal_keys()
        " Exists <buffer> mapping.
        if get(maparg(key, 'n', 0, 1), 'buffer')
            call eskk#map#unmap('b', key, 'n')
        endif
    endfor
endfunction "}}}
function! s:save_normal_keys() "{{{
    if !savemap#supported_version()
        return {}
    endif

    let keys = {'info': {}}
    for key in s:get_normal_keys()
        let keys.info[key] = savemap#save_map('n', key)
    endfor
    function! keys.restore()
        for map in values(self.info)
            if has_key(map, 'restore')
                call map.restore()
            endif
        endfor
    endfunction
    return keys
endfunction "}}}
function! s:restore_normal_keys(keys) "{{{
    if has_key(a:keys, 'restore')
        call a:keys.restore()
    endif
endfunction "}}}


" Egg like newline
function! eskk#map#disable_egg_like_newline() "{{{
    call eskk#register_event(
    \   [
    \       'enter-phase-henkan',
    \       'enter-phase-okuri',
    \       'enter-phase-henkan-select'
    \   ],
    \   eskk#util#get_local_func(
    \       'do_lmap_non_egg_like_newline',
    \       s:SID_PREFIX
    \   ),
    \   [1]
    \)
    call eskk#register_event(
    \   'enter-phase-normal',
    \   eskk#util#get_local_func(
    \       'do_lmap_non_egg_like_newline',
    \       s:SID_PREFIX
    \   ),
    \   [0]
    \)
endfunction "}}}
function! s:do_lmap_non_egg_like_newline(enable) "{{{
    if a:enable
        " Enable
        if !eskk#map#has_temp_key('<CR>')
            call eskk#map#set_up_temp_key(
            \   '<CR>',
            \   '<Plug>(eskk:filter:<CR>)<Plug>(eskk:filter:<CR>)'
            \)
        endif
    else
        " Disable
        call eskk#register_temp_event(
        \   'filter-begin',
        \   'eskk#map#set_up_temp_key_restore',
        \   ['<CR>']
        \)
    endif
endfunction "}}}


" Functions using s:eskk_mappings
function! eskk#map#map_all_keys(...) "{{{
    let inst = eskk#get_buffer_instance()
    if has_key(inst, 'has_mapped')
        return
    endif


    lmapclear <buffer>

    " Map mapped keys.
    for key in g:eskk#mapped_keys
        call call('eskk#map#set_up_key', [key] + a:000)
    endfor

    " Map `:EskkMap -general` keys.
    let eskk_mappings = eskk#_get_eskk_mappings()
    for [key, opt] in items(eskk_mappings.general)
        if !eval(opt.options['map-if'])
            continue
        endif
        if opt.rhs == ''
            call eskk#map#set_up_key(
            \   key,
            \   eskk#util#mapopt_dict2chars(opt.options)
            \)
        else
            call eskk#map#map(
            \   'b'
            \       . (opt.options.noremap ? '' : 'r')
            \       . eskk#util#mapopt_dict2chars(opt.options),
            \   key,
            \   opt.rhs,
            \   'l'
            \)
        endif
    endfor

    let inst.has_mapped = 1
endfunction "}}}
function! eskk#map#unmap_all_keys() "{{{
    let inst = eskk#get_buffer_instance()
    if !has_key(inst, 'has_mapped')
        return
    endif

    for key in g:eskk#mapped_keys
        call eskk#map#unmap('b', key, 'l')
    endfor

    unlet inst.has_mapped
endfunction "}}}
function! eskk#map#is_special_lhs(char, type) "{{{
    " NOTE: This function must not show error
    " when `eskk_mappings[a:type]` does not exist.
    let eskk_mappings = eskk#_get_eskk_mappings()
    return has_key(eskk_mappings, a:type)
    \   && eskk#map#key2char(eskk_mappings[a:type].lhs) ==# a:char
endfunction "}}}
function! eskk#map#get_special_key(type) "{{{
    let eskk_mappings = eskk#_get_eskk_mappings()
    if has_key(eskk_mappings, a:type)
        return eskk_mappings[a:type].lhs
    else
        throw eskk#internal_error(
        \   ['eskk', 'buftable'],
        \   "Unknown map type: " . a:type
        \)
    endif
endfunction "}}}
function! eskk#map#get_special_map(type) "{{{
    let eskk_mappings = eskk#_get_eskk_mappings()
    if has_key(eskk_mappings, a:type)
        let map = printf('<Plug>(eskk:_noremap_%s)', a:type)
        if maparg(map, eskk#map#get_map_modes()) == ''
            " Not to remap.
            call eskk#map#map('', map, eskk_mappings[a:type].lhs)
        endif
        return map
    else
        throw eskk#internal_error(
        \   ['eskk', 'buftable'],
        \   "Unknown map type: " . a:type
        \)
    endif
endfunction "}}}
function! eskk#map#handle_special_lhs(char, type, stash) "{{{
    let eskk_mappings = eskk#_get_eskk_mappings()
    return
    \   eskk#map#is_special_lhs(a:char, a:type)
    \   && has_key(eskk_mappings, a:type)
    \   && call(eskk_mappings[a:type].fn, [a:stash])
endfunction "}}}
function! s:create_map(self, type, options, lhs, rhs, from) "{{{
    let self = a:self
    let lhs = a:lhs
    let rhs = a:rhs

    let eskk_mappings = eskk#_get_eskk_mappings()
    if !has_key(eskk_mappings, a:type)
        call eskk#util#warn(
        \   a:from . ": unknown type '" . a:type . "'."
        \)
        return
    endif
    let type_st = eskk_mappings[a:type]

    if a:type ==# 'general'
        if lhs == ''
            call eskk#util#warn("lhs must not be empty string.")
            return
        endif
        if has_key(type_st, lhs) && a:options.unique
            call eskk#util#warn(
            \   a:from . ": Already mapped to '" . lhs . "'."
            \)
            return
        endif
        let type_st[lhs] = {
        \   'options': a:options,
        \   'rhs': rhs
        \}
    else
        if a:options.unique && has_key(type_st, 'lhs')
            call eskk#util#warn(
            \   a:type . ': -unique is specified'
            \       . ' and mapping already exists. skip.'
            \)
            return
        endif
        let type_st.options = a:options
        let type_st.lhs = lhs
    endif
endfunction "}}}


" :EskkMap - Ex command for s:create_map()
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
        let regexp_string = '^\(''\).\{-}[^''\\]\1'
        let regexp_bare_word = '^\("\).\{-}[^\\]\1'
        let pat = (arg =~# "^'" ? regexp_string : regexp_bare_word)
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
        throw eskk#map#cmd_eskk_map_invalid_args(
        \   "':EskkMap' argument's key must be word."
        \)
    endif

    if a =~# '^'.OPT_CHARS.'\+='    " key has a value.
        let r = '^\('.OPT_CHARS.'\+\)='.'\C'
        let [m, optname; _] = matchlist(a, r)
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

    while args != ''
        let [optname, value, args] = s:parse_options_get_optargs(args)
        if optname ==# '--'
            break
        endif
        if optname ==# 'type'
            let type = value
        elseif has_key(opt, optname)
            let opt[optname] = value
        elseif optname ==# 'remap'
            let opt.noremap = 0
        else
            throw eskk#map#cmd_eskk_map_invalid_args(
            \   printf("unknown option '%s'.", optname)
            \)
        endif
    endwhile

    return [opt, type, args]
endfunction "}}}
function! eskk#map#cmd_eskk_map_invalid_args(...) "{{{
    return eskk#error#build_error(
    \   ['eskk', 'mappings'],
    \   [':EskkMap argument parse error'] + a:000
    \)
endfunction "}}}
function! eskk#map#_cmd_eskk_map(args) "{{{
    let [options, type, args] = s:parse_options(a:args)

    " Get lhs.
    let args = s:skip_white(args)
    let [lhs, args] = s:parse_one_arg_from_q_args(args)
    " Get rhs.
    let rhs = s:skip_white(args)

    call s:create_map(
    \   eskk#get_current_instance(),
    \   type,
    \   options,
    \   lhs,
    \   rhs,
    \   'EskkMap'
    \)
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

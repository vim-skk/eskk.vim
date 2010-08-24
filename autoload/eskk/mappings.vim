" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if exists('s:loaded') && s:loaded
    finish
endif
let s:loaded = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" `eskk#mappings#map_all_keys()` and `eskk#mappings#unmap_all_keys()` toggle this value.
let s:has_mapped = {}
" Database for misc. keys.
let s:map = {
\   'general': {},
\   'sticky': {},
\   'backspace-key': {},
\   'escape-key': {},
\   'enter-key': {},
\   'undo-key': {},
\   'tab': {},
\   'phase:henkan:henkan-key': {},
\   'phase:okuri:henkan-key': {},
\   'phase:henkan-select:choose-next': {},
\   'phase:henkan-select:choose-prev': {},
\   'phase:henkan-select:next-page': {},
\   'phase:henkan-select:prev-page': {},
\   'phase:henkan-select:escape': {},
\   'phase:henkan-select:delete-from-dict': {},
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
function! s:handle_toggle_hankata(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'hankata' ? 'hira' : 'hankata')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_toggle_kata(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
        call eskk#set_mode(eskk#get_mode() ==# 'kata' ? 'hira' : 'kata')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_ctrl_q_key(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \   || a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        call a:stash.buftable.do_ctrl_q_key()
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_q_key(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \   || a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        call a:stash.buftable.do_q_key()
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_ascii(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && a:stash.buf_str.get_rom_str() == ''
        call eskk#set_mode('ascii')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_zenei(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && a:stash.buf_str.get_rom_str() == ''
        call eskk#set_mode('zenei')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_abbrev(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && a:stash.buf_str.get_rom_str() == ''
        call eskk#set_mode('abbrev')
        return 1
    endif
    return 0
endfunction "}}}
let s:map_fn = {
\   'mode:hira:toggle-hankata': 's:handle_toggle_hankata',
\   'mode:hira:ctrl-q-key': 's:handle_ctrl_q_key',
\   'mode:hira:toggle-kata': 's:handle_toggle_kata',
\   'mode:hira:q-key': 's:handle_q_key',
\   'mode:hira:to-ascii': 's:handle_to_ascii',
\   'mode:hira:to-zenei': 's:handle_to_zenei',
\   'mode:hira:to-abbrev': 's:handle_to_abbrev',
\
\   'mode:kata:toggle-hankata': 's:handle_toggle_hankata',
\   'mode:kata:ctrl-q-key': 's:handle_ctrl_q_key',
\   'mode:kata:toggle-kata': 's:handle_toggle_kata',
\   'mode:kata:q-key': 's:handle_q_key',
\   'mode:kata:to-ascii': 's:handle_to_ascii',
\   'mode:kata:to-zenei': 's:handle_to_zenei',
\   'mode:kata:to-abbrev': 's:handle_to_abbrev',
\
\   'mode:hankata:toggle-hankata': 's:handle_toggle_hankata',
\   'mode:hankata:ctrl-q-key': 's:handle_ctrl_q_key',
\   'mode:hankata:toggle-kata': 's:handle_toggle_kata',
\   'mode:hankata:q-key': 's:handle_q_key',
\   'mode:hankata:to-ascii': 's:handle_to_ascii',
\   'mode:hankata:to-zenei': 's:handle_to_zenei',
\   'mode:hankata:to-abbrev': 's:handle_to_abbrev',
\
\
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


" Utilities
function! eskk#mappings#create_default_mapopt() "{{{
    return {
    \   'buffer': 0,
    \   'expr': 0,
    \   'silent': 0,
    \   'unique': 0,
    \   'remap': 0,
    \   'map-if': '1',
    \}
endfunction "}}}
function! eskk#mappings#mapopt_chars2dict(options) "{{{
    let table = {
    \   'b': 'buffer',
    \   'e': 'expr',
    \   's': 'silent',
    \   'u': 'unique',
    \   'r': 'remap',
    \}
    let opt = eskk#mappings#create_default_mapopt()
    for c in split(a:options, '\zs')
        let opt[table[c]] = 1
    endfor
    return opt
endfunction "}}}
function! eskk#mappings#mapopt_dict2raw(options) "{{{
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
function! eskk#mappings#mapopt_dict2chars(options) "{{{
    let table = {
    \   'buffer': 'b',
    \   'expr': 'e',
    \   'silent': 's',
    \   'unique': 'u',
    \   'remap': 'r',
    \}
    return join(map(keys(a:options), 'a:options[v:val] && has_key(table, v:val) ? table[v:val] : ""'), '')
endfunction "}}}
function! eskk#mappings#mapopt_chars2raw(options) "{{{
    let table = {
    \   'b': '<buffer>',
    \   'e': '<expr>',
    \   's': '<silent>',
    \   'u': '<unique>',
    \}
    return join(map(split(a:options, '\zs'), 'get(table, v:val, "")'), '')
endfunction "}}}

function! eskk#mappings#get_map_modes() "{{{
    " XXX: :lmap can't remap to :lmap. It's Vim's bug.
    "   http://groups.google.com/group/vim_dev/browse_thread/thread/17a1273eb82d682d/
    " So I use :map! mappings for 'fallback' of :lmap.

    return 'ic'
endfunction "}}}
function! eskk#mappings#get_filter_map(key) "{{{
    " NOTE:
    " a:key is escaped. So when a:key is '<C-a>', return value is
    "   `<Plug>(eskk:filter:<C-a>)`
    " not
    "   `<Plug>(eskk:filter:^A)` (^A is control character)

    let lhs = printf('<Plug>(eskk:filter:%s)', a:key)
    if maparg(lhs, eskk#mappings#get_map_modes()) != ''
        return lhs
    endif

    call eskk#mappings#map('re', lhs, printf('eskk#filter(%s)', string(a:key)))

    return lhs
endfunction "}}}
function! eskk#mappings#get_nore_map(key, ...) "{{{
    " NOTE:
    " a:key is escaped. So when a:key is '<C-a>', return value is
    "   `<Plug>(eskk:filter:<C-a>)`
    " not
    "   `<Plug>(eskk:filter:^A)` (^A is control character)

    let [rhs, key] = [a:key, a:key]
    let key = eskk#util#str2map(key)

    let lhs = printf('<Plug>(eskk:noremap:%s)', key)
    if maparg(lhs, 'icl') != ''
        return lhs
    endif

    call eskk#mappings#map((a:0 ? substitute(a:1, 'r', '', 'g') : ''), lhs, rhs)

    return lhs
endfunction "}}}
function! eskk#mappings#do_remap(map, modes) "{{{
    let m = maparg(a:map, a:modes)
    return m != '' ? m : a:map
endfunction "}}}

function! eskk#mappings#map(options, lhs, rhs, ...) "{{{
    if a:lhs == '' || a:rhs == ''
        call eskk#util#logstrf_warn('lhs or rhs is empty: lhs = %s, rhs = %s', a:lhs, a:rhs)
        return
    endif

    let map = stridx(a:options, 'r') != -1 ? 'map' : 'noremap'
    let opt = eskk#mappings#mapopt_chars2raw(a:options)
    for mode in split((a:0 ? a:1 : eskk#mappings#get_map_modes()), '\zs')
        let mapcmd = join([mode . map, opt, a:lhs, a:rhs])
        try
            execute mapcmd
        catch
            call eskk#util#log_exception(mapcmd)
        endtry
    endfor
endfunction "}}}
function! eskk#mappings#unmap(modes, options, lhs) "{{{
    if a:lhs == ''
        call eskk#util#logstrf_warn('lhs is empty: lhs = %s', a:lhs)
        return
    endif

    let opt = eskk#mappings#mapopt_chars2raw(a:options)
    for mode in split(a:modes, '\zs')
        let mapcmd = join([mode . 'unmap', opt, a:lhs])
        try
            execute mapcmd
        catch
            call eskk#util#log_exception(mapcmd)
        endtry
    endfor
endfunction "}}}

function! eskk#mappings#set_up_key(key, ...) "{{{
    call eskk#mappings#map(
    \   'rb' . (a:0 ? a:1 : ''),
    \   a:key,
    \   eskk#mappings#get_filter_map(a:key),
    \   'l'
    \)
endfunction "}}}
function! eskk#mappings#set_up_temp_key(lhs, ...) "{{{
    " Assumption: a:lhs must be '<Bar>' not '|'.

    " Save current a:lhs mapping.
    let save_lhs = s:temp_key_map(a:lhs)
    let save_rhs = maparg(a:lhs, 'l')
    if save_rhs != '' && maparg(save_lhs) == ''
        " TODO Check if a:lhs is buffer local.
        call eskk#util#log('Save temp key: ' . maparg(a:lhs, 'l'))
        call eskk#mappings#map('rb', save_lhs, save_rhs, 'l')
    endif

    if a:0
        call eskk#mappings#map('rb', a:lhs, a:1, 'l')
    else
        call eskk#mappings#set_up_key(a:lhs)
    endif
endfunction "}}}
function! eskk#mappings#set_up_temp_key_restore(lhs) "{{{
    let temp_key = s:temp_key_map(a:lhs)
    let saved_rhs = maparg(temp_key, 'l')

    if saved_rhs != ''
        call eskk#util#log('Restore saved temp key: ' . saved_rhs)
        call eskk#mappings#unmap('l', 'b', temp_key)
        call eskk#mappings#map('rb', a:lhs, saved_rhs, 'l')
    else
        call eskk#util#logf_warn("called eskk#mappings#set_up_temp_key_restore() but no '%s' key is stashed.", a:lhs)
        call eskk#mappings#set_up_key(a:lhs)
    endif
endfunction "}}}
function! eskk#mappings#has_temp_key(lhs) "{{{
    let temp_key = s:temp_key_map(a:lhs)
    let saved_rhs = maparg(temp_key, 'l')
    return saved_rhs != ''
endfunction "}}}
function! s:temp_key_map(key) "{{{
    return printf('<Plug>(eskk:prevmap:%s)', a:key)
endfunction "}}}

    function! eskk#mappings#map_mode_local_keys() "{{{
        let mode = eskk#get_mode()

        if has_key(s:mode_local_keys, mode)
            for key in s:mode_local_keys[mode]
                let real_key = eskk#mappings#get_special_key(key)
                call eskk#mappings#set_up_temp_key(real_key)
                call eskk#register_temp_event('leave-mode-' . mode, 'eskk#mappings#set_up_temp_key_restore', [real_key])
            endfor
        endif
    endfunction "}}}


" Functions using s:map
function! eskk#mappings#map_all_keys(...) "{{{
    if has_key(s:has_mapped, bufnr('%'))
        return
    endif


    lmapclear <buffer>

    " Map mapped keys.
    for key in g:eskk_mapped_keys
        call call('eskk#mappings#set_up_key', [key] + a:000)
    endfor

    " Map `:EskkMap -general` keys.
    for [key, opt] in items(s:map.general)
        if !eval(opt.options['map-if'])
            continue
        endif
        if opt.rhs == ''
            call eskk#mappings#set_up_key(key, eskk#mappings#mapopt_dict2chars(opt.options))
        else
            call eskk#mappings#map(
            \   'b'
            \       . (opt.options.remap ? 'r' : '')
            \       . eskk#mappings#mapopt_dict2chars(opt.options),
            \   key,
            \   opt.rhs,
            \   'l'
            \)
        endif
    endfor

    call eskk#util#assert(!has_key(s:has_mapped, bufnr('%')))
    let s:has_mapped[bufnr('%')] = 1
endfunction "}}}
function! eskk#mappings#unmap_all_keys() "{{{
    if !has_key(s:has_mapped, bufnr('%'))
        return
    endif

    for key in g:eskk_mapped_keys
        call eskk#mappings#unmap('l', 'b', key)
    endfor

    unlet s:has_mapped[bufnr('%')]
endfunction "}}}

function! eskk#mappings#is_special_lhs(char, type) "{{{
    " NOTE: This function must not show error when `s:map[a:type]` does not exist.
    return has_key(s:map, a:type)
    \   && eskk#util#key2char(s:map[a:type].lhs) ==# a:char
endfunction "}}}
function! eskk#mappings#get_special_key(type) "{{{
    if has_key(s:map, a:type)
        return s:map[a:type].lhs
    else
        throw eskk#internal_error(['eskk'], "Unknown map type: " . a:type)
    endif
endfunction "}}}
function! eskk#mappings#get_special_map(type) "{{{
    if has_key(s:map, a:type)
        let map = printf('<Plug>(eskk:internal:_noremap_%s)', a:type)
        if maparg(map, eskk#mappings#get_map_modes()) == ''
            " Not to remap.
            call eskk#mappings#map('', map, s:map[a:type].lhs)
        endif
        return map
    else
        throw eskk#internal_error(['eskk'], "Unknown map type: " . a:type)
    endif
endfunction "}}}
function! eskk#mappings#handle_special_lhs(char, type, stash) "{{{
    return
    \   eskk#mappings#is_special_lhs(a:char, a:type)
    \   && has_key(s:map_fn, a:type)
    \   && call(s:map_fn[a:type], [a:stash])
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
    let opt = eskk#mappings#create_default_mapopt()
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
function! eskk#mappings#_cmd_eskk_map(args) "{{{
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


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

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
function! s:handle_l_key(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_HENKAN
    \   || a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_OKURI
        call a:stash.buftable.do_l_key()
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_ascii(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && a:stash.buf_str.rom_str.get() == ''
        call eskk#set_mode('ascii')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_zenei(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && a:stash.buf_str.rom_str.get() == ''
        call eskk#set_mode('zenei')
        return 1
    endif
    return 0
endfunction "}}}
function! s:handle_to_abbrev(stash) "{{{
    if a:stash.phase ==# g:eskk#buftable#HENKAN_PHASE_NORMAL
    \   && a:stash.buf_str.rom_str.get() == ''
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

" FIXME: Make a class for these functions.
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
function! eskk#mappings#mapopt_chars2dict(options) "{{{
    let table = {
    \   'b': 'buffer',
    \   'e': 'expr',
    \   's': 'silent',
    \   'u': 'unique',
    \   'r': 'remap',
    \}
    let opt = s:create_default_mapopt()
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
    return join(
    \   map(
    \       keys(a:options),
    \       'a:options[v:val]'
    \           . ' && has_key(table, v:val) ? table[v:val] : ""'
    \   ),
    \   ''
    \)
endfunction "}}}
function! eskk#mappings#mapopt_chars2raw(options) "{{{
    let table = {
    \   'b': '<buffer>',
    \   'e': '<expr>',
    \   's': '<silent>',
    \   'u': '<unique>',
    \}
    return join(
    \   map(
    \       split(a:options, '\zs'),
    \       'get(table, v:val, "")'
    \   ),
    \   ''
    \)
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

    call eskk#mappings#map('re', lhs, 'eskk#filter(' . string(a:key) . ')')

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

    let options = a:0 ? substitute(a:1, 'r', '', 'g') : ''
    call eskk#mappings#map(options, lhs, rhs)

    return lhs
endfunction "}}}

function! eskk#mappings#map(options, lhs, rhs, ...) "{{{
    if a:lhs == '' || a:rhs == ''
        call eskk#error#logstrf(
        \   'lhs or rhs is empty: lhs = %s, rhs = %s',
        \   a:lhs,
        \   a:rhs
        \)
        return
    endif

    let map = stridx(a:options, 'r') != -1 ? 'map' : 'noremap'
    let opt = eskk#mappings#mapopt_chars2raw(a:options)
    let modes = a:0 ? a:1 : eskk#mappings#get_map_modes()
    for mode in split(modes, '\zs')
        let mapcmd = join([mode . map, opt, a:lhs, a:rhs])
        try
            execute mapcmd
        catch
            call eskk#error#log_exception(mapcmd)
        endtry
    endfor
endfunction "}}}
function! eskk#mappings#unmap(options, lhs, modes) "{{{
    if a:lhs == ''
        call eskk#error#logstrf('lhs is empty: lhs = %s', a:lhs)
        return
    endif

    let opt = eskk#mappings#mapopt_chars2raw(a:options)
    for mode in split(a:modes, '\zs')
        let mapcmd = join([mode . 'unmap', opt, a:lhs])
        try
            execute mapcmd
        catch
            call eskk#error#log_exception(mapcmd)
        endtry
    endfor
endfunction "}}}
function! eskk#mappings#map_from_maparg_dict(dict) "{{{
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
    return eskk#mappings#map(options, lhs, rhs, modes)
endfunction "}}}
function! eskk#mappings#map_exists(mode, ...) "{{{
    let [options, lhs] = [get(a:000, 0, ''), get(a:000, 1, '')]
    let options = eskk#mappings#mapopt_chars2raw(options)
    let excmd = join([a:mode . 'map', options] + (lhs != '' ? [lhs] : []))
    let out = eskk#util#redir_english(excmd)
    return eskk#util#list_has(split(out, '\n'), 'No mapping found')
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
        call eskk#mappings#unmap('b', temp_key, 'l')
        call eskk#mappings#map('rb', a:lhs, saved_rhs, 'l')
    else
        call eskk#error#logf(
        \   "called eskk#mappings#set_up_temp_key_restore()"
        \       . " but no '%s' key is stashed.",
        \   a:lhs
        \)
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

    if has_key(s:MODE_LOCAL_KEYS, mode)
        for key in s:MODE_LOCAL_KEYS[mode]
            let real_key = eskk#mappings#get_special_key(key)
            call eskk#mappings#set_up_temp_key(real_key)
            call eskk#register_temp_event(
            \   'leave-mode-' . mode,
            \   'eskk#mappings#set_up_temp_key_restore',
            \   [real_key]
            \)
        endfor
    endif
endfunction "}}}


" g:eskk#keep_state
function! eskk#mappings#save_state() "{{{
    let inst = eskk#get_current_instance()
    let inst.prev_normal_keys = s:save_normal_keys()

    call s:unmap_normal_keys()

    " Restore previous im options.
    let nr = bufnr('%')
    let prev_im_options = eskk#get_current_instance().prev_im_options
    if has_key(prev_im_options, nr)
        let [&l:iminsert, &l:imsearch] = prev_im_options[nr]
        unlet prev_im_options[nr]
    endif
endfunction "}}}
function! eskk#mappings#restore_state() "{{{
    let inst = eskk#get_current_instance()
    if empty(inst.prev_normal_keys)
        return
    endif
    call s:restore_normal_keys(inst.prev_normal_keys)
    let inst.prev_normal_keys = {}

    call s:map_normal_keys()

    " Save im options.
    let prev_im_options = eskk#get_current_instance().prev_im_options
    let prev_im_options[bufnr('%')] = [&l:iminsert, &l:imsearch]
    let [&l:iminsert, &l:imsearch] = [0, 0]
endfunction "}}}
function! s:get_normal_keys() "{{{
    return split('iIaAoOcCsSR', '\zs')
endfunction "}}}
function! s:map_normal_keys() "{{{
    " From s:SkkMapNormal() in plugin/skk.vim

    let restore_commands =
    \   ':<C-u>'
    \   . 'let [&l:iminsert, &l:imsearch] = '
    \       . string([&l:iminsert, &l:imsearch])
    \   . '<CR>'
    for key in s:get_normal_keys()
        call eskk#mappings#map('sb', key, restore_commands . key, 'n')
    endfor
endfunction "}}}
function! s:unmap_normal_keys() "{{{
    for key in s:get_normal_keys()
        if eskk#mappings#map_exists('n', 'b', key)
            call eskk#mappings#unmap('b', key, 'n')
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


" Functions using s:eskk_mappings
function! eskk#mappings#map_all_keys(...) "{{{
    let mapped_bufnr = eskk#_get_mapped_bufnr()
    if has_key(mapped_bufnr, bufnr('%'))
        return
    endif


    lmapclear <buffer>

    " Map mapped keys.
    for key in g:eskk#mapped_keys
        call call('eskk#mappings#set_up_key', [key] + a:000)
    endfor

    " Map `:EskkMap -general` keys.
    let eskk_mappings = eskk#_get_eskk_mappings()
    for [key, opt] in items(eskk_mappings.general)
        if !eval(opt.options['map-if'])
            continue
        endif
        if opt.rhs == ''
            call eskk#mappings#set_up_key(
            \   key,
            \   eskk#mappings#mapopt_dict2chars(opt.options)
            \)
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

    call eskk#error#assert(!has_key(mapped_bufnr, bufnr('%')))
    let mapped_bufnr[bufnr('%')] = 1
endfunction "}}}
function! eskk#mappings#unmap_all_keys() "{{{
    let mapped_bufnr = eskk#_get_mapped_bufnr()
    if !has_key(mapped_bufnr, bufnr('%'))
        return
    endif

    for key in g:eskk#mapped_keys
        call eskk#mappings#unmap('b', key, 'l')
    endfor

    unlet mapped_bufnr[bufnr('%')]
endfunction "}}}
function! eskk#mappings#is_special_lhs(char, type) "{{{
    " NOTE: This function must not show error
    " when `eskk_mappings[a:type]` does not exist.
    let eskk_mappings = eskk#_get_eskk_mappings()
    return has_key(eskk_mappings, a:type)
    \   && eskk#util#key2char(eskk_mappings[a:type].lhs) ==# a:char
endfunction "}}}
function! eskk#mappings#get_special_key(type) "{{{
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
function! eskk#mappings#get_special_map(type) "{{{
    let eskk_mappings = eskk#_get_eskk_mappings()
    if has_key(eskk_mappings, a:type)
        let map = printf('<Plug>(eskk:_noremap_%s)', a:type)
        if maparg(map, eskk#mappings#get_map_modes()) == ''
            " Not to remap.
            call eskk#mappings#map('', map, eskk_mappings[a:type].lhs)
        endif
        return map
    else
        throw eskk#internal_error(
        \   ['eskk', 'buftable'],
        \   "Unknown map type: " . a:type
        \)
    endif
endfunction "}}}
function! eskk#mappings#handle_special_lhs(char, type, stash) "{{{
    let eskk_mappings = eskk#_get_eskk_mappings()
    return
    \   eskk#mappings#is_special_lhs(a:char, a:type)
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
        throw eskk#mappings#cmd_eskk_map_invalid_args(
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
        else
            throw eskk#mappings#cmd_eskk_map_invalid_args(
            \   printf("unknown option '%s'.", optname)
            \)
        endif
    endwhile

    return [opt, type, args]
endfunction "}}}
function! eskk#mappings#cmd_eskk_map_invalid_args(...) "{{{
    return eskk#error#build_error(
    \   ['eskk', 'mappings'],
    \   [':EskkMap argument parse error'] + a:000
    \)
endfunction "}}}
function! eskk#mappings#_cmd_eskk_map(args) "{{{
    let [options, type, args] = s:parse_options(a:args)

    let args = s:skip_white(args)
    let [lhs, args] = s:parse_one_arg_from_q_args(args)

    let args = s:skip_white(args)
    if args == ''
        call s:create_map(
        \   eskk#get_current_instance(),
        \   type,
        \   options,
        \   lhs,
        \   '',
        \   'EskkMap'
        \)
        return
    endif

    call s:create_map(
    \   eskk#get_current_instance(),
    \   type,
    \   options,
    \   lhs,
    \   args,
    \   'EskkMap'
    \)
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

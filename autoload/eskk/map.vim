" vim:foldmethod=marker:fen:sw=4
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:SID() abort "{{{
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID


let s:prev_normal_keys = {}


" Utilities

function! eskk#map#get_map_modes() abort "{{{
  return 'l'
endfunction "}}}
function! s:get_map_rhs(key) abort "{{{
  return 'eskk#filter(eskk#util#key2char('.string(a:key).'))'
endfunction "}}}
function! eskk#map#map(options, lhs, rhs, ...) abort "{{{
  if a:lhs ==# '' || a:rhs ==# ''
    call eskk#logger#warnf(
          \   'lhs or rhs is empty: lhs = %s, rhs = %s',
          \   string(a:lhs),
          \   string(a:rhs)
          \)
    return
  endif

  let dict = eskk#util#mapopt_chars2dict(a:options)
  let modes = a:0 ? a:1 : eskk#map#get_map_modes()
  for mode in split(modes, '\zs')
    if !eskk#util#is_mode_char(mode)
      continue
    endif
    let mapcmd = eskk#util#get_map_command(mode, dict, a:lhs, a:rhs)
    if dict.unique
      let mapcmd = 'silent! '.mapcmd
    endif
    try
      execute mapcmd
    catch
      call eskk#logger#log_exception(mapcmd)
    endtry
  endfor
endfunction "}}}
function! eskk#map#set_up_key(key, ...) abort "{{{
  call eskk#map#map(
        \   'be' . (a:0 ? a:1 : ''),
        \   a:key,
        \   s:get_map_rhs(a:key),
        \   eskk#map#get_map_modes()
        \)
endfunction "}}}
function! eskk#map#unmap(options, lhs, modes) abort "{{{
  if a:lhs ==# ''
    call eskk#logger#warnf(
          \   'lhs is empty: lhs = %s',
          \   string(a:lhs),
          \)
    return
  endif

  let dict = eskk#util#mapopt_chars2dict(a:options)
  for mode in split(a:modes, '\zs')
    if !eskk#util#is_mode_char(mode)
      continue
    endif
    let mapcmd = eskk#util#get_unmap_command(mode, dict, a:lhs)
    echomsg string(mapcmd)
    try
      execute mapcmd
    catch
      call eskk#logger#log_exception(mapcmd)
    endtry
  endfor
endfunction "}}}
function! eskk#map#map_from_maparg_dict(dict) abort "{{{
  if type(a:dict) !=# type({}) || empty(a:dict)
    " The mapping does not exist.
    return
  endif

  return eskk#map#map(
        \   eskk#util#mapopt_dict2chars(a:dict),
        \   a:dict.lhs, a:dict.rhs, a:dict.mode
        \)
endfunction "}}}


" g:eskk#keep_state, g:eskk#keep_state_beyond_buffer
function! eskk#map#save_normal_keys() abort "{{{
  let s:prev_normal_keys = s:save_normal_keys()
  call s:unmap_normal_keys()
endfunction "}}}
function! eskk#map#restore_normal_keys() abort "{{{
  call s:restore_normal_keys(s:prev_normal_keys)
  let s:prev_normal_keys = {}
  " call s:map_normal_keys()
endfunction "}}}
function! s:get_normal_keys() abort "{{{
  return split('iIaAoOcCsSR', '\zs')
endfunction "}}}
function! s:map_normal_keys() abort "{{{
  " From s:SkkMapNormal() in plugin/skk.vim

  let calling_hook_fn =
        \   eskk#util#get_local_func('do_normal_key', s:SID_PREFIX)
        \   . '(%s,' . &l:iminsert . ',' . &l:imsearch . ')'
  for key in s:get_normal_keys()
    call eskk#map#map('seb', key, printf(calling_hook_fn, string(key)), 'n')
  endfor
endfunction "}}}
function! s:do_normal_key(key, iminsert, imsearch) abort "{{{
  let &l:iminsert = a:iminsert
  let &l:imsearch = a:imsearch
  return a:key
endfunction "}}}
function! s:unmap_normal_keys() abort "{{{
  for key in s:get_normal_keys()
    " Exists <buffer> mapping.
    if get(maparg(key, 'n', 0, 1), 'buffer')
      call eskk#map#unmap('b', key, 'n')
    endif
  endfor
endfunction "}}}
function! s:save_normal_keys() abort "{{{
  if !savemap#supported_version()
    return {}
  endif

  let keys = {'info': {}}
  for key in s:get_normal_keys()
    let keys.info[key] = savemap#save_map('n', key)
  endfor
  function! keys.restore() abort
    for map in values(self.info)
      if has_key(map, 'restore')
        call map.restore()
      endif
    endfor
  endfunction
  return keys
endfunction "}}}
function! s:restore_normal_keys(keys) abort "{{{
  if has_key(a:keys, 'restore')
    call a:keys.restore()
  endif
endfunction "}}}


" Functions using s:eskk_mappings
function! eskk#map#map_all_keys() abort "{{{
  let inst = eskk#get_buffer_instance()
  if has_key(inst, 'prev_lang_keys')
    return
  endif
  let inst.prev_lang_keys = savemap#save_map('l')

  " Map mapped keys.
  for key in g:eskk#mapped_keys
    let rhs = maparg(key, eskk#map#get_map_modes())
    if stridx(rhs, '<Plug>(eskk:disable)') isnot -1
      " execute 'EskkMap -type=disable' key
      call s:create_map(
            \   'disable',
            \   s:create_default_mapopt(),
            \   key,
            \   '',
            \)
    elseif stridx(rhs, '<Plug>(eskk:enable)') isnot -1
      " execute 'EskkMap -type=enable' key
      call s:create_map(
            \   'enable',
            \   s:create_default_mapopt(),
            \   key,
            \   '',
            \)
    elseif stridx(rhs, '<Plug>(eskk:toggle)') isnot -1
      " execute 'EskkMap -type=toggle' key
      call s:create_map(
            \   'toggle',
            \   s:create_default_mapopt(),
            \   key,
            \   '',
            \)
    endif
    " Overwrite 'key'.
    call eskk#map#set_up_key(key)
  endfor

  " Map `:EskkMap -general` keys.
  let general_mappings = eskk#_get_eskk_general_mappings()
  for [key, opt] in items(general_mappings)
    if !eval(opt.options['map-if'])
      continue
    endif
    if opt.rhs ==# ''
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
endfunction "}}}
function! eskk#map#unmap_all_keys() abort "{{{
  let inst = eskk#get_buffer_instance()
  if !has_key(inst, 'prev_lang_keys')
    return
  endif

  lmapclear <buffer>
  lmapclear

  call inst.prev_lang_keys.restore()
  unlet inst.prev_lang_keys
endfunction "}}}
function! s:create_map(type, options, lhs, ...) abort "{{{
  let lhs = a:lhs

  let eskk_mappings = eskk#_get_eskk_mappings()
  if !has_key(eskk_mappings, a:type)
    call eskk#logger#warn(
          \   "EskkMap: unknown type '" . a:type . "'."
          \)
    return
  endif
  let type_st = eskk_mappings[a:type]

  if a:options.unique && has_key(type_st, 'lhs')
    call eskk#logger#warn(
          \   'EskkMap: ' . a:type . ': the mapping already exists.'
          \)
    return
  endif
  let type_st.options = a:options
  let type_st.lhs = lhs
endfunction "}}}
function! s:create_general_map(options, lhs, rhs) abort "{{{
  let lhs = a:lhs
  let rhs = a:rhs
  let type_st = eskk#_get_eskk_general_mappings()

  if lhs ==# ''
    call eskk#logger#warn('lhs must not be empty string.')
    return
  endif
  if has_key(type_st, lhs) && a:options.unique
    call eskk#logger#warn(
          \   'EskkMap: ' . lhs . ': the mapping already exists.'
          \)
    return
  endif
  let type_st[lhs] = {
        \   'options': a:options,
        \   'rhs': rhs
        \}
endfunction "}}}


" :EskkMap
function! s:skip_white(args) abort "{{{
  return substitute(a:args, '^\s*', '', '')
endfunction "}}}
function! s:parse_one_arg_from_q_args(args) abort "{{{
  let arg = s:skip_white(a:args)
  let head = matchstr(arg, '^.\{-}[^\\]\ze\([ \t]\|$\)')
  let rest = strpart(arg, strlen(head))
  return [head, rest]
endfunction "}}}
function! s:parse_string_from_q_args(args) abort "{{{
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
function! s:parse_options_get_optargs(args) abort "{{{
  let OPT_CHARS = '[A-Za-z0-9\-]'
  let a = s:skip_white(a:args)

  if a[0] !=# '-'
    return ['--', '', a]
  endif
  if a ==# '--'
    let rest = s:parse_one_arg_from_q_args(a)[1]
    return ['--', '', rest]
  endif
  let a = substitute(a, '^--\?', '', '')
  if a !~# '^'.OPT_CHARS.'\+'
    throw eskk#map#cmd_eskk_map_invalid_args(
          \   "':EskkMap' argument's key must be word."
          \)
  endif

  if a =~# '^'.OPT_CHARS.'\+='    " key has a value.
    let r = '^\('.OPT_CHARS.'\+\)='.'\C'
    let [m, optname] = matchlist(a, r)[0:1]
    let rest = strpart(a, strlen(m))
    let [value, rest] = s:parse_string_from_q_args(rest)
    return [optname, value, rest]
  else
    let m = matchstr(a, '^'.OPT_CHARS.'\+'.'\C')
    let rest = strpart(a, strlen(m))
    return [m, 1, rest]
  endif
endfunction "}}}
function! s:parse_options(args) abort "{{{
  let args = a:args
  let type = 'general'
  let opt = s:create_default_mapopt()

  while args !=# ''
    let [optname, value, args] = s:parse_options_get_optargs(args)
    if optname ==# '--'
      break
    endif
    if optname ==# 'type'
      let type = value
    elseif has_key(opt, optname)
      let opt[optname] = value
    elseif optname ==# 'force'
      let opt.unique = 0
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
let s:DEFAULT_MAPOPT = {
      \   'buffer': 0,
      \   'expr': 0,
      \   'silent': 0,
      \   'unique': 1,
      \   'noremap': 1,
      \   'map-if': '1',
      \}
if v:version >=# 703 && has('patch1264')
  let s:DEFAULT_MAPOPT['nowait'] = 1
endif
function! s:create_default_mapopt() abort "{{{
  return copy(s:DEFAULT_MAPOPT)
endfunction "}}}
function! eskk#map#cmd_eskk_map_invalid_args(...) abort "{{{
  return eskk#util#build_error(
        \   ['eskk', 'mappings'],
        \   [':EskkMap argument parse error'] + a:000
        \)
endfunction "}}}
function! eskk#map#_cmd_eskk_map(args) abort "{{{
  let [options, type, args] = s:parse_options(a:args)

  " Get lhs.
  let args = s:skip_white(args)
  let [lhs, args] = s:parse_one_arg_from_q_args(args)
  " Get rhs.
  let rhs = s:skip_white(args)

  if type ==# 'general'
    call s:create_general_map(
          \   options,
          \   lhs,
          \   rhs,
          \)
  else
    call s:create_map(
          \   type,
          \   options,
          \   lhs,
          \   rhs,
          \)
  endif
endfunction "}}}
function! eskk#map#_cmd_eskk_unmap(args) abort "{{{
  let [options, type, args] = s:parse_options(a:args)

  " Get lhs.
  let args = s:skip_white(args)
  let [lhs, args] = s:parse_one_arg_from_q_args(args)

  let eskk_mappings = type ==# 'general' ?
        \ eskk#_get_eskk_general_mappings() : eskk#_get_eskk_mappings()

  if !has_key(eskk_mappings, type)
    call eskk#logger#warn(
          \   "EskkMap: unknown type '" . type . "'."
          \)
    return
  endif
  let type_st = eskk_mappings[type]

  if !has_key(type_st, 'lhs')
    call eskk#logger#warn(
          \   'EskkMap: ' . type . ': the mapping not exists.'
          \)
    return
  endif

  let type_st.options = options
  call remove(type_st, 'lhs')
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

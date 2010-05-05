" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" TODO
" - Compile dictionary (s:dict._dict_info) to refer to result.

" Functions {{{

" Searching Functions {{{

function! s:search_next_candidate(dict, key_filter, okuri_rom, okuri_filter) "{{{
    for ph_dict in a:dict._dicts
        if ph_dict.sorted
            let result = s:search_binary(ph_dict.get_lines(), a:key_filter, a:okuri_rom)
        else
            let result = s:search_linear(ph_dict.get_lines(), a:key_filter, a:okuri_rom)
        endif
        if type(result) == type("")
            return result . a:okuri_filter
        endif
    endfor

    return -1
endfunction "}}}

function! s:search_binary(lines, key, okuri) "{{{
    " TODO
endfunction "}}}

function! s:search_linear(lines, key, okuri) "{{{
    let needle = a:key . (a:okuri != '' ? a:okuri[0] : '') . ' '
    for line in a:lines
        if stridx(line, needle) == 0
            call eskk#util#logf('found matched line - %s', string(line))

            try
                let candidates = s:parse_skk_dict_line(line, needle)
            catch /^eskk: dictionary - parse error/
                call eskk#util#log("Can't parse line...")
                return -1
            endtry
            return candidates[0].result
        endif
    endfor
    return -1
endfunction "}}}

function! s:parse_skk_dict_line(line, needle) "{{{
    let line = a:line[strlen(a:needle) :]
    " Assert line =~# '^/.\+/$'
    let line = line[1:-2]

    let candidates = []
    for _ in split(line, '/')
        let semicolon = stridx(_, ';')
        if semicolon != -1
            call add(candidates, {'result': _[: semicolon - 1], 'annotation': _[semicolon + 1 :]})
        else
            call add(candidates, {'result': _, 'annotation': ''})
        endif
    endfor

    return candidates
endfunction "}}}

" }}}

" s:henkan_result {{{

" Interface for henkan result.
" This provides a method `get_next()`
" to get next candidate string.
"
" NOTE: '_okuri' is all rom str. not only one character.

let s:henkan_result = {
\   '_dict': {},
\   '_key': '',
\   '_okuri': '',
\   '_okuri_filter': '',
\}

function! s:henkan_result_new(dict, key, okuri, okuri_filter) "{{{
    return extend(
    \   deepcopy(s:henkan_result),
    \   {'_dict': a:dict, '_key': a:key, '_okuri': a:okuri, '_okuri_filter': a:okuri_filter},
    \   'force'
    \)
endfunction "}}}

function! s:henkan_result.get_next() dict "{{{
    return s:search_next_candidate(self._dict, self._key, self._okuri, self._okuri_filter)
endfunction "}}}


lockvar s:henkan_result
" }}}

" s:physical_dict {{{
"
" Database for physical file dictionary.
" `s:physical_dict` manipulates only one file.
" But `s:dict` may manipulate multiple dictionaries.
"
" `get_lines()` does
" - Lazy file read
" - Memoization for getting file content

let s:physical_dict = {
\   '_content_lines': [],
\   '_loaded': 0,
\   'path': '',
\   'sorted': 0,
\   'encoding': '',
\}

function! s:physical_dict_new(path, sorted, encoding) "{{{
    return extend(
    \   deepcopy(s:physical_dict),
    \   {'path': a:path, 'sorted': a:sorted, 'encoding': a:encoding},
    \   'force'
    \)
endfunction "}}}

function! s:physical_dict.get_lines() dict "{{{
    if self._loaded
        return self._content_lines
    endif

    let path = expand(self.path)
    if filereadable(path)
        let self._content_lines = map(readfile(path), 's:iconv(v:val, self.encoding, &l:encoding)')
    else
        call eskk#util#logf("Can't read '%s'!", path)
    endif
    let self._loaded = 1

    return self._content_lines
endfunction "}}}

function! s:iconv(expr, from, to) "{{{
    if a:from == '' || a:to == '' || a:from ==? a:to
        return a:expr
    endif
    let result = iconv(a:expr, a:from, a:to)
    return result != '' ? result : a:expr
endfunction "}}}

lockvar s:physical_dict
" }}}

" s:dict {{{
"
" Interface for multiple dictionary.
" This behave like one file dictionary.
" But it may have multiple dictionaries.
"
" See section `Searching Functions` for
" implementation of searching dictionaries.

let s:dict = {
\   '_dicts': [],
\}

function! eskk#dictionary#new(dict_info) "{{{
    if type(a:dict_info) == type([])
        let dicts = map(copy(a:dict_info), 's:physical_dict_new(v:val.path, v:val.sorted, v:val.encoding)')
    elseif type(a:dict_info) == type({})
        return eskk#dictionary#new([a:dict_info])
    else
        throw eskk#internal_error(['eskk', 'dictionary'], "eskk#dictionary#new(): invalid argument")
    endif

    return extend(
    \   deepcopy(s:dict),
    \   {'_dicts': dicts},
    \   'force'
    \)
endfunction "}}}

function! s:dict.refer(buftable) dict "{{{
    let buf_str = a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    return s:henkan_result_new(
    \   self,
    \   a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN).get_filter_str(),
    \   a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI).get_rom_str(),
    \   a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI).get_filter_str(),
    \)
endfunction "}}}

lockvar s:dict
" }}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

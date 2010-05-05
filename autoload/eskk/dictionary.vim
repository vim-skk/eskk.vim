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

function! s:search_next_candidate(dict, key, okuri) "{{{
    for ph_dict in a:dict._dicts
        if ph_dict.sorted
            let result = s:search_binary(ph_dict.get_lines(), a:key, a:okuri)
        else
            let result = s:search_linear(ph_dict.get_lines(), a:key, a:okuri)
        endif
        if type(result) == type("")
            return result
        endif
    endfor

    return 'henkan!'
endfunction "}}}

function! s:search_binary(lines, key, okuri) "{{{
    " TODO
endfunction "}}}

function! s:search_linear(lines, key, okuri) "{{{
    let needle = a:key . (a:okuri != '' ? a:okuri[0] : '')
    for line in a:lines
        if stridx(line, needle) == 0
            call eskk#util#logf('found matched line - %s', string(line))

            let found = line[strlen(needle) + 2 :]
            let semicolon = stridx(found, ';')
            let slash = stridx(found, '/')
            if semicolon != -1
                return found[: semicolon - 1]
            elseif slash != -1
                return found[: slash - 1]
            else
                throw eskk#parse_error(['eskk', 'dictionary'], printf("Can't parse %s!", string(line))
            endif
        endif
    endfor
    return -1
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
\}

function! s:henkan_result_new(dict, key, okuri) "{{{
    return extend(
    \   deepcopy(s:henkan_result),
    \   {'_dict': a:dict, '_key': a:key, '_okuri': a:okuri},
    \   'force'
    \)
endfunction "}}}

function! s:henkan_result.get_next() dict "{{{
    return s:search_next_candidate(self._dict, self._key, self._okuri)
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
\}

function! s:physical_dict_new(path, sorted) "{{{
    return extend(
    \   deepcopy(s:physical_dict),
    \   {'path': a:path, 'sorted': a:sorted},
    \   'force'
    \)
endfunction "}}}

function! s:physical_dict.get_lines() dict "{{{
    if self._loaded
        return self._content_lines
    endif

    let path = expand(self.path)
    if filereadable(path)
        let self._content_lines = readfile(path)
    else
        call eskk#util#logf("Can't read '%s'!", path)
    endif
    let self._loaded = 1

    return self._content_lines
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
        let dicts = map(copy(a:dict_info), 's:physical_dict_new(v:val.path, v:val.sorted)')
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
    return s:henkan_result_new(self, buf_str.get_filter_str(), buf_str.get_rom_str())
endfunction "}}}

lockvar s:dict
" }}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

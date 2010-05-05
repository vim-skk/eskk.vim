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

function! s:search_next_candidate(dict, key_filter, okuri_rom) "{{{
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '') . ' '
    for ph_dict in a:dict._dicts
        if ph_dict.sorted
            let result = s:search_binary(ph_dict, needle, has_okuri, 50)
        else
            let result = s:search_linear(ph_dict, needle, has_okuri)
        endif
        if type(result) == type("")
            return result
        endif
    endfor

    return -1
endfunction "}}}

function! s:search_binary(ph_dict, needle, has_okuri, limit) "{{{
    if a:has_okuri
        let min = a:ph_dict.okuri_ari_lnum + 1
        let max = a:ph_dict.okuri_nasi_lnum - 1
    else
        let min = a:ph_dict.okuri_nasi_lnum + 1
        let max = len(a:ph_dict.get_lines())
    endif
    while max - min > a:limit
        let mid = (min + max) / 2
        let line = a:ph_dict.get_lines()[mid]
        let line = s:iconv(line, a:ph_dict.encoding, &l:encoding)
        if a:needle >=# line
            if a:has_okuri
                let max = mid
            else
                let min = mid
            endif
        else
            if a:has_okuri
                let min = mid
            else
                let max = mid
            endif
        endif
    endwhile
    return s:search_linear(a:ph_dict, a:needle, a:has_okuri, min)
endfunction "}}}

function! s:search_linear(ph_dict, needle, has_okuri, ...) "{{{
    if a:0 != 0
        let pos = a:1
    elseif a:has_okuri
        let pos = a:ph_dict.okuri_ari_lnum
    else
        let pos = a:ph_dict.okuri_nasi_lnum
    endif
    while eskk#util#has_idx(a:ph_dict.get_lines(), pos)
        let line = a:ph_dict.get_lines()[pos]
        let line = s:iconv(line, a:ph_dict.encoding, &l:encoding)
        if stridx(line, a:needle) == 0
            call eskk#util#logf('found matched line - %s', string(line))
            return line[strlen(a:needle) :]
        endif
        let pos += 1
    endwhile
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
    let result = s:henkan_result_get_result(self)

    let [candidates, idx] = result
    try
        if eskk#util#has_idx(candidates, idx)
            return candidates[idx].result . self._okuri_filter
        else
            return -1
        endif
    finally
        let result[1] += 1
    endtry
endfunction "}}}

function! s:henkan_result_get_result(this) "{{{
    if has_key(a:this, '_result')
        return a:this._result
    endif

    let line = s:search_next_candidate(a:this._dict, a:this._key, a:this._okuri)
    if type(line) != type("")
        throw eskk#look_up_error(['eskk', 'dictionary'], "Couldn't look up candidate.")
    endif
    let a:this._result = [s:parse_skk_dict_line(line), 0]
    return a:this._result
endfunction "}}}

function! s:parse_skk_dict_line(line) "{{{
    " Assert line =~# '^/.\+/$'
    let line = a:line[1:-2]

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
\   'okuri_ari_lnum': 0,
\   'okuri_nasi_lnum': 0,
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
        let self._content_lines   = readfile(path, 'b')
        let self.okuri_ari_lnum  = index(self._content_lines, ';; okuri-ari entries.')
        let self.okuri_nasi_lnum = index(self._content_lines, ';; okuri-nasi entries.')
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

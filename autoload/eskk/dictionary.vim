" vim:foldmethod=marker:fen:
scriptencoding utf-8

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

" TODO
" - Compile dictionary (s:dict._dict_info) to refer to result.

" Functions {{{

" Searching Functions {{{

function! s:search_next_candidate(physical_dict, key_filter, okuri_rom) "{{{
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '') . ' '

    let converted = s:iconv(needle, &l:encoding, a:physical_dict.encoding)
    if a:physical_dict.sorted
        let result = s:search_binary(a:physical_dict, converted, has_okuri, 5)
    else
        let result = s:search_linear(a:physical_dict, converted, has_okuri)
    endif
    if type(result) == type("")
        return s:iconv(result, a:physical_dict.encoding, &l:encoding)
    else
        return -1
    endif
endfunction "}}}

function! s:search_binary(ph_dict, needle, has_okuri, limit) "{{{
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    call eskk#util#log('s:search_binary()')

    let whole_lines = a:ph_dict.get_lines()
    if a:has_okuri
        let min = a:ph_dict.okuri_ari_lnum + 1
        let max = a:ph_dict.okuri_nasi_lnum - 1
    else
        let min = a:ph_dict.okuri_nasi_lnum + 1
        let max = len(whole_lines)
    endif
    while max - min > a:limit
        let mid = (min + max) / 2
        let line = whole_lines[mid]
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
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    call eskk#util#log('s:search_linear()')

    if a:0 != 0
        let pos = a:1
    elseif a:has_okuri
        let pos = a:ph_dict.okuri_ari_lnum
    else
        let pos = a:ph_dict.okuri_nasi_lnum
    endif
    let whole_lines = a:ph_dict.get_lines()
    while eskk#util#has_idx(whole_lines, pos)
        let line = whole_lines[pos]
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
\   '_buftable': {},
\}

function! s:henkan_result_new(dict, key, okuri, okuri_filter, buftable) "{{{
    return extend(
    \   deepcopy(s:henkan_result),
    \   {
    \       '_dict': a:dict,
    \       '_key': a:key,
    \       '_okuri': a:okuri,
    \       '_okuri_filter': a:okuri_filter,
    \       '_buftable': a:buftable,
    \   },
    \   'force'
    \)
endfunction "}}}

function! s:henkan_result_advance(self, advance) "{{{
    try
        let result = s:henkan_result_get_result(a:self)
        if eskk#util#has_idx(result[0], result[1] + (a:advance ? 1 : -1))
            let result[1] += (a:advance ? 1 : -1)
            return 1
        else
            return 0
        endif
    catch /^eskk: dictionary - internal error/
        return -1
    endtry
endfunction "}}}

function! s:henkan_result_get_result(this) "{{{
    if has_key(a:this, '_result')
        return a:this._result
    endif

    let found = 0
    for dict in a:this._dict._physical_dicts
        let line = s:search_next_candidate(dict, a:this._key, a:this._okuri)
        if type(line) == type("")
            let found = 1
            break
        endif
    endfor
    if !found
        let msg = printf("Can't look up '%s%s%s%s' in dictionaries.",
        \                   g:eskk_marker_henkan, a:this._key, g:eskk_marker_okuri, a:this._okuri)
        throw eskk#internal_error(['eskk', 'dictionary'], msg)
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


function! s:henkan_result.get_candidate() dict "{{{
    try
        let [candidates, idx] = s:henkan_result_get_result(self)
        " Assert eskk#util#has_idx(candidates, idx)
        return candidates[idx].result . self._okuri_filter
    catch /^eskk: dictionary - internal error/
        return -1
    endtry
endfunction "}}}

function! s:henkan_result.advance() dict "{{{
    return s:henkan_result_advance(self, 1)
endfunction "}}}

function! s:henkan_result.back() dict "{{{
    return s:henkan_result_advance(self, 0)
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

function! s:physical_dict_new(path, sorted, encoding, is_user_dict) "{{{
    return extend(
    \   deepcopy(s:physical_dict),
    \   {'path': expand(a:path), 'sorted': a:sorted, 'encoding': a:encoding, 'is_user_dict': a:is_user_dict},
    \   'force'
    \)
endfunction "}}}

function! s:iconv(expr, from, to) "{{{
    if a:from == '' || a:to == '' || a:from ==? a:to
        return a:expr
    endif
    let result = iconv(a:expr, a:from, a:to)
    return result != '' ? result : a:expr
endfunction "}}}



function! s:physical_dict.get_lines() dict "{{{
    if self._loaded
        return self._content_lines
    endif

    let path = self.path
    if filereadable(path)
        call eskk#util#logf('reading %s...', path)
        let self._content_lines   = readfile(path)
        let self.okuri_ari_lnum  = index(self._content_lines, ';; okuri-ari entries.')
        let self.okuri_nasi_lnum = index(self._content_lines, ';; okuri-nasi entries.')
        call eskk#util#logf('reading %s... - done.', path)
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
\   '_physical_dicts': [],
\   '_user_dict': {},
\   '_added_words': [],
\}

function! eskk#dictionary#new(dict_info) "{{{
    if type(a:dict_info) == type([])
        let dicts = map(copy(a:dict_info), 's:physical_dict_new(v:val.path, v:val.sorted, v:val.encoding, get(v:val, "is_user_dict", 0))')
    elseif type(a:dict_info) == type({})
        return eskk#dictionary#new([a:dict_info])
    else
        throw eskk#internal_error(['eskk', 'dictionary'], "eskk#dictionary#new(): invalid argument")
    endif

    " Check if any dictionary has "is_user_dict" key.
    let user_dict = {}
    let found = 0
    for d in dicts
        if d.is_user_dict
            let user_dict = d
            let found = 1
            break
        endif
    endfor
    if !found
        throw eskk#internal_error(['eskk', 'dictionary'], "No 'is_user_dict' key in dictionaries.")
    endif

    return extend(
    \   deepcopy(s:dict),
    \   {'_physical_dicts': dicts, '_user_dict': user_dict},
    \   'force'
    \)
endfunction "}}}



function! s:dict.refer(buftable) dict "{{{
    return s:henkan_result_new(
    \   self,
    \   a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN).get_filter_str(),
    \   a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI).get_rom_str(),
    \   a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI).get_filter_str(),
    \   deepcopy(a:buftable, 1)
    \)
endfunction "}}}

function! s:dict.register_word(henkan_result) dict "{{{
    let buftable  = a:henkan_result._buftable
    let key       = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN).get_filter_str()
    let okuri     = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI).get_filter_str()
    let okuri_rom = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI).get_rom_str()

    let success = 0
    if inputsave() !=# success
        call eskk#util#log("warning: inputsave() failed")
    endif
    let prompt = printf('%s%s%s ', key, g:eskk_marker_okuri, okuri)
    let input  = input(prompt)
    if inputrestore() !=# success
        call eskk#util#log("warning: inputrestore() failed")
    endif

    call add(self._added_words, [input, key, okuri, okuri_rom])

    return input . okuri
endfunction "}}}

function! s:dict.is_modified() dict "{{{
    return !empty(self._added_words)
endfunction "}}}

function! s:dict.update_dictionary() dict "{{{
    if !self.is_modified()
        return
    endif

    let user_dict_lines = self._user_dict.get_lines()

    " Check if a:self.user_dict really does not have added words.
    for [input, key, okuri, okuri_rom] in self._added_words
        let line = s:search_next_candidate(self._user_dict, key, okuri_rom)
        if okuri_rom != ''
            let lnum = self._user_dict.okuri_ari_lnum + 1
        else
            let lnum = self._user_dict.okuri_nasi_lnum + 1
        endif
        call insert(
        \   user_dict_lines,
        \   s:create_new_entry(input, key, okuri, okuri_rom, (type(line) == type("") ? line : '')),
        \   lnum
        \)
    endfor


    " Write to dictionary.
    let save_msg = printf("Saving to '%s'...", self._user_dict.path)
    echo save_msg

    let ret_success = 0
    try
        if writefile(user_dict_lines, self._user_dict.path) ==# ret_success
            echo "\r" . save_msg . 'Done.'
        else
            throw printf("can't write to '%s'.", self._user_dict.path)
        endif
    catch
        echohl WarningMsg
        echo "\r" . save_msg . "Error. Please check permission of"
        \    "'" . self._user_dict.path . "' - " . v:exception
        echohl None
    endtry
endfunction "}}}



function! s:create_new_entry(new_word, key, okuri, okuri_rom, existing_line) "{{{
    " TODO:
    " Rewrite for eskk.
    " This function is from skk.vim's s:SkkMakeNewEntry().

    " Modify to make same input to original s:SkkMakeNewEntry().
    let key = a:key . (a:okuri_rom == '' ? '' : a:okuri_rom[0]) . ' '
    let cand = a:new_word
    let line = (a:existing_line == '' ? '' : substitute(a:existing_line, '^\S\+ ', '', ''))


    let entry = key . '/' . cand . '/'
    let sla1 = match(line, '/', 0)
    if line[sla1 + 1] == '['
        let sla2 = matchend(line, '/\]/', sla1 + 1) - 1
    else
        let sla2 = match(line, '/', sla1 + 1)
    endif
    while sla2 != -1
        let s = strpart(line, sla1 + 1, sla2 - sla1 - 1)
        let sla1 = sla2
        if line[sla1 + 1] == '['
            let sla2 = matchend(line, '/\]/', sla1 + 1) - 1
        else
            let sla2 = match(line, '/', sla1 + 1)
        endif
        if s ==# cand
            continue
        endif
        let entry = entry . s . '/'
    endwhile
    return entry
endfunction "}}}

lockvar s:dict
" }}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

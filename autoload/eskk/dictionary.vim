" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



" Utility functions {{{

" Returns all lines matching the candidate.
"
" TODO: memoization should be done by `autload/eskk.vim`.
" `autoload/eskk/**/*.vim` for libraries.
" They should not have side-effect due to testability.
let s:search_all_candidate_memoize = {}
" eskk#dictionary#search_all_candidates() {{{
function! eskk#dictionary#search_all_candidates(
\   physical_dict, key_filter, okuri_rom, ...
\)
    let limit = a:0 ? a:1 : -1    " No limit by default.
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '')

    let cache_key =
    \   a:physical_dict.get_ftime_at_read()
    \   . a:physical_dict.path
    \   . a:key_filter
    \   . a:okuri_rom
    \   . limit

    if has_key(s:search_all_candidate_memoize, cache_key)
        return s:search_all_candidate_memoize[cache_key]
    endif

    let whole_lines = a:physical_dict.get_lines()
    if !a:physical_dict.is_valid()
        return []
    endif

    let converted = eskk#util#iconv(needle, &l:encoding, a:physical_dict.encoding)
    if a:physical_dict.sorted
        let [line, idx] = s:search_binary(
        \   a:physical_dict,
        \   whole_lines,
        \   converted,
        \   has_okuri,
        \   100
        \)

        if idx == -1
            let s:search_all_candidate_memoize[cache_key] = []
            return []
        endif

        " Get lines until limit.
        let begin = idx
        let i = begin + 1
        while eskk#util#has_idx(whole_lines, i)
                    \   && stridx(whole_lines[i], converted) == 0
            let i += 1
        endwhile
        let end = i - 1
        call eskk#error#assert(begin <= end, 'begin <= end')
        if limit >= 0 && begin + limit < end
            let end = begin + limit
        endif

        let s:search_all_candidate_memoize[cache_key] = map(
        \   whole_lines[begin : end],
        \   'eskk#util#iconv(v:val, a:physical_dict.encoding, &l:encoding)'
        \)
    else
        let lines = []
        let start = 1
        while 1
            let [line, idx] = s:search_linear(
            \   a:physical_dict,
            \   whole_lines,
            \   converted,
            \   has_okuri,
            \   start
            \)

            if idx == -1
                break
            endif

            call add(lines, line)
            let start = idx + 1
        endwhile

        let s:search_all_candidate_memoize[cache_key] = map(
        \   lines,
        \   'eskk#util#iconv(v:val, a:physical_dict.encoding, &l:encoding)'
        \)
    endif

    return s:search_all_candidate_memoize[cache_key]
endfunction "}}}

" Returns [line_string, idx] matching the candidate.
" eskk#dictionary#search_candidate() {{{
function! eskk#dictionary#search_candidate(
\   physical_dict, key_filter, okuri_rom
\)
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '') . ' '

    let whole_lines = a:physical_dict.get_lines()
    if !a:physical_dict.is_valid()
        return ['', -1]
    endif

    let converted = eskk#util#iconv(needle, &l:encoding, a:physical_dict.encoding)
    if a:physical_dict.sorted
        let [line, idx] = s:search_binary(
        \   a:physical_dict, whole_lines, converted, has_okuri, 100
        \)
    else
        let [line, idx] = s:search_linear(
        \   a:physical_dict, whole_lines, converted, has_okuri
        \)
    endif
    if idx !=# -1
        return [
        \   eskk#util#iconv(line, a:physical_dict.encoding, &l:encoding),
        \   idx
        \]
    else
        return ['', -1]
    endif
endfunction "}}}
" Returns [line_string, idx] matching the candidate.
" s:search_binary() {{{
function! s:search_binary(
\   ph_dict, whole_lines, needle, has_okuri, limit
\)
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    " NOTE: min, max, mid are index number. not lnum.

    if a:has_okuri
        let min = a:ph_dict.okuri_ari_idx
        let max = a:ph_dict.okuri_nasi_idx
    else
        let min = a:ph_dict.okuri_nasi_idx
        let max = len(a:whole_lines) - 1
    endif

    if a:has_okuri
        while max - min > a:limit
            let mid = (min + max) / 2
            if a:needle >=# a:whole_lines[mid]
                let max = mid
            else
                let min = mid
            endif
        endwhile
    else
        while max - min > a:limit
            let mid = (min + max) / 2
            if a:needle >=# a:whole_lines[mid]
                let min = mid
            else
                let max = mid
            endif
        endwhile
    endif

    " NOTE: min, max: Give index number, not lnum.
    return s:search_linear(
    \   a:ph_dict, a:whole_lines, a:needle, a:has_okuri, min, max
    \)
endfunction "}}}
" Returns [line_string, idx] matching the candidate.
" s:search_linear() {{{
function! s:search_linear(
\   ph_dict, whole_lines, needle, has_okuri, ...
\)
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    let min_which = a:has_okuri ? 'okuri_ari_idx' : 'okuri_nasi_idx'
    let min = get(a:000, 0, a:ph_dict[min_which])
    let max = get(a:000, 1, len(a:whole_lines) - 1)

    call eskk#error#assert(min <=# max, min.' <=# '.max)
    call eskk#error#assert(min >= 0, "min is not invalid (negative) number:" . min)

    while min <=# max
        if stridx(a:whole_lines[min], a:needle) == 0
            return [a:whole_lines[min], min]
        endif
        let min += 1
    endwhile
    return ['', -1]
endfunction "}}}

" Returns [key, okuri_rom, candidates] which line contains.
function! eskk#dictionary#parse_skk_dict_line(line, from_type) "{{{
    let list = split(a:line, '/')
    call eskk#error#assert(!empty(list), 'list must not be empty')
    let key = matchstr(list[0], '^[^a-z ]\+')
    let okuri_rom = matchstr(list[0], '[a-z]\+')
    let has_okuri = okuri_rom != ''

    let candidates = []
    for _ in list[1:]
        let semicolon = stridx(_, ';')
        if semicolon != -1
            let c = s:candidate_new(
            \   a:from_type,
            \   _[: semicolon - 1],
            \   has_okuri,
            \   _[semicolon + 1 :]
            \)
        else
            let c = s:candidate_new(
            \   a:from_type,
            \   _,
            \   has_okuri
            \)
        endif
        call add(candidates, c)
    endfor

    return [key, okuri_rom, candidates]
endfunction "}}}

" Returns String of the created entry from arguments values.
" eskk#dictionary#create_new_entry() {{{
function! eskk#dictionary#create_new_entry(
\   existing_line, key, okuri_rom, new_word, annotation
\)
    " XXX:
    " TODO:
    " Rewrite for eskk.
    " This function is from skk.vim's s:SkkMakeNewEntry().

    " XXX:
    " Modify them to make the same input to
    " the original s:SkkMakeNewEntry()'s arguments.
    let key = a:key . (a:okuri_rom == '' ? '' : a:okuri_rom[0]) . ' '
    let cand = a:new_word . ";" . a:annotation
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


function! s:clear_command_line() "{{{
    redraw
    echo ''
endfunction "}}}

" }}}


" s:Candidate: s:candidate_new() {{{
" One s:Candidate corresponds to SKK dictionary's one line.
" It is the pair of filtered string and its converted string.

let [
\   s:CANDIDATE_FROM_USER_DICT,
\   s:CANDIDATE_FROM_SYSTEM_DICT,
\   s:CANDIDATE_FROM_REGISTERED_WORDS
\] = range(3)

function! s:candidate_new(from_type, input, has_okuri, ...) "{{{
    let obj = {
    \   'from_type': a:from_type,
    \   'input': a:input,
    \   'has_okuri': a:has_okuri,
    \}

    if a:0
        let obj.annotation = a:1
    endif

    return obj
endfunction "}}}

function! eskk#dictionary#_candidate_identifer(candidate) "{{{
    return
    \   a:candidate.input
    \   . (has_key(a:candidate, 'annotation') ?
    \       ';' . a:candidate.annotation : '')
endfunction "}}}

function! s:candidate2registered_word(candidate, key, okuri, okuri_rom) "{{{
    return s:registered_word_new(
    \   a:candidate.input,
    \   a:key,
    \   a:okuri,
    \   a:okuri_rom,
    \   ''
    \)
endfunction "}}}

" }}}

" s:RegisteredWord: s:registered_word_new() {{{
" s:RegisteredWord is the word registered by
" s:Dictionary.remember_word_prompt().

function! s:registered_word_new(input, key, okuri, okuri_rom, annotation) "{{{
    return {
    \   'input': a:input,
    \   'key': a:key,
    \   'okuri': a:okuri,
    \   'okuri_rom': a:okuri_rom,
    \   'annotation': a:annotation,
    \}
endfunction "}}}

function! eskk#dictionary#_registered_word_identifier(rw) "{{{
    return join(map(
    \   ['input', 'key', 'okuri', 'okuri_rom'], 'a:rw[v:val]'), ';')
endfunction "}}}

" }}}


function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID

let s:VICE_OPTIONS = {'generate_stub': 1}


" s:HenkanResult {{{

" Interface for henkan result.
" This provides a method `get_next()`
" to get next candidate string.

let [
\   g:eskk#dictionary#HR_NO_RESULT,
\   g:eskk#dictionary#HR_LOOK_UP_DICTIONARY,
\   g:eskk#dictionary#HR_GOT_RESULT
\] = range(3)

" self._key, self._okuri_rom, self._okuri:
"   Query for this henkan result.
" self._status:
"   One of g:eskk#dictionary#HR_*
" self._candidates:
"   Candidates looked up by self._key, self._okuri_rom, self._okuri
"   NOTE:
"   Do not access directly.
"   Getter is s:HenkanResult.get_candidates().
" self._candidates_index:
"   Current index of List self._candidates
" self._user_dict_found_index:
"   The lnum of found the candidate in user dictionary.
"   Used by s:HenkanResult.delete_from_dict()
let s:HenkanResult = vice#class('HenkanResult', s:SID_PREFIX, s:VICE_OPTIONS)
call s:HenkanResult.attribute('buftable', {})
call s:HenkanResult.attribute('_key', '')
call s:HenkanResult.attribute('_okuri_rom', '')
call s:HenkanResult.attribute('_okuri', '')
call s:HenkanResult.attribute('_status', -1)
call s:HenkanResult.attribute('_candidates', {})
call s:HenkanResult.attribute('_candidates_index', -1)
call s:HenkanResult.attribute('_user_dict_found_index', -1)

function! {s:HenkanResult.constructor()}(this, key, okuri_rom, okuri, buftable) "{{{
    call extend(
    \   a:this,
    \   {
    \       'buftable': a:buftable,
    \       '_key': a:key,
    \       '_okuri_rom': a:okuri_rom,
    \       '_okuri': a:okuri,
    \   },
    \   'force'
    \)
    call a:this.reset()
endfunction "}}}

" Reset candidates.
" After calling this function,
" s:HenkanResult.get_candidates() will look up dictionary again.
function! {s:HenkanResult.method('reset')}(this) "{{{
    call extend(
    \   a:this,
    \   {
    \       '_status': g:eskk#dictionary#HR_LOOK_UP_DICTIONARY,
    \       '_candidates': cul#ordered_set#new(
    \           {'Fn_identifier': 'eskk#dictionary#_candidate_identifier'}
    \       ),
    \       '_candidates_index': 0,
    \   },
    \   'force'
    \)
    call a:this.remove_cache()
endfunction "}}}

" Forward/Back self._candidates_index safely
" Returns true value when succeeded / false value when failed
function! {s:HenkanResult.method('advance')}(this, advance) "{{{
    call a:this.remove_cache()

    try
        let candidates = a:this.get_candidates()
        let idx = a:this._candidates_index
        if eskk#util#has_idx(candidates, idx + (a:advance ? 1 : -1))
            " Next time to call s:HenkanResult.get_candidates(),
            " eskk will getchar() if `idx >= g:eskk#show_candidates_count`
            let a:this._candidates_index +=  (a:advance ? 1 : -1)
            return 1
        else
            return 0
        endif
        return 0
    catch /^eskk: dictionary look up error/
        " Shut up error. This function does not throw exception.
        call eskk#error#log_exception('s:HenkanResult.get_candidates()')
        return 0
    endtry
endfunction "}}}

" Returns List of candidates.
function! {s:HenkanResult.method('get_candidates')}(this) "{{{
    if a:this._status ==# g:eskk#dictionary#HR_GOT_RESULT
        return a:this._candidates.to_list()

    elseif a:this._status ==# g:eskk#dictionary#HR_LOOK_UP_DICTIONARY
        let dict = eskk#get_skk_dict()
        let user_dict = dict.get_user_dict()
        let system_dict = dict.get_system_dict()
        " Look up this henkan result in dictionaries.
        let user_dict_result = eskk#dictionary#search_candidate(
        \   user_dict, a:this._key, a:this._okuri_rom
        \)
        let system_dict_result = eskk#dictionary#search_candidate(
        \   system_dict, a:this._key, a:this._okuri_rom
        \)
        if user_dict_result[1] ==# -1 && system_dict_result[1] ==# -1
            let a:this._status = g:eskk#dictionary#HR_NO_RESULT
            throw eskk#dictionary#look_up_error(
            \   "Can't look up '"
            \   . g:eskk#marker_henkan
            \   . a:this._key
            \   . g:eskk#marker_okuri
            \   . a:this._okuri_rom
            \   . "' in dictionaries."
            \)
        endif

        " NOTE: The order is important.
        " registered word, user dictionary, system dictionary.

        " Merge registered words.
        let registered = filter(
        \   copy(dict.get_registered_words()),
        \   'v:val.key ==# a:this._key '
        \       . '&& v:val.okuri_rom[0] ==# a:this._okuri_rom[0]'
        \)
        if !empty(registered)
            for rw in registered
                let c = s:candidate_new(
                \   s:CANDIDATE_FROM_REGISTERED_WORDS,
                \   rw.input, rw.okuri_rom != ""
                \)
                call a:this._candidates.push(c)
            endfor
        endif

        " Merge user dictionary.
        if user_dict_result[1] !=# -1
            let [key, okuri_rom, candidates] =
            \   eskk#dictionary#parse_skk_dict_line(
            \       user_dict_result[0],
            \       s:CANDIDATE_FROM_USER_DICT
            \   )
            call eskk#error#assert(
            \   key ==# a:this._key,
            \   "user dict:".string(key)." ==# ".string(a:this._key)
            \)
            call eskk#error#assert(
            \   okuri_rom ==# a:this._okuri_rom[0],
            \   "user dict:".string(okuri_rom)." ==# ".string(a:this._okuri_rom)
            \)

            for c in candidates
                call a:this._candidates.push(c)
            endfor
        endif

        " Merge system dictionary.
        if system_dict_result[1] !=# -1
            let [key, okuri_rom, candidates] =
            \   eskk#dictionary#parse_skk_dict_line(
            \       system_dict_result[0],
            \       s:CANDIDATE_FROM_SYSTEM_DICT
            \   )
            call eskk#error#assert(
            \   key ==# a:this._key,
            \   "system dict:".string(key)." ==# ".string(a:this._key)
            \)
            call eskk#error#assert(
            \   okuri_rom ==# a:this._okuri_rom[0],
            \   "system dict:".string(okuri_rom)." ==# ".string(a:this._okuri_rom)
            \)

            for c in candidates
                call a:this._candidates.push(c)
            endfor
        endif

        let a:this._user_dict_found_index = user_dict_result[1]
        let a:this._status = g:eskk#dictionary#HR_GOT_RESULT

        return a:this._candidates.to_list()
    else
        return []

    elseif a:this._status ==# g:eskk#dictionary#HR_NO_RESULT
        throw eskk#dictionary#look_up_error(
        \   "Can't look up '"
        \   . g:eskk#marker_henkan
        \   . a:this._key
        \   . g:eskk#marker_okuri
        \   . a:this._okuri_rom
        \   . "' in dictionaries."
        \)
    "else
        "throw eskk#internal_error(['eskk', 'dictionary'])
    endif
endfunction "}}}

function! eskk#dictionary#look_up_error(msg) "{{{
    return eskk#error#build_error(
    \   ['eskk', 'dictionary'],
    \   ['dictionary look up error', a:msg]
    \)
endfunction "}}}

" Select candidate from command-line.
" s:HenkanResult.select_candidates() {{{
function! {s:HenkanResult.method('select_candidates')}(
\   this, with_okuri, skip_num, functor
\)
    if eskk#is_neocomplcache_locked()
        NeoComplCacheUnlock
    endif

    " Select candidates by getchar()'s character.
    let words = copy(a:this.get_candidates())
    let word_num_per_page = len(split(g:eskk#select_cand_keys, '\zs'))
    let page_index = 0
    let pages = []

    call eskk#error#assert(
    \   len(words) > a:skip_num,
    \   "words has more than skip_num words."
    \)
    let words = words[a:skip_num :]

    while !empty(words)
        let words_in_page = []
        " Add words to `words_in_page` as number of
        " string length of `g:eskk#select_cand_keys`.
        for c in split(g:eskk#select_cand_keys, '\zs')
            if empty(words)
                break
            endif
            call add(words_in_page, [c, remove(words, 0)])
        endfor
        call add(pages, words_in_page)
    endwhile

    while 1
        " Show candidates.
        redraw
        for [c, word] in pages[page_index]
            if g:eskk#show_annotation
                echon printf('%s:%s%s  ', c, word.input,
                \       (has_key(word, 'annotation') ?
                \           ';' . word.annotation : ''))
            else
                echon printf('%s:%s  ', c, word.input)
            endif
        endfor
        echon printf('(%d/%d)', page_index, len(pages) - 1)

        " Get char for selected candidate.
        try
            let char = eskk#util#getchar()
        catch /^Vim:Interrupt$/
            return a:functor.funcall()
        endtry


        if eskk#mappings#is_special_lhs(
        \   char, 'phase:henkan-select:escape'
        \)
            return a:functor.funcall()
        elseif eskk#mappings#is_special_lhs(
        \   char, 'phase:henkan-select:next-page'
        \)
            if eskk#util#has_idx(pages, page_index + 1)
                let page_index += 1
            else
                " No more pages. Register new word.
                let dict = eskk#get_skk_dict()
                let input = dict.remember_word_prompt(a:this)[0]
                let henkan_buf_str = a:this.buftable.get_buf_str(
                \   g:eskk#buftable#PHASE_HENKAN
                \)
                let okuri_buf_str = a:this.buftable.get_buf_str(
                \   g:eskk#buftable#PHASE_OKURI
                \)
                return [
                \   (input != '' ?
                \       input : henkan_buf_str.rom_pairs.get_filter()),
                \   okuri_buf_str.rom_pairs.get_filter()
                \]
            endif
        elseif eskk#mappings#is_special_lhs(
        \   char, 'phase:henkan-select:prev-page'
        \)
            if eskk#util#has_idx(pages, page_index - 1)
                let page_index -= 1
            else
                return a:functor.funcall()
            endif
        elseif stridx(g:eskk#select_cand_keys, char) != -1
            let selected = g:eskk#select_cand_keys[
            \   stridx(g:eskk#select_cand_keys, char)
            \]
            for idx in range(len(pages[page_index]))
                let [c, word] = pages[page_index][idx]
                if c ==# selected
                    " Dummy result list for `word`.
                    " Note that assigning to index number is useless.
                    let a:this._candidates_index = idx + a:skip_num
                    return [
                    \   word.input,
                    \   (a:with_okuri ? a:this._okuri : '')
                    \]
                endif
            endfor
        endif
    endwhile
endfunction "}}}

" Clear cache of current candidate.
function! {s:HenkanResult.method('remove_cache')}(this) "{{{
    if has_key(a:this, '_candidate')
        unlet a:this._candidate
    endif
endfunction "}}}


" Returns candidate String.
" if optional {with_okuri} arguments are supplied,
" returns candidate String with okuri.
function! {s:HenkanResult.method('get_candidate')}(this, ...) "{{{
    let with_okuri = a:0 ? a:1 : 1

    if has_key(a:this, '_candidate')
        return a:this._candidate[0] . (with_okuri ? a:this._candidate[1] : '')
    endif

    let max_count = g:eskk#show_candidates_count >= 0 ?
    \                   g:eskk#show_candidates_count : 0
    let candidates = a:this.get_candidates()

    if a:this._candidates_index >= max_count
        let functor = {
        \   'candidates': candidates,
        \   'this': a:this,
        \   'with_okuri': with_okuri,
        \}
        function functor.funcall()
            " Clear command-line.
            call s:clear_command_line()

            if self.this._candidates_index > 0
                " This changes self.this._candidates_index.
                call self.this.back()
            endif
            return [
            \   self.candidates[self.this._candidates_index].input,
            \   (self.with_okuri ? self.this._okuri : '')
            \]
        endfunction

        let a:this._candidate = a:this.select_candidates(
        \   with_okuri, max_count, functor
        \)
    else
        let a:this._candidate = [
        \   candidates[a:this._candidates_index].input,
        \   (with_okuri ? a:this._okuri : '')
        \]
    endif

    return a:this._candidate[0] . (with_okuri ? a:this._candidate[1] : '')
endfunction "}}}
" Getter for self._key
function! {s:HenkanResult.method('get_key')}(this) "{{{
    return a:this._key
endfunction "}}}
" Getter for self._okuri
function! {s:HenkanResult.method('get_okuri')}(this) "{{{
    return a:this._okuri
endfunction "}}}
" Getter for self._okuri_rom
function! {s:HenkanResult.method('get_okuri_rom')}(this) "{{{
    return a:this._okuri_rom
endfunction "}}}
" Getter for self._status
function! {s:HenkanResult.method('get_status')}(this) "{{{
    return a:this._status
endfunction "}}}

" Forward current candidate index number (self._candidates_index)
function! {s:HenkanResult.method('forward')}(this) "{{{
    return a:this.advance(1)
endfunction "}}}
" Back current candidate index number (self._candidates_index)
function! {s:HenkanResult.method('back')}(this) "{{{
    return a:this.advance(0)
endfunction "}}}
function! {s:HenkanResult.method('has_next')}(this) "{{{
    try
        let candidates = a:this.get_candidates()
        let idx = a:this._candidates_index
        return eskk#util#has_idx(candidates, idx + 1)
    catch /^eskk: dictionary look up error/
        " Shut up error. This function does not throw exception.
        call eskk#error#log_exception('s:HenkanResult.get_candidates()')
        return 0
    endtry
endfunction "}}}

" Delete current candidate from all places.
" e.g.:
" - s:Dictionary._registered_words
" - self._candidates
" - SKK dictionary
" -- User dictionary
" -- TODO: System dictionary (skk-ignore-dic-word) (Issue #86)
function! {s:HenkanResult.method('delete_from_dict')}(this) "{{{
    try
        return a:this.do_delete_from_dict()
    finally
        let dict = eskk#get_skk_dict()
        call dict.clear_henkan_result()
    endtry
endfunction "}}}
function! {s:HenkanResult.method('do_delete_from_dict')}(this) "{{{
    let candidates = a:this.get_candidates()
    let candidates_index = a:this._candidates_index
    let user_dict_idx = a:this._user_dict_found_index

    if !eskk#util#has_idx(candidates, candidates_index)
        return
    endif

    let dict = eskk#get_skk_dict()
    let user_dict_lines = dict.get_user_dict().get_lines()
    if !dict.get_user_dict().is_valid()
        return
    endif

    let input = eskk#util#input(
    \   'Really purge? '
    \   . a:this._key . a:this._okuri_rom[0]
    \   . ' /'
    \   . candidates[candidates_index].input
    \   . (has_key(candidates[candidates_index], 'annotation') ?
    \       ';' . candidates[candidates_index].annotation :
    \       '')
    \   . '/ (yes/no):'
    \)
    if input !~? '^y\%[es]$'
        return
    endif

    let from_type = candidates[candidates_index].from_type
    if from_type ==# s:CANDIDATE_FROM_REGISTERED_WORDS
        " Remove all elements matching with current candidate
        " from registered words.
        let words = dict.get_registered_words()
        for i in range(len(words))
            if candidates[candidates_index].input ==# words[i].input
                call dict.remove_registered_word(
                \   words[i].input,
                \   words[i].key,
                \   words[i].okuri,
                \   words[i].okuri_rom,
                \   words[i].annotation
                \)
            endif
        endfor
        return
    endif

    call remove(user_dict_lines, user_dict_idx)
    try
        call dict.get_user_dict().set_lines(user_dict_lines)
    catch /^eskk: parse error/
        return
    endtry

    call a:this.reset()

    redraw
    call dict.update_dictionary()
endfunction "}}}

" Move this henkan result to the first of a:this._registered_words.
function! {s:HenkanResult.method('update_candidate')}(this) "{{{
    let candidates = a:this.get_candidates()
    let candidates_index = a:this._candidates_index

    if !eskk#util#has_idx(candidates, candidates_index)
        return
    endif
    let rw = s:candidate2registered_word(
    \   candidates[candidates_index],
    \   a:this._key,
    \   a:this._okuri,
    \   a:this._okuri_rom,
    \)

    " Move a:this to the first.
    let dict = eskk#get_skk_dict()
    call dict.forget_word(rw.input, rw.key, rw.okuri, rw.okuri_rom, rw.annotation)
    call dict.remember_word(rw.input, rw.key, rw.okuri, rw.okuri_rom, rw.annotation)
endfunction "}}}
" }}}

" s:PhysicalDict {{{
"
" Database for physical file dictionary.
" `s:PhysicalDict` manipulates only one file.
" But `s:Dictionary` may manipulate multiple dictionaries.
"
" `get_lines()` does
" - Lazy file read
" - Memoization for getting file content

let s:PhysicalDict = vice#class('PhysicalDict', s:SID_PREFIX, s:VICE_OPTIONS)
call s:PhysicalDict.attribute('_content_lines', [])
call s:PhysicalDict.attribute('_ftime_at_read', 0)
call s:PhysicalDict.attribute('_loaded', 0)
call s:PhysicalDict.attribute('okuri_ari_idx', -1)
call s:PhysicalDict.attribute('okuri_nasi_idx', -1)
call s:PhysicalDict.attribute('path', '')
call s:PhysicalDict.attribute('sorted', 0)
call s:PhysicalDict.attribute('encoding', '')
call s:PhysicalDict.attribute('_is_modified', 0)


function! {s:PhysicalDict.constructor()}(this, path, sorted, encoding) "{{{
    call extend(
    \   a:this,
    \   {
    \       'path': expand(a:path),
    \       'sorted': a:sorted,
    \       'encoding': a:encoding,
    \   },
    \   'force'
    \)
endfunction "}}}



" Get List of whole lines of dictionary.
function! {s:PhysicalDict.method('get_lines')}(this, ...) "{{{
    let force = a:0 ? a:1 : 0

    " FIXME: Separate this to another method
    " and control dictionary read timing.
    " (when it should be read?)
    let same_timestamp = a:this._ftime_at_read ==# getftime(a:this.path)
    if a:this._loaded && same_timestamp && !force
        return a:this._content_lines
    endif

    let path = a:this.path
    try
        let a:this._content_lines  = readfile(path)
        call a:this.parse_lines(a:this._content_lines)

        let a:this._ftime_at_read = getftime(path)
        let a:this._loaded = 1
    catch /E484:/    " Can't open file
        call eskk#error#logf("Can't read '%s'!", path)
    catch /^eskk: parse error/
        call eskk#error#log_exception('s:physical_dict.get_lines()')
        let a:this.okuri_ari_idx = -1
        let a:this.okuri_nasi_idx = -1
    endtry

    return a:this._content_lines
endfunction "}}}

function! {s:PhysicalDict.method('get_updated_lines')}(this, registered_words) "{{{
    let user_dict_lines = a:this.get_lines()
    if a:registered_words.empty()
        return user_dict_lines
    endif
    let user_dict_lines = copy(user_dict_lines)

    " Check if a:this._user_dict really does not have registered words.
    let ari_lnum = a:this.okuri_ari_idx + 1
    let nasi_lnum = a:this.okuri_nasi_idx + 1
    for w in reverse(a:registered_words.to_list())
        let [line, index] = eskk#dictionary#search_candidate(
        \   a:this, w.key, w.okuri_rom
        \)
        if w.okuri_rom != ''
            let lnum = ari_lnum
        else
            let lnum = nasi_lnum
        endif
        " Delete old entry.
        if index !=# -1
            call remove(user_dict_lines, index)
            call eskk#error#assert(line != '', 'line must not be empty string')
        elseif w.okuri_rom != ''
            let nasi_lnum += 1
        endif
        " Merge old one and create new entry.
        call insert(
        \   user_dict_lines,
        \   eskk#dictionary#create_new_entry(
        \       line, w.key, w.okuri_rom,
        \       w.input, w.annotation
        \   ),
        \   lnum
        \)
    endfor

    return user_dict_lines
endfunction "}}}

" Set List of whole lines of dictionary.
function! {s:PhysicalDict.method('set_lines')}(this, lines) "{{{
    try
        let a:this._content_lines  = a:lines
        call a:this.parse_lines(a:lines)
        let a:this._loaded = 1
        let a:this._is_modified = 1
    catch /^eskk: parse error/
        call eskk#error#log_exception('s:physical_dict.set_lines()')
        let a:this.okuri_ari_idx = -1
        let a:this.okuri_nasi_idx = -1
    endtry
endfunction "}}}

" - Validate List of whole lines of dictionary.
" - Set self.okuri_ari_idx, self.okuri_nasi_idx.
function! {s:PhysicalDict.method('parse_lines')}(this, lines) "{{{
    let a:this.okuri_ari_idx  = index(
    \   a:this._content_lines,
    \   ';; okuri-ari entries.'
    \)
    if a:this.okuri_ari_idx ==# -1
        throw eskk#dictionary#parse_error(
        \   "invalid a:this.okuri_ari_idx value"
        \)
    endif

    let a:this.okuri_nasi_idx = index(
    \   a:this._content_lines,
    \   ';; okuri-nasi entries.'
    \)
    if a:this.okuri_nasi_idx ==# -1
        throw eskk#dictionary#parse_error(
        \   "invalid a:this.okuri_nasi_idx value"
        \)
    endif

    if a:this.okuri_ari_idx >= a:this.okuri_nasi_idx
        throw eskk#dictionary#parse_error(
        \   "okuri-ari entries must be before okuri-nasi entries."
        \)
    endif
endfunction "}}}

function! eskk#dictionary#parse_error(msg) "{{{
    return eskk#error#build_error(
    \   ['eskk', 'dictionary'],
    \   ["SKK dictionary parse error", a:msg]
    \)
endfunction "}}}

" Returns true value if "self.okuri_ari_idx" and
" "self.okuri_nasi_idx" is valid range.
function! {s:PhysicalDict.method('is_valid')}(this) "{{{
    " Succeeded to parse SKK dictionary.
    return a:this.okuri_ari_idx >= 0
    \   && a:this.okuri_nasi_idx >= 0
endfunction "}}}

" Get self._ftime_at_read.
" See self._ftime_at_read description at "s:physical_dict".
function! {s:PhysicalDict.method('get_ftime_at_read')}(this) "{{{
    return a:this._ftime_at_read
endfunction "}}}

" }}}

" s:Dictionary {{{
"
" Interface for multiple dictionary.
" This behaves like one file dictionary.
" But it may have multiple dictionaries.
"
" See section `Searching Functions` for
" implementation of searching dictionaries.

" _user_dict:
"   User dictionary.
"
" _system_dict:
"   System dictionary.
"
" _registered_words:
"   ordered set.
"
" _current_henkan_result:
"   Current henkan result.

let s:Dictionary = vice#class('Dictionary', s:SID_PREFIX, s:VICE_OPTIONS)
call s:Dictionary.attribute('_user_dict', {})
call s:Dictionary.attribute('_system_dict', {})
call s:Dictionary.attribute('_registered_words', {})
call s:Dictionary.attribute('_registered_words_modified', 0)
call s:Dictionary.attribute('_current_henkan_result', {})

function! eskk#dictionary#new(...) "{{{
    return call(s:Dictionary.new, a:000, s:Dictionary)
endfunction "}}}

function! {s:Dictionary.constructor()}(this, ...) "{{{
    let user_dict = get(a:000, 0, g:eskk#directory)
    let system_dict = get(a:000, 1, g:eskk#large_dictionary)
    return extend(
    \   a:this,
    \   {
    \       '_user_dict': s:PhysicalDict.new(
    \           user_dict.path,
    \           user_dict.sorted,
    \           user_dict.encoding,
    \       ),
    \       '_system_dict': s:PhysicalDict.new(
    \           system_dict.path,
    \           system_dict.sorted,
    \           system_dict.encoding,
    \       ),
    \       '_registered_words': cul#ordered_set#new(
    \           {'Fn_identifier':
    \               'eskk#dictionary#_registered_word_identifier'}
    \       ),
    \   },
    \   'force'
    \)
endfunction "}}}


" Find matching candidates from all places.
"
" This actually just sets "self._current_henkan_result"
" which is "s:HenkanResult"'s instance.
" This is interface so s:HenkanResult is implementation.
function! {s:Dictionary.method('refer')}(this, buftable, key, okuri, okuri_rom) "{{{
    let hr = s:HenkanResult.new(
    \   a:key,
    \   a:okuri_rom,
    \   a:okuri,
    \   deepcopy(a:buftable, 1),
    \)
    let a:this._current_henkan_result = hr
    return hr
endfunction "}}}

" Register new word (registered word) at command-line.
function! {s:Dictionary.method('remember_word_prompt')}(this, henkan_result) "{{{
    let key       = a:henkan_result.get_key()
    let okuri     = a:henkan_result.get_okuri()
    let okuri_rom = a:henkan_result.get_okuri_rom()


    " Save `&imsearch`.
    let save_imsearch = &l:imsearch
    let &l:imsearch = 1

    " Create new eskk instance.
    call eskk#create_new_instance()

    try
        " Get input from command-line.
        if okuri == ''
            let prompt = printf('%s ', key)
        else
            let prompt = printf('%s%s%s ', key, g:eskk#marker_okuri, okuri)
        endif
        redraw
        let input  = eskk#util#input(prompt)
    catch /^Vim:Interrupt$/
        let input = ''
    finally
        " Destroy current eskk instance.
        try
            call eskk#destroy_current_instance()
        catch /^eskk:/
            call eskk#log_warn('eskk#destroy_current_instance()')
        endtry

        " Enable eskk mapping if it has been disabled.
        call eskk#mappings#map_all_keys()

        " Restore `&imsearch`.
        let &l:imsearch = save_imsearch
    endtry


    if input != ''
        let [input; _] = split(input, ';')
        let annotation = join(_, ';')
        call a:this.remember_word(input, key, okuri, okuri_rom, annotation)
    endif

    call s:clear_command_line()
    return [input, key, okuri]
endfunction "}}}

" Clear all registered words.
function! {s:Dictionary.method('forget_all_words')}(this) "{{{
    call a:this._registered_words.clear()
endfunction "}}}

" Clear given registered word.
function! {s:Dictionary.method('forget_word')}(this, input, key, okuri, okuri_rom, annotation) "{{{
    let rw = s:registered_word_new(a:input, a:key, a:okuri, a:okuri_rom, a:annotation)
    if !a:this._registered_words.has(rw)
        return
    endif

    call a:this._registered_words.remove(rw)
    if a:this._registered_words.empty()
        let a:this._registered_words_modified = 0
    endif

    if !empty(a:this._current_henkan_result)
        call a:this._current_henkan_result.reset()
    endif
endfunction "}}}

" Add registered word.
function! {s:Dictionary.method('remember_word')}(this, input, key, okuri, okuri_rom, annotation) "{{{
    let rw = s:registered_word_new(a:input, a:key, a:okuri, a:okuri_rom, a:annotation)
    if a:this._registered_words.has(rw)
        return
    endif

    call a:this._registered_words.unshift(rw)
    let a:this._registered_words_modified = 1

    if a:this._registered_words.size() >= g:eskk#dictionary_save_count
        call a:this.update_dictionary(0)
    endif

    if !empty(a:this._current_henkan_result)
        call a:this._current_henkan_result.reset()
    endif
endfunction "}}}

" Get List of registered words.
function! {s:Dictionary.method('get_registered_words')}(this) "{{{
    return a:this._registered_words.to_list()
endfunction "}}}

" Remove registered word matching with arguments values.
function! {s:Dictionary.method('remove_registered_word')}(this, input, key, okuri, okuri_rom, annotation) "{{{
    call a:this._registered_words.remove(
    \   s:registered_word_new(
    \       a:input, a:key, a:okuri,
    \       a:okuri_rom, a:annotation
    \   )
    \)
endfunction "}}}

" Returns true value if new registered is added
" or user dictionary's lines are
" modified by "s:physical_dict.set_lines()".
" If this value is false, s:Dictionary.update_dictionary() does nothing.
function! {s:Dictionary.method('is_modified')}(this) "{{{
    " No need to check system dictionary.
    " Because it is immutable.
    return
    \   a:this._registered_words_modified
    \   || a:this._user_dict._is_modified
endfunction "}}}

" After calling this function,
" s:Dictionary.is_modified() will returns false.
" but after calling "s:physical_dict.set_lines()",
" s:Dictionary.is_modified() will returns true.
function! {s:Dictionary.method('clear_modified_flags')}(this) "{{{
    let a:this._registered_words_modified = 0
    let a:this._user_dict._is_modified = 0
endfunction "}}}

" Write to user dictionary.
" By default, This function is executed at VimLeavePre.
function! {s:Dictionary.method('update_dictionary')}(this, ...) "{{{
    let verbose = a:0 ? a:1 : 1
    if !a:this.is_modified()
        return
    endif

    let user_dict_exists = filereadable(a:this._user_dict.path)
    let user_dict_lines = a:this._user_dict.get_lines()
    if user_dict_exists
        if !a:this._user_dict.is_valid()
            return
        endif
    else
        " Create new lines.
        let user_dict_lines = [
        \   ';; okuri-ari entries.',
        \   ';; okuri-nasi entries.'
        \]
        call a:this._user_dict.set_lines(user_dict_lines)
        " NOTE: .set_lines() does not write to dictionary.
        " At this time, dictionary file does not exist.
    endif

    call a:this.write_lines(
    \   a:this._user_dict.get_updated_lines(
    \       a:this._registered_words
    \   ),
    \   verbose
    \)
    call a:this.forget_all_words()
    call a:this.clear_modified_flags()
endfunction "}}}
function! {s:Dictionary.method('write_lines')}(this, lines, verbose) "{{{
    let user_dict_lines = a:lines

    let save_msg =
    \   "Saving to '"
    \   . a:this._user_dict.path
    \   . "'..."

    if a:verbose
        echo save_msg
    endif

    let ret_success = 0
    try
        let ret = writefile(
        \   user_dict_lines, a:this._user_dict.path)
        if ret ==# ret_success
            if a:verbose
                redraw
                echo save_msg . 'Done.'
            endif
        else
            throw eskk#internal_error(
            \   ['eskk', 'dictionary'],
            \   "can't write to '"
            \       . a:this._user_dict.path
            \       . "'."
            \)
        endif
    catch
        redraw
        echohl WarningMsg
        echomsg save_msg . "Error. - " . v:exception
        echomsg " Please check permission of '"
        \   . a:this._user_dict.path . "'."
        echohl None
    endtry
endfunction "}}}

function! eskk#dictionary#_candidate_identifier(candidate) "{{{
    return a:candidate.input
endfunction "}}}

" Reduce the losses of creating instance.
let s:dict_search_candidates = cul#ordered_set#new(
\   {'Fn_identifier': 'eskk#dictionary#_candidate_identifier'}
\)
" Search candidates matching with arguments.
function! {s:Dictionary.method('search')}(this, key, okuri, okuri_rom) "{{{
    let key = a:key
    let okuri = a:okuri
    let okuri_rom = a:okuri_rom

    if key == ''
        return []
    endif

    " To unique candidates.
    let candidates = s:dict_search_candidates
    call candidates.clear()
    let max_count = g:eskk#max_candidates

    for w in a:this._registered_words.to_list()
        if w.key ==# key && w.okuri_rom[0] ==# okuri_rom[0]
            call candidates.push(
            \   s:candidate_new(
            \       s:CANDIDATE_FROM_REGISTERED_WORDS,
            \       w.input,
            \       w.okuri_rom != ""
            \   )
            \)
            if candidates.size() >= max_count
                break
            endif
        endif
    endfor

    if candidates.size() < max_count
        " User dictionary, System dictionary
        try
            for [dict, from_type] in [
            \   [a:this._user_dict, s:CANDIDATE_FROM_USER_DICT],
            \   [a:this._system_dict, s:CANDIDATE_FROM_SYSTEM_DICT],
            \]
                for line in eskk#dictionary#search_all_candidates(
                \   dict, key, okuri_rom, max_count - candidates.size()
                \)
                    for c in eskk#dictionary#parse_skk_dict_line(
                    \   line, from_type
                    \)[2]    " candidates
                        call candidates.push(
                        \   s:candidate_new(
                        \       s:CANDIDATE_FROM_REGISTERED_WORDS,
                        \       c.input,
                        \       okuri_rom != ""
                        \   )
                        \)
                        if candidates.size() >= max_count
                            throw 'break'
                        endif
                    endfor
                endfor
            endfor
        catch /^break$/
        endtry
    endif

    return [key, okuri_rom, candidates.to_list()]
endfunction "}}}


" Getter for self._current_henkan_result
function! {s:Dictionary.method('get_henkan_result')}(this) "{{{
    return a:this._current_henkan_result
endfunction "}}}
" Getter for self._user_dict
function! {s:Dictionary.method('get_user_dict')}(this) "{{{
    return a:this._user_dict
endfunction "}}}
" Getter for self._system_dict
function! {s:Dictionary.method('get_system_dict')}(this) "{{{
    return a:this._system_dict
endfunction "}}}

" Clear self._current_henkan_result
function! {s:Dictionary.method('clear_henkan_result')}(this) "{{{
    let a:this._current_henkan_result = {}
endfunction "}}}

" }}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

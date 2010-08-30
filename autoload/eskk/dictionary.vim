" vim:foldmethod=marker:fen:sw=4:sts=4
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



" Utility autoload functions {{{

" Returns all lines matching the candidate.
function! eskk#dictionary#search_all_candidates(physical_dict, key_filter, okuri_rom, ...) "{{{
    let limit = a:0 ? a:1 : -1    " No limit by default.
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '')

    if g:eskk_debug
        call eskk#util#logf('needle = %s, key = %s, okuri_rom = %s',
        \               string(needle), string(a:key_filter), string(a:okuri_rom))
        call eskk#util#logf('Search %s in %s.', string(needle), string(a:physical_dict.path))
    endif

    let whole_lines = a:physical_dict.get_lines()
    if !a:physical_dict.is_valid()
        return []
    endif

    let converted = s:iconv(needle, &l:encoding, a:physical_dict.encoding)
    if a:physical_dict.sorted
        call eskk#util#log('dictionary is sorted. Try binary search...')

        let result = s:search_binary(a:physical_dict, whole_lines, converted, has_okuri, limit)

        if result[1] == -1
            return []
        endif

        " Get lines until limit.
        let begin = result[1]
        let i = begin + 1
        while eskk#util#has_idx(whole_lines, i)
                    \   && stridx(whole_lines[i], converted) == 0
            let i += 1
        endwhile
        let end = i - 1
        call eskk#util#assert(begin <= end)
        if limit >= 0 && begin + limit < end
            let end = begin + limit
        endif

        return map(whole_lines[begin : end],
                    \   's:iconv(v:val, a:physical_dict.encoding, &l:encoding)'
                    \)
    else
        call eskk#util#log('dictionary is *not* sorted. Try linear search....')

        let lines = []
        let start = 1
        while 1
            let result = s:search_linear(a:physical_dict, whole_lines, converted, has_okuri, start)

            if result[1] == -1
                break
            endif

            call add(lines, result[0])
            let start = result[1] + 1
        endwhile

        return map(lines, 's:iconv(v:val, a:physical_dict.encoding, &l:encoding)')
    endif
endfunction "}}}
" Returns [line_string, lnum] matching the candidate.
function! eskk#dictionary#search_candidate(physical_dict, key_filter, okuri_rom) "{{{
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '') . ' '

    if g:eskk_debug
        call eskk#util#logstrf('needle = %s, key = %s, okuri_rom = %s',
        \               needle, a:key_filter, a:okuri_rom)
        call eskk#util#logstrf('Search %s in %s.', needle, a:physical_dict.path)
    endif

    let whole_lines = a:physical_dict.get_lines()
    if !a:physical_dict.is_valid()
        return ['', -1]
    endif

    let converted = s:iconv(needle, &l:encoding, a:physical_dict.encoding)
    if a:physical_dict.sorted
        call eskk#util#log('dictionary is sorted. Try binary search...')
        let result = s:search_binary(a:physical_dict, whole_lines, converted, has_okuri, 5)
    else
        call eskk#util#log('dictionary is *not* sorted. Try linear search....')
        let result = s:search_linear(a:physical_dict, whole_lines, converted, has_okuri)
    endif
    if result[1] !=# -1
        let conv_line = s:iconv(result[0], a:physical_dict.encoding, &l:encoding)
        call eskk#util#logstrf('eskk#dictionary#search_candidate() - found!: %s', conv_line)
        return [conv_line, result[1]]
    else
        call eskk#util#log('eskk#dictionary#search_candidate() - not found.')
        return ['', -1]
    endif
endfunction "}}}
" Returns [line_string, lnum] matching the candidate.
function! s:search_binary(ph_dict, whole_lines, needle, has_okuri, limit) "{{{
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    " NOTE: min, max, mid are index number. not lnum.

    if a:has_okuri
        let [min, max] = [a:ph_dict.okuri_ari_idx, a:ph_dict.okuri_nasi_idx - 1]
        call eskk#util#assert(a:ph_dict.okuri_ari_idx !=# -1, 'okuri_ari_idx is not -1')
    else
        let [min, max] = [a:ph_dict.okuri_nasi_idx, len(a:whole_lines) - 1]
        call eskk#util#assert(a:ph_dict.okuri_nasi_idx !=# -1, 'okuri_nasi_idx is not -1')
    endif

    " call eskk#util#logf('s:search_binary(): Initial: min = %d, max = %d', min, max)

    if a:has_okuri
        while max - min > a:limit
            let mid = (min + max) / 2
            let line = a:whole_lines[mid]
            if a:needle >=# line
                let max = mid
            else
                let min = mid
            endif
        endwhile
    else
        while max - min > a:limit
            let mid = (min + max) / 2
            let line = a:whole_lines[mid]
            if a:needle >=# line
                let min = mid
            else
                let max = mid
            endif
        endwhile
    endif

    " NOTE: min, max: Give index number, not lnum.
    return s:search_linear(a:ph_dict, a:whole_lines, a:needle, a:has_okuri, min, max)
endfunction "}}}
" Returns [line_string, lnum] matching the candidate.
function! s:search_linear(ph_dict, whole_lines, needle, has_okuri, ...) "{{{
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    if a:0 == 1
        let [min, max] = [a:1, len(a:whole_lines) - 1]
    elseif a:0 >= 2
        let [min, max] = a:000
        call eskk#util#assert(min <=# max, 'min <=# max')
    elseif a:has_okuri
        let [min, max] = [a:ph_dict.okuri_ari_idx, len(a:whole_lines) - 1]
        call eskk#util#assert(a:ph_dict.okuri_ari_idx !=# -1, 'okuri_ari_idx is not -1')
    else
        let [min, max] = [a:ph_dict.okuri_nasi_idx, len(a:whole_lines) - 1]
        call eskk#util#assert(a:ph_dict.okuri_nasi_idx !=# -1, 'okuri_nasi_idx is not -1')
    endif
    call eskk#util#assert(min >= 0, "min is not invalid (negative) number.")
    " call eskk#util#logf('s:search_linear(): Initial: min = %d, max = %d', min, max)

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
    call eskk#util#assert(!empty(list))
    let [key, okuri_rom] = [matchstr(list[0], '^[^a-z ]\+'), matchstr(list[0], '[a-z]\+')]

    let candidates = []
    for _ in list[1:]
        let semicolon = stridx(_, ';')
        call add(
        \   candidates,
        \   semicolon != -1 ?
        \       s:candidate_new(a:from_type, _[: semicolon - 1], _[semicolon + 1 :]) :
        \       s:candidate_new(a:from_type, _)
        \)
    endfor

    return [key, okuri_rom, candidates]
endfunction "}}}

" Returns String of the created entry from arguments values.
function! eskk#dictionary#create_new_entry(new_word, key, okuri, okuri_rom, existing_line) "{{{
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

" }}}



" s:candidate: s:candidate_new() {{{

let s:CANDIDATE_FROM_USER_DICT = 0
let s:CANDIDATE_FROM_SYSTEM_DICT = 1
let s:CANDIDATE_FROM_ADDED_WORDS = 2
lockvar s:CANDIDATE_FROM_USER_DICT s:CANDIDATE_FROM_SYSTEM_DICT s:CANDIDATE_FROM_ADDED_WORDS

function! s:candidate_new(from_type, input, ...) "{{{
    let obj = {'from_type': a:from_type, 'input': a:input}

    if a:0
        let obj.annotation = a:1
    endif

    return obj
endfunction "}}}

" }}}

" s:henkan_result {{{

" Interface for henkan result.
" This provides a method `get_next()`
" to get next candidate string.

let g:eskk#dictionary#HR_NO_RESULT = 0
lockvar g:eskk#dictionary#HR_NO_RESULT
let g:eskk#dictionary#HR_LOOK_UP_DICTIONARY = 1
lockvar g:eskk#dictionary#HR_LOOK_UP_DICTIONARY
let g:eskk#dictionary#HR_SEE_ADDED_WORDS = 2
lockvar g:eskk#dictionary#HR_SEE_ADDED_WORDS
let g:eskk#dictionary#HR_GOT_RESULT = 3
lockvar g:eskk#dictionary#HR_GOT_RESULT

" self._dict:
"   Instance of s:dict
" self._key, self._okuri_rom, self._okuri:
"   Query for this henkan result.
" self._status:
"   One of g:eskk#dictionary#HR_*
" self._candidates:
"   Candidates looked up by self._key, self._okuri_rom, self._okuri
"   NOTE:
"   Do not access directly.
"   Getter is s:henkan_result_get_candidates().
" self._candidates_index:
"   Current index of List self._candidates
" self._user_dict_found_index:
"   The lnum of found the candidate in user dictionary.
"   Used by s:henkan_result.delete_from_dict()
let s:henkan_result = {
\   'buftable': {},
\   '_dict': {},
\   '_key': '',
\   '_okuri_rom': '',
\   '_okuri': '',
\   '_status': -1,
\   '_candidates': [],
\   '_candidates_index': -1,
\   '_user_dict_found_index': -1,
\}

function! s:henkan_result_new(dict, key, okuri_rom, okuri, buftable) "{{{
    let added = filter(copy(a:dict._added_words), 'v:val.key ==# a:key && v:val.okuri_rom[0] ==# a:okuri_rom[0]')

    let obj = extend(
    \   deepcopy(s:henkan_result, 1),
    \   {
    \       'buftable': a:buftable,
    \       '_dict': a:dict,
    \       '_key': a:key,
    \       '_okuri_rom': a:okuri_rom,
    \       '_okuri': a:okuri,
    \   },
    \   'force'
    \)
    call s:henkan_result_init(obj, added)
    return obj
endfunction "}}}

function! s:henkan_result_init(this, added) "{{{
    return extend(
    \   a:this,
    \   {
    \       '_status': (empty(a:added) ? g:eskk#dictionary#HR_LOOK_UP_DICTIONARY : g:eskk#dictionary#HR_SEE_ADDED_WORDS),
    \       '_candidates': (empty(a:added) ? [] : s:henkan_result_merge_candidates(map(copy(a:added), 's:candidate_new(s:CANDIDATE_FROM_ADDED_WORDS, v:val.input)'))),
    \       '_candidates_index': 0,
    \   },
    \   'force'
    \)
endfunction "}}}

function! s:henkan_result_advance(this, advance) "{{{
    if has_key(a:this, '_candidate')
        " Delete current candidate cache.
        unlet a:this._candidate
    endif

    try
        let candidates = self._candidates
        let idx = self._candidates_index
        if eskk#util#has_idx(candidates, idx + (a:advance ? 1 : -1))
            " Next time to call s:henkan_result_get_candidates(),
            " eskk will getchar() if `idx >= g:eskk_show_candidates_count`
            let self._candidates_index +=  (a:advance ? 1 : -1)
            return 1
        elseif a:this._status ==# g:eskk#dictionary#HR_SEE_ADDED_WORDS
            let a:this._status = g:eskk#dictionary#HR_LOOK_UP_DICTIONARY
            return s:henkan_result_advance(a:this, a:advance)
        else
            return 0
        endif
        return 0
    catch /^eskk: dictionary look up error:/
        " Shut up error. This function does not throw exception.
        call eskk#util#log_exception('s:henkan_result_get_candidates()')
        return 0
    endtry
endfunction "}}}

function! s:henkan_result_get_candidates(this, ...) "{{{
    let from_hr_see_added_words = a:0 ? a:1 : 0

    if a:this._status ==# g:eskk#dictionary#HR_GOT_RESULT
        call eskk#util#assert(!empty(a:this._candidates), "a:this._candidates must be not empty.")
        return a:this._candidates

    elseif a:this._status ==# g:eskk#dictionary#HR_LOOK_UP_DICTIONARY
        let [user_dict, system_dict] = [a:this._dict._user_dict, a:this._dict._system_dict]
        " Look up this henkan result in dictionaries.
        let user_dict_result = eskk#dictionary#search_candidate(
        \   user_dict, a:this._key, a:this._okuri_rom
        \)
        let system_dict_result = eskk#dictionary#search_candidate(
        \   system_dict, a:this._key, a:this._okuri_rom
        \)
        if user_dict_result[1] ==# -1 && system_dict_result[1] ==# -1
            let a:this._status = g:eskk#dictionary#HR_NO_RESULT
            throw eskk#dictionary_look_up_error(
            \   ['eskk', 'dictionary'],
            \   "Can't look up '"
            \   . g:eskk_marker_henkan
            \   . a:this._key
            \   . g:eskk_marker_okuri
            \   . a:this._okuri_rom
            \   . "' in dictionaries."
            \)
        endif

        " Merge and unique user dict result and system dict result.
        let results = []

        if user_dict_result[1] !=# -1
            let [key, okuri_rom, candidates] = eskk#dictionary#parse_skk_dict_line(user_dict_result[0], s:CANDIDATE_FROM_USER_DICT)
            call eskk#util#assert(key ==# a:this._key, "user dict:".string(key)." ==# ".string(a:this._key))
            call eskk#util#assert(okuri_rom ==# a:this._okuri_rom[0], "user dict:".string(okuri_rom)." ==# ".string(a:this._okuri_rom))
            let results += candidates
        endif

        if system_dict_result[1] !=# -1
            let [key, okuri_rom, candidates] = eskk#dictionary#parse_skk_dict_line(system_dict_result[0], s:CANDIDATE_FROM_SYSTEM_DICT)
            call eskk#util#assert(key ==# a:this._key, "system dict:".string(key)." ==# ".string(a:this._key))
            call eskk#util#assert(okuri_rom ==# a:this._okuri_rom[0], "system dict:".string(okuri_rom)." ==# ".string(a:this._okuri_rom))
            let results += candidates
        endif

        if from_hr_see_added_words
            let results += a:this.candidates
        endif

        let a:this._user_dict_found_index = user_dict_result[1]
        let a:this._status = g:eskk#dictionary#HR_GOT_RESULT
        let a:this._candidates = s:henkan_result_merge_candidates(results)
        return a:this._candidates

    elseif a:this._status ==# g:eskk#dictionary#HR_SEE_ADDED_WORDS
        let candidates = a:this._candidates
        let idx        = a:this._candidates_index
        if eskk#util#has_idx(candidates, idx)
            return candidates
        else
            let a:this._status = g:eskk#dictionary#HR_LOOK_UP_DICTIONARY
            return s:henkan_result_get_candidates(a:this, 1)
        endif

    elseif a:this._status ==# g:eskk#dictionary#HR_NO_RESULT
        throw eskk#dictionary_look_up_error(
        \   ['eskk', 'dictionary'],
        \   "Can't look up '"
        \   . g:eskk_marker_henkan
        \   . a:this._key
        \   . g:eskk_marker_okuri
        \   . a:this._okuri_rom
        \   . "' in dictionaries."
        \)

    else
        throw eskk#internal_error(['eskk', 'dictionary'])
    endif
endfunction "}}}

function! s:henkan_result_select_candidates(this, with_okuri, skip_num, functor) "{{{
    " Select candidates by getchar()'s character.
    let words = copy(s:henkan_result_get_candidates(a:this))
    let word_num_per_page = len(split(g:eskk_select_cand_keys, '\zs'))
    let page_index = 0
    let pages = []

    call eskk#util#assert(len(words) > a:skip_num, "words has more than skip_num words.")
    let words = words[a:skip_num :]

    while !empty(words)
        let words_in_page = []
        " Add words to `words_in_page` as number of
        " string length of `g:eskk_select_cand_keys`.
        for c in split(g:eskk_select_cand_keys, '\zs')
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
            if g:eskk_show_annotation
                echon printf('%s:%s%s  ', c, word.input,
                \       (has_key(word, 'annotation') ? ';' . word.annotation : ''))
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


        if eskk#mappings#is_special_lhs(char, 'phase:henkan-select:escape')
            return a:functor.funcall()
        elseif eskk#mappings#is_special_lhs(char, 'phase:henkan-select:next-page')
            if eskk#util#has_idx(pages, page_index + 1)
                let page_index += 1
            else
                " No more pages. Register new word.
                let input = a:this._dict.register_word(a:this)[0]
                let henkan_buf_str = a:this.buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
                let okuri_buf_str = a:this.buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
                return [
                \   (input != '' ? input : henkan_buf_str.get_matched_filter()),
                \   okuri_buf_str.get_matched_filter()
                \]
            endif
        elseif eskk#mappings#is_special_lhs(char, 'phase:henkan-select:prev-page')
            if eskk#util#has_idx(pages, page_index - 1)
                let page_index -= 1
            else
                return a:functor.funcall()
            endif
        elseif stridx(g:eskk_select_cand_keys, char) != -1
            let selected = g:eskk_select_cand_keys[stridx(g:eskk_select_cand_keys, char)]
            call eskk#util#logf("Selected char '%s'.", selected)
            for [c, word] in pages[page_index]
                if c ==# selected
                    " Dummy result list for `word`.
                    " Note that assigning to index number is useless.
                    return [word.input, (a:with_okuri ? a:this._okuri : '')]
                endif
            endfor
        endif
    endwhile
endfunction "}}}

function! s:henkan_result_merge_candidates(candidates) "{{{
    let candidates = copy(a:candidates)
    if empty(candidates)
        return candidates
    endif
    let unique = {}
    let i = 0
    while i < len(candidates)
        let r = candidates[i]
        let k = r.input . (has_key(r, 'annotation') ? ";" . r.annotation : '')

        if has_key(unique, k)
            call remove(candidates, i)
            " Next element is candidates[i], Don't increment.
            continue
        else
            let unique[k] = r
        endif
        let i += 1
    endwhile
    return candidates
endfunction "}}}


function! s:henkan_result.get_candidate(...) dict "{{{
    let with_okuri = a:0 ? a:1 : 1

    if has_key(self, '_candidate')
        return self._candidate[0] . (with_okuri ? self._candidate[1] : '')
    endif

    call eskk#util#logf('Get candidate for: buftable.dump() = %s', string(self.buftable.dump()))
    let counter = g:eskk_show_candidates_count >= 0 ? g:eskk_show_candidates_count : 0

    let candidates = s:henkan_result_get_candidates(self)
    let idx = self._candidates_index
    call eskk#util#logf('idx = %d, counter = %d', idx, counter)

    if idx >= counter
        let functor = {'candidates': candidates, 'idx': idx, 'this': self, 'with_okuri': with_okuri}
        function functor.funcall()
            if self.idx > 0
                call self.this.back()
            endif
            return [
            \   self.candidates[self.idx].input,
            \   (self.with_okuri ? self.this._okuri : '')
            \]
        endfunction

        let self._candidate = s:henkan_result_select_candidates(self, with_okuri, counter, functor)
    else
        let self._candidate = [candidates[idx].input, (with_okuri ? self._okuri : '')]
    endif

    return self._candidate[0] . (with_okuri ? self._candidate[1] : '')
endfunction "}}}
function! s:henkan_result.get_key() dict "{{{
    return self._key
endfunction "}}}
function! s:henkan_result.get_okuri() dict "{{{
    return self._okuri
endfunction "}}}
function! s:henkan_result.get_okuri_rom() dict "{{{
    return self._okuri_rom
endfunction "}}}
function! s:henkan_result.get_status() dict "{{{
    return self._status
endfunction "}}}

function! s:henkan_result.advance() dict "{{{
    return s:henkan_result_advance(self, 1)
endfunction "}}}

function! s:henkan_result.back() dict "{{{
    return s:henkan_result_advance(self, 0)
endfunction "}}}

function! s:henkan_result.delete_from_dict() dict "{{{
    if self._status !=# g:eskk#dictionary#HR_GOT_RESULT
        return
    endif
    let candidates = s:henkan_result_get_candidates(self)
    let candidates_index = self._candidates_index
    let user_dict_idx = self._user_dict_found_index

    if !eskk#util#has_idx(candidates, candidates_index)
        return
    endif

    let user_dict_lines = self._dict._user_dict.get_lines()
    if !self._dict._user_dict.is_valid()
        return
    endif

    " Dialog
    let input = eskk#util#input('Really purge? (yes/no)')
    if input !~? '^y\%[es]$'
        return
    endif

    " NOTE: user_dict_idx is -1
    " when the current candidate is from added words.
    if !eskk#util#has_idx(user_dict_lines, user_dict_idx)
        " Remove current candidate from added words.
        for i in range(len(self._dict._added_words))
            if candidates[candidates_index].input ==# self._dict._added_words[i].input
                call remove(candidates, candidates_index)
                call remove(self._dict._added_words, i)
            endif
        endfor
        return
    endif

    call remove(user_dict_lines, user_dict_idx)

    try
        call self._dict._user_dict.set_lines(user_dict_lines)
    catch /^eskk: parse error/
        return
    endtry

    if g:eskk_debug
        call eskk#util#logstrf('Removed from dict: %s', user_dict_lines[user_dict_idx])
        call eskk#util#logstrf('Removed from dict: %s', candidates[idx])
    endif

    call s:henkan_result_init(self, copy(self._dict._added_words))

    redraw
    call self._dict.update_dictionary()
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
\   '_ftime_at_read': 0,
\   '_loaded': 0,
\   'okuri_ari_idx': -1,
\   'okuri_nasi_idx': -1,
\   'path': '',
\   'sorted': 0,
\   'encoding': '',
\   '_is_modified': 0,
\}

function! s:physical_dict_new(path, sorted, encoding) "{{{
    return extend(
    \   deepcopy(s:physical_dict, 1),
    \   {'path': expand(a:path), 'sorted': a:sorted, 'encoding': a:encoding},
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



function! s:physical_dict.get_lines(...) dict "{{{
    let force = a:0 ? a:1 : 0

    if self._loaded && self._ftime_at_read ==# getftime(self.path) && !force
        return self._content_lines
    endif

    let path = self.path
    try
        call eskk#util#logf('reading %s...', path)
        let self._content_lines  = readfile(path)
        call eskk#util#logf('reading %s... - done.', path)

        call eskk#util#logf('parsing %s...', path)
        call s:physical_dict_parse_lines(self, self._content_lines)
        call eskk#util#logf('parsing %s... - done.', path)

        let self._ftime_at_read = getftime(path)
        let self._loaded = 1
    catch /E484:/    " Can't open file
        call eskk#util#logf("Can't read '%s'!", path)
    catch /^eskk: parse error/
        call eskk#util#log_exception('s:physical_dict.get_lines()')
        let self.okuri_ari_idx = -1
        let self.okuri_nasi_idx = -1
    endtry

    return self._content_lines
endfunction "}}}

function! s:physical_dict.set_lines(lines) dict "{{{
    try
        let self._content_lines  = a:lines
        call s:physical_dict_parse_lines(self, a:lines)
        let self._loaded = 1
        let self._is_modified = 1
    catch /^eskk: parse error/
        call eskk#util#log_exception('s:physical_dict.set_lines()')
        let self.okuri_ari_idx = -1
        let self.okuri_nasi_idx = -1
    endtry
endfunction "}}}

function! s:physical_dict_parse_lines(self, lines) "{{{
    let self = a:self

    let self.okuri_ari_idx  = index(self._content_lines, ';; okuri-ari entries.')
    if self.okuri_ari_idx ==# -1
        throw eskk#parse_error(['eskk', 'dictionary'], "SKK dictionary parse error")
    endif
    let self.okuri_nasi_idx = index(self._content_lines, ';; okuri-nasi entries.')
    if self.okuri_nasi_idx ==# -1
        throw eskk#parse_error(['eskk', 'dictionary'], "SKK dictionary parse error")
    endif
    if self.okuri_ari_idx >= self.okuri_nasi_idx
        throw eskk#parse_error(['eskk', 'dictionary'], "SKK dictionary parse error: okuri-ari entries must be before okuri-nasi entries.")
    endif
endfunction "}}}

function! s:physical_dict.is_valid() dict "{{{
    " Succeeded to parse SKK dictionary.
    return self.okuri_ari_idx >= 0 && self.okuri_nasi_idx >= 0
endfunction "}}}

lockvar s:physical_dict
" }}}

" s:registered_word: eskk#dictionary#registered_word_new() {{{

function! eskk#dictionary#registered_word_new(input, key, okuri, okuri_rom) "{{{
    return {
    \   'input': a:input,
    \   'key': a:key,
    \   'okuri': a:okuri,
    \   'okuri_rom': a:okuri_rom,
    \}
endfunction "}}}

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
\   '_user_dict': {},
\   '_system_dict': {},
\   '_added_words': [],
\   '_added_words_modified': 0,
\}

function! eskk#dictionary#new(user_dict, system_dict) "{{{
    return extend(
    \   deepcopy(s:dict, 1),
    \   {
    \       '_user_dict': s:physical_dict_new(
    \           a:user_dict.path,
    \           a:user_dict.sorted,
    \           a:user_dict.encoding,
    \       ),
    \       '_system_dict': s:physical_dict_new(
    \           a:system_dict.path,
    \           a:system_dict.sorted,
    \           a:system_dict.encoding,
    \       ),
    \   },
    \   'force'
    \)
endfunction "}}}


function! s:dict.refer(buftable, key, okuri, okuri_rom) dict "{{{
    return s:henkan_result_new(
    \   self,
    \   a:key,
    \   a:okuri_rom,
    \   a:okuri,
    \   deepcopy(a:buftable, 1),
    \)
endfunction "}}}

function! s:dict.register_word(henkan_result) dict "{{{
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
            let prompt = printf('%s%s%s ', key, g:eskk_marker_okuri, okuri)
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
        call self.remember_registered_word(eskk#dictionary#registered_word_new(input, key, okuri, okuri_rom))
    endif
    return [input, key, okuri]
endfunction "}}}

function! s:dict.forget_registered_words() dict "{{{
    let self._added_words = []
endfunction "}}}

function! s:dict.remember_registered_word(registered_word) dict "{{{
    call add(self._added_words, a:registered_word)
    let self._added_words_modified = 1
endfunction "}}}

function! s:dict.is_modified() dict "{{{
    " No need to check system dictionary.
    " Because it is immutable.
    return
    \   self._added_words_modified
    \   || self._user_dict._is_modified
endfunction "}}}
function! s:dict_clear_modified_flags(this) "{{{
    let a:this._added_words_modified = 0
    let a:this._user_dict._is_modified = 0
endfunction "}}}

function! s:dict.update_dictionary() dict "{{{
    if !self.is_modified()
        return
    endif

    let user_dict_exists = filereadable(self._user_dict.path)
    let user_dict_lines = self._user_dict.get_lines()
    if user_dict_exists
        if empty(user_dict_lines)
            " user dictionary exists but .get_lines() returned empty list.
            " format is invalid.

            " TODO:
            " Echo "user dictionary format is invalid. overwrite with new words?".
            " And do not read, just overwrite it with new words.
            return
        endif
    else
        " Create new lines.
        let user_dict_lines = [';; okuri-ari entries.', ';; okuri-nasi entries.']
        call self._user_dict.set_lines(user_dict_lines)
        " NOTE: .set_lines() does not write to dictionary.
        " Because at this time dictionary file does not exist.
    endif

    call s:dict_write_to_file(self)
    call s:dict_clear_modified_flags(self)
endfunction "}}}
function! s:dict_write_to_file(this) "{{{
    let user_dict_lines = deepcopy(a:this._user_dict.get_lines())

    " Check if a:this.user_dict really does not have added words.
    for w in a:this._added_words
        let [line, index] = eskk#dictionary#search_candidate(a:this._user_dict, w.key, w.okuri_rom)
        if w.okuri_rom != ''
            let lnum = a:this._user_dict.okuri_ari_idx + 1
        else
            let lnum = a:this._user_dict.okuri_nasi_idx + 1
        endif
        " Delete old entry.
        if index !=# -1
            call remove(user_dict_lines, index)
            call eskk#util#assert(line != '')
        endif
        " Merge old one and create new entry.
        call insert(
        \   user_dict_lines,
        \   eskk#dictionary#create_new_entry(w.input, w.key, w.okuri, w.okuri_rom, line),
        \   lnum
        \)
    endfor

    let save_msg = printf("Saving to '%s'...", a:this._user_dict.path)
    echo save_msg

    let ret_success = 0
    try
        if writefile(user_dict_lines, a:this._user_dict.path) ==# ret_success
            redraw
            echo save_msg . 'Done.'
        else
            let msg = printf("can't write to '%s'.", a:this._user_dict.path)
            throw eskk#internal_error(['eskk', 'dictionary'], msg)
        endif
    catch
        redraw
        echohl WarningMsg
        echomsg save_msg . "Error. Please check permission of"
        \    "'" . a:this._user_dict.path . "' - " . v:exception
        echohl None
    endtry
endfunction "}}}

function! s:dict.search(key, okuri, okuri_rom) dict "{{{
    let key = a:key
    let okuri = a:okuri
    let okuri_rom = a:okuri_rom

    if key == ''
        return []
    endif

    " To unique candidates.
    let candidates = {}

    for w in self._added_words
        if w.key ==# key
            let k = w.key . w.okuri_rom
            if !has_key(candidates, k)
                let candidates[k] =
                \   [len(candidates), s:candidate_new(s:CANDIDATE_FROM_ADDED_WORDS, w.input)]
            endif
        endif
    endfor

    for [dict, from_type] in [
    \   [self._user_dict, s:CANDIDATE_FROM_USER_DICT],
    \   [self._system_dict, s:CANDIDATE_FROM_SYSTEM_DICT],
    \]
        for line in eskk#dictionary#search_all_candidates(dict, key, okuri_rom, g:eskk_candidates_max - len(candidates))
            if len(candidates) >= g:eskk_candidates_max
                break
            endif
            let [line_key, line_okuri_rom, list] = eskk#dictionary#parse_skk_dict_line(line, from_type)
            let k = line_key . line_okuri_rom
            if !has_key(candidates, k)
                let candidates[k] = [len(candidates), list]
            endif
        endfor
    endfor

    return [key, okuri_rom] + map(sort(values(candidates), 's:sort_fn_by_head_nr'), 'v:val[1]')
endfunction "}}}

function! s:sort_fn_by_head_nr(a, b) "{{{
    let [a, b] = [a:a[0], a:b[0]]
    return a ==# b ? 0 : a ># b ? 1 : -1
endfunction "}}}

lockvar s:dict
" }}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

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
let s:search_all_candidate_memoize = {}
function! eskk#dictionary#search_all_candidates(physical_dict, key_filter, okuri_rom, ...) "{{{
    let limit = a:0 ? a:1 : -1    " No limit by default.
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '')

    let cache_key = a:physical_dict.get_ftime_at_read() . a:physical_dict.path . a:key_filter . a:okuri_rom . limit
    if has_key(s:search_all_candidate_memoize, cache_key)
        return s:search_all_candidate_memoize[cache_key]
    endif

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

        let [line, idx] = s:search_binary(a:physical_dict, whole_lines, converted, has_okuri, 100)

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
        call eskk#util#assert(begin <= end)
        if limit >= 0 && begin + limit < end
            let end = begin + limit
        endif

        let s:search_all_candidate_memoize[cache_key] =
                    \ map(whole_lines[begin : end],
                    \   's:iconv(v:val, a:physical_dict.encoding, &l:encoding)'
                    \)
    else
        call eskk#util#log('dictionary is *not* sorted. Try linear search....')

        let lines = []
        let start = 1
        while 1
            let [line, idx] = s:search_linear(a:physical_dict, whole_lines, converted, has_okuri, start)

            if idx == -1
                break
            endif

            call add(lines, line)
            let start = idx + 1
        endwhile

        let s:search_all_candidate_memoize[cache_key] =
                    \ map(lines, 's:iconv(v:val, a:physical_dict.encoding, &l:encoding)')
    endif

    return s:search_all_candidate_memoize[cache_key]
endfunction "}}}

" Returns [line_string, idx] matching the candidate.
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
        let [line, idx] = s:search_binary(a:physical_dict, whole_lines, converted, has_okuri, 100)
    else
        call eskk#util#log('dictionary is *not* sorted. Try linear search....')
        let [line, idx] = s:search_linear(a:physical_dict, whole_lines, converted, has_okuri)
    endif
    if idx !=# -1
        let conv_line = s:iconv(line, a:physical_dict.encoding, &l:encoding)
        call eskk#util#logstrf('eskk#dictionary#search_candidate() - found!: %s', conv_line)
        return [conv_line, idx]
    else
        call eskk#util#log('eskk#dictionary#search_candidate() - not found.')
        return ['', -1]
    endif
endfunction "}}}
" Returns [line_string, idx] matching the candidate.
function! s:search_binary(ph_dict, whole_lines, needle, has_okuri, limit) "{{{
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    " NOTE: min, max, mid are index number. not lnum.

    let min = a:has_okuri ? a:ph_dict.okuri_ari_idx : a:ph_dict.okuri_nasi_idx
    let max = a:has_okuri ? a:ph_dict.okuri_nasi_idx : len(a:whole_lines) - 1
    " call eskk#util#logf('s:search_binary(): Initial: min = %d, max = %d', min, max)

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
    return s:search_linear(a:ph_dict, a:whole_lines, a:needle, a:has_okuri, min, max)
endfunction "}}}
" Returns [line_string, idx] matching the candidate.
function! s:search_linear(ph_dict, whole_lines, needle, has_okuri, ...) "{{{
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    let min = get(a:000, 0, a:ph_dict[a:has_okuri ? 'okuri_ari_idx' : 'okuri_nasi_idx'])
    let max = get(a:000, 1, len(a:whole_lines) - 1)

    call eskk#util#assert(min <=# max, 'min <=# max')
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
    let has_okuri = okuri_rom != ''

    let candidates = []
    for _ in list[1:]
        let semicolon = stridx(_, ';')
        call add(
        \   candidates,
        \   semicolon != -1 ?
        \       s:candidate_new(a:from_type, _[: semicolon - 1], has_okuri, _[semicolon + 1 :]) :
        \       s:candidate_new(a:from_type, _, has_okuri)
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
let s:CANDIDATE_FROM_REGISTERED_WORDS = 2
lockvar s:CANDIDATE_FROM_USER_DICT s:CANDIDATE_FROM_SYSTEM_DICT s:CANDIDATE_FROM_REGISTERED_WORDS

function! s:candidate_new(from_type, input, has_okuri, ...) "{{{
    let obj = {'from_type': a:from_type, 'input': a:input, 'has_okuri': a:has_okuri}

    if a:0
        let obj.annotation = a:1
    endif

    return obj
endfunction "}}}

function! s:candidate_make_key(candidate) "{{{
    return
    \   a:candidate.input
    \   . (has_key(a:candidate, 'annotation') ? ';' . a:candidate.annotation : '')
endfunction "}}}

" }}}

" s:registered_word: s:registered_word_new() {{{

function! s:registered_word_new(input, key, okuri, okuri_rom) "{{{
    return {
    \   'input': a:input,
    \   'key': a:key,
    \   'okuri': a:okuri,
    \   'okuri_rom': a:okuri_rom,
    \}
endfunction "}}}

function! s:registered_word_make_key_from_members(input, key, okuri, okuri_rom) "{{{
    return join([a:input, a:key, a:okuri, a:okuri_rom], ';')
endfunction "}}}

" }}}

" s:uniqued_array {{{
let s:uniqued_array = {'_elements': {}, '_counter': 0}

function! s:uniqued_array_new() "{{{
    return deepcopy(s:uniqued_array)
endfunction "}}}

function s:uniqued_array.merge(key, elem, ...) "{{{
    if has_key(self._elements, a:key)
        let overwrite = a:0 ? a:1 : 1
        if overwrite
            let self._elements[a:key][1] = a:elem
        endif
    else
        let self._elements[a:key] = [self._counter, a:elem]
        let self._counter += 1
    endif
endfunction "}}}

function! s:uniqued_array.get_length() "{{{
    return len(self._elements)
endfunction "}}}

function! s:uniqued_array.get() "{{{
    return eskk#util#flatten(
    \   map(
    \       sort(
    \           values(self._elements),
    \           's:sort_fn_by_head_nr'
    \       ),
    \       'v:val[1]'
    \   )
    \)
endfunction "}}}

function! s:sort_fn_by_head_nr(a, b) "{{{
    let [a, b] = [a:a[0], a:b[0]]
    return a ==# b ? 0 : a ># b ? 1 : -1
endfunction "}}}

function! s:uniqued_array.has(key) "{{{
    return has_key(self._elements, a:key)
endfunction "}}}

function! s:uniqued_array.clear() "{{{
    let self._elements = {}
    let self._counter = 0
endfunction "}}}

function! s:uniqued_array.remove(key) "{{{
    if has_key(self._elements, a:key)
        unlet self._elements[a:key]
    endif
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
let g:eskk#dictionary#HR_GOT_RESULT = 2
lockvar g:eskk#dictionary#HR_GOT_RESULT

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
\   '_key': '',
\   '_okuri_rom': '',
\   '_okuri': '',
\   '_status': -1,
\   '_candidates': {},
\   '_candidates_index': -1,
\   '_user_dict_found_index': -1,
\}

function! s:henkan_result_new(key, okuri_rom, okuri, buftable) "{{{
    let obj = extend(
    \   deepcopy(s:henkan_result, 1),
    \   {
    \       'buftable': a:buftable,
    \       '_key': a:key,
    \       '_okuri_rom': a:okuri_rom,
    \       '_okuri': a:okuri,
    \   },
    \   'force'
    \)
    call s:henkan_result_reset(obj)
    return obj
endfunction "}}}

" Reset candidates.
" After calling this function,
" s:henkan_result_get_candidates() will look up dictionary again.
function! s:henkan_result_reset(this) "{{{
    call extend(
    \   a:this,
    \   {
    \       '_status': g:eskk#dictionary#HR_LOOK_UP_DICTIONARY,
    \       '_candidates': s:uniqued_array_new(),
    \       '_candidates_index': 0,
    \   },
    \   'force'
    \)
    call s:henkan_result_remove_cache(a:this)

    call eskk#util#logstrf('re-initialized henkan result: a:this._key = %s, a:this._okuri = %s, a:this._okuri_rom = %s', a:this._key, a:this._okuri, a:this._okuri_rom)
endfunction "}}}

" Forward/Back self._candidates_index safely
" Returns true value when succeeded / false value when failed
function! s:henkan_result_advance(this, advance) "{{{
    call s:henkan_result_remove_cache(a:this)

    try
        let candidates = s:henkan_result_get_candidates(a:this)
        let idx = a:this._candidates_index
        if eskk#util#has_idx(candidates, idx + (a:advance ? 1 : -1))
            " Next time to call s:henkan_result_get_candidates(),
            " eskk will getchar() if `idx >= g:eskk_show_candidates_count`
            let a:this._candidates_index +=  (a:advance ? 1 : -1)
            return 1
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

" Returns List of candidates.
function! s:henkan_result_get_candidates(this) "{{{
    if a:this._status ==# g:eskk#dictionary#HR_GOT_RESULT
        return a:this._candidates.get()

    elseif a:this._status ==# g:eskk#dictionary#HR_LOOK_UP_DICTIONARY
        call eskk#util#logstrf('s:henkan_result_get_candidates(): Look up dictionary for: a:this._key = %s, a:this._okuri = %s, a:this._okuri_rom = %s', a:this._key, a:this._okuri, a:this._okuri_rom)

        let dict = eskk#dictionary#get_instance()
        let [user_dict, system_dict] = [dict.get_user_dict(), dict.get_system_dict()]
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

        if user_dict_result[1] !=# -1
            let [key, okuri_rom, candidates] = eskk#dictionary#parse_skk_dict_line(user_dict_result[0], s:CANDIDATE_FROM_USER_DICT)
            call eskk#util#assert(key ==# a:this._key, "user dict:".string(key)." ==# ".string(a:this._key))
            call eskk#util#assert(okuri_rom ==# a:this._okuri_rom[0], "user dict:".string(okuri_rom)." ==# ".string(a:this._okuri_rom))

            for c in candidates
                call a:this._candidates.merge(s:candidate_make_key(c), c)
            endfor
        endif

        if system_dict_result[1] !=# -1
            let [key, okuri_rom, candidates] = eskk#dictionary#parse_skk_dict_line(system_dict_result[0], s:CANDIDATE_FROM_SYSTEM_DICT)
            call eskk#util#assert(key ==# a:this._key, "system dict:".string(key)." ==# ".string(a:this._key))
            call eskk#util#assert(okuri_rom ==# a:this._okuri_rom[0], "system dict:".string(okuri_rom)." ==# ".string(a:this._okuri_rom))

            for c in candidates
                call a:this._candidates.merge(s:candidate_make_key(c), c)
            endfor
        endif

        " Merge registered words.
        let registered = filter(copy(dict.get_registered_words()), 'v:val.key ==# a:this._key && v:val.okuri_rom[0] ==# a:this._okuri_rom[0]')
        call eskk#util#logstrf('s:henkan_result_get_candidates(): Gathering matched registered words: %s', registered)
        if !empty(registered)
            for rw in registered
                let c = s:candidate_new(s:CANDIDATE_FROM_REGISTERED_WORDS, rw.input, rw.okuri_rom != "")
                call a:this._candidates.merge(rw.input, c)
            endfor
        endif

        let a:this._user_dict_found_index = user_dict_result[1]
        let a:this._status = g:eskk#dictionary#HR_GOT_RESULT

        return a:this._candidates.get()

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

" Select candidate from command-line.
function! s:henkan_result_select_candidates(this, with_okuri, skip_num, functor) "{{{
    if eskk#is_neocomplcache_locked()
        NeoComplCacheUnlock
    endif

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
                let dict = eskk#dictionary#get_instance()
                let input = dict.register_word(a:this)[0]
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

" Clear cache of current candidate.
function! s:henkan_result_remove_cache(this) "{{{
    if has_key(a:this, '_candidate')
        unlet a:this._candidate
    endif
endfunction "}}}


" Returns candidate String.
" if optional {with_okuri} arguments are supplied,
" returns candidate String with okuri.
function! s:henkan_result.get_candidate(...) "{{{
    let with_okuri = a:0 ? a:1 : 1

    if has_key(self, '_candidate')
        return self._candidate[0] . (with_okuri ? self._candidate[1] : '')
    endif

    let max_count = g:eskk_show_candidates_count >= 0 ? g:eskk_show_candidates_count : 0

    let candidates = s:henkan_result_get_candidates(self)

    if g:eskk_debug
        call eskk#util#logf('Get candidate for: buftable.dump() = %s', string(self.buftable.dump()))
        call eskk#util#logstrf('s:henkan_result_get_candidates(): candidates = %s', candidates)
        call eskk#util#logstrf('self._candidates_index = %d, max_count = %d', self._candidates_index, max_count)
    endif

    if self._candidates_index >= max_count
        let functor = {'candidates': candidates, 'this': self, 'with_okuri': with_okuri}
        function functor.funcall()
            if self.this._candidates_index > 0
                " This changes self.this._candidates_index.
                call self.this.back()
            endif
            return [
            \   self.candidates[self.this._candidates_index].input,
            \   (self.with_okuri ? self.this._okuri : '')
            \]
        endfunction

        let self._candidate = s:henkan_result_select_candidates(self, with_okuri, max_count, functor)
    else
        let self._candidate = [
        \   candidates[self._candidates_index].input,
        \   (with_okuri ? self._okuri : '')
        \]
    endif

    return self._candidate[0] . (with_okuri ? self._candidate[1] : '')
endfunction "}}}
" Getter for self._key
function! s:henkan_result.get_key() "{{{
    return self._key
endfunction "}}}
" Getter for self._okuri
function! s:henkan_result.get_okuri() "{{{
    return self._okuri
endfunction "}}}
" Getter for self._okuri_rom
function! s:henkan_result.get_okuri_rom() "{{{
    return self._okuri_rom
endfunction "}}}
" Getter for self._status
function! s:henkan_result.get_status() "{{{
    return self._status
endfunction "}}}

" Forward current candidate index number (self._candidates_index)
function! s:henkan_result.forward() "{{{
    return s:henkan_result_advance(self, 1)
endfunction "}}}
" Back current candidate index number (self._candidates_index)
function! s:henkan_result.back() "{{{
    return s:henkan_result_advance(self, 0)
endfunction "}}}

" Delete current candidate from all places.
" e.g.:
" - s:skk_dict_instance._registered_words
" - self._candidates
" - SKK dictionary
" -- User dictionary
" -- TODO: System dictionary (skk-ignore-dic-word) (Issue #86)
function! s:henkan_result.delete_from_dict() "{{{
    try
        return s:henkan_result_delete_from_dict(self)
    finally
        let dict = eskk#dictionary#get_instance()
        call dict.clear_henkan_result()
    endtry
endfunction "}}}
function! s:henkan_result_delete_from_dict(this) "{{{
    call eskk#util#log('s:henkan_result.delete_from_dict()')

    let candidates = s:henkan_result_get_candidates(a:this)
    let candidates_index = a:this._candidates_index
    let user_dict_idx = a:this._user_dict_found_index

    if !eskk#util#has_idx(candidates, candidates_index)
        call eskk#util#log('.delete_from_dict(): candidates_index is out of range')
        return
    endif

    let dict = eskk#dictionary#get_instance()
    let user_dict_lines = dict.get_user_dict().get_lines()
    if !dict.get_user_dict().is_valid()
        call eskk#util#log('.delete_from_dict(): user dictionary is invalid.')
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
        call eskk#util#log('.delete_from_dict(): user input "' . input . '".')
        return
    endif

    if candidates[candidates_index].from_type ==# s:CANDIDATE_FROM_REGISTERED_WORDS
        " Remove all elements matching with current candidate from registered words.
        let words = dict.get_registered_words()
        for i in range(len(words))
            if candidates[candidates_index].input ==# words[i].input
                call dict.remove_registered_word(words[i].input, words[i].key, words[i].okuri, words[i].okuri_rom)
            endif
        endfor
        call eskk#util#log('.delete_from_dict(): removed candidates from registered words.')
        return
    endif

    call remove(user_dict_lines, user_dict_idx)
    try
        call dict.get_user_dict().set_lines(user_dict_lines)
    catch /^eskk: parse error/
        call eskk#util#log('.delete_from_dict(): removed the line so parse error occurred')
        return
    endtry

    if g:eskk_debug
        call eskk#util#logstrf('Removed from dict: %s', user_dict_lines[user_dict_idx])
        call eskk#util#logstrf('Removed from dict: %s', candidates[candidates_index])
    endif

    call s:henkan_result_reset(a:this)

    redraw
    call dict.update_dictionary()
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



" Get List of whole lines of dictionary.
function! s:physical_dict.get_lines(...) "{{{
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

" Set List of whole lines of dictionary.
function! s:physical_dict.set_lines(lines) "{{{
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

" - Validate List of whole lines of dictionary.
" - Set self.okuri_ari_idx, self.okuri_nasi_idx.
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

" Returns true value if "self.okuri_ari_idx" and
" "self.okuri_nasi_idx" is valid range.
function! s:physical_dict.is_valid() "{{{
    " Succeeded to parse SKK dictionary.
    return self.okuri_ari_idx >= 0 && self.okuri_nasi_idx >= 0
endfunction "}}}

" Get self._ftime_at_read.
" See self._ftime_at_read description at "s:physical_dict".
function! s:physical_dict.get_ftime_at_read() "{{{
    return self._ftime_at_read
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

" _user_dict:
"   User dictionary.
"
" _system_dict:
"   System dictionary.
"
" _registered_words:
"   s:uniqued_array object.
"
" _current_henkan_result:
"   Current henkan result.

let s:dict = {
\   '_user_dict': {},
\   '_system_dict': {},
\   '_registered_words': {},
\   '_registered_words_modified': 0,
\   '_current_henkan_result': {},
\}

function! s:dict_new(user_dict, system_dict) "{{{
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
    \       '_registered_words': s:uniqued_array_new(),
    \   },
    \   'force'
    \)
endfunction "}}}

let s:skk_dict_instance = {}

function! eskk#dictionary#get_instance() "{{{
    if empty(s:skk_dict_instance)
        let s:skk_dict_instance = s:dict_new(g:eskk_dictionary, g:eskk_large_dictionary)
    endif
    return s:skk_dict_instance
endfunction "}}}


" Find matching candidates from all places.
"
" This actually just sets "self._current_henkan_result"
" which is "s:henkan_result"'s instance.
" This is interface so s:henkan_result is implementation.
function! s:dict.refer(buftable, key, okuri, okuri_rom) "{{{
    let hr = s:henkan_result_new(
    \   a:key,
    \   a:okuri_rom,
    \   a:okuri,
    \   deepcopy(a:buftable, 1),
    \)
    let self._current_henkan_result = hr
    return hr
endfunction "}}}

" Register new word (registered word) at command-line.
function! s:dict.register_word(henkan_result) "{{{
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
        call self.remember_registered_word(input, key, okuri, okuri_rom)
    endif
    return [input, key, okuri]
endfunction "}}}

" Clear current registered words.
function! s:dict.forget_registered_words() "{{{
    call self._registered_words.clear()
endfunction "}}}

" Add registered word.
function! s:dict.remember_registered_word(input, key, okuri, okuri_rom) "{{{
    let id = s:registered_word_make_key_from_members(a:input, a:key, a:okuri, a:okuri_rom)
    if self._registered_words.has(id)
        return
    endif

    call self._registered_words.merge(id, s:registered_word_new(a:input, a:key, a:okuri, a:okuri_rom))
    let self._registered_words_modified = 1

    if !empty(self._current_henkan_result)
        call s:henkan_result_reset(self._current_henkan_result)
    endif

    if g:eskk_debug
        call eskk#util#logstrf('registered word: %s', self._registered_words.get())
    endif
endfunction "}}}

" Get List of registered words.
function! s:dict.get_registered_words() "{{{
    return self._registered_words.get()
endfunction "}}}

" Remove registered word matching with arguments values.
function! s:dict.remove_registered_word(input, key, okuri, okuri_rom) "{{{
    call self._registered_words.remove(
    \   s:registered_word_make_key_from_members(a:input, a:key, a:okuri, a:okuri_rom)
    \)
endfunction "}}}

" Returns true value if new registered is added
" or user dictionary's lines are modified by "s:physical_dict_new.set_lines()".
" If this value is false, s:dict.update_dictionary() does nothing.
function! s:dict.is_modified() "{{{
    " No need to check system dictionary.
    " Because it is immutable.
    return
    \   self._registered_words_modified
    \   || self._user_dict._is_modified
endfunction "}}}

" After calling this function,
" s:dict.is_modified() will returns false.
" but after calling "s:physical_dict_new.set_lines()",
" s:dict.is_modified() will returns true.
function! s:dict_clear_modified_flags(this) "{{{
    let a:this._registered_words_modified = 0
    let a:this._user_dict._is_modified = 0
endfunction "}}}

" Write to user dictionary.
" By default, This function is executed at VimLeavePre.
function! s:dict.update_dictionary() "{{{
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
    call self.forget_registered_words()
    call s:dict_clear_modified_flags(self)
endfunction "}}}
function! s:dict_write_to_file(this) "{{{
    let user_dict_lines = deepcopy(a:this._user_dict.get_lines())

    " Check if a:this._user_dict really does not have registered words.
    for w in a:this._registered_words.get()
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

let s:dict_search_candidates = s:uniqued_array_new()
function! s:dict.search(key, okuri, okuri_rom) "{{{
    let key = a:key
    let okuri = a:okuri
    let okuri_rom = a:okuri_rom

    if key == ''
        return []
    endif

    " To unique candidates.
    let candidates = s:dict_search_candidates
    call candidates.clear()
    let max_count = g:eskk_max_candidates

    " self._registered_words
    for w in self._registered_words.get()
        if w.key ==# key && w.okuri_rom[0] ==# okuri_rom[0] && !candidates.has(w.input)
            call candidates.merge(
            \   w.input,
            \   s:candidate_new(
            \       s:CANDIDATE_FROM_REGISTERED_WORDS,
            \       w.input,
            \       w.okuri_rom != ""
            \   )
            \)
            if candidates.get_length() >= max_count
                break
            endif
        endif
    endfor

    if candidates.get_length() < max_count
        " User dictionary, System dictionary
        try
            for [dict, from_type] in [
            \   [self._user_dict, s:CANDIDATE_FROM_USER_DICT],
            \   [self._system_dict, s:CANDIDATE_FROM_SYSTEM_DICT],
            \]
                for line in eskk#dictionary#search_all_candidates(
                \   dict, key, okuri_rom, max_count - candidates.get_length()
                \)
                    for c in eskk#dictionary#parse_skk_dict_line(line, from_type)[2]
                        if !candidates.has(c.input)
                            call candidates.merge(
                            \   c.input,
                            \   s:candidate_new(
                            \       s:CANDIDATE_FROM_REGISTERED_WORDS,
                            \       c.input,
                            \       okuri_rom != ""
                            \   )
                            \)
                            if candidates.get_length() >= max_count
                                throw 'break'
                            endif
                        endif
                    endfor
                endfor
            endfor
        catch /^break$/
        endtry
    endif

    return [key, okuri_rom, candidates.get()]
endfunction "}}}


" Getter for self._current_henkan_result
function! s:dict.get_henkan_result() "{{{
    return self._current_henkan_result
endfunction "}}}
" Getter for self._user_dict
function! s:dict.get_user_dict() "{{{
    return self._user_dict
endfunction "}}}
" Getter for self._system_dict
function! s:dict.get_system_dict() "{{{
    return self._system_dict
endfunction "}}}

" Clear self._current_henkan_result
function! s:dict.clear_henkan_result() "{{{
    let self._current_henkan_result = {}
endfunction "}}}

lockvar s:dict
" }}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

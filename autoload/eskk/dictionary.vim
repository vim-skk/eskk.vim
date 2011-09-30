" vim:foldmethod=marker:fen:sw=4:sts=4
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



" Utility functions {{{

" Returns [key, okuri_rom, candidates] which line contains.
function! eskk#dictionary#parse_skk_dict_line(line, from_type) "{{{
    let list = split(a:line, '/')
    call eskk#util#assert(
    \   !empty(list),
    \   'list must not be empty. (a:line = '
    \   .string(a:line).')')
    let key = matchstr(list[0], '^[^a-z ]\+')
    let okuri_rom = matchstr(list[0], '[a-z]\+')

    let candidates = []
    for _ in list[1:]
        let semicolon = stridx(_, ';')
        if semicolon != -1
            let c = s:candidate_new(
            \   a:from_type,
            \   _[: semicolon - 1],
            \   key,
            \   okuri_rom[0],
            \   _[semicolon + 1 :]
            \)
        else
            let c = s:candidate_new(
            \   a:from_type,
            \   _,
            \   key,
            \   okuri_rom[0],
            \   ''
            \)
        endif
        call add(candidates, c)
    endfor

    return candidates
endfunction "}}}

" Returns line (String) which includes a:candidate.
" If invalid arguments were given, returns empty string.
function! s:add_candidate_to_line(line, candidate) "{{{
    if a:line =~# '^\s*;'
        return ''
    endif
    let candidates =
    \   eskk#dictionary#parse_skk_dict_line(
    \       line, a:candidate.from_type)
    call add(candidates, a:candidate)
    return s:make_line_from_candidates(candidates)
endfunction "}}}

" Returns line (String) which DOES NOT includes a:candidate.
" If invalid arguments were given, returns empty string.
function! s:delete_candidate_from_line(line, candidate) "{{{
    if a:line =~# '^\s*;'
        return ''
    endif

    let candidates =
    \   eskk#dictionary#parse_skk_dict_line(
    \       a:line, a:candidate.from_type)
    " XXX: Should we see `a:candidate.annotation`?
    let not_match =
    \   '!(v:val.input ==# a:candidate.input'
    \   . '&& v:val.key ==# a:candidate.key'
    \   . '&& v:val.okuri_rom_first ==# a:candidate.okuri_rom_first)'
    call filter(candidates, not_match)
    return s:make_line_from_candidates(candidates)
endfunction "}}}
function! s:make_line_from_candidates(candidates) "{{{
    if type(a:candidates) isnot type([])
    \   || empty(a:candidates)
        return ''
    endif
    let c = a:candidates[0]
    let make_string =
    \   'v:val.input . '
    \   . '(v:val.annotation ==# "" ? "" : '
    \   . '";" . v:val.annotation)'
    return
    \   c.key . c.okuri_rom_first . ' '
    \   . '/'.join(map(copy(a:candidates), make_string), '/').'/'
endfunction "}}}


function! s:clear_command_line() "{{{
    redraw
    echo ''
endfunction "}}}

" }}}


" s:Candidate {{{
" One s:Candidate corresponds to SKK dictionary's one line.
" It is the pair of filtered string and its converted string.

let [
\   s:CANDIDATE_FROM_USER_DICT,
\   s:CANDIDATE_FROM_SYSTEM_DICT,
\   s:CANDIDATE_FROM_REGISTERED_WORDS
\] = range(3)

function! s:candidate_new(from_type, input, key, okuri_rom_first, annotation) "{{{
    return {
    \   'from_type': a:from_type,
    \   'input': a:input,
    \   'key': a:key,
    \   'okuri_rom_first': a:okuri_rom_first,
    \   'annotation': a:annotation,
    \}
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

" s:RegisteredWord {{{
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

function! s:registered_word2candidate(rw, from_type)
    return s:candidate_new(
    \   a:from_type,
    \   a:rw.input,
    \   a:rw.key,
    \   a:rw.okuri_rom[0],
    \   a:rw.annotation
    \)
endfunction

" }}}


function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SID_PREFIX = s:SID()
delfunc s:SID


" s:HenkanResult {{{

" This provides a way to get
" next candidate string.
" - s:HenkanResult.forward()
" - s:HenkanResult.back()
"
" self._key, self._okuri_rom, self._okuri:
"   Query for this henkan result.
"
" self._status:
"   One of g:eskk#dictionary#HR_*
"
" self._candidates:
"   Candidates looked up by
"   self._key, self._okuri_rom, self._okuri
"   NOTE: Do not access directly.
"   Getter is s:HenkanResult.get_candidates().
"
" self._candidates_index:
"   Current index of List self._candidates

let [
\   g:eskk#dictionary#HR_NO_RESULT,
\   g:eskk#dictionary#HR_LOOK_UP_DICTIONARY,
\   g:eskk#dictionary#HR_GOT_RESULT
\] = range(3)



function! s:HenkanResult_new(key, okuri_rom, okuri, buftable) "{{{
    let obj = deepcopy(s:HenkanResult)
    let obj = extend(obj, {
    \    'buftable': a:buftable,
    \    '_key': a:key,
    \    '_okuri_rom': a:okuri_rom,
    \    '_okuri': a:okuri,
    \}, 'force')
    call obj.reset()
    return obj
endfunction "}}}

" After calling this function,
" s:HenkanResult.get_candidates() will look up dictionary again.
" So call this function when you modified SKK dictionary file.
function! s:HenkanResult_reset() dict "{{{
    let self._status = g:eskk#dictionary#HR_LOOK_UP_DICTIONARY
    let self._candidates = eskk#util#create_data_ordered_set(
    \   {'Fn_identifier': 'eskk#dictionary#_candidate_identifier'}
    \)
    let self._candidates_index = 0
    call self.remove_cache()
endfunction "}}}

" Forward/Back self._candidates_index safely
" Returns true value when succeeded / false value when failed
function! s:HenkanResult_advance(advance) dict "{{{
    try
        if !self.advance_index(a:advance)
            return 0    " Can't forward/back anymore...
        endif
        call self.update_candidate_prompt()
        return 1
    catch /^eskk: dictionary look up error/
        call eskk#logger#log_exception(
        \   's:HenkanResult.get_candidates()')
        return 0
    endtry
endfunction "}}}
" Advance self._candidates_index
function! s:HenkanResult_advance_index(advance) dict "{{{
    " Remove cache before changing `self` states,
    " because the cache depends on those states.
    call self.remove_cache()

    try
        let candidates = self.get_candidates()
    catch /^eskk: dictionary look up error/
        " Shut up error. This function does not throw exception.
        call eskk#logger#log_exception('s:HenkanResult.get_candidates()')
        return 0
    endtry

    let next_idx = self._candidates_index + (a:advance ? 1 : -1)
    if eskk#util#has_idx(candidates, next_idx)
        " Next time to call s:HenkanResult.get_candidates(),
        " eskk will getchar() if `next_idx >= g:eskk#show_candidates_count`
        let self._candidates_index = next_idx
        return 1
    else
        return 0
    endif
endfunction "}}}
" Set current candidate.
" but this function asks to user in command-line
" when `self._candidates_index >= g:eskk#show_candidates_count`.
" @throws eskk#dictionary#look_up_error()
function! s:HenkanResult_update_candidate_prompt() dict "{{{
    let max_count = g:eskk#show_candidates_count >= 0 ?
    \                   g:eskk#show_candidates_count : 0
    if self._candidates_index >= max_count
        let NONE = []
        let cand = self.select_candidate_prompt(max_count, NONE)
        if cand isnot NONE
            let [self._candidate, self._candidate_okuri] = cand
        else
            " Clear command-line.
            call s:clear_command_line()

            if self._candidates_index > 0
                " This changes self._candidates_index.
                call self.back()
            endif
            " self.get_candidates() may throw an exception.
            let candidates = self.get_candidates()
            return [
            \   candidates[self._candidates_index].input,
            \   self._okuri
            \]
        endif
    else
        call self.update_candidate()
    endif
endfunction "}}}
" Set current candidate.
" @throws eskk#dictionary#look_up_error()
function! s:HenkanResult_update_candidate() dict "{{{
    let candidates = self.get_candidates()
    let [self._candidate, self._candidate_okuri] =
    \   [
    \       candidates[self._candidates_index].input,
    \       self._okuri
    \   ]
endfunction "}}}

" Returns List of candidates.
" @throws eskk#dictionary#look_up_error()
function! s:HenkanResult_get_candidates() dict "{{{
    if self._status ==# g:eskk#dictionary#HR_GOT_RESULT
        return self._candidates.to_list()

    elseif self._status ==# g:eskk#dictionary#HR_LOOK_UP_DICTIONARY
        let dict = eskk#get_skk_dict()

        " Look up from registered words.
        let registered = filter(
        \   copy(dict.get_registered_words()),
        \   'v:val.key ==# self._key '
        \       . '&& v:val.okuri_rom[0] ==# self._okuri_rom[0]'
        \)

        " Look up from dictionaries.
        let user_dict = dict.get_user_dict()
        let system_dict = dict.get_system_dict()
        let user_dict_result =
        \   user_dict.search_candidate(
        \       self._key, self._okuri_rom)
        let system_dict_result =
        \   system_dict.search_candidate(
        \       self._key, self._okuri_rom)

        if user_dict_result[1] ==# -1
        \   && system_dict_result[1] ==# -1
        \   && empty(registered)
            let self._status = g:eskk#dictionary#HR_NO_RESULT
            throw eskk#dictionary#look_up_error(
            \   "Can't look up '"
            \   . g:eskk#marker_henkan
            \   . self._key
            \   . g:eskk#marker_okuri
            \   . self._okuri_rom
            \   . "' in dictionaries."
            \)
        endif

        " NOTE: The order is important.
        " registered word, user dictionary, system dictionary.

        " Merge registered words.
        if !empty(registered)
            for rw in registered
                call self._candidates.push(
                \   s:registered_word2candidate(
                \       rw,
                \       s:CANDIDATE_FROM_REGISTERED_WORDS
                \   )
                \)
            endfor
        endif

        " Merge user dictionary.
        if user_dict_result[1] !=# -1
            let candidates =
            \   eskk#dictionary#parse_skk_dict_line(
            \       user_dict_result[0],
            \       s:CANDIDATE_FROM_USER_DICT
            \   )
            call eskk#util#assert(
            \   !empty(candidates),
            \   'user dict: `candidates` is not empty.'
            \)
            let key = candidates[0].key
            let okuri_rom_first = candidates[0].okuri_rom_first
            call eskk#util#assert(
            \   key ==# self._key,
            \   "user dict:".string(key)." ==# ".string(self._key)
            \)
            call eskk#util#assert(
            \   okuri_rom_first ==# self._okuri_rom[0],
            \   "user dict:".string(okuri_rom_first)." ==# ".string(self._okuri_rom)
            \)

            for c in candidates
                call self._candidates.push(c)
            endfor
        endif

        " Merge system dictionary.
        if system_dict_result[1] !=# -1
            let candidates =
            \   eskk#dictionary#parse_skk_dict_line(
            \       system_dict_result[0],
            \       s:CANDIDATE_FROM_SYSTEM_DICT
            \   )
            call eskk#util#assert(
            \   !empty(candidates),
            \   'system dict: `candidates` is not empty.'
            \)
            let key = candidates[0].key
            let okuri_rom_first = candidates[0].okuri_rom_first
            call eskk#util#assert(
            \   key ==# self._key,
            \   "system dict:".string(key)." ==# ".string(self._key)
            \)
            call eskk#util#assert(
            \   okuri_rom_first ==# self._okuri_rom[0],
            \   "system dict:".string(okuri_rom_first)." ==# ".string(self._okuri_rom)
            \)

            for c in candidates
                call self._candidates.push(c)
            endfor
        endif

        let self._status = g:eskk#dictionary#HR_GOT_RESULT

        return self._candidates.to_list()
    else
        return []

    elseif self._status ==# g:eskk#dictionary#HR_NO_RESULT
        throw eskk#dictionary#look_up_error(
        \   "Can't look up '"
        \   . g:eskk#marker_henkan
        \   . self._key
        \   . g:eskk#marker_okuri
        \   . self._okuri_rom
        \   . "' in dictionaries."
        \)
    else
        throw eskk#internal_error(['eskk', 'dictionary'])
    endif
endfunction "}}}

function! eskk#dictionary#look_up_error(msg) "{{{
    return eskk#util#build_error(
    \   ['eskk', 'dictionary'],
    \   ['dictionary look up error', a:msg]
    \)
endfunction "}}}

" Select candidate from command-line.
" @throws eskk#dictionary#look_up_error()
function! s:HenkanResult_select_candidate_prompt(skip_num, fallback) dict "{{{
    " Select candidates by getchar()'s character.
    let words = copy(self.get_candidates())
    let word_num_per_page = len(split(g:eskk#select_cand_keys, '\zs'))
    let page_index = 0
    let pages = []

    call eskk#util#assert(
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
                \       (get(word, 'annotation', '') !=# '' ?
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
            return a:fallback
        endtry


        if eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:escape'
        \)
            return a:fallback
        elseif eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:next-page'
        \)
            if eskk#util#has_idx(pages, page_index + 1)
                let page_index += 1
            else
                " No more pages. Register new word.
                let dict = eskk#get_skk_dict()
                let input = dict.remember_word_prompt(self)[0]
                let henkan_buf_str = self.buftable.get_buf_str(
                \   g:eskk#buftable#PHASE_HENKAN
                \)
                let okuri_buf_str = self.buftable.get_buf_str(
                \   g:eskk#buftable#PHASE_OKURI
                \)
                return [
                \   (input != '' ?
                \       input : henkan_buf_str.rom_pairs.get_filter()),
                \   okuri_buf_str.rom_pairs.get_filter()
                \]
            endif
        elseif eskk#map#is_special_lhs(
        \   char, 'phase:henkan-select:prev-page'
        \)
            if eskk#util#has_idx(pages, page_index - 1)
                let page_index -= 1
            else
                return a:fallback
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
                    let self._candidates_index = idx + a:skip_num
                    return [word.input, self._okuri]
                endif
            endfor
        endif
    endwhile
endfunction "}}}

" Clear cache of current candidate.
function! s:HenkanResult_remove_cache() dict "{{{
    let self._candidate       = ''
    let self._candidate_okuri = ''
endfunction "}}}


" Returns candidate String.
" if optional {with_okuri} arguments are supplied,
" returns candidate String with okuri.
function! s:HenkanResult_get_current_candidate(...) dict "{{{
    let with_okuri = a:0 ? a:1 : 1
    return self._candidate
    \   . (with_okuri ? self._candidate_okuri : '')
endfunction "}}}
" Getter for self._key
function! s:HenkanResult_get_key() dict "{{{
    return self._key
endfunction "}}}
" Getter for self._okuri
function! s:HenkanResult_get_okuri() dict "{{{
    return self._okuri
endfunction "}}}
" Getter for self._okuri_rom
function! s:HenkanResult_get_okuri_rom() dict "{{{
    return self._okuri_rom
endfunction "}}}
" Getter for self._status
function! s:HenkanResult_get_status() dict "{{{
    return self._status
endfunction "}}}

" Forward current candidate index number (self._candidates_index)
function! s:HenkanResult_forward() dict "{{{
    return self.advance(1)
endfunction "}}}
" Back current candidate index number (self._candidates_index)
function! s:HenkanResult_back() dict "{{{
    return self.advance(0)
endfunction "}}}
function! s:HenkanResult_has_next() dict "{{{
    try
        let candidates = self.get_candidates()
        let idx = self._candidates_index
        return eskk#util#has_idx(candidates, idx + 1)
    catch /^eskk: dictionary look up error/
        " Shut up error. This function does not throw exception.
        call eskk#logger#log_exception('s:HenkanResult.get_candidates()')
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
function! s:HenkanResult_delete_from_dict() dict "{{{
    try
        return self.do_delete_from_dict()
    finally
        let dict = eskk#get_skk_dict()
        call dict.clear_henkan_result()
    endtry
endfunction "}}}
function! s:HenkanResult_do_delete_from_dict() dict "{{{
    " Check if `self` can get candidates.
    try
        let candidates = self.get_candidates()
    catch /^eskk: dictionary look up error/
        call eskk#logger#log_exception(
        \   's:HenkanResult.get_candidates()')
        return
    endtry
    " Check invalid index.
    let candidates_index = self._candidates_index
    if !eskk#util#has_idx(candidates, candidates_index)
        return
    endif
    " Check that user dictionary is valid.
    let del_cand = candidates[candidates_index]
    let dict = eskk#get_skk_dict()
    if !dict.get_user_dict().is_valid()
        return
    endif
    " Check user input.
    let input = eskk#util#input(
    \   'Really purge? '
    \   . self._key . self._okuri_rom[0]
    \   . ' /'
    \   . del_cand.input
    \   . (get(del_cand, 'annotation', '') !=# '' ?
    \       ';' . del_cand.annotation :
    \       '')
    \   . '/ (yes/no):'
    \)
    if input !~? '^y\%[es]$'
        return
    endif


    " Clear self.
    call self.reset()

    " Remove all elements matching with current candidate
    " from registered words.
    for word in dict.get_registered_words()
        call dict.remove_registered_word(word)
    endfor

    " Remove all elements matching with current candidate
    " from SKK dictionary.
    let lines = dict.get_user_dict().get_lines_copy()
    let i = 0
    let len = len(lines)
    while i < len
        " Leave comment line.
        if lines[i] =~# '^\s*;'
            let i += 1
            continue
        endif

        let lines[i] =
        \   s:delete_candidate_from_line(lines[i], del_cand)
        if lines[i] ==# ''
            " If there is no more candidates,
            " delete the line.
            unlet lines[i]
            let len -= 1
            continue
        endif
        let i += 1
    endwhile
    try
        call dict.get_user_dict().set_lines(lines)
    catch /^eskk: parse error/
        return
    endtry
    " Write to dictionary.
    call dict.update_dictionary(1, 0)
endfunction "}}}

" Move this henkan result to the first of self._registered_words.
function! s:HenkanResult_update_rank() dict "{{{
    try
        let candidates = self.get_candidates()
    catch /^eskk: dictionary look up error/
        call eskk#logger#log_exception(
        \   's:HenkanResult.get_candidates()')
        return
    endtry
    let candidates_index = self._candidates_index

    if !eskk#util#has_idx(candidates, candidates_index)
        return
    endif
    let rw = s:candidate2registered_word(
    \   candidates[candidates_index],
    \   self._key,
    \   self._okuri,
    \   self._okuri_rom,
    \)

    " Move self to the first.
    let dict = eskk#get_skk_dict()
    call dict.forget_word(rw.input, rw.key, rw.okuri, rw.okuri_rom, rw.annotation)
    call dict.remember_word(rw.input, rw.key, rw.okuri, rw.okuri_rom, rw.annotation)
endfunction "}}}


let s:HenkanResult = {
\   'buftable': {},
\   '_key': '',
\   '_okuri_rom': '',
\   '_okuri': '',
\   '_status': -1,
\   '_candidates': {},
\   '_candidates_index': -1,
\   '_candidate': '',
\   '_candidate_okuri': '',
\
\   'reset': eskk#util#get_local_funcref('HenkanResult_reset', s:SID_PREFIX),
\   'advance': eskk#util#get_local_funcref('HenkanResult_advance', s:SID_PREFIX),
\   'advance_index': eskk#util#get_local_funcref('HenkanResult_advance_index', s:SID_PREFIX),
\   'update_candidate': eskk#util#get_local_funcref('HenkanResult_update_candidate', s:SID_PREFIX),
\   'update_candidate_prompt': eskk#util#get_local_funcref('HenkanResult_update_candidate_prompt', s:SID_PREFIX),
\   'get_candidates': eskk#util#get_local_funcref('HenkanResult_get_candidates', s:SID_PREFIX),
\   'select_candidate_prompt': eskk#util#get_local_funcref('HenkanResult_select_candidate_prompt', s:SID_PREFIX),
\   'remove_cache': eskk#util#get_local_funcref('HenkanResult_remove_cache', s:SID_PREFIX),
\   'get_current_candidate': eskk#util#get_local_funcref('HenkanResult_get_current_candidate', s:SID_PREFIX),
\   'get_key': eskk#util#get_local_funcref('HenkanResult_get_key', s:SID_PREFIX),
\   'get_okuri': eskk#util#get_local_funcref('HenkanResult_get_okuri', s:SID_PREFIX),
\   'get_okuri_rom': eskk#util#get_local_funcref('HenkanResult_get_okuri_rom', s:SID_PREFIX),
\   'get_status': eskk#util#get_local_funcref('HenkanResult_get_status', s:SID_PREFIX),
\   'forward': eskk#util#get_local_funcref('HenkanResult_forward', s:SID_PREFIX),
\   'back': eskk#util#get_local_funcref('HenkanResult_back', s:SID_PREFIX),
\   'has_next': eskk#util#get_local_funcref('HenkanResult_has_next', s:SID_PREFIX),
\   'delete_from_dict': eskk#util#get_local_funcref('HenkanResult_delete_from_dict', s:SID_PREFIX),
\   'do_delete_from_dict': eskk#util#get_local_funcref('HenkanResult_do_delete_from_dict', s:SID_PREFIX),
\   'update_rank': eskk#util#get_local_funcref('HenkanResult_update_rank', s:SID_PREFIX),
\}

" }}}

" s:PhysicalDict {{{
"
" s:Dictionary may manipulate/abstract multiple dictionaries
" But s:PhysicalDict only manupulates one dictionary.
"
" _content_lines:
"   Whole lines of dictionary file.
"   Use `s:PhysicalDict.get_lines()` to get this.
"   `s:PhysicalDict.get_lines()` does:
"   - Lazy file read
"   - Memoization for getting file content
"
" _ftime_at_set:
"   UNIX time number when `_content_lines` is set.
"
" okuri_ari_idx:
"   Line number of SKK dictionary
"   where ";; okuri-ari entries." found.
"
" okuri_nasi_idx:
"   Line number of SKK dictionary
"   where ";; okuri-nasi entries." found.
"
" path:
"   File path of SKK dictionary.
"
" sorted:
"   If this value is true, assume SKK dictionary is sorted.
"   Otherwise, assume SKK dictionary is not sorted.
"
" encoding:
"   Character encoding of SKK dictionary.
"
" _is_modified:
"   If this value is true, lines were changed
"   by `s:PhysicalDict.set_lines()`.
"   Otherwise, lines were not changed.


function! s:PhysicalDict_new(path, sorted, encoding) "{{{
    return extend(
    \   deepcopy(s:PhysicalDict),
    \   {
    \       'path': expand(a:path),
    \       'sorted': a:sorted,
    \       'encoding': a:encoding,
    \   },
    \   'force'
    \)
endfunction "}}}



" Get List of whole lines of dictionary.
function! s:PhysicalDict_get_lines(...) dict "{{{
    let force = a:0 ? a:1 : 0
    if !force
    \   && self._ftime_at_set isnot -1
    \   && self._ftime_at_set >=# getftime(self.path)
        return self._content_lines
    endif

    try
        unlockvar 1 self._content_lines
        let self._content_lines  = readfile(self.path)
        lockvar 1 self._content_lines
        call self.parse_lines()

        let self._ftime_at_set = getftime(self.path)
    catch /E484:/    " Can't open file
        call eskk#logger#logf("Can't read '%s'!", self.path)
    catch /^eskk: parse error/
        call eskk#logger#log_exception('s:PhysicalDict.get_lines()')
        let self.okuri_ari_idx = -1
        let self.okuri_nasi_idx = -1
    endtry

    return self._content_lines
endfunction "}}}

function! s:PhysicalDict_get_lines_copy() dict "{{{
    let lines = copy(self.get_lines())
    unlockvar 1 lines
    return lines
endfunction "}}}

function! s:PhysicalDict_get_updated_lines(registered_words) dict "{{{
    if a:registered_words.empty()
        return self.get_lines()
    endif
    let lines = self.get_lines_copy()

    " Check if self._user_dict really does not have registered words.
    let ari_lnum = self.okuri_ari_idx + 1
    let nasi_lnum = self.okuri_nasi_idx + 1
    for w in reverse(a:registered_words.to_list())
        " Search the line which has `w`.
        let [l, index] = self.search_candidate(w.key, w.okuri_rom)
        let candidate =
        \   s:registered_word2candidate(w,
        \       s:CANDIDATE_FROM_REGISTERED_WORDS)
        if index >=# 0
            " If the line exists, add `w` to the line.
            call eskk#util#assert(
            \   l != '',
            \   'line must not be empty string'
            \   . ' (index = '.index.')'
            \)
            let lines[index] =
            \   s:add_candidate_to_line(l, candidate)
        else
            " If the line does not exists, add new line.
            let l = s:make_line_from_candidates([candidate])
            call eskk#util#assert(
            \   l !=# '',
            \   'line must not be empty string'
            \   . ' (index = '.index.')'
            \)
            if w.okuri_rom !=# ''
                call insert(lines, l, ari_lnum)
                let nasi_lnum += 1
            else
                call insert(lines, l, nasi_lnum)
            endif
        endif
    endfor

    return lines
endfunction "}}}

" Set List of whole lines of dictionary.
function! s:PhysicalDict_set_lines(lines) dict "{{{
    try
        unlockvar 1 self._content_lines
        let self._content_lines  = a:lines
        lockvar 1 self._content_lines
        call self.parse_lines()
        let self._ftime_at_set = localtime()
        let self._is_modified = 1
    catch /^eskk: parse error/
        call eskk#logger#log_exception('s:PhysicalDict.set_lines()')
        let self.okuri_ari_idx = -1
        let self.okuri_nasi_idx = -1
    endtry
endfunction "}}}

" - Validate List of whole lines of dictionary.
" - Set self.okuri_ari_idx, self.okuri_nasi_idx.
function! s:PhysicalDict_parse_lines() dict "{{{
    let self.okuri_ari_idx  = index(
    \   self._content_lines,
    \   ';; okuri-ari entries.'
    \)
    if self.okuri_ari_idx <# 0
        throw eskk#dictionary#parse_error(
        \   "invalid self.okuri_ari_idx value"
        \)
    endif

    let self.okuri_nasi_idx = index(
    \   self._content_lines,
    \   ';; okuri-nasi entries.'
    \)
    if self.okuri_nasi_idx <# 0
        throw eskk#dictionary#parse_error(
        \   "invalid self.okuri_nasi_idx value"
        \)
    endif

    if self.okuri_ari_idx >= self.okuri_nasi_idx
        throw eskk#dictionary#parse_error(
        \   "okuri-ari entries must be before okuri-nasi entries."
        \)
    endif
endfunction "}}}

function! eskk#dictionary#parse_error(msg) "{{{
    return eskk#util#build_error(
    \   ['eskk', 'dictionary'],
    \   ["SKK dictionary parse error", a:msg]
    \)
endfunction "}}}

" Returns true value if "self.okuri_ari_idx" and
" "self.okuri_nasi_idx" is valid range.
function! s:PhysicalDict_is_valid() dict "{{{
    " Succeeded to parse SKK dictionary.
    return self.okuri_ari_idx >= 0
    \   && self.okuri_nasi_idx >= 0
endfunction "}}}

" Get self._ftime_at_set.
" See self._ftime_at_set description at "s:PhysicalDict".
function! s:PhysicalDict_get_ftime_at_read() dict "{{{
    return self._ftime_at_set
endfunction "}}}

" Set false to `self._is_modified`.
function! s:PhysicalDict_clear_modified_flags() dict "{{{
    let self._is_modified = 0
endfunction "}}}


" Returns all lines matching the candidate.
function! s:PhysicalDict_search_all_candidates(key_filter, okuri_rom, ...) dict "{{{
    let limit = a:0 ? a:1 : -1    " No limit by default.
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '')

    " self.is_valid() loads whole lines if it does not have,
    " so `self` can check the lines.
    let whole_lines = self.get_lines()
    if !self.is_valid()
        return []
    endif

    let converted = eskk#util#iconv(needle, &l:encoding, self.encoding)
    if self.sorted
        let [line, idx] = self.search_binary(
        \   whole_lines,
        \   converted,
        \   has_okuri,
        \   100
        \)

        if idx == -1
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
        call eskk#util#assert(begin <= end, 'begin <= end')
        if limit >= 0 && begin + limit < end
            let end = begin + limit
        endif

        return map(
        \   whole_lines[begin : end],
        \   'eskk#util#iconv(v:val, self.encoding, &l:encoding)'
        \)
    else
        let lines = []
        let start = 1
        while 1
            let [line, idx] = self.search_linear(
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

        return map(
        \   lines,
        \   'eskk#util#iconv(v:val, self.encoding, &l:encoding)'
        \)
    endif
endfunction "}}}
" Returns [line_string, idx] matching the candidate.
function! s:PhysicalDict_search_candidate(key_filter, okuri_rom) dict "{{{
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '') . ' '

    let whole_lines = self.get_lines()
    if !self.is_valid()
        return ['', -1]
    endif

    let converted = eskk#util#iconv(needle, &l:encoding, self.encoding)
    if self.sorted
        let [line, idx] = self.search_binary(
        \   whole_lines, converted, has_okuri, 100
        \)
    else
        let [line, idx] = self.search_linear(
        \   whole_lines, converted, has_okuri
        \)
    endif
    if idx !=# -1
        return [
        \   eskk#util#iconv(line, self.encoding, &l:encoding),
        \   idx
        \]
    else
        return ['', -1]
    endif
endfunction "}}}
" Returns [line_string, idx] matching the candidate.
function! s:PhysicalDict_search_binary(whole_lines, needle, has_okuri, limit) dict "{{{
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    " NOTE: min, max, mid are index number. not lnum.

    if a:has_okuri
        let min = self.okuri_ari_idx
        let max = self.okuri_nasi_idx
    else
        let min = self.okuri_nasi_idx
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
    return self.search_linear(
    \   a:whole_lines, a:needle, a:has_okuri, min, max
    \)
endfunction "}}}
" Returns [line_string, idx] matching the candidate.
function! s:PhysicalDict_search_linear(whole_lines, needle, has_okuri, ...) dict "{{{
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    let min_which = a:has_okuri ? 'okuri_ari_idx' : 'okuri_nasi_idx'
    let min = get(a:000, 0, self[min_which])
    let max = get(a:000, 1, len(a:whole_lines) - 1)

    call eskk#util#assert(min <=# max, min.' <=# '.max)
    call eskk#util#assert(min >= 0, "min is not invalid (negative) number:" . min)

    while min <=# max
        if stridx(a:whole_lines[min], a:needle) == 0
            return [a:whole_lines[min], min]
        endif
        let min += 1
    endwhile
    return ['', -1]
endfunction "}}}


let s:PhysicalDict = {
\   '_content_lines': [],
\   '_ftime_at_set': -1,
\   'okuri_ari_idx': -1,
\   'okuri_nasi_idx': -1,
\   'path': '',
\   'sorted': 0,
\   'encoding': '',
\   '_is_modified': 0,
\
\   'get_lines': eskk#util#get_local_funcref('PhysicalDict_get_lines', s:SID_PREFIX),
\   'get_lines_copy': eskk#util#get_local_funcref('PhysicalDict_get_lines_copy', s:SID_PREFIX),
\   'get_updated_lines': eskk#util#get_local_funcref('PhysicalDict_get_updated_lines', s:SID_PREFIX),
\   'set_lines': eskk#util#get_local_funcref('PhysicalDict_set_lines', s:SID_PREFIX),
\   'parse_lines': eskk#util#get_local_funcref('PhysicalDict_parse_lines', s:SID_PREFIX),
\   'is_valid': eskk#util#get_local_funcref('PhysicalDict_is_valid', s:SID_PREFIX),
\   'get_ftime_at_read': eskk#util#get_local_funcref('PhysicalDict_get_ftime_at_read', s:SID_PREFIX),
\   'clear_modified_flags': eskk#util#get_local_funcref('PhysicalDict_clear_modified_flags', s:SID_PREFIX),
\   'search_all_candidates': eskk#util#get_local_funcref('PhysicalDict_search_all_candidates', s:SID_PREFIX),
\   'search_candidate': eskk#util#get_local_funcref('PhysicalDict_search_candidate', s:SID_PREFIX),
\   'search_binary': eskk#util#get_local_funcref('PhysicalDict_search_binary', s:SID_PREFIX),
\   'search_linear': eskk#util#get_local_funcref('PhysicalDict_search_linear', s:SID_PREFIX),
\}

" }}}

" s:Dictionary {{{
"
" This behaves like one file dictionary.
" But it may manipulate multiple dictionaries.
"
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


function! eskk#dictionary#new(...) "{{{
    return call(function('s:Dictionary_new'), a:000)
endfunction "}}}

function! s:Dictionary_new(...) "{{{
    let user_dict = get(a:000, 0, g:eskk#directory)
    let system_dict = get(a:000, 1, g:eskk#large_dictionary)
    return extend(
    \   deepcopy(s:Dictionary),
    \   {
    \       '_user_dict': s:PhysicalDict_new(
    \           user_dict.path,
    \           user_dict.sorted,
    \           user_dict.encoding,
    \       ),
    \       '_system_dict': s:PhysicalDict_new(
    \           system_dict.path,
    \           system_dict.sorted,
    \           system_dict.encoding,
    \       ),
    \       '_registered_words': eskk#util#create_data_ordered_set(
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
function! s:Dictionary_refer(buftable, key, okuri, okuri_rom) dict "{{{
    let hr = s:HenkanResult_new(
    \   a:key,
    \   a:okuri_rom,
    \   a:okuri,
    \   deepcopy(a:buftable, 1),
    \)
    let self._current_henkan_result = hr
    " s:HenkanResult.update_candidates() may throw
    " eskk#dictionary#look_up_error() exception.
    call hr.update_candidate()
    return hr
endfunction "}}}

" Register new word (registered word) at command-line.
function! s:Dictionary_remember_word_prompt(henkan_result) dict "{{{
    let key       = a:henkan_result.get_key()
    let okuri     = a:henkan_result.get_okuri()
    let okuri_rom = a:henkan_result.get_okuri_rom()


    " Save `&imsearch`.
    let save_imsearch = &l:imsearch
    let &l:imsearch = 1

    " Create new eskk instance.
    call eskk#create_new_instance()

    if okuri == ''
        let prompt = printf('%s ', key)
    else
        let prompt = printf('%s%s%s ', key, g:eskk#marker_okuri, okuri)
    endif
    try
        " Get input from command-line.
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
        call eskk#map#map_all_keys()

        " Restore `&imsearch`.
        let &l:imsearch = save_imsearch
    endtry


    if input != ''
        let [input, annotation] =
        \   matchlist(input, '^\([^;]*\)\(.*\)')[1:2]
        let annotation = substitute(annotation, '^;', '', '')
        call self.remember_word(input, key, okuri, okuri_rom, annotation)
    endif

    call s:clear_command_line()
    return [input, key, okuri]
endfunction "}}}

" Clear all registered words.
function! s:Dictionary_forget_all_words() dict "{{{
    call self._registered_words.clear()
endfunction "}}}

" Clear given registered word.
function! s:Dictionary_forget_word(input, key, okuri, okuri_rom, annotation) dict "{{{
    let rw = s:registered_word_new(a:input, a:key, a:okuri, a:okuri_rom, a:annotation)
    if !self._registered_words.has(rw)
        return
    endif

    call self.remove_registered_word(rw)
    if self._registered_words.empty()
        let self._registered_words_modified = 0
    endif

    if !empty(self._current_henkan_result)
        call self._current_henkan_result.reset()
    endif
endfunction "}}}

" Add registered word.
function! s:Dictionary_remember_word(input, key, okuri, okuri_rom, annotation) dict "{{{
    let rw = s:registered_word_new(a:input, a:key, a:okuri, a:okuri_rom, a:annotation)
    if self._registered_words.has(rw)
        return
    endif

    call self._registered_words.unshift(rw)

    if self._registered_words.size() >= g:eskk#dictionary_save_count
        call self.update_dictionary(0)
    endif

    if !empty(self._current_henkan_result)
        call self._current_henkan_result.reset()
    endif
endfunction "}}}

" Get List of registered words.
function! s:Dictionary_get_registered_words() dict "{{{
    return self._registered_words.to_list()
endfunction "}}}

" Remove registered word matching with arguments values.
function! s:Dictionary_remove_registered_word(word) dict "{{{
    return self._registered_words.remove(a:word)
endfunction "}}}

" Returns true value if new registered is added
" or user dictionary's lines are
" modified by "s:PhysicalDict.set_lines()".
" If this value is false, s:Dictionary.update_dictionary() does nothing.
function! s:Dictionary_is_modified() dict "{{{
    " No need to check system dictionary.
    " Because it is immutable.
    return
    \   !self._registered_words.empty()
    \   || self._user_dict._is_modified
endfunction "}}}

" Write to user dictionary.
" By default, This function is executed at VimLeavePre.
function! s:Dictionary_update_dictionary(...) dict "{{{
    let verbose      = get(a:000, 0, 1)
    let do_get_lines = get(a:000, 1, 1)
    if !self.is_modified()
        return
    endif

    if do_get_lines
        call self._user_dict.get_lines()
    endif
    if filereadable(self._user_dict.path)
        if !self._user_dict.is_valid()
            return
        endif
    else
        " Create new lines.
        " NOTE: It must not throw parse error exception!
        call self._user_dict.set_lines([
        \   ';; okuri-ari entries.',
        \   ';; okuri-nasi entries.'
        \])
    endif

    call self.write_lines(
    \   self._user_dict.get_updated_lines(
    \       self._registered_words
    \   ),
    \   verbose
    \)
    call self.forget_all_words()
    call self._user_dict.clear_modified_flags()
endfunction "}}}
function! s:Dictionary_write_lines(lines, verbose) dict "{{{
    let lines = a:lines

    let save_msg =
    \   "Saving to '"
    \   . self._user_dict.path
    \   . "'..."

    if a:verbose
        redraw
        echo save_msg
    endif

    let ret_success = 0
    try
        let ret = writefile(lines, self._user_dict.path)
        if ret ==# ret_success
            if a:verbose
                redraw
                echo save_msg . 'Done.'
            endif
        else
            throw eskk#internal_error(
            \   ['eskk', 'dictionary'],
            \   "can't write to '"
            \       . self._user_dict.path
            \       . "'."
            \)
        endif
    catch
        redraw
        echohl WarningMsg
        echomsg save_msg . "Error. - " . v:exception
        echomsg " Please check permission of '"
        \   . self._user_dict.path . "'."
        echohl None
    endtry
endfunction "}}}

function! eskk#dictionary#_candidate_identifier(candidate) "{{{
    return a:candidate.input
endfunction "}}}

" Reduce the losses of creating instance.
let s:dict_search_candidates = eskk#util#create_data_ordered_set(
\   {'Fn_identifier': 'eskk#dictionary#_candidate_identifier'}
\)
" Search candidates matching with arguments.
function! s:Dictionary_search_all_candidates(key, okuri, okuri_rom) dict "{{{
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

    for rw in self._registered_words.to_list()
        if rw.key ==# key && rw.okuri_rom[0] ==# okuri_rom[0]
            call candidates.push(
            \   s:registered_word2candidate(
            \       rw,
            \       s:CANDIDATE_FROM_REGISTERED_WORDS,
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
            \   [self._user_dict, s:CANDIDATE_FROM_USER_DICT],
            \   [self._system_dict, s:CANDIDATE_FROM_SYSTEM_DICT],
            \]
                for line in dict.search_all_candidates(
                \   key, okuri_rom, max_count - candidates.size()
                \)
                    for c in eskk#dictionary#parse_skk_dict_line(
                    \   line, from_type
                    \)
                        let c.from_type = s:CANDIDATE_FROM_REGISTERED_WORDS
                        call candidates.push(c)
                        if candidates.size() >= max_count
                            throw 'break'
                        endif
                    endfor
                endfor
            endfor
        catch /^break$/
        endtry
    endif

    return candidates.to_list()
endfunction "}}}


" Getter for self._current_henkan_result
function! s:Dictionary_get_henkan_result() dict "{{{
    return self._current_henkan_result
endfunction "}}}
" Getter for self._user_dict
function! s:Dictionary_get_user_dict() dict "{{{
    return self._user_dict
endfunction "}}}
" Getter for self._system_dict
function! s:Dictionary_get_system_dict() dict "{{{
    return self._system_dict
endfunction "}}}

" Clear self._current_henkan_result
function! s:Dictionary_clear_henkan_result() dict "{{{
    let self._current_henkan_result = {}
endfunction "}}}


let s:Dictionary = {
\   '_user_dict': {},
\   '_system_dict': {},
\   '_registered_words': {},
\   '_registered_words_modified': 0,
\   '_current_henkan_result': {},
\
\   'refer': eskk#util#get_local_funcref('Dictionary_refer', s:SID_PREFIX),
\   'remember_word_prompt': eskk#util#get_local_funcref('Dictionary_remember_word_prompt', s:SID_PREFIX),
\   'forget_all_words': eskk#util#get_local_funcref('Dictionary_forget_all_words', s:SID_PREFIX),
\   'forget_word': eskk#util#get_local_funcref('Dictionary_forget_word', s:SID_PREFIX),
\   'remember_word': eskk#util#get_local_funcref('Dictionary_remember_word', s:SID_PREFIX),
\   'get_registered_words': eskk#util#get_local_funcref('Dictionary_get_registered_words', s:SID_PREFIX),
\   'remove_registered_word': eskk#util#get_local_funcref('Dictionary_remove_registered_word', s:SID_PREFIX),
\   'is_modified': eskk#util#get_local_funcref('Dictionary_is_modified', s:SID_PREFIX),
\   'update_dictionary': eskk#util#get_local_funcref('Dictionary_update_dictionary', s:SID_PREFIX),
\   'write_lines': eskk#util#get_local_funcref('Dictionary_write_lines', s:SID_PREFIX),
\   'search_all_candidates': eskk#util#get_local_funcref('Dictionary_search_all_candidates', s:SID_PREFIX),
\   'get_henkan_result': eskk#util#get_local_funcref('Dictionary_get_henkan_result', s:SID_PREFIX),
\   'get_user_dict': eskk#util#get_local_funcref('Dictionary_get_user_dict', s:SID_PREFIX),
\   'get_system_dict': eskk#util#get_local_funcref('Dictionary_get_system_dict', s:SID_PREFIX),
\   'clear_henkan_result': eskk#util#get_local_funcref('Dictionary_clear_henkan_result', s:SID_PREFIX),
\}

" }}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

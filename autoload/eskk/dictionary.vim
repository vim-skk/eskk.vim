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

" TODO
" - Compile dictionary (s:dict._dict_info) to refer to result.
" - lnum => idx
" - eskk#dictionary#search_next_candidate() => eskk#dictionary#search_candidate()

" Utility autoload functions {{{

function! eskk#dictionary#search_all_candidates(physical_dict, key_filter, okuri_rom) "{{{
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '')

    call eskk#util#logf('needle = %s, key = %s, okuri_rom = %s',
    \               string(needle), string(a:key_filter), string(a:okuri_rom))
    call eskk#util#logf('Search %s in %s.', string(needle), string(a:physical_dict.path))

    if !a:physical_dict.is_valid()
        return []
    endif

    let converted = s:iconv(needle, &l:encoding, a:physical_dict.encoding)
    if a:physical_dict.sorted
        call eskk#util#log('dictionary is sorted. Try binary search...')
        let result = s:search_binary(a:physical_dict, converted, has_okuri, 5)
    else
        call eskk#util#log('dictionary is *not* sorted. Try linear search....')
        let result = s:search_linear(a:physical_dict, converted, has_okuri)
    endif

    if result[1] !=# -1
        let whole_lines = a:physical_dict.get_lines()
        let begin = result[1]
        let i = begin + 1
        while eskk#util#has_idx(whole_lines, i)
        \   && stridx(whole_lines[i], converted) == 0
            let i += 1
        endwhile
        let end = i - 1
        call eskk#util#assert(begin <= end)

        return map(
        \   whole_lines[begin : end],
        \   's:iconv(v:val, a:physical_dict.encoding, &l:encoding)'
        \)
    else
        return []
    endif
endfunction "}}}
function! eskk#dictionary#search_next_candidate(physical_dict, key_filter, okuri_rom) "{{{
    let has_okuri = a:okuri_rom != ''
    let needle = a:key_filter . (has_okuri ? a:okuri_rom[0] : '') . ' '

    call eskk#util#logf('needle = %s, key = %s, okuri_rom = %s',
    \               string(needle), string(a:key_filter), string(a:okuri_rom))
    call eskk#util#logf('Search %s in %s.', string(needle), string(a:physical_dict.path))

    if !a:physical_dict.is_valid()
        return ['', -1]
    endif

    let converted = s:iconv(needle, &l:encoding, a:physical_dict.encoding)
    if a:physical_dict.sorted
        call eskk#util#log('dictionary is sorted. Try binary search...')
        let result = s:search_binary(a:physical_dict, converted, has_okuri, 5)
    else
        call eskk#util#log('dictionary is *not* sorted. Try linear search....')
        let result = s:search_linear(a:physical_dict, converted, has_okuri)
    endif
    if result[1] !=# -1
        return [
        \   s:iconv(result[0], a:physical_dict.encoding, &l:encoding),
        \   result[1]
        \]
    else
        return ['', -1]
    endif
endfunction "}}}
function! s:search_binary(ph_dict, needle, has_okuri, limit) "{{{
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    let whole_lines = a:ph_dict.get_lines()
    if !a:ph_dict.is_valid()
        return ['', -1]
    endif

    " NOTE: min, max, mid are lnum. not index number.

    let min = a:ph_dict.okuri_ari_lnum + 1
    let max = a:has_okuri ? a:ph_dict.okuri_nasi_lnum - 1 : len(whole_lines)
    while max - min > a:limit
        let mid = (min + max + 2) / 2
        let line = whole_lines[mid - 1]
        if a:needle >=# line
            if a:has_okuri
                let max = mid
            else
                let min = mid
            endif
        elseif a:has_okuri
          let min = mid
        else
          let max = mid
        endif
    endwhile
    call eskk#util#logf('min = %d, max = %d', min, max)
    " NOTE: min, max: Give index number, not lnum.
    return s:search_linear(a:ph_dict, a:needle, a:has_okuri, min - 1, max - 1)
endfunction "}}}
function! s:search_linear(ph_dict, needle, has_okuri, ...) "{{{
    " Assumption: `a:needle` is encoded to dictionary file encoding.
    let whole_lines = a:ph_dict.get_lines()
    if !a:ph_dict.is_valid()
        return ['', -1]
    endif

    if a:0 >= 2
        let [pos, end] = a:000
        call eskk#util#assert(pos < end, 'pos < end')
    elseif a:has_okuri
        let [pos, end] = [a:ph_dict.okuri_ari_lnum, len(whole_lines) - 1]
        call eskk#util#assert(a:ph_dict.okuri_ari_lnum !=# -1, 'okuri_ari_lnum is not -1')
    else
        let [pos, end] = [a:ph_dict.okuri_nasi_lnum, len(whole_lines) - 1]
        call eskk#util#assert(a:ph_dict.okuri_nasi_lnum !=# -1, 'okuri_nasi_lnum is not -1')
    endif
    call eskk#util#assert(pos >= 0, "pos is not invalid (negative) number.")

    while pos <=# end
        let line = whole_lines[pos]
        if stridx(line, a:needle) == 0
            call eskk#util#logf('eskk#dictionary#search_next_candidate() - found!: %s', string(line))
            return [line, pos]
        endif
        let pos += 1
    endwhile
    call eskk#util#log('eskk#dictionary#search_next_candidate() - not found.')
    return ['', -1]
endfunction "}}}

function! eskk#dictionary#parse_skk_dict_line(line) "{{{
    let m = matchlist(a:line, '^\([^ ]\+\) /\(.*\)/$')
    call eskk#util#assert(!empty(m))
    let [yomi, line] = m[1:2]

    let candidates = []
    for _ in split(line, '/')
        let semicolon = stridx(_, ';')
        call add(candidates, (semicolon != -1) ?
              \ {'result': _[: semicolon - 1], 'annotation': _[semicolon + 1 :]} :
              \ {'result': _})
    endfor

    return [yomi, candidates]
endfunction "}}}

function! eskk#dictionary#merge_results(user_dict_result, system_dict_result) "{{{
    " Merge.
    let results =
    \   (a:user_dict_result[1] !=# -1 ? eskk#dictionary#parse_skk_dict_line(a:user_dict_result[0])[1] : [])
    \   + (a:system_dict_result[1] !=# -1 ? eskk#dictionary#parse_skk_dict_line(a:system_dict_result[0])[1] : [])

    " Unique.
    let unique = {}
    let i = 0
    while i < len(results)
        let r = results[i]
        let str = r.result

        if has_key(unique, str)
            if get(r, 'annotation', '') ==# get(unique[str], 'annotation', '')
                " If `result` and `annotation` is same as old one, Remove new one.
                call remove(results, i)
                " Next element is results[i], Don't increment.
                continue
            endif
        else
            let unique[str] = r
        endif
        let i += 1
    endwhile

    return results
endfunction "}}}

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

" Functions {{{

" s:henkan_result {{{

" Interface for henkan result.
" This provides a method `get_next()`
" to get next candidate string.

let s:HR_REGISTERED_WORD = 0
lockvar s:HR_REGISTERED_WORD
let s:HR_LOOK_UP_DICTIONARY = 1
lockvar s:HR_LOOK_UP_DICTIONARY
let s:HR_GOT_RESULT = 2
lockvar s:HR_GOT_RESULT

let s:henkan_result = {
\   'buftable': {},
\   '_dict': {},
\   '_key': '',
\   '_okuri_rom': '',
\   '_okuri': '',
\   '_registered_input': '',
\   '_status': s:HR_REGISTERED_WORD,
\   '_result': [],
\}

function! s:henkan_result_new(dict, key, okuri_rom, okuri, buftable, registered_input) "{{{
    return extend(
    \   deepcopy(s:henkan_result),
    \   {
    \       'buftable': a:buftable,
    \       '_dict': a:dict,
    \       '_key': a:key,
    \       '_okuri_rom': a:okuri_rom,
    \       '_okuri': a:okuri,
    \       '_registered_input': a:registered_input,
    \       '_status': (empty(a:registered_input) ? s:HR_LOOK_UP_DICTIONARY : s:HR_REGISTERED_WORD),
    \       '_result': (empty(a:registered_input) ? [] : [map(copy(a:registered_input), '{"result": v:val, "annotation": ""}'), 0]),
    \   },
    \   'force'
    \)
endfunction "}}}

function! s:henkan_result_advance(self, advance) "{{{
    try
        let result = s:henkan_result_get_result(a:self)
        if eskk#util#has_idx(result[0], result[1] + (a:advance ? 1 : -1))
            " Next time to call s:henkan_result_get_result(),
            " eskk will getchar() if `result[1] >= g:eskk_show_candidates_count`
            let result[1] += (a:advance ? 1 : -1)
            return 1
        else
            return 0
        endif
    catch /^eskk: dictionary look up error:/
        return 0
    endtry
endfunction "}}}

function! s:henkan_result_get_result(this) "{{{
    let msg = printf("Can't look up '%s%s%s%s' in dictionaries.",
    \                   g:eskk_marker_henkan, a:this._key, g:eskk_marker_okuri, a:this._okuri_rom)
    let cant_get_result = eskk#dictionary_look_up_error(['eskk', 'dictionary'], msg)

    if a:this._status ==# s:HR_REGISTERED_WORD || a:this._status ==# s:HR_GOT_RESULT
        if !empty(a:this._result)
            return a:this._result
        else
            throw cant_get_result
        endif
    elseif a:this._status ==# s:HR_LOOK_UP_DICTIONARY
        let [user_dict, system_dict] = [a:this._dict._user_dict, a:this._dict._system_dict]
        " Look up this henkan result in dictionaries.
        let user_dict_result = eskk#dictionary#search_next_candidate(
        \   user_dict, a:this._key, a:this._okuri_rom
        \)
        let system_dict_result = eskk#dictionary#search_next_candidate(
        \   system_dict, a:this._key, a:this._okuri_rom
        \)
        if user_dict_result[1] ==# -1 && system_dict_result[1] ==# -1
            throw cant_get_result
        endif
        " Merge and unique user dict result and system dict result.
        let a:this._result = [
        \   eskk#dictionary#merge_results(user_dict_result, system_dict_result),
        \   0
        \]
        let a:this._status = s:HR_GOT_RESULT
        return a:this._result
    endif
endfunction "}}}

function! s:henkan_result_select_candidates(this) "{{{
    " Select candidates by getchar()'s character.
    let words = copy(a:this._result[0])
    let word_num_per_page = len(split(g:eskk_select_cand_keys, '\zs'))
    let page_index = 0
    let pages = []
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
                echon printf('%s:%s%s  ', c, word.result,
                \       (has_key(word, 'annotation') ? ';' . word.annotation : ''))
            else
                echon printf('%s:%s  ', c, word.result)
            endif
        endfor
        echon printf('(%d/%d)', page_index, len(pages) - 1)

        " Get char for selected candidate.
        try
            let char = s:getchar()
        catch /^Vim:Interrupt$/
            throw 'eskk: leave henkan select'
        endtry


        if eskk#is_special_lhs(char, 'phase:henkan-select:escape')
            throw 'eskk: leave henkan select'
        elseif eskk#is_special_lhs(char, 'phase:henkan-select:next-page')
            if eskk#util#has_idx(pages, page_index + 1)
                let page_index += 1
            else
                " No more pages. Register new word.
                return a:this._dict.register_word(a:this)
            endif
        elseif eskk#is_special_lhs(char, 'phase:henkan-select:prev-page')
            if eskk#util#has_idx(pages, page_index - 1)
                let page_index -= 1
            else
                throw 'eskk: leave henkan select'
            endif
        elseif stridx(g:eskk_select_cand_keys, char) != -1
            let selected = g:eskk_select_cand_keys[stridx(g:eskk_select_cand_keys, char)]
            call eskk#util#logf("Selected char '%s'.", selected)
            for [c, word] in pages[page_index]
                if c ==# selected
                    " Dummy result list for `word`.
                    " Note that assigning to index number is useless.
                    return word.result . a:this._okuri
                endif
            endfor
        endif
    endwhile
endfunction "}}}

function! s:getchar(...) "{{{
    let c = call('getchar', a:000)
    return type(c) == type("") ? c : nr2char(c)
endfunction "}}}


function! s:henkan_result.get_candidate() dict "{{{
    call eskk#util#logf('Get candidate for: buftable.dump() = %s', string(self.buftable.dump()))
    let counter = g:eskk_show_candidates_count >= 0 ? g:eskk_show_candidates_count : 0
    try
        let result = s:henkan_result_get_result(self)
        let [candidates, idx] = result
        call eskk#util#logf('idx = %d, counter = %d', idx, counter)
        if idx >= counter
            try
                return s:henkan_result_select_candidates(self)
            catch /^eskk: leave henkan select$/
                if result[1] > 0
                    let result[1] -= 1
                endif
                return candidates[result[1]].result . self._okuri
            endtry
        else
            return candidates[idx].result . self._okuri
        endif
    catch /^eskk: dictionary look up error:/
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
\   '_ftime_at_read': 0,
\   '_loaded': 0,
\   'okuri_ari_lnum': -1,
\   'okuri_nasi_lnum': -1,
\   'path': '',
\   'sorted': 0,
\   'encoding': '',
\}

function! s:physical_dict_new(path, sorted, encoding) "{{{
    return extend(
    \   deepcopy(s:physical_dict),
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

    if self._loaded && !force
        return self._content_lines
    endif

    let path = self.path
    try
        if filereadable(path)
            call eskk#util#logf('reading %s...', path)
            let self._content_lines  = readfile(path)
            call s:physical_dict_parse_lines(self, self._content_lines)
            call eskk#util#logf('reading %s... - done.', path)
        else
            call eskk#util#logf("Can't read '%s'!", path)
        endif
    catch /^eskk: parse error/
        call eskk#util#log('warning: ' . v:exception)
        let self.okuri_ari_lnum = -1
        let self.okuri_nasi_lnum = -1
    endtry
    let self._ftime_at_read = getftime(path)
    let self._loaded = 1

    return self._content_lines
endfunction "}}}

function! s:physical_dict.set_lines(lines) dict "{{{
    try
        let self._content_lines  = a:lines
        call s:physical_dict_parse_lines(self, a:lines)
    catch /^eskk: parse error/
        call eskk#util#log('warning: ' . v:exception)
        let self.okuri_ari_lnum = -1
        let self.okuri_nasi_lnum = -1
    endtry
    let self._loaded = 1

    return self._content_lines
endfunction "}}}

function! s:physical_dict_parse_lines(self, lines) "{{{
    let self = a:self

    let self.okuri_ari_lnum  = index(self._content_lines, ';; okuri-ari entries.')
    if self.okuri_ari_lnum ==# -1
        throw eskk#parse_error(['eskk', 'dictionary'], "SKK dictionary parse error")
    endif
    let self.okuri_nasi_lnum = index(self._content_lines, ';; okuri-nasi entries.')
    if self.okuri_nasi_lnum ==# -1
        throw eskk#parse_error(['eskk', 'dictionary'], "SKK dictionary parse error")
    endif
endfunction "}}}

function! s:physical_dict.is_valid() dict "{{{
    " Succeeded to parse SKK dictionary.
    call self.get_lines()
    return self.okuri_ari_lnum >= 0 && self.okuri_nasi_lnum >= 0
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
\   '_user_dict': {},
\   '_system_dict': {},
\   '_added_words': [],
\}

function! eskk#dictionary#new(user_dict, system_dict) "{{{
    return extend(
    \   deepcopy(s:dict),
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



function! s:dict.refer(buftable) dict "{{{
    let henkan_buf_str = a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    let okuri_buf_str = a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
    let key       = henkan_buf_str.get_matched_filter()
    let okuri     = okuri_buf_str.get_matched_filter()
    let okuri_rom = okuri_buf_str.get_matched_rom()

    let added = []
    for [added_input, added_key, added_okuri, added_okuri_rom] in self._added_words
        if added_key ==# key && added_okuri_rom[0] ==# okuri_rom[0]
            call add(added, added_input)
        endif
    endfor

    return s:henkan_result_new(
    \   self,
    \   key,
    \   okuri_rom,
    \   okuri,
    \   deepcopy(a:buftable, 1),
    \   added,
    \)
endfunction "}}}

function! s:dict.register_word(henkan_result) dict "{{{
    let buftable  = a:henkan_result.buftable
    let key       = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN).get_matched_filter()
    let okuri     = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI).get_matched_filter()
    let okuri_rom = buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI).get_matched_rom()


    " inputsave()
    let success = 0
    if inputsave() !=# success
        call eskk#util#log("warning: inputsave() failed")
    endif

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
        let input  = input(prompt)
    catch /^Vim:Interrupt$/
        let input = ''
    finally
        " Destroy current eskk instance.
        try
            call eskk#destroy_current_instance()
        catch /^eskk:/
            call eskk#log('warning: ' . eskk#get_exception_message(v:exception))
        endtry

        " Enable eskk mapping if it has been disabled.
        call eskk#map_all_keys()

        " Restore `&imsearch`.
        let &l:imsearch = save_imsearch

        " inputrestore()
        if inputrestore() !=# success
            call eskk#util#log("warning: inputrestore() failed")
        endif
    endtry


    if input != ''
        call add(self._added_words, [input, key, okuri, okuri_rom])
        return input . okuri
    else
        return key . okuri
    endif
endfunction "}}}

function! s:dict.is_modified() dict "{{{
    return !empty(self._added_words)
endfunction "}}}

function! s:dict.update_dictionary() dict "{{{
    if !self.is_modified()
        return
    endif
    let user_dict_exists = filereadable(self._user_dict.path)
    if !self._user_dict.is_valid() && user_dict_exists
        " TODO:
        " Echo "user dictionary format is invalid. overwrite with new words?".
        " And do not read, just overwrite it with new words.
        return
    endif

    if self._user_dict._ftime_at_read !=# getftime(self._user_dict.path)
        " Update dictionary's lines.
        call self._user_dict.get_lines(1)
    endif

    if user_dict_exists
        let user_dict_lines = self._user_dict.get_lines()
    else
        " Create new lines.
        let lines = [';; okuri-ari entries.', ';; okuri-nasi entries.']
        call self._user_dict.set_lines(lines)
        let user_dict_lines = lines
    endif

    " Check if a:self.user_dict really does not have added words.
    for [input, key, okuri, okuri_rom] in self._added_words
        let [line, index] = eskk#dictionary#search_next_candidate(self._user_dict, key, okuri_rom)
        if okuri_rom != ''
            let lnum = self._user_dict.okuri_ari_lnum + 1
        else
            let lnum = self._user_dict.okuri_nasi_lnum + 1
        endif
        " Delete old entry.
        if index !=# -1
            call remove(user_dict_lines, index)
            call eskk#util#assert(line != '')
        endif
        " Merge old one and create new entry.
        call insert(
        \   user_dict_lines,
        \   eskk#dictionary#create_new_entry(input, key, okuri, okuri_rom, line),
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
            let msg = printf("can't write to '%s'.", self._user_dict.path)
            throw eskk#internal_error(['eskk', 'dictionary'], msg)
        endif
    catch
        echohl WarningMsg
        echo "\r" . save_msg . "Error. Please check permission of"
        \    "'" . self._user_dict.path . "' - " . v:exception
        echohl None
    endtry
endfunction "}}}

function! s:dict.get_kanji(buftable) dict "{{{
    let henkan_buf_str = a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_HENKAN)
    let okuri_buf_str = a:buftable.get_buf_str(g:eskk#buftable#HENKAN_PHASE_OKURI)
    let key       = henkan_buf_str.get_matched_filter()
    let okuri     = okuri_buf_str.get_matched_filter()
    let okuri_rom = okuri_buf_str.get_matched_rom()

    if key == ''
        return []
    endif

    " Convert `self._added_words` to same value
    " of return value of `eskk#dictionary#parse_skk_dict_line()`.
    let added = []
    for [added_input, added_key, added_okuri, added_okuri_rom] in self._added_words
        call add(added, [added_key, [{'result': added_input . added_okuri_rom}]])
    endfor

    let lines = eskk#dictionary#search_all_candidates(self._user_dict, key, okuri_rom)
          \ + eskk#dictionary#search_all_candidates(self._system_dict, key, okuri_rom)

    " TODO: Unique duplicated candidates.

    return added + map(lines, 'eskk#dictionary#parse_skk_dict_line(v:val)')
endfunction "}}}

lockvar s:dict
" }}}

" }}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

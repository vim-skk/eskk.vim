" vim:foldmethod=marker:fen:
scriptencoding utf-8


" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! eskk#commands#define() abort "{{{
    command!
    \   -nargs=+
    \   EskkMap
    \   call eskk#map#_cmd_eskk_map(<q-args>)

    command!
    \   -bar
    \   EskkForgetRegisteredWords
    \   call s:cmd_forget_registered_words()

    command!
    \   -bar -bang
    \   EskkUpdateDictionary
    \   call s:cmd_update_dictionary(<bang>0)

    command!
    \   -bar -bang -nargs=* -complete=file
    \   EskkFixDictionary
    \   call s:cmd_fix_dictionary(<q-args>, <bang>0)
endfunction "}}}

function! s:cmd_forget_registered_words() abort "{{{
    let skk_dict = eskk#get_skk_dict()
    call skk_dict.forget_all_words()
endfunction "}}}

function! s:cmd_update_dictionary(silent) abort "{{{
    try
        let verbose = !a:silent
        let dict = eskk#get_skk_dict()
        call dict.update_dictionary(verbose)
    catch
        call eskk#logger#write_error_log_file(
        \   {},
        \   eskk#util#build_error(
        \       ['eskk', 'commands'],
        \       ['error occurred while :'
        \           . 'EskkUpdateDictionary: '.v:exception])
        \)
    endtry
endfunction "}}}

function! s:cmd_fix_dictionary(path, skip_prompt) abort "{{{
    let path = a:path !=# '' ? a:path :
    \          exists('g:eskk#dictionary.path') ? g:eskk#dictionary.path : ''
    let path = expand(path)
    if !filereadable(path)
        echohl ErrorMsg
        echom "'".path."' is not readable."
        echohl None
        return
    endif
    if !filewritable(path)
        echohl ErrorMsg
        echom "'".path."' is not writable."
        echohl None
        return
    endif

    let msg = "May I fix the dictionary '" . fnamemodify(path, ':~') . "'? [y/n]:"
    if a:skip_prompt || input(msg) =~? '^y'
        " Backup current dictionary.
        if eskk#util#copy_file(path, path . '.bak')
            echom "original file was moved to '" . path . ".bak'."
        else
            call eskk#logger#warn(
            \   "Could not back up dictionary '" . path . "'."
            \   . " skip fixing the dictionary."
            \)
            return
        endif

        " NOTE: okuri_nasi includes abbrev candidates.
        let okuri_ari = s:Collector.new(
        \   '^\([^ \ta-z]\+[a-z]\)[a-z]*[ \t]\+\(.\+\)')
        let okuri_nasi = s:Collector.new(
        \   '^\([^ \t]\+\)[ \t]\+\(.\+\)')

        let lines = readfile(path)
        let comment = '^\s*;'
        for line in lines
            if line =~# comment
                continue
            endif
            for collector in [okuri_ari, okuri_nasi]
                if collector.add_matching_line(line)
                    break
                endif
            endfor
        endfor

        try
            call writefile(
            \   [';; okuri-ari entries.']
            \       + okuri_ari.get_candidates()
            \       + [';; okuri-nasi entries.']
            \       + okuri_nasi.get_candidates(),
            \   path
            \)
        catch
            call eskk#logger#warn(
            \   ':EskkFixDictionary - '
            \   . "Could not write to '"
            \   . fnamemodify(path, ':~')
            \   . "'."
            \)
            call eskk#logger#warn("Cause: " . v:exception)
        endtry
    endif
endfunction "}}}


" s:Collector {{{

let s:Collector = {
\   'hira_vs_candidates': {},
\   'key_order' : [],
\   'pattern' : '',
\}

function s:Collector.new(pattern) abort
    let obj = deepcopy(self)
    let obj.pattern = a:pattern
    return obj
endfunction

function s:Collector.add_matching_line(line) abort
    let m = matchlist(a:line, self.pattern)
    if !empty(m)
        let [hira, kanji] = m[1:2]
        if !has_key(self.hira_vs_candidates, hira)
            let self.hira_vs_candidates[hira] = eskk#util#create_data_ordered_set()
            call add(self.key_order, hira)
        endif
        for c in split(kanji, '/')
            " Remove the empty annotation.
            let c = substitute(c, ';$', '', '')
            " Skip the empty candidate.
            if c ==# ''
                continue
            endif
            " Add a candidate to self.hira_vs_candidates[hira].
            call self.hira_vs_candidates[hira].push(c)
        endfor
        return 1
    else
        return 0
    endif
endfunction

function s:Collector.get_candidates() abort
    return
    \   map(
    \       map(
    \           copy(self.key_order),
    \           '[v:val, self.hira_vs_candidates[v:val]]'
    \       ),
    \       'v:val[0] . " /" . join(v:val[1].to_list(), "/") . "/"'
    \   )
endfunction

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

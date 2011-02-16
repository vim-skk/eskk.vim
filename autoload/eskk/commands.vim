" vim:foldmethod=marker:fen:
scriptencoding utf-8


" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! eskk#commands#define() "{{{
    command!
    \   -nargs=+
    \   EskkMap
    \   call eskk#mappings#_cmd_eskk_map(<q-args>)

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

    command!
    \   -bar
    \   EskkReload
    \   call eskk#reload()
endfunction "}}}

function! s:cmd_forget_registered_words() "{{{
    call eskk#get_skk_dict().forget_all_words()
endfunction "}}}

function! s:cmd_update_dictionary(silent) "{{{
    let dict = eskk#get_skk_dict()
    execute (a:silent ? 'silent' : '') 'call dict.update_dictionary()'
endfunction "}}}

function! s:cmd_fix_dictionary(path, skip_prompt) "{{{
    let path = a:path != '' ? a:path :
    \          exists('g:eskk#dictionary.path') ? g:eskk#dictionary.path : ''
    let path = expand(path)
    if !filereadable(path)
        return
    endif

    let msg = "May I fix the dictionary '" . fnamemodify(path, ':~') . "'? [y/n]:"
    if a:skip_prompt || input(msg) =~? '^y'
        " Backup current dictionary.
        if eskk#util#copy_file(path, path . '.bak')
            echom "original file was moved to '" . path . ".bak'."
        else
            call eskk#util#warn(
            \   "Could not back up dictionary '" . path . "'."
            \   . " skip fixing the dictionary."
            \)
            return
        endif

        " Fix dictionary lines.
        let lambda = {'candidates': {}}
        function lambda.match_and_add(line, pattern)
            let m = matchlist(a:line, a:pattern)
            if !empty(m)
                let [hira, kanji] = m[1:2]
                let candidates = {}
                for i in split(kanji, '/') + get(self.candidates, hira, [])
                    let candidates[i] = 1
                endfor
                let self.candidates[hira] = keys(candidates)
                return 1
            else
                return 0
            endif
        endfunction
        function lambda.get_candidates()
            return values(map(
            \   self.candidates,
            \   'v:key . " /" . join(v:val, "/") . "/"'
            \))
        endfunction

        let okuri_ari = deepcopy(lambda)
        let okuri_nasi = deepcopy(lambda)
        for line in readfile(path)
            if line =~ '^\s*;'
                " comment
                continue
            endif
            if okuri_ari.match_and_add(line, '^\(\S\+[a-z]\)[ \t]\+\(.\+\)')
                continue
            endif

            call okuri_nasi.match_and_add(line, '^\(\S\+[^a-z]\)[ \t]\+\(.\+\)')
        endfor

        let r = writefile(
        \   [';; okuri-ari entries.']
        \       + okuri_ari.get_candidates()
        \       + [';; okuri-nasi entries.']
        \       + okuri_nasi.get_candidates(),
        \   path
        \)
        if r == -1
            call eskk#util#warn(
            \   ':EskkFixDictionary - '
            \   . "Could not write to '"
            \   . fnamemodify(path, ':~')
            \   . "'."
            \)
        endif
    endif
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

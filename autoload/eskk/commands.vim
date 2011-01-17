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
    if a:skip_prompt || !a:skip_prompt && input(msg) =~? '^y'
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
        let okuri_ari = {}
        let okuri_nasi = {}
        for line in readfile(path)
            if line =~ '^\s*;'
                " comment
                continue
            endif

            let ari_match =
            \   matchlist(line, '^\(\S\+[a-z]\)[ \t]\+\(.\+\)')
            if !empty(ari_match)
                " okuri-ari entry
                let [hira, kanji] = ari_match[1:2]
                let kanji_list = split(kanji, '/')
                if has_key(okuri_ari, hira)
                    let okuri_ari[hira] += kanji_list
                else
                    let okuri_ari[hira] = kanji_list
                endif
                continue
            endif

            let nasi_match =
            \   matchlist(line, '^\(\S\+[^a-z]\)[ \t]\+\(.\+\)')
            if !empty(nasi_match)
                " okuri-nasi entry
                let [hira, kanji] = nasi_match[1:2]
                let kanji_list = split(kanji, '/')
                if has_key(okuri_nasi, hira)
                    let okuri_nasi[hira] += kanji_list
                else
                    let okuri_nasi[hira] = kanji_list
                endif
            endif
        endfor

        let build_line =
        \   'v:key . " /" . join(v:val, "/") . "/"'
        let r = writefile(
        \   [';; okuri-ari entries.']
        \       + values(map(okuri_ari, build_line))
        \       + [';; okuri-nasi entries.']
        \       + values(map(okuri_nasi, build_line)),
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

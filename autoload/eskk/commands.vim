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
endfunction "}}}

function! s:cmd_forget_registered_words() "{{{
    call eskk#get_skk_dict().forget_all_words()
endfunction "}}}

function! s:cmd_update_dictionary(silent) "{{{
    call eskk#_initialize()
    let dict = eskk#get_skk_dict()
    execute (a:silent ? 'silent' : '') 'call dict.update_dictionary()'
endfunction "}}}

function! s:cmd_fix_dictionary(path, skip_prompt) "{{{
    let path = a:path != '' ? a:path :
    \          exists('g:eskk#dictionary.path') ? g:eskk#dictionary.path : ''
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
        let dup = {}
        let ari = []
        let nasi = []
        for line in readfile(path)
            if has_key(dup, line)
                continue
            endif
            let dup[line] = 1

            if line =~ '^\s*;'
                " comment
            elseif line =~ '^\S\+\w '
                " okuri-ari entry
                call add(ari, line)
            elseif line =~ '^\S\+\W '
                " okuri-nasi entry
                call add(nasi, line)
            endif
        endfor
        let lines =
        \   [';; okuri-ari entries.'] + ari
        \   + [';; okuri-nasi entries.']  + nasi

        if writefile(lines, path) == -1
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

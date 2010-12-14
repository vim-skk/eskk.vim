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
  \   -bar -bang
  \   EskkFixDictionary
  \   call s:cmd_fix_dictionary(<bang>0)
endfunction "}}}

function! s:cmd_forget_registered_words() "{{{
    call eskk#get_skk_dict().forget_all_words()
endfunction "}}}

function! s:cmd_update_dictionary(silent) "{{{
    call eskk#_initialize()
    let dict = eskk#get_skk_dict()
    execute (a:silent ? 'silent' : '') 'call dict.update_dictionary()'
endfunction "}}}

function! s:cmd_fix_dictionary(skip_prompt) "{{{
    call eskk#_initialize()
    let dict = eskk#get_skk_dict()

    let path = fnamemodify(dict.get_user_dict().path, ':~')
    let msg = "May I fix the dictionary '" . path . "'? [y/n]:"
    if a:skip_prompt || !a:skip_prompt && input(msg) =~? '^y'
        " Backup current dictionary.
        let src = dict.get_user_dict().path
        if eskk#util#move_file(src, src . '.bak')
            echom "original file was moved to '" . src . ".bak'."
        else
            call eskk#util#warn(
            \   "Could not back up dictionary '" . src . "'."
            \   . " skip fixing the dictionary."
            \)
            return
        endif

        call dict.fix_dictionary(1)
    endif
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

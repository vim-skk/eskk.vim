" vim:foldmethod=marker:fen:
scriptencoding utf-8


" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

function! eskk#commands#define()  " {{{2
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
endfunction

function! s:cmd_forget_registered_words()
    call eskk#get_skk_dict().forget_all_words()
endfunction

function! s:cmd_update_dictionary(silent)
    let silent = a:0 ? a:1 : 0
    let dict = eskk#get_skk_dict()
    execute (silent ? 'silent' : '') 'call dict.update_dictionary()'
endfunction


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

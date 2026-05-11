" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:run() abort "{{{
  let save_iminsert = &l:iminsert
  try
    call eskk#enable()
    let inst = eskk#get_buffer_instance()
    OK has_key(inst, 'prev_lang_keys')
    OK eskk#is_enabled()

    let &l:iminsert = 0
    OK eskk#is_enabled()

    call eskk#toggle()
    let inst = eskk#get_buffer_instance()
    OK !has_key(inst, 'prev_lang_keys')
    OK !eskk#is_enabled()

    call eskk#enable()
    let &l:iminsert = 0
    let &l:imsearch = 1
    OK eskk#is_enabled()

    call eskk#disable()
    let inst = eskk#get_buffer_instance()
    OK !has_key(inst, 'prev_lang_keys')
    OK !eskk#is_enabled()
  finally
    call eskk#disable()
    let &l:iminsert = save_iminsert
  endtry
endfunction "}}}

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

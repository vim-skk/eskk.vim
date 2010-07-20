" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:run()
    for name in eskk#table#get_all_registered_tables()
        try
            call eskk#table#create(name)
            Ok 0, 'eskk#table#create() must throw exception for registered table'
        catch
            Ok 1, 'eskk#table#create() must throw exception for registered table'
        endtry
    endfor

    for name in eskk#table#get_all_tables() + eskk#table#get_all_registered_tables()
        Ok eskk#table#has_table(name), printf('%s must be registered', name)
    endfor
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

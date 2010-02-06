" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


func! s:get_mode_func(mode, func_str)
    return printf('skk7#mode#%s#%s', a:mode, a:func_str)
endfunc

func! s:run()
    for m in skk7#get_registered_modes()
        for f in [
        \   'load',
        \   'initialize',
        \   'cb_now_working',
        \   'filter_main',
        \   'has_candidates'
        \]
            let func = s:get_mode_func(m, f)
            call skk7#test#ok(
            \   skk7#util#exists_func(func),
            \   printf("exists '%s'.", func)
            \)
        endfor
    endfor
endfunc


" ただ変数が関数ローカルじゃなく
" グローバルになってしまうのを防ぐために
" わざわざ関数を作っている。
Skk7TestBegin
call s:run()
Skk7TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

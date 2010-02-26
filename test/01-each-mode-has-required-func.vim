" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


func! s:modef(mode, varname)
    return printf('eskk#mode#%s#%s', a:mode, a:varname)
endfunc

func! s:run()
    for m in eskk#get_registered_modes()

        " 関数のチェック
        for f in [
        \   'filter_main',
        \]
            let func = s:modef(m, f)
            call simpletap#ok(
            \   simpletap#exists_func(func),
            \   printf("exists '%s'.", func)
            \)
        endfor

        " 変数のチェック
        for v in [
        \   'handle_all_keys',
        \]
            let varname = 'g:' . s:modef(m, v)
            call simpletap#ok(
            \   exists(varname),
            \   printf("exists '%s'.", varname)
            \)
        endfor
    endfor
endfunc


" ただ変数が関数ローカルじゃなく
" グローバルになってしまうのを防ぐために
" わざわざ関数を作っている。
TestBegin
call s:run()
TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

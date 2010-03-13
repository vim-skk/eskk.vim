" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:modef(mode, varname)
    return printf('eskk#mode#%s#%s', a:mode, a:varname)
endfunction

function! s:run()
    for m in eskk#get_registered_modes()

        " 関数のチェック
        for f in [
        \   'filter_main',
        \]
            let func = s:modef(m, f)
            call simpletap#ok(
            \   simpletap#util#really_exists_func(func),
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
endfunction


" ただ変数が関数ローカルじゃなく
" グローバルになってしまうのを防ぐために
" わざわざ関数を作っている。
call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

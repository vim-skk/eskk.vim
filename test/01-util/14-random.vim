" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! s:foreach(from, to, fn)
    let i = a:from
    while i < a:to
        call a:fn.call()
        let i += 1
    endwhile
endfunction

function! s:run()
    let make_random_number = {}
    function! make_random_number.call()
        let i = 1
        while i < 50
            let n = eskk#util#make_random_number(i)
            call simpletap#cmp_ok(0, '<=', n, 'n is greater than 0')
            call simpletap#cmp_ok(n, '<', i, 'n is less than i')
            let i += 1
        endwhile

        Is eskk#util#make_random_number(0), -1,
        \   'eskk#util#make_random_number(): invalid argument'
        Is eskk#util#make_random_number(-1), -1,
        \   'eskk#util#make_random_number(): invalid argument'
        Is eskk#util#make_random_number(-2), -1,
        \   'eskk#util#make_random_number(): invalid argument'
    endfunction

    let make_random_string = {}
    function make_random_string.call()
        let varname = eskk#util#make_random_string(10)
        Diag varname
        Is strlen(varname), 10, "varname length is 10"
    endfunction

    call s:foreach(0, 50, make_random_number)
    call s:foreach(0, 50, make_random_string)
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

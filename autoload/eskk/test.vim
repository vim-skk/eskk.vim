" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! eskk#test#emulate_filter_keys(chars, ...) "{{{
    " This function is written almost for the tests.
    " But maybe this is useful
    " when someone (not me) tries to emulate keys? :)

    let clear_buftable = a:0 ? a:1 : 1
    let ret = ''
    let mapmode = eskk#mappings#get_map_modes()
    for c in split(a:chars, '\zs')
        let r = eskk#filter(c)
        let r = eskk#util#remove_all_ctrl_chars(r, "\<Plug>")

        " Remove `<Plug>(eskk:_filter_redispatch_pre)` beforehand.
        let pre = ''
        if r =~# '(eskk:_filter_redispatch_pre)'
            let pre = maparg('<Plug>(eskk:_filter_redispatch_pre)', mapmode)
            let r = substitute(r, '(eskk:_filter_redispatch_pre)', '', '')
        endif

        " Remove `<Plug>(eskk:_filter_redispatch_post)` beforehand.
        let post = ''
        if r =~# '(eskk:_filter_redispatch_post)'
            let post = maparg('<Plug>(eskk:_filter_redispatch_post)', mapmode)
            let r = substitute(r, '(eskk:_filter_redispatch_post)', '', '')
        endif

        " Remove `<Plug>(eskk:_set_begin_pos)`.
        " it is <expr> and does not effect to result string.
        let r = substitute(r, '(eskk:_set_begin_pos)', '', 'g')

        " Expand normal <Plug> mappings.
        let r = substitute(
        \   r,
        \   '(eskk:[^()]\+)',
        \   '\=eskk#util#key2char(s:do_remap("<Plug>".submatch(0), mapmode))',
        \   'g'
        \)

        let [r, ret] = s:emulate_backspace(r, ret)

        " Handle `<Plug>(eskk:_filter_redispatch_pre)`.
        if pre != ''
            let _ = eval(pre)
            let _ = eskk#util#remove_all_ctrl_chars(r, "\<Plug>")
            let [_, ret] = s:emulate_filter_char(_, ret)
            let _ = substitute(
            \   _,
            \   '(eskk:[^()]\+)',
            \   '\=eskk#util#key2char(s:do_remap("<Plug>".submatch(0), mapmode))',
            \   'g'
            \)
            let ret .= _
            let ret .= s:do_remap(eval(pre), mapmode)
        endif

        " Handle rewritten text.
        let ret .= r

        " Handle `<Plug>(eskk:_filter_redispatch_post)`.
        if post != ''
            let _ = eval(post)
            let _ = eskk#util#remove_all_ctrl_chars(_, "\<Plug>")
            let [_, ret] = s:emulate_filter_char(_, ret)
            let _ = substitute(
            \   _,
            \   '(eskk:[^()]\+)',
            \   '\=eskk#util#key2char(s:do_remap("<Plug>".submatch(0), mapmode))',
            \   'g'
            \)
            let ret .= _
        endif
    endfor

    " For convenience.
    if clear_buftable
        let buftable = eskk#get_buftable()
        call buftable.clear_all()
    endif

    return ret
endfunction "}}}
function! s:do_remap(map, modes) "{{{
    let m = maparg(a:map, a:modes)
    return m != '' ? m : a:map
endfunction "}}}
function! s:emulate_backspace(str, cur_ret) "{{{
    let r = a:str
    let ret = a:cur_ret
    for bs in ["\<BS>", "\<C-h>"]
        while 1
            let [r, pos] = eskk#util#remove_ctrl_char(r, bs)
            if pos ==# -1
                break
            endif
            if pos ==# 0
                if ret == ''
                    let r = bs . r
                    break
                else
                    let ret = eskk#util#mb_chop(ret)
                endif
            else
                let before = strpart(r, 0, pos)
                let after = strpart(r, pos)
                let before = eskk#util#mb_chop(before)
                let r = before . after
            endif
        endwhile
    endfor
    return [r, ret]
endfunction "}}}
function! s:emulate_filter_char(str, cur_ret) "{{{
    let r = a:str
    let ret = a:cur_ret
    while 1
        let pat = '(eskk:filter:\([^()]*\))'.'\C'
        let m = matchlist(r, pat)
        if empty(m)
            break
        endif
        let char = m[1]
        let r = substitute(r, pat, '', '')
        let _ = eskk#test#emulate_filter_keys(char, 0)
        let [_, ret] = s:emulate_backspace(_, ret)
        let r .= _
    endwhile
    return [r, ret]
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



func! s:run()
    call eskk#mapclear()

    call simpletap#is(eskk#maparg(';'), '')
    " call simpletap#ok(! eskk#hasmapto('<Plug>(eskk-sticky)-key'))

    call eskk#map(';', '<Plug>(eskk-sticky-key)')

    call simpletap#is(eskk#maparg(';'), '<Plug>(eskk-sticky-key)')
    " call simpletap#ok(eskk#hasmapto('<Plug>(eskk-sticky)-key'))


    call simpletap#is(eskk#mapcheck('f'), [])
    call eskk#map('foo', '<Plug>(eskk-sticky-key)')
    call simpletap#is(eskk#mapcheck('f'), ['<Plug>(eskk-sticky-key)'])
    call simpletap#is(eskk#mapcheck('fo'), ['<Plug>(eskk-sticky-key)'])
    call simpletap#is(eskk#mapcheck('foo'), ['<Plug>(eskk-sticky-key)'])

    call eskk#unmap('fo')
    call simpletap#is(eskk#mapcheck('f'), ['<Plug>(eskk-sticky-key)'])
    call simpletap#is(eskk#mapcheck('fo'), ['<Plug>(eskk-sticky-key)'])
    call simpletap#is(eskk#mapcheck('foo'), ['<Plug>(eskk-sticky-key)'])

    call eskk#unmap('foo')
    call simpletap#is(eskk#mapcheck('f'), [])
    call simpletap#is(eskk#mapcheck('fo'), [])
    call simpletap#is(eskk#mapcheck('foo'), [])


    call simpletap#diag("eskk#map('q', '<Plug>(eskk-mode-to-kata)', 'hira')")
    call eskk#map('q', '<Plug>(eskk-mode-to-kata)', 'hira')
    call simpletap#is(eskk#maparg('q'), '')
    call simpletap#is(eskk#maparg('q', 'hira'), '<Plug>(eskk-mode-to-kata)')
    call simpletap#is(eskk#maparg('q', 'kata'), '')

    call simpletap#diag("eskk#map('q', '<Plug>(eskk-mode-to-hira)')")
    call eskk#map('q', '<Plug>(eskk-mode-to-hira)')
    call simpletap#is(eskk#maparg('q'), '<Plug>(eskk-mode-to-hira)')
    call simpletap#is(eskk#maparg('q', 'hira'), '<Plug>(eskk-mode-to-kata)')
    call simpletap#is(eskk#maparg('q', 'kata'), '')

    call simpletap#diag("eskk#unmap('q')")
    call eskk#unmap('q')
    call simpletap#is(eskk#maparg('q'), '')
    call simpletap#is(eskk#maparg('q', 'hira'), '<Plug>(eskk-mode-to-kata)')
    call simpletap#is(eskk#maparg('q', 'kata'), '')

    call simpletap#diag("eskk#unmap('q', 'hira')")
    call eskk#unmap('q', 'hira')
    call simpletap#is(eskk#maparg('q'), '')
    call simpletap#is(eskk#maparg('q', 'hira'), '')
    call simpletap#is(eskk#maparg('q', 'kata'), '')


    " TODO
    " - force
    " - mapcheck() spec on :help
endfunc


TestBegin
call s:run()
TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



func! s:run()
    call skk7#mapclear()

    call simpletap#is(skk7#maparg(';'), '')
    " call simpletap#ok(! skk7#hasmapto('<Plug>(skk7-sticky)-key'))

    call skk7#map(';', '<Plug>(skk7-sticky-key)')

    call simpletap#is(skk7#maparg(';'), '<Plug>(skk7-sticky-key)')
    " call simpletap#ok(skk7#hasmapto('<Plug>(skk7-sticky)-key'))


    call simpletap#is(skk7#mapcheck('f'), [])
    call skk7#map('foo', '<Plug>(skk7-sticky-key)')
    call simpletap#is(skk7#mapcheck('f'), ['<Plug>(skk7-sticky-key)'])
    call simpletap#is(skk7#mapcheck('fo'), ['<Plug>(skk7-sticky-key)'])
    call simpletap#is(skk7#mapcheck('foo'), ['<Plug>(skk7-sticky-key)'])

    call skk7#unmap('fo')
    call simpletap#is(skk7#mapcheck('f'), ['<Plug>(skk7-sticky-key)'])
    call simpletap#is(skk7#mapcheck('fo'), ['<Plug>(skk7-sticky-key)'])
    call simpletap#is(skk7#mapcheck('foo'), ['<Plug>(skk7-sticky-key)'])

    call skk7#unmap('foo')
    call simpletap#is(skk7#mapcheck('f'), [])
    call simpletap#is(skk7#mapcheck('fo'), [])
    call simpletap#is(skk7#mapcheck('foo'), [])


    call simpletap#diag("skk7#map('q', '<Plug>(skk7-mode-to-kata)', 'hira')")
    call skk7#map('q', '<Plug>(skk7-mode-to-kata)', 'hira')
    call simpletap#is(skk7#maparg('q'), '')
    call simpletap#is(skk7#maparg('q', 'hira'), '<Plug>(skk7-mode-to-kata)')
    call simpletap#is(skk7#maparg('q', 'kata'), '')

    call simpletap#diag("skk7#map('q', '<Plug>(skk7-mode-to-hira)')")
    call skk7#map('q', '<Plug>(skk7-mode-to-hira)')
    call simpletap#is(skk7#maparg('q'), '<Plug>(skk7-mode-to-hira)')
    call simpletap#is(skk7#maparg('q', 'hira'), '<Plug>(skk7-mode-to-kata)')
    call simpletap#is(skk7#maparg('q', 'kata'), '')

    call simpletap#diag("skk7#unmap('q')")
    call skk7#unmap('q')
    call simpletap#is(skk7#maparg('q'), '')
    call simpletap#is(skk7#maparg('q', 'hira'), '<Plug>(skk7-mode-to-kata)')
    call simpletap#is(skk7#maparg('q', 'kata'), '')

    call simpletap#diag("skk7#unmap('q', 'hira')")
    call skk7#unmap('q', 'hira')
    call simpletap#is(skk7#maparg('q'), '')
    call simpletap#is(skk7#maparg('q', 'hira'), '')
    call simpletap#is(skk7#maparg('q', 'kata'), '')


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

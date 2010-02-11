" vim:foldmethod=marker:fen:
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



func! s:run()
    call skk7#mapclear()

    call skk7#test#is(skk7#maparg(';'), '')
    " call skk7#test#ok(! skk7#hasmapto('<Plug>(skk7-sticky)-key'))

    call skk7#map(';', '<Plug>(skk7-sticky-key)')

    call skk7#test#is(skk7#maparg(';'), '<Plug>(skk7-sticky-key)')
    " call skk7#test#ok(skk7#hasmapto('<Plug>(skk7-sticky)-key'))


    call skk7#test#is(skk7#mapcheck('f'), [])
    call skk7#map('foo', '<Plug>(skk7-sticky-key)')
    call skk7#test#is(skk7#mapcheck('f'), ['<Plug>(skk7-sticky-key)'])
    call skk7#test#is(skk7#mapcheck('fo'), ['<Plug>(skk7-sticky-key)'])
    call skk7#test#is(skk7#mapcheck('foo'), ['<Plug>(skk7-sticky-key)'])

    call skk7#unmap('fo')
    call skk7#test#is(skk7#mapcheck('f'), ['<Plug>(skk7-sticky-key)'])
    call skk7#test#is(skk7#mapcheck('fo'), ['<Plug>(skk7-sticky-key)'])
    call skk7#test#is(skk7#mapcheck('foo'), ['<Plug>(skk7-sticky-key)'])

    call skk7#unmap('foo')
    call skk7#test#is(skk7#mapcheck('f'), [])
    call skk7#test#is(skk7#mapcheck('fo'), [])
    call skk7#test#is(skk7#mapcheck('foo'), [])


    call skk7#test#diag("skk7#map('q', '<Plug>(skk7-mode-to-kata)', 'hira')")
    call skk7#map('q', '<Plug>(skk7-mode-to-kata)', 'hira')
    call skk7#test#is(skk7#maparg('q'), '')
    call skk7#test#is(skk7#maparg('q', 'hira'), '<Plug>(skk7-mode-to-kata)')
    call skk7#test#is(skk7#maparg('q', 'kata'), '')

    call skk7#test#diag("skk7#map('q', '<Plug>(skk7-mode-to-hira)')")
    call skk7#map('q', '<Plug>(skk7-mode-to-hira)')
    call skk7#test#is(skk7#maparg('q'), '<Plug>(skk7-mode-to-hira)')
    call skk7#test#is(skk7#maparg('q', 'hira'), '<Plug>(skk7-mode-to-kata)')
    call skk7#test#is(skk7#maparg('q', 'kata'), '')

    call skk7#test#diag("skk7#unmap('q')")
    call skk7#unmap('q')
    call skk7#test#is(skk7#maparg('q'), '')
    call skk7#test#is(skk7#maparg('q', 'hira'), '<Plug>(skk7-mode-to-kata)')
    call skk7#test#is(skk7#maparg('q', 'kata'), '')

    call skk7#test#diag("skk7#unmap('q', 'hira')")
    call skk7#unmap('q', 'hira')
    call skk7#test#is(skk7#maparg('q'), '')
    call skk7#test#is(skk7#maparg('q', 'hira'), '')
    call skk7#test#is(skk7#maparg('q', 'kata'), '')


    " TODO
    " - force
    " - mapcheck() spec on :help
endfunc


Skk7TestBegin
call s:run()
Skk7TestEnd


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

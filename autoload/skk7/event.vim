" vim:foldmethod=marker:fen:
scriptencoding utf-8

" See 'plugin/skk7.vim' about the license.

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



let s:skk7_events = {}

" En-queue a:event to s:skk7_events.
" These functions can register following events:
" - MapmodeLEnter
" - MapmodeLLeave
" - MapmodeICEnter
" - MapmodeICLeave

" Each event's structure:
" command:
"   {'cmd': cmd, 'is_cmd': 1}
" function:
"   {'fn': Fn, 'args': args, 'is_cmd': 0}



" Str event: Event name
func! skk7#event#register_invoked(event) "{{{
    if !skk7#event#is_supported(a:event)
        let s:skk7_events[a:event] = []
    endif
endfunc "}}}


" Num id: Index number of s:skk7_events
" Str event: Event name
" Str cmd: Command to enqueue
func! skk7#event#register_command(event, cmd) "{{{
    if !skk7#event#is_supported(a:event)
        throw printf("skk7: event: '%s' is not supported event name.", a:event)
    endif
    call s:register(a:event, s:create_event(a:cmd, [], 1))
endfunc "}}}

" Num id: Index number of s:skk7_events
" Dict events: Events dictionary to be enqueued
" Str event: Event name
" Callable Fn: Function to call
" List args: Arguments passing to function
" Bool eval_p: If true, evaluate args when execute.
func! skk7#event#register_function(event, Fn, args, ...) "{{{
    let eval_p = a:0 != 0 ? a:1 : 0
    if !skk7#event#is_supported(a:event)
        throw printf("skk7: event: '%s' is not supported event name.", a:event)
    endif
    call s:register(a:event, s:create_event(a:Fn, a:args, 0, eval_p))
endfunc "}}}

" Str event: Event name
func! skk7#event#is_supported(event) "{{{
    return has_key(s:skk7_events, a:event)
endfunc "}}}

" Str event: Event name
func! skk7#event#execute(event) "{{{
    if !skk7#event#is_supported(a:event)
        " Do not throw an error.
        " Just ignore non-supported event.
        return
    endif

    for st in s:skk7_events[a:event]
        call s:dispatch(st)
    endfor
endfunc "}}}



" Add event structure.
func! s:register(event, st) "{{{
    call add(s:skk7_events[a:event], a:st)
endfunc "}}}

" Create event structure.
func! s:create_event(Fn_or_cmd, args, is_cmd, eval_p) "{{{
    if a:is_cmd
        return {'cmd': a:Fn_or_cmd, 'is_cmd': 1}
    else
        return {'fn': a:Fn_or_cmd, 'args': a:args, 'eval': a:eval_p, 'is_cmd': 0}
    endif
endfunc "}}}

" Execute command or function.
func! s:dispatch(st) "{{{
    if a:st.is_cmd
        execute a:st.cmd
        return
    else
        return call(a:st.fn, (a:st.eval ? eval(a:st.args) : a:st.args))
    endif
endfunc "}}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

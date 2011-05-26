" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let g:vice#version = str2nr(printf('%02d%02d%03d', 0, 1, 5))

" Interfaces {{{

function! vice#load() "{{{
    " dummy function to load this script
endfunction "}}}

function! vice#class(class_name, sid, ...) "{{{
    " FIXME: hmm, all members including parents' members
    " are initialized here.
    let options = a:0 ? a:1 : {}

    let obj = {}
    if get(options, 'auto_clone_method', 0)
        let obj.clone = s:get_local_func('Clonable_clone')
    endif
    if get(options, 'auto_new_method', 0)
        let obj.new = s:get_local_func('Clonable_clone')
    endif

    return extend(
    \   deepcopy(s:Class),
    \   {
    \       '_class_name': a:class_name,
    \       '_sid': a:sid,
    \       '_object': obj,
    \       '_builders': [],
    \       '_super': {},
    \       '_opt_generate_stub': get(options, 'generate_stub', 0),
    \   },
    \   'force'
    \)
endfunction "}}}

function! vice#trait(class_name, sid, ...) "{{{
    " FIXME: hmm, all members including parents' members
    " are initialized here.
    let options = a:0 ? a:1 : {}

    let obj = {}
    if get(options, 'auto_clone_method', 0)
        let obj.clone = s:get_local_func('Clonable_clone')
    endif
    if get(options, 'auto_new_method', 0)
        let obj.new = s:get_local_func('Clonable_clone')
    endif

    return extend(
    \   deepcopy(s:Trait),
    \   {
    \       '_class_name': a:class_name,
    \       '_sid': a:sid,
    \       '_object': obj,
    \       '_builders': [],
    \       '_super': {},
    \       '_opt_generate_stub': get(options, 'generate_stub', 0),
    \   },
    \   'force'
    \)
endfunction "}}}

" }}}

" Implementation {{{

function s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun
let s:SID_PREFIX = s:SID()
delfunc s:SID

function! s:get_local_func(function_name) "{{{
    return function(s:format_local_func(a:function_name, s:SID_PREFIX))
endfunction "}}}

function! s:format_local_func(function_name, sid) "{{{
    return '<SNR>' . a:sid . '_' . a:function_name
endfunction "}}}

function! s:get_random_function_string() "{{{
    return substitute(tempname(), '[^a-zA-Z0-9_]', '', 'g')
endfunction "}}}


" s:Builder "{{{
" This provides:
" - .build() which builds ._object
" - .new() which creates object from ._object
"
" s:Builder requires:
" - ._builders (List)

function! s:Builder_new(...) dict "{{{
    call call(self.build, a:000, self)
    return deepcopy(self._object)
endfunction "}}}

function! s:Builder_clone() dict "{{{
    return deepcopy(self)
endfunction "}}}

function! s:Builder_build(...) dict "{{{
    while !empty(self._builders)
        let builder = remove(self._builders, 0)
        call builder.build(self)
    endwhile
    if has_key(self, '_constructor')
        if self._opt_generate_stub
            call call(self._constructor, [self._object] + a:000)
        else
            call call(self._constructor, a:000, self._object)
        endif
    endif
endfunction "}}}

function! s:Builder_add_builder(this, builder) "{{{
    call add(a:this._builders, a:builder)
endfunction "}}}

let s:Builder = {
\   '_object': {},
\   'new': s:get_local_func('Builder_new'),
\   'clone': s:get_local_func('Builder_clone'),
\   'build': s:get_local_func('Builder_build'),
\}
" }}}
" s:MethodManager {{{
" This checks inheritance relationship of `self`
" when adding the method to ._object using .method()
"
" s:MethodManager requires:
" - ._class_name (String)
" - self is a `s:Builder`
" - self is a `s:Extendable`

function! s:MethodManager_method(method_name, ...) dict "{{{
    let options = a:0 ? a:1 : {}
    let full_name = s:MethodManager_format_full_method_name(self, a:method_name)

    " The function `full_name` doesn't exist
    " when .method() is called.
    " So I need to build self._object at .new()
    let builder = {
    \   'full_name': '<SNR>' . self._sid . '_' . full_name,
    \   'method_name': a:method_name,
    \}
    function! builder.build(this)
        if a:this._opt_generate_stub
            " Create a stub for `self.full_name`.
            execute join([
            \   'function! a:this._object[' . string(self.method_name) . '](...)',
            \       'return call(' . string(self.full_name) . ', [self] + a:000)',
            \   'endfunction',
            \], "\n")
        else
            let a:this._object[self.method_name] = function(self.full_name)
        endif
    endfunction
    call s:Builder_add_builder(self, builder)

    " Check an rude override.
    if !get(options, 'override', 0)
    \   && (s:MethodManager_has_method(self, a:method_name)
    \       || s:MethodManager_parent_has_method(self, a:method_name))
        throw "vice: Class '" . self._class_name . "'"
        \       . ": method '" . a:method_name . "' is "
        \       . "already defined, please specify"
        \       . " to .method(" . string(a:method_name) . ", "
        \       . "`{'override': 1}`) to override."
    endif
    let self._methods[a:method_name] = builder.full_name

    return 's:' . full_name
endfunction "}}}

function! s:MethodManager_super(inst, method_name, ...) dict "{{{
    " NOTE: This is called at runtime.
    " Not while building an object.

    " Look up the parent class's method.
    return s:MethodManager_call_parent_method(
    \   self, a:inst, a:method_name, (a:0 ? a:1 : []))
endfunction "}}}

function! s:MethodManager_has_method(this, method_name) "{{{
    return has_key(a:this._methods, a:method_name)
endfunction "}}}

function! s:MethodManager_parent_has_method(this, method_name) "{{{
    if s:Extendable_has_super(a:this)
        let super = s:Extendable_get_super(a:this)
        if s:MethodManager_has_method(super, a:method_name)
            return 1
        endif
        if s:MethodManager_parent_has_method(super, a:method_name)
            return 1
        endif
    endif
    return 0
endfunction "}}}

function! s:MethodManager_get_method(this, method_name, ...) "{{{
    return call('get', [a:this._methods, a:method_name] + (a:0 ? [a:1] : []))
endfunction "}}}

function! s:MethodManager_parent_get_method(this, method_name, ...) "{{{
    if s:Extendable_has_super(a:this)
        let super = s:Extendable_get_super(a:this)
        if s:MethodManager_has_method(super, a:method_name)
            return s:MethodManager_get_method(super, a:method_name)
        endif
        let not_found = {}
        let Value = s:MethodManager_parent_get_method(
        \               super, a:method_name, not_found)
        if Value isnot not_found
            return Value
        endif
    endif
    return a:0 ? a:1 : 0
endfunction "}}}

function! s:MethodManager_call_parent_method(this, inst, method_name, args) "{{{
    let not_found = {}
    let method = s:MethodManager_parent_get_method(
    \               a:this, a:method_name, not_found)
    if method isnot not_found
        if a:this._opt_generate_stub
            return call(method, [a:inst] + a:args)
        else
            return call(method, a:args, a:inst)
        endif
    endif

    throw "vice: Class '" . a:this._class_name . "':"
    \       . " .super() could not find the parent"
    \       . " who has '" . a:method_name . "'."
endfunction "}}}

function! s:MethodManager_format_full_method_name(this, method_name) "{{{
    return a:this._class_name . '_' . a:method_name
endfunction "}}}

let s:MethodManager = {
\   '_sid': -1,
\   '_opt_generate_stub': 0,
\   '_methods': {},
\   'method': s:get_local_func('MethodManager_method'),
\   'super': s:get_local_func('MethodManager_super'),
\}
" }}}
" s:Extendable {{{
" This provides .extends()
"
" s:Extendable requires:
" - ._class_name (String)
" - self is a `s:Builder`

function! s:Extendable_extends(parent_factory) dict "{{{
    if s:Extendable_has_super(self)
        let quote = "'"
        throw "vice: Class '" . self._class_name . "':"
        \       . " multiple inheritance is prohibited:"
        \       . " from Class '" . a:parent_factory._class_name . "',"
        \       . " already inherited from Class '"
        \       . self._super._class_name . "'."
    endif
    let self._super = a:parent_factory

    " a:parent_factory requires s:Builder.
    let builder = {'parent': a:parent_factory}
    function builder.build(this)
        " Build all methods.
        call self.parent.build()
        " Merge missing methods from parent class.
        call extend(a:this._object, self.parent._object, 'keep')
    endfunction
    call s:Builder_add_builder(self, builder)

    return self
endfunction "}}}

function! s:Extendable_has_super(this) "{{{
    return !empty(a:this._super)
endfunction "}}}

function! s:Extendable_get_super(this) "{{{
    return a:this._super
endfunction "}}}

let s:Extendable = {
\   'extends': s:get_local_func('Extendable_extends'),
\   '_super': {},
\}
" }}}
" s:Class {{{
" See vice#class() for the constructor.
"
" Meta object for creating an instance (._object).
"
" s:Class is a `s:Builder`
" s:Class is a `s:MethodManager`
" s:Class is a `s:Extendable`

function! s:Class_accessor(accessor_name, Value) dict "{{{
    let builder = {
    \   'name': a:accessor_name,
    \   'value': a:Value,
    \}
    function builder.build(this)
        let acc = '_accessor_' . self.name
        execute join([
        \   'function a:this._object[' . string(self.name) . '](...)',
        \       'if a:0',
        \           'let self[' . string(acc) . '] = a:1',
        \       'endif',
        \       'return self[' . string(acc) . ']',
        \   'endfunction',
        \], "\n")
        let a:this._object[acc] = self.value
    endfunction
    call s:Builder_add_builder(self, builder)

    return self
endfunction "}}}

function! s:Class_property(property_name, Value) dict "{{{
    let builder = {
    \   'name': a:property_name,
    \   'value': a:Value,
    \}
    function builder.build(this)
        let a:this._object[self.name] = extend(
        \   deepcopy(s:SkeletonProperty),
        \   {'_value': self.value},
        \   'error'
        \)
    endfunction
    call s:Builder_add_builder(self, builder)

    return self
endfunction "}}}
" s:SkeletonProperty {{{

function! s:SkeletonProperty_get() dict "{{{
    return self._value
endfunction "}}}

function! s:SkeletonProperty_set(Value) dict "{{{
    let self._value = a:Value
endfunction "}}}

let s:SkeletonProperty = {
\   'get': s:get_local_func('SkeletonProperty_get'),
\   'set': s:get_local_func('SkeletonProperty_set'),
\}
" }}}

function! s:Class_attribute(attribute_name, Value) dict "{{{
    let builder = {'name': a:attribute_name, 'value': a:Value}
    function builder.build(this)
        let a:this._object[self.name] = self.value
    endfunction
    call s:Builder_add_builder(self, builder)

    return self
endfunction "}}}

function! s:Class_with(trait) dict "{{{
    " Extends all methods before using trait.
    call self.extends(a:trait)

    let builder = {'trait': a:trait, 'has_postponed_once': 0}
    function! builder.build(this)
        " The reason why only trait should postpone
        " its .build() process is that .method() can be
        " after the .with({trait}) .
        " So `self.trait.requires()` method(s)
        " may not exist at the first time.
        if !self.has_postponed_once
            call s:Builder_add_builder(a:this, self)
            let self.has_postponed_once = 1
            return
        endif
        if !has_key(self.trait, 'requires')
            return
        endif
        for prereq_method in self.trait.requires()
            if !has_key(a:this._object, prereq_method)
                throw "vice: required method '" . prereq_method . "'"
                \       . " is not found at the class "
                \       . "'" . a:this._class_name . "'."
            endif
        endfor
    endfunction
    call s:Builder_add_builder(self, builder)

    return self
endfunction "}}}

function! s:Class_constructor() dict "{{{
    let full_name = s:MethodManager_format_full_method_name(
    \   self, s:get_random_function_string()
    \)
    let self._constructor = s:format_local_func(full_name, self._sid)
    return 's:' . full_name
endfunction "}}}

let s:Class = {
\   'property': s:get_local_func('Class_property'),
\   'accessor': s:get_local_func('Class_accessor'),
\   'attribute': s:get_local_func('Class_attribute'),
\   'with': s:get_local_func('Class_with'),
\   'constructor': s:get_local_func('Class_constructor'),
\}
call extend(s:Class, s:Builder, 'error')
call extend(s:Class, s:MethodManager, 'error')
call extend(s:Class, s:Extendable, 'error')
" Implement some properties to satisfy abstruct parents.
let s:Class._builders = []
let s:Class._class_name = ''
" }}}
" s:Trait {{{
" vice#trait() for the constructor.
"
" Meta object for creating a trait.
"
" - s:Trait is a `s:Builder`
" - s:Trait is a `s:MethodManager`
" - s:Trait is a `s:Extendable`

let s:Trait = {}
call extend(s:Trait, s:Builder, 'error')
call extend(s:Trait, s:MethodManager, 'error')
call extend(s:Trait, s:Extendable, 'error')
" Implement some properties to satisfy abstruct parents.
let s:Trait._builders = []    " s:Builder
let s:Trait._class_name = ''    " s:MethodManager

function! s:Trait_new() "{{{
    throw "vice: Trait can't create an instance."
endfunction "}}}

let s:Trait.new = s:get_local_func('Trait_new')
" }}}
" s:Clonable (for .clone() method) {{{
function! s:Clonable_clone() dict "{{{
    return deepcopy(self)
endfunction "}}}
" }}}

" :unlet for memory.
" Those classes' methods/properties are copied already.
unlet s:Builder
unlet s:MethodManager
unlet s:Extendable


" TODO: Type constraints
let s:builtin_types = {}

function! s:initialize_builtin_types() "{{{
    let s:builtin_types['Dict[`a]'] = {}
    function s:builtin_types['Dict[`a]'].where(Value)
        return type(a:Value) == type({})
    endfunction

    let s:builtin_types['List[`a]'] = {}
    function s:builtin_types['List[`a]'].where(Value)
        return type(a:Value) == type([])
    endfunction

    let s:builtin_types['Num'] = {}
    function s:builtin_types['Num'].where(Value)
        return type(a:Value) == type(0)
        \   || type(a:Value) == type(0.0)
    endfunction

    let s:builtin_types['Int'] = {'parent': 'Num'}
    function s:builtin_types['Int'].where(Value)
        return type(a:Value) == type(0)
    endfunction

    let s:builtin_types['Float'] = {'parent': 'Num'}
    function s:builtin_types['Float'].where(Value)
        return type(a:Value) == type(0.0)
    endfunction

    let s:builtin_types['Str'] = {}
    function s:builtin_types['Str'].where(Value)
        return type(a:Value) == type("")
    endfunction

    let s:builtin_types['Fn'] = {}
    function s:builtin_types['Fn'].where(Value)
        return type(a:Value) == type(function('tr'))
    endfunction
endfunction "}}}

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

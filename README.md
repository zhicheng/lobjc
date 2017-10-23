Lemon to Objective-C bridge
===========================

this is an example of [Lemon](https://github.com/lemon-lang/lemon) to Objective-C bridge implementation.

in source:

	lobjc.m is Lemon module
	Value.m is Objective-C's structures and pointer
	Class.m is Objective-C's Class
	Super.m is pseudo Objective-C's super pointer
	Object.m is Objective-C's Object
	Method.m is Objective-C's Selector with binding target
	Selector.m is Objective-C's Selector

Build
-----

copy lemon source code to parent directory and build.
in source code directory `make`

Method translate
----------------

I use `_` replace Objective-C's `:` like all others, such `applicationDidFinishLaunching:` become `applicationDidFinishLaunching_`.

The class has another way call `init`. on class like `NSObject()` will became `[[NSObject alloc] init]`, `UIView(frame=lobjc.CGRectMake(0, 0, 0, 0))` will become `[[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)]`, and `NSObject.alloc().init()` is also available, there is no different between `NSObject()`, but if a class is not from `NSClassFromString`, use `Class()` will create lemon's class instance. `Class.alloc().init()` will create lobjc_Object, that's big different if you use custom Class. Maybe we can swizzling `alloc` fix this.

Super implementation
--------------------

Objective-C's `super` implementation is so weird, and we need call `super` with variable argument, it's very hard archive without write asm, so I use another way implement `super` call, hope it's work. When call `super` I get current object superclass's method, put it on current object with `__super__` prefix, then call the new method on this object, the behavior is just like use original `super`.

Protocol implementation
-----------------------

Lemon Language doesn't have `interface` or `protocol` mechanism (because lemon support multiple inheritance), I implement Objective-C's protocol with lemon's accessor syntax, like

	@lobjc.protocol('UITableViewDelegate')
	class TableViewDelegate(NSObject) {
	}

the reason need protocol is we binding Objective-C method at define, not call. There is another Objective-C's weird thing that you can't know argument type and return type from selector, so there's a lot of if-else-if to detect argument's type and return type, hope I covered all required type.

Memory Management
-----------------

Objective-C is manual memory management, Lemon is auto memory management, the difference make some inconvenient.

if an object is lobjc_Object, you don't need do anything.
if an object is lemon's instance, and you will need Objective-C call this object later (like delegate), then you need make it persistent by set it to global variable or global variable's attribute.Maybe we can swizzling `dealloc` fix this.


Plain Old Data
--------------

All the required data need set to lobjc.m module's attribute, enum, global variable, etc. see lobjc_module function.

Issues
------

* Thread is unsupported.
* Probably has memory leak.

License
-------
Copyright (c) 2017 Zhicheng Wei

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

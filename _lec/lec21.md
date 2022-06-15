---
author: Jason Hemann
title: OO Programming
date: 2022-06-14
---

# Object-oriented Programming

We can look at closures as an impoverished kind of object, and in
another POV look at objects as an impoverished kind of closure. You
should for now be able to see the superficial similarity of a closure
to an object: both conceal encapsulated private data, and require any
access to those data be mediated through use of a publicly exposed
method. The trick is that with a closure, there only ever *is* one
method.

# Class-based OO, vs. prototype-based OO.

We will not be simulating a type system. So our OO simulation will not
be a class-based OO language, using subclassing for inheritance.
Instead, we will use a technique called _delegation_: when this object
doesn't know what to do with a given received message, it contains
with it already a "plan in mind" for which object to instead ask to
handle that message.

# A couple of neat techniques

There are a couple of neat techniques that you need to know about for
some of this discussion to make sense:

## Variable-arity functions, or `varargs`.

The Java programmers in the room already know about how, in some
cases, Java function parameters are wrapped up into an array, and the
function will expect that single array of parameters instead of
however many it was called with. Java does this because they want,
say, some given function to be able to handle varying-numbers of
arguments, and the user of that function shouldn't pay any price for
the generality. A user should be able to call the function like any
other 2 argument function. Racket and it's ancestors have had this
feature for generations.

```racket
(lambda args args)
```

The below is a well-defined function. Notice that we do *not* write
parens around `args` in the first position. That symbol `args` is
supposed to correspond not to a single argument in a list of
parameters, but to the entire parameter list!

```racket
> ((lambda args args) 'a 'b 'c (+ 2 3))
'(a b c 5)
```

So it turns out not only is this an exploitable feature, it's
immediately useful! This is an implementation of `list` in Racket!

If you want to say "one or more arguments", instead of "any number of
arguments", you can use the "dot notation" that we're used to for cons
lists in the function parameters list.

```racket
(define f
  (lambda (a . res)
    (cons res a)))
```

And of course you justly can and should be able to nest functions into
the "MIT-define" syntax.

```racket
(define ((((f) a . res)) . more)
  (append res (cons a more)))
```

And you call the function just like you'd expect.


## "own" variables.

You should like and be happy to know that `define` is not special
syntax that for instance only works with `lambda`. You can construct a
`let` binding in between and around that.

```racket
(define f
  (let ((v 'my-secret-symbol))
    (lambda (x)
	  (eqv? x v))))
```

And the point is that these are called "own" variables, because they
are local to the defined function f, and not globally visible or
visible to any other scope, but they are also not parameters to the
function. It's a way to give functions their own lexically scoped
private environment data.

By the by, since, as you know, named lets also let you approximate a
function---that is, they are not just labels but instead functions in
their own right that you can return as values, you get some more neat
properties. Just fun to think about

```racket
(define f
  (let loop ((v 'my-secret-symbol))
    (lambda (x)
	  (if (eqv? x y)
	      f
          (begin
		    (set! v x)
			loop)))))
```

## `apply`

Another powerful lisp feature that we haven't yet called upon in this
class is `apply` You will occasionally find yourself in a situation
where you have a variable arity function, and a list of the parameters
with which you want to call it.

```racket
(define (call-it var-arity-f list-of-args)
  ...)
```

But it's tough to figure out what to do from here. Because what you
*want* to get is a call that looks like `(f arg1 arg2 arg3 ... argn)`.
But I don't know how many elements are in that list of args, so I
couldn't build

```racket
(f (car ls) (cadr ls) ... (caaaaaaaaaadr ls))
```

even if I wanted to, which we don't.

So what we do here is use `apply`, a special-built tool that will,
when given a function and a list of arguments, call that function with
those arguments as the parameter list.

# Boxing

So we'll start out by building a box-maker. We are simulating with
Racket lambda and a couple of side-effects, which we somewhat control.
If your head is thinking "could I get by with something like this
without Racket side-effects?" I like where your head is at but that's
not today's point.


```racket
(define (box-maker init-val)
  (let ([contents init-val])
	(λ msg
	  (match msg
		[`(type) "box"]
        [`(show) contents]
		[`(update! ,x) (set! contents x)]
		[`(reset!) (set! contents init-val)]
		[else (delegate base-object msg)]))))
```

The `box-maker` function is our constructor, and the function that it
returns is how we represent our boxes. We represent our box objects
using Racket closures. We simpulate the ability to invoke multiple
different methods, with different numbers of parameters each, by using
variable-arity functions and dispatching against the shape of the
message itself. Our implementation of boxes has something that the
typical Racket variant doesn't have---a `reset!` method back to the
original value with which the box was constructed.

We have not yet implemented `delegate`, `base-obj` or an ability to
send along a message. Let us do that now.


```racket
(define delegate
  (λ (obj msg)
    (apply obj msg)))

(define invalid-method-name-indicator "unknown")

(define base-object
  (λ msg
    (match msg
      [`(type) "base object"]
      [else invalid-method-name-indicator])))

(define send
  (λ args
    (let ((obj (car args))
          (msg (cdr args)))
      (let ((try (apply object message)))
        (if (eq? invalid-method-name-indicator try)
            (error 'send "bad method name ~s sent to a ~s" (car message) (object 'type))
            try)))))
```



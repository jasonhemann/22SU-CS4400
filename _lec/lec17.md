---
author: Jason Hemann
title: Macros
date: 2022-06-17
---

This is an exploration of macros, and some debugging tips for defining
and programming with them.

# Macros can help us reduce “boilerplate code”

Consider a pattern where you want to let bind a value with a known
shape, and then get a hold of its pieces.


```racket
(let ([CLOS evalrator])
  (match CLOS
    [`(closure ,x ,cbody ,env2) matchrhs]))
```

We all find this somewhat tedious. It’s boilerplate code, in the sense
that we had to write some intermediate forms necessary to execute what
we needed to /do/ but we had to write out some of those steps in lower
levels of detail than what we would want to express either to the
computer or to another human looking at this expression. Specifically,
we didn’t *really* want a name for the value `CLOS`. We needed to have
it so we could immediately pattern match on it, but it’s not like we
were going to use that variable name elsewhere. In many languages we’d
be forced into these kinds of unnecessary details, and we’d have to
teach new developers how to read these idioms---common more
complicated expressions that we can understand as having a more
concise meaning when used in a given context.

In Racket, though, we have the opportunity to use a macro system to
eliminate such boilerplate.


```racket
(define-syntax matchlet
  (syntax-rules ()
    ((_ ((pattern expr-to-eval)) matchrhs)
	 (let ((CLOS expr-to-eval))
	   (match CLOS
	     [pattern matchrhs])))))
```

We can, on the fly in the middle of our program, whenever we recognize
that we are writing boilerplate code to express some local idiom over
and over, define a macro to express that idiom as a shorthand.

And this is different than a function. This is a different class of
abstraction than functional abstraction, because macro expansion time
is different than run-time.

# Macro expansion time is different than run-time.

```
;; (define (my-thunkify x)
;;   (lambda () x))

(define-syntax thunkify
  (syntax-rules ()
    [(_ e) (lambda () e)]))
```

# See the special "reserved keywords" list

```
(define-syntax if-t-e
  (syntax-rules (then else)
    [(_ t then conseq else alt)
     (if t conseq alt)]))
#|
(define-syntax if
  (syntax-rules (then else)
    [(_ t then conseq else alt)
     (if t conseq alt)]))
|#
```

# Debugging 

For debugging, you can use the quote techniques you see in “Syntax
Rules for the Merely Eccentric”, and you an also try
`trace-define-syntax`.

# Danger: we can loop even at macro expansion time!

```
(trace-define-syntax loop
  (syntax-rules ()
    [(loop e) (loop (list e e))]))

(define-syntax let
  (syntax-rules ()
    [(_ ((x e1) ...) e2)
     ((lambda (x ...) e2) e1 ...)]))
```

## `or` is a macro! 

```
(define-syntax or2
  (syntax-rules ()
    [(_ e1 e2)
     (let ((v e1))
       (if v v e2))]
    [(_ e1 e2 e3 ...) (raise-syntax-error 'or2 "badness")]))

(define-syntax or*
  (syntax-rules ()
    [(_) #f]
    [(_ e1) e1]
    [(_ e1 e2 ...)
     (let ((v e1))
       (if v v (or* e2 ...)))]))
```

The following will fail to execute, because `or` is not a function

```racket
(map or '(#f #f #f #f #f))
```

(define-syntax lambda->lumbda
  (syntax-rules (lambda)
    ((_ (lambda (a) b))
     (lumbda (a) (lambda->lumbda b)))
    ((_ (e1 e2))
     ((lambda->lumbda e1) (lambda->lumbda e2)))
    ((_ x) x)))

;; (define-syntax my-let
;;   (syntax-rules ()
;;     ((_ ((x e) ...) b b* ...)
;;      ((λ (x ...) b b* ...) e ...))))


# Simpler macros

In the simple case that you have a single, non-recursive macro
transformation (and very often what you think is recursive can be
expressed as just `...`s) you can use a special Racket form
`define-syntax-rule` to more succintly write this transformation.

```racket
(define-syntax define-syntax-rule
  (syntax-rules ()
	[(define-syntax-rule (name P ...) B)
	 (define-syntax name
	   (syntax-rules ()
		 [(name P ...) B]))]))
```

If it didn’t exist, you would probably have invented it!

```racket
(define-syntax-rule (my-let ((x e) ...) b b* ...)
  ((λ (x ...) b b* ...) e ...))
```

# Accumulator-passing style macros

You can do an awful lot with the syntax-rules macro system. In fact,
it’s as powerful as any programming language can be!

One of the things you can do is write macros in accumulator-passing
style. As with accumulator-passing style functions, this well let you
build up an information context to help you execute the
transformations you need when you reach a base case.

```racket
(define-syntax rev-app
  (syntax-rules (:)
    ((_ (f) : (acc ...))
     (f acc ...))
    ((_ (input input* ...) : (acc ...))
     (rev-app (input* ...) : (input acc ...)))
    ((_ (input ...))
     (rev-app (input ...) : ()))))
```

But what if the default outside-in macro evaluation order isn’t what
you want? Well, you can imagine what else you can get up to with
continuation-passing-style macros. Google search for the paper on it.

# An insufficiently expressive macro system

Despite that power, the syntax-rules system isn’t as expressive as
we’d wish. Consider, for example, wanting to macro-expand to a call
where one of the arguments is a numeric quantity, and we want to
expand out that number of times. If this example seems artificial,
pick some other operation where you use a number as something besides
an arbitrary constant.

```racket
> (call-on-n-5s f 2) ;; should expand to (f 5 5)
> (call-on-n-5s f 4) ;; should expand to (f 5 5 5 5)
```

We cannot write such a macro with syntax-rules. Syntax-rules is
entirely pattern based, and we cannot case against the infinitely many
distinct racket number with pattern matching. Decimal numbers, yes,
but the pattern matching language doesn’t let us break a number into
the hundreds column, the tens column, etc.

Instead, we would resort to some other lower level macro system, often
generally (but inaccurately) grouped together as “syntax-case” macros,
`syntax-case` being the name of an early exemplar of the family.

# Low-level macros

## “Syntax-case” style macros


```racket
(define-syntax foo (f α)) ;; where (f α) returns a syntax transformer
```

What `'` is to quote, `#'` is to producing syntax.

```racket
'b
(quote b)

#'b
(syntax b)
```

And of course, as you would expect, you have the whole panoply of syntax equivalents for all of quote’s relatives. 

```racket
'b
(quote b)

#'b
(syntax b)
```

- `quasiquote-syntax` (`#` with a backtick after it)
- `unquote-syntax`  (`#,`)
- `syntax-unquote-splice` (`#,@`)


    (define-syntax (if-it stx)
      (syntax-case stx ()
        [(if-it E1 E2 E3)
         (with-syntax ([it (datum->syntax stx 'it)])
           #'(let ([tmp E1]) (if tmp (let ([it tmp]) E2) E3)))]))


### A macro that can help _you_!

```
(define-syntax print-vals
  (syntax-rules ()
    [(_ r ...)
     (begin
       (printf "the register ~s~n has value~n ~s~n" 'r r)
       ...)]))
```


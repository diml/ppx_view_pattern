# Ppx_view_pattern - Pattern matching on abstract types

This repository contrains some experiments for a ppx rewriter
providing pattern matching on abstract types.

## Overview

The main motivation for this is to eventually abstract the OCaml AST
entirely in [ppx_ast][ppx_ast], so that ppx rewriters can use a proper
API to deal with the OCaml AST and not have to worry about the
evolution of the OCaml AST.

The main problem when making the AST abstract is how to deconstruct
it. [ppx_core][ppx_core] provides an `Ast_pattern` module allowing to
do this with combinators. However using them is really painful, and
the code is a lot worse that what you can do by just pattern matching
on the concrete data types.

This ppx rewriter proposes a simple solution to this problem. It
rewrites pattern matching of the form:

```ocaml
match%vpat <expr> with
| A x -> f x
| B x -> g x
```

into some expression where constructors such as `A` or `B` are mapped
to functions by simply lowercasing their name.

You can see a full example in test/test.ml.

## Plan

The plan is:

- finish this rewriter, in particular add support for record patterns
- update [ppx_ast][ppx_ast] to abstract the OCaml AST entirely and
  provide all the necessary builders/patterns
- upgrade all Jane Street ppx rewriters to use this

This will be a breaking change for users of [ppx_core][ppx_core] and
[ppx_driver][ppx_driver]. However, once users will have switched,
they'll get much better stability guarantees since changes in the
parsetree will simply be reflected by forward compatible changes of
the [ppx_ast][ppx_ast] API.

Under the hood, ppx_ast will use the version of the Parsetree
supported by [ocaml-migrate-parsetree][omp]. It will always try to use
the highest available version, so that the latest compiler features
are available immediately.

## Status

Currently nothing appart from this experiment has been done.

[ppx_core]: https://github.com/janestreet/ppx_core
[ppx_ast]: https://github.com/janestreet/ppx_core
[omp]: https://github.com/let-def/ocaml-migrate-parsetree

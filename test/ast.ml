open Migrate_parsetree.Ast_404
open Asttypes
open Parsetree

type nonrec arg_label = arg_label
type nonrec expression = expression

module B = struct
  let nolabel = Nolabel
  let labelled s = Labelled s
  let optional s = Optional s

  let pexp_apply ~loc f args =
    { pexp_loc = loc
    ; pexp_attributes = []
    ; pexp_desc = Pexp_apply (f, args)
    }

  let pexp_ident ~loc id =
    { pexp_loc = loc
    ; pexp_attributes = []
    ; pexp_desc = Pexp_ident id
    }
end

module P = struct
  open View_pattern.Match_result

  let nolabel x l =
    match x with
    | Nolabel -> Ok l
    | _ -> Match_failure

  let labelled t x l =
    match x with
    | Labelled s -> t s l
    | _ -> Match_failure

  let optional t x l =
    match x with
    | Optional s -> t s l
    | _ -> Match_failure

  let pexp_apply tf targs x l =
    match x.pexp_desc with
    | Pexp_apply (f, args) -> begin
        match tf f l with
        | Match_failure -> Match_failure
        | Ok l -> targs args l
      end
    | _ -> Match_failure

  let pexp_ident t x l =
    match x.pexp_desc with
    | Pexp_ident id -> t id l
    | _ -> Match_failure

  let pexp_loc tloc t x l =
    match tloc x.pexp_loc l with
    | Ok l -> t x l
    | Match_failure -> Match_failure
end

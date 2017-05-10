open StdLabels
open Migrate_parsetree.Ast_404
open Asttypes
open Parsetree
open Ast_helper

let evar ~loc s = { loc; txt = Longident.parse s }

let rt_id s = Longident.Ldot (Lident "View_pattern", s)
let rt_lid ~loc s = { Asttypes.loc; txt = rt_id s }
let rt_eid ~loc s = Exp.ident ~loc (rt_lid ~loc s)

let nil : Longident.t = Ldot (Ldot (Lident "View_pattern", "HList"), "[]")
let cons : Longident.t = Ldot (Ldot (Lident "View_pattern", "HList"), "::")

let map_cstr : Longident.t -> Longident.t = function
  | Lident "[]" -> nil
  | Lident "::" -> cons
  | Lident s    -> Lident (String.lowercase s)
  | Ldot (p, s) -> Ldot (p, String.lowercase s)
  | Lapply _ -> assert false

let combine ~loc func l =
  (Exp.apply ~loc func (List.map l ~f:(fun (e, _) -> (Nolabel, e))),
   List.map l ~f:snd |> List.concat)

let rec exprify pat =
  let loc = pat.ppat_loc in
  match pat.ppat_desc with
  | Ppat_any | Ppat_var _ ->
    (rt_eid ~loc "__", [pat])
  | Ppat_tuple l ->
    combine ~loc (rt_eid ~loc (Printf.sprintf "t%d" (List.length l)))
      (List.map l ~f:exprify)
  | Ppat_construct (id, arg) -> begin
      let id = Exp.ident ~loc:id.loc { id with txt = map_cstr id.txt } in
      match arg with
      | None -> (id, [])
      | Some pat ->
        match pat.ppat_desc with
        | Ppat_tuple args ->
          combine ~loc id (List.map args ~f:(exprify))
        | _ ->
          let e, v = exprify pat in
          (Exp.apply ~loc id [(Nolabel, e)], v)
    end
  | Ppat_open (id, p) ->
    let e, v = exprify p in
    (Exp.open_ Override ~loc id e, v)
  | Ppat_record _
  | Ppat_alias _
  | Ppat_constant _
  | Ppat_interval _
  | Ppat_variant _
  | Ppat_array _
  | Ppat_or _
  | Ppat_constraint _
  | Ppat_type _
  | Ppat_lazy _
  | Ppat_unpack _
  | Ppat_exception _
  | Ppat_extension _ ->
    Location.raise_errorf ~loc "ppx_view_pattern: don't know how to handle this pattern"

let rewrite ~loc exp cases =
  let cases =
    List.map cases ~f:(fun c ->
      let e, vars = exprify c.pc_lhs in
      let loc = c.pc_lhs.ppat_loc in
      Exp.apply ~loc (rt_eid ~loc "map")
        [ Nolabel, e
        ; Labelled "f",
          Exp.fun_ ~loc Nolabel None
            (List.fold_right vars ~init:(Pat.construct ~loc { loc; txt = nil } None)
               ~f:(fun var acc ->
                 let loc = var.ppat_loc in
                 Pat.construct ~loc { loc; txt = cons }
                   (Some (Pat.tuple ~loc [var; acc]))))
            c.pc_rhs
        ])
  in
  let pos = loc.Location.loc_start in
  Exp.apply ~loc (rt_eid ~loc "exec_exn")
    [ (Nolabel,
       Exp.apply ~loc
         (rt_eid ~loc "alt")
         [(Nolabel,
           List.fold_right cases ~init:(Exp.construct ~loc { loc; txt = Lident "[]" } None)
             ~f:(fun e acc ->
               let loc = e.pexp_loc in
               Exp.construct ~loc { loc; txt = Lident "::" }
                 (Some (Exp.tuple ~loc [e; acc]))))])
    ; (Nolabel, exp)
    ; (Labelled "loc",
       Exp.tuple ~loc
         [ Exp.constant ~loc (Pconst_string (pos.pos_fname, None))
         ; Exp.constant ~loc (Pconst_integer (string_of_int pos.pos_lnum, None))
         ; Exp.constant ~loc (Pconst_integer
                                (string_of_int (pos.pos_cnum - pos.pos_bol), None))
         ])
    ]

let mapper =
  let super = Ast_mapper.default_mapper in
  let expr self e =
    let e = super.expr self e in
    match e.pexp_desc with
    | Pexp_extension ({ txt = "vpat"; loc }, payload) -> begin
        match payload with
        | PStr [{ pstr_desc =
                    Pstr_eval ({ pexp_desc = Pexp_match (exp, cases)
                               ; _ } as e, _)
                ; _ }] ->
          rewrite ~loc:e.pexp_loc exp cases
        | _ ->
          Location.raise_errorf ~loc "ppx_view_pattern: pattern matching expected"
      end
    | _ -> e
  in
  { super with expr }

let () =
  Migrate_parsetree.Driver.register ~name:"view_pattern"
    (module Migrate_parsetree.OCaml_current)
    (fun _ _ -> mapper)

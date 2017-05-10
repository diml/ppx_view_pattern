open Ast

let () =
  let loc = Location.none in
  let e =
    B.(pexp_apply ~loc (pexp_ident ~loc { loc; txt = Lident "+" })
         [ nolabel, (pexp_ident ~loc { loc; txt = Lident "x" })
         ; nolabel, (pexp_ident ~loc { loc; txt = Lident "y" })
         ])
  in

  begin
    (* Simple matching *)
    match%vpat e with
    | P.(Pexp_apply (Pexp_ident id1,
                     [ Nolabel, Pexp_ident id2
                     ; Nolabel, Pexp_ident id3 ])) ->
      ignore (id1 : Longident.t Asttypes.loc);
      ignore (id2 : Longident.t Asttypes.loc);
      ignore (id3 : Longident.t Asttypes.loc)
    | _ ->
      assert false
  end;

  begin
    (* Capturing the location as well *)
    match%vpat e with
    | P.(Pexp_loc (loc,
                   Pexp_apply (Pexp_ident _,
                               [ Nolabel, Pexp_ident _
                               ; Nolabel, Pexp_ident _ ]))) ->
      ignore (loc : Location.t)
    | _ ->
      assert false
  end;

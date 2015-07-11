(**
  * print_covering_classes.ml
  * openkappa
  * Jérôme Feret, projet Abstraction, INRIA Paris-Rocquencourt
  * 
  * Creation: 2015, the 26th of June
  * Last modification: 
  * 
  * Print the relations between the left hand site of a rule and its sites.
  * 
  * Copyright 2010,2011,2012,2013,2014 Institut National de Recherche en Informatique et   
  * en Automatique.  All rights reserved.  This file is distributed     
  * under the terms of the GNU Library General Public License *)

open Printf
open Covering_classes_type
open Int_storage

(*------------------------------------------------------------------------------*)

let sprintf_list l =
  let acc = ref "{" in
  List.iteri (fun i x ->
    acc := !acc ^
      if i <> 0
      then sprintf "; %i" x
      else sprintf "%i" x
  ) l;
  !acc ^ "}"
    
let print_list l =
  let output = sprintf_list l in
  fprintf stdout "%s\n" output

let print_site_type l =
  let rec aux acc =
    match acc with
      | [] -> ()
      | (x,_) :: tl ->
        fprintf stdout "site_type:%i\n" x;
        aux tl
  in aux l

(*------------------------------------------------------------------------------*)
(*print new index*)

let print_new_index_dic parameter error elt_id store_index =
  Dictionary_of_Covering_class.print
    parameter
    error
    (fun parameter error elt pair_index _ _ ->
      let _ = 
        fprintf stdout
          "Potential dependencies between sites:New-index:Covering_class_id:%i:class_id:%i:\n"
          elt_id elt;
        print_site_type pair_index
      in
      error
    ) store_index
    
(*------------------------------------------------------------------------------*)
(*print test with new index*)

let print_test_new_index_dic parameter error elt_id store_test =
  Dictionary_of_Covering_class.print
    parameter
    error
    (fun parameter error elt value_index _ _ ->
      let _ = fprintf stdout
        "Potential dependencies between sites:New-index:TEST:Covering_class_id:%i:class_id:%i:\n"
          elt_id elt;
        print_site_type value_index
      in
      error
    ) store_test

(*------------------------------------------------------------------------------*)
(*print modified site (action) with new index*)

let print_modified l =
  let rec aux acc =
    match acc with
      | [] -> ()
      | x :: tl ->
        fprintf stdout "site_type:%i\n" x;
        aux tl
  in aux l

let print_modified_dic parameter error elt_id store_modif =
  Dictionary_of_Modified_class.print
    parameter
    error
    (fun parameter error elt l _ _ ->
      let _ =
        fprintf stdout 
          "Potential dependencies between sites:New-index:MODIFICATION-:Covering_class_id:%i:class_id:%i:\n"
          elt_id elt;
        print_modified l
      in
      error
    ) store_modif

(*------------------------------------------------------------------------------*)
(*print remove action*)

let print_pair parameter error ps =
  let rec aux acc =
    match acc with
      | [] -> []
      | (x,i) :: tl ->
        fprintf stdout "site_type:%i:state:%i\n" x i;
        aux tl
  in aux ps

let print_dic_and_new_index parameter error store_index store_test store_modif store_dic =
  Dictionary_of_Covering_class.print
    parameter
    error
    (fun parameter error elt_id pair_list _ _ ->
      let _ =
        let _ =
        (*print covering class in dictionary*)
          printf "Potential dependencies between sites:Covering_class_id:%i:\n"
            elt_id; 
          print_pair parameter error pair_list
        in
        (*print new_index for covering class*)
        let _ = print_new_index_dic
          parameter
          error 
          elt_id 
          store_index 
        in
        (*print site that is tested with its new_index*)
        let _ = print_test_new_index_dic
          parameter 
          error 
          elt_id
          store_test 
        in
        (*print site that is modified with its new_index*)
        print_modified_dic 
          parameter
          error 
          elt_id 
          store_modif
        in error)
    store_dic

(*------------------------------------------------------------------------------*)

let print_value_site parameter error elt site value_site = (*REMOVE*)
  Quick_Nearly_inf_Imperatif.print
    error
    (fun error parameter value_site_list ->
      let _ =
        let rec aux_value acc' =
          match acc' with
            | [] -> acc'
            | vsite :: tl' ->
              let _ =
                fprintf stdout 
                  "Potential dependencies between sites:New-index:Covering_class_id:%i:"
                  elt;
                match vsite with
                  | Ckappa_sig.Internal s ->
		    fprintf stdout "site_modified:%i->%s(internal state)\n"
                      site s
	          | Ckappa_sig.Binding s ->
		    fprintf stdout "site_modified:%i->%s(binding state)\n"
                      site s                                     
              in aux_value tl'
        in aux_value value_site_list
      in
      error
    ) parameter value_site
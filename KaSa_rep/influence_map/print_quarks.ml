 (**
  * translate_sig.ml
  * openkappa
  * Jérôme Feret, projet Abstraction, INRIA Paris-Rocquencourt
  * 
  * Creation: March, the 8th 2011.
  * Last modification: February, the 5th 2015
  * * 
  * Pretty printing of influence map
  *  
  * Copyright 2010,2011,2012,2013,2014,2015 Institut National de Recherche en Informatique et   
  * en Automatique.  All rights reserved.  This file is distributed     
  * under the terms of the GNU Library General Public License *)

let warn parameters mh message exn default = 
     Exception.warn parameters mh (Some "Print_quark") message exn (fun () -> default) 
  

let trace = false 
let local_trace = false  
   
let string_of_port port = "["^(string_of_int port.Cckappa_sig.site_state.Cckappa_sig.min)^";"^(string_of_int port.Cckappa_sig.site_state.Cckappa_sig.max)^"]"
   

let print_agent_map parameters error handler map = 
  let error = 
    Quark_type.AgentMap.iter 
      parameters 
      error 
      (fun parameters error key im -> 
        Int_storage.Quick_Nearly_inf_Imperatif.iter 
          parameters
          error
          (fun parameters error key' im' -> 
              let _ = Printf.fprintf (Remanent_parameters.get_log parameters) "%sagent_type:%i,rule:%i->" (Remanent_parameters.get_prefix parameters) key key' in 
              let _ = Quark_type.Labels.dump parameters error handler im' in 
              let _ = Printf.fprintf (Remanent_parameters.get_log parameters) "\n" in
            error)
          im)
      map
  in error

let print_agent_var_map parameters error handler map = 
  let error = 
    Quark_type.AgentMap.iter 
      parameters 
      error 
      (fun parameters error key im -> 
        Int_storage.Quick_Nearly_inf_Imperatif.iter 
          parameters
          error
          (fun parameters error key' im' -> 
              let _ = Printf.fprintf (Remanent_parameters.get_log parameters) "%sagent_type:%i,var:%i->" (Remanent_parameters.get_prefix parameters) key key' in 
              let _ = Quark_type.Labels.dump parameters error handler im' in 
              let _ = Printf.fprintf (Remanent_parameters.get_log parameters) "\n" in
            error)
          im)      
      map
  in error

let print_agents parameters error handler quark = 
  let parameters_var = Remanent_parameters.update_prefix parameters "agent_var++**:" in 
  let error = print_agent_var_map parameters_var error handler quark.Quark_type.agent_var_plus in
  let parameters_var = Remanent_parameters.update_prefix parameters "agent_var--**:" in 
  let error = print_agent_var_map parameters_var error handler quark.Quark_type.agent_var_minus in
  let parameters_plus = Remanent_parameters.update_prefix parameters "agent_test**:" in 
  let error = print_agent_map parameters_plus error handler quark.Quark_type.agent_test in
  let parameters_plus = Remanent_parameters.update_prefix parameters "agent_modif+:" in 
  let error = print_agent_map parameters_plus error handler quark.Quark_type.agent_modif_plus in
  let parameters_minus = Remanent_parameters.update_prefix parameters "agent_modif-:" in 
  let error = print_agent_map parameters_minus error handler quark.Quark_type.agent_modif_minus in
    error 
  
let print_site_map parameter error handler map = 
     Quark_type.SiteMap.iter 
      parameter 
      error 
      (fun parameters error (agent_type,(site_type,state)) im -> 
        Int_storage.Quick_Nearly_inf_Imperatif.iter 
          parameter
          error
          (fun parameters error rule im' -> 
               let _ = Printf.fprintf (Remanent_parameters.get_log parameter) "%sagent_type:%i,site_type:%i,state:%i,rule:%i->" (Remanent_parameters.get_prefix parameter) agent_type site_type state rule  in 
               let _ = Quark_type.Labels.dump parameter error handler im' in 
               let _ = Printf.fprintf (Remanent_parameters.get_log parameter) "\n" in
                 error)
          im
      )
      map

let print_site_var_map parameter error handler map = 
     Quark_type.SiteMap.iter 
      parameter 
      error 
      (fun parameters error (agent_type,(site_type,state)) im -> 
        Int_storage.Quick_Nearly_inf_Imperatif.iter 
          parameter
          error
          (fun parameters error rule im' -> 
               let _ = Printf.fprintf (Remanent_parameters.get_log parameter) "%sagent_type:%i,site_type:%i,state:%i,var:%i->" (Remanent_parameters.get_prefix parameter) agent_type site_type state rule  in 
               let _ = Quark_type.Labels.dump parameter error handler im' in 
               let _ = Printf.fprintf (Remanent_parameters.get_log parameter) "\n" in
                 error)
          im
      )
      map         
  
let print_sites parameter error handler quark = 
  let parameter_var = Remanent_parameters.update_prefix parameter "site_vars++**:" in 
  let error = print_site_var_map parameter_var error handler quark.Quark_type.site_var_plus in
  let parameter_var = Remanent_parameters.update_prefix parameter "site_vars--**:" in 
  let error = print_site_var_map parameter_var error handler quark.Quark_type.site_var_minus in
  let parameter_plus = Remanent_parameters.update_prefix parameter "site_test**:" in 
  let error = print_site_map parameter_plus error handler quark.Quark_type.site_test in 
  let parameter_plus = Remanent_parameters.update_prefix parameter "site_modif+:" in 
  let error = print_site_map parameter_plus error handler quark.Quark_type.site_modif_plus in
  let parameter_minus = Remanent_parameters.update_prefix parameter "site_modif-:" in 
  let error = print_site_map parameter_minus error handler quark.Quark_type.site_modif_minus in
    error 

let print_quarks parameters  error handler quark = 
  let _ = Printf.fprintf (Remanent_parameters.get_log parameters) "\nREMARKS: The notation [i] is a position of an agent in a rule/var. If a position is a negative number [-i], then it refers an agent that is connected to the agent at position (i-1) that is modified by side effects.\n" in 
  let error = print_agents  parameters error handler quark in 
  let error = print_sites parameters  error handler quark in 
  error
  
let print_maps parameters error handler compilation print_rule print_var get_label_of_rule get_label_of_var print_labels prefix suffix map =
  let _  = 
    Quark_type.Int2Set_and_map.fold_map
      (fun (a,b) couple error -> 
       let error,ruleb = Handler.string_of_rule parameters error handler compilation b in
         let _ = Printf.fprintf (Remanent_parameters.get_log parameters) "%s" prefix in 
         let error,bool,() = Handler.print_rule_or_var parameters error handler compilation print_rule print_var get_label_of_rule get_label_of_var a in 
         let _ = Printf.fprintf (Remanent_parameters.get_log parameters) " -> " in
         let error,bool,()  = Handler.print_rule_or_var parameters error handler compilation print_rule print_var get_label_of_rule get_label_of_var b in
         let _ = print_labels parameters error handler couple in 
         let _ = Printf.fprintf (Remanent_parameters.get_log parameters) "%s" suffix in 
              error
      )  
      map
      error
  in error 
                  
let print_wake_up_map parameters error handler compilation print_rule print_var print_label_rule print_label_var print_labels suffix  map =
  let parameters = Remanent_parameters.update_prefix parameters "Wake_up_map:" in 
  let _ = Printf.fprintf (Remanent_parameters.get_log parameters) "Influence_map: The notation [i -> j] means an agent at position [i] of the first rule/var has an influence to an agent at position [j] of the second rule/var.\n" in
  print_maps parameters error handler compilation print_rule print_var print_label_rule print_label_var print_labels (Remanent_parameters.get_prefix parameters) suffix map
  
let print_inhibition_map parameters error handler compilation print_rule print_var print_label_rule print_label_var print_labels suffix  map =
  let parameters = Remanent_parameters.update_prefix parameters "Inhibition_map:" in 
  print_maps parameters error handler compilation print_rule print_var print_label_rule print_label_var print_labels (Remanent_parameters.get_prefix parameters) suffix map
  
let dot_of_influence_map parameters error handler compilation (wake_up_map,inhibition_map) = 
    let error,parameters_dot = 
          Remanent_parameters.open_influence_map_file parameters error
    in 
    let _ = 
      List.iter 
        (fun x -> Printf.fprintf (Remanent_parameters.get_log parameters_dot) "%s%s\n" Headers.dot_comment x)
        Headers.head 
    in 
    let _ = Printf.fprintf (Remanent_parameters.get_log parameters_dot) "%s%s\n" Headers.dot_comment Headers.head_influence_map_in_dot in 
    let _ = Printf.fprintf (Remanent_parameters.get_log parameters_dot) "digraph G{ \n" in 
    let nrules =  Handler.nrules parameters error handler in 
    let nvars =  Handler.nvars parameters error handler in 
     let error = 
        if nrules > 0 
        then 
          let _ = 
            Printf.fprintf 
              (Remanent_parameters.get_log parameters_dot) 
              "node [shape=%s, style=filled, fillcolor=%s];\n"
              (Remanent_parameters.get_rule_shape parameters_dot)
              (Remanent_parameters.get_rule_color parameters_dot)
          in 
          let rec aux k error = 
             if k>= nrules then error 
             else 
               let error,bool,_ = 
		 Handler.print_rule_or_var 
		   parameters_dot error handler compilation 
		   Handler.print_rule_dot 
		   Handler.print_var_dot 
		   Handler.get_label_of_rule_dot 
		   Handler.get_label_of_var_dot 
		   k 
	       in 
               let _ = if bool then 
                   Printf.fprintf (Remanent_parameters.get_log parameters_dot) " ; \n"
               in aux (k+1) error 
          in aux 0 error 
        else 
           error
    in        
    let error  = 
        if nvars > 0 
        then 
          let _ = 
            Printf.fprintf 
              (Remanent_parameters.get_log parameters_dot) 
              "node [shape=%s, style=filled, fillcolor=%s];\n"
              (Remanent_parameters.get_variable_shape parameters_dot)
              (Remanent_parameters.get_variable_color parameters_dot)
          in 
          let ntot = nrules + nvars in 
          let rec aux k error = 
             if k>= ntot then error 
             else 
               let error,bool,_  = Handler.print_rule_or_var parameters_dot error handler compilation Handler.print_rule_dot Handler.print_var_dot Handler.get_label_of_rule_dot Handler.get_label_of_var_dot k in 
               let _ = if bool then 
                   Printf.fprintf (Remanent_parameters.get_log parameters_dot) " ; \n" else () 
               in aux (k+1) error 
          in aux nrules error 
        else 
          error 
    in 
    let error = 
       if Quark_type.Int2Set_and_map.is_empty_map wake_up_map 
       then error 
       else 
         let _ = 
            Printf.fprintf 
              (Remanent_parameters.get_log parameters_dot) 
              "edge [color=%s, arrowhead=%s];\n"
              (Remanent_parameters.get_wake_up_color parameters_dot)
              (Remanent_parameters.get_wake_up_arrow parameters_dot)
         in 
         let error = print_maps parameters_dot error handler compilation Handler.print_rule_dot Handler.print_var_dot Handler.get_label_of_rule_dot Handler.get_label_of_var_dot Handler.print_labels_dot "" " ; \n" wake_up_map in 
         error 
    in 
    let error = 
       if Quark_type.Int2Set_and_map.is_empty_map inhibition_map 
       then error 
       else 
         let _ = 
            Printf.fprintf 
              (Remanent_parameters.get_log parameters_dot) 
              "edge [color=%s, arrowhead=%s];\n"
              (Remanent_parameters.get_inhibition_color parameters_dot)
              (Remanent_parameters.get_inhibition_arrow parameters_dot)
         in 
         let error = print_maps parameters_dot error handler compilation Handler.print_rule_dot Handler.print_var_dot Handler.get_label_of_rule_dot Handler.get_label_of_var_dot  Handler.print_labels_dot "" " ; \n" inhibition_map in 
         error 
    in 
    let _ = Printf.fprintf (Remanent_parameters.get_log parameters_dot) "}\n" in 
    let error,parameters = Remanent_parameters.close_file parameters_dot error 
    in error 
    

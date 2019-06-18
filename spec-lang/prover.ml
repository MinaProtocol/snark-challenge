open Core
open Util

let url = sprintf "%s/prover.html" base_url

let page (_pages : Pages.t) =
  let page =
    Sectioned_page.map ~f:Markdown.to_string
      [ Problem.Quick_details.render
      { description= Markdown.of_string "The full Groth16 prover."
      ; prize=
          [ (Best_performance_at_end Cpu_and_gpu, Dollars 30_000)
          ; (First_to (Improve_speed_by 2), Dollars 7_000)
          ; (First_to (Improve_speed_by 4), Dollars 8_000)
          ; (First_to (Improve_speed_by 8), Dollars 10_000)
          ; (First_to (Improve_speed_by 16), Dollars 15_000) ] } ]
    @ Sectioned_page.of_markdown (In_channel.read_all "prover.markdown")
  in
  let content = Sectioned_page.render_to_markdown page in
  ksprintf Markdown.of_string
    !{md|
# Constructing optimal pairing-friendly curves
%{Html}

%s|md}
    (Sectioned_page.table_of_contents page)
    content
 
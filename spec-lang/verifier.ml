open Core
open Util

(*

size limit: 100kb

Batch params: the verification key
Output

*)

let page (pages : Pages.t) =
  let page =
    Sectioned_page.map ~f:Markdown.to_string
      [ Problem.Quick_details.render
          { description=
              ksprintf Markdown.of_string
                "Implement the Bowe--Gabizon verifier for [MNT6-753](%s) to \
                 run in the browser using JavaScript and/or WebAssembly."
                pages.mnt6
          ; prize= [(Best_performance_at_end Browser, Dollars 10_000)] } ]
    @ Sectioned_page.of_markdown (In_channel.read_all "verifier.markdown")
  in
  let content = Sectioned_page.render_to_markdown page in
  ksprintf Markdown.of_string !{md|# Fastest JavaScript/WebAssembly verifier
%{Html}

%s|md}
    (Sectioned_page.table_of_contents page)
    content

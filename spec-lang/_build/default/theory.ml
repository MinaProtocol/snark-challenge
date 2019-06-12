open Core
open Util

let url = sprintf "%s/theory.html" base_url

let page (_pages : Pages.t) =
  let page =
    Sectioned_page.map ~f:Markdown.to_string
      [ Problem.Quick_details.render
          { description=
              Markdown.of_string
                "Construct elliptic-curves which are optimal for efficient \
                 proof composition."
          ; prize= [(Highest_quality, Dollars 20_000)] } ]
    @ Sectioned_page.of_markdown (In_channel.read_all "theory.markdown")
  in
  let content = Sectioned_page.render_to_markdown page in
  ksprintf Markdown.of_string
    !{md|
# Constructing optimal pairing-friendly curves
%{Html}

%s|md}
    (Sectioned_page.table_of_contents page)
    content

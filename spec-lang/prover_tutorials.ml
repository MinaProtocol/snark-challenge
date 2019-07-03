open Core
open Util

let url = sprintf "%s/prover-tutorials.html" base_url

let page (_pages : Pages.t) = Markdown.of_string (In_channel.read_all "prover_tutorials.markdown")

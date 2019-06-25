open Core
open Util

let url = sprintf "%s/cloud_setup.html" base_url

let page (_pages : Pages.t) = Markdown.of_string (In_channel.read_all "cloud_setup.markdown")

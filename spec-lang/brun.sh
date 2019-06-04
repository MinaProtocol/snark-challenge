set +e
kill -9 $(ps aux  | grep SimpleH | grep -v grep | awk '{ print $2 }')
rm -r _site
dune exec specl
pushd _site
  python2 -m SimpleHTTPServer 2>/dev/null >/dev/null &
popd

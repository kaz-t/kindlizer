export TARGET='./src/mock_manga.pdf'
export TARGET='./src/'

export KINDLIZER_PHASE2_OPT='-depth 4 -level 5%,95% -depth 4'
export FUZZ='15%'
export PHASE3_COMMAND='mogrify'

export TOP=15
export BOTTOM=10
export LEFT=15
export RIGHT=15

export OUT_DIR='./out'
export OUT_EXT="voyage"

if [ -d "$TARGET" ]; then
  ls "$TARGET"/*.pdf | while read file ; do
    export SRC="$file"
    rake clean
    rake 
  done
else
  rake clean
  rake SRC="$TARGET"
fi

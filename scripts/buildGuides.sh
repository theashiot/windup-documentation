# Establish global variables to the docs and script dirs
CURRENT_DIR="$( pwd -P)"
SCRIPT_SRC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
DOCS_SRC="$( dirname $SCRIPT_SRC )/docs"
BUILD_RESULTS="Build Results:"
BUILD_MESSAGE=$BUILD_RESULTS
BLACK='\033[0;30m'
RED='\033[0;31m'
NO_COLOR="\033[0m"

usage(){
  cat <<EOM
USAGE: $0 [OPTION]... <guide>

DESCRIPTION: Build all of the guides (default), a single guide, and (optionally)
produce pot/po files for translation.

Run this script from either the root of your cloned repository or from the 'scripts'
directory.  Example:
  cd windup-documentation/scripts
  $0

OPTIONS:
  -h       Print help.

EXAMPLES:
  Build all guides:
   $0

  Build all guides and produce pot/po:
   $0 -t

  Build a specific guide(s) from $DOCS_SRC:
    $0 cli-guide
    $0 rules-development-guide
    $0 web-console-guide
    $0 getting-started-guide
    $0 plugin-guide
EOM
}

OPTIND=1
while getopts "ht" c
 do
     case "$c" in
       h)         usage
                  exit 1;;
       \?)        echo "Unknown option: -$OPTARG." >&2
                  usage
                  exit 1;;
     esac
 done
shift $(($OPTIND - 1))

# Use $DOCS_SRC so we don't have to worry about relative paths.
cd $DOCS_SRC

# Set the list of docs to build to whatever the user passed in (if anything)
subdirs=$@
if [ $# -gt 0 ]; then
  echo "=== Bulding $@ ==="
else
  echo "=== Building all the guides ==="
  # Recurse through the guide directories and build them.
  subdirs=`find . -maxdepth 1 -type d ! -iname ".*" ! -iname "topics" | sort`
fi
echo $PWD
for subdir in $subdirs
do
  echo "Building $DOCS_SRC/${subdir##*/}"
  # Navigate to the dirctory and build it
  if ! [ -e $DOCS_SRC/${subdir##*/} ]; then
    BUILD_MESSAGE="$BUILD_MESSAGE\nERROR: $DOCS_SRC/${subdir##*/} does not exist."
    continue
  fi
  cd $DOCS_SRC/${subdir##*/}
  GUIDE_NAME=${PWD##*/}
  ./buildGuide.sh $L10N
  if [ "$?" = "1" ]; then
    BUILD_ERROR="ERROR: Build of $GUIDE_NAME failed. See the log above for details."
    BUILD_MESSAGE="$BUILD_MESSAGE\n$BUILD_ERROR"
  fi
  # Return to the parent directory
  cd $SCRIPT_SRC
done

# Return to where we started as a courtesy.
cd $CURRENT_DIR

# Report any errors
echo ""
if [ "$BUILD_MESSAGE" == "$BUILD_RESULTS" ]; then
  echo "Build was successful!"
  exit 0
else
  echo -e "${RED}$BUILD_MESSAGE${NO_COLOR}"
  echo -e "${RED}Please fix all issues before continuing!${NO_COLOR}"
  exit 1
fi

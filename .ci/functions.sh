# Function to check whether input param is on list of shell scripts
# $1 - <string> absolute path to file
is_it_script () {
  [ $# -eq 0 ] && return 1
  
  readarray list_of_scripts < <(cut -d ' ' -f 1 < <(grep -v "^#.*" ./.ci/script-list.txt)) # fetch array with lines from file while excluding '#' comments
  echo "${list_of_scripts[@]}" | grep --silent "$1" && return 0
  return 1
}

# Color aliases use echo -e to use them
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'

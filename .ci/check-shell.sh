#!/bin/bash

# Path is wrong because of travis
. ./.ci/functions.sh

# ------------ #
#  FILE PATHS  #
# ------------ #

# https://medium.com/@joey_9999/how-to-only-lint-files-a-git-pull-request-modifies-3f02254ec5e0
# get names of files from PR (excluding deleted files)
git diff --name-only --diff-filter=db "${TRAVIS_COMMIT_RANGE}" > ../pr-changes.txt

# Find modified shell scripts
list_of_changes=()
file_to_array "../pr-changes.txt" "list_of_changes" 0
list_of_scripts=()
file_to_array "./.ci/script-list.txt" "list_of_scripts" 1

list_of_changed_scripts=()
for file in "${list_of_changes[@]}"; do
  # Remove new line and add ./ at the beginning
  # https://stackoverflow.com/a/19347380
  is_it_script "$file" "${list_of_scripts[@]}" && list_of_changed_scripts+=("./${file//[$'\t\r\n ']}")
done

# Get list of exceptions
list_of_exceptions=()
file_to_array "./.ci/exception-list.txt" "list_of_exceptions" 1
string_of_exceptions=$(join_by , "${list_of_exceptions[@]}")

echo "Changed shell scripts:"
echo "${list_of_changed_scripts[@]}"
echo "List of exceptions:"
echo "${string_of_exceptions}"
echo "------------"

# ------------ #
#  SHELLCHECK  #
# ------------ #

# sed part is to edit shellcheck output so csdiff/csgrep knows it is shellcheck output (--format=gcc)
shellcheck --format=gcc --exclude="${string_of_exceptions}" "${list_of_changed_scripts[@]}" | sed -e 's|$| <--[shellcheck]|' > ../pr-br-shellcheck.err

# make destination branch
[[ ${TRAVIS_COMMIT_RANGE} =~ ^([0-9|a-f]*?)\. ]] && git checkout -b ci_br_dest "${BASH_REMATCH[1]}"

shellcheck --format=gcc --exclude="${string_of_exceptions}" "${list_of_changed_scripts[@]}" | sed -e 's|$| <--[shellcheck]|' > ../dest-br-shellcheck.err

# ------------ #
#  VALIDATION  #
# ------------ #

exitstatus=0

echo -e "${WHITE}Validation output:${NOCOLOR}"

# Check output for Fixes
csdiff --fixed "../dest-br-shellcheck.err" "../pr-br-shellcheck.err" > ../fixes.log
if [ "$(cat ../fixes.log | wc -l)" -ne 0 ]; then
  echo -e "${GREEN}Fixed bugs:${NOCOLOR}" 
  csgrep ../fixes.log
  echo "------------"
else
  echo -e "${YELLOW}No Fixes!${NOCOLOR}"
  echo "------------"
fi

# Check output for added bugs
csdiff --fixed "../pr-br-shellcheck.err" "../dest-br-shellcheck.err" > ../bugs.log
if [ "$(cat ../bugs.log | wc -l)" -ne 0 ]; then
  echo -e "${RED}Added bugs, NEED INSPECTION:${NOCOLOR}" 
  csgrep ../bugs.log
  echo "------------"
  exitstatus=1
else
  echo -e "${GREEN}No bugs added Yay!${NOCOLOR}" 
  echo "------------"
  exitstatus=0
fi

exit $exitstatus


#!/bin/bash

. ./.ci/functions.sh

# ------------ #
#  FILE PATHS  #
# ------------ #

# https://medium.com/@joey_9999/how-to-only-lint-files-a-git-pull-request-modifies-3f02254ec5e0
# get names of files from PR (excluding deleted files)
# TRAVIS_COMMIT_RANGE - HEAD of destination branch ... HEAD of PR branch
git diff --name-only --diff-filter=db "${TRAVIS_COMMIT_RANGE}" > ../pr-changes.txt

# Find modified shell scripts
readarray list_of_changes < <(cut -d ' ' -f 1 < <(grep -v "^#.*" script-list.txt))
list_of_changed_scripts=()
for file in "${list_of_changes[@]}"; do
  # https://stackoverflow.com/questions/19345872/how-to-remove-a-newline-from-a-string-in-bash
  # Remove new line and add ./ at the beginning
  is_it_script "$file" && list_of_changed_scripts+=("./${file//[$'\t\r\n ']}")
done

# Get list of exceptions
readarray list_of_exceptions < <(cut -d ' ' -f 1 < <(grep -v "^#.*" exception-list.txt))

echo "Changed shell scripts:"
echo "${list_of_changed_scripts[@]}"
echo "List of exceptions:"
echo "${list_of_exceptions[@]}"
echo "------------"

# ------------ #
#  SHELLCHECK  #
# ------------ #

# sed part is to edit shellcheck output so csdiff/csgrep knows it is shellcheck output (--format=gcc)
shellcheck --format=gcc -e "${list_of_exceptions[@]}" "${list_of_changed_scripts[@]}" | sed -e 's|$| <--[shellcheck]|' > ../pr-br-shellcheck.err

# make destination branch
[[ ${TRAVIS_COMMIT_RANGE} =~ ^([0-9|a-f]*?)\. ]] && git checkout -b ci_br_dest "${BASH_REMATCH[1]}"

shellcheck --format=gcc -e "${list_of_exceptions[@]}" "${list_of_changed_scripts[@]}" | sed -e 's|$| <--[shellcheck]|' > ../dest-br-shellcheck.err

# ------------ #
#  VALIDATION  #
# ------------ #

exitstatus=0

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


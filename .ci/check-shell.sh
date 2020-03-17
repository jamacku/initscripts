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
readarray list_of_changes < <(grep "^[^#]" ../pr-changes.txt)
list_of_changed_scripts=()
for file in "${list_of_changes[@]}"; do
  # https://stackoverflow.com/questions/19345872/how-to-remove-a-newline-from-a-string-in-bash
  # Remove new line and add ./ at the beginning
  is_it_script "$file" && list_of_changed_scripts+=("./${file//[$'\t\r\n ']}")
done

echo -e "\n\n\n"
echo "##############"
echo "# CI OUTPUT: #"
echo "##############"
echo -e "\n\n\n"

echo "Changed shell scripts:"
echo "${list_of_changed_scripts[@]}"
echo "------------"
echo -e "\n\n"

# ------------ #
#  SHELLCHECK  #
# ------------ #

shellcheck --format=gcc "${list_of_changed_scripts[@]}" > ../pr-br-shellcheck.err

# make destination branch
[[ ${TRAVIS_COMMIT_RANGE} =~ ^([0-9|a-f]*?)\. ]] && git checkout -b ci_br_dest "${BASH_REMATCH[1]}"

shellcheck --format=gcc "${list_of_changed_scripts[@]}" > ../dest-br-shellcheck.err

# ------------ #
#  VALIDATION  #
# ------------ #

echo "Validation:"
echo "###########"
echo -e "\n\n"

exitstatus=0

# Check output for Fixes
csdiff --fixed "../dest-br-shellcheck.err" "../pr-br-shellcheck.err" > ../fixes.log
if [ "$(wc -l < ../fixes.log)" -ne 0 ]; then
  echo "Fixed bugs:" 
  csgrep ../fixes.log
  echo "------------"
else
  echo "No Fixes!"
  echo "------------"
fi

echo -e "\n\n"

# Check output for added bugs
csdiff --fixed "../pr-br-shellcheck.err" "../dest-br-shellcheck.err" > ../bugs.log
if [ "$(wc -l < ../bugs.log)" -ne 0 ]; then
  echo "Added bugs, NEED INSPECTION:" 
  csgrep ../bugs.log
  echo "------------"
  exitstatus=1
else
  echo "No bugs added Yay!" 
  echo "------------"
  exitstatus=0
fi

exit $exitstatus


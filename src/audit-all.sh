#!/bin/bash
######################################################################################
#
#     PROGRAM       : audit-all.sh
#     DESCRIPTION   : This script will generate an audit report for all Git repos in 
#                     a specified directory
#
#     CREATED BY    : Kevin Custer
#     CREATION DATE : 24-APR-2014
#
######################################################################################

START_HERE="/c/gitp/";
OUTPUT="$START_HERE/report.html"

cd $START_HERE;

echo "<html>" > $OUTPUT

echo -e "\nGenerating an audit report for $START_HERE\n";

for d in $(find . -maxdepth 1 -mindepth 1 -type d); do
	echo -e "$d";
	cd $d;

      # If master is not checked out, store the currently checked out branch
      # to return to it later
      CURRENT_BRANCH=$(git symbolic-ref HEAD | awk -F'/' '{print $3}')

      if [ "$CURRENT_BRANCH" != "master" ]; then
            git checkout master;
      fi

      # Get the latest changes for the master branch
      git pull

      echo "<h1>$(echo ${d} | tr -d './')</h1>" >> $OUTPUT
      echo
      for x in "$(git log --date=short --pretty=format:'%h|%s|%cd|%an' --since=4.weeks)"; do
            echo $x'</br>' >> $OUTPUT
      done
      echo

      # Return to the previously checked out branch
      if [ "$CURRENT_BRANCH" != "master" ]; then
            git checkout "$CURRENT_BRANCH";
      fi

	cd $START_HERE;
done

echo "</html>" >> $OUTPUT

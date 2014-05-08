#!/bin/bash
######################################################################################
#
#     PROGRAM       : audit-all.sh
#     DESCRIPTION   : This script will generate an audit report for all Git repos in 
#                     a specified directory
#     USAGE         : Set the START_HERE variable to the directory containing your
#                     repositories.
#     NOTE          : *** It's strongly recommended to maintain a separate
#                         working directory with fresh clones of all of your Git
#                         repositories for the purposes of running this script.
#
#     CREATED BY    : Kevin Custer
#     CREATION DATE : 24-APR-2014
#
######################################################################################

######################################################################################
# Constants
######################################################################################
START_HERE="/c/gitaudit"
OUTPUT="$START_HERE/report.html"
SINCE="3.weeks"
RIGHT_NOW=$(date +"%x %r %Z")
#LOG_CMD="git log --date=short --pretty=tformat:<tr><td>%h</td><td>%cd</td><td>%an</td><td>%s</td></tr>@@ --since=$SINCE"
LOG_CMD="git log --date=short --oneline --pretty=tformat:%h|%cd|%an|%s@@ --since=$SINCE"


######################################################################################
# Functions
######################################################################################

function generateLogTable ()
{
      BRANCH=$(echo ${1} | tr -d './')
      BRANCH_AUTHOR=`git for-each-ref --format='%(authorname)%09%(refname)' | grep origin/${1} | cut -f1`
      LOG=`$LOG_CMD ${2}`    
      
      if [ "${BRANCH}" = "master" ]; then
            TTITLE="<h3>${BRANCH}</h3>"
      else
            TTITLE="<h3>${BRANCH} (${BRANCH_AUTHOR})</h3>"
      fi

      echo "${TTITLE}"

      count=1
      LOG="${LOG}" | sed 's/@@ /'\\n'/g' | tr -d '@@'
      echo "${LOG}" | while read line
      do
            echo "line ${count}: " "${line}"
            count=$((count+1))
      done
      # if [ -z "${LOG}" ]; then
      #       echo "No recent activity"
      # else
      #       echo "<table>"
      #       echo "${LOG}" | sed 's/@@ /'\\\n'/g' | tr -d '@@'
      #       echo "</table>"
      # fi
}

function processBranches
{
      for b in $(git branch -r | sed '/HEAD/d' | sed '/master/d' | awk -F'origin/' '{print $2}'); do
            
            # If the remote branch already exists locally, check out the local branch
            if [ "${b}" = "$(git branch -l | grep "${b}" | tr -d ' ')" ]; then
                  git checkout -q ${b}
                  #git pull -q
            else
                  git checkout -q -t origin/${b}
            fi
            
            echo "$(generateLogTable ${b} master..)"
      done
}

function processRepos
{
      for d in $(find . -maxdepth 1 -mindepth 1 -type d); do
            cd $d

            # Print current repository name
            echo "<h1>$(echo ${d} | tr -d './')</h1>"

            # Preserve the current working branch
            CURRENT_BRANCH=$(git symbolic-ref HEAD | awk -F'/' '{print $3}')

            # Start with master
            if [ "$CURRENT_BRANCH" != "master" ]; then
                  git checkout -q master
            fi

            #git pull -q
            #git remote prune origin

            # Print Log for Master Branch
            echo "$(generateLogTable master)"

            # Process the remote branches
            echo "$(processBranches)"

            # Return to the previously checked out branch
            if [ "$CURRENT_BRANCH" != "master" ]; then
                  git checkout -q "$CURRENT_BRANCH"
            else
                  git checkout -q master
            fi

            # Go back to root directory
            cd $START_HERE
      done
}

function generatePage
{
cat << EOF
<html>
      <head>
            <title>Git Audit Report for $RIGHT_NOW</title>
      <style media="screen" type="text/css">
            body {
                  font-family:      sans-serif;
                  font-size:        10pt;
            }
      </style>
      </head>
<body>
$(processRepos)
</body>
</html>
EOF
}


######################################################################################
# MAIN
######################################################################################

echo -e "Generating an audit report for $START_HERE..."
cd $START_HERE
generatePage > $OUTPUT
echo -e "Git Audit Report created at $OUTPUT"

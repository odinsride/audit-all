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
START_HERE="/c/gitp"
OUTPUT="$START_HERE/report.html"
SINCE="4.weeks"
RIGHT_NOW=$(date +"%x %r %Z")
LOG_CMD="git log --date=short --pretty=tformat:<tr><td>%h</td><td>%s</td><td>%cd</td><td>%an</td></tr>@@ --since=$SINCE"


######################################################################################
# Functions
######################################################################################

function generateLogTable ()
{
      echo "      <h3>$(echo ${1} | tr -d './')</h3>"
      echo "      <table>"
      echo `$LOG_CMD ${2}` | sed 's/@@ /'\\\n'/g' | tr -d '@@'
      echo "      </table>"
      echo
}

function processBranches
{
      for b in $(git branch -r | sed '/HEAD/d' | sed '/master/d' | awk -F'origin/' '{print $2}'); do
            
            # If the remote branch already exists locally, check out the local branch instead
            
            if [ ${b} == $(git branch -l | grep ${b}) ]; then
                  git checkout -q ${b}
            else
                  git checkout -q -t origin/${b}
            fi
            
            echo "$(generateLogTable ${b} master..)"
      done
}

function processRepos
{
      cd $START_HERE
      for d in $(find . -maxdepth 1 -mindepth 1 -type d); do
            cd $d

            # Print current repository name
            echo "      <h1>$(echo ${d} | tr -d './')</h1>"

            # Preserve the current working branch
            CURRENT_BRANCH=$(git symbolic-ref HEAD | awk -F'/' '{print $3}')

            # Start with master
            if [ "$CURRENT_BRANCH" != "master" ]; then
                  git checkout -q master
            fi

            #git pull

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
generatePage > $OUTPUT
echo -e "Git Audit Report created at $OUTPUT"

#!/bin/bash
######################################################################################
#
#     PROGRAM       : audit-all.sh
#     DESCRIPTION   : This script will generate an audit report for all Git repos in 
#                     a specified directory
#     USAGE         : Set the GIT_REPOS variable to the directory containing your
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
GIT_REPOS="/c/git/UVA-Audit"
OUTPUT="${GIT_REPOS}/report.html"
SINCE="5.weeks"
RIGHT_NOW=$(date +"%x %r %Z")


######################################################################################
# System Commands
######################################################################################
getRepoList () {
  find . -name '.git' -maxdepth 2 | sed 's#\(.*\)/.*#\1#' | sed 's/.\///g'
}

getLog () {
  git log --date=short --oneline --pretty=tformat:"%h|%cd|%an|%s" --since=$SINCE ${1} ${2}
}

getRemoteBranches () {
  git branch -r | sed '/HEAD/d' | awk -F'origin/' '{print $2}'
}

getCurrentBranch () {
  git branch --no-color | grep '^\* ' | grep -v 'no branch' | sed 's/^* //g'
}

checkLocalBranch () {
  git branch -l | grep ${1} | tr -d '* '
}

######################################################################################
# Program Functions
######################################################################################
generateLogTable () {

  BRANCH=$(echo ${1} | tr -d './')
  BRANCH_AUTHOR=`git for-each-ref --format='%(authorname)%09%(refname)' | grep origin/${1} | cut -f1`
  LOG=$(getLog ${1} ${2}) 
      
  if [ "${BRANCH}" = "master" ]; then
    TTITLE="<h3>${BRANCH}</h3>"
  else
    TTITLE="<h3>${BRANCH} (${BRANCH_AUTHOR})</h3>"
  fi

  echo "${TTITLE}"

  if [ -z "${LOG}" ]; then
    echo "<div id=\"norecent\">- No recent activity -</div>"
  else
    echo "<table id=\"logTable\">"
    echo "  <thead>"
    echo "    <tr>"
    echo "      <th scope=\"col\">&nbsp;</th>"
    echo "      <th scope=\"col\">Hash</th>"
    echo "      <th scope=\"col\">Date</th>"
    echo "      <th scope=\"col\">Author</th>"
    echo "      <th scope=\"col\">Message</th>"
    echo "    </tr>"
    echo "  </thead>"

    echo "  <tbody>"
    count=1
    echo "${LOG}" | while read line
    do
      OIFS=$IFS
      IFS='|' read hsh date author msg <<< "${line}"
      IFS='-' read year month day <<< "${date}"

      echo "  <tr>"
      echo "    <td id=\"logrow\">${count}</td>"
      echo "    <td id=\"hash\">${hsh}</td>"
      echo "    <td id=\"date\">${month}/${day}/${year}</td>"
      echo "    <td id=\"author\">${author}</td>"
      echo "    <td id=\"msg\">${msg}</td>"
      echo "  </tr>"
      
      IFS=$OIFS
      count=$((count+1))
    done
    echo "  </tbody>"
    echo "</table>"
  fi
}

printBranches () {

  echo "    <div id=\"repoBranches\">"
  echo "      Branches:<br />"
  echo "      <ul>"
  
  for b in $(getRemoteBranches); do
    echo "      <li><a href=\"#${1}.${b}\">${b}</a></li>"
  done

  echo "      </ul>"
  echo "    </div>"

}

processBranches () {

  for b in $(getRemoteBranches); do
    
    is_local_branch=false

    # If the remote branch already exists locally, check out the local branch
    if [ ${b} = "$(checkLocalBranch ${b})" ]; then
      
      is_local_branch=true

      # If already on the branch, don't try to check it out again
      if [ ${b} != "$(getCurrentBranch)" ]; then
        git checkout -q ${b}
      fi

      git pull -q

    else
      git checkout -q -t origin/${b}
    fi
    
    # Print the log table for the branch
    if [ ${b} = "master" ]; then
      echo "$(generateLogTable ${b})"
    else
      echo "$(generateLogTable ${b} master..)"
    fi

    # Delete the local branch if it did not already exist
    if ! $is_local_branch ; then
      git checkout -q master

      # don't try to delete master
      if [ ${b} != "master" ]; then
        git branch -D ${b} > /dev/null
      fi
    fi

  done

}

updateRepo () {
  git pull -q
  git remote prune origin > /dev/null
}

# Process the current repository
processRepo () {

  original_branch=$(getCurrentBranch)

  # Start with master
  if [ ${original_branch} != "master" ]; then
    git checkout -q master
  fi

  # Pull and prune the repository
  updateRepo

  # Print a list of all the branches
  echo "$(printBranches ${1})"

  # Process the branches
  echo "$(processBranches)"

  # Return to the previously checked out branch
  if [ ${original_branch} != "master" ]; then
    git checkout -q ${original_branch}
  else
    git checkout -q master
  fi

}

# Process the repository directories
processRepoDirs () {

  cd ${GIT_REPOS}

  # loop through directories
  for d in $(getRepoList); do
  
    # Change to the current repository directory
    cd ${d}

    # Print current directory/repository name
    echo "<h1>$(echo ${d} | tr -d './')</h1>"

    # Process the current repository
    processRepo ${d}

    # Go back to root directory
    cd ${GIT_REPOS}

  done
}

# Create the HTML/CSS report skeleton
createReport () {
cat > ${OUTPUT} << EOF
<html>
  <head>
    <title>Git Audit Report for ${RIGHT_NOW}</title>
    <style media="screen" type="text/css">
      body {
        font-family:      "Lucida Sans Unicode", "Lucida Grande", Sans-Serif;
        font-size:        13px;
        color: #039;
      }
      a { color: inherit; }
      a:link
      {
        text-decoration: none;
      }
      a:visited
      {
        text-decoration: none;
      }
      a:hover
      {
        text-decoration: underline;
      }
      a:active
      {
        text-decoration: underline;
      }
      h1
      {
        font-size: 36px;
        border-top: 10px solid #6678b1;
        padding-top: 10px;
      }
      h3
      {
        font-size: 20px;
        margin-left: 30px;
      }
      #repoBranches
      {
        margin-left: 30px;
        font-weight: bold;
        width: 250px;
        border: 1px dotted #6678b1;
        background-color: #FBFDFF;
        padding: 10px;
      }
      #logTable
      {
        font-size: 13px;
        background: #fff;
        margin-left: 30px;
        margin-bottom: 60px;
        width: 80%;
        border-collapse: collapse;
        text-align: left;
      }
      #logTable th
      {
        font-size: 14px;
        font-weight: bold;
        padding: 10px 8px;
        border-bottom: 2px solid #6678b1;
      }
      #norecent
      {
        margin-left: 100px;
        margin-bottom: 60px;
      }
      #logTable td
      {
        border-bottom: 1px solid #ccc;
        color: #669;
        padding: 6px 8px;
      }
      #logTable tbody tr:hover td
      {
        color: #009;
      }
      #logrow
      {
        width: 3%;
        text-align: right;
        border-right: 1px dotted #ccc;
      }
      #hash
      {
        width: 10%;
      }
      #date
      {
        width: 10%;
      }
      #author
      {
        width: 15%;
      } 
      #msg
      {
        width: 62%;
      }
    </style>
  </head>
  <body>
  $(processRepoDirs)
  </body>
</html>
EOF
}

main() {
  echo "Generating an audit report for ${GIT_REPOS}..."
  createReport
  echo "Git Audit Report created at ${OUTPUT}"
}

######################################################################################
# MAIN
######################################################################################

main

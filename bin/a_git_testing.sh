#!/bin/bash

main(){
  echo "=== Start testing: ==="
  existing_commits=()
  missing_commits=()
  non_signed_off_commits=()
  #fetch commit sha from cv32e40s:
  nr_commits=50
  git_commits_100=$(git log --pretty=format:'%H' -$nr_commits)
  #echo $git_commits_100

  for (( i=1; i<=$nr_commits; i++ ))
  do
    #echo "Commit $i: "
    commit_i=$(echo $git_commits_100 | cut -d' ' -f$i)
    #echo $commit_i

    #lagre strengen:
    whole_message=$(git show -s --format=%s%b $commit_i)
    #echo $whole_message

    #sjekk etter signed-off-by:
    #hvis ja, kun vurder det foran signed-off-by.
    if grep -q "Signed-off-by" <<< "$whole_message";

      then signed_off_message=$(echo $whole_message | awk -F 'Signed-off-by' '{print $1}')
      #echo $signed_off_message


      #gå inn i cv32e40x repoet
       #TODO: git checkout xxx
      #søk i loggen etter commit meldingen: git log -100 --grep="iss misa check disable code"
      search_commit=$(git log -100 --grep="$signed_off_message" --format=oneline)
      #echo $search_commit

      if [[ -n $search_commit ]] #true if non-zero string
      then existing_commits+=($i)
      else
        missing_commits+=($i)
      fi

    else
      non_signed_off_commits+=($i)
    fi
  done

  echo
  echo "existing_commits"
  echo ${existing_commits[@]}
  echo "missing_commits"
  echo ${missing_commits[@]}
  echo "non_signed_off_commits"
  echo ${non_signed_off_commits[@]}
  echo

  #TODO: gjør denne if setningen sikker.
  if [[ -z $missing_commits ]] #true if non-zero string
  then echo "No missing commits, no need to merge"
  else
    echo "Missing commits, need to merge"
  fi

}

main "$@"

#  case $1 in
#    "--s_into_x-dv")
#    commit 1, på 100?
#    commit 2, på 100?
#    3 commiter på rad som er i 100 mergen.
#    commit X, på 100? jepp. Print commits som må merges.
#    commit X, på 100? jepp. Print commits som må merges.
#    commit X, på 100? jepp. Print commits som må merges.
#
#    fetch commit sha from cv32e40s: git log --pretty=format:'%H' -2/i
#       commit_hash = ${c:(i-1)*40:i*40} + for mellomrommene.
#    lagre strengen: whole_message = git show -s --format=%s%b <dbe808ff780e529df3c694e28a<808c24a96d010d>
#      sjekk etter signed-off-by:
#      hvis ja, kun vurder det foran signed-off-by.
#        if grep -q "$SUB" <<< "$STR"; then signed_off_message = ... echo $whole_message | cut -d'Signed-off by:' -f1
#        fi
#      hvis nei, gå videre: return ??
#
#    gå inn i cv32e40x repoet
#    søk i loggen etter commit meldingen: git log -100 --grep="iss misa check disable code"
#
#      ;;
#    "--sdev_into_xdev")
#      ;;
#    "--xdev_into_sdev")
#      ;;
#    *)
#      usage
#      ;;
#  esac



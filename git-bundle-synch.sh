#!/bin/bash
CurrentPath=$(pwd)
# a directory where two repositories will get fetched to
SynchLocation="/C/git-synch/"
# bundle file location - typicly on a media that transfers the file (like USB-stick)
BundleLocation="/E/bundlefile.bundle"
# remote location and alias name for repository A
RemoteA="https://github.com/LocationOfRepoA.git"
RepoA="RepoA"
# remote location and alias name for repository B
RemoteB="https://github.com/LocationOfRepoB.git"
RepoB="RepoB"

# check what remotes are accessible and
# assign local variables accordingly
git ls-remote --exit-code $RemoteA
if test $? = 0; then
  RemoteAvailable=$RemoteA
  RepoThis=$RepoA
  RepoOther=$RepoB
else
  git ls-remote --exit-code $RemoteB
  if test $? = 0; then
    RemoteAvailable=$RemoteB
    RepoThis=$RepoB
    RepoOther=$RepoA
  else
    echo "ERROR: Cannot access "$RemoteA" or "$RemoteB
    exit 1
  fi
fi

echo "Synchronizing from " $BundleLocation " into " $RemoteAvailable

# fetch from $RemoteAvailable
# slow
rm -rf $SynchLocation$RepoThis
git clone $RemoteAvailable $SynchLocation$RepoThis

# faster (requires fixing)
#if [ -d $SynchLocation$RepoThis ]; then
#  cd $SynchLocation$RepoThis
#  git fetch
#  git clean -fdx
#  git reset --hard
#  echo $SynchLocation$RepoThis"; git fetch; git reset --hard;"
#else
#  git clone $RemoteAvailable $SynchLocation$RepoThis
#fi

# fetch from bundle
rm -rf $SynchLocation$RepoOther
git clone $BundleLocation $SynchLocation$RepoOther
cd $SynchLocation$RepoOther
git fetch
git checkout master

# perform synchronization using merge with --allow-unrelated-histories
cd $SynchLocation$RepoThis
git remote add $RepoOther $SynchLocation$RepoOther
git fetch $RepoOther
if git merge --allow-unrelated-histories $RepoOther/master; then
  if git push; then
    # bundle is overriden with latest changes for future usages
    git bundle create $BundleLocation --branches --tags
    echo ""
    echo "SUCCESS"
  else
    echo "ERROR: Cannot push to remote "$RemoteAvailable
  fi
else
  echo ""
  echo "ERROR: Cannot merge "$RepoOther" into "$RepoThis
  echo "Please resolve conflicts in "$SynchLocation$RepoThis" and push to "$RemoteAvailable" manually"
  echo "then run this script again to recreate your bundle"
fi
git remote remove $RepoOther;

cd $CurrentPath;
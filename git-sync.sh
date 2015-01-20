#!/bin/bash
#
# The MIT License (MIT)
# Copyright (c) 2014 fishcried(tianqing.w@gmail.com)
#

trap 'echo "ERRTRAP $LINENO" && exit 2' ERR

LOG() { 
	[ "$DEBUG" == "true" ] && echo 1>&2 "$@" 
}

WORKSPACE=/var/cache/git-mirrors
DEBUG=true

if [ $# -ne 1 ];then
	echo "$(basename $0) project-file"
	exit 1
fi

PROJECTS=$1

[ -e $PROJECTS ] || { 
	echo "Can't find the projects file - $PROJECTS" 
	exit 1
}


if [ ! -e $WORKSPACE ];then
	mkdir $WORKSPACE
fi


cd $WORKSPACE

cat $PROJECTS | while read line
do
	# parse the config -> name origin mirror
	eval $(echo $line | awk '{printf("project_dir=%s; origin_url=%s; mirror_url=%s;",$1,$2,$3)}')
	

	LOG "Starting $project_dir:  [$origin_url] --->> [$mirror_url]"
	
	if [ ! -d "$project_dir" ];then
		# clone the new project
		LOG "Clone $project_dir from $origin_url"
		git clone $origin_url
		cd $project_dir

		# set the back mirror
		LOG "Add mirror repository $mirror_url"
		git remote add mirror $mirror_url

		LOG "Starting track remote branchs"
		for br in $(git branch -r | sed '1,2d;s/\*//;s/ //g')
		do
			LOG "Track branch $br"
			git checkout --track $br
		done
		cd ..
	fi

	# pull from the origin and push to the mirror

	cd $project_dir
	LOG "Starting sync mirror"
	for br in $(git branch | sed 's/\*//;s/ //g')
	do
		LOG "Pulling $br from $origin_url"
		git pull origin 
		LOG "Pushing $br to $mirror_url"
		git push mirror $br 
		git push mirror --tags
	done
	cd ..

	LOG "Finish mirror $project_dir"

done

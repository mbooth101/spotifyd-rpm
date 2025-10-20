#!/bin/bash


REPO=copr:copr.fedorainfracloud.org:mbooth:spotifyd

sudo dnf --assumeyes copr enable mbooth/spotifyd

# Pre-fetch SRPMs for all avilable RPMs
declare -A SRPM_MAP
for rpm in $(sudo dnf --repo=$REPO repoquery --available 2>/dev/null) ; do
	rpm_name=$(echo -n "$rpm" | rev | cut -f1,2 -d- --complement | rev)
	if [[ "$rpm" =~ .*\.src$ ]] ; then
		srpm_name=$rpm_name
	else
		srpm=$(sudo dnf --repo=$REPO repoquery --sourcerpm $rpm_name 2>/dev/null | xargs)
		srpm_name=$(echo -n "$srpm" | rev | cut -f1,2 -d- --complement | rev)
	fi
	SRPM_MAP["$rpm_name"]="$srpm_name"
	echo -n "." 1>&2
done
echo 1>&2

# Generate dependency tree
echo "digraph deps {" > package_tree.dot
for rpm in ${!SRPM_MAP[@]} ; do
	deps=$(sudo dnf --repo=$REPO repoquery --available --recursive --whatrequires $rpm 2>/dev/null)
	srpm=${SRPM_MAP[$rpm]}
	for dep in $deps ; do
		dep_name=$(echo -n "$dep" | rev | cut -f1,2 -d- --complement | rev)
		if [[ "$dep" =~ .*\.src$ ]] ; then
			dep_srpm=$dep_name
		else
			dep_srpm=${SRPM_MAP[$dep_name]}
		fi
		if [ "$srpm" != "$dep_srpm" ] ; then
			echo "\"$dep_srpm\" -> \"$srpm\";"
		fi
	done
	echo -n "." 1>&2
done | sort | uniq >> package_tree.dot
echo 1>&2
echo "}" >> package_tree.dot
dot package_tree.dot -Tpng -opackage_tree.png
loupe package_tree.png


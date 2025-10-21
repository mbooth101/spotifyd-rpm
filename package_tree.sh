#!/bin/bash

NAME=spotifyd
REPO=copr:copr.fedorainfracloud.org:mbooth:$NAME

sudo dnf --assumeyes copr enable mbooth/$NAME

function pkg_name {
	echo -n "$1" | rev | cut -f1,2 -d- --complement | rev
}

# All RPMs in the repo
ALL_RPMS=$(sudo dnf --repo=$REPO repoquery --available 2>/dev/null)

# Pre-fetch SRPMs for all avilable RPMs
declare -A SRPMNAME_VERREL_MAP
declare -A RPM_SRPM_MAP
for rpm in $ALL_RPMS ; do
	rpm_name=$(pkg_name $rpm)
	rpm_verrel=$(echo -n "$rpm" | rev | cut -f1,2 -d- | rev | sed -e 's/\(\.fc[0-9][0-9]\)\..*/\1/')
	if [[ "$rpm" =~ .*\.src$ ]] ; then
		srpm=$rpm
		srpm_name=$rpm_name
		srpm_verrel=$rpm_verrel
	else
		srpm=$(sudo dnf --repo=$REPO repoquery --sourcerpm ${rpm_name}-${rpm_verrel} 2>/dev/null | xargs)
		srpm_name=$(pkg_name $srpm)
		srpm_verrel=$(echo -n "$srpm" | rev | cut -f1,2 -d- | rev | sed -e 's/\(\.fc[0-9][0-9]\)\..*/\1/')
	fi
	srpm_highest_verrel=${SRPMNAME_VERREL_MAP[$srpm_name]}
	if [ -z "$srpm_highest_verrel" ] ; then
		SRPMNAME_VERREL_MAP[$srpm_name]=$srpm_verrel
	else
		rpmdev-vercmp $srpm_highest_verrel $srpm_verrel &>/dev/null
		if [ "$?" = 12 ] ; then
			SRPMNAME_VERREL_MAP[$srpm_name]=$srpm_verrel
		fi
	fi
	RPM_SRPM_MAP[$rpm]=$srpm
	echo -n "." 1>&2
done
echo 1>&2

# Generate dependency tree
echo "digraph deps {" > package_tree.dot
echo "rankdir=\"LR\";" >> package_tree.dot
for rpm in "${!RPM_SRPM_MAP[@]}" ; do
	srpm=${RPM_SRPM_MAP[$rpm]}
	rpm_name=$(pkg_name $rpm)
	rpm_verrel=$(echo -n "$rpm" | rev | cut -f1,2 -d- | rev | sed -e 's/\(\.fc[0-9][0-9]\)\..*/\1/')
	srpm_name=$(pkg_name $srpm)
	srpm_verrel=$(echo -n "$srpm" | rev | cut -f1,2 -d- | rev | sed -e 's/\(\.fc[0-9][0-9]\)\..*/\1/')
	srpm_highest_verrel=${SRPMNAME_VERREL_MAP[$srpm_name]}
	# Skip RPM if it belongs to a SRPM that is not the highest version
	rpmdev-vercmp $srpm_highest_verrel $srpm_verrel &>/dev/null
	if [ "$?" != 0 ] ; then
		continue
	fi
	# Find RPMs that depend on this RPM
	deps=$(sudo dnf --repo=$REPO repoquery --available --recursive --whatrequires ${rpm_name}-${rpm_verrel} 2>/dev/null)
	for dep in $deps ; do
		dep_name=$(echo -n "$dep" | rev | cut -f1,2 -d- --complement | rev)
		if [[ "$dep" =~ .*\.src$ ]] ; then
			dep_srpm_name=$dep_name
		else
			dep_srpm_name=$(pkg_name ${RPM_SRPM_MAP[$dep]})
		fi
		if [ "$srpm_name" != "$dep_srpm_name" ] ; then
			echo "\"$dep_srpm_name\" -> \"$srpm_name\";"
		fi
	done
	echo -n "." 1>&2
done | sort | uniq >> package_tree.dot
echo 1>&2
echo "}" >> package_tree.dot
dot package_tree.dot -Tpng -opackage_tree.png

if which loupe &>/dev/null ; then
	loupe package_tree.png
else
	eog package_tree.png
fi


#!/bin/python3

import sys
from dnf import Base

class Node:
    def __init__(self, srpm):
        self.deps = []
        self.srpm = srpm

def getNode(nodes, srpm):
    # Get node from list or create one if necessary
    node = next((x for x in nodes if x.srpm == srpm), None)
    if not node:
        node = Node(srpm)
        nodes.append(node)
    return node

def main(argv):
    NAME = argv[0]

    # Load COPR repo
    base = Base()
    base.repos.add_new_repo(f"mbooth:{NAME}", base.conf, baseurl=[f"https://download.copr.fedorainfracloud.org/results/mbooth/{NAME}/fedora-$releasever-$basearch/"])
    base.fill_sack(load_system_repo=False)

    # Find all RPMs in repository
    all_query = base.sack.query().available()
    all_pkgs = all_query.run()

    srpm_requirements = {}
    for pkg in all_pkgs:
        # Determine SRPM for RPM
        name = pkg.name
        if pkg.arch != 'src':
            name = pkg.source_name
        # Create requirements list for RPM
        if name not in srpm_requirements:
            srpm_requirements[name] = []
        for require in pkg.requires:
            if require not in srpm_requirements[name]:
                srpm_requirements[name].append(require)

    nodes = []
    for srpm in srpm_requirements:
    
        # Find RPMs in repository that satisfy the requirements
        provides_query = base.sack.query().available().filter(provides=srpm_requirements[srpm])
        provides_pkgs = provides_query.run()

        # Get node for the SRPM
        node = getNode(nodes, srpm)
        for pkg in provides_pkgs:
            # Ignore if self-provides
            if pkg.source_name == srpm:
                continue
            # Add dependency node as a child to the SRPM node
            dep_node = getNode(nodes, pkg.source_name)
            if dep_node not in node.deps:
                node.deps.append(dep_node)

    print("digraph deps {")
    print("rankdir=\"LR\";")
    for node in nodes:
        for dep in node.deps:
            print(f"\"{node.srpm}\" -> \"{dep.srpm}\";")
    print("}")

if __name__ == "__main__":
    main(sys.argv[1:])

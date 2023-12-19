#!/usr/bin/env bash

output_path=""
url=""

# Function to display usage information
usage() {
    echo "Usage: $0 -o <output_path> -u <url> -f <targetformat> -n <listname>"
    exit 1
}

# Parse command-line options
while getopts ":o:u:f:n:g:" opt; do
    case $opt in
        o)
            output_path="$OPTARG"
            ;;
        u)
            url="$OPTARG"
            ;;
	f)
	    targetformat="$OPTARG"
	    ;;
	n)
	    listname="$OPTARG"
	    ;;
	g)
	    grepcondition="$OPTARG"
	    ;;
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            usage
            ;;
    esac
done

# Check if both parameters are provided
if [ -z "$output_path" ] || [ -z "$url" ]; then
    echo "Both output path and URL are mandatory."
    usage
fi
if [ -z $targetformat ]; then
    targetformat="dnsdist"
fi
if [ -z $grepcondition ]; then
    grepcondition="0.0.0.0"
fi

# different target format condition
if [ $targetformat == "unbound" ]; then
    echo "server:" > "${output_path}"
    curl -s "${url}" | \
        grep ^${grepcondition} - | \
        sed 's/ #.*$//;
        s/^${grepcondition} \(.*\)/local-zone: "\1" refuse/' \
        >> "${output_path}"
elif [ "$targetformat" == "dnsdist" ]; then
    if [ -z $listname ]; then
	echo "if you convert to dnsdist you have to give a listname with -n"
	exit 10
    fi
    listname="Domainlist${listname}"
    echo "${listname}=newSuffixMatchNode()" > "${output_path}"
    curl -s "${url}" | \
        grep ^0.0.0.0 - | \
        sed -E 's|^0\.0\.0\.0[[:space:]]([^[:space:]]+).*|'"${listname}:add(\"\\1\")"'|' \
        >> "${output_path}"
elif [ "$targetformat" == "plain" ]; then
    curl -s "${url}" | \
        grep ^${grepcondition} - | \
	awk -v ip="${grepcondition}" '$1 == ip { print $2 }' \
	>> "${output_path}"
fi


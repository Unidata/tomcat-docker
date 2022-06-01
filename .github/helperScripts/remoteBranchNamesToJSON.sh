# What this script does, pipe by pipe:

# Print all remote branches |
# Find all lines that *don't* have the string HEAD, main, or master (eg origin/HEAD -> origin/main) |
# Find only lines that have "origin/" in the name (ie in case of multiple remotes) |
# Print the branch name by accessing the second string delimited by "/" |
# Use sed to:
	# -e "Add quotes around, and a comma at the end of, each line"
	# -e "remove comma from the last line"
	# -e "insert a "[" before the first line"
	# -e "insert a "]" after the last line"

git branch -r | grep -v "HEAD" | grep -v "main" | grep -v "master" |
grep "origin/" | awk -F "/" '{print $2}' |
sed -e "s/.*/\"&\",/g" -e "$ s/,$//g" -e "1 i \"branch\": [" -e "$ a ]"

#!/bin/bash

# Set the organization name and output file
ORG_NAME="scta-texts"
OUTPUT_README="./profile/README.md"

# Initialize counters
total_repos=0
passing_repos=0
failing_repos=0
failing_list=""

# Start the README content
echo "## SCTA-TEXTS" > "$OUTPUT_README"
echo "" >> "$OUTPUT_README"
echo "## Summary Report" >> "$OUTPUT_README"
echo "" >> "$OUTPUT_README"

# Fetch all repositories in the organization using the GitHub CLI
repos=$(gh repo list "$ORG_NAME" --limit 1000 --json name --jq '.[]')

# Iterate over each repository
for repo in $(echo "$repos" | jq -c '.'); do
    echo "Processing repository: $repo"
    repo_name=$(echo "$repo" | jq -r '.name')
    ((total_repos++))

    # Check if the repository has a validation workflow
    validation_file_url="https://raw.githubusercontent.com/$ORG_NAME/$repo_name/master/.github/workflows/validation.yml"
    validation_file_status=$(curl -s -o /dev/null -w "%{http_code}" "$validation_file_url")

    if [[ "$validation_file_status" -eq 200 ]]; then
        # Generate status badge link
        status_badge="[![CI](https://github.com/$ORG_NAME/$repo_name/actions/workflows/validation.yml/badge.svg?branch=master)](https://github.com/$ORG_NAME/$repo_name/actions/workflows/validation.yml)"

        # Check the status badge
        status_badge_url="https://github.com/$ORG_NAME/$repo_name/actions/workflows/validation.yml/badge.svg?branch=master"
        status=$(curl -s -o /dev/null -w "%{http_code}" "$status_badge_url")
        echo "Status code for $repo_name: $status"

        if [[ "$status" -eq 200 ]]; then
            ((passing_repos++))
        else
            ((failing_repos++))
            failing_list+="  - [$repo_name](https://github.com/$ORG_NAME/$repo_name/actions/workflows/validation.yml)\n"
        fi
    fi
    echo "total $total_repos"
    echo "passing $passing_repos"
    echo "failing $failing_repos"
done

# Append summary to README
echo "Total Repositories: $total_repos" >> "$OUTPUT_README"
echo "Passing Repositories: $passing_repos" >> "$OUTPUT_README"
echo "Failing Repositories: $failing_repos" >> "$OUTPUT_README"
echo "" >> "$OUTPUT_README"

if [[ "$failing_repos" -gt 0 ]]; then
    echo "### Failing Repositories" >> "$OUTPUT_README"
    echo "" >> "$OUTPUT_README"
    echo -e "$failing_list" >> "$OUTPUT_README"
fi

echo "README file updated at $OUTPUT_README"
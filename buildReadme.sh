#!/bin/bash

# Set the organization name and output file
ORG_NAME="scta-texts"
OUTPUT_README="./profile/README.md"

# Initialize counters
total_repos=0
passing_repos=0
failing_repos=0
no_workflow_repos=0
recent_activity_repos=0
total_open_issues=0
total_open_prs=0
failing_list=""
no_workflow_list=""
recent_activity_list=""

# Start the README content
echo "## SCTA-TEXTS" > "$OUTPUT_README"
echo "" >> "$OUTPUT_README"
echo "## Summary Report" >> "$OUTPUT_README"
echo "" >> "$OUTPUT_README"

# Fetch all repositories in the organization using the GitHub CLI
repos=$(gh repo list "$ORG_NAME" --limit 1000 --json name,pushedAt --jq '.[]')

# Iterate over each repository
for repo in $(echo "$repos" | jq -c '.'); do
    repo_name=$(echo "$repo" | jq -r '.name')
    pushed_at=$(echo "$repo" | jq -r '.pushedAt')
    ((total_repos++))

    # Check if the repository has a validation workflow
    validation_file_url="https://raw.githubusercontent.com/$ORG_NAME/$repo_name/master/.github/workflows/validation.yml"
    validation_file_status=$(curl -s -o /dev/null -w "%{http_code}" "$validation_file_url")

    if [[ "$validation_file_status" -eq 200 ]]; then
        # Generate status badge link
        status_badge="[![CI](https://github.com/$ORG_NAME/$repo_name/actions/workflows/validation.yml/badge.svg?branch=master)](https://github.com/$ORG_NAME/$repo_name/actions/workflows/validation.yml)"

        # Check the status of the latest workflow run
        workflow_status=$(gh run list --repo "$ORG_NAME/$repo_name" --limit 1 --json status,conclusion --jq '.[0] | select(.status == "completed") | .conclusion')

        if [[ "$workflow_status" == "success" ]]; then
            ((passing_repos++))
        else
            ((failing_repos++))
            failing_list+="  - [$repo_name](https://github.com/$ORG_NAME/$repo_name/actions/workflows/validation.yml)\n"
        fi
    else
        ((no_workflow_repos++))
        no_workflow_list+="  - [$repo_name](https://github.com/$ORG_NAME/$repo_name)\n"
    fi

    # Check for recent activity (within the last 6 months)
    if [[ $(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$pushed_at" +%s) -ge $(date -v-6m +%s) ]]; then
        ((recent_activity_repos++))
        recent_activity_list+="  - [$repo_name](https://github.com/$ORG_NAME/$repo_name): Last activity on $pushed_at\n"
    fi

    # Count open issues
    open_issues=$(gh issue list --repo "$ORG_NAME/$repo_name" --state open --json number --jq 'length')
    total_open_issues=$((total_open_issues + open_issues))

    # Count open pull requests
    open_prs=$(gh pr list --repo "$ORG_NAME/$repo_name" --state open --json number --jq 'length')
    total_open_prs=$((total_open_prs + open_prs))
done

# Append summary to README
echo "Total Repositories: $total_repos" >> "$OUTPUT_README"
echo "Passing Repositories: $passing_repos" >> "$OUTPUT_README"
echo "Failing Repositories: $failing_repos" >> "$OUTPUT_README"
echo "Repositories Without Workflows: $no_workflow_repos" >> "$OUTPUT_README"
echo "Repositories With Recent Activity: $recent_activity_repos" >> "$OUTPUT_README"
echo "Total Open Issues: $total_open_issues" >> "$OUTPUT_README"
echo "Total Open Pull Requests: $total_open_prs" >> "$OUTPUT_README"
echo "" >> "$OUTPUT_README"

if [[ "$failing_repos" -gt 0 ]]; then
    echo "### Failing Repositories" >> "$OUTPUT_README"
    echo "" >> "$OUTPUT_README"
    echo -e "$failing_list" >> "$OUTPUT_README"
fi

if [[ "$no_workflow_repos" -gt 0 ]]; then
    echo "### Repositories Without Workflows" >> "$OUTPUT_README"
    echo "" >> "$OUTPUT_README"
    echo -e "$no_workflow_list" >> "$OUTPUT_README"
fi

if [[ "$recent_activity_repos" -gt 0 ]]; then
    echo "### Repositories With Recent Activity" >> "$OUTPUT_README"
    echo "" >> "$OUTPUT_README"
    echo -e "$recent_activity_list" >> "$OUTPUT_README"
fi

echo "README file updated at $OUTPUT_README"
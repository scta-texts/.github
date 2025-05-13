#!/bin/bash

# Set the base directory and output file
BASE_DIR="/Users/jcwitt/Projects/scta/scta-texts"
OUTPUT_README="$BASE_DIR/.github/profile/README.md"

# Start the README content
echo "## SCTA-TEXTS" > "$OUTPUT_README"
echo "" >> "$OUTPUT_README"
echo "## How to use" >> "$OUTPUT_README"
echo "" >> "$OUTPUT_README"
echo "## How to contribute" >> "$OUTPUT_README"
echo "" >> "$OUTPUT_README"
echo "## Status of Repositories" >> "$OUTPUT_README"
echo "" >> "$OUTPUT_README"

# Iterate over subdirectories
for repo_dir in "$BASE_DIR"/*; do
    if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        repo_name=$(basename "$repo_dir")
        echo $repo_name
    
        # Fetch repository details using gh CLI
        #repo_info=$(gh repo view "scta-texts/$repo_name" --json name,description,openIssuesCount --jq '{name: .name, description: .description, open_issues: .openIssuesCount}')
        repo_info=$(gh repo view "scta-texts/$repo_name" --json name,description,issues --jq '{name: .name, description: .description, open_issues: .issues.totalCount}')
        if [ -z "$repo_info" ]; then
            echo "Failed to fetch info for $repo_name"
            continue
        fi

        # Extract details
        repo_name=$(echo "$repo_info" | jq -r '.name')
        repo_description=$(echo "$repo_info" | jq -r '.description')
        open_issues=$(echo "$repo_info" | jq -r '.open_issues')

        # Fetch the number of open pull requests
        open_prs=$(gh pr list --repo "scta-texts/$repo_name" --state open --json id --jq 'length')

        # Generate status badge link
        status_badge="[![CI](https://github.com/scta-texts/$repo_name/actions/workflows/validation.yml/badge.svg?branch=master)](https://github.com/scta-texts/$repo_name/actions/workflows/validation.yml)"

        # Generate live links for issues and pull requests
        issues_link="[Open Issues](https://github.com/scta-texts/$repo_name/issues)"
        prs_link="[Open Pull Requests](https://github.com/scta-texts/$repo_name/pulls)"

        # Append to README
        echo "- **$repo_name**: ${repo_description:-No description}" >> "$OUTPUT_README"
        echo "  - Open Issues: $open_issues ($issues_link)" >> "$OUTPUT_README"
        echo "  - Open Pull Requests: $open_prs ($prs_link)" >> "$OUTPUT_README"
        echo "  - Status: $status_badge" >> "$OUTPUT_README"
        echo "" >> "$OUTPUT_README"
    fi
done

echo "README file updated at $OUTPUT_README"
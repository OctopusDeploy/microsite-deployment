$githubToken = $OctopusParameters["GitHub.Token"]
$pullRequestNumber = $OctopusParameters["Octopus.Release.CustomFields[PullRequestNumber]"]
$environmentName = $OctopusParameters["Octopus.Environment.Name"]
$ephemeralUrl = $OctopusParameters["Octopus.Action[Get Static Site URL].Output.StaticWebsiteUrl"]
$repository = $OctopusParameters["GitHub.Repository"]

# Configure gh CLI auth
$env:GH_TOKEN = $githubToken

# Build comment body
$commentBody = @"
Pull request environment is available at $ephemeralUrl.

You can view the [ephemeral environment status in Octopus Deploy](https://deploy.octopus.app/app#/Spaces-2095/projects/blog-microsite/ephemeral-environments?page=1&environmentName=$environmentName&status=all).

This environment will be automatically deprovisioned when the pull request is closed, or after 7 days of inactivity.
"@

Write-Host "Adding comment to pull request #$pullRequestNumber"
gh pr comment $pullRequestNumber --repo $repository --edit-last --create-if-none --body $commentBody
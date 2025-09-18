# Build the Flutter web app
flutter build web --base-href /mathquest/

# Create temporary worktree for gh-pages
$tempDir = "temp_gh_pages_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
git worktree add $tempDir gh-pages 2>$null
if ($LASTEXITCODE -ne 0) {
    git worktree add -b gh-pages $tempDir
}

try {
    # Work in the temporary directory
    Push-Location $tempDir
    
    # Remove old files except important ones
    Get-ChildItem -Path . -Exclude .git, .gitignore, CNAME, README.md | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    
    # Copy build files
    Copy-Item -Path "..\build\web\*" -Destination . -Recurse -Force
    
    # Add and commit only if there are changes
    git add .
    $changes = git status --porcelain
    if ($changes) {
        git commit -m "Deploy to GitHub Pages - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git push origin gh-pages
    }
}
finally {
    # Return to original directory and clean up
    Pop-Location
    git worktree remove $tempDir --force
}
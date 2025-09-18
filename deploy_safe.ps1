# Deploy seguro para GitHub Pages (sem mudar branch)
Write-Host "Iniciando deploy..." -ForegroundColor Green

# Verificar se estamos na branch main
$currentBranch = git branch --show-current
if ($currentBranch -ne "main") {
    Write-Host "Erro: Execute o deploy apenas da branch main" -ForegroundColor Red
    exit 1
}

# Build da aplicação Flutter web
Write-Host "Construindo aplicação web..." -ForegroundColor Blue
flutter build web --base-href /mathquest/

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro ao fazer build da aplicação" -ForegroundColor Red
    exit 1
}

# Criar diretório temporário para deploy
$tempDir = "temp_gh_pages_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host "Criando worktree temporário..." -ForegroundColor Blue

# Criar worktree da branch gh-pages em diretório temporário
git worktree add $tempDir gh-pages

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro ao criar worktree. Tentando criar branch gh-pages..." -ForegroundColor Yellow
    git worktree add -b gh-pages $tempDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erro ao criar worktree e branch" -ForegroundColor Red
        exit 1
    }
}

try {
    # Navegar para o diretório temporário
    Push-Location $tempDir
    
    # Remover arquivos antigos (exceto .git e arquivos importantes)
    Write-Host "Removendo arquivos antigos da branch gh-pages..." -ForegroundColor Blue
    Get-ChildItem -Path . -Exclude .git, .gitignore, CNAME, README.md | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    
    # Copiar novos arquivos do build
    Write-Host "Copiando arquivos do build..." -ForegroundColor Blue
    Copy-Item -Path "..\build\web\*" -Destination . -Recurse -Force
    
    # Verificar se há alterações
    $changes = git status --porcelain
    if ($changes) {
        # Adicionar e commitar alterações
        Write-Host "Adicionando alterações..." -ForegroundColor Blue
        git add .
        
        $commitMessage = "Deploy to GitHub Pages - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Host "Fazendo commit: $commitMessage" -ForegroundColor Blue
        git commit -m $commitMessage
        
        # Push para origin
        Write-Host "Enviando para GitHub..." -ForegroundColor Blue
        git push origin gh-pages
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Deploy realizado com sucesso!" -ForegroundColor Green
            Write-Host "URL: https://loopedsouls.github.io/mathquest/" -ForegroundColor Cyan
        } else {
            Write-Host "Erro ao fazer push para GitHub" -ForegroundColor Red
        }
    } else {
        Write-Host "Nenhuma alteração para fazer deploy" -ForegroundColor Yellow
    }
}
finally {
    # Voltar para diretório original
    Pop-Location
    
    # Remover worktree temporário
    Write-Host "Removendo worktree temporário..." -ForegroundColor Blue
    git worktree remove $tempDir --force
}

Write-Host "Deploy concluído! Você continua na branch: $(git branch --show-current)" -ForegroundColor Green
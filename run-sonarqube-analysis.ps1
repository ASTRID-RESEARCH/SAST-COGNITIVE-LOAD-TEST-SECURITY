<#
.SYNOPSIS
    Script para executar análise do SonarQube no código do Juice Shop

.DESCRIPTION
    Este script automatiza a execução da análise de código estático do
    OWASP Juice Shop usando SonarQube Scanner em container Docker.

.EXAMPLE
    .\run-sonarqube-analysis.ps1

.NOTES
    Pré-requisitos:
    - SonarQube deve estar rodando (use .\manage-containers.ps1 -Action Start)
    - Docker Desktop deve estar em execução
#>

[CmdletBinding()]
param()

$ColorSuccess = 'Green'
$ColorError = 'Red'
$ColorWarning = 'Yellow'
$ColorInfo = 'Cyan'

$SonarQubeUrl = "http://localhost:9000"
$SonarQubeUser = "admin"
$SonarQubePass = "admin"
$ProjectKey = "juice-shop"
$ProjectPath = ".\juice-shop"

function Show-Banner {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor $ColorInfo
    Write-Host "║   Análise de Código com SonarQube                 ║" -ForegroundColor $ColorInfo
    Write-Host "║   OWASP Juice Shop                                ║" -ForegroundColor $ColorInfo
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor $ColorInfo
    Write-Host ""
}

function Test-SonarQubeAvailable {
    param([int]$MaxAttempts = 30)
    
    Write-Host "[INFO] Verificando disponibilidade do SonarQube..." -ForegroundColor $ColorInfo
    
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "$SonarQubeUrl/api/system/status" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            $status = ($response.Content | ConvertFrom-Json).status
            
            if ($status -eq 'UP') {
                Write-Host "[SUCCESS] SonarQube está disponível!" -ForegroundColor $ColorSuccess
                return $true
            }
        }
        catch {
            Write-Host "[WAIT] Aguardando SonarQube iniciar... (tentativa $i/$MaxAttempts)" -ForegroundColor $ColorWarning
            Start-Sleep -Seconds 10
        }
    }
    
    return $false
}

function Initialize-SonarQubeProject {
    Write-Host "[INFO] Verificando projeto no SonarQube..." -ForegroundColor $ColorInfo
    
    try {
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($SonarQubeUser):$($SonarQubePass)"))
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }
        
        $projectUrl = "$SonarQubeUrl/api/projects/search?projects=$ProjectKey"
        $response = Invoke-RestMethod -Uri $projectUrl -Headers $headers -Method Get -ErrorAction Stop
        
        if ($response.components.Count -eq 0) {
            Write-Host "[INFO] Criando projeto no SonarQube..." -ForegroundColor $ColorInfo
            
            $createUrl = "$SonarQubeUrl/api/projects/create?project=$ProjectKey&name=OWASP%20Juice%20Shop"
            Invoke-RestMethod -Uri $createUrl -Headers $headers -Method Post -ErrorAction Stop | Out-Null
            
            Write-Host "[SUCCESS] Projeto criado com sucesso!" -ForegroundColor $ColorSuccess
        }
        else {
            Write-Host "[INFO] Projeto já existe no SonarQube." -ForegroundColor $ColorInfo
        }
        
        return $true
    }
    catch {
        Write-Host "[WARNING] Não foi possível verificar/criar projeto automaticamente." -ForegroundColor $ColorWarning
        Write-Host "[INFO] O projeto será criado automaticamente na primeira análise." -ForegroundColor $ColorInfo
        return $true
    }
}

function Get-SonarQubeToken {
    Write-Host "[INFO] Gerando token de autenticação..." -ForegroundColor $ColorInfo
    
    try {
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($SonarQubeUser):$($SonarQubePass)"))
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }
        
        $tokenName = "juice-shop-analysis-$(Get-Date -Format 'yyyyMMddHHmmss')"
        
        $tokenUrl = "$SonarQubeUrl/api/user_tokens/generate?name=$tokenName"
        $response = Invoke-RestMethod -Uri $tokenUrl -Headers $headers -Method Post -ErrorAction Stop
        
        Write-Host "[SUCCESS] Token gerado com sucesso!" -ForegroundColor $ColorSuccess
        return $response.token
    }
    catch {
        Write-Host "[WARNING] Não foi possível gerar token. Tentando análise sem autenticação..." -ForegroundColor $ColorWarning
        return $null
    }
}

function Start-SonarAnalysis {
    param([string]$Token)
    
    Write-Host "[INFO] Iniciando análise de código..." -ForegroundColor $ColorInfo
    Write-Host ""
    
    $absolutePath = (Resolve-Path $ProjectPath).Path
    
    Write-Host "[INFO] Executando análise com SonarScanner..." -ForegroundColor $ColorInfo
    Write-Host ""
    
    if ($Token) {
        $dockerArgs = @(
            'run'
            '--rm'
            '--network', 'wp-survey_security-analysis'
            '-v', "${absolutePath}:/usr/src"
            'sonarsource/sonar-scanner-cli'
            "-Dsonar.projectKey=$ProjectKey"
            '-Dsonar.sources=.'
            '-Dsonar.host.url=http://sonarqube:9000'
            "-Dsonar.token=$Token"
            '-Dsonar.exclusions=**/node_modules/**,**/dist/**,**/build/**,**/coverage/**,**/test/**,**/tests/**,**/*.spec.ts,**/*.spec.js,**/*.test.ts,**/*.test.js'
            '-Dsonar.sourceEncoding=UTF-8'
        )
    }
    else {
        $dockerArgs = @(
            'run'
            '--rm'
            '--network', 'wp-survey_security-analysis'
            '-v', "${absolutePath}:/usr/src"
            'sonarsource/sonar-scanner-cli'
            "-Dsonar.projectKey=$ProjectKey"
            '-Dsonar.sources=.'
            '-Dsonar.host.url=http://sonarqube:9000'
            '-Dsonar.exclusions=**/node_modules/**,**/dist/**,**/build/**,**/coverage/**,**/test/**,**/tests/**,**/*.spec.ts,**/*.spec.js,**/*.test.ts,**/*.test.js'
            '-Dsonar.sourceEncoding=UTF-8'
        )
    }
    
    & docker $dockerArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[SUCCESS] Análise concluída com sucesso!" -ForegroundColor $ColorSuccess
        Write-Host ""
        Write-Host "Acesse os resultados em:" -ForegroundColor $ColorInfo
        Write-Host "  $SonarQubeUrl/dashboard?id=$ProjectKey" -ForegroundColor $ColorSuccess
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "[ERROR] Falha na execução da análise!" -ForegroundColor $ColorError
        Write-Host "[INFO] Verifique se o SonarQube está rodando e acessível." -ForegroundColor $ColorWarning
        exit 1
    }
}

Show-Banner

try {
    docker ps | Out-Null
}
catch {
    Write-Host "[ERROR] Docker não está em execução!" -ForegroundColor $ColorError
    Write-Host "[INFO] Inicie o Docker Desktop e tente novamente." -ForegroundColor $ColorWarning
    exit 1
}

if (-not (Test-Path $ProjectPath)) {
    Write-Host "[ERROR] Diretório do projeto não encontrado: $ProjectPath" -ForegroundColor $ColorError
    exit 1
}

if (-not (Test-SonarQubeAvailable)) {
    Write-Host "[ERROR] SonarQube não está disponível!" -ForegroundColor $ColorError
    Write-Host "[INFO] Execute: .\manage-containers.ps1 -Action Start" -ForegroundColor $ColorWarning
    exit 1
}

Initialize-SonarQubeProject | Out-Null

$token = Get-SonarQubeToken

Start-SonarAnalysis -Token $token

Write-Host ""
Write-Host "[INFO] Script finalizado." -ForegroundColor $ColorInfo
Write-Host ""

# Script para executar analise do SonarQube no codigo do Juice Shop
# Versao: 1.0 - Encoding: UTF-8 sem BOM

<#
.SYNOPSIS
    Script para executar analise do SonarQube no codigo do Juice Shop

.DESCRIPTION
    Este script automatiza a execucao da analise de codigo estatico do
    OWASP Juice Shop usando SonarQube Scanner em container Docker.

.EXAMPLE
    .\run-sonarqube-analysis.ps1

.NOTES
    Pre-requisitos:
    - SonarQube deve estar rodando (use .\manage-containers.ps1 -Action Start)
    - Docker Desktop deve estar em execucao
#>

[CmdletBinding()]
param()

# Cores para output
$ColorSuccess = 'Green'
$ColorError = 'Red'
$ColorWarning = 'Yellow'
$ColorInfo = 'Cyan'

# Configuracoes
$SonarQubeUrl = "http://localhost:9000"
$SonarQubeUser = "admin"
$SonarQubePass = "admin"
$ProjectKey = "juice-shop"
$ProjectPath = ".\juice-shop"

# Funcao para exibir banner
function Show-Banner {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $ColorInfo
    Write-Host "   Analise de Codigo com SonarQube                          " -ForegroundColor $ColorInfo
    Write-Host "   OWASP Juice Shop                                         " -ForegroundColor $ColorInfo
    Write-Host "============================================================" -ForegroundColor $ColorInfo
    Write-Host ""
}

# Funcao para verificar se SonarQube esta disponivel
function Test-SonarQubeAvailable {
    param([int]$MaxAttempts = 30)
    
    Write-Host "INFO: Verificando disponibilidade do SonarQube..." -ForegroundColor $ColorInfo
    
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "$SonarQubeUrl/api/system/status" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            $status = ($response.Content | ConvertFrom-Json).status
            
            if ($status -eq 'UP') {
                Write-Host "SUCCESS: SonarQube esta disponivel!" -ForegroundColor $ColorSuccess
                return $true
            }
        }
        catch {
            Write-Host "WAIT: Aguardando SonarQube iniciar... (tentativa $i/$MaxAttempts)" -ForegroundColor $ColorWarning
            Start-Sleep -Seconds 10
        }
    }
    
    return $false
}

# Funcao para criar projeto no SonarQube (se nao existir)
function Initialize-SonarQubeProject {
    Write-Host "INFO: Verificando projeto no SonarQube..." -ForegroundColor $ColorInfo
    
    try {
        # Codificar credenciais em Base64 para autenticacao basica
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($SonarQubeUser):$($SonarQubePass)"))
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }
        
        # Verificar se projeto existe
        $projectUrl = "$SonarQubeUrl/api/projects/search?projects=$ProjectKey"
        $response = Invoke-RestMethod -Uri $projectUrl -Headers $headers -Method Get -ErrorAction Stop
        
        if ($response.components.Count -eq 0) {
            Write-Host "INFO: Criando projeto no SonarQube..." -ForegroundColor $ColorInfo
            
            # Criar projeto
            $createUrl = "$SonarQubeUrl/api/projects/create?project=$ProjectKey&name=OWASP%20Juice%20Shop"
            Invoke-RestMethod -Uri $createUrl -Headers $headers -Method Post -ErrorAction Stop | Out-Null
            
            Write-Host "SUCCESS: Projeto criado com sucesso!" -ForegroundColor $ColorSuccess
        }
        else {
            Write-Host "INFO: Projeto ja existe no SonarQube." -ForegroundColor $ColorInfo
        }
        
        return $true
    }
    catch {
        Write-Host "WARNING: Nao foi possivel verificar/criar projeto automaticamente." -ForegroundColor $ColorWarning
        Write-Host "INFO: O projeto sera criado automaticamente na primeira analise." -ForegroundColor $ColorInfo
        return $true
    }
}

# Funcao para gerar token de acesso
function Get-SonarQubeToken {
    Write-Host "INFO: Gerando token de autenticacao..." -ForegroundColor $ColorInfo
    
    try {
        # Codificar credenciais em Base64
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($SonarQubeUser):$($SonarQubePass)"))
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }
        
        # Nome unico para o token
        $tokenName = "juice-shop-analysis-$(Get-Date -Format 'yyyyMMddHHmmss')"
        
        # Gerar token (API antiga para compatibilidade)
        $tokenUrl = "$SonarQubeUrl/api/user_tokens/generate?name=$tokenName"
        $response = Invoke-RestMethod -Uri $tokenUrl -Headers $headers -Method Post -ErrorAction Stop
        
        Write-Host "SUCCESS: Token gerado com sucesso!" -ForegroundColor $ColorSuccess
        return $response.token
    }
    catch {
        Write-Host "WARNING: Nao foi possivel gerar token. Tentando analise sem autenticacao..." -ForegroundColor $ColorWarning
        return $null
    }
}

# Funcao para executar analise com SonarScanner
function Start-SonarAnalysis {
    Write-Host "INFO: Iniciando analise de codigo..." -ForegroundColor $ColorInfo
    Write-Host ""
    
    # Caminho absoluto do projeto
    $absolutePath = (Resolve-Path $ProjectPath).Path
    
    Write-Host "INFO: Executando analise com SonarScanner (modo local sem autenticacao)..." -ForegroundColor $ColorInfo
    Write-Host ""
    
    # Preparar argumentos do Docker - SEM autenticacao para ambiente local
    $dockerArgs = @(
        'run'
        '--rm'
        '--network', 'sast-cognitive-load-test-security_security-analysis'
        '-v', "${absolutePath}:/usr/src"
        'sonarsource/sonar-scanner-cli'
        "-Dsonar.projectKey=$ProjectKey"
        '-Dsonar.sources=.'
        '-Dsonar.host.url=http://sonarqube:9000'
        '-Dsonar.scm.disabled=true'
        '-Dsonar.exclusions=**/node_modules/**,**/dist/**,**/build/**,**/coverage/**,**/test/**,**/tests/**,**/*.spec.ts,**/*.spec.js,**/*.test.ts,**/*.test.js'
        '-Dsonar.sourceEncoding=UTF-8'
    )
    
    # Executar SonarScanner em container Docker
    & docker $dockerArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "SUCCESS: Analise concluida com sucesso!" -ForegroundColor $ColorSuccess
        Write-Host ""
        Write-Host "Acesse os resultados em:" -ForegroundColor $ColorInfo
        Write-Host "  $SonarQubeUrl/dashboard?id=$ProjectKey" -ForegroundColor $ColorSuccess
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "ERROR: Falha na execucao da analise!" -ForegroundColor $ColorError
        Write-Host "INFO: Verifique se o SonarQube esta rodando e acessivel." -ForegroundColor $ColorWarning
        exit 1
    }
}

# Main
Show-Banner

# Verificar se Docker esta rodando
try {
    docker ps | Out-Null
}
catch {
    Write-Host "ERROR: Docker nao esta em execucao!" -ForegroundColor $ColorError
    Write-Host "INFO: Inicie o Docker Desktop e tente novamente." -ForegroundColor $ColorWarning
    exit 1
}

# Verificar se diretorio do projeto existe
if (-not (Test-Path $ProjectPath)) {
    Write-Host "ERROR: Diretorio do projeto nao encontrado: $ProjectPath" -ForegroundColor $ColorError
    exit 1
}

# Obter caminho absoluto do projeto
$absolutePath = (Resolve-Path $ProjectPath).Path

# Definir exclusoes para analise
$exclusions = @(
    '**/node_modules/**',
    '**/dist/**',
    '**/build/**',
    '**/coverage/**',
    '**/*.spec.ts',
    '**/*.spec.js',
    '**/test/**',
    '**/*.test.ts',
    '**/*.test.js'
)

# Verificar se SonarQube esta disponivel
if (-not (Test-SonarQubeAvailable)) {
    Write-Host "ERROR: SonarQube nao esta disponivel!" -ForegroundColor $ColorError
    Write-Host "INFO: Execute: .\manage-containers.ps1 -Action Start" -ForegroundColor $ColorWarning
    exit 1
}

# Inicializar projeto no SonarQube (automatico com credenciais padrao)
Initialize-SonarQubeProject | Out-Null

# Gerar token de autenticacao (automatico com credenciais padrao)
$token = Get-SonarQubeToken

# Executar analise
if ($null -ne $token) {
    Write-Host "INFO: Executando analise com autenticacao..." -ForegroundColor $ColorInfo
    
    # Docker args com token
    $dockerArgs = @(
        'run', '--rm'
        '--network', 'sast-cognitive-load-test-security_security-analysis'
        '-v', "${absolutePath}:/usr/src"
        'sonarsource/sonar-scanner-cli'
        "-Dsonar.projectKey=$ProjectKey"
        '-Dsonar.sources=.'
        '-Dsonar.host.url=http://sonarqube:9000'
        "-Dsonar.token=$token"
        '-Dsonar.scm.disabled=true'
        "-Dsonar.exclusions=$($exclusions -join ',')"
        '-Dsonar.sourceEncoding=UTF-8'
    )
    
    try {
        & docker $dockerArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "SUCCESS: Analise concluida com sucesso!" -ForegroundColor $ColorSuccess
            Write-Host ""
            Write-Host "INFO: Acesse o resultado em:" -ForegroundColor $ColorInfo
            Write-Host "      $SonarQubeUrl/dashboard?id=$ProjectKey" -ForegroundColor $ColorInfo
            Write-Host ""
        }
        else {
            Write-Host ""
            Write-Host "ERROR: Falha na execucao da analise!" -ForegroundColor $ColorError
            Write-Host "INFO: Verifique se o SonarQube esta rodando e acessivel." -ForegroundColor $ColorWarning
            Write-Host ""
            exit 1
        }
    }
    catch {
        Write-Host ""
        Write-Host "ERROR: Erro ao executar comando docker!" -ForegroundColor $ColorError
        Write-Host "INFO: $_" -ForegroundColor $ColorWarning
        Write-Host ""
        exit 1
    }
}
else {
    Write-Host "ERROR: Nao foi possivel autenticar no SonarQube" -ForegroundColor $ColorError
    Write-Host "INFO: Verifique as credenciais (padrao admin/admin)" -ForegroundColor $ColorWarning
    exit 1
}

Write-Host ""
Write-Host "INFO: Script finalizado." -ForegroundColor $ColorInfo
Write-Host ""

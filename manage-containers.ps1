<#
.SYNOPSIS
    Script de automação para gerenciar containers do Juice Shop e SonarQube

.DESCRIPTION
    Este script automatiza o gerenciamento dos containers Docker do ambiente
    de análise de segurança (OWASP Juice Shop + SonarQube).

.PARAMETER Action
    Ação a ser executada: Start, Stop, Restart, Status, Logs, Down

.EXAMPLE
    .\manage-containers.ps1 -Action Start
    .\manage-containers.ps1 -Action Status
    .\manage-containers.ps1 -Action Logs -Service juice-shop

.NOTES
    Autor: Agente de Automação
    Requer: Docker Desktop instalado e em execução
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Start', 'Stop', 'Restart', 'Status', 'Logs', 'Down', 'Help')]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [ValidateSet('juice-shop', 'sonarqube', 'sonarqube-db', 'all')]
    [string]$Service = 'all'
)

# Cores para output
$ColorSuccess = 'Green'
$ColorError = 'Red'
$ColorWarning = 'Yellow'
$ColorInfo = 'Cyan'

function Test-DockerRunning {
    try {
        $null = docker ps 2>&1
        return $true
    }
    catch {
        return $false
    }
}

function Show-Banner {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor $ColorInfo
    Write-Host "║   Gerenciador de Containers - Security Analysis  ║" -ForegroundColor $ColorInfo
    Write-Host "║   Juice Shop + SonarQube                          ║" -ForegroundColor $ColorInfo
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor $ColorInfo
    Write-Host ""
}

function Start-Environment {
    Write-Host "[INFO] Iniciando containers..." -ForegroundColor $ColorInfo
    
    if ($Service -eq 'all') {
        docker-compose up -d
    }
    else {
        docker-compose up -d $Service
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Containers iniciados com sucesso!" -ForegroundColor $ColorSuccess
        Write-Host ""
        Write-Host "Aguarde alguns instantes para os serviços ficarem prontos..." -ForegroundColor $ColorWarning
        Write-Host ""
        Write-Host "Acesse:" -ForegroundColor $ColorInfo
        Write-Host "  Juice Shop:  http://localhost:3000" -ForegroundColor $ColorSuccess
        Write-Host "  SonarQube:   http://localhost:9000" -ForegroundColor $ColorSuccess
        Write-Host "               (Credenciais padrão: admin/admin)" -ForegroundColor $ColorWarning
        Write-Host ""
    }
    else {
        Write-Host "[ERROR] Falha ao iniciar containers!" -ForegroundColor $ColorError
    }
}

function Stop-Environment {
    Write-Host "[INFO] Parando containers..." -ForegroundColor $ColorInfo
    
    if ($Service -eq 'all') {
        docker-compose stop
    }
    else {
        docker-compose stop $Service
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Containers parados com sucesso!" -ForegroundColor $ColorSuccess
    }
    else {
        Write-Host "[ERROR] Falha ao parar containers!" -ForegroundColor $ColorError
    }
}

function Remove-Environment {
    Write-Host "[WARNING] Esta ação irá remover todos os containers e VOLUMES!" -ForegroundColor $ColorWarning
    $confirm = Read-Host "Deseja continuar? (S/N)"
    
    if ($confirm -eq 'S' -or $confirm -eq 's') {
        Write-Host "[INFO] Removendo containers e volumes..." -ForegroundColor $ColorInfo
        docker-compose down -v
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Ambiente removido com sucesso!" -ForegroundColor $ColorSuccess
        }
        else {
            Write-Host "[ERROR] Falha ao remover ambiente!" -ForegroundColor $ColorError
        }
    }
    else {
        Write-Host "[INFO] Operação cancelada." -ForegroundColor $ColorInfo
    }
}

function Restart-Environment {
    Write-Host "[INFO] Reiniciando containers..." -ForegroundColor $ColorInfo
    
    if ($Service -eq 'all') {
        docker-compose restart
    }
    else {
        docker-compose restart $Service
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Containers reiniciados com sucesso!" -ForegroundColor $ColorSuccess
    }
    else {
        Write-Host "[ERROR] Falha ao reiniciar containers!" -ForegroundColor $ColorError
    }
}

function Show-Status {
    Write-Host "[INFO] Status dos containers:" -ForegroundColor $ColorInfo
    Write-Host ""
    
    docker-compose ps
    
    Write-Host ""
    Write-Host "[INFO] Uso de recursos:" -ForegroundColor $ColorInfo
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $(docker-compose ps -q)
}

function Show-Logs {
    if ($Service -eq 'all') {
        Write-Host "[INFO] Exibindo logs de todos os serviços..." -ForegroundColor $ColorInfo
        docker-compose logs --tail=50 -f
    }
    else {
        Write-Host "[INFO] Exibindo logs do serviço: $Service" -ForegroundColor $ColorInfo
        docker-compose logs --tail=50 -f $Service
    }
}

function Show-Help {
    Write-Host "USO:" -ForegroundColor $ColorInfo
    Write-Host "  .\manage-containers.ps1 -Action <ação> [-Service <serviço>]" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "AÇÕES DISPONÍVEIS:" -ForegroundColor $ColorInfo
    Write-Host "  Start    - Iniciar containers" -ForegroundColor $ColorSuccess
    Write-Host "  Stop     - Parar containers" -ForegroundColor $ColorSuccess
    Write-Host "  Restart  - Reiniciar containers" -ForegroundColor $ColorSuccess
    Write-Host "  Status   - Exibir status e uso de recursos" -ForegroundColor $ColorSuccess
    Write-Host "  Logs     - Exibir logs dos containers" -ForegroundColor $ColorSuccess
    Write-Host "  Down     - Parar e remover containers e volumes" -ForegroundColor $ColorSuccess
    Write-Host "  Help     - Exibir esta ajuda" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "SERVIÇOS DISPONÍVEIS:" -ForegroundColor $ColorInfo
    Write-Host "  all            - Todos os serviços (padrão)" -ForegroundColor $ColorSuccess
    Write-Host "  juice-shop     - Apenas Juice Shop" -ForegroundColor $ColorSuccess
    Write-Host "  sonarqube      - Apenas SonarQube" -ForegroundColor $ColorSuccess
    Write-Host "  sonarqube-db   - Apenas PostgreSQL" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "EXEMPLOS:" -ForegroundColor $ColorInfo
    Write-Host "  .\manage-containers.ps1 -Action Start" -ForegroundColor $ColorWarning
    Write-Host "  .\manage-containers.ps1 -Action Stop -Service juice-shop" -ForegroundColor $ColorWarning
    Write-Host "  .\manage-containers.ps1 -Action Logs -Service sonarqube" -ForegroundColor $ColorWarning
    Write-Host "  .\manage-containers.ps1 -Action Status" -ForegroundColor $ColorWarning
    Write-Host ""
}

Show-Banner

if (-not (Test-DockerRunning)) {
    Write-Host "[ERROR] Docker não está em execução!" -ForegroundColor $ColorError
    Write-Host "[INFO] Inicie o Docker Desktop e tente novamente." -ForegroundColor $ColorWarning
    exit 1
}

switch ($Action) {
    'Start'   { Start-Environment }
    'Stop'    { Stop-Environment }
    'Restart' { Restart-Environment }
    'Status'  { Show-Status }
    'Logs'    { Show-Logs }
    'Down'    { Remove-Environment }
    'Help'    { Show-Help }
}

Write-Host ""

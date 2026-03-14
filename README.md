# SAST Cognitive Load Test Security

Ambiente automatizado para análise de segurança com OWASP Juice Shop e SonarQube.

## 📋 Pré-requisitos

- Docker Desktop instalado e em execução
- PowerShell 5.1 ou superior
- Git (opcional - usado para clonagem automática)
- 4GB RAM disponível (mínimo)
- 10GB de espaço em disco

## 🚀 Início Rápido

### 1. Iniciar Ambiente

```powershell
.\manage-containers.ps1 -Action Start
```

Este comando irá:
- Iniciar PostgreSQL (banco de dados do SonarQube)
- Iniciar SonarQube (porta 9000)
- Iniciar Juice Shop (porta 3000)

Aguarde 1-2 minutos para os serviços ficarem completamente disponíveis.

### 2. Executar Análise de Código

```powershell
.\run-sonarqube-analysis.ps1
```

Este comando irá:
- **Clonar automaticamente** o código do Juice Shop (se não existir)
- Criar arquivo `sonar-project.properties` automaticamente
- Verificar disponibilidade do SonarQube
- Criar projeto no SonarQube automaticamente
- Gerar token de autenticação automaticamente
- Executar análise de código estático
- Exibir link para visualizar resultados

**✨ Totalmente automático!** Não requer configuração manual.

## 📖 Comandos Disponíveis

### Gerenciamento de Containers

```powershell
# Iniciar todos os containers
.\manage-containers.ps1 -Action Start

# Parar todos os containers
.\manage-containers.ps1 -Action Stop

# Reiniciar containers
.\manage-containers.ps1 -Action Restart

# Ver status e uso de recursos
.\manage-containers.ps1 -Action Status

# Ver logs em tempo real
.\manage-containers.ps1 -Action Logs

# Ver logs de um serviço específico
.\manage-containers.ps1 -Action Logs -Service juice-shop

# Remover containers e DADOS (cuidado!)
.\manage-containers.ps1 -Action Down

# Ajuda
.\manage-containers.ps1 -Action Help
```

### Serviços Disponíveis

- `all` - Todos os serviços (padrão)
- `juice-shop` - Aplicação vulnerável para testes
- `sonarqube` - Plataforma de análise de código
- `sonarqube-db` - Banco de dados PostgreSQL

## 🔧 Arquitetura

```
┌─────────────────────────────────────────────────┐
│  Docker Network: security-analysis              │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Juice Shop   │  │  SonarQube   │            │
│  │ Port: 3000   │  │  Port: 9000  │            │
│  └──────────────┘  └──────┬───────┘            │
│                            │                     │
│                     ┌──────▼───────┐            │
│                     │  PostgreSQL  │            │
│                     │  Port: 5432  │            │
│                     └──────────────┘            │
└─────────────────────────────────────────────────┘
```

## 📦 Volumes Persistentes

Os seguintes volumes são criados para persistir dados:

- `sonarqube-db-data` - Dados do PostgreSQL
- `sonarqube-data` - Dados do SonarQube
- `sonarqube-logs` - Logs do SonarQube
- `sonarqube-extensions` - Plugins do SonarQube

**⚠️ Importante:** O comando `-Action Down` remove esses volumes permanentemente!

## 🌐 URLs de Acesso

### Juice Shop
- URL: http://localhost:3000
- Aplicação vulnerável para testes de segurança

### SonarQube
- URL: http://localhost:9000
- Credenciais padrão: `admin` / `admin`
- Dashboard do projeto: http://localhost:9000/dashboard?id=juice-shop

## 🔍 Análise de Código

O script `run-sonarqube-analysis.ps1` realiza:

### Automação Completa
1. **Clone automático** do repositório Juice Shop (se não existir)
2. **Criação automática** do arquivo de configuração SonarQube
3. **Verificação de disponibilidade** dos serviços
4. **Criação automática do projeto** no SonarQube
5. **Geração automática de token** de autenticação
6. **Execução da análise** usando SonarScanner em container

### Exclusões da Análise
- `**/node_modules/**` - Dependências
- `**/dist/**` - Código compilado
- `**/build/**` - Build artifacts
- `**/coverage/**` - Relatórios de cobertura
- `**/*.spec.ts`, `**/*.spec.js` - Arquivos de teste
- `**/test/**` - Diretórios de teste

## 🛠️ Solução de Problemas

### Docker não está rodando
```
ERROR: Docker nao esta em execucao!
```
**Solução:** Inicie o Docker Desktop e aguarde inicialização completa.

### SonarQube não disponível
```
ERROR: SonarQube nao esta disponivel!
```
**Solução:** Aguarde 1-2 minutos após iniciar containers. SonarQube leva tempo para inicializar.

### Erro de encoding em Windows 11
Os scripts foram criados com **UTF-8 sem BOM** e **apenas caracteres ASCII** para compatibilidade total com Windows 11.

Veja [ENCODING-FIX.md](ENCODING-FIX.md) para detalhes técnicos.

### Containers não param
```powershell
# Force stop
docker-compose down --remove-orphans

# Limpar sistema Docker completamente
docker system prune -a --volumes -f
```

### Erro de cache do Docker
```
ERROR: failed to copy xattrs: blob not found
```
**Solução:**
```powershell
.\manage-containers.ps1 -Action Down
docker system prune -a --volumes -f
.\manage-containers.ps1 -Action Start
```

## 📁 Estrutura do Projeto

```
SAST-COGNITIVE-LOAD-TEST-SECURITY/
├── docker-compose.yml              # Orquestração de containers
├── manage-containers.ps1           # Script de gerenciamento
├── run-sonarqube-analysis.ps1      # Script de análise
├── juice-shop/                     # Código fonte (clonado automaticamente)
│   └── sonar-project.properties    # Criado automaticamente
├── README.md                       # Este arquivo
└── ENCODING-FIX.md                 # Documentação de encoding
```

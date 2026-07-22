# BMDesk Windows Build — Opções

## Pré-requisitos

- Docker Desktop for Windows com modo **Windows containers** ativado
  (bandeja do Docker > `Switch to Windows containers...`)
- Mínimo **60 GB** livres (imagem ~25 GB + vcpkg + build)

## Primeiro build da imagem (só uma vez)

```powershell
docker compose -f docker-compose.windows.yml build
```

Demora ~40-60 min. A imagem fica em cache como `bmdesk-windows:latest`.

---

## Opções do entrypoint (`entrypoint.windows.ps1`)

| Parâmetro | Valores | Padrão | Descrição |
|---|---|---|---|
| `-Arch` | `x86_64`, `i686` | `x86_64` | Arquitetura do binário |
| `-ConnType` | `incoming`, `outgoing`, `""` | `""` | Modo do custom client: só recebe conexão, só origina, ou ambos |
| `-Mode` | `release`, `debug` | `release` | Perfil de compilação |
| `-SkipPortablePack` | switch | off | Pula o empacotador portable, só gera a pasta `Release/` |
| `-SkipVcpkg` | switch | off | Pula instalação de dependências vcpkg (use se já estão pré-compiladas) |
| `-SkipBridge` | switch | off | Pula geração do flutter-rust-bridge (use se bridge já foi gerada) |

---

## Exemplos

### Via `docker compose`

```powershell
# Padrão: x86_64, release, cliente completo
docker compose -f docker-compose.windows.yml run --rm bmdesk-windows-build

# Cliente "só recebe conexão" (modo incoming)
docker compose -f docker-compose.windows.yml run --rm bmdesk-windows-build -ConnType incoming

# Cliente "só origina conexão" (modo outgoing)
docker compose -f docker-compose.windows.yml run --rm bmdesk-windows-build -ConnType outgoing

# 32-bit (legacy)
docker compose -f docker-compose.windows.yml run --rm bmdesk-windows-build -Arch i686

# Debug + skip pack
docker compose -f docker-compose.windows.yml run --rm bmdesk-windows-build -Mode debug -SkipPortablePack

# Shell interativa dentro do container
docker compose -f docker-compose.windows.yml run --rm bmdesk-windows-build powershell
```

### Via script auxiliar

```powershell
.\docker-build.ps1 windows -Docker
.\docker-build.ps1 windows -Docker -ConnType incoming
```

---

## Output

Após build bem-sucedido, o instalador aparece na raiz do projeto:

```
bmdesk-1.4.10-install.exe
```

Ou, com `-SkipPortablePack`:

```
flutter\build\windows\x64\runner\Release\
```

---

## Toolchain incluído na imagem

| Ferramenta | Versão |
|---|---|
| Windows Server Core | ltsc2022 |
| VS 2022 Build Tools | 17.x (MSVC v143, Win 11 SDK 22621) |
| LLVM / Clang | 15.0.6 |
| Rust | 1.75.0 (x86_64-pc-windows-msvc + i686) |
| Flutter | 3.44.1 |
| Python | 3.11.9 |
| CMake | 3.30.6 |
| Ninja | 1.12.1 |
| NASM | 2.16.03 |
| vcpkg | 2024.12.16 |
| Git | 2.47.1 |

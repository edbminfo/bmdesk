# Guia do Servidor de Atualização BMDesk

Este documento descreve exatamente como configurar um servidor de atualizações compatível com o BMDesk.

---

## 1. URLs e Endpoints

### 1.1 Verificação de Versão (Version Check)

O BMDesk faz requisições para o **endpoint padrão**:

```
GET https://bmdesk-down.bmhelp.click/releases/latest
```

Se você alterar o `APP_NAME` em `libs/hbb_common/src/config.rs`, a URL base também muda:
- `RustDesk` → `https://api.rustdesk.com/version/latest` (usa POST com JSON)
- Qualquer outro nome → `https://{appname}-down.bmhelp.click/releases/latest`

> **Importante:** Para clientes customizados (não-RustDesk), a requisição é um **GET simples**, sem corpo JSON.

### 1.2 URL de Download

A URL de download é derivada automaticamente da URL de release:

```
URL da release:  .../releases/tag/1.5.0
URL de download: .../releases/download/1.5.0/<arquivo>
```

Ou seja, o cliente substitui `tag` por `download` e acrescenta o nome do arquivo.

---

## 2. Formato da Resposta do `/releases/latest`

O endpoint deve retornar um JSON contendo **obrigatoriamente** o campo `url` ou `html_url`, apontando para a página da release.

### Exemplo de resposta válida:

```json
{
  "url": "https://github.com/edbminfo/bmdesk/releases/tag/1.5.0",
  "html_url": "https://github.com/edbminfo/bmdesk/releases/tag/1.5.0",
  "tag_name": "v1.5.0",
  "name": "v1.5.0",
  "body": "Changelog...",
  "prerelease": false
}
```

### Campos essenciais:

| Campo       | Obrigatório | Descrição                                          |
|-------------|:-----------:|----------------------------------------------------|
| `url`       | **NÃO**     | URL da página de release (API do GitHub ou própria)|
| `html_url`  | **NÃO**     | Fallback caso `url` não exista                     |

> O cliente tenta `url` primeiro, depois `html_url`. Pelo menos **um** deve existir.

### Como o BMDesk detecta que há atualização:

O cliente extrai o **último segmento** da URL (ex: `v1.5.0`), converte para número e compara com a versão atual:

```
url = "https://github.com/edbminfo/bmdesk/releases/tag/1.5.0"
       → extrai "1.5.0"
       → get_version_number("v1.5.0") = 10010500

Se 10010500 > versão_atual → há atualização disponível
```

A função `get_version_number()` converte assim:
```
"1.4.9"   → 1*1000000 + 4*1000*10 + 9*10 = 1.004.090
"1.4.9-1" → 1*1000000 + 4*1000*10 + 9*10 + 1 = 1.004.091
```

---

## 3. Estrutura de Diretórios no Servidor

O servidor deve seguir o padrão GitHub Releases, com as releases organizadas por tag:

```
/releases/
  ├── latest          ← endpoint GET que retorna JSON da última release
  └── download/
      └── 1.5.0/
          ├── bmdesk-1.5.0-x86_64.exe
          ├── bmdesk-1.5.0-x86_64.msi
          └── bmdesk-1.5.0-x86_64.dmg
```

Ou, usando o padrão GitHub:

```
https://github.com/{owner}/{repo}/releases/download/{tag}/{filename}
```

### Resumo das rotas:

| Rota              | Método | Resposta                              |
|-------------------|--------|---------------------------------------|
| `/releases/latest`| GET    | JSON com `url` ou `html_url`          |
| `/releases/download/{tag}/{filename}` | GET | Binário do instalador |

---

## 4. Convenção de Nomes dos Arquivos

Os arquivos de instalação devem seguir EXATAMENTE este padrão:

### Windows

| Tipo       | Nome do arquivo                             |
|------------|---------------------------------------------|
| EXE        | `bmdesk-{versão}-{arch}.exe`               |
| MSI        | `bmdesk-{versão}-{arch}.msi`               |
| Sciter     | `bmdesk-{versão}-x86-sciter.exe`           |

### macOS

| Arquitetura | Nome do arquivo                           |
|-------------|-------------------------------------------|
| x86_64      | `bmdesk-{versão}-x86_64.dmg`             |
| aarch64     | `bmdesk-{versão}-aarch64.dmg`            |

### Exemplos concretos:

```
bmdesk-1.5.0-x86_64.exe
bmdesk-1.5.0-x86_64.msi
bmdesk-1.5.0-x86_64.dmg
bmdesk-1.5.0-aarch64.dmg
```

> **O código gera o nome do arquivo automaticamente** baseado no `APP_NAME`, versão e arquitetura detectada. Se você mudar `APP_NAME` para "MeuApp", os arquivos serão `MeuApp-1.5.0-x86_64.exe`, etc.

---

## 5. Validação de Segurança das URLs

As URLs de download são validadas rigorosamente:

- **Apenas HTTPS** (HTTP é rejeitado)
- **Sem** usuário, senha, porta, query string ou fragmento
- **Hosts permitidos:**
  - `github.com` (repos: `rustdesk/rustdesk` ou `edbminfo/bmdesk`)
  - `bmdesk-down.bmhelp.click`
- **Padrão do caminho (path):** `/{owner}/{repo}/releases/download/{tag}/{filename}`
- **Nomes de arquivo:** sem `/`, `\`, `:`, sem path traversal

Para usar seu próprio domínio, edite:

| Arquivo | Linha | O que alterar |
|---------|-------|--------------|
| `src/common.rs` | 1026 | URL da verificação de versão |
| `src/updater.rs` | ~310-340 | Whitelist de hosts permitidos |

---

## 6. Exemplo de Servidor Mínimo (Nginx)

### Configuração Nginx:

```nginx
server {
    listen 443 ssl;
    server_name bmdesk-down.bmhelp.click;

    ssl_certificate     /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    root /var/www/bmdesk-updates;

    # Endpoint de verificação de versão
    location = /releases/latest {
        default_type application/json;
        # Retorna JSON estático apontando para a release mais recente
        return 200 '{"url":"https://bmdesk-down.bmhelp.click/releases/tag/v1.5.0","html_url":"https://bmdesk-down.bmhelp.click/releases/tag/v1.5.0"}';
    }

    # Arquivos de download
    location /releases/download/ {
        alias /var/www/bmdesk-updates/releases/download/;
    }
}
```

### Estrutura de arquivos no servidor:

```
/var/www/bmdesk-updates/
└── releases/
    ├── latest          → (não é um arquivo real, o nginx retorna inline)
    └── download/
        └── 1.5.0/
            ├── bmdesk-1.5.0-x86_64.exe
            ├── bmdesk-1.5.0-x86_64.msi
            └── bmdesk-1.5.0-x86_64.dmg
```

---

## 7. Exemplo de Servidor com API Dinâmica

### Simples servidor Node.js / Express:

```javascript
const express = require('express');
const app = express();

const LATEST_VERSION = 'v1.5.0';
const BASE_URL = 'https://bmdesk-down.bmhelp.click';

// Endpoint de verificação de versão
app.get('/releases/latest', (req, res) => {
  res.json({
    url: `${BASE_URL}/releases/tag/${LATEST_VERSION}`,
    html_url: `${BASE_URL}/releases/tag/${LATEST_VERSION}`,
    tag_name: LATEST_VERSION,
    name: `BMDesk ${LATEST_VERSION}`,
    prerelease: false,
    published_at: '2026-07-15T00:00:00Z',
    body: '## Changelog\n- Bug fixes\n- New features'
  });
});

// Servir arquivos de download (diretório estático)
app.use('/releases/download', express.static('/data/releases/download'));

app.listen(443);
```

### Simples servidor Python / Flask:

```python
from flask import Flask, jsonify, send_from_directory
import os

app = Flask(__name__)

LATEST_VERSION = 'v1.5.0'
BASE_URL = 'https://bmdesk-down.bmhelp.click'
DOWNLOAD_DIR = '/data/releases/download'

@app.route('/releases/latest')
def latest():
    return jsonify({
        'url': f'{BASE_URL}/releases/tag/{LATEST_VERSION}',
        'html_url': f'{BASE_URL}/releases/tag/{LATEST_VERSION}',
        'tag_name': LATEST_VERSION,
        'name': f'BMDesk {LATEST_VERSION}',
        'prerelease': False,
    })

@app.route('/releases/download/<tag>/<filename>')
def download(tag, filename):
    return send_from_directory(
        os.path.join(DOWNLOAD_DIR, tag),
        filename,
        as_attachment=True
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=443, ssl_context=('cert.pem', 'key.pem'))
```

---

## 8. Checklist de Publicação de uma Nova Release

Antes de publicar uma nova versão, verifique:

- [ ] `src/version.rs` contém o número correto da versão (ex: `"1.5.0"`)
- [ ] Os binários foram compilados para **todas** as plataformas:
  - [ ] `bmdesk-{versão}-x86_64.exe` (Windows 64-bit)
  - [ ] `bmdesk-{versão}-x86_64.msi` (Windows 64-bit MSI)
  - [ ] `bmdesk-{versão}-x86_64.dmg` (macOS Intel)
  - [ ] `bmdesk-{versão}-aarch64.dmg` (macOS Apple Silicon)
- [ ] Os binários foram copiados para `releases/download/{tag}/` no servidor
- [ ] O endpoint `/releases/latest` foi atualizado com a nova tag e o novo número de versão
- [ ] **OPCIONAL:** Testar com um cliente apontando para o servidor

### Exemplo de workflow:

```bash
# 1. Atualizar versão no código
echo 'pub const VERSION: &str = "1.5.0";' > src/version.rs

# 2. Build
cargo build --release

# 3. Nomear binários
VERSION="1.5.0"
cp target/release/bmdesk.exe releases/download/v${VERSION}/bmdesk-${VERSION}-x86_64.exe
cp target/release/bmdesk.msi releases/download/v${VERSION}/bmdesk-${VERSION}-x86_64.msi

# 4. Upload para o servidor
rsync -av releases/download/ server:/var/www/bmdesk-updates/releases/download/

# 5. Atualizar /releases/latest no servidor
ssh server "echo '{\"url\":\"...tag/v1.5.0\",\"html_url\":\"...tag/v1.5.0\"}' > /tmp/latest.json"
```

---

## 9. Resumo Rápido

```
┌──────────────────────────────────────────────────────────────┐
│  CLIENTE BMDesk                                              │
│                                                              │
│  1. GET /releases/latest  ──────────────────────────────►    │
│                                                              │
│  2. ◄── JSON { "url": ".../tag/v1.5.0" }                    │
│                                                              │
│  3. Compara v1.5.0 > versão atual?                           │
│     SIM → Mostra botão "Atualizar"                           │
│                                                              │
│  4. Usuário clica "Atualizar"                                │
│     url.replace("tag", "download") + "/bmdesk-1.5.0-{arch}"  │
│                                                              │
│  5. GET /releases/download/v1.5.0/bmdesk-1.5.0-x86_64.exe   │
│                                                              │
│  6. ◄── Binário do instalador                                │
│                                                              │
│  7. Instala via UAC (Windows) ou osascript (macOS)           │
└──────────────────────────────────────────────────────────────┘
```

### URLs importantes no código fonte:

| O que | Arquivo | Linha |
|-------|---------|-------|
| URL de verificação de versão | `src/common.rs` | 1026 |
| Extração de `url`/`html_url` do JSON | `src/common.rs` | 989-990 |
| Substituição `tag` → `download` | `src/updater.rs` | 135 |
| Validação de URL de download | `src/updater.rs` | ~310 |
| Nome do arquivo por plataforma | `src/updater.rs` | ~136-156 |
| `APP_NAME` padrão | `libs/hbb_common/src/config.rs` | 72 |

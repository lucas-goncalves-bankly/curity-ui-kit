# Restaurar Core e Fazer Deploy do Multi-Brand Partner Portal

Este runbook descreve como:

1. Restaurar os templates core do Identity Server no ambiente para o padrão Curity.
2. Publicar o tema e templates multi-brand do Partner Portal.

Pressupõe acesso SSH ao servidor de destino.

## Escopo e Objetivo

Use este processo quando arquivos do ambiente foram sobrescritos diretamente em caminhos de core e você precisa:

- Voltar ao comportamento padrão Curity para fluxos não customizados.
- Manter customizações de marca apenas em overrides e template-areas.

## Pré-requisitos

- Acesso SSH ao host de destino.
- Estratégia de backup para `/opt/idsvr/usr/share`.
- Repositório local atualizado e build concluído:

```bash
npm run build:identity-server
```

- Script de deploy remoto disponível neste repositório:
  - [deploy-remote.sh](deploy-remote.sh)

## Cenário Sem Backup (Todos os Ambientes Alterados)

Quando não existe backup e todos os ambientes tiveram alterações no core, o processo recomendado é criar uma fonte única de restauração (golden source) baseada na distribuição oficial limpa da mesma versão do Curity em produção.

Versão informada para este cenário:

- Identity Server 10.4.0
- JVM 21.0.6

Plano recomendado:

1. Baixar/reextrair a distribuição oficial limpa do Curity 10.4.0.
2. Em um host de referência, separar a pasta limpa de templates e messages core.
3. Publicar exatamente o mesmo conteúdo de core em todos os ambientes (dev/hml/prod), sem aproveitar core já alterado de outro ambiente.
4. Após restaurar o core padrão, aplicar somente as customizações em `overrides`, `template-areas` e `webroot/assets`.

Exemplo de comandos (com fonte limpa já disponível no host remoto):

```bash
export HOST=<host-remoto>
export USER=<usuario-remoto>
export SHARE_DIR=/opt/idsvr/usr/share
export CLEAN_DIR=/opt/idsvr-clean-10.4.0/usr/share
export TS=$(date +%Y%m%d_%H%M%S)

ssh "$USER@$HOST" "mv $SHARE_DIR/templates/core $SHARE_DIR/templates/core.pre-restore-$TS || true"
ssh "$USER@$HOST" "mv $SHARE_DIR/messages/core $SHARE_DIR/messages/core.pre-restore-$TS || true"
ssh "$USER@$HOST" "cp -a $CLEAN_DIR/templates/core $SHARE_DIR/templates/"
ssh "$USER@$HOST" "cp -a $CLEAN_DIR/messages/core $SHARE_DIR/messages/"
```

Depois dessa restauração, seguir normalmente para a Fase 4 (publicação do Partner Portal).

## Cenário Aprovado - Usar o Core Deste Repositório

Quando o time decide usar este repositório como baseline limpa (sem customização antiga no core), o processo pode ser padronizado em todos os ambientes.

Fonte de restore:

- `src/identity-server/templates/core`
- `src/identity-server/messages/core` (se aplicável no ambiente)

Boas práticas antes de aplicar:

1. Congelar uma referência única (tag/commit) para todos os ambientes.
2. Aplicar exatamente a mesma referência em dev/hml/prod.
3. Após restore do core, manter customizações somente em `overrides`, `template-areas` e `webroot/assets`.

Exemplo de restore remoto usando o core do repositório local:

```bash
export HOST=<host-remoto>
export USER=<usuario-remoto>
export SHARE_DIR=/opt/idsvr/usr/share
export TS=$(date +%Y%m%d_%H%M%S)

# backup rápido do core atual
ssh "$USER@$HOST" "mv $SHARE_DIR/templates/core $SHARE_DIR/templates/core.pre-restore-$TS || true"
ssh "$USER@$HOST" "mv $SHARE_DIR/messages/core $SHARE_DIR/messages/core.pre-restore-$TS || true"

# restore do core usando este repositório
rsync -av --delete src/identity-server/templates/core/ "$USER@$HOST:$SHARE_DIR/templates/core/"
rsync -av --delete src/identity-server/messages/core/ "$USER@$HOST:$SHARE_DIR/messages/core/" || true
```

Depois dessa restauração, seguir para a Fase 4 (deploy do Partner Portal).

## Estratégia de Pastas (Estado Alvo)

O estado final deve seguir este padrão:

- Padrão Curity: `/opt/idsvr/usr/share/templates/core`
- Customizações globais: `/opt/idsvr/usr/share/templates/overrides`
- Customizações por marca: `/opt/idsvr/usr/share/templates/template-areas/partner-portal`
- Assets: `/opt/idsvr/usr/share/webroot/assets`

Não manter arquivos específicos de marca dentro de `templates/core`.

## Fase 1 - Backup do Ambiente Atual

Execute localmente:

```bash
export HOST=<host-remoto>
export USER=<usuario-remoto>
export SHARE_DIR=/opt/idsvr/usr/share
export TS=$(date +%Y%m%d_%H%M%S)

ssh "$USER@$HOST" "mkdir -p $SHARE_DIR/backup_$TS && cp -a $SHARE_DIR/templates $SHARE_DIR/backup_$TS/ && cp -a $SHARE_DIR/messages $SHARE_DIR/backup_$TS/ && cp -a $SHARE_DIR/webroot/assets $SHARE_DIR/backup_$TS/"
```

## Fase 2 - Restaurar Core Padrão Curity

Você tem duas opções válidas:

1. Recomendado: reinstalar ou reextrair o pacote da mesma versão do Curity e restaurar apenas `templates/core` da distribuição limpa.
2. Se já existir uma cópia limpa da mesma versão em outro servidor/repositório de artefatos, copiar `templates/core` dessa fonte para o ambiente.

Exemplo (substituir `<clean-core-source>` pelo caminho limpo no host remoto):

```bash
ssh "$USER@$HOST" "rm -rf $SHARE_DIR/templates/core && cp -a <clean-core-source>/templates/core $SHARE_DIR/templates/"
```

Após esta fase, o core deve estar novamente no padrão Curity.

## Fase 3 - Remover Customizações Legadas em Caminho Incorreto

Se arquivos customizados antigos foram colocados em caminhos de core, remova-os antes de aplicar o novo modelo.

Exemplo de verificação:

```bash
ssh "$USER@$HOST" "find $SHARE_DIR/templates/core -type f | grep -E 'partner-portal|bankly|custom' || true"
```

Se aparecerem resultados, remover ou substituir por arquivos padrão de core.

### Exemplo de Estrutura de Pastas (TOTP no Core)

Use esta estrutura como referência ao validar os arquivos de TOTP no ambiente:

```text
/opt/idsvr/usr/share/templates/core/authenticator/
├── totp
│   ├── authenticate
│   │   ├── enter-totp.vm
│   │   └── index.vm
│   ├── confirm
│   │   └── success.vm
│   ├── register
│   │   └── index.vm
│   └── set-alias
│       └── index.vm
```

## Fase 4 - Publicar o Multi-Brand Partner Portal

Use o script do repositório para sincronizar os artefatos buildados com o ambiente remoto:

```bash
npm run deploy:remote -- --host "$HOST" --user "$USER" --remote-share-dir "$SHARE_DIR"
```

Flags opcionais:

- Simulação (sem alterar):

```bash
npm run deploy:remote -- --host "$HOST" --user "$USER" --remote-share-dir "$SHARE_DIR" --dry-run
```

- Remover arquivos remotos inexistentes localmente nas pastas sincronizadas:

```bash
npm run deploy:remote -- --host "$HOST" --user "$USER" --remote-share-dir "$SHARE_DIR" --delete
```

## Fase 5 - Validar Arquivos no Ambiente

Execute os comandos:

```bash
ssh "$USER@$HOST" "ls -la $SHARE_DIR/templates/template-areas/partner-portal"
ssh "$USER@$HOST" "ls -la $SHARE_DIR/templates/overrides/authenticator/html-form/authenticate/get.vm"
ssh "$USER@$HOST" "ls -la $SHARE_DIR/templates/overrides/authenticator/totp"
ssh "$USER@$HOST" "ls -la $SHARE_DIR/webroot/assets/css/partner-portal-theme.css"
ssh "$USER@$HOST" "ls -la $SHARE_DIR/webroot/assets/images/logo_bankly_preto.svg"
```

## Fase 6 - Reiniciar Curity e Validar Funcionalmente

Reinicie o serviço (exemplo):

```bash
ssh "$USER@$HOST" "sudo systemctl restart idsvr"
```

Checklist de validação:

- Cliente sem template area usa telas padrão Curity.
- Cliente com template area `partner-portal` usa o tema da marca.
- Páginas TOTP e html-form seguem o layout customizado em overrides.
- E-mail de verificação renderiza a logo esperada para partner-portal.

## Rollback

Se necessário, restaure o backup criado na Fase 1:

```bash
ssh "$USER@$HOST" "cp -a $SHARE_DIR/backup_$TS/templates $SHARE_DIR/ && cp -a $SHARE_DIR/backup_$TS/messages $SHARE_DIR/ && cp -a $SHARE_DIR/backup_$TS/assets $SHARE_DIR/webroot/"
```

Depois, reinicie o Curity.

## Observações

- Se a política do servidor permitir somente SFTP, suba as mesmas pastas preservando a estrutura.
- O arquivo de tema atualmente gerado por este repositório é:
  - `partner-portal-theme.css`


# Runbook Manual (SFTP/FTP) - Restore Padrão Curity + Theme Partner Portal

Este documento descreve o processo manual de publicação no servidor (sem script), para:

1. Restaurar o padrão Curity no ambiente.
2. Aplicar novamente o theme Partner Portal (multi-brand).

## Quando usar este processo

Use este procedimento quando o deploy é feito manualmente via SFTP/FTP e houve sobrescrita de arquivos no ambiente.

## Pré-requisitos

- Acesso ao servidor (SSH/SFTP/FTP).
- Backup do ambiente atual.
- Build local atualizado.

Comando local antes de iniciar:

```bash
npm run build:identity-server
```

## 1) Backup no servidor (obrigatório)

Faça backup destas pastas antes de qualquer alteração:

- `/opt/idsvr/usr/share/templates`
- `/opt/idsvr/usr/share/messages`
- `/opt/idsvr/usr/share/webroot/assets`

## 2) Restaurar padrão Curity no ambiente

Se o core foi sobrescrito com customizações, restaure os arquivos padrão da mesma versão do Curity.

Pastas sensíveis para restore:

- `/opt/idsvr/usr/share/templates/core`
- `/opt/idsvr/usr/share/messages/core`

Objetivo desta etapa:

- Fluxos sem branding voltam ao comportamento padrão Curity.

## 3) Aplicar arquivos do Partner Portal (manual)

### 3.1 CSS

Adicionar arquivo de tema na pasta de CSS:

- `/opt/idsvr/usr/share/webroot/assets/css/custom-bankly-theme.css`

Observação: no build local, o tema pode sair como `partner-portal-theme.css`. Se necessário, renomear para `custom-bankly-theme.css` antes de subir.

### 3.2 Imagem

Adicionar logo na pasta de imagens:

- `/opt/idsvr/usr/share/webroot/assets/images/logo_bankly_preto.svg`

### 3.3 Settings

Adicionar settings custom:

- `/opt/idsvr/usr/share/templates/overrides/settings.vm`

## 4) Sobrescrever telas custom (modelo manual solicitado)

### 4.1 TOTP

Sobrescrever os arquivos abaixo:

- `/opt/idsvr/usr/share/templates/core/authenticator/totp/authenticate/enter-totp.vm`
- `/opt/idsvr/usr/share/templates/core/authenticator/totp/authenticate/index.vm`
- `/opt/idsvr/usr/share/templates/core/authenticator/totp/confirm/success.vm`
- `/opt/idsvr/usr/share/templates/core/authenticator/totp/register/index.vm`
- `/opt/idsvr/usr/share/templates/core/authenticator/totp/set-alias/index.vm`

### 4.2 Reset Password

Sobrescrever o arquivo abaixo:

- `/opt/idsvr/usr/share/templates/core/authenticator-action/rest-password/index.vm`

Observação: em instalações Curity, o caminho mais comum é `reset-password`. Validar a estrutura existente antes de sobrescrever.

### 4.3 HTML Form Authenticate

Sobrescrever o arquivo abaixo:

- `/opt/idsvr/usr/share/templates/core/authenticator/html-form/authenticate/get.vm`

## 5) Reiniciar serviço

Após upload dos arquivos, reiniciar o serviço do Curity Identity Server.

Exemplo (ajustar conforme ambiente):

```bash
sudo systemctl restart idsvr
```

## 6) Checklist de validação

- Tela de login abre sem erro.
- CSS e logo da marca carregam corretamente.
- Fluxos de TOTP renderizam layout customizado.
- Fluxo de reset password renderiza template esperado.
- Fluxo de html-form authenticate renderiza template esperado.

## 7) Rollback manual

Se houver problema, restaurar os backups das pastas:

- `/opt/idsvr/usr/share/templates`
- `/opt/idsvr/usr/share/messages`
- `/opt/idsvr/usr/share/webroot/assets`

Depois, reiniciar o serviço.

## Observação importante

Este documento segue o modelo manual solicitado (sobrescrita em `templates/core`).

Como boa prática de longo prazo para multi-brand, prefira:

- `templates/overrides` para custom global.
- `templates/template-areas/partner-portal` para branding por cliente.

Isso reduz risco em upgrades e facilita manutenção.

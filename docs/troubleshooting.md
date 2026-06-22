# Troubleshooting

## Waydroid não encontrado

Instale:

```bash
curl https://repo.waydro.id | sudo bash
sudo apt install waydroid
```

## `waydroid shell` exige root

Algumas instalações retornam `This action needs root access` para comandos de
shell Android. O wdroid usa `sudo -n waydroid shell` como fallback, sem pedir
senha interativa. Se o comando continuar falhando, valide manualmente:

```bash
sudo waydroid shell pm list packages
```

## Play Store sem certificação

Use:

```bash
wdroid playstore status
wdroid playstore certify --open
```

Depois de registrar o Android ID, reinicie a sessão:

```bash
wdroid restart
```

## Xiaomi Cloud não abre como app

O Xiaomi Cloud depende de componentes proprietários da Xiaomi e pode não existir
na imagem Android usada pelo Waydroid. Instale APKs locais fornecidos por você:

```bash
wdroid micloud install XiaomiAccount.apk XiaomiCloud.apk
```

Se o APK exigir privilégios de sistema:

```bash
wdroid micloud install-system XiaomiCloud.apk
```

Em arquiteturas incompatíveis, use o acesso web:

```bash
wdroid micloud web
```

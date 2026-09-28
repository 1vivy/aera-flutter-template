# webui/

The KernelSU / APatch / Magisk module around the web build. `surfaces build
webui` fills `@ID@`, `@NAME@`, `@VERSION@`, `@VERSION_CODE@`, `@AUTHOR@`,
`@DESCRIPTION@` and `@WORKER@` from `surfaces.yaml` and packs:

```
module.prop  customize.sh  META-INF/ (Magisk installer stub)
bin/<abi>/worker            (customize.sh keeps the phone's one as bin/worker)
webroot/                    (the Flutter web build + core.wasm + config.json)
```

`config.json` is WebUI X's per-module settings: Back is sent to the app
(`backInterceptor: "javascript"`) so routes pop before the WebUI closes.
Add `service.sh`, `post-fs-data.sh`, `uninstall.sh`, `action.sh` or
`icon.png` here and they are packed too.

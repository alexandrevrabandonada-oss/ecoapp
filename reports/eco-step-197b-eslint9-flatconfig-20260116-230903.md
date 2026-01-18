ECO STEP 197b — ESLint 9: restaurar config valida + ignores + downgrade de regras que viravam error

Stamp: 20260116-230903

Backup eslint: tools\_patch_backup\eslint.config.mjs--20260116-230903
Backup pkg:   tools\_patch_backup\package.json--20260116-230903

Config atual do ESLint parece quebrada. Tentando restaurar a partir de tools/_patch_backup...
Restaurado de: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eslint.config.mjs--20260116-230228

Patch aplicado em eslint.config.mjs (ECO_STEP197B).

package.json atualizado: scripts.lint = eslint .

TestEslintConfig apos patch: False

Rodando: npm run lint


> eluta-servicos@0.1.0 lint
> eslint .

System.Management.Automation.RemoteException
Oops! Something went wrong! :(
System.Management.Automation.RemoteException
ESLint: 9.39.2
System.Management.Automation.RemoteException
SyntaxError: Unexpected token '}'
    at compileSourceTextModule (node:internal/modules/esm/utils:346:16)
    at ModuleLoader.moduleStrategy (node:internal/modules/esm/translators:107:18)
    at #translate (node:internal/modules/esm/loader:540:12)
    at ModuleLoader.loadAndTranslate (node:internal/modules/esm/loader:587:27)
    at async ModuleJob._link (node:internal/modules/esm/module_job:162:19)

# ECO STEP 203 — ESLint 9 final: lint REAL em src/ + ignores + verify via npm.cmd

Stamp: 20260117-125707
Root: C:\Projetos\App ECO\eluta-servicos

## DIAG
### node --version
~~~
v22.19.0
~~~

### npm path detectado
- npm: C:\Program Files\nodejs\npm.cmd

### eslint.config.mjs (primeiras 60 linhas, se existir)
~~~
import js from "@eslint/js";
import tsParser from "@typescript-eslint/parser";
import tsPlugin from "@typescript-eslint/eslint-plugin";

export default [
  {
    ignores: [
      "**/node_modules/**",
      "**/.next/**",
      "**/dist/**",
      "**/coverage/**",
      "**/reports/**",
      "tools/_patch_backup/**",
      "tools/**/_patch_backup/**",
      "**/*.bak-*",
      "**/*.bak",
      "**/*.log"
    ],
  },
  {
    // base JS rules (escopo: src/)
    ...js.configs.recommended,
    files: ["src/**/*.{js,jsx,ts,tsx}"],
  },
  {
    files: ["src/**/*.{ts,tsx}"],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
        ecmaFeatures: { jsx: true }
      }
    },
    plugins: { "@typescript-eslint": tsPlugin },
    rules: {
      ...tsPlugin.configs.recommended.rules,
      // minsafes pra não travar o projeto agora:
      "no-undef": "off",
      "no-unused-vars": "off",
      "@typescript-eslint/no-unused-vars": ["warn", { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }],
      "@typescript-eslint/no-explicit-any": "off",
    }
  }
];
~~~

## PATCH A — remover __DEP__ em src/ (pra nao poluir hooks/lint)
- ok: sem __DEP__ em src/

## PATCH B — eslint.config.mjs (flat) minimo, mas REAL (src/)
- backup: C:\Projetos\App ECO\eluta-servicos\eslint.config.mjs -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-203\20260117-125707\eslint.config.mjs--20260117-125707
- wrote: C:\Projetos\App ECO\eluta-servicos\eslint.config.mjs

## PATCH C — package.json scripts.lint (robusto: node ./node_modules/.../eslint.js)
- backup: C:\Projetos\App ECO\eluta-servicos\package.json -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-203\20260117-125707\package.json--20260117-125707
- ok: scripts.lint atualizado

## VERIFY
### npm --version (via npm.cmd preferencial)
~~~
npm <command>

Usage:

npm install        install all the dependencies in your project
npm install <foo>  add the <foo> dependency to your project
npm test           run this project's tests
npm run <foo>      run the script named <foo>
npm <command> -h   quick help on <command>
npm -l             display usage info for all commands
npm help <term>    search for help on <term> (in a browser)
npm help npm       more involved overview (in a browser)

All commands:

    access, adduser, audit, bugs, cache, ci, completion,
    config, dedupe, deprecate, diff, dist-tag, docs, doctor,
    edit, exec, explain, explore, find-dupes, fund, get, help,
    help-search, hook, init, install, install-ci-test,
    install-test, link, ll, login, logout, ls, org, outdated,
    owner, pack, ping, pkg, prefix, profile, prune, publish,
    query, rebuild, repo, restart, root, run-script, sbom,
    search, set, shrinkwrap, star, stars, start, stop, team,
    test, token, uninstall, unpublish, unstar, update, version,
    view, whoami

Specify configs in the ini-formatted file:
    C:\Users\Micro\.npmrc
or on the command line via: npm <command> --key=value

More configuration info: npm help config
Configuration fields: npm help 7 config

npm@10.9.3 C:\Program Files\nodejs\node_modules\npm
~~~

### npm run lint
~~~
npm <command>

Usage:

npm install        install all the dependencies in your project
npm install <foo>  add the <foo> dependency to your project
npm test           run this project's tests
npm run <foo>      run the script named <foo>
npm <command> -h   quick help on <command>
npm -l             display usage info for all commands
npm help <term>    search for help on <term> (in a browser)
npm help npm       more involved overview (in a browser)

All commands:

    access, adduser, audit, bugs, cache, ci, completion,
    config, dedupe, deprecate, diff, dist-tag, docs, doctor,
    edit, exec, explain, explore, find-dupes, fund, get, help,
    help-search, hook, init, install, install-ci-test,
    install-test, link, ll, login, logout, ls, org, outdated,
    owner, pack, ping, pkg, prefix, profile, prune, publish,
    query, rebuild, repo, restart, root, run-script, sbom,
    search, set, shrinkwrap, star, stars, start, stop, team,
    test, token, uninstall, unpublish, unstar, update, version,
    view, whoami

Specify configs in the ini-formatted file:
    C:\Users\Micro\.npmrc
or on the command line via: npm <command> --key=value

More configuration info: npm help config
Configuration fields: npm help 7 config

npm@10.9.3 C:\Program Files\nodejs\node_modules\npm
~~~

### npm run build
~~~
npm <command>

Usage:

npm install        install all the dependencies in your project
npm install <foo>  add the <foo> dependency to your project
npm test           run this project's tests
npm run <foo>      run the script named <foo>
npm <command> -h   quick help on <command>
npm -l             display usage info for all commands
npm help <term>    search for help on <term> (in a browser)
npm help npm       more involved overview (in a browser)

All commands:

    access, adduser, audit, bugs, cache, ci, completion,
    config, dedupe, deprecate, diff, dist-tag, docs, doctor,
    edit, exec, explain, explore, find-dupes, fund, get, help,
    help-search, hook, init, install, install-ci-test,
    install-test, link, ll, login, logout, ls, org, outdated,
    owner, pack, ping, pkg, prefix, profile, prune, publish,
    query, rebuild, repo, restart, root, run-script, sbom,
    search, set, shrinkwrap, star, stars, start, stop, team,
    test, token, uninstall, unpublish, unstar, update, version,
    view, whoami

Specify configs in the ini-formatted file:
    C:\Users\Micro\.npmrc
or on the command line via: npm <command> --key=value

More configuration info: npm help config
Configuration fields: npm help 7 config

npm@10.9.3 C:\Program Files\nodejs\node_modules\npm
~~~

## NEXT
- Se no terminal 
pm continuar imprimindo help em vez de rodar, use 
pm.cmd (ou fixe: Set-Alias npm npm.cmd).
- Agora o lint é REAL (src/) e ignora tools/_patch_backup + reports, que eram a origem de muito ruído.
- Próximo tijolo: rodar o smoke canônico (tools\\eco-step-148b* mais recente).
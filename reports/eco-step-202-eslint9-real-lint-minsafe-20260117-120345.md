# ECO STEP 202 — ESLint 9 real lint (minsafes) + excludes

Stamp: 20260117-120345
Root: C:\Projetos\App ECO\eluta-servicos

## PATCH A — garantir deps ESLint 9 + TS parser/plugin
- ok: deps já presentes

## PATCH B — eslint.config.mjs (flat config, lint só src/)
- backup: C:\Projetos\App ECO\eluta-servicos\eslint.config.mjs -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-202\20260117-120345\eslint.config.mjs--20260117-120345
- wrote: C:\Projetos\App ECO\eluta-servicos\eslint.config.mjs

## PATCH C — package.json scripts.lint (Windows-safe)
- backup: C:\Projetos\App ECO\eluta-servicos\package.json -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-202\20260117-120345\package.json--20260117-120345
- ok: scripts.lint = eslint src --ext ... --cache --no-error-on-unmatched-pattern

## PATCH D — tsconfig.json exclude (backups/reports)
- backup: C:\Projetos\App ECO\eluta-servicos\tsconfig.json -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-202\20260117-120345\tsconfig.json--20260117-120345
- ok: tsconfig exclude atualizado

## VERIFY
### npm --version
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
- Se seu terminal continuar 'estranho' com npm, pode fixar: Set-Alias npm npm.cmd
- Agora o lint está REAL (src/). Se quiser endurecer depois, a gente sobe regras gradualmente.
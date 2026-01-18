# ECO — STEP 51 — Prisma EcoDayClose (model + migrate)

Data: 2025-12-27 12:29:33
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG — schema.prisma
- Tamanho: 2876 chars

## PATCH — model EcoDayClose
- OK: já existe (nenhuma alteração).

## PRISMA — format

    Prisma is a modern DB toolkit to query, migrate and model your database (https://prisma.io)

    Usage

      $ prisma [command]

    Commands

                init   Set up Prisma for your app
                 dev   Start a local Prisma Postgres server for development
            generate   Generate artifacts (e.g. Prisma Client)
                  db   Manage your database schema and lifecycle
             migrate   Migrate your database
              studio   Browse your data with Prisma Studio
            validate   Validate your Prisma schema
              format   Format your Prisma schema
             version   Displays Prisma version info
               debug   Displays Prisma debug info
                 mcp   Starts an MCP server to use with AI development tools

    Flags

         --preview-feature   Run Preview Prisma commands
         --help, -h          Show additional information about a command

ÔöîÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÉ
Ôöé  Optimize performance through connection pooling and caching with Prisma Accelerate  Ôöé
Ôöé  and capture real-time events from your database with Prisma Pulse.                  Ôöé
Ôöé  Learn more at https://pris.ly/cli/pdp                                               Ôöé
- ExitCode: 0

## PRISMA — migrate dev (eco_day_close)

    Prisma is a modern DB toolkit to query, migrate and model your database (https://prisma.io)

    Usage

      $ prisma [command]

    Commands

                init   Set up Prisma for your app
                 dev   Start a local Prisma Postgres server for development
            generate   Generate artifacts (e.g. Prisma Client)
                  db   Manage your database schema and lifecycle
             migrate   Migrate your database
              studio   Browse your data with Prisma Studio
            validate   Validate your Prisma schema
              format   Format your Prisma schema
             version   Displays Prisma version info
               debug   Displays Prisma debug info
                 mcp   Starts an MCP server to use with AI development tools

    Flags

         --preview-feature   Run Preview Prisma commands
         --help, -h          Show additional information about a command

ÔöîÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÉ
Ôöé  Optimize performance through connection pooling and caching with Prisma Accelerate  Ôöé
Ôöé  and capture real-time events from your database with Prisma Pulse.                  Ôöé
Ôöé  Learn more at https://pris.ly/cli/pdp                                               Ôöé
ÔööÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÿ

    Examples

      Set up a new local Prisma Postgres `prisma dev`-ready project
      $ prisma init

      Start a local Prisma Postgres server for development
      $ prisma dev

      Generate artifacts (e.g. Prisma Client)
      $ prisma generate

      Browse your data
      $ prisma studio

      Create migrations from your Prisma schema, apply them to the database, generate artifacts (e.g. Prisma Client)
      $ prisma migrate dev

      Pull the schema from an existing database, updating the Prisma schema
      $ prisma db pull

      Push the Prisma schema state to the database
      $ prisma db push

      Validate your Prisma schema
      $ prisma validate

      Format your Prisma schema
      $ prisma format

      Display Prisma version info
      $ prisma version

      Display Prisma debug info
      $ prisma debug

- ExitCode: 0

## PRISMA — generate

    Prisma is a modern DB toolkit to query, migrate and model your database (https://prisma.io)

    Usage

      $ prisma [command]

    Commands

                init   Set up Prisma for your app
                 dev   Start a local Prisma Postgres server for development
            generate   Generate artifacts (e.g. Prisma Client)
                  db   Manage your database schema and lifecycle
             migrate   Migrate your database
              studio   Browse your data with Prisma Studio
            validate   Validate your Prisma schema
              format   Format your Prisma schema
             version   Displays Prisma version info
               debug   Displays Prisma debug info
                 mcp   Starts an MCP server to use with AI development tools

    Flags

         --preview-feature   Run Preview Prisma commands
         --help, -h          Show additional information about a command

ÔöîÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÉ
Ôöé  Optimize performance through connection pooling and caching with Prisma Accelerate  Ôöé
Ôöé  and capture real-time events from your database with Prisma Pulse.                  Ôöé
Ôöé  Learn more at https://pris.ly/cli/pdp                                               Ôöé
ÔööÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÿ

    Examples

      Set up a new local Prisma Postgres `prisma dev`-ready project
      $ prisma init

      Start a local Prisma Postgres server for development
      $ prisma dev

      Generate artifacts (e.g. Prisma Client)
      $ prisma generate

      Browse your data
      $ prisma studio

      Create migrations from your Prisma schema, apply them to the database, generate artifacts (e.g. Prisma Client)
      $ prisma migrate dev

      Pull the schema from an existing database, updating the Prisma schema
      $ prisma db pull

      Push the Prisma schema state to the database
      $ prisma db push

      Validate your Prisma schema
      $ prisma validate

      Format your Prisma schema
      $ prisma format
- ExitCode: 0

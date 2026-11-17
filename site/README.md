# zdawood.dev

My personal site. A static page written in Elm (`Browser.application`, so it owns its own
routing), styled with my personal brand, and built and served by Cloudflare (Workers Builds) on every
push to `main`. It lives in `site/` of the `personal` repo and takes the brand from `../web/`,
which `make` in the repo root generates from `tokens.toml`. Nothing of the brand is copied in here.

```sh
npm install
npm run build   # scripts/build.sh: elm make --optimize in a temp dir → dist/elm.js, then public/ and ../web's css/js into dist/
npm start       # build, then serve dist/ at http://localhost:8000 (deep links fall back to index.html)
```

## Layout

| Path | What |
|---|---|
| `src/Main.elm` | The whole site: routes, pages, view |
| `public/index.html` | The HTML shell: fonts, stylesheets, `Elm.Main.init()` |
| `../web/brand.css`, `../web/theme.js` | The personal brand and the day/night switch (generated; copied into `dist/` by the build) |
| `../web/Brand.elm` | The palette and the leaf for Elm (generated; `elm.json` lists `../web` as a source directory) |
| `public/site.css` | The site's own layout on top of the brand |
| `scripts/serve.mjs` | A local server that behaves like Pages (a real file, else `index.html`) |

To add a page: add a `Route`, a parser line in `routeParser`, and a case in `view`.

## Cloudflare (one time, in the dashboard)

The site deploys as a Worker with static assets. `wrangler.jsonc` says what to upload (`dist/`) and
that unknown paths get `index.html`, so Elm's router handles deep links and shows its own not-found page.

1. Workers & Pages → Create → **Import a repository** → pick `zfdawood/personal`.
2. Project name `site` (it must match `name` in `wrangler.jsonc`). **Root directory `site`.**
   Build command `npm run build`. Deploy command `npx wrangler deploy` (the default).
   Cloudflare still clones the whole repo, so the build can read `../web`.
   Node's version comes from `.node-version` here, so there's no `NODE_VERSION` variable to set.
3. Deploy. Each push to `main` redeploys.
4. The Worker's Settings → Domains & Routes → add the custom domain `zdawood.dev` (and
   `www.zdawood.dev` if wanted). If the domain's DNS is on Cloudflare, the records are created for you.

To check the config locally without deploying: `npm run build && npx wrangler deploy --dry-run`.

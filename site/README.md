# zdawood.dev

My personal site. A static page written in Elm (`Browser.application`, so it owns its own
routing), styled with my personal brand, and built and served by Cloudflare Pages on every push to
`main`.

```sh
npm install
npm run build   # scripts/build.sh: elm make --optimize in a temp dir → dist/elm.js, then public/ into dist/
npm start       # build, then serve dist/ at http://localhost:8000 (deep links fall back to index.html)
```

## Layout

| Path | What |
|---|---|
| `src/Main.elm` | The whole site: routes, pages, view |
| `public/index.html` | The HTML shell: fonts, stylesheets, `Elm.Main.init()` |
| `public/brand.css` | The personal brand. A copy of `~/.claude/skills/personal-brand/brand.css`: change it there, then copy it here |
| `public/site.css` | The site's own layout on top of the brand |
| `scripts/serve.mjs` | A local server that behaves like Pages (a real file, else `index.html`) |

To add a page: add a `Route`, a parser line in `routeParser`, and a case in `view`.

## Cloudflare (one time, in the dashboard)

The site deploys as a Worker with static assets. `wrangler.jsonc` says what to upload (`dist/`) and
that unknown paths get `index.html`, so Elm's router handles deep links and shows its own not-found page.

1. Workers & Pages → Create → **Import a repository** → pick `zfdawood/site`.
2. Project name `site` (it must match `name` in `wrangler.jsonc`).
   Build command `npm run build`. Deploy command `npx wrangler deploy` (the default).
3. Deploy. Each push to `main` redeploys.
4. The Worker's Settings → Domains & Routes → add the custom domain `zdawood.dev` (and
   `www.zdawood.dev` if wanted). If the domain's DNS is on Cloudflare, the records are created for you.

To check the config locally without deploying: `npm run build && npx wrangler deploy --dry-run`.

# The SupremePump Team

The website for Olutayo (Mr. SupremePump) — online coaching, in-person training
and 12-week transformations. Plain HTML, CSS and JS with no build step: Netlify
serves the repo root as-is.

## Layout

```
index.html            Home page
blog.html             Blog reader
thanks.html           Form success page (Netlify Forms fallback)
404.html              Not found
netlify.toml          Publish directory and cache headers
_redirects            Blocks /source-media, redirects the old folder paths

css/styles.css        All styling. Brand colours are the CSS variables at the top.
js/site.js            Shared chrome: header, mobile menu, footer year
js/home.js            Home page: before/after picker, contact form
js/blog.js            Blog page: renders blog-data.json

assets/images/        Images used by the site
assets/stretch-guide.pdf   The free download

admin/                Decap CMS (the blog editor), served at /admin
blog-data.json        Every blog post. Written by the CMS, read by js/blog.js
images/blog/          Blog cover images uploaded through the CMS

source-media/         Original full-resolution photos. Kept for future edits,
                      not served on the site (see _redirects).
tools/prep-images.ps1 Regenerates assets/images/ from source-media/
```

## Regenerating the images

`tools/prep-images.ps1` builds everything in `assets/images/` from the originals
in `source-media/`: it splits the side-by-side before/after collages at the
gutter between the two panels, strips the black letterbox bars phone
screenshots carry, scales each photo down and re-encodes it as JPEG.

```powershell
powershell -File tools\prep-images.ps1
```

It overwrites `assets/images/`, so edit the script rather than the output.

## Editing the blog

Go to `/admin` on the live site and sign in with Netlify Identity. Posts are
stored in `blog-data.json` and cover images land in `images/blog/`. The reader
shows the newest post first.

If `/admin` asks you to log in and nothing happens, check that Netlify Identity
and Git Gateway are both enabled under *Site configuration → Identity*.

## The contact form

`index.html` uses **Netlify Forms** (`data-netlify="true"`). Submissions appear
under *Site → Forms*. Turn on email notifications in
*Forms → Settings → Form notifications* so enquiries reach
`olutayo@leduweglobal.com`.

The previous site posted to formsubmit.co; that is no longer used.

## Images

| File | What it is |
|---|---|
| `assets/images/logo.jpg` | Logo. Note the source art spells it "Suprreme" — a corrected, transparent PNG or SVG would be an improvement. |
| `assets/images/hero-banner.jpg` | "Join the SupremePump Team" banner |
| `assets/images/coach-portrait.jpg` | Olutayo, About section |
| `assets/images/instagram-qr.jpg` | Instagram QR code |
| `assets/images/favicon.png` | Browser tab icon, generated from the logo |
| `assets/images/{dayo,natalie,glen}-{before,after}.jpg` | Transformation photos |

Transformation photos are shown with `object-fit: contain` so full-body shots
are never cropped at the head or feet. Portrait images around 3:4 fit best.

### Adding another transformation

1. Add `assets/images/<name>-before.jpg` and `-after.jpg`.
2. In `index.html`, copy one `<button class="client" …>` in the Transformations
   section and change `data-name`, `data-before`, `data-after` and the text.

### Unused client photos

`source-media/clients-2026-11/` holds three photo pairs from November 2026 that
are **not** on the site yet, because the client names were never recorded and
which shot in each pair is the "before" is a guess. Each pair is `client-N-a`
and `client-N-b`. Once the names and the order are confirmed, add them to
`tools/prep-images.ps1` and to the Transformations list in `index.html`.

A fourth pair from the same batch turned out to be Natalie, and is now
`source-media/natalie-{before,after}-original.jpeg`.

## Colours and fonts

Every brand colour is a CSS variable at the top of `css/styles.css` (`--accent`
is the orange). Fonts are Archivo for headings and Inter for body text, both
loaded from Google Fonts.

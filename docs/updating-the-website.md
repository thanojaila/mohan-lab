# How to update the Mohan Lab website

For lab members who are **not** developers. You do everything in your web browser on github.com. No installs, no terminal.

**The idea:** the website's text and images are stored in GitHub. When you save a change there, the website checks it and publishes it by itself in about 3-5 minutes.

---

## Before you begin

You need:
- A GitHub account that has been given **write access** to this repository (ask the website owner, see the table at the bottom).
- The change you want to make (new text, a new person, a new image).

> Tip: make one small change at a time. If something goes wrong, it is then obvious which change caused it.

---

## A. Change text on the website

1. Go to the repository on github.com and open the folder that holds that kind of content. The file that holds each kind of content is listed in `docs/maintenance.md` (and in the table in section F below).
2. Click the file, then click the **pencil icon** (Edit this file) at the top right.
3. Change the text. Only change the words between quotes or the lines you mean to change. **Do not delete quotation marks, commas, brackets or braces** around the text. They are part of the file's structure.
4. Click the green **Commit changes...** button.
5. In the box, write a short description of what you changed (for example: `Add new publication, Smith 2026`).
6. Leave **Commit directly to the main branch** selected and click **Commit changes**.

## B. Add or replace an image, PDF or video

1. Open the `public` folder, then the sub-folder where similar files already live.
2. Click **Add file → Upload files**, drag your file in, and wait for it to finish.
3. Use a simple file name: lowercase, no spaces (`jane-doe-photo.jpg`, not `Jane Doe Photo (2).JPG`).
4. Write a short description and click **Commit changes** (to main).
5. Now edit the text file that should show the image (section A) and put in the new file name.

Keep images under about 1 MB where possible (photos straight from a phone are often much bigger; resize them first).

## C. Check that it worked

1. Click the **Actions** tab at the top of the repository.
2. The top entry is your change. Wait for it to finish (a spinning yellow circle becomes a result):
   - ✅ **Green check:** published. Reload https://mohanlab.bme.uh.edu (press `Ctrl+Shift+R`, or `Cmd+Shift+R` on a Mac, to skip the browser's saved copy) and look at your change.
   - ❌ **Red X:** your change was **not** published and the website is **unchanged**. See section D.
3. Always look at the live page afterwards, because the automatic checks catch broken files but not typos or wrong facts.

## D. If you see a red X

Don't panic: **the live website keeps working exactly as before.**

1. Click the red entry, then click the step with the red X to read the message.
2. The most common cause is a missing or extra quotation mark or comma in the file you edited. Open the file again, compare it with the lines around it, and fix it.
3. If you cannot see the problem, **undo your edit**: open the file → **History** (top right) → click the commit that broke it → look for the three-dot menu or ask the website owner to revert it. Then ask for help (section G).

## E. Things not to do

- Do not edit files outside the content and `public` folders (anything in `cloudflare/`, `scripts/`, `.github/`, `package.json`, or `src/app/`) unless a developer asked you to.
- Do not make several unrelated edits in one go.
- Do not paste passwords or keys into any file.

---

## F. Where does each kind of content live?

| What you want to change | Where it is |
|---|---|
| People / team members | `src/content-source/pages.json` (source records); curated profile overrides in `src/app/lib/content.ts` |
| Publications | `src/app/lib/publications.ts` (parsing and supplemental records); source records in `src/content-source/pages.json` |
| News | `src/app/lib/news.ts` |
| Research projects | `src/content-source/pages.json` (source records); the study recruitment page is `src/app/research/digital-phenotyping/page.tsx` and `src/app/components/StudyCallout.tsx` |
| Internships / past interns | `src/content-source/pages.json` (source records); the specific open-positions list is in `src/app/opportunities/page.tsx` |
| Contact details | `src/app/contact/page.tsx` (address and email are written directly in this file) |
| Images and downloads | `public/media/` (and `src/content-source/site-media-map.json` maps files to pages) |

---

## G. Who to ask / who owns what

*(Website owner: fill this in before handing over. Keep the actual passwords in the lab password manager, never in this file.)*

| Item | Owner / contact | Notes |
|---|---|---|
| Day-to-day website owner | `TODO name, email` | Reviews changes, gives GitHub access |
| Technical backup | `TODO name, email` | Can fix servers and failed publishes |
| GitHub repository | `TODO account/org` | Where the site's files live |
| AWS account (hosting) | `TODO account owner` | Server costs about $20/month. Billing alerts go to `TODO email` |
| Domain `mohanlab.bme.uh.edu` (DNS) | Dr. Vivek Kumar / UH IT | Only needed if the server's IP address ever changes |
| Password manager | `TODO` | Holds AWS login and the server key file |

---

## H. If something is really wrong

| Situation | What to do |
|---|---|
| The website shows an error or will not load | Wait 5 minutes, then ask the technical backup. They can restart the server (`docs/aws-hosting.md`, "Everyday commands") |
| A bad change got published | Ask the technical backup to run a go-back (**Actions → Deploy website → Run workflow** with the previous commit ID) |
| You need a change that is not just text/images (new page, new design) | Ask a developer. Do not edit code files yourself |

Developers: the full hosting setup, recovery steps and troubleshooting table are in `docs/aws-hosting.md`.

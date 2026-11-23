# Contributing to Turn-in Totals

Thanks for helping out! Bug reports, ideas and pull requests are all welcome.

## Reporting a bug

Open an issue and include:

- what you did, what you expected, and what happened instead;
- the output of `/tit`;
- the full Lua error text, if there was one ([BugSack](https://www.curseforge.com/wow/addons/bugsack) makes this easy).

## Development setup

1. Clone the repository anywhere you like.
2. Link the folder into the game, so `/reload` picks up your changes. From a Command Prompt:

   ```bat
   mklink /J "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\TurnInTotals" "C:\path\to\your\clone"
   ```

   The link must be called `TurnInTotals` (the addon's name), whatever your clone's folder is called.

   On macOS, use `ln -s` into `/Applications/World of Warcraft/_forever_/Interface/AddOns/`.

3. Log in, make changes, and type `/reload`.

## Code layout

| File | Purpose |
|---|---|
| `Core.lua` | Everything: translations, the totals, the line above the quest list, the options panel, `/tit` |
| `Media/Icon.tga` | The addon's icon in the game's AddOns list (64×64, 32-bit TGA) |

## Guidelines

- **Indentation:** use tabs in Lua, matching the existing code.
- **Language:** write player-facing text in English in the `L` table at the top of `Core.lua`, and
  add the translation to the `ptBR` block below it.
- **Taint:** Blizzard code must never read a value the addon wrote. The line is the addon's own
  frame, not a child of the quest list's layout; room is made only by moving the list's scroll frame
  (geometry doesn't spread taint). An earlier version that put the line inside the list's layout got
  "TurnInTotals tried to perform a blocked action" on the world map.
- **One change per pull request**, with a short description of what it does and how you tested it
  in game.
- **Changelog:** add a line under *Unreleased* in `CHANGELOG.md`.

## Releasing (maintainers)

1. In the release pull request, move the *Unreleased* changelog entries under a new `## X.Y.Z` heading.
2. Merging it runs `.github/workflows/release.yml`: it builds `TurnInTotals-vX.Y.Z.zip`
   (without the files listed under `ignore` in `.pkgmeta`, and with `@project-version@` in the `.toc`
   replaced by the version), uploads it to CurseForge and creates the GitHub release `vX.Y.Z`.
   It needs the repository secret `CF_API_KEY` and the `X-Curse-Project-ID` line in the `.toc`.

By contributing, you agree that your contributions are licensed under the project's
[MIT License](LICENSE).

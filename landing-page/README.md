# Zumo marketing landing page

Responsive one-page marketing website concept for the Zumo visitor app for Dehiwala Zoo.

## Run locally

1. Extract the ZIP (if using the ZIP package).
2. Open `index.html` in a browser, or use VS Code Live Server.
3. An internet connection is needed for Google Fonts and the externally hosted Unsplash photos.

## Files

- `index.html` — page content and semantic sections
- `styles.css` — responsive layout, colour system, typography and visual styles
- `script.js` — mobile navigation and scroll reveal interactions

## Branding

- Background: `#FCFCF7`
- Primary green: `#004D3E`
- Deep green: `#07382E`
- Sage: `#E6EEE2`
- Typography: Manrope + DM Sans

## Notes

- This is a marketing landing-page concept, separate from the Flutter mobile application.
- The map, assistant chat, and collection visuals are illustrative previews; they do not claim live data or verified zoo-path accuracy.
- Photo references: [Asian elephant](https://unsplash.com/photos/an-elephant-standing-in-a-lush-green-forest-bDONg1pCj7o), [giraffe](https://unsplash.com/photos/Mgj3_Fa852U), [flamingo](https://unsplash.com/photos/pink-flamingo-on-body-of-water-x9JSjPiWCvo), and [lion](https://unsplash.com/photos/a-close-up-of-a-lion-laying-in-the-grass-27pK82W2ve8). Images are remotely loaded from Unsplash CDN URLs.
- Animal photography is loaded from Unsplash-hosted image URLs. Before production deployment, confirm that the selected images match the intended animals and retain appropriate attribution/asset records where required.
- Replace the example contact email `hello@zumo.lk` with the project's official contact address before launch.

## Clickable app prototype (hero)

The phone in the hero plays the Zumo app prototype exported from the Figma file (`Zumo — Editable Home Screen`).

- `figma-screens.js` — all prototype screens converted from Figma to SVG, with the click areas and flow taken from the Figma prototype
- `prototype.js` — small player that shows the screens, handles taps and the splash timer
- `prototype.css` — phone frame and tap-area styles
- `assets/figma/` — images used inside the screens
- To update after changing the Figma design, re-export the `.fig` file and ask for the screens to be regenerated.

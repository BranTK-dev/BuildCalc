# BuildCalc

BuildCalc is a small Qt/C++ mobile app for quick home-improvement material estimates. It follows the concept notes in `buildcalc_app_notes.txt`: pick a calculator, enter a few measurements, and get a practical buying quantity plus an optional cost estimate.

## Current V1 Scope

- Paint
- Tiling
- Flooring
- Concrete
- Bricks
- Plastering
- Roofing sheets
- Local recent calculation using `QSettings`
- Placeholder banner ad areas for a future AdMob integration

## Open In Qt Creator

1. Open Qt Creator.
2. Choose **File > Open File or Project**.
3. Select `CMakeLists.txt` in this folder.
4. Configure a Qt 6.5 or newer kit.
5. Run the `appBuildCalc` target.

For Android, configure an Android Qt kit in Qt Creator, then build and deploy the same target to an emulator or phone.

## Formula Notes

The formulas are practical starting points and should be checked against local supplier guidance before release:

- Paint: 10 m2 per liter, multiplied by number of coats, plus 10% extra.
- Tiling: surface area plus 10% spare, divided by tile area.
- Flooring: room area plus 10% spare, divided by pack coverage.
- Concrete: slab volume with a 1:2:4 mix estimate and dry-volume factor.
- Bricks: 50 bricks per m2 for a single-skin wall, plus 5% extra.
- Plastering: 1:4 plaster estimate using wall area and thickness.
- Roofing: roof width divided by effective sheet cover width.

## Next Steps

- Replace placeholder ad banners with AdMob after the Android package name is final.
- Add app icons and store screenshots.
- Verify formulas against target-market materials and units.
- Add Android signing configuration when ready for Play Store testing.

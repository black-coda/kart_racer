
## 2026-11-25 — M0 complete: framing fixed, milestone checked off
- Developer confirmed the landscape fix on the Pixel 6.
- Fixed camera framing in `models_view.dart`: both karts side by side at Y=0 (type-1 at x=-1.5, type-2 at x=1.5, z=8); camera at (0, 1.5, 2) aimed at (0, 0, 8). Verified with a fresh `flutter run -d macos` + screenshot: HotRod and Toy Car both visible in one view. Analyzer + format clean; run stopped cleanly.
- Checked the M0 box in the APP.md status tracker. guide.html M0 marked Complete (all acceptance criteria done; FPS test skipped by developer decision).

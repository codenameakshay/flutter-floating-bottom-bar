# Review evidence

These clips are real simulator captures from an iPhone 17e running iOS 26.5.
The MP4 derivatives are 390×844 H.264/yuv420p at 24 fps with faststart. PNGs
are resized to 390×844.

| Feature | Before | After | Stills | Provenance and comparison |
| --- | --- | --- | --- | --- |
| Contextual issue actions | [context-before.mp4](./context-before.mp4) | [context-after.mp4](./context-after.mp4) | [context.png](./context.png), [context-archived.png](./context-archived.png) | Baseline `cdaf18d`; after feature source `ba0b330`. The after capture selects two real rows, archives both with a snackbar, then selects and clears another row. |
| Local composer | [composer-interaction-before.mp4](./composer-interaction-before.mp4) | [composer-after.mp4](./composer-after.mp4) | [composer.png](./composer.png), [composer-software-keyboard.png](./composer-software-keyboard.png) | Baseline `cdaf18d`; after feature source `a1f25fc`. The before clip is the legacy composer visual; the after clip shows the local draft and transcript flow. |
| Reader controls | [reader-before.mp4](./reader-before.mp4) | [reader-after.mp4](./reader-after.mp4) | [reader.png](./reader.png) | Baseline `cdaf18d`, using the Minimal API demo; after feature source `a78f27e`. This is a comparison against the baseline demo, not the same page before and after. |
| Scroll under | [scroll-under-before.mp4](./scroll-under-before.mp4) | [scroll-under-after.mp4](./scroll-under-after.mp4) | [scroll-under.png](./scroll-under.png) | Baseline `cdaf18d`, using the Minimal API demo; after feature source `39abd32`. This is a comparison against the baseline demo, not the same page before and after. |
| Adaptive navigation | [adaptive-before.mp4](./adaptive-before.mp4) | [adaptive-after.mp4](./adaptive-after.mp4) | [adaptive-ltr.png](./adaptive-ltr.png), [adaptive.png](./adaptive.png) | Baseline `cdaf18d`, using the Badged nav demo; after feature source `069137c`. The after stills show the labeled destinations in LTR and RTL layouts. |

The reader and scroll-under before clips retain the baseline interactions and
are intentionally labeled as Minimal API comparisons. The adaptive before clip
is intentionally labeled as a Badged nav comparison. No before clip claims to
be a capture of the new page before its implementation.

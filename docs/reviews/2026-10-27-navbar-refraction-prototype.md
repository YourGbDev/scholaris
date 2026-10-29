# Navbar refraction prototype

Owner authorized an isolated experiment after reviewing the cropped 30 fps Tarsi recording. Apple HIG material guidance informs restrained functional-layer use, legibility, and high-contrast fallback; this does not reproduce or claim Tarsi's implementation.

Implemented `StudentGlassRefraction` and `shaders/student_glass_lens.frag`. The shader displaces backdrop sampling around the capsule perimeter while leaving the center relatively undistorted. Existing navigation remains the child and the default production dock keeps this experiment disabled. Preview opt-in: `?refraction=true` (combine with `bands=true`).

Support: installed SDK supports ImageFilter.shader only with Impeller. Unsupported renderers, shader loading failures, high contrast, reduced motion and accessible navigation retain the existing material. Browser preview therefore demonstrates fallback, NOT refraction. No native device or IPA build performed.

Fresh checks: 38 focused tests passed (`scratch/codex-refraction-prototype-tests.txt`), four-file scoped analysis clean (`scratch/codex-refraction-analysis.txt`). These prove compilation, fallback and navigation regressions only. They do not prove the optical shader on physical hardware. Native backdrop coordinate alignment, device-pixel ratio, nested backdrop composition, scrolling frame cost and edge sampling need device validation before enabling in production. Prototype currently affects the main dock only; separate action retains its existing material.

No dependencies installed, no commits, remote operations, deployment or release builds. Current nonexperimental navbar is preserved.

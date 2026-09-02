# WBAB Retirement Dependency Inventory

Status: **initial inventory in progress**

Authoritative retirement tracker: #61

This inventory records accessible repository references to WineBotAppBuilder and classifies whether they are live dependencies or historical/documentation references. It is intentionally evidence-driven: a repository name or architecture mention alone is not treated as a live dependency.

## Confirmed references

| Repository | Reference | Classification | Initial disposition |
| --- | --- | --- | --- |
| `SemperSupra/WinInspect-private` | `.gitmodules` entry `external/WineBotAppBuilder` | build/development dependency candidate | Highest-priority detachment target. Verify no current workflow/script requires the submodule, preserve replacement evidence from native Windows CI/release, then remove in a bounded WinInspect change. |
| `SemperSupra/WineBot` | architecture documentation lists WBAB as build toolchain / ecosystem component | documentation / architecture | Update only after WBAB consumer detachment is proven; point architecture to successor build/release path rather than preserving WBAB as an active component. |
| `SemperSupra/WineBotAppBuilder` | self-references across code/docs/workflows | project-internal | Retain only as needed for retirement, migration evidence, and historical intelligibility. |

## Current negative evidence

Repository code search during the retirement red-team did not find Delphi-specific requirements in WBAB or the broader SemperSupra code search. The original legacy/licensed-Windows motivation is therefore not represented as a durable WBAB requirement today.

Current WinInspect CI already performs native Windows build/test directly on `windows-latest`, including CMake/CTest and local smoke validation. Its full matrix performs native packaging with NSIS. This is the candidate replacement path for the WBAB dependency and must be validated as sufficient before removal.

## Search/classification procedure

For each accessible organization/personal repository, search for:

- `WineBotAppBuilder`
- `WBAB` / `wbab`
- `external/WineBotAppBuilder`
- Git submodule URLs referencing the WBAB repository
- reusable workflow/action references to WBAB
- shell/PowerShell/Python invocations of `wbab` or `wbabd`
- documentation that recommends WBAB for new work

Classify each result as one of:

- **runtime dependency** — required while the product/application runs;
- **build dependency** — required to produce product artifacts;
- **test/qualification dependency** — required only for validation;
- **documentation/architecture** — descriptive reference, not executable;
- **stale reference** — no longer used and safe to remove after bounded verification.

## Detachment gate

A dependency is removable when:

1. its actual purpose is identified;
2. the successor path executes against a real target;
3. evidence identifies exact source/artifact identities where material;
4. removal does not silently lower the qualification claim; and
5. the downstream repository's durable docs/workflows no longer direct humans or agents back to WBAB.

## WinInspect first-pass conclusion

The checked-in WBAB submodule is currently the strongest concrete downstream dependency found. The native Windows CI path appears to have superseded its build/package role. The next bounded change should occur in WinInspect, not WBAB: verify references on the active branch and remove the submodule only if no executable path still consumes it.

## Inventory completion condition

This inventory is complete when all accessible SemperSupra and relevant personal repositories have been searched, every executable reference is classified, and each live dependency has either a migration issue/change or an explicit retained-capability justification linked from #61.

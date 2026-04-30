#!/usr/bin/env python3
"""Grade the iteration-1 runs by checking assertions against output Dart files."""
import json
import re
from pathlib import Path

WS = Path(__file__).parent

def read(p: Path) -> str:
    try:
        return p.read_text()
    except Exception:
        return ""

# Assertion is (name, predicate, evidence_extractor)
# predicate: text -> bool
# evidence_extractor: text -> str (a quote that proves the result, or empty)

def has(s):
    return lambda t: (s in t, _quote_around(t, s) if s in t else "(not found)")

def has_regex(pattern, label=None):
    rx = re.compile(pattern)
    return lambda t: (
        bool(rx.search(t)),
        rx.search(t).group(0) if rx.search(t) else f"(no match for {label or pattern!r})",
    )

def lacks(s, label=None):
    return lambda t: (s not in t, "(absent — good)" if s not in t else _quote_around(t, s))

def lacks_regex(pattern, label=None):
    rx = re.compile(pattern)
    return lambda t: (
        not rx.search(t),
        "(absent — good)" if not rx.search(t) else rx.search(t).group(0),
    )

def has_all(*needles):
    """Pass when ALL listed substrings are present anywhere in the text."""
    def check(t):
        missing = [n for n in needles if n not in t]
        if missing:
            return False, f"(missing: {', '.join(missing)})"
        return True, f"(all present: {', '.join(needles)})"
    return check

def _quote_around(text, needle, context=40):
    i = text.find(needle)
    if i < 0:
        return ""
    start = max(0, i - context)
    end = min(len(text), i + len(needle) + context)
    snippet = text[start:end].replace("\n", " ")
    return f"…{snippet}…"

# Define assertions per eval
ASSERTIONS = {
    "eval-0-replace-bottomnavbar": {
        "file": "home_page.dart",
        "checks": [
            ("imports_package", has("package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart")),
            ("uses_BottomBar_widget", has_regex(r"\bBottomBar\s*\(", "BottomBar(")),
            ("removes_BottomNavigationBar", lacks_regex(r"\bBottomNavigationBar\s*\(", "BottomNavigationBar(")),
            ("removes_BottomNavigationBarItem", lacks_regex(r"\bBottomNavigationBarItem\s*\(", "BottomNavigationBarItem(")),
            ("preserves_currentIndex_field", has("_currentIndex")),
            ("uses_v2_body_as_widget_not_v1_builder", lacks_regex(r"body:\s*\(\s*context\s*,\s*\w+\)\s*=>", "(context, controller) =>")),
            ("references_deepPurple", has("deepPurple")),
            ("has_4_tabs", has_regex(r"BottomBarItem|home|Home|search|Search|notif|Notif|alert|Alert|profile|Profile", "tab labels")),
        ],
    },
    "eval-1-migrate-v1-to-v2": {
        "file": "feed_page.dart",
        "checks": [
            ("removes_v1_barColor_param", lacks_regex(r"\bbarColor\s*:", "barColor:")),
            ("removes_v1_body_builder", lacks_regex(r"body:\s*\(\s*\w+\s*,\s*\w+\)\s*=>", "(context, controller) =>")),
            ("uses_BottomBarLayout", has("BottomBarLayout")),
            ("uses_BottomBarMotion", has("BottomBarMotion")),
            ("uses_BottomBarScrollBehavior", has("BottomBarScrollBehavior")),
            ("uses_BottomBarThemeData", has("BottomBarThemeData")),
            ("uses_slideStart_Offset", has_regex(r"slideStart\s*:\s*(?:const\s+)?Offset", "slideStart: Offset")),
            ("uses_deltaThreshold_not_scrollDeltaThreshold", has("deltaThreshold")),
            ("removes_v1_scrollDeltaThreshold", lacks("scrollDeltaThreshold")),
            ("uses_easeOutCubic", has("easeOutCubic")),
            ("uses_280ms_duration", has_regex(r"(?:milliseconds\s*:\s*280|Duration\s*\(\s*milliseconds\s*:\s*280)", "280ms")),
            ("removes_v1_start_end_doubles", lacks_regex(r"\bstart\s*:\s*[0-9]", "start: <number>")),
        ],
    },
    "eval-2-fix-glitches": {
        "file": "buggy_page.dart",
        "checks": [
            ("clamps_anim_value_in_transitionBuilder", has_regex(r"\.clamp\s*\(\s*0(?:\.0)?\s*,\s*1(?:\.0)?\s*\)", ".clamp(0, 1)")),
            ("addresses_content_clipping", has_regex(r"BottomBarScope|padding[^,]*[Bb]ottom[^,]*[0-9]{2,}|EdgeInsets\.[^,]*bottom[^,]*[0-9]{2,}|fromLTRB", "spacer/padding")),
            ("uses_predicate_to_filter_scrolls", has("predicate")),
            ("filters_by_depth", has_regex(r"depth\s*[><=]", "n.depth > 0")),
        ],
    },
    "eval-3-greenfield": {
        "file": "articles_page.dart",
        "checks": [
            ("imports_package", has("package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart")),
            ("converts_to_StatefulWidget", has("StatefulWidget")),
            ("uses_BottomBar_widget", has_regex(r"\bBottomBar\s*\(", "BottomBar(")),
            ("uses_BottomBarItem_for_three_tabs", has_regex(r"BottomBarItem|TabBar|_TabItem", "tab item widget")),
            ("references_three_tab_labels", has_all("Home", "Search", "Profile")),
            ("uses_iOS_native_motion", has_regex(r"BottomBarMotion(?:\.cupertino|\(\))|CupertinoMotion", "BottomBarMotion.cupertino or default()")),
            ("does_not_use_v1_builder", lacks_regex(r"body:\s*\(\s*context\s*,\s*\w+\)\s*=>", "(context, controller) =>")),
            ("does_not_pass_scrollController_to_BottomBar", lacks_regex(r"BottomBar\s*\([^)]*scrollController\s*:", "scrollController: ...")),
            ("has_state_index_field", has_regex(r"int\s+_(?:index|currentIndex|tabIndex|selectedIndex)\s*=\s*0", "int _index = 0;")),
        ],
    },
}

results = {}
for eval_name, spec in ASSERTIONS.items():
    for cfg in ("with_skill", "without_skill"):
        path = WS / eval_name / cfg / "outputs" / spec["file"]
        text = read(path)
        expectations = []
        for check_name, predicate in spec["checks"]:
            passed, evidence = predicate(text)
            expectations.append({"text": check_name, "passed": passed, "evidence": evidence})
        run_id = f"{eval_name}-{cfg}"
        passed_count = sum(1 for e in expectations if e["passed"])
        total_count = len(expectations)
        results[run_id] = {
            "passed": passed_count,
            "total": total_count,
            "pass_rate": passed_count / total_count if total_count else 0.0,
            "expectations": expectations,
        }
        # write grading.json
        grading_path = WS / eval_name / cfg / "grading.json"
        grading_path.write_text(json.dumps({
            "expectations": expectations,
            "summary": {"passed": passed_count, "total": total_count}
        }, indent=2))

# Print summary
print(f"{'run':<55} {'pass':>5}  {'rate':>5}")
print("-" * 75)
for run_id, r in sorted(results.items()):
    print(f"{run_id:<55} {r['passed']:>2}/{r['total']:<2}  {r['pass_rate']:.0%}")
print()
# Aggregate by config
ws_total = sum(r["passed"] for k, r in results.items() if "with_skill" in k)
ws_max = sum(r["total"] for k, r in results.items() if "with_skill" in k)
no_total = sum(r["passed"] for k, r in results.items() if "without_skill" in k)
no_max = sum(r["total"] for k, r in results.items() if "without_skill" in k)
print(f"with_skill aggregate:    {ws_total}/{ws_max}  ({ws_total/ws_max:.0%})")
print(f"without_skill aggregate: {no_total}/{no_max}  ({no_total/no_max:.0%})")

from pathlib import Path


ROOT = next(
    parent
    for parent in Path(__file__).resolve().parents
    if (parent / "pubspec.yaml").is_file() and (parent / "lib" / "main.dart").is_file()
)
REPORT_DIR = ROOT / "docs" / "final_report"
REQUIRED = [
    "BSc Project Proposal.pdf",
    "contextual-report.pdf",
    "sample_report.pdf",
    "Smart_Study_Reflective_Report.pdf",
    "Guidelines - Thesis Report/CIS017-3 Session 3 Final report_11.3.26_LHW (1).pptx",
    "Guidelines - Thesis Report/Final report etc.pptx",
    "Guidelines - Thesis Report/Guidelines - Thesis Report.doc",
    "Guidelines - Thesis Report/Session Three - Guidelines -2026.pdf",
    "Guidelines - Thesis Report/Writing your Final Report_GC.ppt",
]


def main() -> int:
    missing = []
    print(f"Report source directory: {REPORT_DIR}")
    for relative in REQUIRED:
        state = "OK" if (REPORT_DIR / relative).is_file() else "MISSING"
        print(f"[{state}] {relative}")
        if state == "MISSING":
            missing.append(relative)
    screenshots = [p for p in (REPORT_DIR / "project screenshots").glob("*") if p.is_file()]
    print(f"[INFO] Project screenshots: {len(screenshots)}")
    if missing:
        print(f"Coverage failed: {len(missing)} required source(s) missing.")
        return 1
    print("Coverage passed: all required report sources are present.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3

import json
import traceback
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, jsonify, request

# ----------------------------------------------------------------------
# TrustCircle ONLY
# InvestigatorAI is intentionally NOT imported.
# ----------------------------------------------------------------------

# TrustCircle is a standalone application.
# Resolve everything from the repository root, never from InvestigatorAI.
TRUSTCIRCLE_ROOT = Path(__file__).resolve().parents[1]

app = Flask("trustcircle_service")

TC = None
LOAD_ERROR = None


def load_trustcircle():
    global TC, LOAD_ERROR

    try:
        from trustcircle import trustcircle_integration as tc

        # Force the production adapter to initialize now.
        # This verifies the production artifact before accepting requests.
        smoke_report = {
            "case_id": "TC-SERVICE-BOOT",
            "claim": "The company has no connection with the sanctioned entity.",
            "modus": "The company has no connection with the sanctioned entity.",
            "statement": "The company has no connection with the sanctioned entity.",
            "ocr_text": (
                "Official registry evidence shows the company is connected "
                "to the sanctioned entity."
            ),
            "document_text": (
                "Official registry evidence shows the company is connected "
                "to the sanctioned entity."
            ),
            "evidence": [
                {
                    "type": "document",
                    "text": (
                        "Official registry evidence shows the company is "
                        "connected to the sanctioned entity."
                    ),
                }
            ],
        }

        result = tc.run_trustcircle(smoke_report)

        if result.get("status") != "CLAIM_EVIDENCE_ASSESSED":
            raise RuntimeError(
                "TrustCircle boot inference failed: "
                + str(result.get("status"))
            )

        if result.get("error"):
            raise RuntimeError(
                "TrustCircle boot inference returned error: "
                + str(result.get("error"))
            )

        if not result.get("final_xgboost"):
            raise RuntimeError("Final XGBoost result missing")

        features = result.get("features") or {}
        if len(features) != 20:
            raise RuntimeError(
                f"Expected 20 features, received {len(features)}"
            )

        TC = tc
        LOAD_ERROR = None

        print("[TrustCircle] SERVICE LOAD: PASS")
        print("[TrustCircle] Production adapter: PASS")
        print("[TrustCircle] NLI V3: PASS")
        print("[TrustCircle] Final XGBoost: PASS")
        print("[TrustCircle] 20-feature contract: PASS")
        print("[TrustCircle] Person verdict gate: "
              + str(result.get("person_verdict")))

    except Exception as exc:
        TC = None
        LOAD_ERROR = f"{type(exc).__name__}: {exc}"
        print("[TrustCircle] SERVICE LOAD: FAIL")
        traceback.print_exc()


load_trustcircle()


@app.get("/health")
def health():
    return jsonify({
        "service": "TrustCircle",
        "version": "TrustCircle Hybrid V1",
        "status": "healthy" if TC is not None else "error",
        "production_artifact": str(
            TRUSTCIRCLE_ROOT / "artifacts" / "trustcircle_nli_v3"
        ),
        "investigator_ai_dependency": False,
        "person_verdict": "GATED",
        "error": LOAD_ERROR,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }), (200 if TC is not None else 503)


@app.get("/api/trustcircle/health")
def api_health():
    return health()


@app.post("/api/trustcircle/analyze")
def analyze():
    if TC is None:
        return jsonify({
            "status": "ERROR",
            "error": LOAD_ERROR,
        }), 503

    payload = request.get_json(silent=True)

    if not isinstance(payload, dict):
        return jsonify({
            "status": "ERROR",
            "error": "JSON object required",
        }), 400

    claim = (
        payload.get("claim")
        or payload.get("statement")
        or payload.get("modus")
        or ""
    ).strip()

    if not claim:
        return jsonify({
            "status": "ERROR",
            "error": "claim is required",
        }), 400

    evidence = payload.get("evidence", [])

    if isinstance(evidence, str):
        evidence = [{
            "type": "text",
            "text": evidence,
        }]

    if not isinstance(evidence, list):
        return jsonify({
            "status": "ERROR",
            "error": "evidence must be a list or string",
        }), 400

    report_data = {
        "case_id": payload.get("case_id", "TRUSTCIRCLE-API"),
        "claim": claim,
        "statement": claim,
        "modus": claim,
        "evidence": evidence,

        # Preserve explicit text fields if supplied.
        "ocr_text": payload.get("ocr_text", ""),
        "document_text": payload.get("document_text", ""),
    }

    try:
        result = TC.run_trustcircle(report_data)

        # Explicitly expose the policy gate.
        result["service"] = "TrustCircle"
        result["investigator_ai_dependency"] = False
        result["timestamp"] = datetime.now(timezone.utc).isoformat()

        return jsonify(result), 200

    except Exception as exc:
        traceback.print_exc()

        return jsonify({
            "status": "ERROR",
            "service": "TrustCircle",
            "error": f"{type(exc).__name__}: {exc}",
            "person_verdict": None,
        }), 500


@app.get("/")
def root():
    return jsonify({
        "service": "TrustCircle",
        "version": "TrustCircle Hybrid V1",
        "status": "running" if TC is not None else "error",
        "endpoints": [
            "/health",
            "/api/trustcircle/health",
            "/api/trustcircle/analyze",
        ],
        "investigator_ai_dependency": False,
    })


if __name__ == "__main__":
    print("=" * 78)
    print("TRUSTCIRCLE STANDALONE PRODUCTION SERVICE")
    print("=" * 78)
    print("Bind       : 127.0.0.1:5002")
    print("InvestigatorAI dependency: FALSE")
    print("TrustCircle root:", TRUSTCIRCLE_ROOT)
    print("=" * 78)

    app.run(
        host="127.0.0.1",
        port=5002,
        debug=False,
        threaded=True,
    )

# -*- coding: utf-8 -*-
"""
TrustCircle Hybrid V1 production adapter.

IMPORTANT:
- Does not modify InvestigatorAI's existing deception/risk/verdict fields.
- Writes only report_data["trustcircle"].
- Does not fabricate unavailable evidence.
- Does not issue person-level trust/lied verdicts by itself.
"""

from __future__ import annotations

import json
import math
import re
import hashlib
from pathlib import Path
# Canonical verified TrustCircle Hybrid V1 release
# TrustCircle production artifacts live inside this standalone repository.
# File:
#   <repo>/src/trustcircle/trustcircle_integration.py
# Therefore parents[2] resolves to:
#   <repo>/
TRUSTCIRCLE_RELEASE_ROOT = Path(__file__).resolve().parents[2]

# TrustCircle NLI runtime state
_NLI_TOKENIZER = None
_NLI_MODEL = None


from typing import Any, Dict, List, Tuple

try:
    import numpy as np
except Exception:
    np = None

try:
    import xgboost as xgb
except Exception:
    xgb = None

try:
    import torch
    from transformers import (
        AutoConfig,
        AutoTokenizer,
        AutoModelForSequenceClassification,
    )
except Exception:
    torch = None
    AutoConfig = None
    AutoTokenizer = None
    AutoModelForSequenceClassification = None


# Standalone TrustCircle repository root.
ROOT = TRUSTCIRCLE_RELEASE_ROOT
RELEASE = TRUSTCIRCLE_RELEASE_ROOT

NLI_DIR = RELEASE / "artifacts" / "trustcircle_nli_v3"
FINAL_DIR = RELEASE / "artifacts" / "trustcircle_final_xgboost"
VERIFY_FILE = RELEASE / "verification" / "hybrid_v1_verification.json"


FINAL_FEATURES = [
    "evidence_count",
    "unique_page_count",
    "has_evidence",
    "has_multiple_pages",
    "has_multiple_evidence",
    "total_evidence_characters",
    "average_evidence_sentence_length",
    "minimum_evidence_sentence_length",
    "maximum_evidence_sentence_length",
    "claim_word_count",
    "evidence_claim_length_ratio",
    "lexical_overlap_count",
    "lexical_overlap_ratio",
    "claim_negation_count",
    "evidence_negation_count",
    "evidence_positive_count",
    "evidence_page_diversity",
    "nli_entailment_prob",
    "nli_neutral_prob",
    "nli_contradiction_prob",
]


_NLI = None
_TOKENIZER = None
_XGB = None
_VERIFY = None


def _load_verify():
    global _VERIFY
    if _VERIFY is None:
        try:
            with open(VERIFY_FILE, "r", encoding="utf-8") as f:
                _VERIFY = json.load(f)
        except Exception:
            _VERIFY = {}
    return _VERIFY


def _find_file(root: Path, names: Tuple[str, ...]):
    for name in names:
        p = root / name
        if p.exists():
            return p
    for p in root.rglob("*"):
        if p.is_file() and p.name in names:
            return p
    return None


def _load_nli():
    """
    Load TrustCircle NLI V3 production artifact.

    The released checkpoint was trained through the custom TrustCircleNLI
    wrapper. Its backbone keys are stored under `backbone.*`, while the
    standard DeBERTa sequence-classification implementation expects
    `deberta.*`.

    The released NLI checkpoint is a 3-class model:
        0 = entailment
        1 = neutral
        2 = contradiction

    IMPORTANT:
    - Do not modify the checkpoint.
    - Do not require pooler weights.
    - The checkpoint is authoritative.
    """

    global _NLI_TOKENIZER, _NLI_MODEL

    if _NLI_MODEL is not None and _NLI_TOKENIZER is not None:
        return _NLI_TOKENIZER, _NLI_MODEL

    import torch
    from transformers import (
        AutoConfig,
        AutoTokenizer,
        AutoModelForSequenceClassification,
    )
    from safetensors.torch import load_file

    release_root = Path(TRUSTCIRCLE_RELEASE_ROOT)

    nli_root = None

    candidates = [
        release_root / "artifacts" / "trustcircle_nli_v3",
        release_root / "artifacts" / "trustcircle_nli_v3",
    ]

    for candidate in candidates:
        if candidate.exists():
            nli_root = candidate
            break

    if nli_root is None:
        matches = list(
            (release_root / "artifacts").glob("*nli*8000*")
        )
        if matches:
            nli_root = matches[0]

    if nli_root is None:
        raise FileNotFoundError(
            "TrustCircle NLI production artifact directory not found"
        )

    config_path = nli_root / "config.json"
    tokenizer_path = nli_root

    weight_candidates = [
        nli_root / "model.safetensors",
        nli_root / "pytorch_model.bin",
    ]

    weight_path = None
    for p in weight_candidates:
        if p.exists():
            weight_path = p
            break

    if weight_path is None:
        all_weights = list(nli_root.glob("*.safetensors"))
        if all_weights:
            weight_path = all_weights[0]

    if weight_path is None:
        raise FileNotFoundError(
            f"No NLI weights found in {nli_root}"
        )

    print("[TrustCircle] NLI root:", nli_root)
    print("[TrustCircle] NLI weights:", weight_path)

    # ------------------------------------------------------------------
    # Tokenizer
    # ------------------------------------------------------------------
    tokenizer = AutoTokenizer.from_pretrained(
        str(tokenizer_path),
        local_files_only=True,
    )

    # ------------------------------------------------------------------
    # Config
    # ------------------------------------------------------------------
    config = AutoConfig.from_pretrained(
        str(config_path),
        local_files_only=True,
    )

    # TrustCircle NLI is explicitly 3-class.
    config.num_labels = 3
    config.id2label = {
        0: "entailment",
        1: "neutral",
        2: "contradiction",
    }
    config.label2id = {
        "entailment": 0,
        "neutral": 1,
        "contradiction": 2,
    }

    # ------------------------------------------------------------------
    # Instantiate model from config only.
    # No checkpoint loading is performed by Transformers here.
    # ------------------------------------------------------------------
    model = AutoModelForSequenceClassification.from_config(config)

    # ------------------------------------------------------------------
    # Read released weights
    # ------------------------------------------------------------------
    if weight_path.suffix == ".safetensors":
        raw_state = load_file(
            str(weight_path),
            device="cpu",
        )
    else:
        raw_state = torch.load(
            str(weight_path),
            map_location="cpu",
            weights_only=True,
        )

    print("[TrustCircle] Checkpoint tensors:", len(raw_state))

    # ------------------------------------------------------------------
    # Inspect classifier contract
    # ------------------------------------------------------------------
    classifier_weight = None
    classifier_bias = None

    for key in (
        "classifier.weight",
        "classifier.out_proj.weight",
    ):
        if key in raw_state:
            classifier_weight = raw_state[key]
            break

    for key in (
        "classifier.bias",
        "classifier.out_proj.bias",
    ):
        if key in raw_state:
            classifier_bias = raw_state[key]
            break

    if classifier_weight is None:
        raise RuntimeError(
            "TrustCircle NLI checkpoint classifier weights not found"
        )

    print(
        "[TrustCircle] Classifier weight shape:",
        tuple(classifier_weight.shape),
    )

    if tuple(classifier_weight.shape) != (3, 768):
        raise RuntimeError(
            "Unexpected TrustCircle NLI classifier shape: "
            f"{tuple(classifier_weight.shape)}; expected (3, 768)"
        )

    if classifier_bias is not None:
        print(
            "[TrustCircle] Classifier bias shape:",
            tuple(classifier_bias.shape),
        )

        if tuple(classifier_bias.shape) != (3,):
            raise RuntimeError(
                "Unexpected TrustCircle NLI classifier bias shape: "
                f"{tuple(classifier_bias.shape)}; expected (3,)"
            )

    # ------------------------------------------------------------------
    # Remap custom TrustCircle backbone namespace.
    #
    # checkpoint:
    #     backbone.encoder...
    #
    # standard DeBERTa model:
    #     deberta.encoder...
    #
    # Keep classifier.
    # Ignore pooler because it is absent from the released checkpoint.
    # ------------------------------------------------------------------
    state = {}

    for key, value in raw_state.items():

        if key.startswith("backbone."):
            new_key = "deberta." + key[len("backbone."):]

        elif key.startswith("deberta."):
            new_key = key

        elif key.startswith("classifier."):
            new_key = key

        elif key.startswith("pooler."):
            # Released checkpoint does not require pooler.
            # Do not inject or synthesize pooler weights.
            continue

        else:
            # Ignore unrelated wrapper/training tensors.
            continue

        state[new_key] = value

    # ------------------------------------------------------------------
    # Verify that the actual released checkpoint contains the DeBERTa
    # backbone and classifier expected by the model.
    # ------------------------------------------------------------------
    backbone_keys = [
        k for k in state
        if k.startswith("deberta.")
    ]

    classifier_keys = [
        k for k in state
        if k.startswith("classifier.")
    ]

    if not backbone_keys:
        raise RuntimeError(
            "No remapped DeBERTa backbone tensors found in NLI checkpoint"
        )

    if "classifier.weight" not in state:
        raise RuntimeError(
            "classifier.weight missing after checkpoint remapping"
        )

    if "classifier.bias" not in state:
        raise RuntimeError(
            "classifier.bias missing after checkpoint remapping"
        )

    print(
        "[TrustCircle] Remapped backbone tensors:",
        len(backbone_keys),
    )
    print(
        "[TrustCircle] Classifier tensors:",
        len(classifier_keys),
    )

    # ------------------------------------------------------------------
    # IMPORTANT:
    # The released checkpoint has no pooler.* tensors.
    #
    # Therefore we load non-pooler tensors strictly, while allowing the
    # model-created pooler parameters to remain at their initialized values.
    # This is loader compatibility only. No checkpoint weights are changed.
    # ------------------------------------------------------------------
    incompatible = model.load_state_dict(
        state,
        strict=False,
    )

    missing = list(incompatible.missing_keys)
    unexpected = list(incompatible.unexpected_keys)

    print("[TrustCircle] Missing keys:", len(missing))
    print("[TrustCircle] Unexpected keys:", len(unexpected))

    # Only pooler weights are permitted to remain missing.
    bad_missing = [
        k for k in missing
        if not k.startswith("pooler.")
    ]

    if bad_missing:
        preview = bad_missing[:20]
        raise RuntimeError(
            "Unexpected missing NLI weights after remapping: "
            f"{preview}"
        )

    if unexpected:
        raise RuntimeError(
            "Unexpected NLI checkpoint keys after remapping: "
            f"{unexpected[:20]}"
        )

    model = model.to("cpu")
    model.eval()

    # ------------------------------------------------------------------
    # Final architecture sanity checks
    # ------------------------------------------------------------------
    if getattr(model.config, "num_labels", None) != 3:
        raise RuntimeError(
            f"NLI model num_labels={model.config.num_labels}, expected 3"
        )

    final_classifier = getattr(model, "classifier", None)

    if final_classifier is None:
        raise RuntimeError(
            "NLI classifier layer not found"
        )

    final_weight = final_classifier.weight

    if tuple(final_weight.shape) != (3, 768):
        raise RuntimeError(
            "Loaded NLI classifier has unexpected shape: "
            f"{tuple(final_weight.shape)}"
        )

    _NLI_TOKENIZER = tokenizer
    _NLI_MODEL = model

    print(
        "[TrustCircle] NLI V3 loaded successfully "
        "(custom backbone remapped, 3-class classifier, "
        "pooler compatibility handled)"
    )

    return _NLI_TOKENIZER, _NLI_MODEL


def _load_xgb():
    global _XGB

    if _XGB is not None:
        return _XGB

    if xgb is None:
        raise RuntimeError("xgboost unavailable")

    model_file = _find_file(
        FINAL_DIR,
        ("trustcircle_xgboost_final.json",),
    )

    if not model_file:
        candidates = [
            p for p in FINAL_DIR.rglob("*.json")
            if "manifest" not in p.name.lower()
            and "verification" not in p.name.lower()
        ]
        if len(candidates) != 1:
            raise RuntimeError("Final XGBoost model JSON is ambiguous/missing")
        model_file = candidates[0]

    if hashlib.sha256(model_file.read_bytes()).hexdigest() != (
        "5b327026b0656e3d0937c0d4a75bff93556b429b6917ca717cd28398f7c5f58a"
    ):
        raise RuntimeError("Final XGBoost SHA256 mismatch")

    _XGB = xgb.XGBClassifier()
    _XGB.load_model(str(model_file))

    return _XGB


def _clean_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, (list, tuple)):
        return " ".join(_clean_text(x) for x in value if x is not None)
    if isinstance(value, dict):
        parts = []
        for k, v in value.items():
            if k in ("text", "content", "ocr_text", "transcript", "claim", "evidence"):
                parts.append(_clean_text(v))
        return " ".join(parts)
    return str(value).strip()


def _extract_claim(report_data: Dict[str, Any], case_data: Dict[str, Any]) -> str:
    candidates = [
        case_data.get("modus"),
        case_data.get("mo_description"),
        report_data.get("modus"),
        report_data.get("statement"),
        report_data.get("claim"),
    ]

    for c in candidates:
        text = _clean_text(c)
        if text:
            return text

    return ""


def _collect_evidence(report_data: Dict[str, Any], case_data: Dict[str, Any]) -> List[Dict[str, Any]]:
    evidence = []

    def add(kind, value, page=None, source=None):
        text = _clean_text(value)
        if not text:
            return
        evidence.append({
            "type": str(kind),
            "text": text,
            "page": page,
            "source": source,
        })

    # Actual OCR/document material.
    add("ocr", report_data.get("ocr_text"), source="ocr_text")

    ocr = report_data.get("ocr")
    if isinstance(ocr, dict):
        add("ocr", ocr.get("text"), source="report_data.ocr")
        add("document", ocr.get("ocr_text"), source="report_data.ocr")

    # Existing evidence-analysis outputs.
    for key in (
        "evidence_analysis",
        "document_analysis",
        "document",
        "financial",
        "network",
        "vehicle",
    ):
        value = report_data.get(key)
        if isinstance(value, dict):
            for subkey in ("text", "content", "summary", "evidence", "details"):
                if subkey in value:
                    add(key, value[subkey], source=f"report_data.{key}.{subkey}")
        elif isinstance(value, str):
            add(key, value, source=f"report_data.{key}")

    # Existing evidence containers.
    # Accept the production API schema:
    # evidence = [{"type": "...", "text": "..."}]
    # while preserving support for legacy dict/string containers.
    ev = report_data.get("evidence")

    if isinstance(ev, list):
        for index, item in enumerate(ev):
            if isinstance(item, dict):
                text_value = (
                    item.get("text")
                    or item.get("content")
                    or item.get("evidence")
                    or item.get("summary")
                    or ""
                )

                add(
                    item.get("type", "text"),
                    text_value,
                    page=item.get("page"),
                    source=item.get("source")
                    or f"report_data.evidence[{index}]",
                )

            elif isinstance(item, str):
                add(
                    "text",
                    item,
                    source=f"report_data.evidence[{index}]",
                )

    elif isinstance(ev, dict):
        for k, v in ev.items():
            if isinstance(v, (str, list, tuple, dict)):
                add(k, v, source=f"report_data.evidence.{k}")

    elif isinstance(ev, str):
        add(
            "text",
            ev,
            source="report_data.evidence",
        )

    ev2 = case_data.get("evidence")

    if isinstance(ev2, list):
        for index, item in enumerate(ev2):
            if isinstance(item, dict):
                text_value = (
                    item.get("text")
                    or item.get("content")
                    or item.get("evidence")
                    or item.get("summary")
                    or ""
                )

                add(
                    item.get("type", "text"),
                    text_value,
                    page=item.get("page"),
                    source=item.get("source")
                    or f"case_data.evidence[{index}]",
                )

            elif isinstance(item, str):
                add(
                    "text",
                    item,
                    source=f"case_data.evidence[{index}]",
                )

    elif isinstance(ev2, dict):
        for k, v in ev2.items():
            add(k, v, source=f"case_data.evidence.{k}")

    elif isinstance(ev2, str):
        add(
            "text",
            ev2,
            source="case_data.evidence",
        )

    # Remove exact duplicate evidence text.
    unique = []
    seen = set()
    for item in evidence:
        key = item["text"].strip().lower()
        if not key or key in seen:
            continue
        seen.add(key)
        unique.append(item)

    return unique


def _words(text: str):
    return set(
        w.lower()
        for w in re.findall(r"\b[\w\u0900-\u097F]+\b", text)
        if len(w) > 1
    )


def _sentences(text: str):
    parts = re.split(r"(?<=[.!?।])\s+", text.strip())
    return [p.strip() for p in parts if p.strip()]


def _neg_count(text: str):
    return len(
        re.findall(
            r"\b(no|not|never|none|without|false|fake|denied|deny|नहीं|नही|झूठ|गलत)\b",
            text.lower(),
        )
    )


def _positive_count(text: str):
    return len(
        re.findall(
            r"\b(confirmed|verified|true|genuine|valid|supported|evidence|प्रमाणित|सत्य|सही|पुष्टि)\b",
            text.lower(),
        )
    )


def _nli(claim: str, evidence_text: str):
    tokenizer, model = _load_nli()

    enc = tokenizer(
        claim,
        evidence_text,
        return_tensors="pt",
        truncation=True,
        max_length=512,
    )

    with torch.inference_mode():
        out = model(**enc)
        probs = torch.softmax(out.logits, dim=-1)[0].detach().cpu().numpy()

    # Verified TrustCircle mapping:
    # 0 entailment, 1 neutral, 2 contradiction.
    if len(probs) != 3:
        raise RuntimeError(f"Expected 3 NLI probabilities, got {len(probs)}")

    return {
        "entailment": float(probs[0]),
        "neutral": float(probs[1]),
        "contradiction": float(probs[2]),
    }


def _features(claim: str, evidence_items: List[Dict[str, Any]], nli: Dict[str, float]):
    texts = [x["text"] for x in evidence_items]
    evidence_text = " ".join(texts)

    claim_words = _words(claim)
    evidence_words = _words(evidence_text)
    overlap = claim_words & evidence_words

    lengths = [len(_words(x)) for x in texts]
    pages = [
        str(x.get("page"))
        for x in evidence_items
        if x.get("page") is not None
    ]

    evidence_count = len(texts)
    total_chars = len(evidence_text)

    if lengths:
        avg_len = sum(lengths) / len(lengths)
        min_len = min(lengths)
        max_len = max(lengths)
    else:
        avg_len = min_len = max_len = 0

    claim_wc = len(claim_words)

    if claim_wc:
        ratio = total_chars / max(claim_wc, 1)
    else:
        ratio = 0.0

    page_diversity = len(set(pages)) if pages else 0

    return {
        "evidence_count": evidence_count,
        "unique_page_count": page_diversity,
        "has_evidence": int(evidence_count > 0),
        "has_multiple_pages": int(page_diversity > 1),
        "has_multiple_evidence": int(evidence_count > 1),
        "total_evidence_characters": total_chars,
        "average_evidence_sentence_length": avg_len,
        "minimum_evidence_sentence_length": min_len,
        "maximum_evidence_sentence_length": max_len,
        "claim_word_count": claim_wc,
        "evidence_claim_length_ratio": ratio,
        "lexical_overlap_count": len(overlap),
        "lexical_overlap_ratio": (
            len(overlap) / max(len(claim_words), 1)
        ),
        "claim_negation_count": _neg_count(claim),
        "evidence_negation_count": _neg_count(evidence_text),
        "evidence_positive_count": _positive_count(evidence_text),
        "evidence_page_diversity": page_diversity,
        "nli_entailment_prob": nli["entailment"],
        "nli_neutral_prob": nli["neutral"],
        "nli_contradiction_prob": nli["contradiction"],
    }


def _final_xgb(feature_dict: Dict[str, Any]):
    model = _load_xgb()

    vector = np.asarray(
        [[float(feature_dict[name]) for name in FINAL_FEATURES]],
        dtype=np.float32,
    )

    probs = model.predict_proba(vector)[0]
    pred = int(np.argmax(probs))

    labels = {
        0: "entailment",
        1: "neutral",
        2: "contradiction",
    }

    return {
        "class_id": pred,
        "label": labels.get(pred, "unknown"),
        "probabilities": {
            labels.get(i, str(i)): float(p)
            for i, p in enumerate(probs)
        },
    }


def run_trustcircle(
    report_data: Dict[str, Any],
    case_data: Dict[str, Any] | None = None,
) -> Dict[str, Any]:
    """
    Main production entry point.

    Returns a namespaced result. It never mutates the old InvestigatorAI
    deception/risk/verdict fields.
    """

    case_data = case_data or {}

    result = {
        "status": "NOT_RUN",
        "version": "TrustCircle Hybrid V1",
        "architecture": "CLAIM_EVIDENCE_NLI_XGB",
        "claim": "",
        "evidence": [],
        "nli": None,
        "features": None,
        "final_xgboost": None,
        "person_verdict": None,
        "policy": {
            "single_model_verdict": False,
            "requires_claim_evidence": True,
            "requires_reasoning": True,
            "requires_trust_intelligence": True,
            "requires_verification": True,
        },
        "error": None,
    }

    try:
        claim = _extract_claim(report_data, case_data)
        evidence = _collect_evidence(report_data, case_data)

        result["claim"] = claim
        result["evidence"] = evidence

        # No fabricated evidence and no model-only verdict.
        if not claim:
            result["status"] = "INSUFFICIENT_CLAIM"
            return result

        if not evidence:
            result["status"] = "INSUFFICIENT_EVIDENCE"
            return result

        evidence_text = "\n".join(x["text"] for x in evidence)

        nli_result = _nli(claim, evidence_text)
        feature_dict = _features(claim, evidence, nli_result)
        xgb_result = _final_xgb(feature_dict)

        result["status"] = "CLAIM_EVIDENCE_ASSESSED"
        result["nli"] = nli_result
        result["features"] = feature_dict
        result["final_xgboost"] = xgb_result

        # Deliberately no person-level verdict here.
        result["person_verdict"] = None

        return result

    except Exception as exc:
        result["status"] = "ERROR"
        result["error"] = f"{type(exc).__name__}: {exc}"
        return result

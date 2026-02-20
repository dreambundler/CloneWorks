from __future__ import annotations
from typing import Any, Dict

def plan_to_comfy_workflow(plan: Dict[str, Any]) -> Dict[str, Any]:
    """
    Convert our neutral plan into a ComfyUI workflow JSON.
    Stub for now: you will map steps to your real workflow graph later.
    """
    return {
        "meta": {"source": "cloneworks", "planId": plan.get("planId")},
        "steps": plan.get("steps", [])
    }

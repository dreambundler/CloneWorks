from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Dict, List
import uuid

@dataclass
class PlanStep:
    name: str
    params: Dict[str, Any]

def build_plan(request: Dict[str, Any]) -> Dict[str, Any]:
    """
    Deterministically convert a request into an execution plan.
    This is intentionally minimal to start—expand as modules stabilize.
    """
    plan_id = f"plan_{uuid.uuid4().hex[:12]}"

    identity = request.get("identity", {})
    steps: List[PlanStep] = []

    # Example: load identity LoRA (if provided)
    if identity.get("lora"):
        steps.append(PlanStep(
            name="load_identity_lora",
            params={
                "lora": identity["lora"],
                "strength": identity.get("strength", 1.0),
                "identity_id": identity.get("id")
            }
        ))

    # Example: render image step
    if request.get("mode") == "image":
        steps.append(PlanStep(
            name="render_image",
            params={
                "style": request.get("style", {}),
                "pose": request.get("pose", {}),
                "garments": request.get("garments", []),
                "output": request.get("output", {})
            }
        ))

    return {
        "planId": plan_id,
        "adapter": "comfyui",
        "steps": [s.__dict__ for s in steps]
    }

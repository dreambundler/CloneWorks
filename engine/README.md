# CloneWorks Engine

The Engine is responsible for turning a structured request into a deterministic execution plan.

## Responsibilities
- Validate requests (schemas + business rules)
- Compose identity + pose + style + garments into a plan
- Produce an execution graph that workers can run (e.g. ComfyUI)

## Folder map
- composer/  -> request validation + planning (deterministic)
- runtime/   -> execute plans (locally or via worker RPC)
- adapters/  -> integrations (ComfyUI, WAN, etc.)
- schemas/   -> JSON Schemas for request + plan
- templates/ -> prompt templates + control presets

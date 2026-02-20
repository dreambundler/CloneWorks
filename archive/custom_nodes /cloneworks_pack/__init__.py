# cloneworks_pack/__init__.py
# Cloneworks – CN Sequencer (ComfyUI >= v0.3.59)
# Folder must be: /home/test/ComfyUI/custom_nodes/cloneworks_pack

print("[cloneworks_pack] Loading CN Sequencer…")

class CNSequencer:
    """
    CN Sequencer (Cloneworks)
    - Sequentially decorates a MODEL with up to 5 ControlNets.
    - Order is guaranteed by slot index: CN1 -> CN2 -> ... -> CN5.
    - Each slot has: ControlNet, Image (hint), Strength, Start, End.
    - Positive/Negative conditioning are passed through unchanged.
    """

    @classmethod
    def INPUT_TYPES(s):
        inputs = {
            "required": {
                "model": ("MODEL",),
                "cond_pos": ("CONDITIONING",),
                "cond_neg": ("CONDITIONING",),
            },
            "optional": {}
        }

        # Define 5 ControlNet slots
        for i in range(1, 6):
            inputs["optional"].update({
                f"controlnet{i}": ("CONTROL_NET",),
                f"image{i}": ("IMAGE",),
                f"strength{i}": ("FLOAT", {
                    "default": 1.0, "min": 0.0, "max": 2.0, "step": 0.05
                }),
                f"start{i}": ("FLOAT", {
                    "default": 0.0, "min": 0.0, "max": 1.0, "step": 0.01
                }),
                f"end{i}": ("FLOAT", {
                    "default": 1.0, "min": 0.0, "max": 1.0, "step": 0.01
                }),
            })
        return inputs

    RETURN_TYPES = ("MODEL", "CONDITIONING", "CONDITIONING")
    RETURN_NAMES = ("model", "cond_pos", "cond_neg")
    FUNCTION = "apply"
    CATEGORY = "Cloneworks"

    def apply(self, model, cond_pos, cond_neg, **kwargs):
        """
        Apply CN slots 1..5 in order if both ControlNet and Image are provided.
        """
        new_model = model

        for i in range(1, 6):
            cn = kwargs.get(f"controlnet{i}", None)
            img = kwargs.get(f"image{i}", None)
            w  = kwargs.get(f"strength{i}", 1.0)
            s  = kwargs.get(f"start{i}", 0.0)
            e  = kwargs.get(f"end{i}", 1.0)

            # Only apply if both CN + image are connected
            if cn is not None and img is not None:
                try:
                    print(f"[CN Sequencer] Slot {i}: weight={w}, range=({s}-{e})")
                    # Native ComfyUI ControlNet API: decorate model
                    new_model = cn.add_controlnet(
                        new_model,
                        img,
                        weight=w,
                        start_percent=s,
                        end_percent=e
                    )
                except Exception as ex:
                    # Fail safe: skip broken slot, continue others
                    print(f"[CN Sequencer] Slot {i} failed: {ex}")

        return (new_model, cond_pos, cond_neg)


# Required mappings for ComfyUI to register the node
NODE_CLASS_MAPPINGS = {
    "CNSequencer": CNSequencer,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "CNSequencer": "CN Sequencer",
}

print("[cloneworks_pack] CN Sequencer registered.")



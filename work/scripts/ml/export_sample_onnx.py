#!/usr/bin/env python3
"""
Export a tiny PyTorch MLP to ONNX for SPOTS app testing.

Produces model.onnx with:
- input name: "input"  shape: [N, 4] (float32)
- output name: "output" shape: [N, 3] (float32)

Usage:
  python scripts/ml/export_sample_onnx.py --out assets/models/default.onnx
"""
import argparse
import os
import torch
import torch.nn as nn


class MLP(nn.Module):
    def __init__(self) -> None:
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(4, 16),
            nn.ReLU(),
            nn.Linear(16, 3),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="model.onnx", help="Output ONNX file path")
    parser.add_argument("--opset", type=int, default=17, help="ONNX opset version")
    args = parser.parse_args()

    model = MLP().eval()
    dummy = torch.randn(1, 4, dtype=torch.float32)

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)

    torch.onnx.export(
        model,
        dummy,
        args.out,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={"input": {0: "batch"}, "output": {0: "batch"}},
        opset_version=args.opset,
    )
    print(f"Wrote ONNX model to: {args.out}")


if __name__ == "__main__":
    main()



import argparse
import json
from pathlib import Path

import torch
import torchvision.transforms as standard_transforms
from PIL import Image, ImageDraw

from models import build_model


class Args:
    def __init__(self, backbone='vgg16_bn', row=2, line=2, pretrained_backbone=False):
        self.backbone = backbone
        self.row = row
        self.line = line
        self.pretrained_backbone = pretrained_backbone


def parse_args():
    parser = argparse.ArgumentParser(description='Run P2PNet inference on a single image.')
    parser.add_argument('--image-path', required=True)
    parser.add_argument('--output-path', required=True)
    parser.add_argument('--weight-path', required=True)
    parser.add_argument('--threshold', type=float, default=0.5)
    parser.add_argument('--device', default='auto', choices=['auto', 'cpu', 'cuda'])
    parser.add_argument('--backbone', default='vgg16_bn')
    parser.add_argument('--row', type=int, default=2)
    parser.add_argument('--line', type=int, default=2)
    return parser.parse_args()


def resolve_device(requested):
    if requested == 'auto':
        return torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    if requested == 'cuda' and not torch.cuda.is_available():
        raise RuntimeError('CUDA requested, but no CUDA device is available.')
    return torch.device(requested)


def load_model(weight_path, device, backbone, row, line):
    model = build_model(Args(backbone=backbone, row=row, line=line, pretrained_backbone=False))
    checkpoint = torch.load(weight_path, map_location='cpu')
    model.load_state_dict(checkpoint['model'])
    model.to(device)
    model.eval()
    return model


def preprocess_image(image_path):
    img_raw = Image.open(image_path).convert('RGB')
    original_width, original_height = img_raw.size
    resized_width = max(128, original_width // 128 * 128)
    resized_height = max(128, original_height // 128 * 128)

    resized = img_raw.resize((resized_width, resized_height), Image.Resampling.LANCZOS)
    transform = standard_transforms.Compose([
        standard_transforms.ToTensor(),
        standard_transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    tensor = transform(resized).unsqueeze(0)
    return img_raw, resized, tensor


@torch.no_grad()
def infer(model, tensor, threshold, device):
    outputs = model(tensor.to(device))
    scores = torch.nn.functional.softmax(outputs['pred_logits'], -1)[:, :, 1][0]
    points = outputs['pred_points'][0]
    selected_points = points[scores > threshold].detach().cpu().numpy()
    count = int((scores > threshold).sum())
    return selected_points, count


def draw_points(image, points):
    annotated = image.copy()
    draw = ImageDraw.Draw(annotated)
    radius = 2
    for x, y in points:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(255, 0, 0))
    return annotated


def main():
    args = parse_args()
    output_path = Path(args.output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    device = resolve_device(args.device)
    model = load_model(args.weight_path, device, args.backbone, args.row, args.line)
    _original, resized_image, tensor = preprocess_image(args.image_path)
    points, count = infer(model, tensor, args.threshold, device)
    annotated = draw_points(resized_image, points)
    annotated.save(output_path)

    payload = {
        'count': count,
        'annotated_image_path': str(output_path.resolve()),
        'points': points.tolist(),
        'threshold': args.threshold,
        'device': str(device),
        'input_image_path': str(Path(args.image_path).resolve()),
        'weight_path': str(Path(args.weight_path).resolve()),
        'resized_width': resized_image.size[0],
        'resized_height': resized_image.size[1],
    }
    print(json.dumps(payload))


if __name__ == '__main__':
    main()

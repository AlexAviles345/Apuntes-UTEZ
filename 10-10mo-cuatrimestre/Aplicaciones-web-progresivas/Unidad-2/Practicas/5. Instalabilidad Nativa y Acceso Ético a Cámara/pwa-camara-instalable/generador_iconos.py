from PIL import Image, ImageDraw
for s in (192, 512):
    img = Image.new("RGB", (s, s), "#0d6efd")
    d = ImageDraw.Draw(img)
    m = s // 4
    d.ellipse([m, m, s - m, s - m], fill="white")
    d.ellipse([s*0.38, s*0.38, s*0.62, s*0.62], fill="#0d6efd")
    img.save(f"icons/icon-{s}.png")
# Gera o icone provisorio do Rastro: fundo escuro do tema (#0B0D12) e um
# trajeto em lima (#C6F432) com cantos, como uma rota no mapa, com inicio
# (ponto) e fim (alvo). Provisorio ate a marca ser escolhida (relatorio 11).
# Uso, dentro de app/: python tool/icon/gen_icon.py  (precisa do Pillow)
# Gera todos os tamanhos do AppIcon do iOS (sem transparencia) e os
# ic_launcher do Android.
import json
from PIL import Image, ImageDraw
N = 4096
BG = (0x0B, 0x0D, 0x12)
LIME = (0xC6, 0xF4, 0x32)
img = Image.new('RGB', (N, N), BG)
d = ImageDraw.Draw(img)
pts = [(0.29, 0.76), (0.51, 0.76), (0.51, 0.52), (0.67, 0.52), (0.67, 0.30)]
P = [(x * N, y * N) for x, y in pts]
w = int(0.075 * N)
d.line(P, fill=LIME, width=w, joint='curve')
def disc(c, r, fill):
    d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=fill)
# Pontas arredondadas e inicio.
disc(P[0], 0.075 * N, LIME)
disc(P[0], 0.035 * N, BG)
# Fim: alvo.
disc(P[-1], 0.115 * N, LIME)
disc(P[-1], 0.068 * N, BG)
disc(P[-1], 0.038 * N, LIME)
m = img.resize((1024, 1024), Image.LANCZOS)
base = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
for im in json.load(open(base + 'Contents.json'))['images']:
    s = round(float(im['size'].split('x')[0]) * int(im['scale'][0]))
    m.resize((s, s), Image.LANCZOS).save(base + im['filename'])
for d, s in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    m.resize((s, s), Image.LANCZOS).save(f'android/app/src/main/res/mipmap-{d}/ic_launcher.png')

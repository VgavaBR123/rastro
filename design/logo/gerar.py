"""SVGs autorais e exportação local com Pillow, sem dependências globais.
Execute: python design/logo/gerar.py
O rasterizador cobre apenas M/L/C/Z, retângulos e círculos usados nestas artes.
"""
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
BG, LIME = '#0B0D12', '#C6F432'

def svg(name, body, w=1024, h=1024):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" role="img" aria-label="{name}">
  <title>{name}</title>
  <rect width="{w}" height="{h}" fill="{BG}"/>
{body}
</svg>
'''

# Coordenadas e curvas desenhadas manualmente; nenhum símbolo de biblioteca.
route = '''  <path d="M 286 738 L 286 426 C 286 324 352 270 450 270 L 608 270 C 700 270 744 322 744 390 C 744 466 692 510 608 510 L 486 510 C 438 510 424 554 458 588 L 606 736" fill="none" stroke="#C6F432" stroke-width="100" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="744" cy="736" r="50" fill="#C6F432"/>'''
ribbon = '''  <path d="M 280 232 L 658 232 C 746 232 792 292 792 376 L 792 650 C 792 738 732 792 644 792 L 366 792 C 278 792 232 736 232 650 L 232 302 C 232 260 250 232 280 232 Z" fill="#C6F432"/>
  <path d="M 336 824 L 336 642 C 336 548 384 492 478 492 L 554 492 C 634 492 686 440 686 354 L 686 204" fill="none" stroke="#0B0D12" stroke-width="96" stroke-linecap="round"/>
  <circle cx="544" cy="680" r="48" fill="#0B0D12"/>'''
echo = '''  <path d="M 268 690 C 232 526 288 354 420 262" fill="none" stroke="#C6F432" stroke-width="100" stroke-linecap="round"/>
  <path d="M 470 742 C 416 598 458 448 580 366" fill="none" stroke="#C6F432" stroke-width="100" stroke-linecap="round"/>
  <path d="M 672 748 C 628 656 650 554 744 492" fill="none" stroke="#C6F432" stroke-width="100" stroke-linecap="round"/>'''
concepts = [('01-dobra', 'Rastro — Dobra', route), ('02-passagem', 'Rastro — Passagem', ribbon), ('03-vestigios', 'Rastro — Vestígios', echo)]
for filename, title, body in concepts:
    (OUT / f'{filename}.svg').write_text(svg(title, body), encoding='utf-8')

# Lettering próprio em traços: R a s t r o. Não requer fontes instaladas.
letters = '''<g fill="none" stroke="#F4F6FA" stroke-width="23" stroke-linecap="round" stroke-linejoin="round">
<path d="M 496 312 L 496 150 L 551 150 C 608 150 608 230 551 230 L 496 230 M 550 230 L 602 312"/>
<path d="M 710 213 C 646 185 625 222 625 260 C 625 305 654 329 710 298 M 710 210 L 710 312"/>
<path d="M 823 214 C 762 190 735 228 775 250 L 799 261 C 843 283 811 330 752 305"/>
<path d="M 875 171 L 875 282 C 875 307 888 319 912 307 M 848 213 L 913 213"/>
<path d="M 953 312 L 953 213 M 953 245 C 962 220 982 207 1005 213"/>
<path d="M 1080 208 C 1015 208 1015 314 1080 314 C 1145 314 1145 208 1080 208 Z"/>
</g>'''
(OUT / 'rastro-completo.svg').write_text(svg('Rastro — assinatura Dobra', '<g transform="translate(28 24) scale(0.42)">'+route+'</g>\n'+letters, 1220, 480), encoding='utf-8')

def render(path, size):
    root = ET.parse(path).getroot()
    scale = size / float(root.attrib['width'])
    im = Image.new('RGB', (size, size), BG)
    d = ImageDraw.Draw(im)
    for el in root:
        tag = el.tag.split('}')[-1]
        a = el.attrib
        if tag == 'circle':
            x,y,r = [float(a[k])*scale for k in ('cx','cy','r')]
            d.ellipse((x-r,y-r,x+r,y+r), fill=a['fill'])
        if tag != 'path':
            continue
        tokens = re.findall(r'[MLCZ]|-?\d+(?:\.\d+)?', a['d'])
        pts=[]; i=0; current=(0,0)
        while i < len(tokens):
            op=tokens[i]; i+=1
            if op in ('M','L'):
                current=tuple(float(v) for v in tokens[i:i+2]); i+=2
                pts.append(current)
            elif op == 'C':
                p0=current
                p1,p2,p3=[tuple(float(v) for v in tokens[j:j+2]) for j in (i,i+2,i+4)]; i+=6
                for step in range(1,129):
                    t=step/128; u=1-t
                    pts.append(tuple(u**3*p0[k]+3*u*u*t*p1[k]+3*u*t*t*p2[k]+t**3*p3[k] for k in (0,1)))
                current=p3
            elif op == 'Z':
                pts.append(pts[0])
        pts=[(x*scale,y*scale) for x,y in pts]
        if a.get('fill','none') != 'none':
            d.polygon(pts, fill=a['fill'])
        if 'stroke' in a:
            width=round(float(a['stroke-width'])*scale)
            d.line(pts, fill=a['stroke'], width=width)
            # Discos nas amostras eliminam lacunas do rasterizador em curvas grossas.
            r=width/2
            for x,y in pts[1:-1]:
                d.ellipse((x-r,y-r,x+r,y+r), fill=a['stroke'])
            if a.get('stroke-linecap') == 'round':
                r=width/2
                for x,y in (pts[0],pts[-1]):
                    d.ellipse((x-r,y-r,x+r,y+r), fill=a['stroke'])
    return im

sheet=Image.new('RGB',(1200,520), BG)
draw=ImageDraw.Draw(sheet)
for index,(filename,title,_) in enumerate(concepts):
    im=render(OUT/f'{filename}.svg',3072).resize((1024,1024),Image.Resampling.LANCZOS)
    im.save(OUT/f'{filename}-1024.png')
    x=index*400
    sheet.paste(im.resize((360,360),Image.Resampling.LANCZOS),(x+20,10))
    draw.text((x+28,380), title, fill='#F4F6FA', font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22))
    for j,size in enumerate((24,32,48)):
        sheet.paste(im.resize((size,size),Image.Resampling.LANCZOS),(x+28+j*90,435))
sheet.save(OUT/'comparativo.png')
print('Gerados: 4 SVGs, 3 PNGs 1024 RGB e comparativo.')

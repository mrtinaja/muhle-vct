import base64, os, subprocess
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))

def b64(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("ascii")

LOGO_WHITE = b64(os.path.join(BASE, "logo_white_text.png"))
LOGO_BORDO = b64(os.path.join(BASE, "logo_bordo_text.png"))

COMMON_CSS = """
* { margin:0; padding:0; box-sizing:border-box; }
@import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@500;700;800&display=swap');
html,body { width:600px; height:220px; overflow:hidden; font-family:'Montserrat','Segoe UI',Arial,sans-serif; }
.banner { position:relative; width:600px; height:220px; }
.pattern {
  position:absolute; inset:0; overflow:hidden; pointer-events:none;
}
.pattern svg { position:absolute; }
"""

def v_pattern_svg(color, opacity, w=600, h=90, size=30):
    # Build repeating V (chevron) motif matching the brand pattern
    cols = int(w/size)+2
    paths = []
    for row in range(2):
        y0 = row*size*0.6
        for c in range(cols):
            x = c*size
            paths.append(f'<path d="M{x} {y0} L{x+size/2} {y0+size*0.7} L{x+size} {y0}" stroke="{color}" stroke-width="{size*0.26}" fill="none" stroke-linecap="round"/>')
    return f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg" opacity="{opacity}">{"".join(paths)}</svg>'

BANNERS = {}

# 1) BIENVENIDA - bordo bg, white logo, big title
BANNERS["banner_bienvenida"] = f"""
<html><head><style>{COMMON_CSS}
.b1 {{ background:#66062D; }}
.b1 .patternTop {{ top:0; left:0; transform:translateY(-46px); }}
.b1 .content {{ position:relative; z-index:2; height:100%; display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center; padding:0 40px; }}
.b1 img.logo {{ height:26px; margin-bottom:18px; opacity:.96; }}
.b1 h1 {{ color:#FFFFFF; font-size:28px; font-weight:800; letter-spacing:.2px; margin-bottom:8px; }}
.b1 p {{ color:#F3D9E2; font-size:13px; font-weight:500; letter-spacing:.3px; }}
</style></head>
<body>
<div class="banner b1">
  <div class="pattern patternTop">{v_pattern_svg('#FFFFFF', 0.07)}</div>
  <div class="content">
    <img class="logo" src="data:image/png;base64,{LOGO_WHITE}">
    <h1>&iexcl;Bienvenido a Vocaturo!</h1>
    <p>Tu plataforma de gesti&oacute;n de servicios profesionales</p>
  </div>
</div>
</body></html>
"""

# 2) RECORDATORIO DE TURNO - soft pink bg, bordo accent bar left, bordo logo
BANNERS["banner_recordatorio"] = f"""
<html><head><style>{COMMON_CSS}
.b2 {{ background:#F7EAF0; }}
.b2 .bar {{ position:absolute; top:0; left:0; bottom:0; width:10px; background:#66062D; }}
.b2 .content {{ position:relative; z-index:2; height:100%; display:flex; align-items:center; padding:0 46px 0 56px; gap:26px; }}
.b2 .icon {{ flex:0 0 auto; width:64px; height:64px; border-radius:999px; background:#66062D; display:flex; align-items:center; justify-content:center; }}
.b2 .icon svg {{ width:30px; height:30px; }}
.b2 .text {{ flex:1; }}
.b2 img.logo {{ height:15px; margin-bottom:12px; opacity:.9; }}
.b2 h1 {{ color:#333233; font-size:23px; font-weight:800; margin-bottom:6px; }}
.b2 p {{ color:#66062D; font-size:13px; font-weight:600; }}
</style></head>
<body>
<div class="banner b2">
  <div class="bar"></div>
  <div class="content">
    <div class="icon">
      <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="5" width="18" height="16" rx="2" stroke="#FFFFFF" stroke-width="1.8"/><path d="M3 9H21" stroke="#FFFFFF" stroke-width="1.8"/><path d="M7 3V6" stroke="#FFFFFF" stroke-width="1.8" stroke-linecap="round"/><path d="M17 3V6" stroke="#FFFFFF" stroke-width="1.8" stroke-linecap="round"/><circle cx="12" cy="14.5" r="2.3" stroke="#FFFFFF" stroke-width="1.6"/></svg>
    </div>
    <div class="text">
      <img class="logo" src="data:image/png;base64,{LOGO_BORDO}">
      <h1>Recordatorio de turno</h1>
      <p>Ten&eacute;s una actividad agendada pr&oacute;ximamente</p>
    </div>
  </div>
</div>
</body></html>
"""

# 3) CONFIRMACION - dark bg, bordo accent, check icon
BANNERS["banner_confirmacion"] = f"""
<html><head><style>{COMMON_CSS}
.b3 {{ background:#333233; }}
.b3 .accent {{ position:absolute; top:0; right:0; bottom:0; width:190px; background:#66062D; clip-path:polygon(38% 0,100% 0,100% 100%,0% 100%); }}
.b3 .patternR {{ top:0; right:-10px; width:220px; transform:rotate(90deg) translate(0,-190px); }}
.b3 .content {{ position:relative; z-index:2; height:100%; display:flex; flex-direction:column; align-items:flex-start; justify-content:center; padding:0 0 0 48px; }}
.b3 img.logo {{ width:auto; display:block; }}
.b3 .check {{ width:46px; height:46px; border-radius:999px; background:#FFFFFF; display:flex; align-items:center; justify-content:center; margin-bottom:16px; }}
.b3 .check svg {{ width:22px; height:22px; }}
.b3 img.logo {{ height:14px; margin-bottom:10px; opacity:.85; }}
.b3 h1 {{ color:#FFFFFF; font-size:24px; font-weight:800; margin-bottom:6px; max-width:330px; }}
.b3 p {{ color:#D9D6D8; font-size:12.5px; font-weight:500; max-width:320px; }}
</style></head>
<body>
<div class="banner b3">
  <div class="accent"></div>
  <div class="content">
    <div class="check"><svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M5 13L9.5 17.5L19 7" stroke="#66062D" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg></div>
    <img class="logo" src="data:image/png;base64,{LOGO_WHITE}">
    <h1>Confirmaci&oacute;n realizada</h1>
    <p>Tu solicitud fue procesada correctamente</p>
  </div>
</div>
</body></html>
"""

# 4) AVISO / NOTIFICACION GENERAL - white bg, bordo top bar, faint pattern
BANNERS["banner_aviso"] = f"""
<html><head><style>{COMMON_CSS}
.b4 {{ background:#FFFFFF; border:1px solid #EFE3E9; }}
.b4 .topbar {{ position:absolute; top:0; left:0; right:0; height:7px; background:#66062D; }}
.b4 .patternBR {{ bottom:-30px; right:-10px; }}
.b4 .content {{ position:relative; z-index:2; height:100%; display:flex; flex-direction:column; align-items:flex-start; justify-content:center; padding:0 46px; }}
.b4 img.logo {{ height:15px; margin-bottom:16px; }}
.b4 .badge {{ display:inline-block; background:#F7EAF0; color:#66062D; font-size:10.5px; font-weight:800; letter-spacing:.06em; text-transform:uppercase; padding:5px 12px; border-radius:999px; margin-bottom:12px; }}
.b4 h1 {{ color:#333233; font-size:23px; font-weight:800; margin-bottom:4px; }}
.b4 p {{ color:#747780; font-size:12.5px; font-weight:500; }}
</style></head>
<body>
<div class="banner b4">
  <div class="topbar"></div>
  <div class="pattern patternBR">{v_pattern_svg('#66062D', 0.05, w=260, h=140, size=26)}</div>
  <div class="content">
    <img class="logo" src="data:image/png;base64,{LOGO_BORDO}">
    <span class="badge">Notificaci&oacute;n</span>
    <h1>Ten&eacute;s una novedad</h1>
    <p>Revis&aacute; los detalles dentro de la plataforma</p>
  </div>
</div>
</body></html>
"""

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

for name, html in BANNERS.items():
    html_path = os.path.join(BASE, name + ".html")
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html)
    raw_png = os.path.join(BASE, name + "_raw.png")
    subprocess.run([
        CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
        "--force-device-scale-factor=2",
        "--window-size=600,220",
        f"--screenshot={raw_png}",
        "file:///" + html_path.replace("\\", "/")
    ], check=True, capture_output=True)
    img = Image.open(raw_png)
    # crop to exact 1200x440 (2x) top-left in case chrome added extra pixels, then downscale
    img = img.crop((0,0,1200,440)).resize((600,220), Image.LANCZOS)
    final_path = os.path.join(BASE, name + ".png")
    img.save(final_path)
    print(name, "->", final_path, img.size, os.path.getsize(final_path), "bytes")

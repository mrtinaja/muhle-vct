import base64, os, subprocess
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))

def b64(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("ascii")

WORDMARK_WHITE = b64(os.path.join(BASE, "logo_white_text.png"))
WORDMARK_BORDO = b64(os.path.join(BASE, "logo_bordo_text.png"))
ICON_WHITE = b64(os.path.join(BASE, "icon_v_only_white.png"))
ICON_BORDO = b64(os.path.join(BASE, "icon_v_only_bordo.png"))

CSS = """
* { margin:0; padding:0; box-sizing:border-box; }
@import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@700;800&display=swap');
html,body { width:600px; height:90px; overflow:hidden; font-family:'Montserrat','Segoe UI',Arial,sans-serif; }
.banner { position:relative; width:600px; height:90px; display:flex; align-items:center; padding:0 40px; gap:18px; }
.banner img.icon { height:26px; width:auto; display:block; }
.banner .sep { width:1px; align-self:stretch; margin:20px 0; }
.banner img.wordmark { height:22px; width:auto; display:block; }
"""

VARIANTS = [
    ("banner_masthead_bordo", "#66062D", ICON_WHITE, WORDMARK_WHITE, "rgba(255,255,255,.35)", None),
    ("banner_masthead_blanco", "#FFFFFF", ICON_BORDO, WORDMARK_BORDO, "rgba(102,6,45,.22)", "1px solid #EFE3E9"),
    ("banner_masthead_gris", "#333233", ICON_WHITE, WORDMARK_WHITE, "rgba(255,255,255,.28)", None),
]

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

for name, bg, icon, wordmark, sepcolor, border in VARIANTS:
    border_css = f"border:{border};" if border else ""
    html = f"""<html><head><style>{CSS}
    .banner {{ background:{bg}; {border_css} }}
    .sep {{ background:{sepcolor}; }}
    </style></head><body>
    <div class="banner">
      <img class="icon" src="data:image/png;base64,{icon}">
      <span class="sep"></span>
      <img class="wordmark" src="data:image/png;base64,{wordmark}">
    </div>
    </body></html>"""
    html_path = os.path.join(BASE, name + ".html")
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html)
    raw_png = os.path.join(BASE, name + "_raw.png")
    subprocess.run([
        CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
        "--force-device-scale-factor=2",
        "--window-size=600,90",
        f"--screenshot={raw_png}",
        "file:///" + html_path.replace("\\", "/")
    ], check=True, capture_output=True)
    img = Image.open(raw_png)
    img = img.crop((0,0,1200,180))
    final_path = os.path.join(BASE, name + ".png")
    img.save(final_path)
    print(name, "->", final_path, img.size, os.path.getsize(final_path), "bytes")

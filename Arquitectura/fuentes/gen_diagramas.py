"""Genera los SVG de contenedores (C4 nivel 2) y despliegue del Canal Retail (G4)."""
import sys
from html import escape

FONT = "Arial, Helvetica, sans-serif"
AZUL_PERSONA = "#08427b"
AZUL_CONT = "#438dd5"
GRIS_EXT = "#8a8a8a"
LINEA = "#555555"


class Svg:
    def __init__(self, w, h):
        self.w, self.h, self.p = w, h, []

    def add(self, s):
        self.p.append(s)

    def text(self, x, y, lines, size=14, color="#fff", weight="normal", anchor="middle", italic=False, lh=None):
        lh = lh or size * 1.25
        st = ' font-style="italic"' if italic else ""
        for i, ln in enumerate(lines):
            self.add(f'<text x="{x}" y="{y + i * lh:.1f}" font-family="{FONT}" font-size="{size}" '
                     f'fill="{color}" font-weight="{weight}" text-anchor="{anchor}"{st}>{escape(ln)}</text>')

    def caja(self, x, y, w, h, fill, titulo, tipo, desc=(), dashed=False, stroke=None, rx=10, tcolor="#fff"):
        da = ' stroke-dasharray="8 5"' if dashed else ""
        stroke = stroke or fill
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="2"{da}/>')
        cy = y + 30
        self.text(x + w / 2, cy, [titulo], 18, tcolor, "bold")
        self.text(x + w / 2, cy + 20, [tipo], 12, tcolor, italic=True)
        self.text(x + w / 2, cy + 46, list(desc), 13, tcolor)

    def cilindro(self, x, y, w, h, fill, titulo, tipo, desc=()):
        ry = 14
        self.add(f'<path d="M{x},{y + ry} A{w / 2},{ry} 0 0 1 {x + w},{y + ry} V{y + h - ry} '
                 f'A{w / 2},{ry} 0 0 1 {x},{y + h - ry} Z" fill="{fill}" stroke="{fill}" stroke-width="2"/>')
        self.add(f'<ellipse cx="{x + w / 2}" cy="{y + ry}" rx="{w / 2}" ry="{ry}" fill="none" stroke="#2e6aa8" stroke-width="2"/>')
        self.text(x + w / 2, y + 48, [titulo], 18, "#fff", "bold")
        self.text(x + w / 2, y + 68, [tipo], 12, "#fff", italic=True)
        self.text(x + w / 2, y + 92, list(desc), 13, "#fff")

    def persona(self, x, y, w, h, titulo, tipo, desc=()):
        cx = x + w / 2
        self.add(f'<circle cx="{cx}" cy="{y - 28}" r="30" fill="{AZUL_PERSONA}"/>')
        self.caja(x, y, w, h, AZUL_PERSONA, titulo, tipo, desc, rx=30)

    def limite(self, x, y, w, h, titulo, tipo, color="#444"):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="none" stroke="{color}" '
                 f'stroke-width="2" stroke-dasharray="10 6"/>')
        self.text(x + 16, y + h - 34, [titulo], 17, color, "bold", "start")
        self.text(x + 16, y + h - 14, [tipo], 12, color, anchor="start", italic=True)

    def flecha(self, puntos, etiqueta=(), pos=None, dashed=False, color=LINEA, ambos=False, ancho=None):
        d = "M" + " L".join(f"{px},{py}" for px, py in puntos)
        da = ' stroke-dasharray="7 5"' if dashed else ""
        ini = ' marker-start="url(#ini)"' if ambos else ""
        self.add(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="2"{da}{ini} marker-end="url(#fin)"/>')
        if etiqueta:
            if pos is None:
                (x1, y1), (x2, y2) = puntos[len(puntos) // 2 - 1], puntos[len(puntos) // 2]
                pos = ((x1 + x2) / 2, (y1 + y2) / 2)
            lines = list(etiqueta)
            ancho = ancho or max(len(l) for l in lines) * 6.9 + 18
            alto = len(lines) * 16 + 10
            x, y = pos
            self.add(f'<rect x="{x - ancho / 2:.1f}" y="{y - alto / 2:.1f}" width="{ancho:.1f}" height="{alto}" '
                     f'rx="5" fill="#ffffff" stroke="#bbbbbb" stroke-width="1"/>')
            self.text(x, y - alto / 2 + 18, lines, 12.5, "#222", lh=16)

    def render(self, titulo, subtitulo):
        cab = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
               f'viewBox="0 0 {self.w} {self.h}">'
               '<defs>'
               '<marker id="fin" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse">'
               f'<path d="M0,0 L10,5 L0,10 z" fill="{LINEA}"/></marker>'
               '<marker id="ini" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse">'
               f'<path d="M0,0 L10,5 L0,10 z" fill="{LINEA}"/></marker>'
               '</defs>'
               f'<rect width="{self.w}" height="{self.h}" fill="#ffffff"/>')
        enc = []
        enc.append(f'<text x="{self.w / 2}" y="44" font-family="{FONT}" font-size="28" font-weight="bold" '
                   f'fill="#1f2d3d" text-anchor="middle">{escape(titulo)}</text>')
        enc.append(f'<text x="{self.w / 2}" y="72" font-family="{FONT}" font-size="15" fill="#555" '
                   f'text-anchor="middle">{escape(subtitulo)}</text>')
        return cab + "".join(enc) + "".join(self.p) + "</svg>"


def leyenda(s, x, y, items):
    s.add(f'<rect x="{x}" y="{y}" width="290" height="{34 + 30 * len(items)}" rx="8" fill="#fafafa" stroke="#ccc"/>')
    s.text(x + 14, y + 24, ["Leyenda"], 15, "#222", "bold", "start")
    for i, (fill, txt, dashed) in enumerate(items):
        yy = y + 40 + 30 * i
        da = ' stroke-dasharray="5 3"' if dashed else ""
        stroke = "#555" if dashed else fill
        s.add(f'<rect x="{x + 14}" y="{yy}" width="34" height="20" rx="4" fill="{fill}" stroke="{stroke}" stroke-width="1.5"{da}/>')
        s.text(x + 58, yy + 15, [txt], 13, "#222", anchor="start")


def contenedores():
    s = Svg(1840, 1180)
    # Persona
    s.persona(60, 150, 280, 120, "Personal de tienda", "[Persona]", ["Vendedor y supervisor", "en el mostrador"])
    # Limite del sistema
    s.limite(400, 360, 920, 560, "Canal Retail (G4)", "[Sistema: punto de venta en mostrador]")
    s.caja(450, 440, 320, 150, AZUL_CONT, "Web App POS", "[Contenedor: React 19 + TypeScript + Vite]",
           ["SPA del mostrador: venta, cobro,", "caja, pickup, historial y cambios"])
    s.caja(940, 440, 330, 150, AZUL_CONT, "ms-retail", "[Contenedor: Java 21 + Spring Boot 3.5]",
           ["API REST /api/v1/retail/*", "Reglas de mostrador e integraciones"])
    s.cilindro(940, 700, 330, 140, AZUL_CONT, "BD_Retail", "[Contenedor: PostgreSQL en Supabase]",
               ["Turnos, ventas, comprobantes,", "personal de tienda (RET_*)"])
    # Externos
    s.caja(560, 110, 380, 130, GRIS_EXT, "Seguridad y Usuarios (G7)", "[Sistema externo · Render]",
           ["Login con MFA, emite JWT (RS256),", "JWKS y tokens de servicio"])
    s.caja(1450, 440, 340, 150, GRIS_EXT, "Ventas y Postventa (G5)", "[Sistema externo · Render]",
           ["Dueño del pedido y su estado;", "bandeja pickup y entrega"])
    s.caja(1450, 140, 340, 130, "#f2f2f2", "Productos y Ofertas (G6)", "[Sistema externo · simulado]",
           ["Catálogo y precios: en el Hito 4", "se usa el mock interno de ms-retail"],
           dashed=True, stroke="#777", tcolor="#333")
    s.caja(450, 1010, 320, 110, GRIS_EXT, "Impresora de tickets", "[Hardware de mostrador]",
           ["Boleta / ticket térmico"])

    # Relaciones
    s.flecha([(300, 270), (500, 440)], ["Usa el POS en el navegador", "[HTTPS]"], pos=(330, 395))
    s.flecha([(560, 440), (640, 240)], ["Inicia sesión con MFA", "y obtiene el JWT", "[HTTPS / REST]"], pos=(660, 320))
    s.flecha([(770, 515), (940, 515)], ["Consume la API con JWT", "[HTTPS / REST · JSON]"], pos=(855, 470), ancho=170)
    s.flecha([(1040, 440), (860, 240)],
             ["Valida el JWT con JWKS (RS256)", "y pide token de servicio", "client_credentials (audience api-ventas)",
              "[HTTPS]"], pos=(990, 320))
    s.flecha([(1270, 515), (1450, 515)],
             ["Crea pedidos IN_STORE (F4/F5)", "Bandeja y entrega pickup (F7)", "Bearer G7 · Idempotency-Key",
              "[HTTPS / REST]"], pos=(1360, 615))
    s.flecha([(1230, 440), (1450, 230)], ["Lecturas de catálogo", "[simulado: perfil mock]"], pos=(1335, 330),
             dashed=True)
    s.flecha([(1105, 590), (1105, 700)], ["Lee y escribe", "[JDBC sobre TLS]"], pos=(1185, 645))
    s.flecha([(700, 590), (700, 1010)], ["Imprime el ticket", "[diálogo de impresión]"], pos=(700, 960))

    leyenda(s, 1490, 760, [(AZUL_PERSONA, "Persona", False), (AZUL_CONT, "Contenedor del Canal Retail", False),
                           (GRIS_EXT, "Sistema externo en vivo", False), ("#f2f2f2", "Sistema externo simulado", True)])
    s.text(1490, 1000, ["G2 Despacho no se integra con Retail:", "el retiro en tienda se resuelve con G5",
                        "(contrato §4.4)."], 13, "#555", anchor="start")
    return s.render("Diagrama de Contenedores (C4 · nivel 2) — Canal Retail (G4)",
                    "Hito 4 · Semana 11 · conexiones reales con Ventas (G5) y Seguridad (G7)")


def nodo(s, x, y, w, h, titulo, estereotipo, fill, borde="#1f4e79"):
    d = 14
    s.add(f'<path d="M{x},{y + d} L{x + d},{y} L{x + w + d},{y} L{x + w + d},{y + h - d} L{x + w},{y + h}" '
          f'fill="{fill}" stroke="{borde}" stroke-width="2"/>')
    s.add(f'<path d="M{x + w},{y + d} L{x + w + d},{y}" stroke="{borde}" stroke-width="2"/>')
    s.add(f'<rect x="{x}" y="{y + d}" width="{w}" height="{h - d}" fill="{fill}" stroke="{borde}" stroke-width="2"/>')
    s.text(x + w / 2, y + d + 24, [f"«{estereotipo}»"], 13, "#333", italic=True)
    s.text(x + w / 2, y + d + 46, [titulo], 17, "#111", "bold")


def artefacto(s, x, y, w, h, lineas, fill="#ffffff"):
    s.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="{fill}" stroke="#888" stroke-width="1.5"/>')
    s.add(f'<path d="M{x + w - 22},{y + 6} h10 l6,6 v12 h-16 z" fill="#fff" stroke="#888"/>')
    s.text(x + w / 2, y + 24, [lineas[0]], 14, "#111", "bold")
    s.text(x + w / 2, y + 44, list(lineas[1:]), 12.5, "#333", lh=16)


def despliegue():
    s = Svg(1840, 1260)
    # Navegador
    nodo(s, 620, 110, 520, 200, "PC del mostrador · Navegador", "dispositivo", "#e3f0fb")
    artefacto(s, 690, 200, 380, 90, ["SPA React (bundle JS)", "descargada de Vercel", "VITE_API_URL → backend en Railway"])
    # Vercel
    nodo(s, 60, 420, 420, 220, "Vercel", "nube · CDN", "#e8f5e9", "#2e7d32")
    artefacto(s, 100, 520, 340, 96, ["G4-Retail-frontend", "build estático de Vite", "vercel.json: rutas SPA"])
    # Railway
    nodo(s, 620, 420, 560, 360, "Railway", "nube · contenedor Docker", "#fff4e0", "#b26a00")
    artefacto(s, 660, 520, 480, 110, ["ms-retail.jar", "Spring Boot 3.5 · Java 21 (eclipse-temurin)",
                                       "SPRING_PROFILES_ACTIVE=supabase,mock",
                                       "healthcheck /api/v1/retail/health"])
    artefacto(s, 660, 650, 480, 104, ["Variables de entorno", "SUPABASE_DB_URL · SUPABASE_DB_USER/PASSWORD",
                                       "G7_CLIENT_SECRET (token de servicio)",
                                       "RETAIL_VENTAS_URL · RETAIL_SEGURIDAD_JWKS_URI"], fill="#fffdf6")
    # Supabase
    nodo(s, 620, 920, 560, 220, "Supabase", "nube · PostgreSQL gestionado", "#ede7f6", "#4527a0")
    artefacto(s, 660, 1020, 480, 96, ["Base de datos Retail", "PostgreSQL · tablas RET_*",
                                       "turnos, ventas, comprobantes, personal"])
    # Render (otros grupos)
    nodo(s, 1300, 260, 480, 560, "Render · otros módulos", "nube · servicios de otros grupos", "#eceff1", "#455a64")
    artefacto(s, 1340, 370, 400, 110, ["Seguridad (G7)", "g7-auth-service.onrender.com",
                                        "/auth/login · /auth/token", "/.well-known/jwks.json"])
    artefacto(s, 1340, 520, 400, 110, ["Ventas y Postventa (G5)", "g5-servicio-ventas.onrender.com",
                                        "POST /pedidos · GET /pedidos/pickup",
                                        "POST /pedidos/{id}/entrega-pickup"])
    artefacto(s, 1340, 670, 400, 110, ["Productos y Ofertas (G6)", "no se consume en el Hito 4:",
                                        "ms-retail usa su mock interno",
                                        "(perfil mock)"], fill="#f7f7f7")
    # GitHub
    nodo(s, 60, 800, 420, 200, "GitHub", "repositorios + CI", "#f3f3f3", "#333")
    artefacto(s, 100, 900, 340, 80, ["GitHub Actions", "compila, prueba y empaqueta", "en cada push / PR"])

    # Relaciones
    s.flecha([(760, 310), (380, 420)], ["Descarga la SPA", "[HTTPS]"], pos=(560, 360), dashed=True)
    s.flecha([(880, 310), (880, 420)], ["API /api/v1/retail/* con JWT", "[HTTPS / REST]"], pos=(980, 365))
    s.flecha([(1140, 200), (1540, 200), (1540, 370)], ["Login con MFA", "[HTTPS / REST]"], pos=(1340, 200))
    s.flecha([(1194, 560), (1340, 425)], ["JWKS (RS256) y", "token de servicio", "[HTTPS]"], pos=(1255, 470))
    s.flecha([(1194, 600), (1340, 575)], ["Pedidos y pickup", "Bearer G7", "[HTTPS / REST]"], pos=(1268, 610))
    s.flecha([(900, 780), (900, 920)], ["JDBC sobre TLS", "[puerto 5432 / pooler]"], pos=(1000, 850))
    s.flecha([(270, 800), (270, 640)], ["Despliegue continuo", "desde GitHub"], pos=(270, 720), dashed=True)
    s.flecha([(480, 860), (620, 700)], ["Despliegue continuo", "desde GitHub"], pos=(545, 790), dashed=True)

    return s.render("Diagrama de Despliegue — Canal Retail (G4)",
                    "Hito 4 · Semana 11 · Vercel (SPA) · Railway (Spring Boot) · Supabase (PostgreSQL) · G5/G7 en Render")


if __name__ == "__main__":
    salida = sys.argv[1]
    open(f"{salida}/Modelo-Contenedor.svg", "w", encoding="utf-8").write(contenedores())
    open(f"{salida}/Modelo-Despliegue.svg", "w", encoding="utf-8").write(despliegue())
    print("ok")

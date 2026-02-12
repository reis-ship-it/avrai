#!/usr/bin/env python3
"""Generate the AVRAI Brand Book PDF."""

from fpdf import FPDF
import os

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_PATH = os.path.join(OUT_DIR, "AVRAI_Brand_Book.pdf")

# Brand colors
GREEN = (0, 255, 102)
DARK_BG = (11, 11, 11)
DEEP_NIGHT = (10, 26, 47)
WHITE = (255, 255, 255)
LIGHT_GREY = (176, 176, 176)
MID_GREY = (138, 138, 138)
DIM_GREY = (110, 110, 110)
PLATINUM = (224, 224, 224)
CHARCOAL = (64, 64, 64)
BODY_COLOR = (190, 190, 190)
DIVIDER = (40, 40, 40)


class BrandBook(FPDF):
    def __init__(self):
        super().__init__(orientation="P", unit="mm", format="A4")
        self.set_auto_page_break(auto=False)
        # Use built-in fonts (Helvetica as Inter substitute)

    # ── Helpers ──

    def dark_page(self, color=DARK_BG):
        self.add_page()
        self.set_fill_color(*color)
        self.rect(0, 0, 210, 297, "F")

    def green_label(self, text, x=20, y=None):
        if y is not None:
            self.set_y(y)
        self.set_x(x)
        self.set_font("Helvetica", "B", 8)
        self.set_text_color(*GREEN)
        self.cell(0, 5, text.upper(), ln=True)
        self.set_y(self.get_y() + 2)

    def metallic_heading(self, text, size=18, x=20):
        self.set_x(x)
        self.set_font("Helvetica", "B", size)
        self.set_text_color(*PLATINUM)
        self.multi_cell(170, size * 0.55, text)
        self.set_y(self.get_y() + 3)

    def body_text(self, text, x=20, w=170):
        self.set_x(x)
        self.set_font("Helvetica", "", 9.5)
        self.set_text_color(*BODY_COLOR)
        self.multi_cell(w, 5, text)
        self.set_y(self.get_y() + 2)

    def small_text(self, text, x=20, w=170, italic=False):
        self.set_x(x)
        self.set_font("Helvetica", "I" if italic else "", 8)
        self.set_text_color(*MID_GREY)
        self.multi_cell(w, 4.5, text)
        self.set_y(self.get_y() + 1)

    def divider(self, x=20, w=170):
        y = self.get_y() + 2
        self.set_draw_color(*DIVIDER)
        self.line(x, y, x + w, y)
        self.set_y(y + 4)

    def color_swatch(self, x, y, r, g, b, name, hex_code):
        # Swatch circle
        self.set_fill_color(r, g, b)
        self.ellipse(x, y, 10, 10, "F")
        # Name
        self.set_xy(x + 13, y)
        self.set_font("Helvetica", "B", 9)
        self.set_text_color(*PLATINUM)
        self.cell(50, 5, name)
        # Hex
        self.set_xy(x + 13, y + 5)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(*MID_GREY)
        self.cell(50, 5, hex_code)

    def table_row(self, cols, widths, bold=False, header=False):
        x = 20
        if header:
            self.set_font("Helvetica", "B", 8)
            self.set_text_color(*GREEN)
        elif bold:
            self.set_font("Helvetica", "B", 8.5)
            self.set_text_color(*PLATINUM)
        else:
            self.set_font("Helvetica", "", 8.5)
            self.set_text_color(*BODY_COLOR)
        for i, col in enumerate(cols):
            self.set_x(x)
            self.cell(widths[i], 6, col)
            x += widths[i]
        self.ln(6)

    def page_number_footer(self, num):
        self.set_xy(0, 285)
        self.set_font("Helvetica", "", 7)
        self.set_text_color(*CHARCOAL)
        self.cell(210, 5, str(num), align="C")

    # ── Pages ──

    def page_cover(self):
        self.dark_page(DEEP_NIGHT)
        # Subtitle top
        self.set_xy(0, 30)
        self.set_font("Helvetica", "", 9)
        self.set_text_color(*MID_GREY)
        self.cell(210, 5, "Identity Guidelines", align="C")

        # Brand name
        self.set_xy(0, 115)
        self.set_font("Helvetica", "B", 56)
        self.set_text_color(*PLATINUM)
        self.cell(210, 20, "avrai", align="C")

        # Tagline
        self.set_xy(0, 145)
        self.set_font("Helvetica", "", 13)
        self.set_text_color(*LIGHT_GREY)
        self.cell(210, 8, "know you belong.", align="C")

        # Green accent line
        self.set_draw_color(*GREEN)
        self.set_line_width(0.4)
        self.line(75, 165, 135, 165)

        # Version
        self.set_xy(0, 275)
        self.set_font("Helvetica", "", 7)
        self.set_text_color(*DIM_GREY)
        self.cell(210, 5, "Version 1.0  -  February 2026", align="C")

    def page_toc_philosophy(self):
        self.dark_page()

        # TOC left column
        self.green_label("What You'll Find Inside", y=25)
        self.set_y(35)

        toc = [
            "Brand Philosophy", "Brand Story", "Brand Values",
            "Primary Logo", "Logo Variants", "Clear Space & Minimum Size",
            "Color Palette", "Typography", "The Glass Slate",
            "Portal Components", "Imagery & Photography", "Voice & Tone",
            "Application Mockups", "Do's and Don'ts"
        ]
        for i, item in enumerate(toc):
            self.set_x(20)
            self.set_font("Helvetica", "B", 9)
            self.set_text_color(*GREEN)
            self.cell(12, 6, f"{i+1:02d}")
            self.set_font("Helvetica", "", 9)
            self.set_text_color(*MID_GREY)
            self.cell(70, 6, item, ln=True)

        # Vertical divider
        self.set_draw_color(*DIVIDER)
        self.line(105, 25, 105, 270)

        # Philosophy right column
        self.set_xy(112, 25)
        self.set_font("Helvetica", "B", 8)
        self.set_text_color(*GREEN)
        self.cell(0, 5, "AVRAI BRAND PHILOSOPHY")

        self.set_xy(112, 38)
        self.set_font("Helvetica", "B", 16)
        self.set_text_color(*PLATINUM)
        self.multi_cell(82, 8, "There is no secret to life. Just doors that haven't been opened yet.")

        self.set_xy(112, 80)
        self.set_font("Helvetica", "", 9.5)
        self.set_text_color(*BODY_COLOR)
        self.multi_cell(82, 5, (
            "We believe everyone deserves to know they belong. AVRAI exists to help people find "
            "the places, experiences, communities, and people where they truly feel at home - "
            "wherever they are.\n\n"
            "Our purpose is to open doors for meaningful connections. Everything we build ensures "
            "that meaningful connections exist, that people can find them more easily, and that "
            "people can find them truthfully.\n\n"
            "AVRAI is the key. You open the doors. You find your life."
        ))

        self.page_number_footer(2)

    def page_brand_story(self):
        self.dark_page()
        self.green_label("THE DOORS", y=25)
        self.metallic_heading("Every spot is a door. Every person is a door.\nEvery community is a door. Every event is a door.", 16)

        self.body_text(
            "Doors lead to experiences, communities, people, meaning, belonging - and more doors.\n\n"
            "We don't show you recommendations. We show you doors.\n"
            "We don't match you with people. We connect you with people who open similar doors.\n"
            "We don't measure engagement. We measure doors opened."
        )

        self.divider()
        self.green_label("THE JOURNEY")

        steps = [
            "Find YOUR Spots",
            "Those spots have communities",
            "Those communities have events",
            "You find YOUR people",
            "You find YOUR life"
        ]
        for i, step in enumerate(steps):
            self.set_x(25)
            self.set_font("Helvetica", "" if i > 0 else "B", 10)
            self.set_text_color(*PLATINUM if i == 0 or i == 4 else BODY_COLOR)
            prefix = "->  " if i > 0 else ""
            self.cell(0, 7, prefix + step, ln=True)

        self.set_y(self.get_y() + 6)
        self.small_text(
            "Week 1: The key opens a door - a coffee shop that matches your vibe. "
            "Week 3: You return. It resonates. The key notices. "
            "Week 5: The key shows another door - a writers' group at that coffee shop. "
            "Week 10: Through those doors, you've found your community, your people, your life.\n\n"
            "AVRAI was the key. You did the walking. You found the life.",
            italic=True
        )
        self.page_number_footer(3)

    def page_brand_values(self):
        self.dark_page()
        self.green_label("WHAT WE STAND FOR", y=25)

        values = [
            ("Doors, Not Badges",
             "Authentic contributions over gamification. Your journey is yours - not a leaderboard, "
             "not a streak, not a level. Every feature exists to open real doors to meaning, fulfillment, "
             "and happiness. We don't capitalize on usage. We don't gamify experiences to replace "
             "authentic real-world engagement."),
            ("Real World First",
             "Technology enhances life; it never replaces it. When you use avrai, you find a coffee shop "
             "and go there in person. You discover an event and attend it in real life. You meet someone "
             "and connect face-to-face. The doors we open lead to real places, real people, real "
             "communities. The real world is where you walk through the doors."),
            ("Privacy Is Architecture",
             "Your data is yours. All personal data stays on your device. Learning happens locally. "
             "Only anonymized signals are ever shared - protected by post-quantum encryption. "
             "Privacy isn't a policy we follow. It's the architecture we built. No agenda. No politics. "
             "No pay-to-play. Our suggestions are never for sale.")
        ]

        for title, desc in values:
            self.divider()
            self.metallic_heading(title, 14)
            self.body_text(desc)

        self.page_number_footer(4)

    def page_primary_logo(self):
        self.dark_page()
        self.green_label("PRIMARY LOGO", y=25)
        self.metallic_heading("The Glass Knot", 18)

        self.body_text(
            "The AVRAI logo is a glass knot - interconnected crystalline strands radiating outward "
            "from a central form. It represents the interconnected nature of personality, place, and "
            "community. Its glass material reflects the Portal design system's transparency-first aesthetic.\n\n"
            "The knot is never static. In digital contexts, it catches light and refracts the world behind "
            "it - just as avrai catches the patterns of your life and refracts them into doors worth opening."
        )

        # Logo placeholder
        self.set_y(self.get_y() + 5)
        self.set_draw_color(*CHARCOAL)
        self.set_fill_color(20, 20, 30)
        self.rect(55, self.get_y(), 100, 70, "DF")
        self.set_xy(55, self.get_y() + 28)
        self.set_font("Helvetica", "", 10)
        self.set_text_color(*DIM_GREY)
        self.cell(100, 8, "[ Glass Knot Logo ]", align="C")
        self.set_y(self.get_y() + 50)

        # Wordmark
        self.set_xy(0, self.get_y())
        self.set_font("Helvetica", "B", 28)
        self.set_text_color(*PLATINUM)
        self.cell(210, 12, "avrai", align="C")

        self.set_y(self.get_y() + 15)
        self.small_text("Primary logo: Glass knot icon with \"avrai\" wordmark. Use as the default in all contexts where space allows.")

        self.set_y(self.get_y() + 4)
        annotations = [
            "Glass material - transparency, honesty, clarity",
            "Radiating strands - connections extending outward",
            "Central knot - personality, the core of who you are",
            "Blue sky refraction - the real world, seen through a new lens"
        ]
        for a in annotations:
            self.set_x(30)
            self.set_font("Helvetica", "", 8)
            self.set_text_color(*MID_GREY)
            self.cell(5, 5, "*")
            self.cell(0, 5, a, ln=True)

        self.page_number_footer(5)

    def page_logo_variants(self):
        self.dark_page()
        self.green_label("LOGO VARIANTS", y=25)

        variants = [
            ("1. Full Logo (Knot + Wordmark)",
             "Glass knot above \"avrai\" wordmark.",
             "Marketing materials, headers, splash screens, presentations."),
            ("2. Icon Only (Knot)",
             "Glass knot without wordmark.",
             "App icon, favicon, social media avatars, small spaces."),
            ("3. Wordmark Only (\"avrai\")",
             "\"avrai\" in metallic gradient text, Inter Bold, letter-spacing 4px.",
             "Navigation bars, footers, inline references, co-branding."),
            ("4. Reversed (White)",
             "White silhouette version of the knot and wordmark.",
             "Dark backgrounds, Portal night mode, video overlays."),
            ("5. Monochrome",
             "Single-color version in #8A8A8A.",
             "Grayscale print, embossing, single-color merchandise.")
        ]

        for title, desc, use in variants:
            self.set_x(20)
            self.set_font("Helvetica", "B", 10)
            self.set_text_color(*PLATINUM)
            self.cell(0, 7, title, ln=True)
            self.set_x(20)
            self.set_font("Helvetica", "", 9)
            self.set_text_color(*BODY_COLOR)
            self.cell(0, 5, desc, ln=True)
            self.set_x(20)
            self.set_font("Helvetica", "", 8)
            self.set_text_color(*MID_GREY)
            self.cell(0, 5, "Use: " + use, ln=True)
            self.set_y(self.get_y() + 4)

        self.divider()
        self.small_text(
            "To maintain consistency, never recreate the logo. Only use approved digital files. "
            "Alternative formats are available when full-color reproduction is not an option.",
            italic=True
        )
        self.page_number_footer(6)

    def page_clear_space(self):
        self.dark_page()
        self.green_label("CLEAR SPACE & MINIMUM SIZE", y=25)

        self.body_text(
            "To preserve the avrai logo's integrity, always maintain minimum clear space around the logo. "
            "This isolates the logo from competing graphic elements - other logos, copy, photography, "
            "or background patterns that may divert attention."
        )

        self.divider()
        self.metallic_heading("Clear Space Rule", 12)
        self.body_text(
            "The minimum clear space is defined as 1.5x the height of the letter \"a\" in the \"avrai\" "
            "wordmark, measured on all four sides. For the icon-only variant, use 1.5x the diameter of "
            "the core knot center.\n\n"
            "This minimum space must be maintained as the logo is proportionally enlarged or reduced."
        )

        self.divider()
        self.metallic_heading("Minimum Size", 12)

        widths = [60, 40, 40]
        self.table_row(["Context", "Full Logo", "Icon Only"], widths, header=True)
        self.table_row(["Digital (screen)", "120px wide", "32px wide"], widths)
        self.table_row(["Print", "1.5in wide", "0.5in wide"], widths)
        self.table_row(["App icon master", "-", "1024 x 1024px"], widths)

        self.set_y(self.get_y() + 5)
        self.small_text(
            "To maintain legibility, never reduce the logo beyond these minimum width requirements. "
            "The glass knot's detail is lost below these thresholds.",
            italic=True
        )
        self.page_number_footer(7)

    def page_colors(self):
        self.dark_page()
        self.green_label("COLOR PALETTE", y=25)

        self.metallic_heading("Primary Colors", 12)
        y = self.get_y()
        self.color_swatch(20, y, 0, 255, 102, "Electric Green", "#00FF66")
        self.color_swatch(105, y, 0, 212, 255, "Electric Blue", "#00D4FF")
        self.set_y(y + 18)

        self.divider()
        self.metallic_heading("Satin Titanium (Portal Metallics)", 12)

        metallics = [
            (224, 224, 224, "Light Platinum", "#E0E0E0"),
            (176, 176, 176, "Mid Grey", "#B0B0B0"),
            (144, 144, 144, "Darker Steel", "#909090"),
            (112, 112, 112, "Gunmetal Light", "#707070"),
            (64, 64, 64, "Charcoal", "#404040"),
            (48, 48, 48, "Deep Graphite", "#303030"),
        ]
        y = self.get_y()
        for i, (r, g, b, name, h) in enumerate(metallics):
            col = i % 3
            row = i // 3
            self.color_swatch(20 + col * 62, y + row * 16, r, g, b, name, h)
        self.set_y(y + 38)

        self.divider()
        self.metallic_heading("Neutrals", 12)
        neutrals = [
            (255, 255, 255, "White", "#FFFFFF"), (250, 250, 250, "Grey 50", "#FAFAFA"),
            (245, 245, 245, "Grey 100", "#F5F5F5"), (229, 229, 229, "Grey 200", "#E5E5E5"),
            (110, 110, 110, "Grey 600", "#6E6E6E"), (31, 31, 31, "Grey 800", "#1F1F1F"),
            (11, 11, 11, "Grey 900", "#0B0B0B"), (0, 0, 0, "Black", "#000000"),
        ]
        y = self.get_y()
        for i, (r, g, b, name, h) in enumerate(neutrals):
            col = i % 3
            row = i // 3
            self.color_swatch(20 + col * 62, y + row * 16, r, g, b, name, h)
        self.set_y(y + 52)

        self.divider()
        self.metallic_heading("Semantic", 12)
        y = self.get_y()
        self.color_swatch(20, y, 255, 77, 77, "Error", "#FF4D4D")
        self.color_swatch(82, y, 255, 193, 7, "Warning", "#FFC107")
        self.color_swatch(144, y, 0, 255, 102, "Success", "#00FF66")

        self.page_number_footer(8)

    def page_typography(self):
        self.dark_page()
        self.green_label("TYPOGRAPHY", y=25)

        self.metallic_heading("Inter", 14)
        self.body_text(
            "Inter is our primary typeface. Designed for screens, it's clean, highly legible, and precise - "
            "engineered for the same clarity we bring to every door we open.\n\n"
            "Inter communicates avrai's promise: intelligence delivered with warmth. Modern enough for "
            "cutting-edge AI. Human enough for real-world connection."
        )

        # Specimen
        self.set_y(self.get_y() + 2)
        self.set_x(20)
        self.set_font("Helvetica", "B", 12)
        self.set_text_color(*PLATINUM)
        self.cell(0, 7, "Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm", ln=True)
        self.set_x(20)
        self.cell(0, 7, "Nn Oo Pp Qq Rr Ss Tt Uu Vv Ww Xx Yy Zz", ln=True)
        self.set_x(20)
        self.cell(0, 7, "0 1 2 3 4 5 6 7 8 9", ln=True)

        self.set_y(self.get_y() + 4)
        weights = [
            ("Regular", "Body text, descriptions, captions"),
            ("Medium", "Labels, navigation, secondary headings"),
            ("SemiBold", "Subheadings, buttons, emphasis"),
            ("Bold", "Headlines, display text, titles"),
        ]
        for w, use in weights:
            self.set_x(20)
            self.set_font("Helvetica", "B" if "Bold" in w else "", 9)
            self.set_text_color(*PLATINUM)
            self.cell(40, 5, "Inter " + w)
            self.set_font("Helvetica", "", 8)
            self.set_text_color(*MID_GREY)
            self.cell(0, 5, "- " + use, ln=True)

        self.divider()
        self.metallic_heading("Satin Titanium Treatment", 12)
        self.body_text(
            "For primary headings and the \"avrai\" brand name, we apply the Satin Titanium metallic "
            "gradient. This gives text a physical, machined quality - as if the words were etched into "
            "brushed metal.\n\n"
            "Direction: Top-left to Bottom-right (45 degrees)\n"
            "Day stops: #E0E0E0 -> #B0B0B0 -> #E0E0E0 -> #909090\n"
            "Night stops: #707070 -> #404040 -> #707070 -> #303030\n"
            "Text shadow: Offset (0, 2), blur 4, black at 50%"
        )

        self.divider()
        self.metallic_heading("Type Scale", 12)
        w = [30, 28, 25, 52, 35]
        self.table_row(["Role", "Weight", "Size", "Color", ""], w, header=True)
        rows = [
            ["Display", "Bold", "28-32pt", "Metallic gradient", ""],
            ["Heading", "SemiBold", "18-22pt", "Metallic / #E0E0E0", ""],
            ["Title", "SemiBold", "14-16pt", "#E0E0E0 or #121212", ""],
            ["Body", "Regular", "14-16pt", "#E0E0E0 / #121212", ""],
            ["Caption", "Medium", "12pt", "#8A8A8A", ""],
            ["Button", "SemiBold", "16pt", "#FFFFFF", ""],
        ]
        for r in rows:
            self.table_row(r, w)

        self.page_number_footer(9)

    def page_glass_slate(self):
        self.dark_page()
        self.green_label("THE GLASS SLATE", y=25)
        self.metallic_heading("A floating window into your world.", 16)

        self.body_text(
            "The Glass Slate is avrai's signature UI container. It floats over a procedurally generated "
            "3D world - a living landscape of sky, grass, clouds, and light that responds to time of day "
            "and device orientation. Content lives inside the glass. The world lives behind it.\n\n"
            "The slate is never flat. It has physical presence: depth from its drop shadow, weight from "
            "its blur, warmth from its border gradient that catches light like a chamfered metal edge."
        )

        self.divider()
        self.metallic_heading("Specifications", 12)

        w = [55, 115]
        specs = [
            ["Background blur", "25 sigma (X and Y) - frosted glass"],
            ["Tint (Day)", "Black at 22% - \"smoked glass\""],
            ["Tint (Night)", "White at 8% - \"moonlit mist\""],
            ["Corner radius", "32px - soft, organic, approachable"],
            ["Border", "1.5px gradient - chamfered metallic edge"],
            ["Border (Day)", "#99FFFFFF -> #1AFFFFFF -> #66000000"],
            ["Border (Night)", "#CCFFFFFF -> #33FFFFFF -> #66404040"],
            ["Drop shadow", "Black 45%, blur 40, y:20, spread:-10"],
            ["Negative border", "12px beyond screen edges"],
        ]
        for s in specs:
            self.table_row(s, w)

        self.set_y(self.get_y() + 5)
        self.small_text(
            "The Glass Slate communicates avrai's core philosophy through its design: the world is "
            "what matters, and avrai is a transparent lens that helps you see it more clearly. "
            "The glass doesn't hide the world - it reveals it.",
            italic=True
        )
        self.page_number_footer(10)

    def page_components(self):
        self.dark_page()
        self.green_label("PORTAL COMPONENTS", y=25)

        components = [
            ("Turbine Loader",
             "Two concentric rings rotating in opposite directions around a breathing Electric Green core. "
             "It communicates motion, intelligence, and life - the key is thinking.",
             "Size: 64px  |  Outer: 270° sweep, 3px  |  Inner: 180° sweep, 2px  |  "
             "Core: Electric Green #00FF66, 30%, breathing  |  Cycle: 2s"),
            ("Recessed Map",
             "Maps sit recessed into the glass slate - inset like an instrument in a cockpit. "
             "A vignette darkens the edges, and a subtle crosshair marks center.",
             "Radius: 20px  |  Border: white 10%, 1px  |  Shadow: black 80%, blur 15  |  "
             "Vignette: black 60%, stops 0.7-1.0"),
            ("Electric Edge Glow",
             "When you scroll past the edge of content, a glowing overscroll indicator appears - "
             "Electric Green at night, white platinum during the day.",
             "Night: #00FF66  |  Day: #E0E0E0"),
            ("Page Transitions",
             "Content enters the glass slate by scaling from 95% to 100% with a simultaneous fade.",
             "Scale: 0.95->1.0  |  Opacity: 0->1  |  Duration: 300ms / 200ms  |  Curve: easeOutCubic"),
        ]

        for title, desc, spec in components:
            self.divider()
            self.metallic_heading(title, 12)
            self.body_text(desc)
            self.small_text(spec)

        self.page_number_footer(11)

    def page_imagery(self):
        self.dark_page()
        self.green_label("IMAGERY & PHOTOGRAPHY", y=25)
        self.metallic_heading("Three visual categories that tell\nthe avrai story.", 15)

        cats = [
            ("Portal World",
             "Screenshots and renders of the procedural 3D landscape. Day skies, night skies, "
             "fireflies, rolling grass, cloud formations.",
             "App backgrounds, marketing hero images, presentation backdrops."),
            ("Glass & Metal",
             "Close-ups of the glass knot logo, glass slate UI elements, metallic text treatments, "
             "light refractions.",
             "Brand collateral, social media, investor materials, product detail shots."),
            ("Real World Doors",
             "Photography of real places, real people, real communities. Coffee shops, parks, "
             "street markets, events, friends laughing, strangers meeting.",
             "Marketing campaigns, social media, editorial, app content."),
        ]
        for title, desc, use in cats:
            self.divider()
            self.set_x(20)
            self.set_font("Helvetica", "B", 11)
            self.set_text_color(*GREEN)
            self.cell(0, 7, title, ln=True)
            self.body_text(desc)
            self.small_text("Use for: " + use)

        self.divider()
        self.metallic_heading("Photography Guidelines", 12)

        guidelines = [
            "Warm and authentic. Never staged, never stock. Real moments.",
            "Natural light preferred. Golden hour, overcast, dappled sun.",
            "Diversity always. People, places, cultures, ages, lifestyles.",
            "Candid over posed. People in the middle of living.",
            "Color treatment. Slightly desaturated, cool-to-warm shift.",
            "No screens. People are in the real world, not staring at phones.",
        ]
        for g in guidelines:
            self.set_x(24)
            self.set_font("Helvetica", "", 8.5)
            self.set_text_color(*BODY_COLOR)
            self.cell(3, 5, "*")
            self.cell(0, 5, " " + g, ln=True)

        self.page_number_footer(12)

    def page_voice_tone(self):
        self.dark_page()
        self.green_label("VOICE & TONE", y=25)
        self.metallic_heading("How avrai speaks.", 16)

        self.body_text(
            "avrai's voice is direct, warm, and grounded. We speak like a thoughtful friend who knows "
            "you well - not a brand trying to be your friend. We say less, not more. We show doors, "
            "we don't sell them."
        )

        self.divider()
        self.metallic_heading("The Name", 12)
        rules = [
            "Always lowercase: avrai",
            "Never: AVRAI, Avrai, AvRai, AvRAI",
            "In sentences: \"Ask avrai\" / \"avrai helps you find...\"",
            "Exception: Legal documents, all-caps contexts",
        ]
        for r in rules:
            self.set_x(24)
            self.set_font("Helvetica", "", 9)
            self.set_text_color(*BODY_COLOR)
            self.cell(3, 5.5, "*")
            self.cell(0, 5.5, " " + r, ln=True)

        self.divider()
        self.metallic_heading("Language", 12)
        w = [80, 90]
        self.table_row(["We Say", "We Don't Say"], w, header=True)
        pairs = [
            ["Open new doors", "We recommend"],
            ["Your next door", "Top picks for you"],
            ["Find your people", "Leverage our AI-powered matching"],
            ["Get out there", "Browse profiles"],
            ["You found it", "We found this for you"],
            ["Your journey", "You earned a badge!"],
            ["The AI learns with you", "Our revolutionary AI technology"],
        ]
        for p in pairs:
            self.table_row(p, w)

        self.divider()
        self.metallic_heading("Taglines", 12)
        self.set_x(20)
        self.set_font("Helvetica", "B", 13)
        self.set_text_color(*PLATINUM)
        self.cell(0, 8, "know you belong.", ln=True)
        self.set_y(self.get_y() + 2)

        phrases = [
            "Life is doors you haven't opened yet.",
            "The key to your next chapter.",
            "Spots. Community. Life.",
            "Not to give you answers. To show you possibilities.",
            "You open the doors. You find your life.",
            "No agenda. No politics. No pay-to-play.",
        ]
        for p in phrases:
            self.set_x(24)
            self.set_font("Helvetica", "", 8.5)
            self.set_text_color(*MID_GREY)
            self.cell(3, 5, "*")
            self.cell(0, 5, " " + p, ln=True)

        self.page_number_footer(13)

    def page_dos_donts(self):
        self.dark_page()
        self.green_label("DO'S AND DON'TS", y=25)

        sections = [
            ("Logo", [
                ("Use the logo on dark or Portal backgrounds",
                 "Place logo on busy patterns or light backgrounds"),
                ("Maintain clear space on all sides",
                 "Crowd the logo with other elements"),
                ("Use approved digital files only",
                 "Recreate, redraw, trace, or modify"),
            ]),
            ("Color", [
                ("Use Electric Green #00FF66 for accents",
                 "Substitute with other greens, lime, or teal"),
                ("Use Satin Titanium gradient for headlines",
                 "Use flat grey for headlines or brand name"),
                ("Pair Electric Green with dark neutrals",
                 "Pair with bright or competing colors"),
            ]),
            ("Typography", [
                ("Use Inter for all text",
                 "Substitute with Arial, Helvetica, etc."),
                ("Write \"avrai\" in lowercase",
                 "Write AVRAI, Avrai, or AvRai"),
            ]),
            ("Design", [
                ("Use Glass Slate (32px radius, blur 25)",
                 "Use flat white cards with sharp corners"),
                ("Let the Portal world show through",
                 "Cover the world with opaque surfaces"),
            ]),
            ("Voice", [
                ("Use \"doors\" language",
                 "Use \"recommendations\" or \"picks\""),
                ("Credit the user: \"You found it\"",
                 "Credit avrai: \"We found this for you\""),
            ]),
        ]

        for section_title, items in sections:
            self.set_x(20)
            self.set_font("Helvetica", "B", 10)
            self.set_text_color(*PLATINUM)
            self.cell(0, 7, section_title, ln=True)
            for do, dont in items:
                self.set_x(24)
                self.set_font("Helvetica", "B", 8)
                self.set_text_color(*GREEN)
                self.cell(4, 5, "[Y]")
                self.set_font("Helvetica", "", 8)
                self.set_text_color(*BODY_COLOR)
                self.cell(78, 5, do)
                self.set_font("Helvetica", "B", 8)
                self.set_text_color(255, 77, 77)
                self.cell(4, 5, "[N]")
                self.set_font("Helvetica", "", 8)
                self.set_text_color(*MID_GREY)
                self.cell(0, 5, dont, ln=True)
            self.set_y(self.get_y() + 3)

        self.page_number_footer(14)

    def page_back_cover(self):
        self.dark_page(DEEP_NIGHT)

        # Brand name
        self.set_xy(0, 120)
        self.set_font("Helvetica", "B", 36)
        self.set_text_color(*PLATINUM)
        self.cell(210, 14, "avrai", align="C")

        # Tagline
        self.set_xy(0, 145)
        self.set_font("Helvetica", "", 14)
        self.set_text_color(*LIGHT_GREY)
        self.cell(210, 8, "know you belong.", align="C")

        # URL
        self.set_xy(0, 240)
        self.set_font("Helvetica", "", 9)
        self.set_text_color(*DIM_GREY)
        self.cell(210, 5, "avrai.app", align="C")

        # Copyright
        self.set_xy(0, 265)
        self.set_font("Helvetica", "", 7)
        self.set_text_color(*CHARCOAL)
        self.cell(210, 4, "© 2026 AVRAI. All rights reserved.", align="C")
        self.set_xy(0, 269)
        self.cell(210, 4, "This document and its contents are confidential.", align="C")
        self.set_xy(0, 273)
        self.cell(210, 4, "For questions about brand usage, contact brand@avrai.app", align="C")

    def build(self):
        self.page_cover()
        self.page_toc_philosophy()
        self.page_brand_story()
        self.page_brand_values()
        self.page_primary_logo()
        self.page_logo_variants()
        self.page_clear_space()
        self.page_colors()
        self.page_typography()
        self.page_glass_slate()
        self.page_components()
        self.page_imagery()
        self.page_voice_tone()
        self.page_dos_donts()
        self.page_back_cover()
        self.output(OUT_PATH)
        print(f"Brand book saved to: {OUT_PATH}")


if __name__ == "__main__":
    book = BrandBook()
    book.build()

#!/usr/bin/env python3
"""Draw the nine-pointed star emblem as an SVG on a transparent square.

usage: star.py <out.svg> [size]

The star itself is the {9/3} figure, three interlaced equilateral triangles,
gilded by splitting each point into a lit and a shaded facet. Behind it sit a
{9/4} line star, two rings and a circlet of nine and eighteen beads.
"""
import math
import sys

out = sys.argv[1]
S = int(sys.argv[2]) if len(sys.argv) > 2 else 2000
C = S / 2
R = S * 0.29                                                    # tip radius
r = R * math.cos(math.pi * 3 / 9) / math.cos(math.pi * 2 / 9)   # valley radius of {9/3}

GOLD_LIGHT = (0xF6, 0xDF, 0xA4)
GOLD_DARK = (0x8E, 0x66, 0x28)
LINE = "#D9AE5B"
LIGHT_FROM = 315  # degrees clockwise from the top: upper left


def pt(radius, deg):
    a = math.radians(deg - 90)
    return C + radius * math.cos(a), C + radius * math.sin(a)


def poly(points):
    return " ".join(f"{x:.2f},{y:.2f}" for x, y in points)


def shade(deg):
    t = 0.5 + 0.5 * math.cos(math.radians(deg - LIGHT_FROM))
    t = t ** 1.3
    rgb = [round(d + (l - d) * t) for l, d in zip(GOLD_LIGHT, GOLD_DARK)]
    return "#%02X%02X%02X" % tuple(rgb)


parts = []
w = S / 1000  # one stroke unit

# Rings and beads.
parts.append(f'<circle cx="{C}" cy="{C}" r="{R * 1.47:.2f}" fill="none" stroke="{LINE}" '
             f'stroke-width="{2.6 * w:.2f}" stroke-opacity="0.55"/>')
parts.append(f'<circle cx="{C}" cy="{C}" r="{R * 1.52:.2f}" fill="none" stroke="{LINE}" '
             f'stroke-width="{1.0 * w:.2f}" stroke-opacity="0.35"/>')
parts.append(f'<circle cx="{C}" cy="{C}" r="{R * 1.13:.2f}" fill="none" stroke="{LINE}" '
             f'stroke-width="{1.0 * w:.2f}" stroke-opacity="0.22"/>')
for k in range(9):
    x, y = pt(R * 1.62, 40 * k)
    parts.append(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{5.5 * w:.2f}" fill="{LINE}" fill-opacity="0.75"/>')
    x, y = pt(R * 1.62, 40 * k + 20)
    parts.append(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{2.6 * w:.2f}" fill="{LINE}" fill-opacity="0.45"/>')

# {9/4} line star inscribed in the inner ring.
lines = [pt(R * 1.47, 40 * ((4 * i) % 9)) for i in range(9)]
parts.append(f'<polygon points="{poly(lines)}" fill="none" stroke="{LINE}" '
             f'stroke-width="{1.4 * w:.2f}" stroke-opacity="0.32" stroke-linejoin="miter"/>')

# The gilded {9/3} star, two facets per point.
for k in range(9):
    tip = pt(R, 40 * k)
    left = pt(r, 40 * k - 20)
    right = pt(r, 40 * k + 20)
    parts.append(f'<polygon points="{poly([(C, C), left, tip])}" fill="{shade(40 * k - 90)}"/>')
    parts.append(f'<polygon points="{poly([(C, C), tip, right])}" fill="{shade(40 * k + 90)}"/>')

outline = []
for k in range(9):
    outline += [pt(R, 40 * k), pt(r, 40 * k + 20)]
parts.append(f'<polygon points="{poly(outline)}" fill="none" stroke="#F8E6B4" '
             f'stroke-width="{1.6 * w:.2f}" stroke-opacity="0.7" stroke-linejoin="miter"/>')

with open(out, "w") as f:
    f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">\n')
    f.write("\n".join(parts))
    f.write("\n</svg>\n")

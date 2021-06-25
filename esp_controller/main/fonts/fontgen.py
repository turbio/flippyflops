#
# FontGen
# Author: Jared Sanson (jared@jared.geek.nz)
#
# Requires Python Imaging Library (PIL)
#
# To add a new font, create a new FONT dictionary and tweak the parameters
# until the output .png looks correct.
# Monospaced fonts work best, but some variable-width ones work well too.
#
# Once the png file looks good, you can simply include the .h file in your
# project and use it. (how you use it is up to you)
#

from PIL import Image, ImageFont, ImageDraw
import os.path

# MONOSPACE:
#FONT = {'fname': r'pzim3x5.ttf', 'size': 9, 'yoff':1, 'w': 3, 'h': 8}
#FONT = {'fname': r'5x5.ttf', 'size': 10, 'yoff':-2, 'w': 6, 'h': 8}
#FONT = {'fname': r'BMSPA.ttf', 'size': 9, 'yoff':0, 'w': 8, 'h': 8} #NOTE: add .upper() because lower characters are broken
#FONT = {'fname': r'BMplain.ttf', 'size': 7, 'yoff':0, 'w': 6, 'h': 8}
#FONT = {'fname': r'bubblesstandard.ttf', 'size': 15, 'yoff':-1, 'w': 7, 'h': 8}
#FONT = {'fname': r'7linedigital.ttf', 'size': 8, 'yoff':0, 'w': 4, 'h': 8}  # 7-seg. NOTE: can't display certain letters like 'M'
#FONT = {'fname': r'HUNTER.ttf', 'size': 9, 'yoff':-1, 'w': 8, 'h': 8}
#FONT = {'fname': r'm38.ttf', 'size': 8, 'yoff':-0, 'w': 8, 'h': 8}
#FONT = {'fname': r'formplex12.ttf', 'size': 11, 'yoff':0, 'w': 8, 'h': 8}
#FONT = {'fname': r'sloth.ttf', 'size': 15, 'yoff':-2, 'w': 6, 'h': 8}

# VARIABLE-WIDTH:
#FONT = {'fname': r'SUPERDIG.ttf', 'size': 9, 'yoff':-1, 'w': 6, 'h': 8} # Missing some symbols
#FONT = {'fname': r'tama_mini02.TTF', 'size': 11, 'yoff': -2, 'w': 5, 'h': 8}
#FONT = {'fname': r'homespun.ttf', 'size': 9, 'yoff':-1, 'w': 7, 'h': 8}  # Non-monospaced
#FONT = {'fname': r'zxpix.ttf', 'size': 10, 'yoff':-2, 'w': 6, 'h': 8}
#FONT = {'fname': r'Minimum.ttf', 'size': 16, 'yoff':-8, 'w': 6, 'h': 8}
FONT = {'fname': r'Minimum+1.ttf', 'size': 16, 'yoff':-8, 'w': 7, 'h': 8}
#FONT = {'fname': r'HISKYF21.ttf', 'size': 9, 'yoff':0, 'w': 6, 'h': 8}
#FONT = {'fname': r'renew.ttf', 'size': 8, 'yoff':-2, 'w': 7, 'h': 8}
#FONT = {'fname': r'acme_5_outlines.ttf', 'size': 8, 'yoff':-5, 'w': 6, 'h': 8}
#FONT = {'fname': r'haiku.ttf', 'size': 11, 'yoff':-2, 'w': 6, 'h': 8}
#FONT = {'fname': r'aztech.ttf', 'size': 16, 'yoff':-1, 'w': 6, 'h': 8}
#FONT = {'fname': r'Commo-Monospaced.otf', 'size': 8, 'yoff':-6, 'w': 8, 'h': 8}
#FONT = {'fname': r'crackers.ttf', 'size': 21, 'yoff':-4, 'w': 6, 'h': 8}
#FONT = {'fname': r'Blokus.otf', 'size': 9, 'yoff':-2, 'w': 6, 'h': 8}

#TODO: Support variable-width character fonts

FONT_FILE = FONT['fname']
FONT_SIZE = FONT['size']
FONT_Y_OFFSET = FONT.get('yoff', 0)

CHAR_WIDTH = FONT.get('w', 5)
CHAR_HEIGHT = FONT.get('h', 8)

FONT_BEGIN = ' '
FONT_END = '~'
#FONTSTR = ''.join(chr(x).upper() for x in range(ord(FONT_BEGIN), ord(FONT_END)+1))
FONTSTR = ''.join(chr(x) for x in range(ord(FONT_BEGIN), ord(FONT_END)+1))

OUTPUT_NAME = os.path.splitext(FONT_FILE)[0] + '_font'
OUTPUT_PNG = OUTPUT_NAME + '.png'
OUTPUT_H = OUTPUT_NAME + '.h'

GLYPH_WIDTH = CHAR_WIDTH + 1

WIDTH = GLYPH_WIDTH * len(FONTSTR)
HEIGHT = CHAR_HEIGHT

img = Image.new("RGBA", (WIDTH, HEIGHT), (255,255,255))
#fnt = ImageFont.load_default()
fnt = ImageFont.truetype(FONT_FILE, FONT_SIZE)

drw = ImageDraw.Draw(img)
#drw.fontmode = 1

for i in range(len(FONTSTR)):
    drw.text((i*GLYPH_WIDTH,FONT_Y_OFFSET), FONTSTR[i], (0,0,0), font=fnt)

img.save(OUTPUT_PNG)

#### Convert to C-header format
f = open(OUTPUT_H, 'w')
num_chars = len(FONTSTR)
f.write('const unsigned char font[%d][%d] = {\n' % (num_chars+1, CHAR_WIDTH))

chars = []
for i in range(num_chars):
    ints = []
    for j in range(CHAR_WIDTH):
        x = i*GLYPH_WIDTH + j
        val = 0
        for y in range(CHAR_HEIGHT):
            rgb = img.getpixel((x,y))
            val = (val >> 1) | (0x80 if rgb[0] == 0 else 0)

        ints.append('0x%.2x' % (val))
    c = FONTSTR[i]
    if c == '\\': c = '"\\"' # bugfix
    f.write('\t{%s}, // %s\n' % (','.join(ints), c))


f.write('\t{%s}\n' % (','.join(['0x00']*CHAR_WIDTH)))
f.write('};\n\n')

f.write('#define FONT_NAME "%s"\n' % OUTPUT_NAME)

f.close()

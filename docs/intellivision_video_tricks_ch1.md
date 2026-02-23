# Chapter 1: Intellivision Video Tricks

*From the book by Oscar Toledo G.*

---

The Intellivision is a game console capable of displaying 159×96 pixels on the TV screen. It can show eight movable objects on screen (known as MOB or SPRITE in the IntyBASIC jargon). It also has sixteen colors designed in the STIC (Standard Television Interface Circuit).

There are 64 definable bitmaps in GRAM memory, and there are 256 predefined bitmaps in GROM memory. We'll discuss first the fine details of the two video modes.

The first important thing is the background/foreground distinction. The background is any bit set to zero in definable bitmaps or GROM memory. And the foreground is any bit set to one in definable bitmaps or GROM memory.

This difference is important for the color selection in your game.

All the information in this chapter serves to complement my previous book.

---

## 1.1 Color Stack Mode

The Color Stack mode is enabled by reading the $0021 address at the time of a video interrupt (this is already handled by IntyBASIC when you use the sentence `MODE 0`).

The Color Stack mode sets the background color as an array of 4 colors that can be chosen from the 16 available. When the display starts being drawn, the color stack points to the first of the 4 colors. This pointer is advanced immediately whenever Bit 13 of the card is set to one, equivalent to mask $2000 (take note it doesn't work for Colored Squares cards).

This mode also allows to show the 64 definable bitmaps from GRAM memory. The foreground color can be any of the 16 colors.

All of the GROM predefined bitmaps can be shown (see appendix C), including lowercase letters, but the foreground color is limited to the colors 0-7.

Sprites (MOB) are able to use the GRAM defined bitmaps, but also can refer to all of the GROM predefined bitmaps.

Since bitmask $2000 advances the color stack pointer immediately, it can be used to get twice as many GROM predefined bitmaps, because you can use these in inverse video mode.

### Example: Inverse Video Shapes

```basic
' Test inverse video shapes
' by Oscar Toledo G.
' Creation date: Dec/31/2020

CLS
MODE 0,0,7,0,7    ' Color Stack mode, black, white, black, white
WAIT

#backtab(24) = 96 * 8 + 7           ' White over black
#backtab(25) = 96 * 8 + 0 + $2000   ' Black over white
#backtab(26) = 96 * 8 + 7 + $2000   ' White over black
#backtab(27) = 96 * 8 + 0 + $2000   ' Black over white
#backtab(28) = $2000                 ' Return to black bkgnd.

WHILE 1: WEND
```

Refer to appendix C for the GROM shapes. In this case we used GROM card 96. Notice how `#backtab(28)` is assigned in order to prevent the remainder of the screen from being white.

The Color Stack mode is useful because it allows to have lowercase letters and all of the GROM predefined cards. You have only four background colors, but repeating those two colors allows you to switch easily between two background colors. Using the full four background colors is more useful when your screen is divided in areas, for example: a top line with blue background, a middle area with black background, and a bottom area with red background.

### Example: Areas in Color Stack Mode

```basic
' Example of areas in Color Stack mode
' by Oscar Toledo G.
' Creation date: Dec/31/2020

CLS
MODE 0,1,0,2,0
WAIT

' The display starts with the first background color

#backtab(20) = $2000    ' Switch to second background color

#backtab(160) = $2000   ' Switch to third background color

WHILE 1: WEND
```

The fact that you have the whole GROM accessible also helps when doing full screen graphics because the GRAM only allows to define 64 8×8 cards, and this isn't enough to cover a whole screen. You can design screens using the GROM shapes, and pass these through IntyColor. IntyBASIC will automatically use the GROM shapes if using the Color Stack mode, and the file `grom.bin` is available in the same directory.

Another advantage of this mode is the availability of the Colored Squares mode, allowing to use any of colors 0-6 for 4×4 pixels inside the 8×8 area, and using the color 7 as direct access to the current Color Stack.

IntyBASIC distribution includes an example of how to use the Colored Squares mode contributed by Mark Ball. It is in the folder "contrib/ColouredSquares.bas".

In order to use a card with Colored Squares mode, the card bits should be mapped like this:

| bit | 13 | 12 | 11 | 10 | 9  | 8  | 7  | 6  | 5  | 4  | 3  | 2  | 1  | 0  |
|-----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
|     | p3 | 1  | 0  | p3 | p3 | p2 | p2 | p2 | p2 | p1 | p1 | p1 | p0 | p0 | p0 |

Where each pixel is mapped like this into the card:

```
+----+----+
| p0 | p1 |
+----+----+
| p2 | p3 |
+----+----+
```

---

## 1.2 Foreground/Background Mode

The Foreground/Background mode is enabled by writing any value to the address $0021 at the time of a video interrupt (this is already handled by IntyBASIC when using the sentence `MODE 1`).

This mode allows to use the colors 0-7 for the foreground color, and the colors 0-15 for the background color.

Only cards 0-63 from GROM are available (again see appendix C). This is also enforced for sprites (MOB). This means that the lowercase letters and the predefined graphic shapes aren't available, but you have access to the uppercase letters, symbols, and digits.

The color stack isn't used in this mode, and the Colored Squares mode also isn't available.

However, this mode allows to draw highly detailed graphic images that can use shadow tricks because it allows all the sixteen colors for background. I've used this method to draw more recognizable faces for the game Cinemaware's Defender of the Crown, developed for Intellivision by Arnauld Chevallier, and published by Elektronite.

More recently I did a picture of my wife Rosa Nely (RIP) for an homage of three free games published in Atariage.

> Reference: https://atariage.com/forums/topic/314943-in-memory-of-rosa-nely/

I'll describe the conversion process as it can be useful. It is good only for small images due to the 64 GRAM-card limitation of the Intellivision. For this I've used Windows XP SP3, and Paint.NET 3.5.11.

---

## 1.3 Image Conversion Process

The first step is to have a good quality picture. It needs to have enough contrast, for example, to distinguish the background from the hair.

### Step 1: Prepare the Source Image

The source picture should be the best one available for the conversion, however it may be rotated in a difficult angle. This can be solved in Paint.NET by using the **Layers → Rotate & Zoom** option. Apply the required degree rotation in the Angle field.

### Step 2: Select and Extract

From the rotated image, select a square region using the **Rectangle Select** tool:
- For a 64×64 pixel final image, select a 292×292 pixel square (this gives approximately 4.5× downscaling ratio)
- Press **Ctrl+C** to copy it to the clipboard
- Select **Edit → Paste in to New Image**

This creates a new working image at the correct aspect ratio for conversion.

---

## Portrait Examples: Defender of the Crown

Different versions of the portraits used in the game Defender of the Crown for the Intellivision demonstrate the effectiveness of these techniques:

**Original portraits (2012):** Created using Color Stack mode

**Converted portraits:** Created from original Amiga images using the same method described above, using Foreground/Background mode

**Key differences:**
- The Foreground/Background mode versions have higher picture fidelity
- However, the lowercase letters are lost in this mode
- The trade-off is between text flexibility and image quality

### Character Examples:
- **Wilfred of Ivanhoe** - Leadership: Good, Jousting: Good, Swordplay: Average
- **Geoffrey Longsword** - Leadership: Average, Jousting: Average, Swordplay: Strong
- **Cedric of Rotherwood** - Leadership: Strong, Jousting: Good, Swordplay: Weak
- **Wolfric the Wild** - Leadership: Average, Jousting: Strong, Swordplay: Average

---

## Quick Reference

### Mode Comparison

| Feature | Color Stack (MODE 0) | Foreground/Background (MODE 1) |
|---------|---------------------|-------------------------------|
| Background colors | 4 from stack (any of 16) | Any of 16 per card |
| Foreground colors | 16 for GRAM, 0-7 for GROM | 0-7 only |
| GROM cards available | All 256 | Cards 0-63 only |
| Lowercase letters | Yes | No |
| Colored Squares | Yes | No |
| Best for | Text-heavy games, varied backgrounds | Detailed graphics, portraits |

### Key Memory Addresses

- `$0021` - Video mode control
- `$2000` - Color stack advance bitmask

### IntyBASIC Commands

- `MODE 0,c1,c2,c3,c4` - Color Stack mode with 4 background colors
- `MODE 1` - Foreground/Background mode
- `#backtab(n)` - Direct BACKTAB access for card n

---

*End of Chapter 1, Pages 1-6*

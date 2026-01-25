	ROMW 16
intybasic_map:	equ 2	; ROM map used
intybasic_jlp:	equ 0	; JLP is used
intybasic_cc3:	equ 0	; CC3 is used and where is RAM
intybasic_ecs:	equ 0	; Forces to include ECS startup
intybasic_voice:	equ 1	; Forces to include voice library
intybasic_flash:	equ 0	; Forces to include Flash memory library
	IF DEFINED __FEATURE.CFGVAR
		CFGVAR "voice" = 1
	ENDI
intybasic_scroll:	equ 0	; Forces to include scroll library
intybasic_col:	equ 0	; Forces to include collision detection
intybasic_keypad:	equ 1	; Forces to include keypad library
intybasic_music:	equ 1	; Forces to include music library
intybasic_music_ecs:	equ 0	; Forces to include music library
intybasic_music_volume:	equ 0	; Forces to include music volume change
intybasic_stack:	equ 0	; Forces to include stack overflow checking
intybasic_numbers:	equ 1	; Forces to include numbers library
intybasic_fastmult:	equ 1	; Forces to include fast multiplication
intybasic_fastdiv:	equ 0	; Forces to include fast division/remainder
	;
	; Prologue for IntyBASIC programs
	; by Oscar Toledo G.  http://nanochess.org/
	;
	; Revision: Jan/30/2014. Spacing adjustment and more comments.
	; Revision: Apr/01/2014. It now sets the starting screen pos. for PRINT
	; Revision: Aug/26/2014. Added PAL detection code.
	; Revision: Dec/12/2014. Added optimized constant multiplication routines.
	;                        by James Pujals.
	; Revision: Jan/25/2015. Added marker for automatic title replacement.
	;                        (option --title of IntyBASIC)
	; Revision: Aug/06/2015. Turns off ECS sound. Seed random generator using
	;                        trash in 16-bit RAM. Solved bugs and optimized
	;                        macro for constant multiplication.
	; Revision: Jan/12/2016. Solved bug in PAL detection.
	; Revision: May/03/2016. Changed in _mode_select initialization.
	; Revision: Jul/31/2016. Solved bug in multiplication by 126 and 127.
	; Revision: Sep/08/2016. Now CLRSCR initializes screen position for PRINT,
	;                        this solves bug when user programs goes directly
	;                        to PRINT.
	; Revision: Oct/21/2016. Accelerated MEMSET.
	; Revision: Jan/09/2018. Adjusted PAL/NTSC constant.
	; Revision: Feb/05/2018. Forces initialization of Intellivoice if included.
	;                        So VOICE INIT ceases to be dangerous.
	; Revision: Oct/30/2018. Redesigned PAL/NTSC detection using intvnut code,
	;                        also now compatible with Tutorvision. Reformatted.
	; Revision: Jan/10/2018. Added ECS detection.
	;

    LISTING "off"

;;==========================================================================;;
;; IntyBASIC SDK Library: romseg-bs.mac                                     ;;
;;--------------------------------------------------------------------------;;
;;  This macro library is used by the IntyBASIC SDK to manage ROM address   ;;
;;  segments and generate statistics on program ROM usage.  It is an        ;;
;;  extension of the "romseg.mac" macro library with added support for      ;;
;;  bank-switching.                                                         ;;
;;                                                                          ;;
;;  The library is based on a similar module created for the P-Machinery    ;;
;;  programming framework, which itself was based on the "CART.MAC" macro   ;;
;;  library originally created by Joe Zbiciak and distributed as part of    ;;
;;  the SDK-1600 development kit.                                           ;;
;;--------------------------------------------------------------------------;;
;;      The file is placed into the public domain by its author.            ;;
;;      All copyrights are hereby relinquished on the routines and data in  ;;
;;      this file.  -- James Pujals (DZ-Jay), 2024-2025                     ;;
;;==========================================================================;;

;; ======================================================================== ;;
;;  ROM MANAGEMENT STRUCTURES                                               ;;
;; ======================================================================== ;;

                ; Internal ROM information structure
_rom            STRUCT  0
@@null          QEQU    0
@@invalid       QEQU    -1

@@legacy        QEQU    0
@@static        QEQU    1
@@dynamic       QEQU    2

@@mapcnt        QEQU    9
@@pgsize        QEQU    4096

@@open          QSET    @@invalid
@@error         QSET    @@null

@@segcnt        QSET    0
@@segs          QSET    0
                ENDS

.ROM            STRUCT  0
@@CurrentSeg    QSET    _rom.invalid    ; No open segment

@@Size          QSET    0
@@Used          QSET    0
@@Available     QSET    0

                ; Initialize segment counters
@@Segments[_rom.legacy ]    QSET    0
@@Segments[_rom.static ]    QSET    0
@@Segments[_rom.dynamic]    QSET    0

                ENDS

_rom_stat       STRUCT  0
@@space         QEQU    "                                                                           " ; 75
@@single        QEQU    "---------------------------------------------------------------------------"
@@double        QEQU    "==========================================================================="
                ENDS


;; ======================================================================== ;;
;;  __rom_raise_error(err, desc)                                            ;;
;;  Generates an assembler error and sets the global error flag.            ;;
;;                                                                          ;;
;;  NOTE:   Both strings must be devoid of semi-colons and commas, or       ;;
;;          Bad Things(tm) may happen during pre-processing.                ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      err         The error message.                                      ;;
;;      desc        Optional error description, or _rom.null if none.       ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 (failed).                                            ;;
;; ======================================================================== ;;
MACRO   __rom_raise_error(err, desc)
;
    LISTING "off"

_rom.error      QSET    _rom.invalid

_rom.err_len    QSET    _rom.null
_rom.err_len    QSET    %desc%

        IF (_rom.err_len <> _rom.null)
            ERR  $(%err%, ": ", %desc%)
        ELSE
            ERR  $(%err%)
        ENDI

    LISTING "prev"
ENDM

;; ======================================================================== ;;
;;  __rom_reset_error                                                       ;;
;;  Resets the global error flag.                                           ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      None.                                                               ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  0 (no error)                                            ;;
;; ======================================================================== ;;
MACRO   __rom_reset_error
;
_rom.error      QSET    _rom.null
ENDM

;; ======================================================================== ;;
;;  __rom_validate_map(map)                                                 ;;
;;  Validates the requested ROM map.                                        ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      map         The ROM map selected. Valid values are 0 to 7.          ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_validate_map(map)
;
_rom.max        QSET    (_rom.mapcnt - 1)

        IF (((%map%) < 0) OR ((%map%) > _rom.max))
            __rom_raise_error(["Invalid ROM map number (", $#(%map%), ")"], ["Valid maps are from 0 to ", $#(_rom.max), "."])
        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_validate_type(type)                                               ;;
;;  Validates the requested segment type symbol.                            ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      type        The segment type to validate.                           ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_validate_type(type)
;
        IF ((CLASSIFY(_rom.%type%) = -10000))
            __rom_raise_error("Invalid ROM segment type \"%type%\".", _rom.null)
        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_validate_segment(seg)                                             ;;
;;  Validates the requested segment number to ensure it is supported by the ;;
;;  active memory map.                                                      ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      seg         The segment number to validate.                         ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_validate_segment(seg)
;
        IF ((CLASSIFY(_rom.segidx[%seg%]) = -10000))
            __rom_raise_error(["Invalid ROM segment number #", $#(%seg%), " for selected memory map."], _rom.null)
        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_validate_seg_bank(seg, bank)                                      ;;
;;  Validates the requested dynamic segment and bank number to ensure it is ;;
;;  supported by the active memory map.                                     ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      seg         The segment number to validate, or -1 for the first one.;;
;;      bank        The dynamic segment bank number to validate.            ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_validate_seg_bank(seg, bank)
;
        ; First, check if the map supports dynamic segments at all
        IF (.ROM.Segments[_rom.dynamic] = 0)
                __rom_raise_error("The selected memory map does not support dynamic segments.", _rom.null)
        ENDI

        ; Validate the segment
        IF (_rom.error = _rom.null)
                __rom_validate_segment(%seg%)
        ENDI

        ; Validate the bank
        IF (_rom.error = _rom.null)

_rom.num    QSET    _rom.segidx[%seg%]
_rom.max    QSET    (_rom.bnkcnt[_rom.num] - 1)

            IF (((%bank%) < 0) OR ((%bank%) > _rom.max))
                __rom_raise_error(["Invalid bank number #", $#(%bank%), " for dynamic ROM segment #", $#(%seg%)], ["Must be between 0 and ", $#(_rom.max), "."])
            ENDI

        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_validate_segnum(segnum)                                           ;;
;;  Validates the requested internal segment number to ensure that it is    ;;
;;  valid within the active memory map.                                     ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      segnum      The internal memory map segment number to validate.     ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_validate_segnum(segnum)
;
        IF _EXPMAC ((CLASSIFY(_rom.t[%segnum%]) = -10000))
            __rom_raise_error(["Unknown internal ROM segment number #", $#(%segnum%), "."], _rom.null)
        ELSE

_rom.type   QSET    _rom.t[%segnum%]
_rom.max    QSET    (.ROM.Segments[_rom.type] - 1)

            IF _EXPMAC (((%segnum%) < 0) OR ((%segnum%) > _rom.max))
                __rom_raise_error(["Invalid internal segment number #", $#(%segnum%), " for selected memory map"], ["Must be a value between 0 and ", $#(_rom.max), "."])
            ENDI

        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_assert_setup(label)                                               ;;
;;  Ensures that ROM.Setup has been called.                                 ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      label       A quoted-string containing the label of the asserting   ;;
;;                  macro or function.                                      ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_assert_setup(label)
;
        IF ((CLASSIFY(_rom.init) = -10000))
            __rom_raise_error(["ROM", ".Setup directive must be used before calling ROM.", %label%, "."], _rom.null)
        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_assert_romseg_support(label)                                      ;;
;;  Prevents the invocation of a feature that is not supported by the       ;;
;;  legacy memory map when ROM map #0 is selected.                          ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      label       A quoted-string containing the label of the asserting   ;;
;;                  macro or function.                                      ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_assert_romseg_support(label)
;
        IF (_rom.map = 0)
            __rom_raise_error([%label%, " failed"], ["Legacy ROM map #", $#(_rom.map), " does not support it."])
        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_assert_def_order(type)                                            ;;
;;  Ensures that segments are defined in the proper order:  all legacy and  ;;
;;  static segments first, followed by all dynamic ones.                    ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      type        The segment type to check.                              ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_assert_def_order(type)
;
_rom.type   QSET    _rom.%type%

        ; Make sure all dynamic segments are defined last
        IF (((_rom.type = _rom.legacy) OR (_rom.type = _rom.static)) AND (.ROM.Segments[_rom.dynamic] > 0))
            __rom_raise_error("Invalid ROM segment definition order", "All static and legacy segments must be defined before any dynamic ones.")
        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_segmem_size(segnum)                                               ;;
;;  Computes the total size of a ROM segment.                               ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      segnum      The internal segment for which to compute the size.     ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      None.                                                               ;;
;; ======================================================================== ;;
MACRO   __rom_segmem_size(segnum)
;
.ROM.SegSize[%segnum%]  QSET (_rom.e[%segnum%] - _rom.b[%segnum%] + 1)
ENDM

;; ======================================================================== ;;
;;  __rom_segmem_used(segnum)                                               ;;
;;  Computes the usage of a ROM segment.                                    ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      segnum      The internal segment for which to compute the usage.    ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      None.                                                               ;;
;; ======================================================================== ;;
MACRO   __rom_segmem_used(segnum)
;
.ROM.SegUsed[%segnum%]  QSET (_rom.pos[%segnum%] - _rom.b[%segnum%])
ENDM

;; ======================================================================== ;;
;;  __rom_segmem_available(segnum)                                          ;;
;;  Computes the available space of a ROM segment.                          ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      segnum      The internal segment for which to compute the available ;;
;;                  space.                                                  ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      None.                                                               ;;
;; ======================================================================== ;;
MACRO   __rom_segmem_available(segnum)
;
.ROM.SegAvlb[%segnum%]  QSET (_rom.e[%segnum%] - _rom.pos[%segnum%] + 1)
ENDM

;; ======================================================================== ;;
;;  __rom_calculate_stats                                                   ;;
;;  Computes the total ROM size and usage statistics.                       ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      None.                                                               ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      None.                                                               ;;
;; ======================================================================== ;;
MACRO   __rom_calculate_stats
;
_rom.segnum     QSET    0

            REPEAT (_rom.segcnt)

.ROM.Size       SET     (.ROM.Size      + .ROM.SegSize[_rom.segnum])
.ROM.Used       SET     (.ROM.Used      + .ROM.SegUsed[_rom.segnum])
.ROM.Available  SET     (.ROM.Available + .ROM.SegAvlb[_rom.segnum])

_rom.segnum     QSET    (_rom.segnum + 1)

            ENDR
ENDM

;; ======================================================================== ;;
;;  __rom_init_segmem(seg, start, end, page, type)                          ;;
;;  Initializes and configures the requested memory map segment indicated   ;;
;;  by "seg," using the provided arguments.  All internal data structures   ;;
;;  for memory integrity and accounting are also initialized.               ;;
;;                                                                          ;;
;;                                                                          ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      seg         The number of the segment to initialize.                ;;
;;      start       The start address of the segment.                       ;;
;;      end         The end address of the segment.                         ;;
;;      page        An optional page number to switch the segment to.       ;;
;;      type        The type of segment:  "legacy," "static," or "dynamic". ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_init_segmem(seg, start, end, page, type)
;
                __rom_validate_type(%type%)
                __rom_assert_def_order(%type%)

        IF (_rom.error = _rom.null)

_rom.type           QSET    _rom.%type%
_rom.num            QSET    _rom.segcnt                 ; New internal segment number
_rom.segcnt         QSET    (_rom.segcnt + 1)           ; Total internal segments (so far)

            ; Keep track of the index for the given segment
            IF ((CLASSIFY(_rom.segidx[%seg%]) = -10000))
_rom.segs           QSET    (_rom.segs + 1)
_rom.segidx[%seg%]  QSET    _rom.num
_rom.bnkcnt[%seg%]  QSET    0
            ENDI

_rom.b   [_rom.num] QSET    %start%                     ; Start address
_rom.e   [_rom.num] QSET    %end%                       ; End address
_rom.p   [_rom.num] QSET    %page%                      ; Page number
_rom.t   [_rom.num] QSET    _rom.type                   ; Segment type

            IF ((%page%) <> _rom.invalid)

_rom.sbase          QSET    (_rom.b[_rom.num] AND $F000)
_rom.send           QSET    (_rom.e[_rom.num] OR  $0FFF)
_rom.spages         QSET    (((_rom.send - _rom.sbase) + 1) / _rom.pgsize)

_rom.pgs [_rom.num] QSET    _rom.spages                 ; Physical pages in segment

                ; For dynamic segments, keep track of
                ; the number of banks.
                IF (_rom.type = _rom.dynamic)
_rom.bnk [_rom.num] QSET    _rom.bnkcnt[%seg%]          ; Logical bank number
_rom.bnkcnt[%seg%]  QSET    (_rom.bnkcnt[%seg%] + 1)    ; Banks in segment
                ENDI

            ELSE

_rom.bnk [_rom.num] QSET    _rom.invalid
_rom.pgs [_rom.num] QSET    _rom.invalid

            ENDI

_rom.seg [_rom.num] QSET    %seg%
_rom.pos [_rom.num] QSET    %start%                     ; Starting position

.ROM.Segments[_rom.type] QSET   (.ROM.Segments[_rom.type] + 1)

            IF (_rom.type <> _rom.legacy)
                ; Initialize accounting statistics
                __rom_segmem_size     (_rom.num)
                __rom_segmem_used     (_rom.num)
                __rom_segmem_available(_rom.num)
            ENDI
        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_check_segmem_range(addr, segnum)                                  ;;
;;  Checks an address to make sure it falls within a given ROM segment.     ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      addr        The address to check.                                   ;;
;;      segnum      The internal segment for which to check the range.      ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;;      _rom.ovrflo The number of words in excess.                          ;;
;;      _rom.sidx   The logical segment number.                             ;;
;;      _rom.bidx   The logical bank number.                                ;;
;; ======================================================================== ;;
MACRO   __rom_check_segmem_range(addr, segnum)
;
        IF (_rom.open = %segnum%)
_rom.rbase      QSET    _rom.cb
_rom.rend       QSET    _rom.ce
        ELSE
_rom.rbase      QSET    _rom.b[%segnum%]
_rom.rend       QSET    _rom.e[%segnum%]
        ENDI


        IF _EXPMAC ((%addr%) < _rom.rbase) OR (((%addr%) - 1) > _rom.rend)

_rom.ovrflo     QSET    ((%addr%) - _rom.rend - 1)
_rom.sidx       QSET    _rom.seg[%segnum%]
_rom.bidx       QSET    _rom.bnk[%segnum%]

          ; NOTE: Overflows are significant, so we want to
          ;       display such errors in STDOUT as well.
          IF _EXPMAC (_rom.t[%segnum%] = _rom.dynamic)
            __rom_raise_error(["Dynamic ROM segment overflow in segment #", $#(_rom.sidx), ", bank #", $#(_rom.bidx)], ["Total ", $#(_rom.ovrflo), " words in excess."])

            SMSG $("ERROR: Overflow in dynamic ROM segment #", $#(_rom.sidx), ", bank #", $#(_rom.bidx), ": Total ", $#(_rom.ovrflo), " words in excess.")
          ELSE
            __rom_raise_error(["ROM segment overflow in segment #", $#(_rom.sidx)], ["Total ", $#(_rom.ovrflo), " words in excess."])

            SMSG $("ERROR: Overflow in ROM segment #", $#(_rom.sidx), ": Total ", $#(_rom.ovrflo), " words in excess.")
          ENDI
        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_set_pc_addrs(addr, page)                                          ;;
;;  Relocates the program counter to the given address, selecting a         ;;
;;  specific page if requested.                                             ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      addr        The new address to set the program counter.             ;;
;;      page        An optional page to select (or _rom.invalid if none).   ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      None.                                                               ;;
;; ======================================================================== ;;
MACRO   __rom_set_pc_addrs(addr, page)
;
        IF (%page% <> _rom.invalid)

            LISTING "on"
                ; Open segment page
                ORG     %addr%:%page%
            LISTING "prev"

        ELSE

            LISTING "on"
                ; Open segment
                ORG     %addr%
            LISTING "prev"

        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_open_seg(segnum)                                                  ;;
;;  Opens a ROM segment.  If the segment is already open, it checks the     ;;
;;  current program counter to ensure it is still within valid range.       ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      segnum      The internal memory map segment to open.                ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_open_seg(segnum)
;
                __rom_reset_error
                __rom_validate_segnum(%segnum%)

        IF _EXPMAC (_rom.error = _rom.null)

            IF _EXPMAC (_rom.open <> %segnum%)

_rom.cb         QSET    _rom.b  [%segnum%]      ; Current base address
_rom.ce         QSET    _rom.e  [%segnum%]      ; Current end address
_rom.cp         QSET    _rom.p  [%segnum%]      ; Current page

_rom.cpos       QSET    _rom.pos[%segnum%]

                __rom_set_pc_addrs(_rom.cpos, _rom.cp)

_rom.open       QSET    %segnum%
.ROM.CurrentSeg QSET    _rom.open

            ELSE

_rom.pc         QSET    $

                ; If the segment is already open, just
                ; verify we're still within in range.
                __rom_check_segmem_range(_rom.pc, %segnum%)

            ENDI

        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_close_seg(segnum)                                                 ;;
;;  Closes an open ROM segment.  It also checks that the current program    ;;
;;  counter falls within the valid range of the open segment.  Nothing will ;;
;;  be done if "segnum" is _rom.invalid.  An error is raised if the given   ;;
;;  segment is not open.                                                    ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      segnum      The internal memory map segment to close.               ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_close_seg(segnum)
;
                __rom_reset_error

        IF ((%segnum%) <> _rom.invalid)

                __rom_validate_segnum(%segnum%)

          IF (_rom.error = _rom.null)

            IF (_rom.open <> %segnum%)
                IF (_rom.t[%segnum%] = _rom.dynamic)
                  __rom_raise_error("Dynamic ROM segment closure failed", ["Bank #", $#(_rom.bnk[%segnum%]), " is not opened."])
                ELSE
                  __rom_raise_error("ROM segment closure failed", ["Segment #", $#(_rom.seg[%segnum%]), " is not opened."])
                ENDI
            ELSE

_rom.pc             QSET $

              ; Ignore legacy segments
              IF (_rom.t[%segnum%] <> _rom.legacy)

                ; Close segment
                __rom_check_segmem_range(_rom.pc, %segnum%)

                ; Keep track of current segment position
_rom.pos[%segnum%]  QSET _rom.pc

                ; Compute usage statistics
                __rom_segmem_used(%segnum%)
                __rom_segmem_available(%segnum%)

              ENDI

_rom.open           QSET _rom.invalid                   ; Close segment %segnum%
.ROM.CurrentSeg     QSET _rom.open

            ENDI

          ENDI

        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_try_open_seg(segnum, min)                                         ;;
;;  Opens a given ROM segment if it has a minimum of "min" words available. ;;
;;                                                                          ;;
;;  NOTE:   If a ROM segment is currently opened, this macro will not do    ;;
;;          anything.  This lets us chain calls to __rom_try_open_seg() for ;;
;;          all available segments, in order to attempt to find one with    ;;
;;          sufficient capacity.                                            ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      segnum      The internal memory map segment to test and open.       ;;
;;      min         The minimum size required, in 16-bit words.             ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_try_open_seg(segnum, min)
;
        IF _EXPMAC ((_rom.open = _rom.invalid) AND (%segnum% < _rom.segcnt) AND ((_rom.pos[%segnum%] + (%min%)) < _rom.e[%segnum%]))
                __rom_open_seg(%segnum%)
        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_select_segment(seg)                                               ;;
;;  Relocates the program counter to a static ROM segment.  Also closes the ;;
;;  currently open segment, keeping track of its usage.                     ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      seg         The static ROM segment to open.                         ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_select_segment(seg)
;
        IF (_rom.error = _rom.null)
                __rom_validate_segment(%seg%)
        ENDI

        IF (_rom.error = _rom.null)

_rom.segnum     QSET    _rom.segidx[%seg%]
_rom.type       QSET    _rom.t[_rom.segnum]

            ; Fail if the segment is dynamic
            IF (_rom.type = _rom.dynamic)
                __rom_raise_error(["Cannot select ROM segment #", $#(%seg%), " without a bank"], "Segment is dynamic.")
            ENDI

            ; Open static segment
            IF (_rom.type = _rom.static)
                __rom_close_seg(_rom.open)
                __rom_open_seg(_rom.segnum)
            ENDI

        ENDI
ENDM

;; ======================================================================== ;;
;;  __rom_switch_mem_page(base, page)                                       ;;
;;  Switches a range of memory addresses to a target page.                  ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      base        The base address of the range to switch.                ;;
;;      page        The target page number.                                 ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   __rom_switch_mem_page(base, page)
;
_rom.b_addr     QSET    ((%base%) AND $F000)
_rom.b_src      QSET    (_rom.b_addr OR $0A50 OR (%page%))
_rom.b_trg      QSET    (_rom.b_addr OR $0FFF)

    LISTING "on"

                MVII    #_rom.b_src, R0                 ; \_ Switch bank: [$s000 - $sFFF] to page
                MVO     R0,     _rom.b_trg              ; /

    LISTING "prev"
ENDM

;; ======================================================================== ;;
;;  __rom_stats_scale(val, scale)                                           ;;
;;  Returns value "val" scaled by "scale." The formula used for scaling is: ;;
;;                                                                          ;;
;;              return = ceil(val / scale)                                  ;;
;;                     = [((val * base) / scale) + (base - 1)] / base       ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      val         The value to scale.                                     ;;
;;      scale       The scale to apply.                                     ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      ceil(val / scale).                                                  ;;
;; ======================================================================== ;;
MACRO   __rom_stats_scale(val, scale)
    (((((%val%) * 10) / (%scale%)) + 9) / 10)
ENDM

;; ======================================================================== ;;
;;  __rom_stats_draw_line(style, len)                                       ;;
;;  Outputs a horizontal line, useful for displaying tabular information.   ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      style       The line style to draw.  Available values are:          ;;
;;                      single      Single (thin) line.                     ;;
;;                      double      Double (thick) line.                    ;;
;;                                                                          ;;
;;      len         The length of the line to draw, in characters.          ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      A horizontal line in the given style.                               ;;
;; ======================================================================== ;;
MACRO   __rom_stats_draw_line(style, len)
        _rom_stat.%style%[0, ((%len%) - 1)]
ENDM

;; ======================================================================== ;;
;;  __rom_stats_pad_left(str, len)                                          ;;
;;  Outputs a string in a field of "len" characters, justified to the right ;;
;;  and padded on the left with blank spaces.                               ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      str         The string to output.                                   ;;
;;      len         The length of the field, in characters.                 ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      The string, left-padded in the field.                               ;;
;; ======================================================================== ;;
MACRO   __rom_stats_pad_left(str, len)
        $(_rom_stat.space[0, ((%len%) - STRLEN(%str%) - 1)], %str%)
ENDM

;; ======================================================================== ;;
;;  __rom_stats_pad_right(str, len)                                         ;;
;;  Outputs a string in a field of "len" characters, justified to the left  ;;
;;  and padded on the right with blank spaces.                              ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      str         The string to output.                                   ;;
;;      len         The length of the field, in characters.                 ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      The string, right-padded in the field.                              ;;
;; ======================================================================== ;;
MACRO   __rom_stats_pad_right(str, len)
        $(%str%, _rom_stat.space[0, ((%len%) - STRLEN(%str%) - 1)])
ENDM

;; ======================================================================== ;;
;;  ROM.Setup map                                                           ;;
;;  Configures and initializes the memory map indicated by "map."           ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      map         The memory map number to initialize.                    ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   ROM.Setup map
;
    LISTING "code"

                __rom_reset_error

        ; Make sure the directive is called only once!
        IF ((CLASSIFY(_rom.init) = -10000))
                __rom_validate_map(%map%)
        ELSE
                __rom_raise_error(["ROM", ".Setup directive must be called only once per program."], _rom.null)
        ENDI

        IF (_rom.error = _rom.null)

_rom.init       QEQU    1
_rom.map        QSET    %map%
_rom.ecs_off    QSET    _rom.null
_rom.extra_rom  QSET    0

            IF (intybasic_ecs)
_rom.ecs_req    QSET    intybasic_ecs
            ELSE
_rom.ecs_req    QSET    _rom.null
            ENDI

            IF (intybasic_jlp)
_rom.jlp_req    QSET    intybasic_jlp
            ELSE
_rom.jlp_req    QSET    _rom.null
            ENDI

            IF (intybasic_cc3 OR intybasic_jlp)
_rom.cart_ram   QSET    1
            ELSE
_rom.cart_ram   QSET    _rom.null
            ENDI

            ; ---------------------------------------------------------
            ; Initialize ROM segments for active memory map.
            ;
            ; NOTE: Define below the segments available for each memory
            ;       map supported.  When defining a map, the following
            ;       rules must be observed:
            ;
            ;         - Map #0 must always be the "legacy" map.
            ;         - All static segments in a map must be defined
            ;           before any dynamic ones.
            ;         - Segment numbers must start at zero.
            ;         - Segment numbers should be defined in order.
            ;         - There must not be gaps in segment numbers.
            ; ---------------------------------------------------------

            ; MAP #0: Legacy memory map wit no ROM management
            IF (_rom.map = 0)
                __rom_init_segmem(0, $5000, $FFFF, _rom.invalid, legacy)
            ENDI

            ; MAP #1: Original Mattel 16K static memory map
            IF (_rom.map = 1)
                __rom_init_segmem(0, $5000, $6FFF, _rom.invalid, static)
                __rom_init_segmem(1, $D000, $DFFF, _rom.invalid, static)
                __rom_init_segmem(2, $F000, $FFFF, _rom.invalid, static)
            ENDI

            ; MAP #2: JLP 42K static memory map
            IF (_rom.map = 2)
_rom.ecs_off    QSET    1

                __rom_init_segmem(0, $5000, $6FFF, _rom.invalid, static)
                __rom_init_segmem(1, $A000, $BFFF, _rom.invalid, static)
                __rom_init_segmem(2, $C040, $FFFF, _rom.invalid, static)

              IF (_rom.jlp_req <> _rom.null)
                __rom_init_segmem(3, $2000, $2FFF, $F,           static)
                __rom_init_segmem(4, $7000, $7FFF, $F,           static)
              ELSE
                __rom_init_segmem(3, $2100, $2FFF, _rom.invalid, static)
                __rom_init_segmem(4, $7100, $7FFF, _rom.invalid, static)
              ENDI

                __rom_init_segmem(5, $4810, $4FFF, _rom.invalid, static)
            ENDI

            ; MAP #3: Dynamic bank-switching 98K memory map - 4K banks
            IF (_rom.map = 3)
_rom.ecs_off    QSET    1

                __rom_init_segmem(0, $5000, $6FFF, _rom.invalid, static)
                __rom_init_segmem(1, $A000, $BFFF, _rom.invalid, static)
                __rom_init_segmem(2, $C040, $FFFF, _rom.invalid, static)
                __rom_init_segmem(3, $2000, $2FFF, $F,           static)
                __rom_init_segmem(4, $4810, $4FFF, _rom.invalid, static)

_rom.dynseg     QSET    _rom.segcnt

                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $1, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $2, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $3, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $4, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $5, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $6, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $7, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $8, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $9, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $A, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $B, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $C, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $D, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $E, dynamic)
                __rom_init_segmem(_rom.dynseg, $7000, $7FFF, $F, dynamic)
            ENDI

            ; MAP #4: Dynamic bank-switching 154K memory map - 8K banks
            IF (_rom.map = 4)
_rom.ecs_off    QSET    1

                __rom_init_segmem(0, $5000, $6FFF, _rom.invalid, static)
                __rom_init_segmem(1, $A000, $BFFF, _rom.invalid, static)
                __rom_init_segmem(2, $C040, $DFFF, _rom.invalid, static)
                __rom_init_segmem(3, $2000, $2FFF, $F,           static)
                __rom_init_segmem(4, $7000, $7FFF, $F,           static)
                __rom_init_segmem(5, $4810, $4FFF, _rom.invalid, static)

_rom.dynseg     QSET    _rom.segcnt

                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $0, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $2, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $3, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $4, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $5, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $6, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $7, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $8, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $9, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $A, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $B, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $C, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $D, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $E, dynamic)
                __rom_init_segmem(_rom.dynseg, $E000, $FFFF, $F, dynamic)
            ENDI

            ; MAP #5: Dynamic bank-switching 254K memory map - 16K banks
            IF (_rom.map = 5)
_rom.ecs_off    QSET    1

                __rom_init_segmem(0, $5000, $6FFF, _rom.invalid, static)
                __rom_init_segmem(1, $A000, $BFFF, _rom.invalid, static)
                __rom_init_segmem(2, $2000, $2FFF, $F,           static)
                __rom_init_segmem(3, $7000, $7FFF, $F,           static)
                __rom_init_segmem(4, $4810, $4FFF, _rom.invalid, static)

_rom.dynseg     QSET    _rom.segcnt

                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $0, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $2, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $3, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $4, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $5, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $6, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $7, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $8, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $9, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $A, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $B, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $C, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $D, dynamic)
                __rom_init_segmem(_rom.dynseg, $C040, $FFFF, $E, dynamic)
            ENDI

            ; MAP #6: Dynamic bank-switching 256K map -- 2 dynamic segments
            IF (_rom.map = 6)
_rom.ecs_off    QSET    1

                __rom_init_segmem(0, $5000, $6FFF, _rom.invalid, static)
                __rom_init_segmem(1, $C040, $DFFF, _rom.invalid, static)

                __rom_init_segmem(2, $A000, $BFFF, $0,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $1,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $2,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $3,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $4,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $5,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $6,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $7,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $8,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $9,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $A,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $B,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $C,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $D,           dynamic)
                __rom_init_segmem(2, $A000, $BFFF, $E,           dynamic)

                __rom_init_segmem(3, $E000, $FFFF, $0,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $2,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $3,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $4,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $5,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $6,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $7,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $8,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $9,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $A,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $B,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $C,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $D,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $E,           dynamic)
                __rom_init_segmem(3, $E000, $FFFF, $F,           dynamic)
            ENDI


            ; MAP #7: Dynamic bank-switching 238K map -- 4 dynamic segments
            IF (_rom.map = 7)
_rom.ecs_off    QSET    1

                __rom_init_segmem(0, $5000, $6FFF, _rom.invalid, static)
                __rom_init_segmem(1, $2000, $2FFF, $F,           static)
                __rom_init_segmem(2, $4810, $4FFF, _rom.invalid, static)

                __rom_init_segmem(3, $7000, $7FFF, $1,           dynamic)
                __rom_init_segmem(3, $7000, $7FFF, $2,           dynamic)
                __rom_init_segmem(3, $7000, $7FFF, $3,           dynamic)
                __rom_init_segmem(3, $7000, $7FFF, $4,           dynamic)
                __rom_init_segmem(3, $7000, $7FFF, $5,           dynamic)
                __rom_init_segmem(3, $7000, $7FFF, $6,           dynamic)
                __rom_init_segmem(3, $7000, $7FFF, $7,           dynamic)
                __rom_init_segmem(3, $7000, $7FFF, $8,           dynamic)

                __rom_init_segmem(4, $A000, $BFFF, $0,           dynamic)
                __rom_init_segmem(4, $A000, $BFFF, $1,           dynamic)
                __rom_init_segmem(4, $A000, $BFFF, $2,           dynamic)
                __rom_init_segmem(4, $A000, $BFFF, $3,           dynamic)
                __rom_init_segmem(4, $A000, $BFFF, $4,           dynamic)
                __rom_init_segmem(4, $A000, $BFFF, $5,           dynamic)
                __rom_init_segmem(4, $A000, $BFFF, $6,           dynamic)
                __rom_init_segmem(4, $A000, $BFFF, $7,           dynamic)

                __rom_init_segmem(5, $C040, $DFFF, $0,           dynamic)
                __rom_init_segmem(5, $C040, $DFFF, $1,           dynamic)
                __rom_init_segmem(5, $C040, $DFFF, $2,           dynamic)
                __rom_init_segmem(5, $C040, $DFFF, $3,           dynamic)
                __rom_init_segmem(5, $C040, $DFFF, $4,           dynamic)
                __rom_init_segmem(5, $C040, $DFFF, $5,           dynamic)
                __rom_init_segmem(5, $C040, $DFFF, $6,           dynamic)
                __rom_init_segmem(5, $C040, $DFFF, $7,           dynamic)

                __rom_init_segmem(6, $E000, $FFFF, $0,           dynamic)
                __rom_init_segmem(6, $E000, $FFFF, $2,           dynamic)
                __rom_init_segmem(6, $E000, $FFFF, $3,           dynamic)
                __rom_init_segmem(6, $E000, $FFFF, $4,           dynamic)
                __rom_init_segmem(6, $E000, $FFFF, $5,           dynamic)
                __rom_init_segmem(6, $E000, $FFFF, $6,           dynamic)
                __rom_init_segmem(6, $E000, $FFFF, $7,           dynamic)
                __rom_init_segmem(6, $E000, $FFFF, $8,           dynamic)
            ENDI

            ; MAP #8: 50K static memory map
            IF (_rom.map = 8)
_rom.extra_rom  QSET    1

                __rom_init_segmem(0, $5000, $6FFF, _rom.invalid, static)
                __rom_init_segmem(1, $A000, $BFFF, _rom.invalid, static)
                __rom_init_segmem(2, $C040, $FFFF, _rom.invalid, static)
                __rom_init_segmem(3, $2100, $2FFF, _rom.invalid, static)
                __rom_init_segmem(4, $7100, $7FFF, _rom.invalid, static)

                __rom_init_segmem(5, $4810, $4FFF, _rom.invalid, static)
                __rom_init_segmem(6, $8040, $9FFF, _rom.invalid, static)
            ENDI

        ENDI

        ; Check if cartridge RAM conflicts with extra ROM at $8040
        IF (_rom.cart_ram AND _rom.extra_rom)
          __rom_raise_error(["Map #", $#(_rom.map), " is not compatible with JLP or CC3 cartridge RAM."], _rom.null)

          SMSG $("ERROR: Map #", $#(_rom.map), " is not compatible with JLP or CC3 cartridge RAM.")
        ENDI

        IF (_rom.error = _rom.null)

                ; Disable ECS in advanced maps and when ECS is used.
            IF ((_rom.ecs_off <> _rom.null) OR (_rom.ecs_req))
                __rom_set_pc_addrs($4800, _rom.invalid) ; Set up bootstrap hook

                __rom_switch_mem_page($2000, $F)        ; \
                __rom_switch_mem_page($7000, $F)        ;  > Switch off ECS ROMs
                __rom_switch_mem_page($E000, $F)        ; /

                B       $1041                           ; resume boot
            ENDI

                ; Initialize ROM base to segment #0
                ;   ($5000 - $6FFF in all maps)
                __rom_open_seg(0)

                ; ------------------------------------------------
                ; Configure the ROM header (Universal Data Block)
                ; ------------------------------------------------
                BIDECLE _ZERO           ; MOB picture base
                BIDECLE _ZERO           ; Process table
                BIDECLE _MAIN           ; Program start
                BIDECLE _ZERO           ; Background base image
                BIDECLE _ONES           ; GRAM
                BIDECLE _TITLE          ; Cartridge title and date
                DECLE   $03C0           ; No ECS title, jump to code after title,
                                        ; ... no clicks

_ZERO:          DECLE   $0000           ; Border control
                DECLE   $0000           ; 0 = color stack, 1 = f/b mode

_ONES:          DECLE   $0001, $0001    ; Initial color stack 0 and 1: Blue
                DECLE   $0001, $0001    ; Initial color stack 2 and 3: Blue
                DECLE   $0001           ; Initial border color: Blue

        ENDI

    LISTING "prev"
ENDM

;; ======================================================================== ;;
;;  ROM.SelectDefaultSegment                                                ;;
;;  Relocates the program counter to the default ROM segment (#0).  Also    ;;
;;  closes the currently open segment, keeping track of its usage.          ;;
;;                                                                          ;;
;;  The macro will do nothing when the legacy map (#0) is selected.         ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      None.                                                               ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   ROM.SelectDefaultSegment
;
    LISTING "code"

                __rom_reset_error
                __rom_assert_setup("SelectSegment")

        IF (_rom.error = _rom.null)

            ; Ignore when the legacy map is selected
            IF (_rom.map > 0)
                __rom_select_segment(0)
            ENDI

        ENDI

    LISTING "prev"
ENDM

;; ======================================================================== ;;
;;  ROM.SelectSegment seg                                                   ;;
;;  Relocates the program counter to a static ROM segment.  Also closes the ;;
;;  currently open segment, keeping track of its usage.                     ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      seg         The static ROM segment to open.                         ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   ROM.SelectSegment seg
;
    LISTING "code"

                __rom_reset_error
                __rom_assert_romseg_support("Segment selection")
                __rom_assert_setup("SelectSegment")

        IF (_rom.error = _rom.null)
                __rom_select_segment(%seg%)
        ENDI

    LISTING "prev"
ENDM

;; ======================================================================== ;;
;;  ROM.SelectBank seg, bank                                                ;;
;;  Relocates the program counter to a dynamic ROM segment bank.  Also      ;;
;;  closes the currently open segment, keeping track of its usage.          ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      seg         The dynamic ROM segment, or -1 for the first one.       ;;
;;      bank        The segment bank number to open.                        ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   ROM.SelectBank seg, bank
;
    LISTING "code"

                __rom_reset_error
                __rom_assert_romseg_support("Dynamic segment bank selection")
                __rom_assert_setup("SelectBank")

        IF (_rom.error = _rom.null)

            ; Determine the logical segment number
            IF ((%seg%) = _rom.invalid)
_rom.num        QSET    .ROM.Segments[_rom.static]
            ELSE
_rom.num        QSET    %seg%
            ENDI

_rom.type       QSET    _rom.t[_rom.num]

            ; Fail if the segment is not dynamic
            IF (_rom.type <> _rom.dynamic)
                __rom_raise_error(["Cannot select bank on ROM segment #", $#(_rom.num)], "Segment is not dynamic.")
            ENDI

            ; Validate the segment and bank
            IF (_rom.error = _rom.null)
                __rom_validate_seg_bank(_rom.num, %bank%)
            ENDI

            IF (_rom.error = _rom.null)

_rom.segnum     QSET    (_rom.segidx[_rom.num] + (%bank%))

              IF (_rom.segnum <> _rom.open)
                ; Open dynamic segment bank
                IF (_rom.error = _rom.null)
                  __rom_close_seg(_rom.open)
                  __rom_open_seg(_rom.segnum)
                ENDI
              ENDI

            ENDI

        ENDI

    LISTING "prev"
ENDM

;; ======================================================================== ;;
;;  ROM.AutoSelectSegment min                                               ;;
;;  Finds a static ROM segment with the specified minimum available         ;;
;;  capacity, and relocates the program counter to it.  Also closes the     ;;
;;  currently open segment, keeping track of its usage statistics.          ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      min         The minimum capacity required, in 16-bit words.         ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   ROM.AutoSelectSegment min
;
    LISTING "code"

                __rom_reset_error
                __rom_assert_romseg_support("Automatic segment selection")
                __rom_assert_setup("AutoSelectSegment")

        IF (_rom.error = _rom.null)
                __rom_close_seg(_rom.open)
        ENDI

        IF (_rom.error = _rom.null)

_rom.segnum     QSET    0

            REPEAT (.ROM.Segments[_rom.static])
                __rom_try_open_seg(_rom.segnum, %min%)

_rom.segnum     QSET    (_rom.segnum + 1)
            ENDR

            ; Fail if no segment was found with enough space
            IF (_rom.open = _rom.invalid)
                __rom_raise_error("Automatic ROM segment selection failed", ["Could not find a suitable segment with ", $#(%min%), " words available."])
            ENDI

        ENDI

    LISTING "prev"
ENDM

;; ======================================================================== ;;
;;  ROM.SwitchBank seg, bank                                                ;;
;;  Switches a dynamic ROM segment to the requested bank.                   ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      seg         The dynamic ROM segment, or -1 for the first one.       ;;
;;      bank        The dynamic ROM segment bank number to activate.        ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   ROM.SwitchBank seg, bank
;
    LISTING "code"

                __rom_reset_error
                __rom_assert_romseg_support("Automatic segment selection")
                __rom_assert_setup("SwitchBank")

        IF (_rom.error = _rom.null)

            ; Determine the logical segment number
            IF ((%seg%) = _rom.invalid)
_rom.num        QSET    .ROM.Segments[_rom.static]
            ELSE
_rom.num        QSET    %seg%
            ENDI

_rom.type       QSET    _rom.t[_rom.num]

            ; Fail if the segment is not dynamic
            IF (_rom.type <> _rom.dynamic)
                __rom_raise_error(["Cannot switch bank on ROM segment #", $#(_rom.num)], "Segment is not dynamic.")
            ENDI

            ; Validate the segment and bank
            IF (_rom.error = _rom.null)
                __rom_validate_seg_bank(_rom.num, %bank%)
            ENDI

            IF (_rom.error = _rom.null)

_rom.segnum     QSET    (_rom.segidx[_rom.num] + (%bank%))

                ; Initialize REPEAT loop symbols
_rom.r_pgs      QSET    _rom.pgs[_rom.segnum]
_rom.r_addr     QSET    _rom.b  [_rom.segnum]
_rom.r_page     QSET    _rom.p  [_rom.segnum]

                ; Switch the physical pages that comprise
                ; the logical segment bank.
                REPEAT (_rom.r_pgs)
                    __rom_switch_mem_page(_rom.r_addr, _rom.r_page)
_rom.r_addr         QSET    (_rom.r_addr + _rom.pgsize)
                ENDR

            ENDI

        ENDI

    LISTING "prev"
ENDM


;; ======================================================================== ;;
;;  ROM.End                                                                 ;;
;;  Closes any open ROM segment, reports usage statistics, and finalizes    ;;
;;  the program.                                                            ;;
;;                                                                          ;;
;;  This macro must be called at the very end of the program.               ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      None.                                                               ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      _rom.error  -1 on failure.                                          ;;
;; ======================================================================== ;;
MACRO   ROM.End
;
    LISTING "code"

                __rom_reset_error
                __rom_assert_setup("End")

        IF (_rom.error = _rom.null)
                __rom_close_seg(_rom.open)

            ; The legacy map does not support usage statistics
            IF (_rom.map > 0)
                __rom_calculate_stats
            ENDI
        ENDI

    LISTING "prev"
ENDM

;; ======================================================================== ;;
;;  ROM.OutputRomStats                                                      ;;
;;  Outputs ROM usage statistics to STDOUT and to the listing file.         ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      None.                                                               ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      ROM usage statistics.                                               ;;
;; ======================================================================== ;;
MACRO   ROM.OutputRomStats
;
    LISTING "code"

_rom.hdr_len    QSET    55
_rom.fld_ttl    QSET    15
_rom.fld_mem    QSET    7
_rom.fld_bnk    QSET    3
_rom.fld_siz    QSET    4
_rom.fld_avl    QSET    8
_rom.scale      QSET    1024

_rom.static_sz  QSET    0
_rom.static_us  QSET    0
_rom.static_av  QSET    0

      IF (_rom.map > 0)

                ; Draw header
                SMSG ""
                SMSG $("ROM USAGE (MAP #", $#(_rom.map), "):")
                SMSG    $("    ", __rom_stats_draw_line(double, _rom.hdr_len))
                SMSG    $("    ", "    Segment        Size       Used      Available")
                SMSG    $("    ", __rom_stats_draw_line(double, _rom.hdr_len))

_rom.idx        QSET    0
_rom.cnt        QSET    .ROM.Segments[_rom.static]

        ; Static segments
        REPEAT (_rom.cnt)
_rom.segnum     QSET    _rom.segidx[_rom.idx]

_rom.size       QSET    .ROM.SegSize[_rom.segnum]
_rom.used       QSET    .ROM.SegUsed[_rom.segnum]
_rom.avlb       QSET    .ROM.SegAvlb[_rom.segnum]

_rom.size       QSET    __rom_stats_scale(_rom.size, _rom.scale)    ; Scaled to 1K

                ; Static ROM segment stats
                SMSG    $("    ", "Static Seg #", $#(_rom.idx), "     ", __rom_stats_pad_left($#(_rom.size), _rom.fld_siz), "K     ", __rom_stats_pad_left($#(_rom.used), _rom.fld_mem), "  ", __rom_stats_pad_left($#(_rom.avlb), _rom.fld_avl), " words")

_rom.static_sz  QSET    (_rom.static_sz + _rom.size)
_rom.static_us  QSET    (_rom.static_us + _rom.used)
_rom.static_av  QSET    (_rom.static_av + _rom.avlb)

_rom.idx        QSET    (_rom.idx + 1)
        ENDR

_rom.cnt        QSET    (_rom.segs - _rom.idx)

        ; Report static sub-total if there are dynamic segments.
        ; (When there are no dynamic segments, the final account
        ; is the total for static segments.)
        IF (_rom.cnt > 0)
                ; Draw footer
                SMSG    $("    ", __rom_stats_draw_line(single, _rom.hdr_len))
                SMSG    $("    ", __rom_stats_pad_left("SUB-TOTAL:", _rom.fld_ttl), "   ", __rom_stats_pad_left($#(_rom.static_sz), _rom.fld_siz), "K     ", __rom_stats_pad_left($#(_rom.static_us), _rom.fld_mem), "  ", __rom_stats_pad_left($#(_rom.static_av), _rom.fld_avl), " words")
        ENDI

        ; Dynamic segments
        REPEAT (_rom.cnt)
_rom.segnum     QSET    _rom.segidx[_rom.idx]

                ; Dynamic ROM segment header
                SMSG    $("    ", __rom_stats_draw_line(single, _rom.hdr_len))
                SMSG    $("    ", "Dynamic Seg #", $#(_rom.idx), ":")

_rom.bidx       QSET    0
_rom.bcnt       QSET    _rom.bnkcnt[_rom.idx]

            ; Dynamic segment banks
            REPEAT (_rom.bcnt)

_rom.segnum     QSET    (_rom.segidx[_rom.idx] + _rom.bidx)

_rom.size       QSET    .ROM.SegSize[_rom.segnum]
_rom.used       QSET    .ROM.SegUsed[_rom.segnum]
_rom.avlb       QSET    .ROM.SegAvlb[_rom.segnum]

_rom.size       QSET    __rom_stats_scale(_rom.size, _rom.scale)    ; Scaled to 1K

                SMSG    $("    ", "       Bank #", __rom_stats_pad_right($#(_rom.bidx), _rom.fld_bnk), "  ", __rom_stats_pad_left($#(_rom.size), _rom.fld_siz), "K     ", __rom_stats_pad_left($#(_rom.used), _rom.fld_mem), "  ", __rom_stats_pad_left($#(_rom.avlb), _rom.fld_avl), " words")

_rom.bidx       QSET    (_rom.bidx + 1)
            ENDR

_rom.idx        QSET    (_rom.idx + 1)
        ENDR

_rom.size       QSET    __rom_stats_scale(.ROM.Size, _rom.scale)    ; Scaled to 1K

                ; Draw footer
                SMSG    $("    ", __rom_stats_draw_line(double, _rom.hdr_len))
                SMSG    $("    ", __rom_stats_pad_left("TOTAL:", _rom.fld_ttl), "   ", __rom_stats_pad_left($#(_rom.size), _rom.fld_siz), "K     ", __rom_stats_pad_left($#(.ROM.Used), _rom.fld_mem), "  ", __rom_stats_pad_left($#(.ROM.Available), _rom.fld_avl), " words")
                SMSG    $("    ", __rom_stats_draw_line(double, _rom.hdr_len))
                SMSG ""

      ENDI

    LISTING "prev"
ENDM

;; ======================================================================== ;;
;;  EOF: romseg-bs.mac                                                      ;;
;; ======================================================================== ;;

    LISTING "prev"

	ROM.Setup intybasic_map

	; This macro will 'eat' SRCFILE directives if the assembler doesn't support the directive.
	IF ( DEFINED __FEATURE.SRCFILE ) = 0
	    MACRO SRCFILE x, y
	    ; macro must be non-empty, but a comment works fine.
	    ENDM
	ENDI

CLRSCR:	MVII #$200,R4		; Used also for CLS
	MVO R4,_screen		; Set up starting screen position for PRINT
	MVII #$F0,R1
FILLZERO:
	CLRR R0
MEMSET:
	SARC R1,2
	BNOV $+4
	MVO@ R0,R4
	MVO@ R0,R4
	BNC $+3
	MVO@ R0,R4
	BEQ $+7
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	DECR R1
	BNE $-5
	JR R5

	;
	; Title, Intellivision EXEC will jump over it and start
	; execution directly in _MAIN
	;
	; Note mark is for automatic replacement by IntyBASIC
_TITLE:
	BYTE 126,'IntyBASIC program',0
        
	;
	; Main program
	;
_MAIN:
	DIS			; Disable interrupts
	MVII #STACK,R6

	;
	; Clean memory
	;
	CALL CLRSCR		; Clean up screen, right here to avoid brief
				; screen display of title in Sears Intellivision.
	MVII #$00e,R1		; 14 of sound (ECS)
	MVII #$0f0,R4		; ECS PSG
	CALL FILLZERO
	MVII #$0fe,R1		; 240 words of 8 bits plus 14 of sound
	MVII #$100,R4		; 8-bit scratch RAM
	CALL FILLZERO

	; Seed random generator using 16 bit RAM (not cleared by EXEC)
	CLRR R0
	MVII #$02F0,R4
	MVII #$0110/4,R1	; Includes phantom memory for extra randomness
_MAIN4:				; This loop is courtesy of GroovyBee
	ADD@ R4,R0
	ADD@ R4,R0
	ADD@ R4,R0
	ADD@ R4,R0
	DECR R1
	BNE _MAIN4
	MVO R0,_rand

	MVII #$058,R1		; 88 words of 16 bits
	MVII #$308,R4		; 16-bit scratch RAM
	CALL FILLZERO

    IF intybasic_jlp
	MVII #$1F40,R1		; Words of 16 bits
	MVII #$8040,R4		; 16-bit scratch RAM
	CALL FILLZERO
    ENDI
    IF intybasic_cc3
	MVII #$1F40,R1		; Words of 16 bits
	MVII #intybasic_cc3*256+$40,R4	; 16-bit scratch RAM
	CALL FILLZERO
    ENDI

	; PAL/NTSC detect
	CALL _set_isr
	DECLE _pal1
	EIS
	DECR PC			; This is a kind of HALT instruction

	; First interrupt may come at a weird time on Tutorvision, or
	; if other startup timing changes.
_pal1:	SUBI #8,R6		; Drop interrupt stack.
	CALL _set_isr
	DECLE _pal2
	DECR PC

	; Second interrupt is safe for initializing MOBs.
	; We will know the screen is off after this one fires.
_pal2:	SUBI #8,R6		; Drop interrupt stack.
	CALL _set_isr
	DECLE _pal3
	; clear MOBs
	CLRR R0
	CLRR R4
	MVII #$18,R2
_pal2_lp:
	MVO@ R0,R4
	DECR R2
	BNE _pal2_lp
	MVO R0,$30		; Reset horizontal delay register
	MVO R0,$31		; Reset vertical delay register

	MVII #-1100,R2		; PAL/NTSC threshold
_pal2_cnt:
	INCR R2
	B _pal2_cnt

	; The final count in R2 will either be negative or positive.
	; If R2 is still -ve, NTSC; else PAL.
_pal3:	SUBI #8,R6		; Drop interrupt stack.
	RLC R2,1
	RLC R2,1
	ANDI #1,R2		; 1 = NTSC, 0 = PAL

	MVII #$55,R1
	MVO R1,$4040
	MVII #$AA,R1
	MVO R1,$4041
	MVI $4040,R1
	CMPI #$55,R1
	BNE _ecs1
	MVI $4041,R1
	CMPI #$AA,R1
	BNE _ecs1
	ADDI #2,R2		; ECS detected flag
_ecs1:
	MVO R2,_ntsc

	CALL _set_isr
	DECLE _int_vector

	CALL CLRSCR		; Because _screen was reset to zero
	CALL _wait
	CALL _init_music
	MVII #2,R0		; Color Stack mode
	MVO R0,_mode_select
	MVII #$038,R0
	MVO R0,$01F8		; Configures sound
	MVO R0,$00F8		; Configures sound (ECS)
	CALL IV_INIT_and_wait	; Setup Intellivoice

;* ======================================================================== *;
;*  These routines are placed into the public domain by their author.  All  *;
;*  copyright rights are hereby relinquished on the routines and data in    *;
;*  this file.  -- James Pujals (DZ-Jay), 2014                              *;
;* ======================================================================== *;

; Modified by Oscar Toledo G. (nanochess), Aug/06/2015
; * Tested all multiplications with automated test.
; * Accelerated multiplication by 7,14,15,28,31,60,62,63,112,120,124
; * Solved bug in multiplication by 23,39,46,47,55,71,78,79,87,92,93,94,95,103,110,111,119
; * Improved sequence of instructions to be more interruptible.

;; ======================================================================== ;;
;;  MULT reg, tmp, const                                                    ;;
;;  Multiplies "reg" by constant "const" and using "tmp" for temporary      ;;
;;  calculations.  The result is placed in "reg."  The multiplication is    ;;
;;  performed by an optimal combination of shifts, additions, and           ;;
;;  subtractions.                                                           ;;
;;                                                                          ;;
;;  NOTE:   The resulting contents of the "tmp" are undefined.              ;;
;;                                                                          ;;
;;  ARGUMENTS                                                               ;;
;;      reg         A register containing the multiplicand.                 ;;
;;      tmp         A register for temporary calculations.                  ;;
;;      const       The constant multiplier.                                ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      reg         Output value.                                           ;;
;;      tmp         Trashed.                                                ;;
;;      .ERR.Failed True if operation failed.                               ;;
;; ======================================================================== ;;
MACRO   MULT reg, tmp, const
;
    LISTING "code"

_mul.const      QSET    %const%
_mul.done       QSET    0

        IF (%const% > $7F)
_mul.const      QSET    (_mul.const SHR 1)
                SLL     %reg%,  1
        ENDI

        ; Multiply by $00 (0)
        IF (_mul.const = $00)
_mul.done       QSET    -1
                CLRR    %reg%
        ENDI

        ; Multiply by $01 (1)
        IF (_mul.const = $01)
_mul.done       QSET    -1
                ; Nothing to do
        ENDI

        ; Multiply by $02 (2)
        IF (_mul.const = $02)
_mul.done       QSET    -1
                SLL     %reg%,  1
        ENDI

        ; Multiply by $03 (3)
        IF (_mul.const = $03)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $04 (4)
        IF (_mul.const = $04)
_mul.done       QSET    -1
                SLL     %reg%,  2
        ENDI

        ; Multiply by $05 (5)
        IF (_mul.const = $05)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $06 (6)
        IF (_mul.const = $06)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $07 (7)
        IF (_mul.const = $07)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $08 (8)
        IF (_mul.const = $08)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  1
        ENDI

        ; Multiply by $09 (9)
        IF (_mul.const = $09)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $0A (10)
        IF (_mul.const = $0A)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $0B (11)
        IF (_mul.const = $0B)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $0C (12)
        IF (_mul.const = $0C)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $0D (13)
        IF (_mul.const = $0D)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $0E (14)
        IF (_mul.const = $0E)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $0F (15)
        IF (_mul.const = $0F)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $10 (16)
        IF (_mul.const = $10)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  2
        ENDI

        ; Multiply by $11 (17)
        IF (_mul.const = $11)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $12 (18)
        IF (_mul.const = $12)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $13 (19)
        IF (_mul.const = $13)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $14 (20)
        IF (_mul.const = $14)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $15 (21)
        IF (_mul.const = $15)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $16 (22)
        IF (_mul.const = $16)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $17 (23)
        IF (_mul.const = $17)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  1
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $18 (24)
        IF (_mul.const = $18)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $19 (25)
        IF (_mul.const = $19)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $1A (26)
        IF (_mul.const = $1A)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $1B (27)
        IF (_mul.const = $1B)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $1C (28)
        IF (_mul.const = $1C)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $1D (29)
        IF (_mul.const = $1D)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $1E (30)
        IF (_mul.const = $1E)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $1F (31)
        IF (_mul.const = $1F)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
		ADDR	%reg%,	%reg%
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $20 (32)
        IF (_mul.const = $20)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  2
		ADDR	%reg%,	%reg%
        ENDI

        ; Multiply by $21 (33)
        IF (_mul.const = $21)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
		ADDR	%reg%,	%reg%
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $22 (34)
        IF (_mul.const = $22)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $23 (35)
        IF (_mul.const = $23)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $24 (36)
        IF (_mul.const = $24)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $25 (37)
        IF (_mul.const = $25)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $26 (38)
        IF (_mul.const = $26)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $27 (39)
        IF (_mul.const = $27)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $28 (40)
        IF (_mul.const = $28)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $29 (41)
        IF (_mul.const = $29)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $2A (42)
        IF (_mul.const = $2A)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $2B (43)
        IF (_mul.const = $2B)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $2C (44)
        IF (_mul.const = $2C)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $2D (45)
        IF (_mul.const = $2D)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $2E (46)
        IF (_mul.const = $2E)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  1
		SUBR	%tmp%,  %reg%
        ENDI

        ; Multiply by $2F (47)
        IF (_mul.const = $2F)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  1
		SUBR	%tmp%,  %reg%
        ENDI

        ; Multiply by $30 (48)
        IF (_mul.const = $30)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $31 (49)
        IF (_mul.const = $31)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $32 (50)
        IF (_mul.const = $32)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $33 (51)
        IF (_mul.const = $33)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $34 (52)
        IF (_mul.const = $34)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $35 (53)
        IF (_mul.const = $35)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $36 (54)
        IF (_mul.const = $36)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $37 (55)
        IF (_mul.const = $37)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
		SLL	%reg%,	1
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $38 (56)
        IF (_mul.const = $38)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $39 (57)
        IF (_mul.const = $39)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $3A (58)
        IF (_mul.const = $3A)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $3B (59)
        IF (_mul.const = $3B)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $3C (60)
        IF (_mul.const = $3C)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $3D (61)
        IF (_mul.const = $3D)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $3E (62)
        IF (_mul.const = $3E)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
		ADDR	%reg%,	%reg%
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $3F (63)
        IF (_mul.const = $3F)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $40 (64)
        IF (_mul.const = $40)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  2
                SLL     %reg%,  2
        ENDI

        ; Multiply by $41 (65)
        IF (_mul.const = $41)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $42 (66)
        IF (_mul.const = $42)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
		ADDR	%reg%,	%reg%
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $43 (67)
        IF (_mul.const = $43)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
		ADDR	%reg%,	%reg%
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $44 (68)
        IF (_mul.const = $44)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $45 (69)
        IF (_mul.const = $45)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $46 (70)
        IF (_mul.const = $46)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $47 (71)
        IF (_mul.const = $47)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $48 (72)
        IF (_mul.const = $48)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $49 (73)
        IF (_mul.const = $49)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $4A (74)
        IF (_mul.const = $4A)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $4B (75)
        IF (_mul.const = $4B)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $4C (76)
        IF (_mul.const = $4C)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $4D (77)
        IF (_mul.const = $4D)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $4E (78)
        IF (_mul.const = $4E)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $4F (79)
        IF (_mul.const = $4F)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $50 (80)
        IF (_mul.const = $50)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $51 (81)
        IF (_mul.const = $51)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $52 (82)
        IF (_mul.const = $52)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $53 (83)
        IF (_mul.const = $53)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $54 (84)
        IF (_mul.const = $54)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $55 (85)
        IF (_mul.const = $55)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $56 (86)
        IF (_mul.const = $56)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $57 (87)
        IF (_mul.const = $57)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  1
		SUBR    %reg%,	%tmp%
                SLL     %reg%,  2
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $58 (88)
        IF (_mul.const = $58)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $59 (89)
        IF (_mul.const = $59)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $5A (90)
        IF (_mul.const = $5A)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $5B (91)
        IF (_mul.const = $5B)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $5C (92)
        IF (_mul.const = $5C)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  1
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $5D (93)
        IF (_mul.const = $5D)
_mul.done       QSET    -1
		MOVR	%reg%,	%tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  1
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $5E (94)
        IF (_mul.const = $5E)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  1
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $5F (95)
        IF (_mul.const = $5F)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                ADDR	%reg%,	%reg%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  1
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $60 (96)
        IF (_mul.const = $60)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  2
		ADDR	%reg%,	%reg%
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $61 (97)
        IF (_mul.const = $61)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $62 (98)
        IF (_mul.const = $62)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $63 (99)
        IF (_mul.const = $63)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $64 (100)
        IF (_mul.const = $64)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $65 (101)
        IF (_mul.const = $65)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $66 (102)
        IF (_mul.const = $66)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $67 (103)
        IF (_mul.const = $67)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  1
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $68 (104)
        IF (_mul.const = $68)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $69 (105)
        IF (_mul.const = $69)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $6A (106)
        IF (_mul.const = $6A)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $6B (107)
        IF (_mul.const = $6B)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $6C (108)
        IF (_mul.const = $6C)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $6D (109)
        IF (_mul.const = $6D)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $6E (110)
        IF (_mul.const = $6E)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $6F (111)
        IF (_mul.const = $6F)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
		SUBR	%tmp%,	%reg%
        ENDI

        ; Multiply by $70 (112)
        IF (_mul.const = $70)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $71 (113)
        IF (_mul.const = $71)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $72 (114)
        IF (_mul.const = $72)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $73 (115)
        IF (_mul.const = $73)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $74 (116)
        IF (_mul.const = $74)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $75 (117)
        IF (_mul.const = $75)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $76 (118)
        IF (_mul.const = $76)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $77 (119)
        IF (_mul.const = $77)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $78 (120)
        IF (_mul.const = $78)
_mul.done       QSET    -1
                SLL     %reg%,  2
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $79 (121)
        IF (_mul.const = $79)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $7A (122)
        IF (_mul.const = $7A)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $7B (123)
        IF (_mul.const = $7B)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  1
                ADDR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $7C (124)
        IF (_mul.const = $7C)
_mul.done       QSET    -1
                SLL     %reg%,  2
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
		ADDR	%reg%,	%reg%
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $7D (125)
        IF (_mul.const = $7D)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SUBR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
		ADDR	%reg%,	%reg%
                ADDR    %tmp%,  %reg%
        ENDI

        ; Multiply by $7E (126)
        IF (_mul.const = $7E)
_mul.done       QSET    -1
                SLL     %reg%,  1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SLL     %reg%,  2
                SUBR    %tmp%,  %reg%
        ENDI

        ; Multiply by $7F (127)
        IF (_mul.const = $7F)
_mul.done       QSET    -1
                MOVR    %reg%,  %tmp%
                SLL     %reg%,  2
                SLL     %reg%,  2
                SLL     %reg%,  2
                SLL     %reg%,  1
                SUBR    %tmp%,  %reg%
        ENDI

        IF  (_mul.done = 0)
            ERR $("Invalid multiplication constant \'%const%\', must be between 0 and ", $#($7F), ".")
        ENDI

    LISTING "prev"
ENDM

;; ======================================================================== ;;
;;  EOF: pm:mac:lang:mult                                                   ;;
;; ======================================================================== ;;

	; IntyBASIC compiler v1.5.1 May/10/2025
	;FILE ./games/orchestra-demo/src/main.bas
	;[1] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",1
	;[2] ' Intellivoice Demo - Intellivision Game
	SRCFILE "./games/orchestra-demo/src/main.bas",2
	;[3] ' Author: Mike Holzinger
	SRCFILE "./games/orchestra-demo/src/main.bas",3
	;[4] ' Date: 2026
	SRCFILE "./games/orchestra-demo/src/main.bas",4
	;[5] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",5
	;[6] ' Demonstrates Intellivoice speech synthesis
	SRCFILE "./games/orchestra-demo/src/main.bas",6
	;[7] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",7
	;[8] 
	SRCFILE "./games/orchestra-demo/src/main.bas",8
	;[9]     ' Use 42K static memory map (compatible with JLP and modern PCBs)
	SRCFILE "./games/orchestra-demo/src/main.bas",9
	;[10]     OPTION MAP 2
	SRCFILE "./games/orchestra-demo/src/main.bas",10
	;[11] 
	SRCFILE "./games/orchestra-demo/src/main.bas",11
	;[12]     ' --- Constants ---
	SRCFILE "./games/orchestra-demo/src/main.bas",12
	;[13]     CONST COLOR_BLACK = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",13
const_COLOR_BLACK:	EQU 0
	;[14]     CONST COLOR_BLUE = 1
	SRCFILE "./games/orchestra-demo/src/main.bas",14
const_COLOR_BLUE:	EQU 1
	;[15]     CONST COLOR_WHITE = 7
	SRCFILE "./games/orchestra-demo/src/main.bas",15
const_COLOR_WHITE:	EQU 7
	;[16]     CONST MAX_PAGE = 3
	SRCFILE "./games/orchestra-demo/src/main.bas",16
const_MAX_PAGE:	EQU 3
	;[17] 
	SRCFILE "./games/orchestra-demo/src/main.bas",17
	;[18]     ' --- Variables ---
	SRCFILE "./games/orchestra-demo/src/main.bas",18
	;[19]     last_key = 12  ' 12 = no key pressed
	SRCFILE "./games/orchestra-demo/src/main.bas",19
	MVII #12,R0
	MVO R0,var_LAST_KEY
	;[20]     page = 0       ' Menu page
	SRCFILE "./games/orchestra-demo/src/main.bas",20
	CLRR R0
	MVO R0,var_PAGE
	;[21] 
	SRCFILE "./games/orchestra-demo/src/main.bas",21
	;[22]     ' --- Initialize ---
	SRCFILE "./games/orchestra-demo/src/main.bas",22
	;[23]     WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",23
	CALL _wait
	;[24]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",24
	CALL CLRSCR
	;[25]     MODE 0, COLOR_BLUE, COLOR_BLUE, COLOR_BLUE, COLOR_BLUE
	SRCFILE "./games/orchestra-demo/src/main.bas",25
	MVII #4369,R0
	MVO R0,_color
	MVII #2,R0
	MVO R0,_mode_select
	;[26] 
	SRCFILE "./games/orchestra-demo/src/main.bas",26
	;[27]     ' Initialize Intellivoice
	SRCFILE "./games/orchestra-demo/src/main.bas",27
	;[28]     VOICE INIT
	SRCFILE "./games/orchestra-demo/src/main.bas",28
	CALL IV_HUSH
	;[29] 
	SRCFILE "./games/orchestra-demo/src/main.bas",29
	;[30]     ' Initialize music player (SIMPLE uses 2 channels, leaves room for voice)
	SRCFILE "./games/orchestra-demo/src/main.bas",30
	;[31]     PLAY SIMPLE
	SRCFILE "./games/orchestra-demo/src/main.bas",31
	MVII #3,R3
	MVO R3,_music_mode
	;[32] 
	SRCFILE "./games/orchestra-demo/src/main.bas",32
	;[33]     ' Say intro phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",33
	;[34]     VOICE PLAY intro_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",34
	MVII #label_INTRO_PHRASE,R0
	CALL IV_PLAY.1
	;[35] 
	SRCFILE "./games/orchestra-demo/src/main.bas",35
	;[36]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",36
	CALL label_DRAW_MENU
	;[37] 
	SRCFILE "./games/orchestra-demo/src/main.bas",37
	;[38]     ' --- Main Game Loop ---
	SRCFILE "./games/orchestra-demo/src/main.bas",38
	;[39] main_loop:
	SRCFILE "./games/orchestra-demo/src/main.bas",39
	; MAIN_LOOP
label_MAIN_LOOP:	;[40]     WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",40
	CALL _wait
	;[41] 
	SRCFILE "./games/orchestra-demo/src/main.bas",41
	;[42]     k = CONT.key
	SRCFILE "./games/orchestra-demo/src/main.bas",42
	MVI _cnt1_key,R0
	CMPI #12,R0
	BNE T1
	MVI _cnt2_key,R0
T1:
	MVO R0,var_K
	;[43] 
	SRCFILE "./games/orchestra-demo/src/main.bas",43
	;[44]     ' Only trigger on new key press (debounce)
	SRCFILE "./games/orchestra-demo/src/main.bas",44
	;[45]     IF k = last_key THEN GOTO skip_input
	SRCFILE "./games/orchestra-demo/src/main.bas",45
	MVI var_K,R0
	CMP var_LAST_KEY,R0
	BEQ label_SKIP_INPUT
	;[46]     last_key = k
	SRCFILE "./games/orchestra-demo/src/main.bas",46
	MVI var_K,R0
	MVO R0,var_LAST_KEY
	;[47] 
	SRCFILE "./games/orchestra-demo/src/main.bas",47
	;[48]     ' Route to correct page handler
	SRCFILE "./games/orchestra-demo/src/main.bas",48
	;[49]     IF page = 0 THEN GOTO page0_input
	SRCFILE "./games/orchestra-demo/src/main.bas",49
	MVI var_PAGE,R0
	TSTR R0
	BEQ label_PAGE0_INPUT
	;[50]     IF page = 1 THEN GOTO page1_input
	SRCFILE "./games/orchestra-demo/src/main.bas",50
	MVI var_PAGE,R0
	CMPI #1,R0
	BEQ label_PAGE1_INPUT
	;[51]     IF page = 2 THEN GOTO page2_input
	SRCFILE "./games/orchestra-demo/src/main.bas",51
	MVI var_PAGE,R0
	CMPI #2,R0
	BEQ label_PAGE2_INPUT
	;[52]     IF page = 3 THEN GOTO page3_input
	SRCFILE "./games/orchestra-demo/src/main.bas",52
	MVI var_PAGE,R0
	CMPI #3,R0
	BEQ label_PAGE3_INPUT
	;[53]     GOTO skip_input
	SRCFILE "./games/orchestra-demo/src/main.bas",53
	B label_SKIP_INPUT
	;[54] 
	SRCFILE "./games/orchestra-demo/src/main.bas",54
	;[55] page0_input:
	SRCFILE "./games/orchestra-demo/src/main.bas",55
	; PAGE0_INPUT
label_PAGE0_INPUT:	;[56]     ' Instruments A: Cello, Oboe, Bass, Timpani, Trombone, Piccolo
	SRCFILE "./games/orchestra-demo/src/main.bas",56
	;[57]     IF k = 1 THEN GOSUB say_cello
	SRCFILE "./games/orchestra-demo/src/main.bas",57
	MVI var_K,R0
	CMPI #1,R0
	BNE T7
	CALL label_SAY_CELLO
T7:
	;[58]     IF k = 2 THEN GOSUB say_oboe
	SRCFILE "./games/orchestra-demo/src/main.bas",58
	MVI var_K,R0
	CMPI #2,R0
	BNE T8
	CALL label_SAY_OBOE
T8:
	;[59]     IF k = 3 THEN GOSUB say_bass
	SRCFILE "./games/orchestra-demo/src/main.bas",59
	MVI var_K,R0
	CMPI #3,R0
	BNE T9
	CALL label_SAY_BASS
T9:
	;[60]     IF k = 4 THEN GOSUB say_timpani
	SRCFILE "./games/orchestra-demo/src/main.bas",60
	MVI var_K,R0
	CMPI #4,R0
	BNE T10
	CALL label_SAY_TIMPANI
T10:
	;[61]     IF k = 5 THEN GOSUB say_trombone
	SRCFILE "./games/orchestra-demo/src/main.bas",61
	MVI var_K,R0
	CMPI #5,R0
	BNE T11
	CALL label_SAY_TROMBONE
T11:
	;[62]     IF k = 6 THEN GOSUB say_piccolo
	SRCFILE "./games/orchestra-demo/src/main.bas",62
	MVI var_K,R0
	CMPI #6,R0
	BNE T12
	CALL label_SAY_PICCOLO
T12:
	;[63]     IF k = 0 THEN GOSUB next_page
	SRCFILE "./games/orchestra-demo/src/main.bas",63
	MVI var_K,R0
	TSTR R0
	BNE T13
	CALL label_NEXT_PAGE
T13:
	;[64]     GOTO skip_input
	SRCFILE "./games/orchestra-demo/src/main.bas",64
	B label_SKIP_INPUT
	;[65] 
	SRCFILE "./games/orchestra-demo/src/main.bas",65
	;[66] page1_input:
	SRCFILE "./games/orchestra-demo/src/main.bas",66
	; PAGE1_INPUT
label_PAGE1_INPUT:	;[67]     ' Sneeze page: Normal, Big, Tiny, Triple, Stifled, Cartoon
	SRCFILE "./games/orchestra-demo/src/main.bas",67
	;[68]     IF k = 1 THEN GOSUB sneeze_normal
	SRCFILE "./games/orchestra-demo/src/main.bas",68
	MVI var_K,R0
	CMPI #1,R0
	BNE T14
	CALL label_SNEEZE_NORMAL
T14:
	;[69]     IF k = 2 THEN GOSUB sneeze_big
	SRCFILE "./games/orchestra-demo/src/main.bas",69
	MVI var_K,R0
	CMPI #2,R0
	BNE T15
	CALL label_SNEEZE_BIG
T15:
	;[70]     IF k = 3 THEN GOSUB sneeze_tiny
	SRCFILE "./games/orchestra-demo/src/main.bas",70
	MVI var_K,R0
	CMPI #3,R0
	BNE T16
	CALL label_SNEEZE_TINY
T16:
	;[71]     IF k = 4 THEN GOSUB sneeze_triple
	SRCFILE "./games/orchestra-demo/src/main.bas",71
	MVI var_K,R0
	CMPI #4,R0
	BNE T17
	CALL label_SNEEZE_TRIPLE
T17:
	;[72]     IF k = 5 THEN GOSUB sneeze_stifled
	SRCFILE "./games/orchestra-demo/src/main.bas",72
	MVI var_K,R0
	CMPI #5,R0
	BNE T18
	CALL label_SNEEZE_STIFLED
T18:
	;[73]     IF k = 6 THEN GOSUB sneeze_cartoon
	SRCFILE "./games/orchestra-demo/src/main.bas",73
	MVI var_K,R0
	CMPI #6,R0
	BNE T19
	CALL label_SNEEZE_CARTOON
T19:
	;[74]     IF k = 0 THEN GOSUB next_page
	SRCFILE "./games/orchestra-demo/src/main.bas",74
	MVI var_K,R0
	TSTR R0
	BNE T20
	CALL label_NEXT_PAGE
T20:
	;[75]     GOTO skip_input
	SRCFILE "./games/orchestra-demo/src/main.bas",75
	B label_SKIP_INPUT
	;[76] 
	SRCFILE "./games/orchestra-demo/src/main.bas",76
	;[77] page2_input:
	SRCFILE "./games/orchestra-demo/src/main.bas",77
	; PAGE2_INPUT
label_PAGE2_INPUT:	;[78]     ' Special sounds
	SRCFILE "./games/orchestra-demo/src/main.bas",78
	;[79]     IF k = 1 THEN GOSUB say_bravo
	SRCFILE "./games/orchestra-demo/src/main.bas",79
	MVI var_K,R0
	CMPI #1,R0
	BNE T21
	CALL label_SAY_BRAVO
T21:
	;[80]     IF k = 2 THEN GOSUB say_encore
	SRCFILE "./games/orchestra-demo/src/main.bas",80
	MVI var_K,R0
	CMPI #2,R0
	BNE T22
	CALL label_SAY_ENCORE
T22:
	;[81]     IF k = 3 THEN GOSUB count_words
	SRCFILE "./games/orchestra-demo/src/main.bas",81
	MVI var_K,R0
	CMPI #3,R0
	BNE T23
	CALL label_COUNT_WORDS
T23:
	;[82]     IF k = 4 THEN GOSUB pencil_drop
	SRCFILE "./games/orchestra-demo/src/main.bas",82
	MVI var_K,R0
	CMPI #4,R0
	BNE T24
	CALL label_PENCIL_DROP
T24:
	;[83]     IF k = 5 THEN GOSUB orchestra_tune
	SRCFILE "./games/orchestra-demo/src/main.bas",83
	MVI var_K,R0
	CMPI #5,R0
	BNE T25
	CALL label_ORCHESTRA_TUNE
T25:
	;[84]     IF k = 0 THEN GOSUB next_page
	SRCFILE "./games/orchestra-demo/src/main.bas",84
	MVI var_K,R0
	TSTR R0
	BNE T26
	CALL label_NEXT_PAGE
T26:
	;[85]     GOTO skip_input
	SRCFILE "./games/orchestra-demo/src/main.bas",85
	B label_SKIP_INPUT
	;[86] 
	SRCFILE "./games/orchestra-demo/src/main.bas",86
	;[87] page3_input:
	SRCFILE "./games/orchestra-demo/src/main.bas",87
	; PAGE3_INPUT
label_PAGE3_INPUT:	;[88]     ' Music player page
	SRCFILE "./games/orchestra-demo/src/main.bas",88
	;[89]     IF k = 1 THEN GOSUB play_greensleeves
	SRCFILE "./games/orchestra-demo/src/main.bas",89
	MVI var_K,R0
	CMPI #1,R0
	BNE T27
	CALL label_PLAY_GREENSLEEVES
T27:
	;[90]     IF k = 2 THEN GOSUB play_canon
	SRCFILE "./games/orchestra-demo/src/main.bas",90
	MVI var_K,R0
	CMPI #2,R0
	BNE T28
	CALL label_PLAY_CANON
T28:
	;[91]     IF k = 3 THEN GOSUB play_tuning
	SRCFILE "./games/orchestra-demo/src/main.bas",91
	MVI var_K,R0
	CMPI #3,R0
	BNE T29
	CALL label_PLAY_TUNING
T29:
	;[92]     IF k = 4 THEN GOSUB play_nutcracker
	SRCFILE "./games/orchestra-demo/src/main.bas",92
	MVI var_K,R0
	CMPI #4,R0
	BNE T30
	CALL label_PLAY_NUTCRACKER
T30:
	;[93]     IF k = 5 THEN GOSUB stop_music
	SRCFILE "./games/orchestra-demo/src/main.bas",93
	MVI var_K,R0
	CMPI #5,R0
	BNE T31
	CALL label_STOP_MUSIC
T31:
	;[94]     IF k = 0 THEN GOSUB next_page
	SRCFILE "./games/orchestra-demo/src/main.bas",94
	MVI var_K,R0
	TSTR R0
	BNE T32
	CALL label_NEXT_PAGE
T32:
	;[95]     GOTO skip_input
	SRCFILE "./games/orchestra-demo/src/main.bas",95
	B label_SKIP_INPUT
	;[96] 
	SRCFILE "./games/orchestra-demo/src/main.bas",96
	;[97] skip_input:
	SRCFILE "./games/orchestra-demo/src/main.bas",97
	; SKIP_INPUT
label_SKIP_INPUT:	;[98]     GOTO main_loop
	SRCFILE "./games/orchestra-demo/src/main.bas",98
	B label_MAIN_LOOP
	;[99] 
	SRCFILE "./games/orchestra-demo/src/main.bas",99
	;[100] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",100
	;[101] ' SUBROUTINES
	SRCFILE "./games/orchestra-demo/src/main.bas",101
	;[102] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",102
	;[103] 
	SRCFILE "./games/orchestra-demo/src/main.bas",103
	;[104] draw_menu: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",104
	; DRAW_MENU
label_DRAW_MENU:	PROC
	BEGIN
	;[105]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",105
	CALL CLRSCR
	;[106]     PRINT AT 6, "ORCHESTRA!"
	SRCFILE "./games/orchestra-demo/src/main.bas",106
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #376,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #256,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[107]     IF page = 0 THEN GOTO draw_page0
	SRCFILE "./games/orchestra-demo/src/main.bas",107
	MVI var_PAGE,R0
	TSTR R0
	BEQ label_DRAW_PAGE0
	;[108]     IF page = 1 THEN GOTO draw_page1
	SRCFILE "./games/orchestra-demo/src/main.bas",108
	MVI var_PAGE,R0
	CMPI #1,R0
	BEQ label_DRAW_PAGE1
	;[109]     IF page = 2 THEN GOTO draw_page2
	SRCFILE "./games/orchestra-demo/src/main.bas",109
	MVI var_PAGE,R0
	CMPI #2,R0
	BEQ label_DRAW_PAGE2
	;[110]     IF page = 3 THEN GOTO draw_page3
	SRCFILE "./games/orchestra-demo/src/main.bas",110
	MVI var_PAGE,R0
	CMPI #3,R0
	BEQ label_DRAW_PAGE3
	;[111]     GOTO draw_done
	SRCFILE "./games/orchestra-demo/src/main.bas",111
	B label_DRAW_DONE
	;[112] draw_page0:
	SRCFILE "./games/orchestra-demo/src/main.bas",112
	; DRAW_PAGE0
label_DRAW_PAGE0:	;[113]     PRINT AT 40, "--- INSTRUMENTS A ---"
	SRCFILE "./games/orchestra-demo/src/main.bas",113
	MVII #552,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #104,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #328,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[114]     PRINT AT 60, "1: CELLO"
	SRCFILE "./games/orchestra-demo/src/main.bas",114
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #136,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[115]     PRINT AT 80, "2: OBOE"
	SRCFILE "./games/orchestra-demo/src/main.bas",115
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #144,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #376,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[116]     PRINT AT 100, "3: BASS"
	SRCFILE "./games/orchestra-demo/src/main.bas",116
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #152,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #144,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[117]     PRINT AT 120, "4: TIMPANI"
	SRCFILE "./games/orchestra-demo/src/main.bas",117
	MVII #632,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #160,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #32,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[118]     PRINT AT 140, "5: TROMBONE"
	SRCFILE "./games/orchestra-demo/src/main.bas",118
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #168,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[119]     PRINT AT 160, "6: PICCOLO"
	SRCFILE "./games/orchestra-demo/src/main.bas",119
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #176,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #384,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[120]     PRINT AT 200, "0: MORE >"
	SRCFILE "./games/orchestra-demo/src/main.bas",120
	MVII #712,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #128,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #360,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #240,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[121]     GOTO draw_done
	SRCFILE "./games/orchestra-demo/src/main.bas",121
	B label_DRAW_DONE
	;[122] draw_page1:
	SRCFILE "./games/orchestra-demo/src/main.bas",122
	; DRAW_PAGE1
label_DRAW_PAGE1:	;[123]     PRINT AT 40, "--- SNEEZES ---"
	SRCFILE "./games/orchestra-demo/src/main.bas",123
	MVII #552,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #104,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[124]     PRINT AT 60, "1: NORMAL"
	SRCFILE "./games/orchestra-demo/src/main.bas",124
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #136,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[125]     PRINT AT 80, "2: BIG DRAMATIC"
	SRCFILE "./games/orchestra-demo/src/main.bas",125
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #144,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #312,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[126]     PRINT AT 100, "3: TINY"
	SRCFILE "./games/orchestra-demo/src/main.bas",126
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #152,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[127]     PRINT AT 120, "4: TRIPLE"
	SRCFILE "./games/orchestra-demo/src/main.bas",127
	MVII #632,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #160,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[128]     PRINT AT 140, "5: STIFLED"
	SRCFILE "./games/orchestra-demo/src/main.bas",128
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #168,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[129]     PRINT AT 160, "6: CARTOON"
	SRCFILE "./games/orchestra-demo/src/main.bas",129
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #176,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[130]     PRINT AT 200, "0: MORE >"
	SRCFILE "./games/orchestra-demo/src/main.bas",130
	MVII #712,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #128,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #360,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #240,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[131]     GOTO draw_done
	SRCFILE "./games/orchestra-demo/src/main.bas",131
	B label_DRAW_DONE
	;[132] draw_page2:
	SRCFILE "./games/orchestra-demo/src/main.bas",132
	; DRAW_PAGE2
label_DRAW_PAGE2:	;[133]     PRINT AT 40, "--- SPECIAL ---"
	SRCFILE "./games/orchestra-demo/src/main.bas",133
	MVII #552,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #104,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[134]     PRINT AT 60, "1: BRAVO"
	SRCFILE "./games/orchestra-demo/src/main.bas",134
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #136,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[135]     PRINT AT 80, "2: ENCORE"
	SRCFILE "./games/orchestra-demo/src/main.bas",135
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #144,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[136]     PRINT AT 100, "3: COUNT WORDS"
	SRCFILE "./games/orchestra-demo/src/main.bas",136
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #152,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #440,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[137]     PRINT AT 120, "4: PENCIL DROP"
	SRCFILE "./games/orchestra-demo/src/main.bas",137
	MVII #632,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #160,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #384,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[138]     PRINT AT 140, "5: ORCH TUNING"
	SRCFILE "./games/orchestra-demo/src/main.bas",138
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #168,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #376,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #320,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[139]     PRINT AT 200, "0: MORE >"
	SRCFILE "./games/orchestra-demo/src/main.bas",139
	MVII #712,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #128,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #360,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #240,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[140]     GOTO draw_done
	SRCFILE "./games/orchestra-demo/src/main.bas",140
	B label_DRAW_DONE
	;[141] draw_page3:
	SRCFILE "./games/orchestra-demo/src/main.bas",141
	; DRAW_PAGE3
label_DRAW_PAGE3:	;[142]     PRINT AT 40, "--- MUSIC ---"
	SRCFILE "./games/orchestra-demo/src/main.bas",142
	MVII #552,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #104,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #360,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[143]     PRINT AT 60, "1: GREENSLEEVES"
	SRCFILE "./games/orchestra-demo/src/main.bas",143
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #136,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #312,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[144]     PRINT AT 80, "2: CANON IN D"
	SRCFILE "./games/orchestra-demo/src/main.bas",144
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #144,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	XORI #328,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[145]     PRINT AT 100, "3: ORCH TUNING"
	SRCFILE "./games/orchestra-demo/src/main.bas",145
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #152,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #376,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #320,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[146]     PRINT AT 120, "4: NUTCRACKER"
	SRCFILE "./games/orchestra-demo/src/main.bas",146
	MVII #632,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #160,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[147]     PRINT AT 140, "5: STOP MUSIC"
	SRCFILE "./games/orchestra-demo/src/main.bas",147
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #168,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #384,R0
	MVO@ R0,R4
	XORI #360,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[148]     PRINT AT 180, "(music plays in bg)"
	SRCFILE "./games/orchestra-demo/src/main.bas",148
	MVII #692,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #64,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #552,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #536,R0
	MVO@ R0,R4
	XORI #640,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #664,R0
	MVO@ R0,R4
	XORI #584,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #624,R0
	MVO@ R0,R4
	XORI #528,R0
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #624,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[149]     PRINT AT 200, "0: MORE >"
	SRCFILE "./games/orchestra-demo/src/main.bas",149
	MVII #712,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #128,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #360,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #240,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[150]     GOTO draw_done
	SRCFILE "./games/orchestra-demo/src/main.bas",150
	B label_DRAW_DONE
	;[151] draw_done:
	SRCFILE "./games/orchestra-demo/src/main.bas",151
	; DRAW_DONE
label_DRAW_DONE:	;[152]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",152
	RETURN
	;[153] END
	SRCFILE "./games/orchestra-demo/src/main.bas",153
	ENDP
	;[154] 
	SRCFILE "./games/orchestra-demo/src/main.bas",154
	;[155] next_page: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",155
	; NEXT_PAGE
label_NEXT_PAGE:	PROC
	BEGIN
	;[156]     page = page + 1
	SRCFILE "./games/orchestra-demo/src/main.bas",156
	MVI var_PAGE,R0
	INCR R0
	MVO R0,var_PAGE
	;[157]     IF page > MAX_PAGE THEN page = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",157
	MVI var_PAGE,R0
	CMPI #3,R0
	BLE T37
	CLRR R0
	MVO R0,var_PAGE
T37:
	;[158]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",158
	CALL label_DRAW_MENU
	;[159]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",159
	RETURN
	;[160] END
	SRCFILE "./games/orchestra-demo/src/main.bas",160
	ENDP
	;[161] 
	SRCFILE "./games/orchestra-demo/src/main.bas",161
	;[162] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",162
	;[163] ' VOICE VISUALIZER (shared routine)
	SRCFILE "./games/orchestra-demo/src/main.bas",163
	;[164] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",164
	;[165] ' Call with: vid = phrase_id (0-17), then GOSUB voice_viz
	SRCFILE "./games/orchestra-demo/src/main.bas",165
	;[166] ' This displays animated bars while voice plays
	SRCFILE "./games/orchestra-demo/src/main.bas",166
	;[167] 
	SRCFILE "./games/orchestra-demo/src/main.bas",167
	;[168] voice_viz: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",168
	; VOICE_VIZ
label_VOICE_VIZ:	PROC
	BEGIN
	;[169]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",169
	CALL CLRSCR
	;[170]     PRINT AT 6, "VOICE VISUALIZER"
	SRCFILE "./games/orchestra-demo/src/main.bas",170
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #432,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #432,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #160,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[171]     PRINT AT 40, "PHRASE:"
	SRCFILE "./games/orchestra-demo/src/main.bas",171
	MVII #552,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #384,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #144,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[172] 
	SRCFILE "./games/orchestra-demo/src/main.bas",172
	;[173]     ' Print phrase name and phoneme breakdown based on vid
	SRCFILE "./games/orchestra-demo/src/main.bas",173
	;[174]     IF vid = 0 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",174
	MVI var_VID,R0
	TSTR R0
	BNE T38
	;[175]         PRINT AT 60, "CELLO"
	SRCFILE "./games/orchestra-demo/src/main.bas",175
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[176]         PRINT AT 80, "CH-EH-LL-OW"
	SRCFILE "./games/orchestra-demo/src/main.bas",176
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #320,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[177]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",177
T38:
	;[178]     IF vid = 1 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",178
	MVI var_VID,R0
	CMPI #1,R0
	BNE T39
	;[179]         PRINT AT 60, "OBOE"
	SRCFILE "./games/orchestra-demo/src/main.bas",179
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #376,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[180]         PRINT AT 80, "OW-BB1-OW"
	SRCFILE "./games/orchestra-demo/src/main.bas",180
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #376,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #464,R0
	MVO@ R0,R4
	XORI #376,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[181]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",181
T39:
	;[182]     IF vid = 2 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",182
	MVI var_VID,R0
	CMPI #2,R0
	BNE T40
	;[183]         PRINT AT 60, "BASS"
	SRCFILE "./games/orchestra-demo/src/main.bas",183
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #144,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[184]         PRINT AT 80, "BB1-EY-SS"
	SRCFILE "./games/orchestra-demo/src/main.bas",184
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #320,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #496,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[185]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",185
T40:
	;[186]     IF vid = 3 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",186
	MVI var_VID,R0
	CMPI #3,R0
	BNE T41
	;[187]         PRINT AT 60, "TIMPANI"
	SRCFILE "./games/orchestra-demo/src/main.bas",187
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #32,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[188]         PRINT AT 80, "TT1-IH-MM-PP-UH-NN1-IY"
	SRCFILE "./games/orchestra-demo/src/main.bas",188
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #256,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #256,R0
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[189]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",189
T41:
	;[190]     IF vid = 4 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",190
	MVI var_VID,R0
	CMPI #4,R0
	BNE T42
	;[191]         PRINT AT 60, "TROMBONE"
	SRCFILE "./games/orchestra-demo/src/main.bas",191
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[192]         PRINT AT 80, "TT1-RR1-AO-MM-BB1-OW-NN1"
	SRCFILE "./games/orchestra-demo/src/main.bas",192
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #256,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #256,R0
	MVO@ R0,R4
	XORI #376,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #464,R0
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[193]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",193
T42:
	;[194]     IF vid = 5 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",194
	MVI var_VID,R0
	CMPI #5,R0
	BNE T43
	;[195]         PRINT AT 60, "PICCOLO"
	SRCFILE "./games/orchestra-demo/src/main.bas",195
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #384,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[196]         PRINT AT 80, "PP-IH-KK1-UH-LL-OW"
	SRCFILE "./games/orchestra-demo/src/main.bas",196
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #384,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #304,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #464,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[197]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",197
T43:
	;[198]     IF vid = 6 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",198
	MVI var_VID,R0
	CMPI #6,R0
	BNE T44
	;[199]         PRINT AT 60, "TRUMPET"
	SRCFILE "./games/orchestra-demo/src/main.bas",199
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[200]         PRINT AT 80, "TT1-RR1-AX-MM-PP-IH-TT1"
	SRCFILE "./games/orchestra-demo/src/main.bas",200
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #424,R0
	MVO@ R0,R4
	XORI #256,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #256,R0
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #456,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[201]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",201
T44:
	;[202]     IF vid = 7 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",202
	MVI var_VID,R0
	CMPI #7,R0
	BNE T45
	;[203]         PRINT AT 60, "VIOLA"
	SRCFILE "./games/orchestra-demo/src/main.bas",203
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #432,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[204]         PRINT AT 80, "VV-IY-OW-LL-UH"
	SRCFILE "./games/orchestra-demo/src/main.bas",204
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #432,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #472,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #464,R0
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[205]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",205
T45:
	;[206]     IF vid = 8 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",206
	MVI var_VID,R0
	CMPI #8,R0
	BNE T46
	;[207]         PRINT AT 60, "TUBA"
	SRCFILE "./games/orchestra-demo/src/main.bas",207
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[208]         PRINT AT 80, "TT1-UW1-BB1-UH"
	SRCFILE "./games/orchestra-demo/src/main.bas",208
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #304,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #376,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[209]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",209
T46:
	;[210]     IF vid = 9 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",210
	MVI var_VID,R0
	CMPI #9,R0
	BNE T47
	;[211]         PRINT AT 60, "ACHOO!"
	SRCFILE "./games/orchestra-demo/src/main.bas",211
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #264,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[212]         PRINT AT 80, "AA-CH-UW1"
	SRCFILE "./games/orchestra-demo/src/main.bas",212
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #264,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #304,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[213]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",213
T47:
	;[214]     IF vid = 10 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",214
	MVI var_VID,R0
	CMPI #10,R0
	BNE T48
	;[215]         PRINT AT 60, "BRAVO"
	SRCFILE "./games/orchestra-demo/src/main.bas",215
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[216]         PRINT AT 80, "BB1-RR1-AA-VV-OW"
	SRCFILE "./games/orchestra-demo/src/main.bas",216
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	XORI #472,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #472,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[217]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",217
T48:
	;[218]     IF vid = 11 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",218
	MVI var_VID,R0
	CMPI #11,R0
	BNE T49
	;[219]         PRINT AT 60, "ENCORE"
	SRCFILE "./games/orchestra-demo/src/main.bas",219
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #296,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[220]         PRINT AT 80, "AO-NN1-KK1-AO-RR1"
	SRCFILE "./games/orchestra-demo/src/main.bas",220
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #264,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #304,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #464,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #272,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[221]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",221
T49:
	;[222]     IF vid = 12 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",222
	MVI var_VID,R0
	CMPI #12,R0
	BNE T50
	;[223]         PRINT AT 60, "PENCIL DROP"
	SRCFILE "./games/orchestra-demo/src/main.bas",223
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #384,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[224]         PRINT AT 80, "PP-TT1-TT2-TT1 (SFX)"
	SRCFILE "./games/orchestra-demo/src/main.bas",224
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #384,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	XORI #456,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #456,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #304,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #456,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #472,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #240,R0
	MVO@ R0,R4
	XORI #392,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[225]     END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",225
T50:
	;[226] 
	SRCFILE "./games/orchestra-demo/src/main.bas",226
	;[227]     PRINT AT 120, "INTELLIVOICE OUTPUT:"
	SRCFILE "./games/orchestra-demo/src/main.bas",227
	MVII #632,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #328,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #376,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #32,R0
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[228]     PRINT AT 220, "BTN=EXIT"
	SRCFILE "./games/orchestra-demo/src/main.bas",228
	MVII #732,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[229] 
	SRCFILE "./games/orchestra-demo/src/main.bas",229
	;[230]     ' Wait for controller release (debounce)
	SRCFILE "./games/orchestra-demo/src/main.bas",230
	;[231]     WHILE CONT.BUTTON
	SRCFILE "./games/orchestra-demo/src/main.bas",231
T51:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T52
	;[232]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",232
	CALL _wait
	;[233]     WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",233
	B T51
T52:
	;[234] 
	SRCFILE "./games/orchestra-demo/src/main.bas",234
	;[235]     ' Start the voice based on vid
	SRCFILE "./games/orchestra-demo/src/main.bas",235
	;[236]     ON vid GOSUB vp0,vp1,vp2,vp3,vp4,vp5,vp6,vp7,vp8,vp9,vp10,vp11,vp12
	SRCFILE "./games/orchestra-demo/src/main.bas",236
	MVI var_VID,R1
	CMPI #13,R1
	BC T54
	MVII #T54,R5
	ADDI #T53,R1
	MVI@ R1,PC
T53:
	DECLE label_VP0
	DECLE label_VP1
	DECLE label_VP2
	DECLE label_VP3
	DECLE label_VP4
	DECLE label_VP5
	DECLE label_VP6
	DECLE label_VP7
	DECLE label_VP8
	DECLE label_VP9
	DECLE label_VP10
	DECLE label_VP11
	DECLE label_VP12
T54:
	;[237]     tick = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",237
	CLRR R0
	MVO R0,var_TICK
	;[238] 
	SRCFILE "./games/orchestra-demo/src/main.bas",238
	;[239]     ' Animate while voice is playing
	SRCFILE "./games/orchestra-demo/src/main.bas",239
	;[240]     WHILE VOICE.PLAYING
	SRCFILE "./games/orchestra-demo/src/main.bas",240
T55:
	MVI IV.QT,R0
	ANDI #7,R0
	SUB IV.QH,R0
	BNE T57
	MVI IV.FPTR,R0
	TSTR R0
	BNE T57
	MVI 129,R0
	COMR R0
	AND 128,R0
	COMR R0
	ANDI #32768,R0
T57:
	TSTR R0
	BEQ T56
	;[241]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",241
	CALL _wait
	;[242] 
	SRCFILE "./games/orchestra-demo/src/main.bas",242
	;[243]         ' Check for early exit
	SRCFILE "./games/orchestra-demo/src/main.bas",243
	;[244]         IF CONT.BUTTON THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",244
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T58
	;[245]             VOICE INIT
	SRCFILE "./games/orchestra-demo/src/main.bas",245
	CALL IV_HUSH
	;[246]             EXIT WHILE
	SRCFILE "./games/orchestra-demo/src/main.bas",246
	B T56
	;[247]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",247
T58:
	;[248] 
	SRCFILE "./games/orchestra-demo/src/main.bas",248
	;[249]         tick = tick + 1
	SRCFILE "./games/orchestra-demo/src/main.bas",249
	MVI var_TICK,R0
	INCR R0
	MVO R0,var_TICK
	;[250] 
	SRCFILE "./games/orchestra-demo/src/main.bas",250
	;[251]         ' Animated bars
	SRCFILE "./games/orchestra-demo/src/main.bas",251
	;[252]         r = (tick + RAND) AND 7
	SRCFILE "./games/orchestra-demo/src/main.bas",252
	MVI _rand,R0
	ADD var_TICK,R0
	ANDI #7,R0
	MVO R0,var_R
	;[253]         IF r < 2 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",253
	MVI var_R,R0
	CMPI #2,R0
	BGE T59
	;[254]             PRINT AT 142, "_"
	SRCFILE "./games/orchestra-demo/src/main.bas",254
	MVII #654,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #504,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[255]         ELSEIF r < 4 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",255
	B T60
T59:
	MVI var_R,R0
	CMPI #4,R0
	BGE T61
	;[256]             PRINT AT 142, "="
	SRCFILE "./games/orchestra-demo/src/main.bas",256
	MVII #654,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #232,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[257]         ELSEIF r < 6 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",257
	B T60
T61:
	MVI var_R,R0
	CMPI #6,R0
	BGE T62
	;[258]             PRINT AT 142, "#"
	SRCFILE "./games/orchestra-demo/src/main.bas",258
	MVII #654,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #24,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[259]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",259
	B T60
T62:
	;[260]             PRINT AT 142, "@"
	SRCFILE "./games/orchestra-demo/src/main.bas",260
	MVII #654,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #256,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[261]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",261
T60:
	;[262] 
	SRCFILE "./games/orchestra-demo/src/main.bas",262
	;[263]         r = (tick + RAND + 3) AND 7
	SRCFILE "./games/orchestra-demo/src/main.bas",263
	MVI _rand,R0
	ADD var_TICK,R0
	ADDI #3,R0
	ANDI #7,R0
	MVO R0,var_R
	;[264]         IF r < 2 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",264
	MVI var_R,R0
	CMPI #2,R0
	BGE T63
	;[265]             PRINT AT 144, "_"
	SRCFILE "./games/orchestra-demo/src/main.bas",265
	MVII #656,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #504,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[266]         ELSEIF r < 4 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",266
	B T64
T63:
	MVI var_R,R0
	CMPI #4,R0
	BGE T65
	;[267]             PRINT AT 144, "="
	SRCFILE "./games/orchestra-demo/src/main.bas",267
	MVII #656,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #232,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[268]         ELSEIF r < 6 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",268
	B T64
T65:
	MVI var_R,R0
	CMPI #6,R0
	BGE T66
	;[269]             PRINT AT 144, "#"
	SRCFILE "./games/orchestra-demo/src/main.bas",269
	MVII #656,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #24,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[270]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",270
	B T64
T66:
	;[271]             PRINT AT 144, "@"
	SRCFILE "./games/orchestra-demo/src/main.bas",271
	MVII #656,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #256,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[272]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",272
T64:
	;[273] 
	SRCFILE "./games/orchestra-demo/src/main.bas",273
	;[274]         r = (tick + RAND + 5) AND 7
	SRCFILE "./games/orchestra-demo/src/main.bas",274
	MVI _rand,R0
	ADD var_TICK,R0
	ADDI #5,R0
	ANDI #7,R0
	MVO R0,var_R
	;[275]         IF r < 2 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",275
	MVI var_R,R0
	CMPI #2,R0
	BGE T67
	;[276]             PRINT AT 146, "_"
	SRCFILE "./games/orchestra-demo/src/main.bas",276
	MVII #658,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #504,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[277]         ELSEIF r < 4 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",277
	B T68
T67:
	MVI var_R,R0
	CMPI #4,R0
	BGE T69
	;[278]             PRINT AT 146, "="
	SRCFILE "./games/orchestra-demo/src/main.bas",278
	MVII #658,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #232,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[279]         ELSEIF r < 6 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",279
	B T68
T69:
	MVI var_R,R0
	CMPI #6,R0
	BGE T70
	;[280]             PRINT AT 146, "#"
	SRCFILE "./games/orchestra-demo/src/main.bas",280
	MVII #658,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #24,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[281]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",281
	B T68
T70:
	;[282]             PRINT AT 146, "@"
	SRCFILE "./games/orchestra-demo/src/main.bas",282
	MVII #658,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #256,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[283]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",283
T68:
	;[284] 
	SRCFILE "./games/orchestra-demo/src/main.bas",284
	;[285]         r = (tick + RAND + 2) AND 7
	SRCFILE "./games/orchestra-demo/src/main.bas",285
	MVI _rand,R0
	ADD var_TICK,R0
	ADDI #2,R0
	ANDI #7,R0
	MVO R0,var_R
	;[286]         IF r < 2 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",286
	MVI var_R,R0
	CMPI #2,R0
	BGE T71
	;[287]             PRINT AT 148, "_"
	SRCFILE "./games/orchestra-demo/src/main.bas",287
	MVII #660,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #504,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[288]         ELSEIF r < 4 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",288
	B T72
T71:
	MVI var_R,R0
	CMPI #4,R0
	BGE T73
	;[289]             PRINT AT 148, "="
	SRCFILE "./games/orchestra-demo/src/main.bas",289
	MVII #660,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #232,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[290]         ELSEIF r < 6 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",290
	B T72
T73:
	MVI var_R,R0
	CMPI #6,R0
	BGE T74
	;[291]             PRINT AT 148, "#"
	SRCFILE "./games/orchestra-demo/src/main.bas",291
	MVII #660,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #24,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[292]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",292
	B T72
T74:
	;[293]             PRINT AT 148, "@"
	SRCFILE "./games/orchestra-demo/src/main.bas",293
	MVII #660,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #256,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[294]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",294
T72:
	;[295] 
	SRCFILE "./games/orchestra-demo/src/main.bas",295
	;[296]         r = (tick + RAND + 7) AND 7
	SRCFILE "./games/orchestra-demo/src/main.bas",296
	MVI _rand,R0
	ADD var_TICK,R0
	ADDI #7,R0
	ANDI #7,R0
	MVO R0,var_R
	;[297]         IF r < 2 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",297
	MVI var_R,R0
	CMPI #2,R0
	BGE T75
	;[298]             PRINT AT 150, "_"
	SRCFILE "./games/orchestra-demo/src/main.bas",298
	MVII #662,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #504,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[299]         ELSEIF r < 4 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",299
	B T76
T75:
	MVI var_R,R0
	CMPI #4,R0
	BGE T77
	;[300]             PRINT AT 150, "="
	SRCFILE "./games/orchestra-demo/src/main.bas",300
	MVII #662,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #232,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[301]         ELSEIF r < 6 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",301
	B T76
T77:
	MVI var_R,R0
	CMPI #6,R0
	BGE T78
	;[302]             PRINT AT 150, "#"
	SRCFILE "./games/orchestra-demo/src/main.bas",302
	MVII #662,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #24,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[303]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",303
	B T76
T78:
	;[304]             PRINT AT 150, "@"
	SRCFILE "./games/orchestra-demo/src/main.bas",304
	MVII #662,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #256,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[305]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",305
T76:
	;[306] 
	SRCFILE "./games/orchestra-demo/src/main.bas",306
	;[307]         r = (tick + RAND + 1) AND 7
	SRCFILE "./games/orchestra-demo/src/main.bas",307
	MVI _rand,R0
	ADD var_TICK,R0
	INCR R0
	ANDI #7,R0
	MVO R0,var_R
	;[308]         IF r < 2 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",308
	MVI var_R,R0
	CMPI #2,R0
	BGE T79
	;[309]             PRINT AT 152, "_"
	SRCFILE "./games/orchestra-demo/src/main.bas",309
	MVII #664,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #504,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[310]         ELSEIF r < 4 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",310
	B T80
T79:
	MVI var_R,R0
	CMPI #4,R0
	BGE T81
	;[311]             PRINT AT 152, "="
	SRCFILE "./games/orchestra-demo/src/main.bas",311
	MVII #664,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #232,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[312]         ELSEIF r < 6 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",312
	B T80
T81:
	MVI var_R,R0
	CMPI #6,R0
	BGE T82
	;[313]             PRINT AT 152, "#"
	SRCFILE "./games/orchestra-demo/src/main.bas",313
	MVII #664,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #24,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[314]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",314
	B T80
T82:
	;[315]             PRINT AT 152, "@"
	SRCFILE "./games/orchestra-demo/src/main.bas",315
	MVII #664,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #256,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[316]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",316
T80:
	;[317] 
	SRCFILE "./games/orchestra-demo/src/main.bas",317
	;[318]         ' Blinking SPEAKING indicator
	SRCFILE "./games/orchestra-demo/src/main.bas",318
	;[319]         IF (tick AND 4) THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",319
	MVI var_TICK,R0
	ANDI #4,R0
	BEQ T83
	;[320]             PRINT AT 180, "** SPEAKING **"
	SRCFILE "./games/orchestra-demo/src/main.bas",320
	MVII #692,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #80,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #32,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #312,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[321]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",321
	B T84
T83:
	;[322]             PRINT AT 180, "              "
	SRCFILE "./games/orchestra-demo/src/main.bas",322
	MVII #692,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[323]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",323
T84:
	;[324] 
	SRCFILE "./games/orchestra-demo/src/main.bas",324
	;[325]         PRINT AT 200, "FRAME: "
	SRCFILE "./games/orchestra-demo/src/main.bas",325
	MVII #712,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #304,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #160,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[326]         PRINT AT 207, <3>tick
	SRCFILE "./games/orchestra-demo/src/main.bas",326
	MVII #719,R0
	MVO R0,_screen
	MVI var_TICK,R0
	MVII #3,R2
	MVI _color,R3
	MVI _screen,R4
	CALL PRNUM16.z
	MVO R4,_screen
	;[327]     WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",327
	B T55
T56:
	;[328] 
	SRCFILE "./games/orchestra-demo/src/main.bas",328
	;[329]     PRINT AT 142, "          "
	SRCFILE "./games/orchestra-demo/src/main.bas",329
	MVII #654,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[330]     PRINT AT 180, "--- DONE ---  "
	SRCFILE "./games/orchestra-demo/src/main.bas",330
	MVII #692,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #104,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[331]     FOR j = 1 TO 60: WAIT: NEXT j
	SRCFILE "./games/orchestra-demo/src/main.bas",331
	MVII #1,R0
	MVO R0,var_J
T85:
	CALL _wait
	MVI var_J,R0
	INCR R0
	MVO R0,var_J
	CMPI #60,R0
	BLE T85
	;[332] 
	SRCFILE "./games/orchestra-demo/src/main.bas",332
	;[333]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",333
	CALL label_DRAW_MENU
	;[334]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",334
	RETURN
	;[335] END
	SRCFILE "./games/orchestra-demo/src/main.bas",335
	ENDP
	;[336] 
	SRCFILE "./games/orchestra-demo/src/main.bas",336
	;[337] ' Voice play helpers (called via ON GOSUB)
	SRCFILE "./games/orchestra-demo/src/main.bas",337
	;[338] vp0: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",338
	; VP0
label_VP0:	PROC
	BEGIN
	;[339]     VOICE PLAY cello_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",339
	MVII #label_CELLO_PHRASE,R0
	CALL IV_PLAY.1
	;[340]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",340
	RETURN
	;[341] END
	SRCFILE "./games/orchestra-demo/src/main.bas",341
	ENDP
	;[342] 
	SRCFILE "./games/orchestra-demo/src/main.bas",342
	;[343] vp1: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",343
	; VP1
label_VP1:	PROC
	BEGIN
	;[344]     VOICE PLAY oboe_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",344
	MVII #label_OBOE_PHRASE,R0
	CALL IV_PLAY.1
	;[345]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",345
	RETURN
	;[346] END
	SRCFILE "./games/orchestra-demo/src/main.bas",346
	ENDP
	;[347] 
	SRCFILE "./games/orchestra-demo/src/main.bas",347
	;[348] vp2: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",348
	; VP2
label_VP2:	PROC
	BEGIN
	;[349]     VOICE PLAY bass_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",349
	MVII #label_BASS_PHRASE,R0
	CALL IV_PLAY.1
	;[350]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",350
	RETURN
	;[351] END
	SRCFILE "./games/orchestra-demo/src/main.bas",351
	ENDP
	;[352] 
	SRCFILE "./games/orchestra-demo/src/main.bas",352
	;[353] vp3: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",353
	; VP3
label_VP3:	PROC
	BEGIN
	;[354]     VOICE PLAY timpani_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",354
	MVII #label_TIMPANI_PHRASE,R0
	CALL IV_PLAY.1
	;[355]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",355
	RETURN
	;[356] END
	SRCFILE "./games/orchestra-demo/src/main.bas",356
	ENDP
	;[357] 
	SRCFILE "./games/orchestra-demo/src/main.bas",357
	;[358] vp4: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",358
	; VP4
label_VP4:	PROC
	BEGIN
	;[359]     VOICE PLAY trombone_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",359
	MVII #label_TROMBONE_PHRASE,R0
	CALL IV_PLAY.1
	;[360]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",360
	RETURN
	;[361] END
	SRCFILE "./games/orchestra-demo/src/main.bas",361
	ENDP
	;[362] 
	SRCFILE "./games/orchestra-demo/src/main.bas",362
	;[363] vp5: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",363
	; VP5
label_VP5:	PROC
	BEGIN
	;[364]     VOICE PLAY piccolo_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",364
	MVII #label_PICCOLO_PHRASE,R0
	CALL IV_PLAY.1
	;[365]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",365
	RETURN
	;[366] END
	SRCFILE "./games/orchestra-demo/src/main.bas",366
	ENDP
	;[367] 
	SRCFILE "./games/orchestra-demo/src/main.bas",367
	;[368] vp6: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",368
	; VP6
label_VP6:	PROC
	BEGIN
	;[369]     VOICE PLAY trumpet_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",369
	MVII #label_TRUMPET_PHRASE,R0
	CALL IV_PLAY.1
	;[370]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",370
	RETURN
	;[371] END
	SRCFILE "./games/orchestra-demo/src/main.bas",371
	ENDP
	;[372] 
	SRCFILE "./games/orchestra-demo/src/main.bas",372
	;[373] vp7: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",373
	; VP7
label_VP7:	PROC
	BEGIN
	;[374]     VOICE PLAY viola_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",374
	MVII #label_VIOLA_PHRASE,R0
	CALL IV_PLAY.1
	;[375]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",375
	RETURN
	;[376] END
	SRCFILE "./games/orchestra-demo/src/main.bas",376
	ENDP
	;[377] 
	SRCFILE "./games/orchestra-demo/src/main.bas",377
	;[378] vp8: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",378
	; VP8
label_VP8:	PROC
	BEGIN
	;[379]     VOICE PLAY tuba_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",379
	MVII #label_TUBA_PHRASE,R0
	CALL IV_PLAY.1
	;[380]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",380
	RETURN
	;[381] END
	SRCFILE "./games/orchestra-demo/src/main.bas",381
	ENDP
	;[382] 
	SRCFILE "./games/orchestra-demo/src/main.bas",382
	;[383] vp9: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",383
	; VP9
label_VP9:	PROC
	BEGIN
	;[384]     VOICE PLAY sneeze_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",384
	MVII #label_SNEEZE_PHRASE,R0
	CALL IV_PLAY.1
	;[385]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",385
	RETURN
	;[386] END
	SRCFILE "./games/orchestra-demo/src/main.bas",386
	ENDP
	;[387] 
	SRCFILE "./games/orchestra-demo/src/main.bas",387
	;[388] vp10: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",388
	; VP10
label_VP10:	PROC
	BEGIN
	;[389]     VOICE PLAY bravo_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",389
	MVII #label_BRAVO_PHRASE,R0
	CALL IV_PLAY.1
	;[390]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",390
	RETURN
	;[391] END
	SRCFILE "./games/orchestra-demo/src/main.bas",391
	ENDP
	;[392] 
	SRCFILE "./games/orchestra-demo/src/main.bas",392
	;[393] vp11: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",393
	; VP11
label_VP11:	PROC
	BEGIN
	;[394]     VOICE PLAY encore_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",394
	MVII #label_ENCORE_PHRASE,R0
	CALL IV_PLAY.1
	;[395]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",395
	RETURN
	;[396] END
	SRCFILE "./games/orchestra-demo/src/main.bas",396
	ENDP
	;[397] 
	SRCFILE "./games/orchestra-demo/src/main.bas",397
	;[398] vp12: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",398
	; VP12
label_VP12:	PROC
	BEGIN
	;[399]     VOICE PLAY pencil_phrase
	SRCFILE "./games/orchestra-demo/src/main.bas",399
	MVII #label_PENCIL_PHRASE,R0
	CALL IV_PLAY.1
	;[400]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",400
	RETURN
	;[401] END
	SRCFILE "./games/orchestra-demo/src/main.bas",401
	ENDP
	;[402] 
	SRCFILE "./games/orchestra-demo/src/main.bas",402
	;[403] ' --- Instrument Procedures (now use visualizer) ---
	SRCFILE "./games/orchestra-demo/src/main.bas",403
	;[404] say_cello: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",404
	; SAY_CELLO
label_SAY_CELLO:	PROC
	BEGIN
	;[405]     vid = 0: GOSUB voice_viz
	SRCFILE "./games/orchestra-demo/src/main.bas",405
	CLRR R0
	MVO R0,var_VID
	CALL label_VOICE_VIZ
	;[406]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",406
	RETURN
	;[407] END
	SRCFILE "./games/orchestra-demo/src/main.bas",407
	ENDP
	;[408] 
	SRCFILE "./games/orchestra-demo/src/main.bas",408
	;[409] say_oboe: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",409
	; SAY_OBOE
label_SAY_OBOE:	PROC
	BEGIN
	;[410]     vid = 1: GOSUB voice_viz
	SRCFILE "./games/orchestra-demo/src/main.bas",410
	MVII #1,R0
	MVO R0,var_VID
	CALL label_VOICE_VIZ
	;[411]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",411
	RETURN
	;[412] END
	SRCFILE "./games/orchestra-demo/src/main.bas",412
	ENDP
	;[413] 
	SRCFILE "./games/orchestra-demo/src/main.bas",413
	;[414] say_bass: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",414
	; SAY_BASS
label_SAY_BASS:	PROC
	BEGIN
	;[415]     vid = 2: GOSUB voice_viz
	SRCFILE "./games/orchestra-demo/src/main.bas",415
	MVII #2,R0
	MVO R0,var_VID
	CALL label_VOICE_VIZ
	;[416]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",416
	RETURN
	;[417] END
	SRCFILE "./games/orchestra-demo/src/main.bas",417
	ENDP
	;[418] 
	SRCFILE "./games/orchestra-demo/src/main.bas",418
	;[419] say_timpani: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",419
	; SAY_TIMPANI
label_SAY_TIMPANI:	PROC
	BEGIN
	;[420]     vid = 3: GOSUB voice_viz
	SRCFILE "./games/orchestra-demo/src/main.bas",420
	MVII #3,R0
	MVO R0,var_VID
	CALL label_VOICE_VIZ
	;[421]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",421
	RETURN
	;[422] END
	SRCFILE "./games/orchestra-demo/src/main.bas",422
	ENDP
	;[423] 
	SRCFILE "./games/orchestra-demo/src/main.bas",423
	;[424] say_trombone: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",424
	; SAY_TROMBONE
label_SAY_TROMBONE:	PROC
	BEGIN
	;[425]     vid = 4: GOSUB voice_viz
	SRCFILE "./games/orchestra-demo/src/main.bas",425
	MVII #4,R0
	MVO R0,var_VID
	CALL label_VOICE_VIZ
	;[426]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",426
	RETURN
	;[427] END
	SRCFILE "./games/orchestra-demo/src/main.bas",427
	ENDP
	;[428] 
	SRCFILE "./games/orchestra-demo/src/main.bas",428
	;[429] say_piccolo: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",429
	; SAY_PICCOLO
label_SAY_PICCOLO:	PROC
	BEGIN
	;[430]     vid = 5: GOSUB voice_viz
	SRCFILE "./games/orchestra-demo/src/main.bas",430
	MVII #5,R0
	MVO R0,var_VID
	CALL label_VOICE_VIZ
	;[431]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",431
	RETURN
	;[432] END
	SRCFILE "./games/orchestra-demo/src/main.bas",432
	ENDP
	;[433] 
	SRCFILE "./games/orchestra-demo/src/main.bas",433
	;[434] ' Move sneeze procedures to Segment 1 to avoid overflow
	SRCFILE "./games/orchestra-demo/src/main.bas",434
	;[435]     SEGMENT 1
	SRCFILE "./games/orchestra-demo/src/main.bas",435
ROM.SelectSegment 1
	;[436] 
	SRCFILE "./games/orchestra-demo/src/main.bas",436
	;[437] sneeze_normal: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",437
	; SNEEZE_NORMAL
label_SNEEZE_NORMAL:	PROC
	BEGIN
	;[438]     ' PSG-based sneeze effect: "Ahh...CHOO!"
	SRCFILE "./games/orchestra-demo/src/main.bas",438
	;[439]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",439
	CALL CLRSCR
	;[440]     PRINT AT 6, "NORMAL SNEEZE"
	SRCFILE "./games/orchestra-demo/src/main.bas",440
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #368,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[441]     PRINT AT 60, "Ahh...CHOO!"
	SRCFILE "./games/orchestra-demo/src/main.bas",441
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #264,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #840,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #560,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #360,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[442]     PRINT AT 220, "BTN=EXIT"
	SRCFILE "./games/orchestra-demo/src/main.bas",442
	MVII #732,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[443] 
	SRCFILE "./games/orchestra-demo/src/main.bas",443
	;[444]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",444
T86:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T87
	CALL _wait
	B T86
T87:
	;[445] 
	SRCFILE "./games/orchestra-demo/src/main.bas",445
	;[446]     ' Phase 1: Build-up "Ahhh..." - rising tone with slight warble
	SRCFILE "./games/orchestra-demo/src/main.bas",446
	;[447]     PRINT AT 100, "  Ahhh...  "
	SRCFILE "./games/orchestra-demo/src/main.bas",447
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	XORI #840,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #560,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[448]     FOR i = 0 TO 20
	SRCFILE "./games/orchestra-demo/src/main.bas",448
	CLRR R0
	MVO R0,var_I
T88:
	;[449]         freq = 300 - (i * 5)
	SRCFILE "./games/orchestra-demo/src/main.bas",449
	MVII #300,R0
	MVI var_I,R1
	MULT R1,R4,5
	SUBR R1,R0
	MVO R0,var_FREQ
	;[450]         vol = 8 + (i / 4)
	SRCFILE "./games/orchestra-demo/src/main.bas",450
	MVI var_I,R0
	SLR R0,2
	ADDI #8,R0
	MVO R0,var_VOL
	;[451]         SOUND 0, freq, vol
	SRCFILE "./games/orchestra-demo/src/main.bas",451
	MVI var_FREQ,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVI var_VOL,R0
	MVO R0,507
	;[452]         SOUND 1, freq + 3, vol - 2  ' Slight detuning for texture
	SRCFILE "./games/orchestra-demo/src/main.bas",452
	MVI var_FREQ,R0
	ADDI #3,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVI var_VOL,R0
	SUBI #2,R0
	MVO R0,508
	;[453]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",453
	CALL _wait
	;[454]         IF CONT.BUTTON THEN GOTO sn_done
	SRCFILE "./games/orchestra-demo/src/main.bas",454
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_SN_DONE
	;[455]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",455
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #20,R0
	BLE T88
	;[456] 
	SRCFILE "./games/orchestra-demo/src/main.bas",456
	;[457]     ' Phase 2: Pause/inhale - quick silence
	SRCFILE "./games/orchestra-demo/src/main.bas",457
	;[458]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",458
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[459]     SOUND 1, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",459
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[460]     PRINT AT 100, "           "
	SRCFILE "./games/orchestra-demo/src/main.bas",460
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[461]     FOR i = 1 TO 8: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",461
	MVII #1,R0
	MVO R0,var_I
T90:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #8,R0
	BLE T90
	;[462] 
	SRCFILE "./games/orchestra-demo/src/main.bas",462
	;[463]     ' Phase 3: "CHOO!" - explosive noise burst
	SRCFILE "./games/orchestra-demo/src/main.bas",463
	;[464]     PRINT AT 100, "  CHOO!!   "
	SRCFILE "./games/orchestra-demo/src/main.bas",464
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[465]     SOUND 4, 12, 7          ' Noise on all 3 channels
	SRCFILE "./games/orchestra-demo/src/main.bas",465
	MVII #12,R0
	MVO R0,505
	MVII #7,R0
	MVO R0,504
	;[466]     SOUND 0, 120, 15        ' Low fundamental
	SRCFILE "./games/orchestra-demo/src/main.bas",466
	MVII #120,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #15,R0
	MVO R0,507
	;[467]     SOUND 1, 180, 12        ' Mid tone
	SRCFILE "./games/orchestra-demo/src/main.bas",467
	MVII #180,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVII #12,R0
	MVO R0,508
	;[468]     SOUND 2, 90, 10         ' Sub bass
	SRCFILE "./games/orchestra-demo/src/main.bas",468
	MVII #90,R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	MVII #10,R0
	MVO R0,509
	;[469] 
	SRCFILE "./games/orchestra-demo/src/main.bas",469
	;[470]     ' Rapid decay
	SRCFILE "./games/orchestra-demo/src/main.bas",470
	;[471]     FOR i = 15 TO 0 STEP -1
	SRCFILE "./games/orchestra-demo/src/main.bas",471
	MVII #15,R0
	MVO R0,var_I
T91:
	;[472]         SOUND 0, 120, i
	SRCFILE "./games/orchestra-demo/src/main.bas",472
	MVII #120,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVI var_I,R0
	MVO R0,507
	;[473]         SOUND 1, 180, (i * 3) / 4
	SRCFILE "./games/orchestra-demo/src/main.bas",473
	MVII #180,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVI var_I,R0
	MULT R0,R4,3
	SLR R0,2
	MVO R0,508
	;[474]         SOUND 2, 90, i / 2
	SRCFILE "./games/orchestra-demo/src/main.bas",474
	MVII #90,R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	MVI var_I,R0
	SLR R0,1
	MVO R0,509
	;[475]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",475
	CALL _wait
	;[476]         IF CONT.BUTTON THEN GOTO sn_done
	SRCFILE "./games/orchestra-demo/src/main.bas",476
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_SN_DONE
	;[477]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",477
	MVI var_I,R0
	DECR R0
	MVO R0,var_I
	CMPI #0,R0
	BGE T91
	;[478] 
	SRCFILE "./games/orchestra-demo/src/main.bas",478
	;[479]     ' Cleanup
	SRCFILE "./games/orchestra-demo/src/main.bas",479
	;[480] sn_done:
	SRCFILE "./games/orchestra-demo/src/main.bas",480
	; SN_DONE
label_SN_DONE:	;[481]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",481
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[482]     SOUND 1, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",482
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[483]     SOUND 2, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",483
	MVO R0,498
	SWAP R0
	MVO R0,502
	CLRR R0
	MVO R0,509
	;[484]     SOUND 4, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",484
	MVO R0,505
	NOP
	MVO R0,504
	;[485] 
	SRCFILE "./games/orchestra-demo/src/main.bas",485
	;[486]     PRINT AT 100, " *sniff*   "
	SRCFILE "./games/orchestra-demo/src/main.bas",486
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #712,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #608,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[487]     FOR i = 1 TO 40: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",487
	MVII #1,R0
	MVO R0,var_I
T93:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #40,R0
	BLE T93
	;[488] 
	SRCFILE "./games/orchestra-demo/src/main.bas",488
	;[489]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",489
	CALL label_DRAW_MENU
	;[490]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",490
	RETURN
	;[491] END
	SRCFILE "./games/orchestra-demo/src/main.bas",491
	ENDP
	;[492] 
	SRCFILE "./games/orchestra-demo/src/main.bas",492
	;[493] sneeze_big: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",493
	; SNEEZE_BIG
label_SNEEZE_BIG:	PROC
	BEGIN
	;[494]     ' BIG DRAMATIC sneeze - long build-up, massive explosion
	SRCFILE "./games/orchestra-demo/src/main.bas",494
	;[495]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",495
	CALL CLRSCR
	;[496]     PRINT AT 6, "BIG SNEEZE"
	SRCFILE "./games/orchestra-demo/src/main.bas",496
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #312,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[497]     PRINT AT 60, "AAAAHHHHH...CHOOO!!!"
	SRCFILE "./games/orchestra-demo/src/main.bas",497
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #264,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	XORI #304,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #360,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[498]     PRINT AT 220, "BTN=EXIT"
	SRCFILE "./games/orchestra-demo/src/main.bas",498
	MVII #732,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[499] 
	SRCFILE "./games/orchestra-demo/src/main.bas",499
	;[500]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",500
T94:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T95
	CALL _wait
	B T94
T95:
	;[501] 
	SRCFILE "./games/orchestra-demo/src/main.bas",501
	;[502]     ' Phase 1: Long dramatic build-up with crescendo
	SRCFILE "./games/orchestra-demo/src/main.bas",502
	;[503]     PRINT AT 100, " AAAAAHHH.."
	SRCFILE "./games/orchestra-demo/src/main.bas",503
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #304,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[504]     FOR i = 0 TO 40
	SRCFILE "./games/orchestra-demo/src/main.bas",504
	CLRR R0
	MVO R0,var_I
T96:
	;[505]         freq = 400 - (i * 4)
	SRCFILE "./games/orchestra-demo/src/main.bas",505
	MVII #400,R0
	MVI var_I,R1
	SLL R1,2
	SUBR R1,R0
	MVO R0,var_FREQ
	;[506]         vol = 5 + (i / 5)
	SRCFILE "./games/orchestra-demo/src/main.bas",506
	MVI var_I,R0
	MVII #65535,R4
T97:
	INCR R4
	SUBI #5,R0
	BC T97
	MOVR R4,R0
	ADDI #5,R0
	MVO R0,var_VOL
	;[507]         IF vol > 14 THEN vol = 14
	SRCFILE "./games/orchestra-demo/src/main.bas",507
	MVI var_VOL,R0
	CMPI #14,R0
	BLE T98
	MVII #14,R0
	MVO R0,var_VOL
T98:
	;[508]         SOUND 0, freq, vol
	SRCFILE "./games/orchestra-demo/src/main.bas",508
	MVI var_FREQ,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVI var_VOL,R0
	MVO R0,507
	;[509]         SOUND 1, freq + 5, vol - 2
	SRCFILE "./games/orchestra-demo/src/main.bas",509
	MVI var_FREQ,R0
	ADDI #5,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVI var_VOL,R0
	SUBI #2,R0
	MVO R0,508
	;[510]         SOUND 2, freq - 10, vol / 2  ' Deep undertone
	SRCFILE "./games/orchestra-demo/src/main.bas",510
	MVI var_FREQ,R0
	SUBI #10,R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	MVI var_VOL,R0
	SLR R0,1
	MVO R0,509
	;[511]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",511
	CALL _wait
	;[512]         IF CONT.BUTTON THEN GOTO sb_done
	SRCFILE "./games/orchestra-demo/src/main.bas",512
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_SB_DONE
	;[513]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",513
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #40,R0
	BLE T96
	;[514] 
	SRCFILE "./games/orchestra-demo/src/main.bas",514
	;[515]     ' Phase 2: Suspenseful pause
	SRCFILE "./games/orchestra-demo/src/main.bas",515
	;[516]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",516
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[517]     SOUND 1, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",517
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[518]     SOUND 2, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",518
	MVO R0,498
	SWAP R0
	MVO R0,502
	CLRR R0
	MVO R0,509
	;[519]     PRINT AT 100, "           "
	SRCFILE "./games/orchestra-demo/src/main.bas",519
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[520]     FOR i = 1 TO 15: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",520
	MVII #1,R0
	MVO R0,var_I
T100:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #15,R0
	BLE T100
	;[521] 
	SRCFILE "./games/orchestra-demo/src/main.bas",521
	;[522]     ' Phase 3: MASSIVE "CHOOOOO!!!" - all channels at max
	SRCFILE "./games/orchestra-demo/src/main.bas",522
	;[523]     PRINT AT 100, "CHOOOOO!!!!"
	SRCFILE "./games/orchestra-demo/src/main.bas",523
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[524]     SOUND 4, 8, 7           ' Heavy noise
	SRCFILE "./games/orchestra-demo/src/main.bas",524
	MVII #8,R0
	MVO R0,505
	MVII #7,R0
	MVO R0,504
	;[525]     SOUND 0, 80, 15         ' Deep bass
	SRCFILE "./games/orchestra-demo/src/main.bas",525
	MVII #80,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #15,R0
	MVO R0,507
	;[526]     SOUND 1, 150, 15        ' Mid tone
	SRCFILE "./games/orchestra-demo/src/main.bas",526
	MVII #150,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVII #15,R0
	MVO R0,508
	;[527]     SOUND 2, 60, 15         ' Sub rumble
	SRCFILE "./games/orchestra-demo/src/main.bas",527
	MVII #60,R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	MVII #15,R0
	MVO R0,509
	;[528] 
	SRCFILE "./games/orchestra-demo/src/main.bas",528
	;[529]     ' Long dramatic decay
	SRCFILE "./games/orchestra-demo/src/main.bas",529
	;[530]     FOR i = 15 TO 0 STEP -1
	SRCFILE "./games/orchestra-demo/src/main.bas",530
	MVO R0,var_I
T101:
	;[531]         SOUND 0, 80, i
	SRCFILE "./games/orchestra-demo/src/main.bas",531
	MVII #80,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVI var_I,R0
	MVO R0,507
	;[532]         SOUND 1, 150, i
	SRCFILE "./games/orchestra-demo/src/main.bas",532
	MVII #150,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVI var_I,R0
	MVO R0,508
	;[533]         SOUND 2, 60, i
	SRCFILE "./games/orchestra-demo/src/main.bas",533
	MVII #60,R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	MVI var_I,R0
	MVO R0,509
	;[534]         WAIT: WAIT  ' Slow decay
	SRCFILE "./games/orchestra-demo/src/main.bas",534
	CALL _wait
	CALL _wait
	;[535]         IF CONT.BUTTON THEN GOTO sb_done
	SRCFILE "./games/orchestra-demo/src/main.bas",535
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_SB_DONE
	;[536]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",536
	MVI var_I,R0
	DECR R0
	MVO R0,var_I
	CMPI #0,R0
	BGE T101
	;[537] 
	SRCFILE "./games/orchestra-demo/src/main.bas",537
	;[538] sb_done:
	SRCFILE "./games/orchestra-demo/src/main.bas",538
	; SB_DONE
label_SB_DONE:	;[539]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",539
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[540]     SOUND 1, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",540
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[541]     SOUND 2, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",541
	MVO R0,498
	SWAP R0
	MVO R0,502
	CLRR R0
	MVO R0,509
	;[542]     SOUND 4, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",542
	MVO R0,505
	NOP
	MVO R0,504
	;[543] 
	SRCFILE "./games/orchestra-demo/src/main.bas",543
	;[544]     PRINT AT 100, " *SNIFF*   "
	SRCFILE "./games/orchestra-demo/src/main.bas",544
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #456,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #352,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[545]     FOR i = 1 TO 50: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",545
	MVII #1,R0
	MVO R0,var_I
T103:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #50,R0
	BLE T103
	;[546] 
	SRCFILE "./games/orchestra-demo/src/main.bas",546
	;[547]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",547
	CALL label_DRAW_MENU
	;[548]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",548
	RETURN
	;[549] END
	SRCFILE "./games/orchestra-demo/src/main.bas",549
	ENDP
	;[550] 
	SRCFILE "./games/orchestra-demo/src/main.bas",550
	;[551] sneeze_tiny: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",551
	; SNEEZE_TINY
label_SNEEZE_TINY:	PROC
	BEGIN
	;[552]     ' TINY sneeze - quick high-pitched little "achoo"
	SRCFILE "./games/orchestra-demo/src/main.bas",552
	;[553]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",553
	CALL CLRSCR
	;[554]     PRINT AT 6, "TINY SNEEZE"
	SRCFILE "./games/orchestra-demo/src/main.bas",554
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #456,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[555]     PRINT AT 60, "ah-choo!"
	SRCFILE "./games/orchestra-demo/src/main.bas",555
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #520,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #552,R0
	MVO@ R0,R4
	XORI #624,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #624,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[556]     PRINT AT 220, "BTN=EXIT"
	SRCFILE "./games/orchestra-demo/src/main.bas",556
	MVII #732,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[557] 
	SRCFILE "./games/orchestra-demo/src/main.bas",557
	;[558]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",558
T104:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T105
	CALL _wait
	B T104
T105:
	;[559] 
	SRCFILE "./games/orchestra-demo/src/main.bas",559
	;[560]     ' Phase 1: Quick little "ah" - high pitched
	SRCFILE "./games/orchestra-demo/src/main.bas",560
	;[561]     PRINT AT 100, "   ah...   "
	SRCFILE "./games/orchestra-demo/src/main.bas",561
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #520,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #560,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[562]     FOR i = 0 TO 6
	SRCFILE "./games/orchestra-demo/src/main.bas",562
	CLRR R0
	MVO R0,var_I
T106:
	;[563]         freq = 600 - (i * 10)
	SRCFILE "./games/orchestra-demo/src/main.bas",563
	MVII #600,R0
	MVI var_I,R1
	MULT R1,R4,10
	SUBR R1,R0
	MVO R0,var_FREQ
	;[564]         SOUND 0, freq, 8
	SRCFILE "./games/orchestra-demo/src/main.bas",564
	MVI var_FREQ,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #8,R0
	MVO R0,507
	;[565]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",565
	CALL _wait
	;[566]         IF CONT.BUTTON THEN GOTO st_done
	SRCFILE "./games/orchestra-demo/src/main.bas",566
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_ST_DONE
	;[567]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",567
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #6,R0
	BLE T106
	;[568] 
	SRCFILE "./games/orchestra-demo/src/main.bas",568
	;[569]     ' Phase 2: Tiny pause
	SRCFILE "./games/orchestra-demo/src/main.bas",569
	;[570]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",570
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[571]     FOR i = 1 TO 3: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",571
	MVII #1,R0
	MVO R0,var_I
T108:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #3,R0
	BLE T108
	;[572] 
	SRCFILE "./games/orchestra-demo/src/main.bas",572
	;[573]     ' Phase 3: Little "choo" - quick and light
	SRCFILE "./games/orchestra-demo/src/main.bas",573
	;[574]     PRINT AT 100, "  choo!    "
	SRCFILE "./games/orchestra-demo/src/main.bas",574
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #536,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #624,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[575]     SOUND 4, 20, 3          ' Light noise
	SRCFILE "./games/orchestra-demo/src/main.bas",575
	MVII #20,R0
	MVO R0,505
	MVII #3,R0
	MVO R0,504
	;[576]     SOUND 0, 400, 10        ' High tone
	SRCFILE "./games/orchestra-demo/src/main.bas",576
	MVII #400,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #10,R0
	MVO R0,507
	;[577] 
	SRCFILE "./games/orchestra-demo/src/main.bas",577
	;[578]     ' Quick decay
	SRCFILE "./games/orchestra-demo/src/main.bas",578
	;[579]     FOR i = 10 TO 0 STEP -2
	SRCFILE "./games/orchestra-demo/src/main.bas",579
	MVO R0,var_I
T109:
	;[580]         SOUND 0, 400, i
	SRCFILE "./games/orchestra-demo/src/main.bas",580
	MVII #400,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVI var_I,R0
	MVO R0,507
	;[581]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",581
	CALL _wait
	;[582]         IF CONT.BUTTON THEN GOTO st_done
	SRCFILE "./games/orchestra-demo/src/main.bas",582
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_ST_DONE
	;[583]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",583
	MVI var_I,R0
	SUBI #2,R0
	MVO R0,var_I
	CMPI #0,R0
	BGE T109
	;[584] 
	SRCFILE "./games/orchestra-demo/src/main.bas",584
	;[585] st_done:
	SRCFILE "./games/orchestra-demo/src/main.bas",585
	; ST_DONE
label_ST_DONE:	;[586]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",586
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[587]     SOUND 4, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",587
	MVO R0,505
	NOP
	MVO R0,504
	;[588] 
	SRCFILE "./games/orchestra-demo/src/main.bas",588
	;[589]     PRINT AT 100, " *snf*     "
	SRCFILE "./games/orchestra-demo/src/main.bas",589
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #712,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #608,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO R4,_screen
	;[590]     FOR i = 1 TO 30: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",590
	MVII #1,R0
	MVO R0,var_I
T111:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #30,R0
	BLE T111
	;[591] 
	SRCFILE "./games/orchestra-demo/src/main.bas",591
	;[592]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",592
	CALL label_DRAW_MENU
	;[593]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",593
	RETURN
	;[594] END
	SRCFILE "./games/orchestra-demo/src/main.bas",594
	ENDP
	;[595] 
	SRCFILE "./games/orchestra-demo/src/main.bas",595
	;[596] sneeze_triple: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",596
	; SNEEZE_TRIPLE
label_SNEEZE_TRIPLE:	PROC
	BEGIN
	;[597]     ' TRIPLE sneeze - ah...ah...ah-CHOO!
	SRCFILE "./games/orchestra-demo/src/main.bas",597
	;[598]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",598
	CALL CLRSCR
	;[599]     PRINT AT 6, "TRIPLE SNEEZE"
	SRCFILE "./games/orchestra-demo/src/main.bas",599
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[600]     PRINT AT 60, "ah..ah..ah-CHOO!"
	SRCFILE "./games/orchestra-demo/src/main.bas",600
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #520,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #560,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #632,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #560,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #632,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #552,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[601]     PRINT AT 220, "BTN=EXIT"
	SRCFILE "./games/orchestra-demo/src/main.bas",601
	MVII #732,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[602] 
	SRCFILE "./games/orchestra-demo/src/main.bas",602
	;[603]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",603
T112:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T113
	CALL _wait
	B T112
T113:
	;[604] 
	SRCFILE "./games/orchestra-demo/src/main.bas",604
	;[605]     ' First "ah" - building
	SRCFILE "./games/orchestra-demo/src/main.bas",605
	;[606]     PRINT AT 100, "   ah...   "
	SRCFILE "./games/orchestra-demo/src/main.bas",606
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #520,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #560,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[607]     FOR i = 0 TO 8
	SRCFILE "./games/orchestra-demo/src/main.bas",607
	CLRR R0
	MVO R0,var_I
T114:
	;[608]         SOUND 0, 350 - (i * 5), 8
	SRCFILE "./games/orchestra-demo/src/main.bas",608
	MVII #350,R0
	MVI var_I,R1
	MULT R1,R4,5
	SUBR R1,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #8,R0
	MVO R0,507
	;[609]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",609
	CALL _wait
	;[610]         IF CONT.BUTTON THEN GOTO s3_done
	SRCFILE "./games/orchestra-demo/src/main.bas",610
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_S3_DONE
	;[611]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",611
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #8,R0
	BLE T114
	;[612]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",612
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[613]     FOR i = 1 TO 10: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",613
	MVII #1,R0
	MVO R0,var_I
T116:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #10,R0
	BLE T116
	;[614] 
	SRCFILE "./games/orchestra-demo/src/main.bas",614
	;[615]     ' Second "ah" - stronger
	SRCFILE "./games/orchestra-demo/src/main.bas",615
	;[616]     PRINT AT 100, "   AH...   "
	SRCFILE "./games/orchestra-demo/src/main.bas",616
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #304,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[617]     FOR i = 0 TO 10
	SRCFILE "./games/orchestra-demo/src/main.bas",617
	CLRR R0
	MVO R0,var_I
T117:
	;[618]         SOUND 0, 320 - (i * 5), 10
	SRCFILE "./games/orchestra-demo/src/main.bas",618
	MVII #320,R0
	MVI var_I,R1
	MULT R1,R4,5
	SUBR R1,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #10,R0
	MVO R0,507
	;[619]         SOUND 1, 325 - (i * 5), 6
	SRCFILE "./games/orchestra-demo/src/main.bas",619
	MVII #325,R0
	MVI var_I,R1
	MULT R1,R4,5
	SUBR R1,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVII #6,R0
	MVO R0,508
	;[620]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",620
	CALL _wait
	;[621]         IF CONT.BUTTON THEN GOTO s3_done
	SRCFILE "./games/orchestra-demo/src/main.bas",621
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_S3_DONE
	;[622]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",622
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #10,R0
	BLE T117
	;[623]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",623
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[624]     SOUND 1, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",624
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[625]     FOR i = 1 TO 8: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",625
	MVII #1,R0
	MVO R0,var_I
T119:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #8,R0
	BLE T119
	;[626] 
	SRCFILE "./games/orchestra-demo/src/main.bas",626
	;[627]     ' Third "AH" - building to climax
	SRCFILE "./games/orchestra-demo/src/main.bas",627
	;[628]     PRINT AT 100, "   AAH..   "
	SRCFILE "./games/orchestra-demo/src/main.bas",628
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #264,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #304,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[629]     FOR i = 0 TO 15
	SRCFILE "./games/orchestra-demo/src/main.bas",629
	CLRR R0
	MVO R0,var_I
T120:
	;[630]         vol = 8 + (i / 3)
	SRCFILE "./games/orchestra-demo/src/main.bas",630
	MVI var_I,R0
	MVII #65535,R4
T121:
	INCR R4
	SUBI #3,R0
	BC T121
	MOVR R4,R0
	ADDI #8,R0
	MVO R0,var_VOL
	;[631]         SOUND 0, 280 - (i * 4), vol
	SRCFILE "./games/orchestra-demo/src/main.bas",631
	MVII #280,R0
	MVI var_I,R1
	SLL R1,2
	SUBR R1,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVI var_VOL,R0
	MVO R0,507
	;[632]         SOUND 1, 285 - (i * 4), vol - 3
	SRCFILE "./games/orchestra-demo/src/main.bas",632
	MVII #285,R0
	MVI var_I,R1
	SLL R1,2
	SUBR R1,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVI var_VOL,R0
	SUBI #3,R0
	MVO R0,508
	;[633]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",633
	CALL _wait
	;[634]         IF CONT.BUTTON THEN GOTO s3_done
	SRCFILE "./games/orchestra-demo/src/main.bas",634
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_S3_DONE
	;[635]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",635
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #15,R0
	BLE T120
	;[636] 
	SRCFILE "./games/orchestra-demo/src/main.bas",636
	;[637]     ' Quick pause
	SRCFILE "./games/orchestra-demo/src/main.bas",637
	;[638]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",638
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[639]     SOUND 1, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",639
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[640]     PRINT AT 100, "           "
	SRCFILE "./games/orchestra-demo/src/main.bas",640
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[641]     FOR i = 1 TO 5: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",641
	MVII #1,R0
	MVO R0,var_I
T123:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #5,R0
	BLE T123
	;[642] 
	SRCFILE "./games/orchestra-demo/src/main.bas",642
	;[643]     ' Final big CHOO!
	SRCFILE "./games/orchestra-demo/src/main.bas",643
	;[644]     PRINT AT 100, "  CHOO!!!  "
	SRCFILE "./games/orchestra-demo/src/main.bas",644
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[645]     SOUND 4, 10, 7
	SRCFILE "./games/orchestra-demo/src/main.bas",645
	MVII #10,R0
	MVO R0,505
	MVII #7,R0
	MVO R0,504
	;[646]     SOUND 0, 100, 15
	SRCFILE "./games/orchestra-demo/src/main.bas",646
	MVII #100,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #15,R0
	MVO R0,507
	;[647]     SOUND 1, 160, 13
	SRCFILE "./games/orchestra-demo/src/main.bas",647
	MVII #160,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVII #13,R0
	MVO R0,508
	;[648]     SOUND 2, 80, 11
	SRCFILE "./games/orchestra-demo/src/main.bas",648
	MVII #80,R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	MVII #11,R0
	MVO R0,509
	;[649] 
	SRCFILE "./games/orchestra-demo/src/main.bas",649
	;[650]     ' Decay
	SRCFILE "./games/orchestra-demo/src/main.bas",650
	;[651]     FOR i = 15 TO 0 STEP -1
	SRCFILE "./games/orchestra-demo/src/main.bas",651
	MVII #15,R0
	MVO R0,var_I
T124:
	;[652]         SOUND 0, 100, i
	SRCFILE "./games/orchestra-demo/src/main.bas",652
	MVII #100,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVI var_I,R0
	MVO R0,507
	;[653]         SOUND 1, 160, (i * 3) / 4
	SRCFILE "./games/orchestra-demo/src/main.bas",653
	MVII #160,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVI var_I,R0
	MULT R0,R4,3
	SLR R0,2
	MVO R0,508
	;[654]         SOUND 2, 80, i / 2
	SRCFILE "./games/orchestra-demo/src/main.bas",654
	MVII #80,R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	MVI var_I,R0
	SLR R0,1
	MVO R0,509
	;[655]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",655
	CALL _wait
	;[656]         IF CONT.BUTTON THEN GOTO s3_done
	SRCFILE "./games/orchestra-demo/src/main.bas",656
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_S3_DONE
	;[657]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",657
	MVI var_I,R0
	DECR R0
	MVO R0,var_I
	CMPI #0,R0
	BGE T124
	;[658] 
	SRCFILE "./games/orchestra-demo/src/main.bas",658
	;[659] s3_done:
	SRCFILE "./games/orchestra-demo/src/main.bas",659
	; S3_DONE
label_S3_DONE:	;[660]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",660
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[661]     SOUND 1, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",661
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[662]     SOUND 2, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",662
	MVO R0,498
	SWAP R0
	MVO R0,502
	CLRR R0
	MVO R0,509
	;[663]     SOUND 4, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",663
	MVO R0,505
	NOP
	MVO R0,504
	;[664] 
	SRCFILE "./games/orchestra-demo/src/main.bas",664
	;[665]     PRINT AT 100, "*sniff snf*"
	SRCFILE "./games/orchestra-demo/src/main.bas",665
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #80,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #712,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #560,R0
	MVO@ R0,R4
	XORI #664,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #608,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[666]     FOR i = 1 TO 50: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",666
	MVII #1,R0
	MVO R0,var_I
T126:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #50,R0
	BLE T126
	;[667] 
	SRCFILE "./games/orchestra-demo/src/main.bas",667
	;[668]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",668
	CALL label_DRAW_MENU
	;[669]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",669
	RETURN
	;[670] END
	SRCFILE "./games/orchestra-demo/src/main.bas",670
	ENDP
	;[671] 
	SRCFILE "./games/orchestra-demo/src/main.bas",671
	;[672] sneeze_stifled: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",672
	; SNEEZE_STIFLED
label_SNEEZE_STIFLED:	PROC
	BEGIN
	;[673]     ' STIFLED sneeze - suppressed, muffled
	SRCFILE "./games/orchestra-demo/src/main.bas",673
	;[674]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",674
	CALL CLRSCR
	;[675]     PRINT AT 6, "STIFLED SNEEZE"
	SRCFILE "./games/orchestra-demo/src/main.bas",675
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #408,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[676]     PRINT AT 60, "(trying not to sneeze)"
	SRCFILE "./games/orchestra-demo/src/main.bas",676
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #64,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #736,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #568,R0
	MVO@ R0,R4
	XORI #624,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #672,R0
	MVO@ R0,R4
	XORI #672,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #632,R0
	MVO@ R0,R4
	XORI #664,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #608,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[677]     PRINT AT 220, "BTN=EXIT"
	SRCFILE "./games/orchestra-demo/src/main.bas",677
	MVII #732,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[678] 
	SRCFILE "./games/orchestra-demo/src/main.bas",678
	;[679]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",679
T127:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T128
	CALL _wait
	B T127
T128:
	;[680] 
	SRCFILE "./games/orchestra-demo/src/main.bas",680
	;[681]     ' Phase 1: Struggling to hold it in
	SRCFILE "./games/orchestra-demo/src/main.bas",681
	;[682]     PRINT AT 100, " nnngggh.. "
	SRCFILE "./games/orchestra-demo/src/main.bas",682
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	XORI #624,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #560,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[683]     FOR i = 0 TO 25
	SRCFILE "./games/orchestra-demo/src/main.bas",683
	CLRR R0
	MVO R0,var_I
T129:
	;[684]         freq = 200 + (RANDOM(30))
	SRCFILE "./games/orchestra-demo/src/main.bas",684
	MVII #30,R1
	CALL _next_random
	CALL qs_mpy8
	SWAP R0
	ANDI #255,R0
	ADDI #200,R0
	MVO R0,var_FREQ
	;[685]         vol = 5 + (i / 6)
	SRCFILE "./games/orchestra-demo/src/main.bas",685
	MVI var_I,R0
	MVII #65535,R4
T130:
	INCR R4
	SUBI #6,R0
	BC T130
	MOVR R4,R0
	ADDI #5,R0
	MVO R0,var_VOL
	;[686]         IF vol > 10 THEN vol = 10
	SRCFILE "./games/orchestra-demo/src/main.bas",686
	MVI var_VOL,R0
	CMPI #10,R0
	BLE T131
	MVII #10,R0
	MVO R0,var_VOL
T131:
	;[687]         SOUND 0, freq, vol
	SRCFILE "./games/orchestra-demo/src/main.bas",687
	MVI var_FREQ,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVI var_VOL,R0
	MVO R0,507
	;[688]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",688
	CALL _wait
	;[689]         IF CONT.BUTTON THEN GOTO ss_done
	SRCFILE "./games/orchestra-demo/src/main.bas",689
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_SS_DONE
	;[690]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",690
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #25,R0
	BLE T129
	;[691] 
	SRCFILE "./games/orchestra-demo/src/main.bas",691
	;[692]     ' Phase 2: The suppressed explosion
	SRCFILE "./games/orchestra-demo/src/main.bas",692
	;[693]     PRINT AT 100, "  -mmpf!-  "
	SRCFILE "./games/orchestra-demo/src/main.bas",693
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #512,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #568,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[694]     SOUND 4, 25, 4          ' Muffled noise
	SRCFILE "./games/orchestra-demo/src/main.bas",694
	MVII #25,R0
	MVO R0,505
	MVII #4,R0
	MVO R0,504
	;[695]     SOUND 0, 250, 8         ' Mid tone, not too loud
	SRCFILE "./games/orchestra-demo/src/main.bas",695
	MVII #250,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #8,R0
	MVO R0,507
	;[696]     SOUND 1, 180, 6
	SRCFILE "./games/orchestra-demo/src/main.bas",696
	MVII #180,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVII #6,R0
	MVO R0,508
	;[697] 
	SRCFILE "./games/orchestra-demo/src/main.bas",697
	;[698]     ' Quick muffled decay
	SRCFILE "./games/orchestra-demo/src/main.bas",698
	;[699]     FOR i = 8 TO 0 STEP -1
	SRCFILE "./games/orchestra-demo/src/main.bas",699
	MVII #8,R0
	MVO R0,var_I
T133:
	;[700]         SOUND 0, 250, i
	SRCFILE "./games/orchestra-demo/src/main.bas",700
	MVII #250,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVI var_I,R0
	MVO R0,507
	;[701]         SOUND 1, 180, i - 2
	SRCFILE "./games/orchestra-demo/src/main.bas",701
	MVII #180,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVI var_I,R0
	SUBI #2,R0
	MVO R0,508
	;[702]         IF i > 5 THEN SOUND 4, 25, 3
	SRCFILE "./games/orchestra-demo/src/main.bas",702
	MVI var_I,R0
	CMPI #5,R0
	BLE T134
	MVII #25,R0
	MVO R0,505
	MVII #3,R0
	MVO R0,504
T134:
	;[703]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",703
	CALL _wait
	;[704]         IF CONT.BUTTON THEN GOTO ss_done
	SRCFILE "./games/orchestra-demo/src/main.bas",704
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_SS_DONE
	;[705]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",705
	MVI var_I,R0
	DECR R0
	MVO R0,var_I
	CMPI #0,R0
	BGE T133
	;[706] 
	SRCFILE "./games/orchestra-demo/src/main.bas",706
	;[707] ss_done:
	SRCFILE "./games/orchestra-demo/src/main.bas",707
	; SS_DONE
label_SS_DONE:	;[708]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",708
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[709]     SOUND 1, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",709
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[710]     SOUND 4, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",710
	MVO R0,505
	NOP
	MVO R0,504
	;[711] 
	SRCFILE "./games/orchestra-demo/src/main.bas",711
	;[712]     PRINT AT 100, " *ow...*   "
	SRCFILE "./games/orchestra-demo/src/main.bas",712
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #552,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #712,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #32,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[713]     FOR i = 1 TO 40: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",713
	MVII #1,R0
	MVO R0,var_I
T136:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #40,R0
	BLE T136
	;[714] 
	SRCFILE "./games/orchestra-demo/src/main.bas",714
	;[715]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",715
	CALL label_DRAW_MENU
	;[716]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",716
	RETURN
	;[717] END
	SRCFILE "./games/orchestra-demo/src/main.bas",717
	ENDP
	;[718] 
	SRCFILE "./games/orchestra-demo/src/main.bas",718
	;[719] sneeze_cartoon: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",719
	; SNEEZE_CARTOON
label_SNEEZE_CARTOON:	PROC
	BEGIN
	;[720]     ' CARTOON sneeze - over-the-top slide whistle style
	SRCFILE "./games/orchestra-demo/src/main.bas",720
	;[721]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",721
	CALL CLRSCR
	;[722]     PRINT AT 6, "CARTOON SNEEZE"
	SRCFILE "./games/orchestra-demo/src/main.bas",722
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[723]     PRINT AT 60, "WAAAAH-CHOOEY!"
	SRCFILE "./games/orchestra-demo/src/main.bas",723
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #440,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[724]     PRINT AT 220, "BTN=EXIT"
	SRCFILE "./games/orchestra-demo/src/main.bas",724
	MVII #732,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[725] 
	SRCFILE "./games/orchestra-demo/src/main.bas",725
	;[726]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",726
T137:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T138
	CALL _wait
	B T137
T138:
	;[727] 
	SRCFILE "./games/orchestra-demo/src/main.bas",727
	;[728]     ' Phase 1: Cartoon wind-up with rising pitch
	SRCFILE "./games/orchestra-demo/src/main.bas",728
	;[729]     PRINT AT 100, " WAAAAAHH! "
	SRCFILE "./games/orchestra-demo/src/main.bas",729
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	XORI #440,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #328,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[730]     FOR i = 0 TO 30
	SRCFILE "./games/orchestra-demo/src/main.bas",730
	CLRR R0
	MVO R0,var_I
T139:
	;[731]         freq = 800 - (i * 15)  ' Slide down
	SRCFILE "./games/orchestra-demo/src/main.bas",731
	MVII #800,R0
	MVI var_I,R1
	MULT R1,R4,15
	SUBR R1,R0
	MVO R0,var_FREQ
	;[732]         SOUND 0, freq, 12
	SRCFILE "./games/orchestra-demo/src/main.bas",732
	MVI var_FREQ,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #12,R0
	MVO R0,507
	;[733]         SOUND 1, freq / 2, 8   ' Harmony
	SRCFILE "./games/orchestra-demo/src/main.bas",733
	MVI var_FREQ,R0
	SLR R0,1
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVII #8,R0
	MVO R0,508
	;[734]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",734
	CALL _wait
	;[735]         IF CONT.BUTTON THEN GOTO sc_done
	SRCFILE "./games/orchestra-demo/src/main.bas",735
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_SC_DONE
	;[736]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",736
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #30,R0
	BLE T139
	;[737] 
	SRCFILE "./games/orchestra-demo/src/main.bas",737
	;[738]     ' Quick slide up before explosion
	SRCFILE "./games/orchestra-demo/src/main.bas",738
	;[739]     FOR i = 0 TO 10
	SRCFILE "./games/orchestra-demo/src/main.bas",739
	CLRR R0
	MVO R0,var_I
T141:
	;[740]         freq = 350 + (i * 30)  ' Slide up!
	SRCFILE "./games/orchestra-demo/src/main.bas",740
	MVI var_I,R0
	MULT R0,R4,30
	ADDI #350,R0
	MVO R0,var_FREQ
	;[741]         SOUND 0, freq, 14
	SRCFILE "./games/orchestra-demo/src/main.bas",741
	MVI var_FREQ,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #14,R0
	MVO R0,507
	;[742]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",742
	CALL _wait
	;[743]         IF CONT.BUTTON THEN GOTO sc_done
	SRCFILE "./games/orchestra-demo/src/main.bas",743
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_SC_DONE
	;[744]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",744
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #10,R0
	BLE T141
	;[745] 
	SRCFILE "./games/orchestra-demo/src/main.bas",745
	;[746]     ' Phase 2: Comical explosion with warble
	SRCFILE "./games/orchestra-demo/src/main.bas",746
	;[747]     PRINT AT 100, " CHOOEY!!! "
	SRCFILE "./games/orchestra-demo/src/main.bas",747
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	XORI #280,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[748]     FOR i = 0 TO 20
	SRCFILE "./games/orchestra-demo/src/main.bas",748
	CLRR R0
	MVO R0,var_I
T143:
	;[749]         f = 100 + ((i AND 3) * 50)  ' Warbling
	SRCFILE "./games/orchestra-demo/src/main.bas",749
	MVI var_I,R0
	ANDI #3,R0
	MULT R0,R4,50
	ADDI #100,R0
	MVO R0,var_F
	;[750]         SOUND 4, 8, 5
	SRCFILE "./games/orchestra-demo/src/main.bas",750
	MVII #8,R0
	MVO R0,505
	MVII #5,R0
	MVO R0,504
	;[751]         SOUND 0, f, 15 - (i / 2)
	SRCFILE "./games/orchestra-demo/src/main.bas",751
	MVI var_F,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #15,R0
	MVI var_I,R1
	SLR R1,1
	SUBR R1,R0
	MVO R0,507
	;[752]         SOUND 1, f + 100, 12 - (i / 2)
	SRCFILE "./games/orchestra-demo/src/main.bas",752
	MVI var_F,R0
	ADDI #100,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVII #12,R0
	MVI var_I,R1
	SLR R1,1
	SUBR R1,R0
	MVO R0,508
	;[753]         SOUND 2, 50, 10 - (i / 3)
	SRCFILE "./games/orchestra-demo/src/main.bas",753
	MVII #50,R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	MVII #10,R0
	MVI var_I,R1
	MVII #65535,R4
T144:
	INCR R4
	SUBI #3,R1
	BC T144
	MOVR R4,R1
	SUBR R1,R0
	MVO R0,509
	;[754]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",754
	CALL _wait
	;[755]         IF CONT.BUTTON THEN GOTO sc_done
	SRCFILE "./games/orchestra-demo/src/main.bas",755
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_SC_DONE
	;[756]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",756
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #20,R0
	BLE T143
	;[757] 
	SRCFILE "./games/orchestra-demo/src/main.bas",757
	;[758]     ' Cartoon "boing" aftermath
	SRCFILE "./games/orchestra-demo/src/main.bas",758
	;[759]     FOR i = 0 TO 10
	SRCFILE "./games/orchestra-demo/src/main.bas",759
	CLRR R0
	MVO R0,var_I
T146:
	;[760]         freq = 300 + (i * 40)  ' Rising boing
	SRCFILE "./games/orchestra-demo/src/main.bas",760
	MVI var_I,R0
	MULT R0,R4,40
	ADDI #300,R0
	MVO R0,var_FREQ
	;[761]         SOUND 0, freq, 8 - (i / 2)
	SRCFILE "./games/orchestra-demo/src/main.bas",761
	MVI var_FREQ,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #8,R0
	MVI var_I,R1
	SLR R1,1
	SUBR R1,R0
	MVO R0,507
	;[762]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",762
	CALL _wait
	;[763]         IF CONT.BUTTON THEN GOTO sc_done
	SRCFILE "./games/orchestra-demo/src/main.bas",763
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE label_SC_DONE
	;[764]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",764
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #10,R0
	BLE T146
	;[765] 
	SRCFILE "./games/orchestra-demo/src/main.bas",765
	;[766] sc_done:
	SRCFILE "./games/orchestra-demo/src/main.bas",766
	; SC_DONE
label_SC_DONE:	;[767]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",767
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[768]     SOUND 1, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",768
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[769]     SOUND 2, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",769
	MVO R0,498
	SWAP R0
	MVO R0,502
	CLRR R0
	MVO R0,509
	;[770]     SOUND 4, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",770
	MVO R0,505
	NOP
	MVO R0,504
	;[771] 
	SRCFILE "./games/orchestra-demo/src/main.bas",771
	;[772]     PRINT AT 100, " ~splat~   "
	SRCFILE "./games/orchestra-demo/src/main.bas",772
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	XORI #752,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #752,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[773]     FOR i = 1 TO 50: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",773
	MVII #1,R0
	MVO R0,var_I
T148:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #50,R0
	BLE T148
	;[774] 
	SRCFILE "./games/orchestra-demo/src/main.bas",774
	;[775]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",775
	CALL label_DRAW_MENU
	;[776]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",776
	RETURN
	;[777] END
	SRCFILE "./games/orchestra-demo/src/main.bas",777
	ENDP
	;[778] 
	SRCFILE "./games/orchestra-demo/src/main.bas",778
	;[779] ' --- Special Procedures ---
	SRCFILE "./games/orchestra-demo/src/main.bas",779
	;[780] say_bravo: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",780
	; SAY_BRAVO
label_SAY_BRAVO:	PROC
	BEGIN
	;[781]     vid = 10: GOSUB voice_viz
	SRCFILE "./games/orchestra-demo/src/main.bas",781
	MVII #10,R0
	MVO R0,var_VID
	CALL label_VOICE_VIZ
	;[782]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",782
	RETURN
	;[783] END
	SRCFILE "./games/orchestra-demo/src/main.bas",783
	ENDP
	;[784] 
	SRCFILE "./games/orchestra-demo/src/main.bas",784
	;[785] say_encore: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",785
	; SAY_ENCORE
label_SAY_ENCORE:	PROC
	BEGIN
	;[786]     vid = 11: GOSUB voice_viz
	SRCFILE "./games/orchestra-demo/src/main.bas",786
	MVII #11,R0
	MVO R0,var_VID
	CALL label_VOICE_VIZ
	;[787]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",787
	RETURN
	;[788] END
	SRCFILE "./games/orchestra-demo/src/main.bas",788
	ENDP
	;[789] 
	SRCFILE "./games/orchestra-demo/src/main.bas",789
	;[790] count_words: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",790
	; COUNT_WORDS
label_COUNT_WORDS:	PROC
	BEGIN
	;[791]     ' Count 1-5 using built-in VOICE NUMBER with visualizer
	SRCFILE "./games/orchestra-demo/src/main.bas",791
	;[792]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",792
	CALL CLRSCR
	;[793]     PRINT AT 6, "VOICE VISUALIZER"
	SRCFILE "./games/orchestra-demo/src/main.bas",793
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #432,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #432,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #160,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[794]     PRINT AT 40, "PHRASE:"
	SRCFILE "./games/orchestra-demo/src/main.bas",794
	MVII #552,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #384,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #144,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[795]     PRINT AT 60, "COUNT WORDS 1-5"
	SRCFILE "./games/orchestra-demo/src/main.bas",795
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #440,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[796]     PRINT AT 80, "(built-in numbers)"
	SRCFILE "./games/orchestra-demo/src/main.bas",796
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #64,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #592,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #712,R0
	MVO@ R0,R4
	XORI #544,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #624,R0
	MVO@ R0,R4
	XORI #624,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #720,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[797]     PRINT AT 120, "INTELLIVOICE OUTPUT:"
	SRCFILE "./games/orchestra-demo/src/main.bas",797
	MVII #632,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #328,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #376,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #32,R0
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[798]     PRINT AT 220, "BTN=EXIT"
	SRCFILE "./games/orchestra-demo/src/main.bas",798
	MVII #732,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[799] 
	SRCFILE "./games/orchestra-demo/src/main.bas",799
	;[800]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",800
T149:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T150
	CALL _wait
	B T149
T150:
	;[801] 
	SRCFILE "./games/orchestra-demo/src/main.bas",801
	;[802]     tick = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",802
	CLRR R0
	MVO R0,var_TICK
	;[803]     FOR i = 1 TO 5
	SRCFILE "./games/orchestra-demo/src/main.bas",803
	MVII #1,R0
	MVO R0,var_I
T151:
	;[804]         VOICE NUMBER i
	SRCFILE "./games/orchestra-demo/src/main.bas",804
	MVI var_I,R0
	CALL IV_SAYNUM16
	;[805]         FOR j = 1 TO 30
	SRCFILE "./games/orchestra-demo/src/main.bas",805
	MVII #1,R0
	MVO R0,var_J
T152:
	;[806]             WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",806
	CALL _wait
	;[807]             IF CONT.BUTTON THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",807
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T153
	;[808]                 VOICE INIT
	SRCFILE "./games/orchestra-demo/src/main.bas",808
	CALL IV_HUSH
	;[809]                 GOTO cw_done
	SRCFILE "./games/orchestra-demo/src/main.bas",809
	B label_CW_DONE
	;[810]             END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",810
T153:
	;[811]             tick = tick + 1
	SRCFILE "./games/orchestra-demo/src/main.bas",811
	MVI var_TICK,R0
	INCR R0
	MVO R0,var_TICK
	;[812]             r = (tick + RAND) AND 7
	SRCFILE "./games/orchestra-demo/src/main.bas",812
	MVI _rand,R0
	ADD var_TICK,R0
	ANDI #7,R0
	MVO R0,var_R
	;[813]             IF r < 4 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",813
	MVI var_R,R0
	CMPI #4,R0
	BGE T154
	;[814]                 PRINT AT 142, "==#=="
	SRCFILE "./games/orchestra-demo/src/main.bas",814
	MVII #654,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #232,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #240,R0
	MVO@ R0,R4
	XORI #240,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[815]             ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",815
	B T155
T154:
	;[816]                 PRINT AT 142, "@@@@@"
	SRCFILE "./games/orchestra-demo/src/main.bas",816
	MVII #654,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #256,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO R4,_screen
	;[817]             END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",817
T155:
	;[818]             IF (tick AND 4) THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",818
	MVI var_TICK,R0
	ANDI #4,R0
	BEQ T156
	;[819]                 PRINT AT 180, "** SPEAKING **"
	SRCFILE "./games/orchestra-demo/src/main.bas",819
	MVII #692,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #80,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #32,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #312,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[820]             ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",820
	B T157
T156:
	;[821]                 PRINT AT 180, "              "
	SRCFILE "./games/orchestra-demo/src/main.bas",821
	MVII #692,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[822]             END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",822
T157:
	;[823]         NEXT j
	SRCFILE "./games/orchestra-demo/src/main.bas",823
	MVI var_J,R0
	INCR R0
	MVO R0,var_J
	CMPI #30,R0
	BLE T152
	;[824]     NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",824
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #5,R0
	BLE T151
	;[825] cw_done:
	SRCFILE "./games/orchestra-demo/src/main.bas",825
	; CW_DONE
label_CW_DONE:	;[826]     PRINT AT 142, "          "
	SRCFILE "./games/orchestra-demo/src/main.bas",826
	MVII #654,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[827]     PRINT AT 180, "--- DONE ---  "
	SRCFILE "./games/orchestra-demo/src/main.bas",827
	MVII #692,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #104,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[828]     FOR j = 1 TO 60: WAIT: NEXT j
	SRCFILE "./games/orchestra-demo/src/main.bas",828
	MVII #1,R0
	MVO R0,var_J
T158:
	CALL _wait
	MVI var_J,R0
	INCR R0
	MVO R0,var_J
	CMPI #60,R0
	BLE T158
	;[829]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",829
	CALL label_DRAW_MENU
	;[830]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",830
	RETURN
	;[831] END
	SRCFILE "./games/orchestra-demo/src/main.bas",831
	ENDP
	;[832] 
	SRCFILE "./games/orchestra-demo/src/main.bas",832
	;[833] pencil_drop: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",833
	; PENCIL_DROP
label_PENCIL_DROP:	PROC
	BEGIN
	;[834]     vid = 12: GOSUB voice_viz
	SRCFILE "./games/orchestra-demo/src/main.bas",834
	MVII #12,R0
	MVO R0,var_VID
	CALL label_VOICE_VIZ
	;[835]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",835
	RETURN
	;[836] END
	SRCFILE "./games/orchestra-demo/src/main.bas",836
	ENDP
	;[837] 
	SRCFILE "./games/orchestra-demo/src/main.bas",837
	;[838] ' --- Music Playback Procedures ---
	SRCFILE "./games/orchestra-demo/src/main.bas",838
	;[839] play_greensleeves: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",839
	; PLAY_GREENSLEEVES
label_PLAY_GREENSLEEVES:	PROC
	BEGIN
	;[840]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",840
	CALL CLRSCR
	;[841]     PRINT AT 6, "NOW PLAYING"
	SRCFILE "./games/orchestra-demo/src/main.bas",841
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #368,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #440,R0
	MVO@ R0,R4
	XORI #384,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[842]     PRINT AT 60, "GREENSLEEVES"
	SRCFILE "./games/orchestra-demo/src/main.bas",842
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #312,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[843]     PRINT AT 80, "(Traditional)"
	SRCFILE "./games/orchestra-demo/src/main.bas",843
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #64,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #480,R0
	MVO@ R0,R4
	XORI #816,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #40,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #552,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[844]     PRINT AT 120, "Music plays in"
	SRCFILE "./games/orchestra-demo/src/main.bas",844
	MVII #632,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #360,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #960,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #536,R0
	MVO@ R0,R4
	XORI #640,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #664,R0
	MVO@ R0,R4
	XORI #584,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[845]     PRINT AT 140, "background..."
	SRCFILE "./games/orchestra-demo/src/main.bas",845
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #528,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #592,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[846]     PRINT AT 200, "BTN=BACK"
	SRCFILE "./games/orchestra-demo/src/main.bas",846
	MVII #712,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[847] 
	SRCFILE "./games/orchestra-demo/src/main.bas",847
	;[848]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",848
T159:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T160
	CALL _wait
	B T159
T160:
	;[849] 
	SRCFILE "./games/orchestra-demo/src/main.bas",849
	;[850]     PLAY FULL
	SRCFILE "./games/orchestra-demo/src/main.bas",850
	MVII #5,R3
	MVO R3,_music_mode
	;[851]     PLAY Greensleeves
	SRCFILE "./games/orchestra-demo/src/main.bas",851
	MVII #label_GREENSLEEVES,R0
	CALL _play_music
	;[852] 
	SRCFILE "./games/orchestra-demo/src/main.bas",852
	;[853]     ' Wait for button to return to menu
	SRCFILE "./games/orchestra-demo/src/main.bas",853
	;[854]     WHILE CONT.BUTTON = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",854
T161:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE T162
	;[855]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",855
	CALL _wait
	;[856]         ' Show playing indicator
	SRCFILE "./games/orchestra-demo/src/main.bas",856
	;[857]         IF (FRAME AND 15) < 8 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",857
	MVI _frame,R0
	ANDI #15,R0
	CMPI #8,R0
	BGE T163
	;[858]             PRINT AT 160, "   [PLAYING]   "
	SRCFILE "./games/orchestra-demo/src/main.bas",858
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #472,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[859]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",859
	B T164
T163:
	;[860]             PRINT AT 160, "               "
	SRCFILE "./games/orchestra-demo/src/main.bas",860
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[861]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",861
T164:
	;[862]     WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",862
	B T161
T162:
	;[863] 
	SRCFILE "./games/orchestra-demo/src/main.bas",863
	;[864]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",864
	CALL label_DRAW_MENU
	;[865]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",865
	RETURN
	;[866] END
	SRCFILE "./games/orchestra-demo/src/main.bas",866
	ENDP
	;[867] 
	SRCFILE "./games/orchestra-demo/src/main.bas",867
	;[868] play_canon: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",868
	; PLAY_CANON
label_PLAY_CANON:	PROC
	BEGIN
	;[869]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",869
	CALL CLRSCR
	;[870]     PRINT AT 6, "NOW PLAYING"
	SRCFILE "./games/orchestra-demo/src/main.bas",870
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #368,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #440,R0
	MVO@ R0,R4
	XORI #384,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[871]     PRINT AT 60, "CANON IN D"
	SRCFILE "./games/orchestra-demo/src/main.bas",871
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	XORI #328,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #368,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[872]     PRINT AT 80, "(Pachelbel)"
	SRCFILE "./games/orchestra-demo/src/main.bas",872
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #64,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #904,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #112,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #552,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[873]     PRINT AT 120, "Music plays in"
	SRCFILE "./games/orchestra-demo/src/main.bas",873
	MVII #632,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #360,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #960,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #536,R0
	MVO@ R0,R4
	XORI #640,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #664,R0
	MVO@ R0,R4
	XORI #584,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[874]     PRINT AT 140, "background..."
	SRCFILE "./games/orchestra-demo/src/main.bas",874
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #528,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #592,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[875]     PRINT AT 200, "BTN=BACK"
	SRCFILE "./games/orchestra-demo/src/main.bas",875
	MVII #712,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[876] 
	SRCFILE "./games/orchestra-demo/src/main.bas",876
	;[877]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",877
T165:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T166
	CALL _wait
	B T165
T166:
	;[878] 
	SRCFILE "./games/orchestra-demo/src/main.bas",878
	;[879]     PLAY FULL
	SRCFILE "./games/orchestra-demo/src/main.bas",879
	MVII #5,R3
	MVO R3,_music_mode
	;[880]     PLAY Canon_in_D
	SRCFILE "./games/orchestra-demo/src/main.bas",880
	MVII #label_CANON_IN_D,R0
	CALL _play_music
	;[881] 
	SRCFILE "./games/orchestra-demo/src/main.bas",881
	;[882]     ' Wait for button to return to menu
	SRCFILE "./games/orchestra-demo/src/main.bas",882
	;[883]     WHILE CONT.BUTTON = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",883
T167:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE T168
	;[884]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",884
	CALL _wait
	;[885]         IF (FRAME AND 15) < 8 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",885
	MVI _frame,R0
	ANDI #15,R0
	CMPI #8,R0
	BGE T169
	;[886]             PRINT AT 160, "   [PLAYING]   "
	SRCFILE "./games/orchestra-demo/src/main.bas",886
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #472,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[887]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",887
	B T170
T169:
	;[888]             PRINT AT 160, "               "
	SRCFILE "./games/orchestra-demo/src/main.bas",888
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[889]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",889
T170:
	;[890]     WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",890
	B T167
T168:
	;[891] 
	SRCFILE "./games/orchestra-demo/src/main.bas",891
	;[892]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",892
	CALL label_DRAW_MENU
	;[893]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",893
	RETURN
	;[894] END
	SRCFILE "./games/orchestra-demo/src/main.bas",894
	ENDP
	;[895] 
	SRCFILE "./games/orchestra-demo/src/main.bas",895
	;[896] play_tuning: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",896
	; PLAY_TUNING
label_PLAY_TUNING:	PROC
	BEGIN
	;[897]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",897
	CALL CLRSCR
	;[898]     PRINT AT 6, "NOW PLAYING"
	SRCFILE "./games/orchestra-demo/src/main.bas",898
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #368,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #440,R0
	MVO@ R0,R4
	XORI #384,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[899]     PRINT AT 60, "ORCH TUNING"
	SRCFILE "./games/orchestra-demo/src/main.bas",899
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #376,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #320,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[900]     PRINT AT 80, "(A440 + chords)"
	SRCFILE "./games/orchestra-demo/src/main.bas",900
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #64,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #328,R0
	MVO@ R0,R4
	XORI #424,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #32,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #536,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #184,R0
	MVO@ R0,R4
	XORI #720,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[901]     PRINT AT 120, "Music plays in"
	SRCFILE "./games/orchestra-demo/src/main.bas",901
	MVII #632,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #360,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #960,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #536,R0
	MVO@ R0,R4
	XORI #640,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #664,R0
	MVO@ R0,R4
	XORI #584,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[902]     PRINT AT 140, "background..."
	SRCFILE "./games/orchestra-demo/src/main.bas",902
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #528,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #592,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[903]     PRINT AT 200, "BTN=BACK"
	SRCFILE "./games/orchestra-demo/src/main.bas",903
	MVII #712,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[904] 
	SRCFILE "./games/orchestra-demo/src/main.bas",904
	;[905]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",905
T171:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T172
	CALL _wait
	B T171
T172:
	;[906] 
	SRCFILE "./games/orchestra-demo/src/main.bas",906
	;[907]     PLAY FULL
	SRCFILE "./games/orchestra-demo/src/main.bas",907
	MVII #5,R3
	MVO R3,_music_mode
	;[908]     PLAY intellivision_orchestra_tuning
	SRCFILE "./games/orchestra-demo/src/main.bas",908
	MVII #label_INTELLIVISION_ORCHESTRA_TUNING,R0
	CALL _play_music
	;[909] 
	SRCFILE "./games/orchestra-demo/src/main.bas",909
	;[910]     WHILE CONT.BUTTON = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",910
T173:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE T174
	;[911]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",911
	CALL _wait
	;[912]         IF (FRAME AND 15) < 8 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",912
	MVI _frame,R0
	ANDI #15,R0
	CMPI #8,R0
	BGE T175
	;[913]             PRINT AT 160, "   [PLAYING]   "
	SRCFILE "./games/orchestra-demo/src/main.bas",913
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #472,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[914]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",914
	B T176
T175:
	;[915]             PRINT AT 160, "               "
	SRCFILE "./games/orchestra-demo/src/main.bas",915
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[916]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",916
T176:
	;[917]     WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",917
	B T173
T174:
	;[918] 
	SRCFILE "./games/orchestra-demo/src/main.bas",918
	;[919]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",919
	CALL label_DRAW_MENU
	;[920]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",920
	RETURN
	;[921] END
	SRCFILE "./games/orchestra-demo/src/main.bas",921
	ENDP
	;[922] 
	SRCFILE "./games/orchestra-demo/src/main.bas",922
	;[923] stop_music: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",923
	; STOP_MUSIC
label_STOP_MUSIC:	PROC
	BEGIN
	;[924]     PLAY OFF
	SRCFILE "./games/orchestra-demo/src/main.bas",924
	CLRR R0
	CALL _play_music
	;[925]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",925
	CALL label_DRAW_MENU
	;[926]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",926
	RETURN
	;[927] END
	SRCFILE "./games/orchestra-demo/src/main.bas",927
	ENDP
	;[928] 
	SRCFILE "./games/orchestra-demo/src/main.bas",928
	;[929] ' --- Nutcracker March (IntyBASIC MUSIC) ---
	SRCFILE "./games/orchestra-demo/src/main.bas",929
	;[930] play_nutcracker: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",930
	; PLAY_NUTCRACKER
label_PLAY_NUTCRACKER:	PROC
	BEGIN
	;[931]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",931
	CALL CLRSCR
	;[932]     PRINT AT 6, "RAW SOUND TEST"
	SRCFILE "./games/orchestra-demo/src/main.bas",932
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #400,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #440,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[933]     PRINT AT 40, "Testing PSG"
	SRCFILE "./games/orchestra-demo/src/main.bas",933
	MVII #552,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #904,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #568,R0
	MVO@ R0,R4
	XORI #384,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #160,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[934]     PRINT AT 60, "channels 0,1,2"
	SRCFILE "./games/orchestra-demo/src/main.bas",934
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #536,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	XORI #664,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #240,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[935]     PRINT AT 100, "v5 - PLAY OFF"
	SRCFILE "./games/orchestra-demo/src/main.bas",935
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #688,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #536,R0
	MVO@ R0,R4
	XORI #168,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #384,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #456,R0
	MVO@ R0,R4
	XORI #376,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[936]     PRINT AT 200, "BTN=BACK"
	SRCFILE "./games/orchestra-demo/src/main.bas",936
	MVII #712,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #504,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[937] 
	SRCFILE "./games/orchestra-demo/src/main.bas",937
	;[938]     WHILE CONT.BUTTON: WAIT: WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",938
T177:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T178
	CALL _wait
	B T177
T178:
	;[939] 
	SRCFILE "./games/orchestra-demo/src/main.bas",939
	;[940]     ' === RAW SOUND TEST - bypasses MUSIC system ===
	SRCFILE "./games/orchestra-demo/src/main.bas",940
	;[941]     ' First disable the music system completely
	SRCFILE "./games/orchestra-demo/src/main.bas",941
	;[942]     PLAY OFF
	SRCFILE "./games/orchestra-demo/src/main.bas",942
	CLRR R0
	CALL _play_music
	;[943]     FOR i = 0 TO 10: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",943
	CLRR R0
	MVO R0,var_I
T179:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #10,R0
	BLE T179
	;[944] 
	SRCFILE "./games/orchestra-demo/src/main.bas",944
	;[945]     ' Test channel 0 (A4 = 440Hz, period ~254)
	SRCFILE "./games/orchestra-demo/src/main.bas",945
	;[946]     PRINT AT 140, "Channel 0..."
	SRCFILE "./games/orchestra-demo/src/main.bas",946
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #856,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #608,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #240,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[947]     SOUND 0, 254, 15  ' Channel 0, period 254, volume 15
	SRCFILE "./games/orchestra-demo/src/main.bas",947
	MVII #254,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #15,R0
	MVO R0,507
	;[948]     FOR i = 0 TO 60: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",948
	CLRR R0
	MVO R0,var_I
T180:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #60,R0
	BLE T180
	;[949]     SOUND 0, 0, 0     ' Silence
	SRCFILE "./games/orchestra-demo/src/main.bas",949
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[950]     FOR i = 0 TO 30: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",950
	MVO R0,var_I
T181:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #30,R0
	BLE T181
	;[951] 
	SRCFILE "./games/orchestra-demo/src/main.bas",951
	;[952]     ' Test channel 1
	SRCFILE "./games/orchestra-demo/src/main.bas",952
	;[953]     PRINT AT 140, "Channel 1..."
	SRCFILE "./games/orchestra-demo/src/main.bas",953
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #856,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #608,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #248,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[954]     SOUND 1, 254, 15  ' Channel 1, same note
	SRCFILE "./games/orchestra-demo/src/main.bas",954
	MVII #254,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVII #15,R0
	MVO R0,508
	;[955]     FOR i = 0 TO 60: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",955
	CLRR R0
	MVO R0,var_I
T182:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #60,R0
	BLE T182
	;[956]     SOUND 1, 0, 0     ' Silence
	SRCFILE "./games/orchestra-demo/src/main.bas",956
	CLRR R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[957]     FOR i = 0 TO 30: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",957
	MVO R0,var_I
T183:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #30,R0
	BLE T183
	;[958] 
	SRCFILE "./games/orchestra-demo/src/main.bas",958
	;[959]     ' Test channel 2
	SRCFILE "./games/orchestra-demo/src/main.bas",959
	;[960]     PRINT AT 140, "Channel 2..."
	SRCFILE "./games/orchestra-demo/src/main.bas",960
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #856,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #608,R0
	MVO@ R0,R4
	XORI #144,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[961]     SOUND 2, 254, 15  ' Channel 2, same note
	SRCFILE "./games/orchestra-demo/src/main.bas",961
	MVII #254,R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	MVII #15,R0
	MVO R0,509
	;[962]     FOR i = 0 TO 60: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",962
	CLRR R0
	MVO R0,var_I
T184:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #60,R0
	BLE T184
	;[963]     SOUND 2, 0, 0     ' Silence
	SRCFILE "./games/orchestra-demo/src/main.bas",963
	CLRR R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	CLRR R0
	MVO R0,509
	;[964]     FOR i = 0 TO 30: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",964
	MVO R0,var_I
T185:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #30,R0
	BLE T185
	;[965] 
	SRCFILE "./games/orchestra-demo/src/main.bas",965
	;[966]     ' Test all 3 together (should be louder)
	SRCFILE "./games/orchestra-demo/src/main.bas",966
	;[967]     PRINT AT 140, "All 3 chans!"
	SRCFILE "./games/orchestra-demo/src/main.bas",967
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #264,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #872,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #608,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #536,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #656,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[968]     SOUND 0, 254, 15
	SRCFILE "./games/orchestra-demo/src/main.bas",968
	MVII #254,R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	MVII #15,R0
	MVO R0,507
	;[969]     SOUND 1, 254, 15
	SRCFILE "./games/orchestra-demo/src/main.bas",969
	MVII #254,R0
	MVO R0,497
	SWAP R0
	MVO R0,501
	MVII #15,R0
	MVO R0,508
	;[970]     SOUND 2, 254, 15
	SRCFILE "./games/orchestra-demo/src/main.bas",970
	MVII #254,R0
	MVO R0,498
	SWAP R0
	MVO R0,502
	MVII #15,R0
	MVO R0,509
	;[971]     FOR i = 0 TO 90: WAIT: NEXT i
	SRCFILE "./games/orchestra-demo/src/main.bas",971
	CLRR R0
	MVO R0,var_I
T186:
	CALL _wait
	MVI var_I,R0
	INCR R0
	MVO R0,var_I
	CMPI #90,R0
	BLE T186
	;[972]     SOUND 0, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",972
	CLRR R0
	MVO R0,496
	SWAP R0
	MVO R0,500
	CLRR R0
	MVO R0,507
	;[973]     SOUND 1, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",973
	MVO R0,497
	SWAP R0
	MVO R0,501
	CLRR R0
	MVO R0,508
	;[974]     SOUND 2, 0, 0
	SRCFILE "./games/orchestra-demo/src/main.bas",974
	MVO R0,498
	SWAP R0
	MVO R0,502
	CLRR R0
	MVO R0,509
	;[975] 
	SRCFILE "./games/orchestra-demo/src/main.bas",975
	;[976]     PRINT AT 140, "Test complete"
	SRCFILE "./games/orchestra-demo/src/main.bas",976
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #904,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #672,R0
	MVO@ R0,R4
	XORI #536,R0
	MVO@ R0,R4
	XORI #96,R0
	MVO@ R0,R4
	XORI #16,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[977] 
	SRCFILE "./games/orchestra-demo/src/main.bas",977
	;[978]     ' Now play the actual music
	SRCFILE "./games/orchestra-demo/src/main.bas",978
	;[979]     PLAY FULL
	SRCFILE "./games/orchestra-demo/src/main.bas",979
	MVII #5,R3
	MVO R3,_music_mode
	;[980]     PLAY NutcrackerMarch
	SRCFILE "./games/orchestra-demo/src/main.bas",980
	MVII #label_NUTCRACKERMARCH,R0
	CALL _play_music
	;[981] 
	SRCFILE "./games/orchestra-demo/src/main.bas",981
	;[982]     ' Wait for button or music to end
	SRCFILE "./games/orchestra-demo/src/main.bas",982
	;[983]     WHILE CONT.BUTTON = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",983
T187:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BNE T188
	;[984]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",984
	CALL _wait
	;[985]         ' Show playing indicator
	SRCFILE "./games/orchestra-demo/src/main.bas",985
	;[986]         IF MUSIC.PLAYING THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",986
	MVI _music_p,R0
	TSTR R0
	BEQ T190
	MOVR R0,R4
	MVI@ R4,R0
	MOVR R0,R5
	MVI@ R4,R0
	SUBI #65024,R0
	BNE T190
	MOVR R5,R0
T190:
	TSTR R0
	BEQ T189
	;[987]             IF (FRAME AND 15) < 8 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",987
	MVI _frame,R0
	ANDI #15,R0
	CMPI #8,R0
	BGE T191
	;[988]                 PRINT AT 160, "   [PLAYING]   "
	SRCFILE "./games/orchestra-demo/src/main.bas",988
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #472,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #224,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #128,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[989]             ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",989
	B T192
T191:
	;[990]                 PRINT AT 160, "               "
	SRCFILE "./games/orchestra-demo/src/main.bas",990
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[991]             END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",991
T192:
	;[992]         ELSE
	SRCFILE "./games/orchestra-demo/src/main.bas",992
	B T193
T189:
	;[993]             PRINT AT 160, "   [FINISHED]  "
	SRCFILE "./games/orchestra-demo/src/main.bas",993
	MVII #672,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #472,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #488,R0
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[994]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",994
T193:
	;[995]     WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",995
	B T187
T188:
	;[996] 
	SRCFILE "./games/orchestra-demo/src/main.bas",996
	;[997]     ' Stop the music when exiting
	SRCFILE "./games/orchestra-demo/src/main.bas",997
	;[998]     PLAY OFF
	SRCFILE "./games/orchestra-demo/src/main.bas",998
	CLRR R0
	CALL _play_music
	;[999] 
	SRCFILE "./games/orchestra-demo/src/main.bas",999
	;[1000]     ' Return to SIMPLE mode for voice compatibility
	SRCFILE "./games/orchestra-demo/src/main.bas",1000
	;[1001]     PLAY SIMPLE
	SRCFILE "./games/orchestra-demo/src/main.bas",1001
	MVII #3,R3
	MVO R3,_music_mode
	;[1002] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1002
	;[1003]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",1003
	CALL label_DRAW_MENU
	;[1004]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",1004
	RETURN
	;[1005] END
	SRCFILE "./games/orchestra-demo/src/main.bas",1005
	ENDP
	;[1006] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1006
	;[1007] ' Move remaining procedures to Segment 1 to save space
	SRCFILE "./games/orchestra-demo/src/main.bas",1007
	;[1008]     SEGMENT 1
	SRCFILE "./games/orchestra-demo/src/main.bas",1008
ROM.SelectSegment 1
	;[1009] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1009
	;[1010] orchestra_tune: PROCEDURE
	SRCFILE "./games/orchestra-demo/src/main.bas",1010
	; ORCHESTRA_TUNE
label_ORCHESTRA_TUNE:	PROC
	BEGIN
	;[1011]     ' Play the A440 tuning music from MIDI
	SRCFILE "./games/orchestra-demo/src/main.bas",1011
	;[1012]     CLS
	SRCFILE "./games/orchestra-demo/src/main.bas",1012
	CALL CLRSCR
	;[1013]     WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",1013
	CALL _wait
	;[1014]     PRINT AT 6, "ORCH TUNING"
	SRCFILE "./games/orchestra-demo/src/main.bas",1014
	MVII #518,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #376,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #320,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #72,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[1015] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1015
	;[1016]     ' Static labels - clear gaps too
	SRCFILE "./games/orchestra-demo/src/main.bas",1016
	;[1017]     PRINT AT 60, "INSTRUMENTS:        "
	SRCFILE "./games/orchestra-demo/src/main.bas",1017
	MVII #572,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #328,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #48,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #192,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #328,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1018]     PRINT AT 80, "                    "
	SRCFILE "./games/orchestra-demo/src/main.bas",1018
	MVII #592,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1019]     PRINT AT 220, "BTN=EXIT"
	SRCFILE "./games/orchestra-demo/src/main.bas",1019
	MVII #732,R0
	MVO R0,_screen
	MOVR R0,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #176,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	XORI #448,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[1020] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1020
	;[1021]     ' Initialize instrument display (all inactive/grey initially)
	SRCFILE "./games/orchestra-demo/src/main.bas",1021
	;[1022]     PRINT AT 100 COLOR 8, "FLUTE    ---        "
	SRCFILE "./games/orchestra-demo/src/main.bas",1022
	MVII #612,R0
	MVO R0,_screen
	MVII #8,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #304,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1023]     PRINT AT 120 COLOR 8, "CLARINET ---        "
	SRCFILE "./games/orchestra-demo/src/main.bas",1023
	MVII #632,R0
	MVO R0,_screen
	MVII #8,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1024]     PRINT AT 140 COLOR 8, "BASS     ---        "
	SRCFILE "./games/orchestra-demo/src/main.bas",1024
	MVII #652,R0
	MVO R0,_screen
	MVII #8,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #144,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1025] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1025
	;[1026]     ' Wait for controller release (debounce)
	SRCFILE "./games/orchestra-demo/src/main.bas",1026
	;[1027]     WHILE CONT.BUTTON
	SRCFILE "./games/orchestra-demo/src/main.bas",1027
T194:
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T195
	;[1028]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",1028
	CALL _wait
	;[1029]     WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",1029
	B T194
T195:
	;[1030] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1030
	;[1031]     ' Start playback
	SRCFILE "./games/orchestra-demo/src/main.bas",1031
	;[1032]     PLAY intellivision_orchestra_tuning
	SRCFILE "./games/orchestra-demo/src/main.bas",1032
	MVII #label_INTELLIVISION_ORCHESTRA_TUNING,R0
	CALL _play_music
	;[1033]     #tick = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",1033
	CLRR R0
	MVO R0,var_&TICK
	;[1034] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1034
	;[1035]     ' Wait for music to finish with visual feedback
	SRCFILE "./games/orchestra-demo/src/main.bas",1035
	;[1036]     WHILE MUSIC.PLAYING
	SRCFILE "./games/orchestra-demo/src/main.bas",1036
T196:
	MVI _music_p,R0
	TSTR R0
	BEQ T198
	MOVR R0,R4
	MVI@ R4,R0
	MOVR R0,R5
	MVI@ R4,R0
	SUBI #65024,R0
	BNE T198
	MOVR R5,R0
T198:
	TSTR R0
	BEQ T197
	;[1037]         WAIT
	SRCFILE "./games/orchestra-demo/src/main.bas",1037
	CALL _wait
	;[1038]         #tick = #tick + 1
	SRCFILE "./games/orchestra-demo/src/main.bas",1038
	MVI var_&TICK,R0
	INCR R0
	MVO R0,var_&TICK
	;[1039] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1039
	;[1040]         ' Check for early exit (any button or disc)
	SRCFILE "./games/orchestra-demo/src/main.bas",1040
	;[1041]         IF CONT.BUTTON THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",1041
	MVI 510,R0
	XOR 511,R0
	ANDI #224,R0
	BEQ T199
	;[1042]             PLAY OFF
	SRCFILE "./games/orchestra-demo/src/main.bas",1042
	CLRR R0
	CALL _play_music
	;[1043]             EXIT WHILE
	SRCFILE "./games/orchestra-demo/src/main.bas",1043
	B T197
	;[1044]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",1044
T199:
	;[1045] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1045
	;[1046]         ' Reset all instruments to OFF each frame
	SRCFILE "./games/orchestra-demo/src/main.bas",1046
	;[1047]         flute_on = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",1047
	CLRR R0
	MVO R0,var_FLUTE_ON
	;[1048]         clarinet_on = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",1048
	MVO R0,var_CLARINET_ON
	;[1049]         bass_on = 0
	SRCFILE "./games/orchestra-demo/src/main.bas",1049
	NOP
	MVO R0,var_BASS_ON
	;[1050] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1050
	;[1051]         ' Music timeline (33 ticks per note, 8 notes per section = 264 ticks):
	SRCFILE "./games/orchestra-demo/src/main.bas",1051
	;[1052]         '   0-263:    Flute only
	SRCFILE "./games/orchestra-demo/src/main.bas",1052
	;[1053]         '   264-527:  Flute + Clarinet
	SRCFILE "./games/orchestra-demo/src/main.bas",1053
	;[1054]         '   528-791:  All three
	SRCFILE "./games/orchestra-demo/src/main.bas",1054
	;[1055]         '   792-1055: All three (alternating)
	SRCFILE "./games/orchestra-demo/src/main.bas",1055
	;[1056]         '   1056-1319: Flute + Clarinet (bass stops)
	SRCFILE "./games/orchestra-demo/src/main.bas",1056
	;[1057]         '   1320-1583: All three, then silence
	SRCFILE "./games/orchestra-demo/src/main.bas",1057
	;[1058] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1058
	;[1059]         ' Flute (Channel 1) - active until tick 1550
	SRCFILE "./games/orchestra-demo/src/main.bas",1059
	;[1060]         IF #tick < 1550 THEN flute_on = 1
	SRCFILE "./games/orchestra-demo/src/main.bas",1060
	MVI var_&TICK,R0
	CMPI #1550,R0
	BGE T200
	MVII #1,R0
	MVO R0,var_FLUTE_ON
T200:
	;[1061] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1061
	;[1062]         ' Clarinet (Channel 2) - starts at 264
	SRCFILE "./games/orchestra-demo/src/main.bas",1062
	;[1063]         IF #tick >= 264 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",1063
	MVI var_&TICK,R0
	CMPI #264,R0
	BLT T201
	;[1064]             IF #tick < 1550 THEN clarinet_on = 1
	SRCFILE "./games/orchestra-demo/src/main.bas",1064
	CMPI #1550,R0
	BGE T202
	MVII #1,R0
	MVO R0,var_CLARINET_ON
T202:
	;[1065]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",1065
T201:
	;[1066] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1066
	;[1067]         ' Bass (Channel 3) - plays 528-1055, then 1320-1549
	SRCFILE "./games/orchestra-demo/src/main.bas",1067
	;[1068]         IF #tick >= 528 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",1068
	MVI var_&TICK,R0
	CMPI #528,R0
	BLT T203
	;[1069]             IF #tick < 1056 THEN bass_on = 1
	SRCFILE "./games/orchestra-demo/src/main.bas",1069
	CMPI #1056,R0
	BGE T204
	MVII #1,R0
	MVO R0,var_BASS_ON
T204:
	;[1070]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",1070
T203:
	;[1071]         IF #tick >= 1320 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",1071
	MVI var_&TICK,R0
	CMPI #1320,R0
	BLT T205
	;[1072]             IF #tick < 1550 THEN bass_on = 1
	SRCFILE "./games/orchestra-demo/src/main.bas",1072
	CMPI #1550,R0
	BGE T206
	MVII #1,R0
	MVO R0,var_BASS_ON
T206:
	;[1073]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",1073
T205:
	;[1074] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1074
	;[1075]         ' Clear display rows first (null out the area)
	SRCFILE "./games/orchestra-demo/src/main.bas",1075
	;[1076]         PRINT AT 100, "                    "
	SRCFILE "./games/orchestra-demo/src/main.bas",1076
	MVII #612,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1077]         PRINT AT 120, "                    "
	SRCFILE "./games/orchestra-demo/src/main.bas",1077
	MVII #632,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1078]         PRINT AT 140, "                    "
	SRCFILE "./games/orchestra-demo/src/main.bas",1078
	MVII #652,R0
	MVO R0,_screen
	MOVR R0,R4
	MVI _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1079] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1079
	;[1080]         ' Set colors based on active state (6=yellow, 7=white)
	SRCFILE "./games/orchestra-demo/src/main.bas",1080
	;[1081]         fc = 7: IF flute_on = 1 THEN fc = 6
	SRCFILE "./games/orchestra-demo/src/main.bas",1081
	MVII #7,R0
	MVO R0,var_FC
	MVI var_FLUTE_ON,R0
	CMPI #1,R0
	BNE T207
	MVII #6,R0
	MVO R0,var_FC
T207:
	;[1082]         cc = 7: IF clarinet_on = 1 THEN cc = 6
	SRCFILE "./games/orchestra-demo/src/main.bas",1082
	MVII #7,R0
	MVO R0,var_CC
	MVI var_CLARINET_ON,R0
	CMPI #1,R0
	BNE T208
	MVII #6,R0
	MVO R0,var_CC
T208:
	;[1083]         bc = 7: IF bass_on = 1 THEN bc = 6
	SRCFILE "./games/orchestra-demo/src/main.bas",1083
	MVII #7,R0
	MVO R0,var_BC
	MVI var_BASS_ON,R0
	CMPI #1,R0
	BNE T209
	MVII #6,R0
	MVO R0,var_BC
T209:
	;[1084] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1084
	;[1085]         ' Print instrument names with color
	SRCFILE "./games/orchestra-demo/src/main.bas",1085
	;[1086]         PRINT AT 100 COLOR fc, "FLUTE    ---"
	SRCFILE "./games/orchestra-demo/src/main.bas",1086
	MVII #612,R0
	MVO R0,_screen
	MVI var_FC,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #304,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #200,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1087]         PRINT AT 120 COLOR cc, "CLARINET ---"
	SRCFILE "./games/orchestra-demo/src/main.bas",1087
	MVII #632,R0
	MVO R0,_screen
	MVI var_CC,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #280,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #120,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #152,R0
	MVO@ R0,R4
	XORI #216,R0
	MVO@ R0,R4
	XORI #56,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #136,R0
	MVO@ R0,R4
	XORI #416,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1088]         PRINT AT 140 COLOR bc, "BASS     ---"
	SRCFILE "./games/orchestra-demo/src/main.bas",1088
	MVII #652,R0
	MVO R0,_screen
	MVI var_BC,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #272,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #24,R0
	MVO@ R0,R4
	XORI #144,R0
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #408,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1089] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1089
	;[1090]         ' Add pulsing ### for active instruments
	SRCFILE "./games/orchestra-demo/src/main.bas",1090
	;[1091]         IF flute_on = 1 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",1091
	MVI var_FLUTE_ON,R0
	CMPI #1,R0
	BNE T210
	;[1092]             IF (#tick AND 7) < 4 THEN PRINT AT 109 COLOR 6, "###"
	SRCFILE "./games/orchestra-demo/src/main.bas",1092
	MVI var_&TICK,R0
	ANDI #7,R0
	CMPI #4,R0
	BGE T211
	MVII #621,R0
	MVO R0,_screen
	MVII #6,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #24,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
T211:
	;[1093]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",1093
T210:
	;[1094]         IF clarinet_on = 1 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",1094
	MVI var_CLARINET_ON,R0
	CMPI #1,R0
	BNE T212
	;[1095]             IF ((#tick + 2) AND 7) < 4 THEN PRINT AT 129 COLOR 6, "###"
	SRCFILE "./games/orchestra-demo/src/main.bas",1095
	MVI var_&TICK,R0
	ADDI #2,R0
	ANDI #7,R0
	CMPI #4,R0
	BGE T213
	MVII #641,R0
	MVO R0,_screen
	MVII #6,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #24,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
T213:
	;[1096]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",1096
T212:
	;[1097]         IF bass_on = 1 THEN
	SRCFILE "./games/orchestra-demo/src/main.bas",1097
	MVI var_BASS_ON,R0
	CMPI #1,R0
	BNE T214
	;[1098]             IF ((#tick + 4) AND 7) < 4 THEN PRINT AT 149 COLOR 6, "###"
	SRCFILE "./games/orchestra-demo/src/main.bas",1098
	MVI var_&TICK,R0
	ADDI #4,R0
	ANDI #7,R0
	CMPI #4,R0
	BGE T215
	MVII #661,R0
	MVO R0,_screen
	MVII #6,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #24,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
T215:
	;[1099]         END IF
	SRCFILE "./games/orchestra-demo/src/main.bas",1099
T214:
	;[1100] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1100
	;[1101]         ' Show tick counter for debug (row 10)
	SRCFILE "./games/orchestra-demo/src/main.bas",1101
	;[1102]         PRINT AT 200 COLOR 7, "TICK: "
	SRCFILE "./games/orchestra-demo/src/main.bas",1102
	MVII #712,R0
	MVO R0,_screen
	MVII #7,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #416,R0
	XOR _color,R0
	MVO@ R0,R4
	XORI #232,R0
	MVO@ R0,R4
	XORI #80,R0
	MVO@ R0,R4
	XORI #64,R0
	MVO@ R0,R4
	XORI #392,R0
	MVO@ R0,R4
	XORI #208,R0
	MVO@ R0,R4
	MVO R4,_screen
	;[1103]         PRINT AT 206, <4>#tick
	SRCFILE "./games/orchestra-demo/src/main.bas",1103
	MVII #718,R0
	MVO R0,_screen
	MVI var_&TICK,R0
	MVII #4,R2
	MVI _color,R3
	MVI _screen,R4
	CALL PRNUM16.z
	MVO R4,_screen
	;[1104]     WEND
	SRCFILE "./games/orchestra-demo/src/main.bas",1104
	B T196
T197:
	;[1105] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1105
	;[1106]     ' Show completion
	SRCFILE "./games/orchestra-demo/src/main.bas",1106
	;[1107]     PRINT AT 120 COLOR 7, "--- DONE ---    "
	SRCFILE "./games/orchestra-demo/src/main.bas",1107
	MVII #632,R0
	MVO R0,_screen
	MVII #7,R0
	MVO R0,_color
	MVI _screen,R4
	MVII #104,R0
	XOR _color,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	XORI #288,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #8,R0
	MVO@ R0,R4
	XORI #88,R0
	MVO@ R0,R4
	XORI #296,R0
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	XORI #104,R0
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	MVO@ R0,R4
	NOP
	MVO R4,_screen
	;[1108]     FOR j = 1 TO 60: WAIT: NEXT j
	SRCFILE "./games/orchestra-demo/src/main.bas",1108
	MVII #1,R0
	MVO R0,var_J
T216:
	CALL _wait
	MVI var_J,R0
	INCR R0
	MVO R0,var_J
	CMPI #60,R0
	BLE T216
	;[1109] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1109
	;[1110]     ' Redraw menu
	SRCFILE "./games/orchestra-demo/src/main.bas",1110
	;[1111]     GOSUB draw_menu
	SRCFILE "./games/orchestra-demo/src/main.bas",1111
	CALL label_DRAW_MENU
	;[1112]     RETURN
	SRCFILE "./games/orchestra-demo/src/main.bas",1112
	RETURN
	;[1113] END
	SRCFILE "./games/orchestra-demo/src/main.bas",1113
	ENDP
	;[1114] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1114
	;[1115] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",1115
	;[1116] ' VOICE DATA SECTION
	SRCFILE "./games/orchestra-demo/src/main.bas",1116
	;[1117] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",1117
	;[1118] ' Phonemes: PA1-PA5, OY, AY, EH, KK1-KK3, PP, JH,
	SRCFILE "./games/orchestra-demo/src/main.bas",1118
	;[1119] ' NN1-NN2, IH, TT1-TT2, RR1-RR2, AX, MM, DH1-DH2, IY, EY,
	SRCFILE "./games/orchestra-demo/src/main.bas",1119
	;[1120] ' DD1-DD2, UW1-UW2, AO, AA, YY1-YY2, AE, HH1-HH2, BB1-BB2,
	SRCFILE "./games/orchestra-demo/src/main.bas",1120
	;[1121] ' TH, UH, AW, GG1-GG3, VV, SH, ZH, FF, ZZ, NG, LL, WW,
	SRCFILE "./games/orchestra-demo/src/main.bas",1121
	;[1122] ' XR, WH, CH, ER1-ER2, OW, SS, OR, AR, YR, EL
	SRCFILE "./games/orchestra-demo/src/main.bas",1122
	;[1123] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1123
	;[1124] intro_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1124
	; INTRO_PHRASE
label_INTRO_PHRASE:	;[1125]     VOICE HH1,EH,LL,AO,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1125
	DECLE _HH1
	DECLE _EH
	DECLE _LL
	DECLE _AO
	DECLE 4
	DECLE 0
	;[1126] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1126
	;[1127] ' --- INSTRUMENT PHRASES ---
	SRCFILE "./games/orchestra-demo/src/main.bas",1127
	;[1128] cello_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1128
	; CELLO_PHRASE
label_CELLO_PHRASE:	;[1129]     ' "Cello" - CHEL-oh
	SRCFILE "./games/orchestra-demo/src/main.bas",1129
	;[1130]     VOICE CH,EH,LL,PA1,OW,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1130
	DECLE _CH
	DECLE _EH
	DECLE _LL
	DECLE 5
	DECLE _OW
	DECLE 4
	DECLE 0
	;[1131] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1131
	;[1132] oboe_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1132
	; OBOE_PHRASE
label_OBOE_PHRASE:	;[1133]     ' "Oboe" - OH-boh
	SRCFILE "./games/orchestra-demo/src/main.bas",1133
	;[1134]     VOICE OW,PA1,BB1,OW,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1134
	DECLE _OW
	DECLE 5
	DECLE _BB1
	DECLE _OW
	DECLE 4
	DECLE 0
	;[1135] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1135
	;[1136] bass_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1136
	; BASS_PHRASE
label_BASS_PHRASE:	;[1137]     ' "Bass" - BAYSS
	SRCFILE "./games/orchestra-demo/src/main.bas",1137
	;[1138]     VOICE BB1,EY,SS,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1138
	DECLE _BB1
	DECLE _EY
	DECLE _SS
	DECLE 4
	DECLE 0
	;[1139] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1139
	;[1140] timpani_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1140
	; TIMPANI_PHRASE
label_TIMPANI_PHRASE:	;[1141]     ' "Timpani" - TIM-puh-nee
	SRCFILE "./games/orchestra-demo/src/main.bas",1141
	;[1142]     VOICE TT1,IH,MM,PA1
	SRCFILE "./games/orchestra-demo/src/main.bas",1142
	DECLE _TT1
	DECLE _IH
	DECLE _MM
	DECLE 5
	;[1143]     VOICE PP,UH,NN1,IY,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1143
	DECLE _PP
	DECLE _UH
	DECLE _NN1
	DECLE _IY
	DECLE 4
	DECLE 0
	;[1144] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1144
	;[1145] trombone_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1145
	; TROMBONE_PHRASE
label_TROMBONE_PHRASE:	;[1146]     ' "Trombone" - TRAHM-bohn
	SRCFILE "./games/orchestra-demo/src/main.bas",1146
	;[1147]     VOICE TT1,RR1,AO,MM,PA1
	SRCFILE "./games/orchestra-demo/src/main.bas",1147
	DECLE _TT1
	DECLE _RR1
	DECLE _AO
	DECLE _MM
	DECLE 5
	;[1148]     VOICE BB1,OW,NN1,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1148
	DECLE _BB1
	DECLE _OW
	DECLE _NN1
	DECLE 4
	DECLE 0
	;[1149] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1149
	;[1150] piccolo_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1150
	; PICCOLO_PHRASE
label_PICCOLO_PHRASE:	;[1151]     ' "Piccolo" - PIK-uh-loh
	SRCFILE "./games/orchestra-demo/src/main.bas",1151
	;[1152]     VOICE PP,IH,KK1,PA1
	SRCFILE "./games/orchestra-demo/src/main.bas",1152
	DECLE _PP
	DECLE _IH
	DECLE _KK1
	DECLE 5
	;[1153]     VOICE UH,LL,OW,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1153
	DECLE _UH
	DECLE _LL
	DECLE _OW
	DECLE 4
	DECLE 0
	;[1154] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1154
	;[1155] trumpet_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1155
	; TRUMPET_PHRASE
label_TRUMPET_PHRASE:	;[1156]     ' "Trumpet" - TRUM-pit
	SRCFILE "./games/orchestra-demo/src/main.bas",1156
	;[1157]     VOICE TT1,RR1,AX,MM,PA1
	SRCFILE "./games/orchestra-demo/src/main.bas",1157
	DECLE _TT1
	DECLE _RR1
	DECLE _AX
	DECLE _MM
	DECLE 5
	;[1158]     VOICE PP,IH,TT1,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1158
	DECLE _PP
	DECLE _IH
	DECLE _TT1
	DECLE 4
	DECLE 0
	;[1159] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1159
	;[1160] viola_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1160
	; VIOLA_PHRASE
label_VIOLA_PHRASE:	;[1161]     ' "Viola" - vee-OH-luh
	SRCFILE "./games/orchestra-demo/src/main.bas",1161
	;[1162]     VOICE VV,IY,PA1
	SRCFILE "./games/orchestra-demo/src/main.bas",1162
	DECLE _VV
	DECLE _IY
	DECLE 5
	;[1163]     VOICE OW,LL,UH,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1163
	DECLE _OW
	DECLE _LL
	DECLE _UH
	DECLE 4
	DECLE 0
	;[1164] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1164
	;[1165] tuba_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1165
	; TUBA_PHRASE
label_TUBA_PHRASE:	;[1166]     ' "Tuba" - TOO-buh
	SRCFILE "./games/orchestra-demo/src/main.bas",1166
	;[1167]     VOICE TT1,UW1,PA1
	SRCFILE "./games/orchestra-demo/src/main.bas",1167
	DECLE _TT1
	DECLE _UW1
	DECLE 5
	;[1168]     VOICE BB1,UH,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1168
	DECLE _BB1
	DECLE _UH
	DECLE 4
	DECLE 0
	;[1169] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1169
	;[1170] sneeze_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1170
	; SNEEZE_PHRASE
label_SNEEZE_PHRASE:	;[1171]     ' "Achoo!" - AH...CHOO
	SRCFILE "./games/orchestra-demo/src/main.bas",1171
	;[1172]     VOICE AA,PA1,PA1
	SRCFILE "./games/orchestra-demo/src/main.bas",1172
	DECLE _AA
	DECLE 5
	DECLE 5
	;[1173]     VOICE CH,UW1,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1173
	DECLE _CH
	DECLE _UW1
	DECLE 4
	DECLE 0
	;[1174] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1174
	;[1175] ' --- SPECIAL PHRASES ---
	SRCFILE "./games/orchestra-demo/src/main.bas",1175
	;[1176] bravo_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1176
	; BRAVO_PHRASE
label_BRAVO_PHRASE:	;[1177]     ' "Bravo" - BRAH-VOH
	SRCFILE "./games/orchestra-demo/src/main.bas",1177
	;[1178]     VOICE BB1,RR1,AA,PA1
	SRCFILE "./games/orchestra-demo/src/main.bas",1178
	DECLE _BB1
	DECLE _RR1
	DECLE _AA
	DECLE 5
	;[1179]     VOICE VV,OW,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1179
	DECLE _VV
	DECLE _OW
	DECLE 4
	DECLE 0
	;[1180] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1180
	;[1181] encore_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1181
	; ENCORE_PHRASE
label_ENCORE_PHRASE:	;[1182]     ' "Encore" - AHN-KOR
	SRCFILE "./games/orchestra-demo/src/main.bas",1182
	;[1183]     VOICE AO,NN1,PA1
	SRCFILE "./games/orchestra-demo/src/main.bas",1183
	DECLE _AO
	DECLE _NN1
	DECLE 5
	;[1184]     VOICE KK1,AO,RR1,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1184
	DECLE _KK1
	DECLE _AO
	DECLE _RR1
	DECLE 4
	DECLE 0
	;[1185] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1185
	;[1186] pencil_phrase:
	SRCFILE "./games/orchestra-demo/src/main.bas",1186
	; PENCIL_PHRASE
label_PENCIL_PHRASE:	;[1187]     ' Pencil drop sound effect
	SRCFILE "./games/orchestra-demo/src/main.bas",1187
	;[1188]     VOICE PP,PA1,TT1,PA1,TT2,PA1,TT1,PA2,0
	SRCFILE "./games/orchestra-demo/src/main.bas",1188
	DECLE _PP
	DECLE 5
	DECLE _TT1
	DECLE 5
	DECLE _TT2
	DECLE 5
	DECLE _TT1
	DECLE 4
	DECLE 0
	;[1189] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1189
	;[1190] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",1190
	;[1191] ' MUSIC DATA SECTION (from MIDI conversion)
	SRCFILE "./games/orchestra-demo/src/main.bas",1191
	;[1192] ' Move to Segment 2 for more space
	SRCFILE "./games/orchestra-demo/src/main.bas",1192
	;[1193] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",1193
	;[1194]     SEGMENT 2
	SRCFILE "./games/orchestra-demo/src/main.bas",1194
ROM.SelectSegment 2
	;[1195] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1195
	;[1196] INCLUDE "assets/music/tuning_music.bas"
	SRCFILE "./games/orchestra-demo/src/main.bas",1196
	;FILE assets/music/tuning_music.bas
	;[1] intellivision_orchestra_tuning:
	SRCFILE "assets/music/tuning_music.bas",1
	; INTELLIVISION_ORCHESTRA_TUNING
label_INTELLIVISION_ORCHESTRA_TUNING:	;[2]     DATA 33
	SRCFILE "assets/music/tuning_music.bas",2
	DECLE 33
	;[3] 
	SRCFILE "assets/music/tuning_music.bas",3
	;[4]     MUSIC A4Y,-,-,-
	SRCFILE "assets/music/tuning_music.bas",4
	DECLE 162,0
	;[5]     MUSIC A4,-,-,-
	SRCFILE "assets/music/tuning_music.bas",5
	DECLE 162,0
	;[6]     MUSIC A4,-,-,-
	SRCFILE "assets/music/tuning_music.bas",6
	DECLE 162,0
	;[7]     MUSIC A4,-,-,-
	SRCFILE "assets/music/tuning_music.bas",7
	DECLE 162,0
	;[8] 
	SRCFILE "assets/music/tuning_music.bas",8
	;[9]     MUSIC A4,-,-,-
	SRCFILE "assets/music/tuning_music.bas",9
	DECLE 162,0
	;[10]     MUSIC A4,-,-,-
	SRCFILE "assets/music/tuning_music.bas",10
	DECLE 162,0
	;[11]     MUSIC A4,-,-,-
	SRCFILE "assets/music/tuning_music.bas",11
	DECLE 162,0
	;[12]     MUSIC A4,-,-,-
	SRCFILE "assets/music/tuning_music.bas",12
	DECLE 162,0
	;[13] 
	SRCFILE "assets/music/tuning_music.bas",13
	;[14]     MUSIC A4,D4X,-,-
	SRCFILE "assets/music/tuning_music.bas",14
	DECLE 23458,0
	;[15]     MUSIC A4,D4,-,-
	SRCFILE "assets/music/tuning_music.bas",15
	DECLE 23458,0
	;[16]     MUSIC A4,D4,-,-
	SRCFILE "assets/music/tuning_music.bas",16
	DECLE 23458,0
	;[17]     MUSIC A4,D4,-,-
	SRCFILE "assets/music/tuning_music.bas",17
	DECLE 23458,0
	;[18] 
	SRCFILE "assets/music/tuning_music.bas",18
	;[19]     MUSIC A4,D4,-,-
	SRCFILE "assets/music/tuning_music.bas",19
	DECLE 23458,0
	;[20]     MUSIC A4,D4,-,-
	SRCFILE "assets/music/tuning_music.bas",20
	DECLE 23458,0
	;[21]     MUSIC A4,D4,-,-
	SRCFILE "assets/music/tuning_music.bas",21
	DECLE 23458,0
	;[22]     MUSIC A4,D4,-,-
	SRCFILE "assets/music/tuning_music.bas",22
	DECLE 23458,0
	;[23] 
	SRCFILE "assets/music/tuning_music.bas",23
	;[24]     MUSIC A4,D4,G3Z,-
	SRCFILE "assets/music/tuning_music.bas",24
	DECLE 23458,212
	;[25]     MUSIC A4,D4,G3,-
	SRCFILE "assets/music/tuning_music.bas",25
	DECLE 23458,212
	;[26]     MUSIC A4,D4,G3,-
	SRCFILE "assets/music/tuning_music.bas",26
	DECLE 23458,212
	;[27]     MUSIC A4,D4,G3,-
	SRCFILE "assets/music/tuning_music.bas",27
	DECLE 23458,212
	;[28] 
	SRCFILE "assets/music/tuning_music.bas",28
	;[29]     MUSIC A4,D4,G3,-
	SRCFILE "assets/music/tuning_music.bas",29
	DECLE 23458,212
	;[30]     MUSIC A4,D4,G3,-
	SRCFILE "assets/music/tuning_music.bas",30
	DECLE 23458,212
	;[31]     MUSIC A4,D4,G3,-
	SRCFILE "assets/music/tuning_music.bas",31
	DECLE 23458,212
	;[32]     MUSIC A4,D4,G3,-
	SRCFILE "assets/music/tuning_music.bas",32
	DECLE 23458,212
	;[33] 
	SRCFILE "assets/music/tuning_music.bas",33
	;[34]     MUSIC A4,D4,E5,-
	SRCFILE "assets/music/tuning_music.bas",34
	DECLE 23458,233
	;[35]     MUSIC A4,G3,C4,-
	SRCFILE "assets/music/tuning_music.bas",35
	DECLE 21666,217
	;[36]     MUSIC A4,D4,E5,-
	SRCFILE "assets/music/tuning_music.bas",36
	DECLE 23458,233
	;[37]     MUSIC A4,G3,C4,-
	SRCFILE "assets/music/tuning_music.bas",37
	DECLE 21666,217
	;[38] 
	SRCFILE "assets/music/tuning_music.bas",38
	;[39]     MUSIC A4,D4,E5,-
	SRCFILE "assets/music/tuning_music.bas",39
	DECLE 23458,233
	;[40]     MUSIC A4,G3,C4,-
	SRCFILE "assets/music/tuning_music.bas",40
	DECLE 21666,217
	;[41]     MUSIC A4,D4,E5,-
	SRCFILE "assets/music/tuning_music.bas",41
	DECLE 23458,233
	;[42]     MUSIC A4,G3,C4,-
	SRCFILE "assets/music/tuning_music.bas",42
	DECLE 21666,217
	;[43] 
	SRCFILE "assets/music/tuning_music.bas",43
	;[44]     MUSIC A4,A3#,-,-
	SRCFILE "assets/music/tuning_music.bas",44
	DECLE 22434,0
	;[45]     MUSIC A4,F4,-,-
	SRCFILE "assets/music/tuning_music.bas",45
	DECLE 24226,0
	;[46]     MUSIC A4,A3#,-,-
	SRCFILE "assets/music/tuning_music.bas",46
	DECLE 22434,0
	;[47]     MUSIC A4,F4,-,-
	SRCFILE "assets/music/tuning_music.bas",47
	DECLE 24226,0
	;[48] 
	SRCFILE "assets/music/tuning_music.bas",48
	;[49]     MUSIC A4,A3#,-,-
	SRCFILE "assets/music/tuning_music.bas",49
	DECLE 22434,0
	;[50]     MUSIC A4,F4,-,-
	SRCFILE "assets/music/tuning_music.bas",50
	DECLE 24226,0
	;[51]     MUSIC A4,A3#,-,-
	SRCFILE "assets/music/tuning_music.bas",51
	DECLE 22434,0
	;[52]     MUSIC A4,F4,-,-
	SRCFILE "assets/music/tuning_music.bas",52
	DECLE 24226,0
	;[53] 
	SRCFILE "assets/music/tuning_music.bas",53
	;[54]     MUSIC A4,D4,A3,-
	SRCFILE "assets/music/tuning_music.bas",54
	DECLE 23458,214
	;[55]     MUSIC A4,D4,A3,-
	SRCFILE "assets/music/tuning_music.bas",55
	DECLE 23458,214
	;[56]     MUSIC A4,D4,A3,-
	SRCFILE "assets/music/tuning_music.bas",56
	DECLE 23458,214
	;[57]     MUSIC A4,D4,A3,-
	SRCFILE "assets/music/tuning_music.bas",57
	DECLE 23458,214
	;[58] 
	SRCFILE "assets/music/tuning_music.bas",58
	;[59]     MUSIC A4,D4,A3,-
	SRCFILE "assets/music/tuning_music.bas",59
	DECLE 23458,214
	;[60]     MUSIC A4,D4,A3,-
	SRCFILE "assets/music/tuning_music.bas",60
	DECLE 23458,214
	;[61]     MUSIC A4,-,-,-
	SRCFILE "assets/music/tuning_music.bas",61
	DECLE 162,0
	;[62]     MUSIC S,-,-,-
	SRCFILE "assets/music/tuning_music.bas",62
	DECLE 63,0
	;[63] 
	SRCFILE "assets/music/tuning_music.bas",63
	;[64]     MUSIC -,-,-,-
	SRCFILE "assets/music/tuning_music.bas",64
	DECLE 0,0
	;[65] 
	SRCFILE "assets/music/tuning_music.bas",65
	;[66]     MUSIC STOP
	SRCFILE "assets/music/tuning_music.bas",66
	DECLE 0,65024
	;ENDFILE
	;FILE ./games/orchestra-demo/src/main.bas
	;[1197] INCLUDE "assets/music/greensleeves_music.bas"
	SRCFILE "./games/orchestra-demo/src/main.bas",1197
	;FILE assets/music/greensleeves_music.bas
	;[1] Greensleeves:
	SRCFILE "assets/music/greensleeves_music.bas",1
	; GREENSLEEVES
label_GREENSLEEVES:	;[2]     DATA 9
	SRCFILE "assets/music/greensleeves_music.bas",2
	DECLE 9
	;[3] 
	SRCFILE "assets/music/greensleeves_music.bas",3
	;[4]     MUSIC A4W,-,-,-
	SRCFILE "assets/music/greensleeves_music.bas",4
	DECLE 34,0
	;[5]     MUSIC S,-,-,-
	SRCFILE "assets/music/greensleeves_music.bas",5
	DECLE 63,0
	;[6] 
	SRCFILE "assets/music/greensleeves_music.bas",6
	;[7]     MUSIC C5,A3W,-,-
	SRCFILE "assets/music/greensleeves_music.bas",7
	DECLE 5669,0
	;[8]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",8
	DECLE 16191,0
	;[9]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",9
	DECLE 16191,0
	;[10]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",10
	DECLE 16191,0
	;[11]     MUSIC D5,B3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",11
	DECLE 6183,0
	;[12]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",12
	DECLE 16191,0
	;[13] 
	SRCFILE "assets/music/greensleeves_music.bas",13
	;[14]     MUSIC E5,C4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",14
	DECLE 6441,0
	;[15]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",15
	DECLE 16191,0
	;[16]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",16
	DECLE 16191,0
	;[17]     MUSIC F5,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",17
	DECLE 16170,0
	;[18]     MUSIC E5,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",18
	DECLE 16169,0
	;[19]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",19
	DECLE 16191,0
	;[20] 
	SRCFILE "assets/music/greensleeves_music.bas",20
	;[21]     MUSIC D5,G3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",21
	DECLE 5159,0
	;[22]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",22
	DECLE 16191,0
	;[23]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",23
	DECLE 16191,0
	;[24]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",24
	DECLE 16191,0
	;[25]     MUSIC B4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",25
	DECLE 16164,0
	;[26]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",26
	DECLE 16191,0
	;[27] 
	SRCFILE "assets/music/greensleeves_music.bas",27
	;[28]     MUSIC B3,G4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",28
	DECLE 8216,0
	;[29]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",29
	DECLE 16191,0
	;[30]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",30
	DECLE 16191,0
	;[31]     MUSIC S,A4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",31
	DECLE 8767,0
	;[32]     MUSIC S,B4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",32
	DECLE 9279,0
	;[33]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",33
	DECLE 16191,0
	;[34] 
	SRCFILE "assets/music/greensleeves_music.bas",34
	;[35]     MUSIC C5,A3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",35
	DECLE 5669,0
	;[36]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",36
	DECLE 16191,0
	;[37]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",37
	DECLE 16191,0
	;[38]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",38
	DECLE 16191,0
	;[39]     MUSIC A4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",39
	DECLE 16162,0
	;[40]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",40
	DECLE 16191,0
	;[41] 
	SRCFILE "assets/music/greensleeves_music.bas",41
	;[42]     MUSIC A4,F4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",42
	DECLE 7714,0
	;[43]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",43
	DECLE 16191,0
	;[44]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",44
	DECLE 16191,0
	;[45]     MUSIC G4#,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",45
	DECLE 16161,0
	;[46]     MUSIC A4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",46
	DECLE 16162,0
	;[47]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",47
	DECLE 16191,0
	;[48] 
	SRCFILE "assets/music/greensleeves_music.bas",48
	;[49]     MUSIC B4,E4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",49
	DECLE 7460,0
	;[50]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",50
	DECLE 16191,0
	;[51]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",51
	DECLE 16191,0
	;[52]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",52
	DECLE 16191,0
	;[53]     MUSIC G4#,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",53
	DECLE 16161,0
	;[54]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",54
	DECLE 16191,0
	;[55] 
	SRCFILE "assets/music/greensleeves_music.bas",55
	;[56]     MUSIC E3,E4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",56
	DECLE 7441,0
	;[57]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",57
	DECLE 16191,0
	;[58]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",58
	DECLE 16191,0
	;[59]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",59
	DECLE 16191,0
	;[60]     MUSIC S,A4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",60
	DECLE 8767,0
	;[61]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",61
	DECLE 16191,0
	;[62] 
	SRCFILE "assets/music/greensleeves_music.bas",62
	;[63]     MUSIC C5,A3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",63
	DECLE 5669,0
	;[64]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",64
	DECLE 16191,0
	;[65]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",65
	DECLE 16191,0
	;[66]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",66
	DECLE 16191,0
	;[67]     MUSIC D5,B3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",67
	DECLE 6183,0
	;[68]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",68
	DECLE 16191,0
	;[69] 
	SRCFILE "assets/music/greensleeves_music.bas",69
	;[70]     MUSIC E5,C4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",70
	DECLE 6441,0
	;[71]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",71
	DECLE 16191,0
	;[72]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",72
	DECLE 16191,0
	;[73]     MUSIC F5,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",73
	DECLE 16170,0
	;[74]     MUSIC E5,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",74
	DECLE 16169,0
	;[75]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",75
	DECLE 16191,0
	;[76] 
	SRCFILE "assets/music/greensleeves_music.bas",76
	;[77]     MUSIC D5,G3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",77
	DECLE 5159,0
	;[78]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",78
	DECLE 16191,0
	;[79]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",79
	DECLE 16191,0
	;[80]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",80
	DECLE 16191,0
	;[81]     MUSIC B4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",81
	DECLE 16164,0
	;[82]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",82
	DECLE 16191,0
	;[83] 
	SRCFILE "assets/music/greensleeves_music.bas",83
	;[84]     MUSIC B3,G4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",84
	DECLE 8216,0
	;[85]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",85
	DECLE 16191,0
	;[86]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",86
	DECLE 16191,0
	;[87]     MUSIC S,A4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",87
	DECLE 8767,0
	;[88]     MUSIC S,B4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",88
	DECLE 9279,0
	;[89]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",89
	DECLE 16191,0
	;[90] 
	SRCFILE "assets/music/greensleeves_music.bas",90
	;[91]     MUSIC C5,A3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",91
	DECLE 5669,0
	;[92]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",92
	DECLE 16191,0
	;[93]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",93
	DECLE 16191,0
	;[94]     MUSIC B4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",94
	DECLE 16164,0
	;[95]     MUSIC A4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",95
	DECLE 16162,0
	;[96]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",96
	DECLE 16191,0
	;[97] 
	SRCFILE "assets/music/greensleeves_music.bas",97
	;[98]     MUSIC G4#,E3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",98
	DECLE 4385,0
	;[99]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",99
	DECLE 16191,0
	;[100]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",100
	DECLE 16191,0
	;[101]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",101
	DECLE 16159,0
	;[102]     MUSIC G4#,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",102
	DECLE 16161,0
	;[103]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",103
	DECLE 16191,0
	;[104] 
	SRCFILE "assets/music/greensleeves_music.bas",104
	;[105]     MUSIC A4,A3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",105
	DECLE 5666,0
	;[106]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",106
	DECLE 16191,0
	;[107]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",107
	DECLE 16191,0
	;[108]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",108
	DECLE 16191,0
	;[109]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",109
	DECLE 16191,0
	;[110]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",110
	DECLE 16191,0
	;[111] 
	SRCFILE "assets/music/greensleeves_music.bas",111
	;[112]     MUSIC A3,A4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",112
	DECLE 8726,0
	;[113]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",113
	DECLE 16191,0
	;[114]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",114
	DECLE 16191,0
	;[115]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",115
	DECLE 16191,0
	;[116]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",116
	DECLE 16191,0
	;[117]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",117
	DECLE 16191,0
	;[118] 
	SRCFILE "assets/music/greensleeves_music.bas",118
	;[119]     MUSIC G5,C4,E4W,-
	SRCFILE "assets/music/greensleeves_music.bas",119
	DECLE 6444,29
	;[120]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",120
	DECLE 16191,63
	;[121]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",121
	DECLE 16191,63
	;[122]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",122
	DECLE 16191,63
	;[123]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",123
	DECLE 16191,63
	;[124]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",124
	DECLE 16191,63
	;[125] 
	SRCFILE "assets/music/greensleeves_music.bas",125
	;[126]     MUSIC G5,C4,E4,-
	SRCFILE "assets/music/greensleeves_music.bas",126
	DECLE 6444,29
	;[127]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",127
	DECLE 16191,63
	;[128]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",128
	DECLE 16191,63
	;[129]     MUSIC F5,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",129
	DECLE 16170,63
	;[130]     MUSIC E5,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",130
	DECLE 16169,63
	;[131]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",131
	DECLE 16191,63
	;[132] 
	SRCFILE "assets/music/greensleeves_music.bas",132
	;[133]     MUSIC D5,G3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",133
	DECLE 5159,0
	;[134]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",134
	DECLE 16191,0
	;[135]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",135
	DECLE 16191,0
	;[136]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",136
	DECLE 16191,0
	;[137]     MUSIC B4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",137
	DECLE 16164,0
	;[138]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",138
	DECLE 16191,0
	;[139] 
	SRCFILE "assets/music/greensleeves_music.bas",139
	;[140]     MUSIC B3,G4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",140
	DECLE 8216,0
	;[141]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",141
	DECLE 16191,0
	;[142]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",142
	DECLE 16191,0
	;[143]     MUSIC S,A4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",143
	DECLE 8767,0
	;[144]     MUSIC S,B4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",144
	DECLE 9279,0
	;[145]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",145
	DECLE 16191,0
	;[146] 
	SRCFILE "assets/music/greensleeves_music.bas",146
	;[147]     MUSIC C5,A3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",147
	DECLE 5669,0
	;[148]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",148
	DECLE 16191,0
	;[149]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",149
	DECLE 16191,0
	;[150]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",150
	DECLE 16191,0
	;[151]     MUSIC A4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",151
	DECLE 16162,0
	;[152]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",152
	DECLE 16191,0
	;[153] 
	SRCFILE "assets/music/greensleeves_music.bas",153
	;[154]     MUSIC A4,F4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",154
	DECLE 7714,0
	;[155]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",155
	DECLE 16191,0
	;[156]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",156
	DECLE 16191,0
	;[157]     MUSIC G4#,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",157
	DECLE 16161,0
	;[158]     MUSIC A4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",158
	DECLE 16162,0
	;[159]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",159
	DECLE 16191,0
	;[160] 
	SRCFILE "assets/music/greensleeves_music.bas",160
	;[161]     MUSIC B4,E4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",161
	DECLE 7460,0
	;[162]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",162
	DECLE 16191,0
	;[163]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",163
	DECLE 16191,0
	;[164]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",164
	DECLE 16191,0
	;[165]     MUSIC G4#,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",165
	DECLE 16161,0
	;[166]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",166
	DECLE 16191,0
	;[167] 
	SRCFILE "assets/music/greensleeves_music.bas",167
	;[168]     MUSIC E3,E4,-,-
	SRCFILE "assets/music/greensleeves_music.bas",168
	DECLE 7441,0
	;[169]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",169
	DECLE 16191,0
	;[170]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",170
	DECLE 16191,0
	;[171]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",171
	DECLE 16191,0
	;[172]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",172
	DECLE 16191,0
	;[173]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",173
	DECLE 16191,0
	;[174] 
	SRCFILE "assets/music/greensleeves_music.bas",174
	;[175]     MUSIC G5,C4,E4,-
	SRCFILE "assets/music/greensleeves_music.bas",175
	DECLE 6444,29
	;[176]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",176
	DECLE 16191,63
	;[177]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",177
	DECLE 16191,63
	;[178]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",178
	DECLE 16191,63
	;[179]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",179
	DECLE 16191,63
	;[180]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",180
	DECLE 16191,63
	;[181] 
	SRCFILE "assets/music/greensleeves_music.bas",181
	;[182]     MUSIC G5,C4,E4,-
	SRCFILE "assets/music/greensleeves_music.bas",182
	DECLE 6444,29
	;[183]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",183
	DECLE 16191,63
	;[184]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",184
	DECLE 16191,63
	;[185]     MUSIC F5,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",185
	DECLE 16170,63
	;[186]     MUSIC E5,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",186
	DECLE 16169,63
	;[187]     MUSIC S,S,S,-
	SRCFILE "assets/music/greensleeves_music.bas",187
	DECLE 16191,63
	;[188] 
	SRCFILE "assets/music/greensleeves_music.bas",188
	;[189]     MUSIC D5,G3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",189
	DECLE 5159,0
	;[190]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",190
	DECLE 16191,0
	;[191]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",191
	DECLE 16191,0
	;[192]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",192
	DECLE 16191,0
	;[193]     MUSIC B4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",193
	DECLE 16164,0
	;[194]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",194
	DECLE 16191,0
	;[195] 
	SRCFILE "assets/music/greensleeves_music.bas",195
	;[196]     MUSIC G4,B3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",196
	DECLE 6176,0
	;[197]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",197
	DECLE 16191,0
	;[198]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",198
	DECLE 16191,0
	;[199]     MUSIC A4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",199
	DECLE 16162,0
	;[200]     MUSIC B4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",200
	DECLE 16164,0
	;[201]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",201
	DECLE 16191,0
	;[202] 
	SRCFILE "assets/music/greensleeves_music.bas",202
	;[203]     MUSIC C5,A3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",203
	DECLE 5669,0
	;[204]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",204
	DECLE 16191,0
	;[205]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",205
	DECLE 16191,0
	;[206]     MUSIC B4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",206
	DECLE 16164,0
	;[207]     MUSIC A4,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",207
	DECLE 16162,0
	;[208]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",208
	DECLE 16191,0
	;[209] 
	SRCFILE "assets/music/greensleeves_music.bas",209
	;[210]     MUSIC G4#,E3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",210
	DECLE 4385,0
	;[211]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",211
	DECLE 16191,0
	;[212]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",212
	DECLE 16191,0
	;[213]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",213
	DECLE 16159,0
	;[214]     MUSIC G4#,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",214
	DECLE 16161,0
	;[215]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",215
	DECLE 16191,0
	;[216] 
	SRCFILE "assets/music/greensleeves_music.bas",216
	;[217]     MUSIC A4,A3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",217
	DECLE 5666,0
	;[218]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",218
	DECLE 16191,0
	;[219]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",219
	DECLE 16191,0
	;[220]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",220
	DECLE 16191,0
	;[221]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",221
	DECLE 16191,0
	;[222]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",222
	DECLE 16191,0
	;[223] 
	SRCFILE "assets/music/greensleeves_music.bas",223
	;[224]     MUSIC A4,A3,-,-
	SRCFILE "assets/music/greensleeves_music.bas",224
	DECLE 5666,0
	;[225]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",225
	DECLE 16191,0
	;[226]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",226
	DECLE 16191,0
	;[227]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",227
	DECLE 16191,0
	;[228]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",228
	DECLE 16191,0
	;[229]     MUSIC S,S,-,-
	SRCFILE "assets/music/greensleeves_music.bas",229
	DECLE 16191,0
	;[230] 
	SRCFILE "assets/music/greensleeves_music.bas",230
	;[231]     MUSIC -,-,-,-
	SRCFILE "assets/music/greensleeves_music.bas",231
	DECLE 0,0
	;[232] 
	SRCFILE "assets/music/greensleeves_music.bas",232
	;[233]     MUSIC STOP
	SRCFILE "assets/music/greensleeves_music.bas",233
	DECLE 0,65024
	;ENDFILE
	;FILE ./games/orchestra-demo/src/main.bas
	;[1198] INCLUDE "assets/music/canon_music.bas"
	SRCFILE "./games/orchestra-demo/src/main.bas",1198
	;FILE assets/music/canon_music.bas
	;[1] Canon_in_D:
	SRCFILE "assets/music/canon_music.bas",1
	; CANON_IN_D
label_CANON_IN_D:	;[2]     DATA 7
	SRCFILE "assets/music/canon_music.bas",2
	DECLE 7
	;[3] 
	SRCFILE "assets/music/canon_music.bas",3
	;[4]     MUSIC D3W,-,-,-
	SRCFILE "assets/music/canon_music.bas",4
	DECLE 15,0
	;[5]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",5
	DECLE 63,0
	;[6]     MUSIC F3#,-,-,-
	SRCFILE "assets/music/canon_music.bas",6
	DECLE 19,0
	;[7]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",7
	DECLE 63,0
	;[8]     MUSIC A3,-,-,-
	SRCFILE "assets/music/canon_music.bas",8
	DECLE 22,0
	;[9]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",9
	DECLE 63,0
	;[10]     MUSIC D4,-,-,-
	SRCFILE "assets/music/canon_music.bas",10
	DECLE 27,0
	;[11]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",11
	DECLE 63,0
	;[12]     MUSIC A2,-,-,-
	SRCFILE "assets/music/canon_music.bas",12
	DECLE 10,0
	;[13]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",13
	DECLE 63,0
	;[14]     MUSIC C3#,-,-,-
	SRCFILE "assets/music/canon_music.bas",14
	DECLE 14,0
	;[15]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",15
	DECLE 63,0
	;[16]     MUSIC E3,-,-,-
	SRCFILE "assets/music/canon_music.bas",16
	DECLE 17,0
	;[17]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",17
	DECLE 63,0
	;[18]     MUSIC A3,-,-,-
	SRCFILE "assets/music/canon_music.bas",18
	DECLE 22,0
	;[19]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",19
	DECLE 63,0
	;[20] 
	SRCFILE "assets/music/canon_music.bas",20
	;[21]     MUSIC B2,-,-,-
	SRCFILE "assets/music/canon_music.bas",21
	DECLE 12,0
	;[22]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",22
	DECLE 63,0
	;[23]     MUSIC D3,-,-,-
	SRCFILE "assets/music/canon_music.bas",23
	DECLE 15,0
	;[24]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",24
	DECLE 63,0
	;[25]     MUSIC F3#,-,-,-
	SRCFILE "assets/music/canon_music.bas",25
	DECLE 19,0
	;[26]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",26
	DECLE 63,0
	;[27]     MUSIC B3,-,-,-
	SRCFILE "assets/music/canon_music.bas",27
	DECLE 24,0
	;[28]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",28
	DECLE 63,0
	;[29]     MUSIC F2#,-,-,-
	SRCFILE "assets/music/canon_music.bas",29
	DECLE 7,0
	;[30]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",30
	DECLE 63,0
	;[31]     MUSIC A2,-,-,-
	SRCFILE "assets/music/canon_music.bas",31
	DECLE 10,0
	;[32]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",32
	DECLE 63,0
	;[33]     MUSIC C3#,-,-,-
	SRCFILE "assets/music/canon_music.bas",33
	DECLE 14,0
	;[34]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",34
	DECLE 63,0
	;[35]     MUSIC F3#,-,-,-
	SRCFILE "assets/music/canon_music.bas",35
	DECLE 19,0
	;[36]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",36
	DECLE 63,0
	;[37] 
	SRCFILE "assets/music/canon_music.bas",37
	;[38]     MUSIC G2,-,-,-
	SRCFILE "assets/music/canon_music.bas",38
	DECLE 8,0
	;[39]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",39
	DECLE 63,0
	;[40]     MUSIC B2,-,-,-
	SRCFILE "assets/music/canon_music.bas",40
	DECLE 12,0
	;[41]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",41
	DECLE 63,0
	;[42]     MUSIC D3,-,-,-
	SRCFILE "assets/music/canon_music.bas",42
	DECLE 15,0
	;[43]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",43
	DECLE 63,0
	;[44]     MUSIC G3,-,-,-
	SRCFILE "assets/music/canon_music.bas",44
	DECLE 20,0
	;[45]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",45
	DECLE 63,0
	;[46]     MUSIC D2,-,-,-
	SRCFILE "assets/music/canon_music.bas",46
	DECLE 3,0
	;[47]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",47
	DECLE 63,0
	;[48]     MUSIC F2#,-,-,-
	SRCFILE "assets/music/canon_music.bas",48
	DECLE 7,0
	;[49]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",49
	DECLE 63,0
	;[50]     MUSIC A2,-,-,-
	SRCFILE "assets/music/canon_music.bas",50
	DECLE 10,0
	;[51]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",51
	DECLE 63,0
	;[52]     MUSIC D3,-,-,-
	SRCFILE "assets/music/canon_music.bas",52
	DECLE 15,0
	;[53]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",53
	DECLE 63,0
	;[54] 
	SRCFILE "assets/music/canon_music.bas",54
	;[55]     MUSIC G2,-,-,-
	SRCFILE "assets/music/canon_music.bas",55
	DECLE 8,0
	;[56]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",56
	DECLE 63,0
	;[57]     MUSIC B2,-,-,-
	SRCFILE "assets/music/canon_music.bas",57
	DECLE 12,0
	;[58]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",58
	DECLE 63,0
	;[59]     MUSIC D3,-,-,-
	SRCFILE "assets/music/canon_music.bas",59
	DECLE 15,0
	;[60]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",60
	DECLE 63,0
	;[61]     MUSIC G3,-,-,-
	SRCFILE "assets/music/canon_music.bas",61
	DECLE 20,0
	;[62]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",62
	DECLE 63,0
	;[63]     MUSIC A2,-,-,-
	SRCFILE "assets/music/canon_music.bas",63
	DECLE 10,0
	;[64]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",64
	DECLE 63,0
	;[65]     MUSIC C3#,-,-,-
	SRCFILE "assets/music/canon_music.bas",65
	DECLE 14,0
	;[66]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",66
	DECLE 63,0
	;[67]     MUSIC E3,-,-,-
	SRCFILE "assets/music/canon_music.bas",67
	DECLE 17,0
	;[68]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",68
	DECLE 63,0
	;[69]     MUSIC A3,-,-,-
	SRCFILE "assets/music/canon_music.bas",69
	DECLE 22,0
	;[70]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",70
	DECLE 63,0
	;[71] 
	SRCFILE "assets/music/canon_music.bas",71
	;[72]     MUSIC F5#,D3W,-,-
	SRCFILE "assets/music/canon_music.bas",72
	DECLE 3883,0
	;[73]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",73
	DECLE 16191,0
	;[74]     MUSIC S,F3#,-,-
	SRCFILE "assets/music/canon_music.bas",74
	DECLE 4927,0
	;[75]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",75
	DECLE 16191,0
	;[76]     MUSIC S,A3,-,-
	SRCFILE "assets/music/canon_music.bas",76
	DECLE 5695,0
	;[77]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",77
	DECLE 16191,0
	;[78]     MUSIC S,D4,-,-
	SRCFILE "assets/music/canon_music.bas",78
	DECLE 6975,0
	;[79]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",79
	DECLE 16191,0
	;[80]     MUSIC E5,A2,-,-
	SRCFILE "assets/music/canon_music.bas",80
	DECLE 2601,0
	;[81]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",81
	DECLE 16191,0
	;[82]     MUSIC S,C3#,-,-
	SRCFILE "assets/music/canon_music.bas",82
	DECLE 3647,0
	;[83]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",83
	DECLE 16191,0
	;[84]     MUSIC S,E3,-,-
	SRCFILE "assets/music/canon_music.bas",84
	DECLE 4415,0
	;[85]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",85
	DECLE 16191,0
	;[86]     MUSIC S,A3,-,-
	SRCFILE "assets/music/canon_music.bas",86
	DECLE 5695,0
	;[87]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",87
	DECLE 16191,0
	;[88] 
	SRCFILE "assets/music/canon_music.bas",88
	;[89]     MUSIC D5,B2,-,-
	SRCFILE "assets/music/canon_music.bas",89
	DECLE 3111,0
	;[90]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",90
	DECLE 16191,0
	;[91]     MUSIC S,D3,-,-
	SRCFILE "assets/music/canon_music.bas",91
	DECLE 3903,0
	;[92]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",92
	DECLE 16191,0
	;[93]     MUSIC S,F3#,-,-
	SRCFILE "assets/music/canon_music.bas",93
	DECLE 4927,0
	;[94]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",94
	DECLE 16191,0
	;[95]     MUSIC S,B3,-,-
	SRCFILE "assets/music/canon_music.bas",95
	DECLE 6207,0
	;[96]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",96
	DECLE 16191,0
	;[97]     MUSIC C5#,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",97
	DECLE 1830,0
	;[98]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",98
	DECLE 16191,0
	;[99]     MUSIC S,A2,-,-
	SRCFILE "assets/music/canon_music.bas",99
	DECLE 2623,0
	;[100]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",100
	DECLE 16191,0
	;[101]     MUSIC S,C3#,-,-
	SRCFILE "assets/music/canon_music.bas",101
	DECLE 3647,0
	;[102]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",102
	DECLE 16191,0
	;[103]     MUSIC S,F3#,-,-
	SRCFILE "assets/music/canon_music.bas",103
	DECLE 4927,0
	;[104]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",104
	DECLE 16191,0
	;[105] 
	SRCFILE "assets/music/canon_music.bas",105
	;[106]     MUSIC B4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",106
	DECLE 2084,0
	;[107]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",107
	DECLE 16191,0
	;[108]     MUSIC S,B2,-,-
	SRCFILE "assets/music/canon_music.bas",108
	DECLE 3135,0
	;[109]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",109
	DECLE 16191,0
	;[110]     MUSIC S,D3,-,-
	SRCFILE "assets/music/canon_music.bas",110
	DECLE 3903,0
	;[111]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",111
	DECLE 16191,0
	;[112]     MUSIC S,G3,-,-
	SRCFILE "assets/music/canon_music.bas",112
	DECLE 5183,0
	;[113]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",113
	DECLE 16191,0
	;[114]     MUSIC A4,D2,-,-
	SRCFILE "assets/music/canon_music.bas",114
	DECLE 802,0
	;[115]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",115
	DECLE 16191,0
	;[116]     MUSIC S,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",116
	DECLE 1855,0
	;[117]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",117
	DECLE 16191,0
	;[118]     MUSIC S,A2,-,-
	SRCFILE "assets/music/canon_music.bas",118
	DECLE 2623,0
	;[119]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",119
	DECLE 16191,0
	;[120]     MUSIC S,D3,-,-
	SRCFILE "assets/music/canon_music.bas",120
	DECLE 3903,0
	;[121]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",121
	DECLE 16191,0
	;[122] 
	SRCFILE "assets/music/canon_music.bas",122
	;[123]     MUSIC B4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",123
	DECLE 2084,0
	;[124]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",124
	DECLE 16191,0
	;[125]     MUSIC S,B2,-,-
	SRCFILE "assets/music/canon_music.bas",125
	DECLE 3135,0
	;[126]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",126
	DECLE 16191,0
	;[127]     MUSIC S,D3,-,-
	SRCFILE "assets/music/canon_music.bas",127
	DECLE 3903,0
	;[128]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",128
	DECLE 16191,0
	;[129]     MUSIC S,G3,-,-
	SRCFILE "assets/music/canon_music.bas",129
	DECLE 5183,0
	;[130]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",130
	DECLE 16191,0
	;[131]     MUSIC C5#,A2,-,-
	SRCFILE "assets/music/canon_music.bas",131
	DECLE 2598,0
	;[132]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",132
	DECLE 16191,0
	;[133]     MUSIC S,C3#,-,-
	SRCFILE "assets/music/canon_music.bas",133
	DECLE 3647,0
	;[134]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",134
	DECLE 16191,0
	;[135]     MUSIC S,E3,-,-
	SRCFILE "assets/music/canon_music.bas",135
	DECLE 4415,0
	;[136]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",136
	DECLE 16191,0
	;[137]     MUSIC S,A3,-,-
	SRCFILE "assets/music/canon_music.bas",137
	DECLE 5695,0
	;[138]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",138
	DECLE 16191,0
	;[139] 
	SRCFILE "assets/music/canon_music.bas",139
	;[140]     MUSIC D5,F5#,D3W,-
	SRCFILE "assets/music/canon_music.bas",140
	DECLE 11047,15
	;[141]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",141
	DECLE 16191,63
	;[142]     MUSIC S,S,F3#,-
	SRCFILE "assets/music/canon_music.bas",142
	DECLE 16191,19
	;[143]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",143
	DECLE 16191,63
	;[144]     MUSIC S,S,A3,-
	SRCFILE "assets/music/canon_music.bas",144
	DECLE 16191,22
	;[145]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",145
	DECLE 16191,63
	;[146]     MUSIC S,S,D4,-
	SRCFILE "assets/music/canon_music.bas",146
	DECLE 16191,27
	;[147]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",147
	DECLE 16191,63
	;[148]     MUSIC C5#,E5,A2,-
	SRCFILE "assets/music/canon_music.bas",148
	DECLE 10534,10
	;[149]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",149
	DECLE 16191,63
	;[150]     MUSIC S,S,C3#,-
	SRCFILE "assets/music/canon_music.bas",150
	DECLE 16191,14
	;[151]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",151
	DECLE 16191,63
	;[152]     MUSIC S,S,E3,-
	SRCFILE "assets/music/canon_music.bas",152
	DECLE 16191,17
	;[153]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",153
	DECLE 16191,63
	;[154]     MUSIC S,S,A3,-
	SRCFILE "assets/music/canon_music.bas",154
	DECLE 16191,22
	;[155]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",155
	DECLE 16191,63
	;[156] 
	SRCFILE "assets/music/canon_music.bas",156
	;[157]     MUSIC B4,D5,B2,-
	SRCFILE "assets/music/canon_music.bas",157
	DECLE 10020,12
	;[158]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",158
	DECLE 16191,63
	;[159]     MUSIC S,S,D3,-
	SRCFILE "assets/music/canon_music.bas",159
	DECLE 16191,15
	;[160]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",160
	DECLE 16191,63
	;[161]     MUSIC S,S,F3#,-
	SRCFILE "assets/music/canon_music.bas",161
	DECLE 16191,19
	;[162]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",162
	DECLE 16191,63
	;[163]     MUSIC S,S,B3,-
	SRCFILE "assets/music/canon_music.bas",163
	DECLE 16191,24
	;[164]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",164
	DECLE 16191,63
	;[165]     MUSIC A4,C5#,F2#,-
	SRCFILE "assets/music/canon_music.bas",165
	DECLE 9762,7
	;[166]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",166
	DECLE 16191,63
	;[167]     MUSIC S,S,A2,-
	SRCFILE "assets/music/canon_music.bas",167
	DECLE 16191,10
	;[168]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",168
	DECLE 16191,63
	;[169]     MUSIC S,S,C3#,-
	SRCFILE "assets/music/canon_music.bas",169
	DECLE 16191,14
	;[170]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",170
	DECLE 16191,63
	;[171]     MUSIC S,S,F3#,-
	SRCFILE "assets/music/canon_music.bas",171
	DECLE 16191,19
	;[172]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",172
	DECLE 16191,63
	;[173] 
	SRCFILE "assets/music/canon_music.bas",173
	;[174]     MUSIC G4,B4,G2,-
	SRCFILE "assets/music/canon_music.bas",174
	DECLE 9248,8
	;[175]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",175
	DECLE 16191,63
	;[176]     MUSIC S,S,B2,-
	SRCFILE "assets/music/canon_music.bas",176
	DECLE 16191,12
	;[177]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",177
	DECLE 16191,63
	;[178]     MUSIC S,S,D3,-
	SRCFILE "assets/music/canon_music.bas",178
	DECLE 16191,15
	;[179]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",179
	DECLE 16191,63
	;[180]     MUSIC S,S,G3,-
	SRCFILE "assets/music/canon_music.bas",180
	DECLE 16191,20
	;[181]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",181
	DECLE 16191,63
	;[182]     MUSIC F4#,A4,D2,-
	SRCFILE "assets/music/canon_music.bas",182
	DECLE 8735,3
	;[183]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",183
	DECLE 16191,63
	;[184]     MUSIC S,S,F2#,-
	SRCFILE "assets/music/canon_music.bas",184
	DECLE 16191,7
	;[185]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",185
	DECLE 16191,63
	;[186]     MUSIC S,S,A2,-
	SRCFILE "assets/music/canon_music.bas",186
	DECLE 16191,10
	;[187]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",187
	DECLE 16191,63
	;[188]     MUSIC S,S,D3,-
	SRCFILE "assets/music/canon_music.bas",188
	DECLE 16191,15
	;[189]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",189
	DECLE 16191,63
	;[190] 
	SRCFILE "assets/music/canon_music.bas",190
	;[191]     MUSIC G4,B4,G2,-
	SRCFILE "assets/music/canon_music.bas",191
	DECLE 9248,8
	;[192]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",192
	DECLE 16191,63
	;[193]     MUSIC S,S,B2,-
	SRCFILE "assets/music/canon_music.bas",193
	DECLE 16191,12
	;[194]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",194
	DECLE 16191,63
	;[195]     MUSIC S,S,D3,-
	SRCFILE "assets/music/canon_music.bas",195
	DECLE 16191,15
	;[196]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",196
	DECLE 16191,63
	;[197]     MUSIC S,S,G3,-
	SRCFILE "assets/music/canon_music.bas",197
	DECLE 16191,20
	;[198]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",198
	DECLE 16191,63
	;[199]     MUSIC A4,C5#,A2,-
	SRCFILE "assets/music/canon_music.bas",199
	DECLE 9762,10
	;[200]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",200
	DECLE 16191,63
	;[201]     MUSIC S,S,C3#,-
	SRCFILE "assets/music/canon_music.bas",201
	DECLE 16191,14
	;[202]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",202
	DECLE 16191,63
	;[203]     MUSIC S,S,E3,-
	SRCFILE "assets/music/canon_music.bas",203
	DECLE 16191,17
	;[204]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",204
	DECLE 16191,63
	;[205]     MUSIC S,S,A3,-
	SRCFILE "assets/music/canon_music.bas",205
	DECLE 16191,22
	;[206]     MUSIC S,S,S,-
	SRCFILE "assets/music/canon_music.bas",206
	DECLE 16191,63
	;[207] 
	SRCFILE "assets/music/canon_music.bas",207
	;[208]     MUSIC D4,D3,-,-
	SRCFILE "assets/music/canon_music.bas",208
	DECLE 3867,0
	;[209]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",209
	DECLE 16191,0
	;[210]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",210
	DECLE 16191,0
	;[211]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",211
	DECLE 16191,0
	;[212]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",212
	DECLE 16159,0
	;[213]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",213
	DECLE 16191,0
	;[214]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",214
	DECLE 16191,0
	;[215]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",215
	DECLE 16191,0
	;[216]     MUSIC A4,A2,-,-
	SRCFILE "assets/music/canon_music.bas",216
	DECLE 2594,0
	;[217]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",217
	DECLE 16191,0
	;[218]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",218
	DECLE 16191,0
	;[219]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",219
	DECLE 16191,0
	;[220]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",220
	DECLE 16160,0
	;[221]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",221
	DECLE 16191,0
	;[222]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",222
	DECLE 16191,0
	;[223]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",223
	DECLE 16191,0
	;[224] 
	SRCFILE "assets/music/canon_music.bas",224
	;[225]     MUSIC F4#,B2,-,-
	SRCFILE "assets/music/canon_music.bas",225
	DECLE 3103,0
	;[226]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",226
	DECLE 16191,0
	;[227]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",227
	DECLE 16191,0
	;[228]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",228
	DECLE 16191,0
	;[229]     MUSIC D4,S,-,-
	SRCFILE "assets/music/canon_music.bas",229
	DECLE 16155,0
	;[230]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",230
	DECLE 16191,0
	;[231]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",231
	DECLE 16191,0
	;[232]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",232
	DECLE 16191,0
	;[233]     MUSIC F4#,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",233
	DECLE 1823,0
	;[234]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",234
	DECLE 16191,0
	;[235]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",235
	DECLE 16191,0
	;[236]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",236
	DECLE 16191,0
	;[237]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",237
	DECLE 16157,0
	;[238]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",238
	DECLE 16191,0
	;[239]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",239
	DECLE 16191,0
	;[240]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",240
	DECLE 16191,0
	;[241] 
	SRCFILE "assets/music/canon_music.bas",241
	;[242]     MUSIC D4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",242
	DECLE 2075,0
	;[243]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",243
	DECLE 16191,0
	;[244]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",244
	DECLE 16191,0
	;[245]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",245
	DECLE 16191,0
	;[246]     MUSIC B3,S,-,-
	SRCFILE "assets/music/canon_music.bas",246
	DECLE 16152,0
	;[247]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",247
	DECLE 16191,0
	;[248]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",248
	DECLE 16191,0
	;[249]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",249
	DECLE 16191,0
	;[250]     MUSIC D4,D2,-,-
	SRCFILE "assets/music/canon_music.bas",250
	DECLE 795,0
	;[251]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",251
	DECLE 16191,0
	;[252]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",252
	DECLE 16191,0
	;[253]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",253
	DECLE 16191,0
	;[254]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",254
	DECLE 16162,0
	;[255]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",255
	DECLE 16191,0
	;[256]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",256
	DECLE 16191,0
	;[257]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",257
	DECLE 16191,0
	;[258] 
	SRCFILE "assets/music/canon_music.bas",258
	;[259]     MUSIC G4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",259
	DECLE 2080,0
	;[260]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",260
	DECLE 16191,0
	;[261]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",261
	DECLE 16191,0
	;[262]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",262
	DECLE 16191,0
	;[263]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",263
	DECLE 16164,0
	;[264]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",264
	DECLE 16191,0
	;[265]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",265
	DECLE 16191,0
	;[266]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",266
	DECLE 16191,0
	;[267]     MUSIC A4,A2,-,-
	SRCFILE "assets/music/canon_music.bas",267
	DECLE 2594,0
	;[268]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",268
	DECLE 16191,0
	;[269]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",269
	DECLE 16191,0
	;[270]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",270
	DECLE 16191,0
	;[271]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",271
	DECLE 16160,0
	;[272]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",272
	DECLE 16191,0
	;[273]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",273
	DECLE 16191,0
	;[274]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",274
	DECLE 16191,0
	;[275] 
	SRCFILE "assets/music/canon_music.bas",275
	;[276]     MUSIC F4#,D3,-,-
	SRCFILE "assets/music/canon_music.bas",276
	DECLE 3871,0
	;[277]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",277
	DECLE 16191,0
	;[278]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",278
	DECLE 16191,0
	;[279]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",279
	DECLE 16191,0
	;[280]     MUSIC D4,S,-,-
	SRCFILE "assets/music/canon_music.bas",280
	DECLE 16155,0
	;[281]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",281
	DECLE 16191,0
	;[282]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",282
	DECLE 16191,0
	;[283]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",283
	DECLE 16191,0
	;[284]     MUSIC E4,A2,-,-
	SRCFILE "assets/music/canon_music.bas",284
	DECLE 2589,0
	;[285]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",285
	DECLE 16191,0
	;[286]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",286
	DECLE 16191,0
	;[287]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",287
	DECLE 16191,0
	;[288]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",288
	DECLE 16166,0
	;[289]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",289
	DECLE 16191,0
	;[290]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",290
	DECLE 16191,0
	;[291]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",291
	DECLE 16191,0
	;[292] 
	SRCFILE "assets/music/canon_music.bas",292
	;[293]     MUSIC D5,B2,-,-
	SRCFILE "assets/music/canon_music.bas",293
	DECLE 3111,0
	;[294]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",294
	DECLE 16191,0
	;[295]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",295
	DECLE 16191,0
	;[296]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",296
	DECLE 16191,0
	;[297]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",297
	DECLE 16171,0
	;[298]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",298
	DECLE 16191,0
	;[299]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",299
	DECLE 16191,0
	;[300]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",300
	DECLE 16191,0
	;[301]     MUSIC A5,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",301
	DECLE 1838,0
	;[302]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",302
	DECLE 16191,0
	;[303]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",303
	DECLE 16191,0
	;[304]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",304
	DECLE 16191,0
	;[305]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",305
	DECLE 16162,0
	;[306]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",306
	DECLE 16191,0
	;[307]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",307
	DECLE 16191,0
	;[308]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",308
	DECLE 16191,0
	;[309] 
	SRCFILE "assets/music/canon_music.bas",309
	;[310]     MUSIC B4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",310
	DECLE 2084,0
	;[311]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",311
	DECLE 16191,0
	;[312]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",312
	DECLE 16191,0
	;[313]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",313
	DECLE 16191,0
	;[314]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",314
	DECLE 16160,0
	;[315]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",315
	DECLE 16191,0
	;[316]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",316
	DECLE 16191,0
	;[317]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",317
	DECLE 16191,0
	;[318]     MUSIC A4,D2,-,-
	SRCFILE "assets/music/canon_music.bas",318
	DECLE 802,0
	;[319]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",319
	DECLE 16191,0
	;[320]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",320
	DECLE 16191,0
	;[321]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",321
	DECLE 16191,0
	;[322]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",322
	DECLE 16159,0
	;[323]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",323
	DECLE 16191,0
	;[324]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",324
	DECLE 16191,0
	;[325]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",325
	DECLE 16191,0
	;[326] 
	SRCFILE "assets/music/canon_music.bas",326
	;[327]     MUSIC D4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",327
	DECLE 2075,0
	;[328]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",328
	DECLE 16191,0
	;[329]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",329
	DECLE 16191,0
	;[330]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",330
	DECLE 16191,0
	;[331]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",331
	DECLE 16167,0
	;[332]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",332
	DECLE 16191,0
	;[333]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",333
	DECLE 16191,0
	;[334]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",334
	DECLE 16191,0
	;[335]     MUSIC C5#,A2,-,-
	SRCFILE "assets/music/canon_music.bas",335
	DECLE 2598,0
	;[336]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",336
	DECLE 16191,0
	;[337]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",337
	DECLE 16191,0
	;[338]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",338
	DECLE 16191,0
	;[339]     MUSIC -,S,-,-
	SRCFILE "assets/music/canon_music.bas",339
	DECLE 16128,0
	;[340]     MUSIC -,S,-,-
	SRCFILE "assets/music/canon_music.bas",340
	DECLE 16128,0
	;[341]     MUSIC -,S,-,-
	SRCFILE "assets/music/canon_music.bas",341
	DECLE 16128,0
	;[342]     MUSIC -,S,-,-
	SRCFILE "assets/music/canon_music.bas",342
	DECLE 16128,0
	;[343] 
	SRCFILE "assets/music/canon_music.bas",343
	;[344]     MUSIC D5,D3,-,-
	SRCFILE "assets/music/canon_music.bas",344
	DECLE 3879,0
	;[345]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",345
	DECLE 16191,0
	;[346]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",346
	DECLE 16166,0
	;[347]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",347
	DECLE 16191,0
	;[348]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",348
	DECLE 16167,0
	;[349]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",349
	DECLE 16191,0
	;[350]     MUSIC D4,S,-,-
	SRCFILE "assets/music/canon_music.bas",350
	DECLE 16155,0
	;[351]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",351
	DECLE 16191,0
	;[352]     MUSIC C4#,A2,-,-
	SRCFILE "assets/music/canon_music.bas",352
	DECLE 2586,0
	;[353]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",353
	DECLE 16191,0
	;[354]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",354
	DECLE 16162,0
	;[355]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",355
	DECLE 16191,0
	;[356]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",356
	DECLE 16157,0
	;[357]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",357
	DECLE 16191,0
	;[358]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",358
	DECLE 16159,0
	;[359]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",359
	DECLE 16191,0
	;[360] 
	SRCFILE "assets/music/canon_music.bas",360
	;[361]     MUSIC D4,B2,-,-
	SRCFILE "assets/music/canon_music.bas",361
	DECLE 3099,0
	;[362]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",362
	DECLE 16191,0
	;[363]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",363
	DECLE 16167,0
	;[364]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",364
	DECLE 16191,0
	;[365]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",365
	DECLE 16166,0
	;[366]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",366
	DECLE 16191,0
	;[367]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",367
	DECLE 16164,0
	;[368]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",368
	DECLE 16191,0
	;[369]     MUSIC C5#,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",369
	DECLE 1830,0
	;[370]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",370
	DECLE 16191,0
	;[371]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",371
	DECLE 16171,0
	;[372]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",372
	DECLE 16191,0
	;[373]     MUSIC A5,S,-,-
	SRCFILE "assets/music/canon_music.bas",373
	DECLE 16174,0
	;[374]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",374
	DECLE 16191,0
	;[375]     MUSIC B5,S,-,-
	SRCFILE "assets/music/canon_music.bas",375
	DECLE 16176,0
	;[376]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",376
	DECLE 16191,0
	;[377] 
	SRCFILE "assets/music/canon_music.bas",377
	;[378]     MUSIC G5,G2,-,-
	SRCFILE "assets/music/canon_music.bas",378
	DECLE 2092,0
	;[379]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",379
	DECLE 16191,0
	;[380]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",380
	DECLE 16171,0
	;[381]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",381
	DECLE 16191,0
	;[382]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",382
	DECLE 16169,0
	;[383]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",383
	DECLE 16191,0
	;[384]     MUSIC G5,S,-,-
	SRCFILE "assets/music/canon_music.bas",384
	DECLE 16172,0
	;[385]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",385
	DECLE 16191,0
	;[386]     MUSIC F5#,D2,-,-
	SRCFILE "assets/music/canon_music.bas",386
	DECLE 811,0
	;[387]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",387
	DECLE 16191,0
	;[388]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",388
	DECLE 16169,0
	;[389]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",389
	DECLE 16191,0
	;[390]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",390
	DECLE 16167,0
	;[391]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",391
	DECLE 16191,0
	;[392]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",392
	DECLE 16166,0
	;[393]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",393
	DECLE 16191,0
	;[394] 
	SRCFILE "assets/music/canon_music.bas",394
	;[395]     MUSIC B4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",395
	DECLE 2084,0
	;[396]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",396
	DECLE 16191,0
	;[397]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",397
	DECLE 16162,0
	;[398]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",398
	DECLE 16191,0
	;[399]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",399
	DECLE 16160,0
	;[400]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",400
	DECLE 16191,0
	;[401]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",401
	DECLE 16159,0
	;[402]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",402
	DECLE 16191,0
	;[403]     MUSIC E4,A2,-,-
	SRCFILE "assets/music/canon_music.bas",403
	DECLE 2589,0
	;[404]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",404
	DECLE 16191,0
	;[405]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",405
	DECLE 16160,0
	;[406]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",406
	DECLE 16191,0
	;[407]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",407
	DECLE 16159,0
	;[408]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",408
	DECLE 16191,0
	;[409]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",409
	DECLE 16157,0
	;[410]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",410
	DECLE 16191,0
	;[411] 
	SRCFILE "assets/music/canon_music.bas",411
	;[412]     MUSIC D4,D3,-,-
	SRCFILE "assets/music/canon_music.bas",412
	DECLE 3867,0
	;[413]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",413
	DECLE 16191,0
	;[414]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",414
	DECLE 16157,0
	;[415]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",415
	DECLE 16191,0
	;[416]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",416
	DECLE 16159,0
	;[417]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",417
	DECLE 16191,0
	;[418]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",418
	DECLE 16160,0
	;[419]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",419
	DECLE 16191,0
	;[420]     MUSIC A4,A2,-,-
	SRCFILE "assets/music/canon_music.bas",420
	DECLE 2594,0
	;[421]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",421
	DECLE 16191,0
	;[422]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",422
	DECLE 16157,0
	;[423]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",423
	DECLE 16191,0
	;[424]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",424
	DECLE 16162,0
	;[425]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",425
	DECLE 16191,0
	;[426]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",426
	DECLE 16160,0
	;[427]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",427
	DECLE 16191,0
	;[428] 
	SRCFILE "assets/music/canon_music.bas",428
	;[429]     MUSIC F4#,B2,-,-
	SRCFILE "assets/music/canon_music.bas",429
	DECLE 3103,0
	;[430]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",430
	DECLE 16191,0
	;[431]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",431
	DECLE 16164,0
	;[432]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",432
	DECLE 16191,0
	;[433]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",433
	DECLE 16162,0
	;[434]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",434
	DECLE 16191,0
	;[435]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",435
	DECLE 16160,0
	;[436]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",436
	DECLE 16191,0
	;[437]     MUSIC A4,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",437
	DECLE 1826,0
	;[438]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",438
	DECLE 16191,0
	;[439]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",439
	DECLE 16160,0
	;[440]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",440
	DECLE 16191,0
	;[441]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",441
	DECLE 16159,0
	;[442]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",442
	DECLE 16191,0
	;[443]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",443
	DECLE 16157,0
	;[444]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",444
	DECLE 16191,0
	;[445] 
	SRCFILE "assets/music/canon_music.bas",445
	;[446]     MUSIC D4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",446
	DECLE 2075,0
	;[447]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",447
	DECLE 16191,0
	;[448]     MUSIC B3,S,-,-
	SRCFILE "assets/music/canon_music.bas",448
	DECLE 16152,0
	;[449]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",449
	DECLE 16191,0
	;[450]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",450
	DECLE 16164,0
	;[451]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",451
	DECLE 16191,0
	;[452]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",452
	DECLE 16166,0
	;[453]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",453
	DECLE 16191,0
	;[454]     MUSIC D5,D2,-,-
	SRCFILE "assets/music/canon_music.bas",454
	DECLE 807,0
	;[455]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",455
	DECLE 16191,0
	;[456]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",456
	DECLE 16166,0
	;[457]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",457
	DECLE 16191,0
	;[458]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",458
	DECLE 16164,0
	;[459]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",459
	DECLE 16191,0
	;[460]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",460
	DECLE 16162,0
	;[461]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",461
	DECLE 16191,0
	;[462] 
	SRCFILE "assets/music/canon_music.bas",462
	;[463]     MUSIC G4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",463
	DECLE 2080,0
	;[464]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",464
	DECLE 16191,0
	;[465]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",465
	DECLE 16159,0
	;[466]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",466
	DECLE 16191,0
	;[467]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",467
	DECLE 16157,0
	;[468]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",468
	DECLE 16191,0
	;[469]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",469
	DECLE 16164,0
	;[470]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",470
	DECLE 16191,0
	;[471]     MUSIC A4,A2,-,-
	SRCFILE "assets/music/canon_music.bas",471
	DECLE 2594,0
	;[472]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",472
	DECLE 16191,0
	;[473]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",473
	DECLE 16164,0
	;[474]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",474
	DECLE 16191,0
	;[475]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",475
	DECLE 16162,0
	;[476]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",476
	DECLE 16191,0
	;[477]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",477
	DECLE 16160,0
	;[478]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",478
	DECLE 16191,0
	;[479] 
	SRCFILE "assets/music/canon_music.bas",479
	;[480]     MUSIC F4#,D3,-,-
	SRCFILE "assets/music/canon_music.bas",480
	DECLE 3871,0
	;[481]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",481
	DECLE 16191,0
	;[482]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",482
	DECLE 16191,0
	;[483]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",483
	DECLE 16191,0
	;[484]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",484
	DECLE 16171,0
	;[485]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",485
	DECLE 16191,0
	;[486]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",486
	DECLE 16191,0
	;[487]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",487
	DECLE 16191,0
	;[488]     MUSIC E5,A2,-,-
	SRCFILE "assets/music/canon_music.bas",488
	DECLE 2601,0
	;[489]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",489
	DECLE 16191,0
	;[490]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",490
	DECLE 16191,0
	;[491]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",491
	DECLE 16191,0
	;[492]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",492
	DECLE 16191,0
	;[493]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",493
	DECLE 16191,0
	;[494]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",494
	DECLE 16191,0
	;[495]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",495
	DECLE 16191,0
	;[496] 
	SRCFILE "assets/music/canon_music.bas",496
	;[497]     MUSIC B2,-,-,-
	SRCFILE "assets/music/canon_music.bas",497
	DECLE 12,0
	;[498]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",498
	DECLE 63,0
	;[499]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",499
	DECLE 63,0
	;[500]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",500
	DECLE 63,0
	;[501]     MUSIC S,D5,-,-
	SRCFILE "assets/music/canon_music.bas",501
	DECLE 10047,0
	;[502]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",502
	DECLE 16191,0
	;[503]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",503
	DECLE 16191,0
	;[504]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",504
	DECLE 16191,0
	;[505]     MUSIC F5#,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",505
	DECLE 1835,0
	;[506]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",506
	DECLE 16191,0
	;[507]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",507
	DECLE 16191,0
	;[508]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",508
	DECLE 16191,0
	;[509]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",509
	DECLE 16191,0
	;[510]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",510
	DECLE 16191,0
	;[511]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",511
	DECLE 16191,0
	;[512]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",512
	DECLE 16191,0
	;[513] 
	SRCFILE "assets/music/canon_music.bas",513
	;[514]     MUSIC B5,G2,-,-
	SRCFILE "assets/music/canon_music.bas",514
	DECLE 2096,0
	;[515]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",515
	DECLE 16191,0
	;[516]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",516
	DECLE 16191,0
	;[517]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",517
	DECLE 16191,0
	;[518]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",518
	DECLE 16191,0
	;[519]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",519
	DECLE 16191,0
	;[520]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",520
	DECLE 16191,0
	;[521]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",521
	DECLE 16191,0
	;[522]     MUSIC A5,D2,-,-
	SRCFILE "assets/music/canon_music.bas",522
	DECLE 814,0
	;[523]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",523
	DECLE 16191,0
	;[524]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",524
	DECLE 16191,0
	;[525]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",525
	DECLE 16191,0
	;[526]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",526
	DECLE 16191,0
	;[527]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",527
	DECLE 16191,0
	;[528]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",528
	DECLE 16191,0
	;[529]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",529
	DECLE 16191,0
	;[530] 
	SRCFILE "assets/music/canon_music.bas",530
	;[531]     MUSIC B5,G2,-,-
	SRCFILE "assets/music/canon_music.bas",531
	DECLE 2096,0
	;[532]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",532
	DECLE 16191,0
	;[533]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",533
	DECLE 16191,0
	;[534]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",534
	DECLE 16191,0
	;[535]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",535
	DECLE 16191,0
	;[536]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",536
	DECLE 16191,0
	;[537]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",537
	DECLE 16191,0
	;[538]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",538
	DECLE 16191,0
	;[539]     MUSIC C6#,A2,-,-
	SRCFILE "assets/music/canon_music.bas",539
	DECLE 2610,0
	;[540]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",540
	DECLE 16191,0
	;[541]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",541
	DECLE 16191,0
	;[542]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",542
	DECLE 16191,0
	;[543]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",543
	DECLE 16191,0
	;[544]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",544
	DECLE 16191,0
	;[545]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",545
	DECLE 16191,0
	;[546]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",546
	DECLE 16191,0
	;[547] 
	SRCFILE "assets/music/canon_music.bas",547
	;[548]     MUSIC D6,D3,-,-
	SRCFILE "assets/music/canon_music.bas",548
	DECLE 3891,0
	;[549]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",549
	DECLE 16191,0
	;[550]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",550
	DECLE 16191,0
	;[551]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",551
	DECLE 16191,0
	;[552]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",552
	DECLE 16167,0
	;[553]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",553
	DECLE 16191,0
	;[554]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",554
	DECLE 16191,0
	;[555]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",555
	DECLE 16191,0
	;[556]     MUSIC C5#,A2,-,-
	SRCFILE "assets/music/canon_music.bas",556
	DECLE 2598,0
	;[557]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",557
	DECLE 16191,0
	;[558]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",558
	DECLE 16191,0
	;[559]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",559
	DECLE 16191,0
	;[560]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",560
	DECLE 16191,0
	;[561]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",561
	DECLE 16191,0
	;[562]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",562
	DECLE 16191,0
	;[563]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",563
	DECLE 16191,0
	;[564] 
	SRCFILE "assets/music/canon_music.bas",564
	;[565]     MUSIC B2,-,-,-
	SRCFILE "assets/music/canon_music.bas",565
	DECLE 12,0
	;[566]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",566
	DECLE 63,0
	;[567]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",567
	DECLE 63,0
	;[568]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",568
	DECLE 63,0
	;[569]     MUSIC S,B4,-,-
	SRCFILE "assets/music/canon_music.bas",569
	DECLE 9279,0
	;[570]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",570
	DECLE 16191,0
	;[571]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",571
	DECLE 16191,0
	;[572]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",572
	DECLE 16191,0
	;[573]     MUSIC D5,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",573
	DECLE 1831,0
	;[574]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",574
	DECLE 16191,0
	;[575]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",575
	DECLE 16191,0
	;[576]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",576
	DECLE 16191,0
	;[577]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",577
	DECLE 16191,0
	;[578]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",578
	DECLE 16191,0
	;[579]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",579
	DECLE 16191,0
	;[580]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",580
	DECLE 16191,0
	;[581] 
	SRCFILE "assets/music/canon_music.bas",581
	;[582]     MUSIC D5,G2,-,-
	SRCFILE "assets/music/canon_music.bas",582
	DECLE 2087,0
	;[583]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",583
	DECLE 16191,0
	;[584]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",584
	DECLE 16191,0
	;[585]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",585
	DECLE 16191,0
	;[586]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",586
	DECLE 16191,0
	;[587]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",587
	DECLE 16191,0
	;[588]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",588
	DECLE 16191,0
	;[589]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",589
	DECLE 16191,0
	;[590]     MUSIC D2,-,-,-
	SRCFILE "assets/music/canon_music.bas",590
	DECLE 3,0
	;[591]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",591
	DECLE 63,0
	;[592]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",592
	DECLE 63,0
	;[593]     MUSIC S,-,-,-
	SRCFILE "assets/music/canon_music.bas",593
	DECLE 63,0
	;[594]     MUSIC S,D5,-,-
	SRCFILE "assets/music/canon_music.bas",594
	DECLE 10047,0
	;[595]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",595
	DECLE 16191,0
	;[596]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",596
	DECLE 16191,0
	;[597]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",597
	DECLE 16191,0
	;[598] 
	SRCFILE "assets/music/canon_music.bas",598
	;[599]     MUSIC D5,G2,-,-
	SRCFILE "assets/music/canon_music.bas",599
	DECLE 2087,0
	;[600]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",600
	DECLE 16191,0
	;[601]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",601
	DECLE 16191,0
	;[602]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",602
	DECLE 16191,0
	;[603]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",603
	DECLE 16171,0
	;[604]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",604
	DECLE 16191,0
	;[605]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",605
	DECLE 16191,0
	;[606]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",606
	DECLE 16191,0
	;[607]     MUSIC E5,A2,-,-
	SRCFILE "assets/music/canon_music.bas",607
	DECLE 2601,0
	;[608]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",608
	DECLE 16191,0
	;[609]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",609
	DECLE 16191,0
	;[610]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",610
	DECLE 16191,0
	;[611]     MUSIC A5,S,-,-
	SRCFILE "assets/music/canon_music.bas",611
	DECLE 16174,0
	;[612]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",612
	DECLE 16191,0
	;[613]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",613
	DECLE 16191,0
	;[614]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",614
	DECLE 16191,0
	;[615] 
	SRCFILE "assets/music/canon_music.bas",615
	;[616]     MUSIC A5,D3,-,-
	SRCFILE "assets/music/canon_music.bas",616
	DECLE 3886,0
	;[617]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",617
	DECLE 16191,0
	;[618]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",618
	DECLE 16171,0
	;[619]     MUSIC G5,S,-,-
	SRCFILE "assets/music/canon_music.bas",619
	DECLE 16172,0
	;[620]     MUSIC A5,S,-,-
	SRCFILE "assets/music/canon_music.bas",620
	DECLE 16174,0
	;[621]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",621
	DECLE 16191,0
	;[622]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",622
	DECLE 16171,0
	;[623]     MUSIC G5,S,-,-
	SRCFILE "assets/music/canon_music.bas",623
	DECLE 16172,0
	;[624]     MUSIC A5,A2,-,-
	SRCFILE "assets/music/canon_music.bas",624
	DECLE 2606,0
	;[625]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",625
	DECLE 16162,0
	;[626]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",626
	DECLE 16164,0
	;[627]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",627
	DECLE 16166,0
	;[628]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",628
	DECLE 16167,0
	;[629]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",629
	DECLE 16169,0
	;[630]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",630
	DECLE 16171,0
	;[631]     MUSIC G5,S,-,-
	SRCFILE "assets/music/canon_music.bas",631
	DECLE 16172,0
	;[632] 
	SRCFILE "assets/music/canon_music.bas",632
	;[633]     MUSIC F5#,B2,-,-
	SRCFILE "assets/music/canon_music.bas",633
	DECLE 3115,0
	;[634]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",634
	DECLE 16191,0
	;[635]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",635
	DECLE 16167,0
	;[636]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",636
	DECLE 16169,0
	;[637]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",637
	DECLE 16171,0
	;[638]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",638
	DECLE 16191,0
	;[639]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",639
	DECLE 16159,0
	;[640]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",640
	DECLE 16160,0
	;[641]     MUSIC A4,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",641
	DECLE 1826,0
	;[642]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",642
	DECLE 16164,0
	;[643]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",643
	DECLE 16162,0
	;[644]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",644
	DECLE 16160,0
	;[645]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",645
	DECLE 16162,0
	;[646]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",646
	DECLE 16159,0
	;[647]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",647
	DECLE 16160,0
	;[648]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",648
	DECLE 16162,0
	;[649] 
	SRCFILE "assets/music/canon_music.bas",649
	;[650]     MUSIC G4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",650
	DECLE 2080,0
	;[651]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",651
	DECLE 16191,0
	;[652]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",652
	DECLE 16164,0
	;[653]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",653
	DECLE 16162,0
	;[654]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",654
	DECLE 16160,0
	;[655]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",655
	DECLE 16191,0
	;[656]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",656
	DECLE 16159,0
	;[657]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",657
	DECLE 16157,0
	;[658]     MUSIC F4#,D2,-,-
	SRCFILE "assets/music/canon_music.bas",658
	DECLE 799,0
	;[659]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",659
	DECLE 16157,0
	;[660]     MUSIC D4,S,-,-
	SRCFILE "assets/music/canon_music.bas",660
	DECLE 16155,0
	;[661]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",661
	DECLE 16157,0
	;[662]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",662
	DECLE 16159,0
	;[663]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",663
	DECLE 16160,0
	;[664]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",664
	DECLE 16162,0
	;[665]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",665
	DECLE 16164,0
	;[666] 
	SRCFILE "assets/music/canon_music.bas",666
	;[667]     MUSIC G4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",667
	DECLE 2080,0
	;[668]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",668
	DECLE 16191,0
	;[669]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",669
	DECLE 16164,0
	;[670]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",670
	DECLE 16162,0
	;[671]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",671
	DECLE 16164,0
	;[672]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",672
	DECLE 16191,0
	;[673]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",673
	DECLE 16166,0
	;[674]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",674
	DECLE 16167,0
	;[675]     MUSIC A4,A2,-,-
	SRCFILE "assets/music/canon_music.bas",675
	DECLE 2594,0
	;[676]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",676
	DECLE 16164,0
	;[677]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",677
	DECLE 16166,0
	;[678]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",678
	DECLE 16167,0
	;[679]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",679
	DECLE 16169,0
	;[680]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",680
	DECLE 16171,0
	;[681]     MUSIC G5,S,-,-
	SRCFILE "assets/music/canon_music.bas",681
	DECLE 16172,0
	;[682]     MUSIC A5,S,-,-
	SRCFILE "assets/music/canon_music.bas",682
	DECLE 16174,0
	;[683] 
	SRCFILE "assets/music/canon_music.bas",683
	;[684]     MUSIC F5#,D3,-,-
	SRCFILE "assets/music/canon_music.bas",684
	DECLE 3883,0
	;[685]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",685
	DECLE 16191,0
	;[686]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",686
	DECLE 16167,0
	;[687]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",687
	DECLE 16169,0
	;[688]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",688
	DECLE 16171,0
	;[689]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",689
	DECLE 16191,0
	;[690]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",690
	DECLE 16169,0
	;[691]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",691
	DECLE 16167,0
	;[692]     MUSIC E5,A2,-,-
	SRCFILE "assets/music/canon_music.bas",692
	DECLE 2601,0
	;[693]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",693
	DECLE 16166,0
	;[694]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",694
	DECLE 16167,0
	;[695]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",695
	DECLE 16169,0
	;[696]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",696
	DECLE 16171,0
	;[697]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",697
	DECLE 16169,0
	;[698]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",698
	DECLE 16167,0
	;[699]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",699
	DECLE 16166,0
	;[700] 
	SRCFILE "assets/music/canon_music.bas",700
	;[701]     MUSIC D5,B2,-,-
	SRCFILE "assets/music/canon_music.bas",701
	DECLE 3111,0
	;[702]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",702
	DECLE 16191,0
	;[703]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",703
	DECLE 16164,0
	;[704]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",704
	DECLE 16166,0
	;[705]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",705
	DECLE 16167,0
	;[706]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",706
	DECLE 16191,0
	;[707]     MUSIC D4,S,-,-
	SRCFILE "assets/music/canon_music.bas",707
	DECLE 16155,0
	;[708]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",708
	DECLE 16157,0
	;[709]     MUSIC F4#,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",709
	DECLE 1823,0
	;[710]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",710
	DECLE 16160,0
	;[711]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",711
	DECLE 16159,0
	;[712]     MUSIC E4,S,-,-
	SRCFILE "assets/music/canon_music.bas",712
	DECLE 16157,0
	;[713]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",713
	DECLE 16159,0
	;[714]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",714
	DECLE 16167,0
	;[715]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",715
	DECLE 16166,0
	;[716]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",716
	DECLE 16167,0
	;[717] 
	SRCFILE "assets/music/canon_music.bas",717
	;[718]     MUSIC B4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",718
	DECLE 2084,0
	;[719]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",719
	DECLE 16191,0
	;[720]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",720
	DECLE 16167,0
	;[721]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",721
	DECLE 16166,0
	;[722]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",722
	DECLE 16164,0
	;[723]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",723
	DECLE 16191,0
	;[724]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",724
	DECLE 16162,0
	;[725]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",725
	DECLE 16160,0
	;[726]     MUSIC A4,D2,-,-
	SRCFILE "assets/music/canon_music.bas",726
	DECLE 802,0
	;[727]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",727
	DECLE 16160,0
	;[728]     MUSIC F4#,S,-,-
	SRCFILE "assets/music/canon_music.bas",728
	DECLE 16159,0
	;[729]     MUSIC G4,S,-,-
	SRCFILE "assets/music/canon_music.bas",729
	DECLE 16160,0
	;[730]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",730
	DECLE 16162,0
	;[731]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",731
	DECLE 16164,0
	;[732]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",732
	DECLE 16166,0
	;[733]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",733
	DECLE 16167,0
	;[734] 
	SRCFILE "assets/music/canon_music.bas",734
	;[735]     MUSIC B4,G2,-,-
	SRCFILE "assets/music/canon_music.bas",735
	DECLE 2084,0
	;[736]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",736
	DECLE 16191,0
	;[737]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",737
	DECLE 16167,0
	;[738]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",738
	DECLE 16166,0
	;[739]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",739
	DECLE 16167,0
	;[740]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",740
	DECLE 16191,0
	;[741]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",741
	DECLE 16166,0
	;[742]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",742
	DECLE 16164,0
	;[743]     MUSIC C5#,A2,-,-
	SRCFILE "assets/music/canon_music.bas",743
	DECLE 2598,0
	;[744]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",744
	DECLE 16167,0
	;[745]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",745
	DECLE 16169,0
	;[746]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",746
	DECLE 16167,0
	;[747]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",747
	DECLE 16166,0
	;[748]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",748
	DECLE 16167,0
	;[749]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",749
	DECLE 16164,0
	;[750]     MUSIC C5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",750
	DECLE 16166,0
	;[751] 
	SRCFILE "assets/music/canon_music.bas",751
	;[752]     MUSIC D5,D3,-,-
	SRCFILE "assets/music/canon_music.bas",752
	DECLE 3879,0
	;[753]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",753
	DECLE 16191,0
	;[754]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",754
	DECLE 16191,0
	;[755]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",755
	DECLE 16191,0
	;[756]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",756
	DECLE 16191,0
	;[757]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",757
	DECLE 16191,0
	;[758]     MUSIC A5,S,-,-
	SRCFILE "assets/music/canon_music.bas",758
	DECLE 16174,0
	;[759]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",759
	DECLE 16191,0
	;[760]     MUSIC A5,A2,-,-
	SRCFILE "assets/music/canon_music.bas",760
	DECLE 2606,0
	;[761]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",761
	DECLE 16191,0
	;[762]     MUSIC B5,S,-,-
	SRCFILE "assets/music/canon_music.bas",762
	DECLE 16176,0
	;[763]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",763
	DECLE 16191,0
	;[764]     MUSIC A5,S,-,-
	SRCFILE "assets/music/canon_music.bas",764
	DECLE 16174,0
	;[765]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",765
	DECLE 16191,0
	;[766]     MUSIC G5,S,-,-
	SRCFILE "assets/music/canon_music.bas",766
	DECLE 16172,0
	;[767]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",767
	DECLE 16191,0
	;[768] 
	SRCFILE "assets/music/canon_music.bas",768
	;[769]     MUSIC F5#,B2,-,-
	SRCFILE "assets/music/canon_music.bas",769
	DECLE 3115,0
	;[770]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",770
	DECLE 16191,0
	;[771]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",771
	DECLE 16191,0
	;[772]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",772
	DECLE 16191,0
	;[773]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",773
	DECLE 16191,0
	;[774]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",774
	DECLE 16191,0
	;[775]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",775
	DECLE 16171,0
	;[776]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",776
	DECLE 16191,0
	;[777]     MUSIC F5#,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",777
	DECLE 1835,0
	;[778]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",778
	DECLE 16191,0
	;[779]     MUSIC G5,S,-,-
	SRCFILE "assets/music/canon_music.bas",779
	DECLE 16172,0
	;[780]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",780
	DECLE 16191,0
	;[781]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",781
	DECLE 16171,0
	;[782]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",782
	DECLE 16191,0
	;[783]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",783
	DECLE 16169,0
	;[784]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",784
	DECLE 16191,0
	;[785] 
	SRCFILE "assets/music/canon_music.bas",785
	;[786]     MUSIC D5,G2,-,-
	SRCFILE "assets/music/canon_music.bas",786
	DECLE 2087,0
	;[787]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",787
	DECLE 16191,0
	;[788]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",788
	DECLE 16191,0
	;[789]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",789
	DECLE 16191,0
	;[790]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",790
	DECLE 16191,0
	;[791]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",791
	DECLE 16191,0
	;[792]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",792
	DECLE 16167,0
	;[793]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",793
	DECLE 16191,0
	;[794]     MUSIC D5,D2,-,-
	SRCFILE "assets/music/canon_music.bas",794
	DECLE 807,0
	;[795]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",795
	DECLE 16191,0
	;[796]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",796
	DECLE 16191,0
	;[797]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",797
	DECLE 16191,0
	;[798]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",798
	DECLE 16162,0
	;[799]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",799
	DECLE 16191,0
	;[800]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",800
	DECLE 16191,0
	;[801]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",801
	DECLE 16191,0
	;[802] 
	SRCFILE "assets/music/canon_music.bas",802
	;[803]     MUSIC D5,G2,-,-
	SRCFILE "assets/music/canon_music.bas",803
	DECLE 2087,0
	;[804]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",804
	DECLE 16191,0
	;[805]     MUSIC C5,S,-,-
	SRCFILE "assets/music/canon_music.bas",805
	DECLE 16165,0
	;[806]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",806
	DECLE 16191,0
	;[807]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",807
	DECLE 16164,0
	;[808]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",808
	DECLE 16191,0
	;[809]     MUSIC C5,S,-,-
	SRCFILE "assets/music/canon_music.bas",809
	DECLE 16165,0
	;[810]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",810
	DECLE 16191,0
	;[811]     MUSIC C5#,A2,-,-
	SRCFILE "assets/music/canon_music.bas",811
	DECLE 2598,0
	;[812]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",812
	DECLE 16191,0
	;[813]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",813
	DECLE 16191,0
	;[814]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",814
	DECLE 16191,0
	;[815]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",815
	DECLE 16191,0
	;[816]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",816
	DECLE 16191,0
	;[817]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",817
	DECLE 16191,0
	;[818]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",818
	DECLE 16191,0
	;[819] 
	SRCFILE "assets/music/canon_music.bas",819
	;[820]     MUSIC D5,D3,-,-
	SRCFILE "assets/music/canon_music.bas",820
	DECLE 3879,0
	;[821]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",821
	DECLE 16191,0
	;[822]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",822
	DECLE 16191,0
	;[823]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",823
	DECLE 16191,0
	;[824]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",824
	DECLE 16191,0
	;[825]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",825
	DECLE 16191,0
	;[826]     MUSIC A5,S,-,-
	SRCFILE "assets/music/canon_music.bas",826
	DECLE 16174,0
	;[827]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",827
	DECLE 16191,0
	;[828]     MUSIC A5,A2,-,-
	SRCFILE "assets/music/canon_music.bas",828
	DECLE 2606,0
	;[829]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",829
	DECLE 16191,0
	;[830]     MUSIC B5,S,-,-
	SRCFILE "assets/music/canon_music.bas",830
	DECLE 16176,0
	;[831]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",831
	DECLE 16191,0
	;[832]     MUSIC A5,S,-,-
	SRCFILE "assets/music/canon_music.bas",832
	DECLE 16174,0
	;[833]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",833
	DECLE 16191,0
	;[834]     MUSIC G5,S,-,-
	SRCFILE "assets/music/canon_music.bas",834
	DECLE 16172,0
	;[835]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",835
	DECLE 16191,0
	;[836] 
	SRCFILE "assets/music/canon_music.bas",836
	;[837]     MUSIC F5#,B2,-,-
	SRCFILE "assets/music/canon_music.bas",837
	DECLE 3115,0
	;[838]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",838
	DECLE 16191,0
	;[839]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",839
	DECLE 16191,0
	;[840]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",840
	DECLE 16191,0
	;[841]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",841
	DECLE 16191,0
	;[842]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",842
	DECLE 16191,0
	;[843]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",843
	DECLE 16171,0
	;[844]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",844
	DECLE 16191,0
	;[845]     MUSIC F5#,F2#,-,-
	SRCFILE "assets/music/canon_music.bas",845
	DECLE 1835,0
	;[846]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",846
	DECLE 16191,0
	;[847]     MUSIC G5,S,-,-
	SRCFILE "assets/music/canon_music.bas",847
	DECLE 16172,0
	;[848]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",848
	DECLE 16191,0
	;[849]     MUSIC F5#,S,-,-
	SRCFILE "assets/music/canon_music.bas",849
	DECLE 16171,0
	;[850]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",850
	DECLE 16191,0
	;[851]     MUSIC E5,S,-,-
	SRCFILE "assets/music/canon_music.bas",851
	DECLE 16169,0
	;[852]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",852
	DECLE 16191,0
	;[853] 
	SRCFILE "assets/music/canon_music.bas",853
	;[854]     MUSIC D5,G2,-,-
	SRCFILE "assets/music/canon_music.bas",854
	DECLE 2087,0
	;[855]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",855
	DECLE 16191,0
	;[856]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",856
	DECLE 16191,0
	;[857]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",857
	DECLE 16191,0
	;[858]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",858
	DECLE 16191,0
	;[859]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",859
	DECLE 16191,0
	;[860]     MUSIC D5,S,-,-
	SRCFILE "assets/music/canon_music.bas",860
	DECLE 16167,0
	;[861]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",861
	DECLE 16191,0
	;[862]     MUSIC D5,D2,-,-
	SRCFILE "assets/music/canon_music.bas",862
	DECLE 807,0
	;[863]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",863
	DECLE 16191,0
	;[864]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",864
	DECLE 16191,0
	;[865]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",865
	DECLE 16191,0
	;[866]     MUSIC A4,S,-,-
	SRCFILE "assets/music/canon_music.bas",866
	DECLE 16162,0
	;[867]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",867
	DECLE 16191,0
	;[868]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",868
	DECLE 16191,0
	;[869]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",869
	DECLE 16191,0
	;[870] 
	SRCFILE "assets/music/canon_music.bas",870
	;[871]     MUSIC D5,G2,-,-
	SRCFILE "assets/music/canon_music.bas",871
	DECLE 2087,0
	;[872]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",872
	DECLE 16191,0
	;[873]     MUSIC C5,S,-,-
	SRCFILE "assets/music/canon_music.bas",873
	DECLE 16165,0
	;[874]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",874
	DECLE 16191,0
	;[875]     MUSIC B4,S,-,-
	SRCFILE "assets/music/canon_music.bas",875
	DECLE 16164,0
	;[876]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",876
	DECLE 16191,0
	;[877]     MUSIC C5,S,-,-
	SRCFILE "assets/music/canon_music.bas",877
	DECLE 16165,0
	;[878]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",878
	DECLE 16191,0
	;[879]     MUSIC C5#,A2,-,-
	SRCFILE "assets/music/canon_music.bas",879
	DECLE 2598,0
	;[880]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",880
	DECLE 16191,0
	;[881]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",881
	DECLE 16191,0
	;[882]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",882
	DECLE 16191,0
	;[883]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",883
	DECLE 16191,0
	;[884]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",884
	DECLE 16191,0
	;[885]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",885
	DECLE 16191,0
	;[886]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",886
	DECLE 16191,0
	;[887] 
	SRCFILE "assets/music/canon_music.bas",887
	;[888]     MUSIC D5,D3,-,-
	SRCFILE "assets/music/canon_music.bas",888
	DECLE 3879,0
	;[889]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",889
	DECLE 16191,0
	;[890]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",890
	DECLE 16191,0
	;[891]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",891
	DECLE 16191,0
	;[892]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",892
	DECLE 16191,0
	;[893]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",893
	DECLE 16191,0
	;[894]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",894
	DECLE 16191,0
	;[895]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",895
	DECLE 16191,0
	;[896]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",896
	DECLE 16191,0
	;[897]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",897
	DECLE 16191,0
	;[898]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",898
	DECLE 16191,0
	;[899]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",899
	DECLE 16191,0
	;[900]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",900
	DECLE 16191,0
	;[901]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",901
	DECLE 16191,0
	;[902]     MUSIC S,S,-,-
	SRCFILE "assets/music/canon_music.bas",902
	DECLE 16191,0
	;[903]     MUSIC -,-,-,-
	SRCFILE "assets/music/canon_music.bas",903
	DECLE 0,0
	;[904] 
	SRCFILE "assets/music/canon_music.bas",904
	;[905]     MUSIC STOP
	SRCFILE "assets/music/canon_music.bas",905
	DECLE 0,65024
	;ENDFILE
	;FILE ./games/orchestra-demo/src/main.bas
	;[1199] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1199
	;[1200] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",1200
	;[1201] ' NUTCRACKER MARCH - IntyBASIC MUSIC FORMAT
	SRCFILE "./games/orchestra-demo/src/main.bas",1201
	;[1202] ' Simplified 3-channel arrangement
	SRCFILE "./games/orchestra-demo/src/main.bas",1202
	;[1203] ' ============================================
	SRCFILE "./games/orchestra-demo/src/main.bas",1203
	;[1204] INCLUDE "assets/music/nutcracker_intybasic.bas"
	SRCFILE "./games/orchestra-demo/src/main.bas",1204
	;FILE assets/music/nutcracker_intybasic.bas
	;[1] ' ============================================
	SRCFILE "assets/music/nutcracker_intybasic.bas",1
	;[2] ' Nutcracker March - IntyBASIC MUSIC Format
	SRCFILE "assets/music/nutcracker_intybasic.bas",2
	;[3] ' Simplified 3-channel arrangement
	SRCFILE "assets/music/nutcracker_intybasic.bas",3
	;[4] ' Original by Tchaikovsky
	SRCFILE "assets/music/nutcracker_intybasic.bas",4
	;[5] ' ============================================
	SRCFILE "assets/music/nutcracker_intybasic.bas",5
	;[6] ' Channel 1: Melody (high)
	SRCFILE "assets/music/nutcracker_intybasic.bas",6
	;[7] ' Channel 2: Harmony (mid)
	SRCFILE "assets/music/nutcracker_intybasic.bas",7
	;[8] ' Channel 3: Bass (low)
	SRCFILE "assets/music/nutcracker_intybasic.bas",8
	;[9] ' ============================================
	SRCFILE "assets/music/nutcracker_intybasic.bas",9
	;[10] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",10
	;[11] NutcrackerMarch:
	SRCFILE "assets/music/nutcracker_intybasic.bas",11
	; NUTCRACKERMARCH
label_NUTCRACKERMARCH:	;[12]     DATA 7
	SRCFILE "assets/music/nutcracker_intybasic.bas",12
	DECLE 7
	;[13] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",13
	;[14]     ' VOLUME TEST: Same note A4 on each channel, then all together
	SRCFILE "assets/music/nutcracker_intybasic.bas",14
	;[15]     ' If all 3 channels work, the combined sound should be 3x louder
	SRCFILE "assets/music/nutcracker_intybasic.bas",15
	;[16] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",16
	;[17]     ' A4 on CH1 only (should hear it)
	SRCFILE "assets/music/nutcracker_intybasic.bas",17
	;[18]     MUSIC A4,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",18
	DECLE 34,0
	;[19]     MUSIC S,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",19
	DECLE 63,0
	;[20]     MUSIC S,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",20
	DECLE 63,0
	;[21]     MUSIC S,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",21
	DECLE 63,0
	;[22]     MUSIC S,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",22
	DECLE 63,0
	;[23]     MUSIC S,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",23
	DECLE 63,0
	;[24]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",24
	DECLE 0,0
	;[25]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",25
	DECLE 0,0
	;[26] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",26
	;[27]     ' A4 on CH2 only (should hear it)
	SRCFILE "assets/music/nutcracker_intybasic.bas",27
	;[28]     MUSIC -,A4,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",28
	DECLE 8704,0
	;[29]     MUSIC -,S,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",29
	DECLE 16128,0
	;[30]     MUSIC -,S,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",30
	DECLE 16128,0
	;[31]     MUSIC -,S,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",31
	DECLE 16128,0
	;[32]     MUSIC -,S,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",32
	DECLE 16128,0
	;[33]     MUSIC -,S,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",33
	DECLE 16128,0
	;[34]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",34
	DECLE 0,0
	;[35]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",35
	DECLE 0,0
	;[36] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",36
	;[37]     ' A4 on CH3 only (does this play?)
	SRCFILE "assets/music/nutcracker_intybasic.bas",37
	;[38]     MUSIC -,-,A4,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",38
	DECLE 0,34
	;[39]     MUSIC -,-,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",39
	DECLE 0,63
	;[40]     MUSIC -,-,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",40
	DECLE 0,63
	;[41]     MUSIC -,-,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",41
	DECLE 0,63
	;[42]     MUSIC -,-,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",42
	DECLE 0,63
	;[43]     MUSIC -,-,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",43
	DECLE 0,63
	;[44]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",44
	DECLE 0,0
	;[45]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",45
	DECLE 0,0
	;[46] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",46
	;[47]     ' A4 on ALL THREE (should be much louder if 3 channels work)
	SRCFILE "assets/music/nutcracker_intybasic.bas",47
	;[48]     MUSIC A4,A4,A4,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",48
	DECLE 8738,34
	;[49]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",49
	DECLE 16191,63
	;[50]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",50
	DECLE 16191,63
	;[51]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",51
	DECLE 16191,63
	;[52]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",52
	DECLE 16191,63
	;[53]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",53
	DECLE 16191,63
	;[54]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",54
	DECLE 16191,63
	;[55]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",55
	DECLE 16191,63
	;[56]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",56
	DECLE 0,0
	;[57]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",57
	DECLE 0,0
	;[58] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",58
	;[59]     ' Opening fanfare - G major chord hits
	SRCFILE "assets/music/nutcracker_intybasic.bas",59
	;[60]     MUSIC G5,B4,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",60
	DECLE 9260,20
	;[61]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",61
	DECLE 16191,63
	;[62]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",62
	DECLE 0,0
	;[63]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",63
	DECLE 0,0
	;[64]     MUSIC G5,B4,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",64
	DECLE 9260,20
	;[65]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",65
	DECLE 16191,63
	;[66]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",66
	DECLE 0,0
	;[67]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",67
	DECLE 0,0
	;[68]     MUSIC G5,B4,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",68
	DECLE 9260,20
	;[69]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",69
	DECLE 16191,63
	;[70]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",70
	DECLE 0,0
	;[71]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",71
	DECLE 0,0
	;[72]     MUSIC G5,D5,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",72
	DECLE 10028,20
	;[73]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",73
	DECLE 16191,63
	;[74]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",74
	DECLE 0,0
	;[75]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",75
	DECLE 0,0
	;[76] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",76
	;[77]     ' Main theme A - E minor feel
	SRCFILE "assets/music/nutcracker_intybasic.bas",77
	;[78]     MUSIC E5,B4,E3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",78
	DECLE 9257,17
	;[79]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",79
	DECLE 16191,63
	;[80]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",80
	DECLE 16191,63
	;[81]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",81
	DECLE 16191,63
	;[82]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",82
	DECLE 0,0
	;[83]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",83
	DECLE 0,0
	;[84]     MUSIC E5,B4,E3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",84
	DECLE 9257,17
	;[85]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",85
	DECLE 16191,63
	;[86]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",86
	DECLE 16191,63
	;[87]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",87
	DECLE 16191,63
	;[88]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",88
	DECLE 0,0
	;[89]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",89
	DECLE 0,0
	;[90] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",90
	;[91]     MUSIC F5,C5,F3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",91
	DECLE 9514,18
	;[92]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",92
	DECLE 16191,63
	;[93]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",93
	DECLE 16191,63
	;[94]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",94
	DECLE 16191,63
	;[95]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",95
	DECLE 0,0
	;[96]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",96
	DECLE 0,0
	;[97] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",97
	;[98]     MUSIC G5,D5,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",98
	DECLE 10028,20
	;[99]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",99
	DECLE 16191,63
	;[100]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",100
	DECLE 16191,63
	;[101]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",101
	DECLE 16191,63
	;[102]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",102
	DECLE 16191,63
	;[103]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",103
	DECLE 16191,63
	;[104]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",104
	DECLE 16191,63
	;[105]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",105
	DECLE 16191,63
	;[106] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",106
	;[107]     ' Theme B - higher melody
	SRCFILE "assets/music/nutcracker_intybasic.bas",107
	;[108]     MUSIC G5,E5,C4,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",108
	DECLE 10540,25
	;[109]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",109
	DECLE 16191,63
	;[110]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",110
	DECLE 16191,63
	;[111]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",111
	DECLE 16191,63
	;[112]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",112
	DECLE 0,0
	;[113]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",113
	DECLE 0,0
	;[114]     MUSIC G5,E5,C4,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",114
	DECLE 10540,25
	;[115]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",115
	DECLE 16191,63
	;[116]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",116
	DECLE 16191,63
	;[117]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",117
	DECLE 16191,63
	;[118]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",118
	DECLE 0,0
	;[119]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",119
	DECLE 0,0
	;[120] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",120
	;[121]     MUSIC A5,F5,D4,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",121
	DECLE 10798,27
	;[122]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",122
	DECLE 16191,63
	;[123]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",123
	DECLE 16191,63
	;[124]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",124
	DECLE 16191,63
	;[125]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",125
	DECLE 0,0
	;[126]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",126
	DECLE 0,0
	;[127] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",127
	;[128]     MUSIC B5,G5,D4,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",128
	DECLE 11312,27
	;[129]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",129
	DECLE 16191,63
	;[130]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",130
	DECLE 16191,63
	;[131]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",131
	DECLE 16191,63
	;[132]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",132
	DECLE 16191,63
	;[133]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",133
	DECLE 16191,63
	;[134]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",134
	DECLE 16191,63
	;[135]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",135
	DECLE 16191,63
	;[136] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",136
	;[137]     ' March section - staccato hits
	SRCFILE "assets/music/nutcracker_intybasic.bas",137
	;[138]     MUSIC G5,D5,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",138
	DECLE 10028,20
	;[139]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",139
	DECLE 16191,63
	;[140]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",140
	DECLE 0,0
	;[141]     MUSIC G5,D5,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",141
	DECLE 10028,20
	;[142]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",142
	DECLE 16191,63
	;[143]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",143
	DECLE 0,0
	;[144]     MUSIC A5,E5,A3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",144
	DECLE 10542,22
	;[145]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",145
	DECLE 16191,63
	;[146]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",146
	DECLE 0,0
	;[147]     MUSIC A5,E5,A3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",147
	DECLE 10542,22
	;[148]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",148
	DECLE 16191,63
	;[149]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",149
	DECLE 0,0
	;[150] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",150
	;[151]     MUSIC B5,F5,B3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",151
	DECLE 10800,24
	;[152]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",152
	DECLE 16191,63
	;[153]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",153
	DECLE 16191,63
	;[154]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",154
	DECLE 16191,63
	;[155]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",155
	DECLE 16191,63
	;[156]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",156
	DECLE 16191,63
	;[157]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",157
	DECLE 16191,63
	;[158]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",158
	DECLE 16191,63
	;[159] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",159
	;[160]     ' Descending passage
	SRCFILE "assets/music/nutcracker_intybasic.bas",160
	;[161]     MUSIC D6,A5,D4,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",161
	DECLE 11827,27
	;[162]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",162
	DECLE 16191,63
	;[163]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",163
	DECLE 16191,63
	;[164]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",164
	DECLE 0,0
	;[165]     MUSIC C6,G5,C4,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",165
	DECLE 11313,25
	;[166]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",166
	DECLE 16191,63
	;[167]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",167
	DECLE 16191,63
	;[168]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",168
	DECLE 0,0
	;[169]     MUSIC B5,F5,B3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",169
	DECLE 10800,24
	;[170]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",170
	DECLE 16191,63
	;[171]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",171
	DECLE 16191,63
	;[172]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",172
	DECLE 0,0
	;[173]     MUSIC A5,E5,A3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",173
	DECLE 10542,22
	;[174]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",174
	DECLE 16191,63
	;[175]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",175
	DECLE 16191,63
	;[176]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",176
	DECLE 0,0
	;[177] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",177
	;[178]     ' Resolution chord
	SRCFILE "assets/music/nutcracker_intybasic.bas",178
	;[179]     MUSIC G5,D5,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",179
	DECLE 10028,20
	;[180]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",180
	DECLE 16191,63
	;[181]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",181
	DECLE 16191,63
	;[182]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",182
	DECLE 16191,63
	;[183]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",183
	DECLE 16191,63
	;[184]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",184
	DECLE 16191,63
	;[185]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",185
	DECLE 16191,63
	;[186]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",186
	DECLE 16191,63
	;[187]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",187
	DECLE 16191,63
	;[188]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",188
	DECLE 16191,63
	;[189]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",189
	DECLE 16191,63
	;[190]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",190
	DECLE 16191,63
	;[191] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",191
	;[192]     ' Repeat theme A
	SRCFILE "assets/music/nutcracker_intybasic.bas",192
	;[193]     MUSIC E5,B4,E3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",193
	DECLE 9257,17
	;[194]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",194
	DECLE 16191,63
	;[195]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",195
	DECLE 16191,63
	;[196]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",196
	DECLE 16191,63
	;[197]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",197
	DECLE 0,0
	;[198]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",198
	DECLE 0,0
	;[199]     MUSIC E5,B4,E3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",199
	DECLE 9257,17
	;[200]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",200
	DECLE 16191,63
	;[201]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",201
	DECLE 16191,63
	;[202]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",202
	DECLE 16191,63
	;[203]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",203
	DECLE 0,0
	;[204]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",204
	DECLE 0,0
	;[205] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",205
	;[206]     MUSIC F5,C5,F3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",206
	DECLE 9514,18
	;[207]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",207
	DECLE 16191,63
	;[208]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",208
	DECLE 16191,63
	;[209]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",209
	DECLE 16191,63
	;[210]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",210
	DECLE 0,0
	;[211]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",211
	DECLE 0,0
	;[212] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",212
	;[213]     MUSIC G5,D5,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",213
	DECLE 10028,20
	;[214]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",214
	DECLE 16191,63
	;[215]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",215
	DECLE 16191,63
	;[216]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",216
	DECLE 16191,63
	;[217]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",217
	DECLE 16191,63
	;[218]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",218
	DECLE 16191,63
	;[219]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",219
	DECLE 16191,63
	;[220]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",220
	DECLE 16191,63
	;[221] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",221
	;[222]     ' Higher theme
	SRCFILE "assets/music/nutcracker_intybasic.bas",222
	;[223]     MUSIC B5,G5,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",223
	DECLE 11312,20
	;[224]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",224
	DECLE 16191,63
	;[225]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",225
	DECLE 16191,63
	;[226]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",226
	DECLE 16191,63
	;[227]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",227
	DECLE 0,0
	;[228]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",228
	DECLE 0,0
	;[229]     MUSIC B5,G5,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",229
	DECLE 11312,20
	;[230]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",230
	DECLE 16191,63
	;[231]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",231
	DECLE 16191,63
	;[232]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",232
	DECLE 16191,63
	;[233]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",233
	DECLE 0,0
	;[234]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",234
	DECLE 0,0
	;[235] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",235
	;[236]     MUSIC C6,A5,A3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",236
	DECLE 11825,22
	;[237]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",237
	DECLE 16191,63
	;[238]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",238
	DECLE 16191,63
	;[239]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",239
	DECLE 16191,63
	;[240]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",240
	DECLE 0,0
	;[241]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",241
	DECLE 0,0
	;[242] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",242
	;[243]     MUSIC D6,B5,B3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",243
	DECLE 12339,24
	;[244]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",244
	DECLE 16191,63
	;[245]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",245
	DECLE 16191,63
	;[246]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",246
	DECLE 16191,63
	;[247]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",247
	DECLE 16191,63
	;[248]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",248
	DECLE 16191,63
	;[249]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",249
	DECLE 16191,63
	;[250]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",250
	DECLE 16191,63
	;[251] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",251
	;[252]     ' Final descent
	SRCFILE "assets/music/nutcracker_intybasic.bas",252
	;[253]     MUSIC D6,A5,D4,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",253
	DECLE 11827,27
	;[254]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",254
	DECLE 16191,63
	;[255]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",255
	DECLE 16191,63
	;[256]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",256
	DECLE 0,0
	;[257]     MUSIC C6,G5,C4,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",257
	DECLE 11313,25
	;[258]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",258
	DECLE 16191,63
	;[259]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",259
	DECLE 16191,63
	;[260]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",260
	DECLE 0,0
	;[261]     MUSIC B5,F5,B3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",261
	DECLE 10800,24
	;[262]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",262
	DECLE 16191,63
	;[263]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",263
	DECLE 16191,63
	;[264]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",264
	DECLE 0,0
	;[265]     MUSIC A5,E5,A3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",265
	DECLE 10542,22
	;[266]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",266
	DECLE 16191,63
	;[267]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",267
	DECLE 16191,63
	;[268]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",268
	DECLE 0,0
	;[269] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",269
	;[270]     ' Grand finale
	SRCFILE "assets/music/nutcracker_intybasic.bas",270
	;[271]     MUSIC G5,D5,G3,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",271
	DECLE 10028,20
	;[272]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",272
	DECLE 16191,63
	;[273]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",273
	DECLE 16191,63
	;[274]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",274
	DECLE 16191,63
	;[275]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",275
	DECLE 0,0
	;[276]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",276
	DECLE 0,0
	;[277] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",277
	;[278]     MUSIC G5,B4,G2,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",278
	DECLE 9260,8
	;[279]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",279
	DECLE 16191,63
	;[280]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",280
	DECLE 16191,63
	;[281]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",281
	DECLE 16191,63
	;[282]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",282
	DECLE 16191,63
	;[283]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",283
	DECLE 16191,63
	;[284]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",284
	DECLE 16191,63
	;[285]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",285
	DECLE 16191,63
	;[286]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",286
	DECLE 16191,63
	;[287]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",287
	DECLE 16191,63
	;[288]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",288
	DECLE 16191,63
	;[289]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",289
	DECLE 16191,63
	;[290]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",290
	DECLE 16191,63
	;[291]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",291
	DECLE 16191,63
	;[292]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",292
	DECLE 16191,63
	;[293]     MUSIC S,S,S,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",293
	DECLE 16191,63
	;[294] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",294
	;[295]     MUSIC -,-,-,-
	SRCFILE "assets/music/nutcracker_intybasic.bas",295
	DECLE 0,0
	;[296] 
	SRCFILE "assets/music/nutcracker_intybasic.bas",296
	;[297]     MUSIC STOP
	SRCFILE "assets/music/nutcracker_intybasic.bas",297
	DECLE 0,65024
	;ENDFILE
	;FILE ./games/orchestra-demo/src/main.bas
	;[1205] 
	SRCFILE "./games/orchestra-demo/src/main.bas",1205
	;ENDFILE
	;ENDFILE
	SRCFILE "",0
	;
	; Epilogue for IntyBASIC programs
	; by Oscar Toledo G.  http://nanochess.org/
	;
	; Revision: Jan/30/2014. Moved GRAM code below MOB updates.
	;                        Added comments.
	; Revision: Feb/26/2014. Optimized access to collision registers
	;                        per DZ-Jay suggestion. Added scrolling
	;                        routines with optimization per intvnut
	;                        suggestion. Added border/mask support.
	; Revision: Apr/02/2014. Added support to set MODE (color stack
	;                        or foreground/background), added support
	;                        for SCREEN statement.
	; Revision: Aug/19/2014. Solved bug in bottom scroll, moved an
	;                        extra unneeded line.
	; Revision: Aug/26/2014. Integrated music player and NTSC/PAL
	;                        detection.
	; Revision: Oct/24/2014. Adjust in some comments.
	; Revision: Nov/13/2014. Integrated Joseph Zbiciak's routines
	;                        for printing numbers.
	; Revision: Nov/17/2014. Redesigned MODE support to use a single
	;                        variable.
	; Revision: Nov/21/2014. Added Intellivoice support routines made
	;                        by Joseph Zbiciak.
	; Revision: Dec/11/2014. Optimized keypad decode routines.
	; Revision: Jan/25/2015. Added marker for insertion of ON FRAME GOSUB
	; Revision: Feb/17/2015. Allows to deactivate music player (PLAY NONE)
	; Revision: Apr/21/2015. Accelerates common case of keypad not pressed.
	;                        Added ECS ROM disable code.
	; Revision: Apr/22/2015. Added Joseph Zbiciak accelerated multiplication
	;                        routines.
	; Revision: Jun/04/2015. Optimized play_music (per GroovyBee suggestion)
	; Revision: Jul/25/2015. Added infinite loop at start to avoid crashing
	;                        with empty programs. Solved bug where _color
	;                        didn't started with white.
	; Revision: Aug/20/2015. Moved ECS mapper disable code so nothing gets
	;                        after it (GroovyBee 42K sample code)
	; Revision: Aug/21/2015. Added Joseph Zbiciak routines for JLP Flash
	;                        handling.
	; Revision: Aug/31/2015. Added CPYBLK2 for SCREEN fifth argument.
	; Revision: Sep/01/2015. Defined labels Q1 and Q2 as alias.
	; Revision: Jan/22/2016. Music player allows not to use noise channel
	;                        for drums. Allows setting music volume.
	; Revision: Jan/23/2016. Added jump inside of music (for MUSIC JUMP)
	; Revision: May/03/2016. Preserves current mode in bit 0 of _mode_select
	; Revision: Oct/21/2016. Added C7 in notes table, it was missing. (thanks
	;                        mmarrero)
	; Revision: Jan/09/2018. Initializes scroll offset registers (useful when
	;                        starting from $4800). Uses slightly less space.
	; Revision: Feb/05/2018. Added IV_HUSH.
	; Revision: Mar/01/2018. Added support for music tracker over ECS.
	; Revision: Sep/25/2018. Solved bug in mixer for ECS drums.
	; Revision: Oct/30/2018. Small optimization in music player.
	; Revision: Jan/09/2019. Solved bug where it would play always like
	;                        PLAY SIMPLE NO DRUMS.
	; Revision: May/18/2019. Solved bug where drums failed in ECS side.
	;

	;
	; Avoids empty programs to crash
	; 
stuck:	B stuck

	ROM.SelectDefaultSegment

	;
	; Copy screen helper for SCREEN wide statement
	;

CPYBLK2:	PROC
	MOVR R0,R3		; Offset
	MOVR R5,R2
	PULR R0
	PULR R1
	PULR R5
	PULR R4
	PSHR R2
	SUBR R1,R3

@@1:	PSHR R3
	MOVR R1,R3		; Init line copy
@@2:	MVI@ R4,R2		; Copy line
	MVO@ R2,R5
	DECR R3
	BNE @@2
	PULR R3		 ; Add offset to start in next line
	ADDR R3,R4
	SUBR R1,R5
	ADDI #20,R5
	DECR R0		 ; Count lines
	BNE @@1

	RETURN
	ENDP

	;
	; Copy screen helper for SCREEN statement
	;
CPYBLK:	PROC
	BEGIN
	MOVR R3,R4
	MOVR R2,R5

@@1:	MOVR R1,R3	      ; Init line copy
@@2:	MVI@ R4,R2	      ; Copy line
	MVO@ R2,R5
	DECR R3
	BNE @@2
	MVII #20,R3	     ; Add offset to start in next line
	SUBR R1,R3
	ADDR R3,R4
	ADDR R3,R5
	DECR R0		 ; Count lines
	BNE @@1
	RETURN
	ENDP

	;
	; Wait for interruption
	;
_wait:  PROC

    IF intybasic_keypad
	MVI $01FF,R0
	COMR R0
	ANDI #$FF,R0
	CMP _cnt1_p0,R0
	BNE @@2
	CMP _cnt1_p1,R0
	BNE @@2
	TSTR R0		; Accelerates common case of key not pressed
	MVII #_keypad_table+13,R4
	BEQ @@4
	MVII #_keypad_table,R4
    REPEAT 6
	CMP@ R4,R0
	BEQ @@4
	CMP@ R4,R0
	BEQ @@4
    ENDR
	INCR R4
@@4:    SUBI #_keypad_table+1,R4
	MVO R4,_cnt1_key

@@2:    MVI _cnt1_p1,R1
	MVO R1,_cnt1_p0
	MVO R0,_cnt1_p1

	MVI $01FE,R0
	COMR R0
	ANDI #$FF,R0
	CMP _cnt2_p0,R0
	BNE @@5
	CMP _cnt2_p1,R0
	BNE @@5
	TSTR R0		; Accelerates common case of key not pressed
	MVII #_keypad_table+13,R4
	BEQ @@7
	MVII #_keypad_table,R4
    REPEAT 6
	CMP@ R4,R0
	BEQ @@7
	CMP@ R4,R0
	BEQ @@7
    ENDR

	INCR R4
@@7:    SUBI #_keypad_table+1,R4
	MVO R4,_cnt2_key

@@5:    MVI _cnt2_p1,R1
	MVO R1,_cnt2_p0
	MVO R0,_cnt2_p1
    ENDI

	CLRR    R0
	MVO     R0,_int	 ; Clears waiting flag
@@1:	CMP     _int,  R0       ; Waits for change
	BEQ     @@1
	JR      R5	      ; Returns
	ENDP

	;
	; Keypad table
	;
_keypad_table:	  PROC
	DECLE $48,$81,$41,$21,$82,$42,$22,$84,$44,$24,$88,$28
	ENDP

_set_isr:	PROC
	MVI@ R5,R0
	MVO R0,ISRVEC
	SWAP R0
	MVO R0,ISRVEC+1
	JR R5
	ENDP

	;
	; Interruption routine
	;
_int_vector:     PROC

    IF intybasic_stack
	CMPI #$308,R6
	BNC @@vs
	MVO R0,$20	; Enables display
	MVI $21,R0	; Activates Color Stack mode
	CLRR R0
	MVO R0,$28
	MVO R0,$29
	MVO R0,$2A
	MVO R0,$2B
	MVII #@@vs1,R4
	MVII #$200,R5
	MVII #20,R1
@@vs2:	MVI@ R4,R0
	MVO@ R0,R5
	DECR R1
	BNE @@vs2
	RETURN

	; Stack Overflow message
@@vs1:	DECLE 0,0,0,$33*8+7,$54*8+7,$41*8+7,$43*8+7,$4B*8+7,$00*8+7
	DECLE $4F*8+7,$56*8+7,$45*8+7,$52*8+7,$46*8+7,$4C*8+7
	DECLE $4F*8+7,$57*8+7,0,0,0

@@vs:
    ENDI

	MVII #1,R1
	MVO R1,_int	; Indicates interrupt happened.

	MVI _mode_select,R0
	SARC R0,2
	BNE @@ds
	MVO R0,$20	; Enables display
@@ds:	BNC @@vi14
	MVO R0,$21	; Foreground/background mode
	BNOV @@vi0
	B @@vi15

@@vi14:	MVI $21,R0	; Color stack mode
	BNOV @@vi0
	CLRR R1
	MVI _color,R0
	MVO R0,$28
	SWAP R0
	MVO R0,$29
	SLR R0,2
	SLR R0,2
	MVO R0,$2A
	SWAP R0
	MVO R0,$2B
@@vi15:
	MVO R1,_mode_select
	MVII #7,R0
	MVO R0,_color	   ; Default color for PRINT "string"
@@vi0:

	BEGIN

	MVI _border_color,R0
	MVO     R0,     $2C     ; Border color
	MVI _border_mask,R0
	MVO     R0,     $32     ; Border mask
    IF intybasic_col
	;
	; Save collision registers for further use and clear them
	;
	MVII #$18,R4
	MVII #_col0,R5
	MVI@ R4,R0
	MVO@ R0,R5  ; _col0
	MVI@ R4,R0
	MVO@ R0,R5  ; _col1
	MVI@ R4,R0
	MVO@ R0,R5  ; _col2
	MVI@ R4,R0
	MVO@ R0,R5  ; _col3
	MVI@ R4,R0
	MVO@ R0,R5  ; _col4
	MVI@ R4,R0
	MVO@ R0,R5  ; _col5
	MVI@ R4,R0
	MVO@ R0,R5  ; _col6
	MVI@ R4,R0
	MVO@ R0,R5  ; _col7
    ENDI
	
    IF intybasic_scroll

	;
	; Scrolling things
	;
	MVI _scroll_x,R0
	MVO R0,$30
	MVI _scroll_y,R0
	MVO R0,$31
    ENDI

	;
	; Updates sprites (MOBs)
	;
	MVII #_mobs,R4
	CLRR R5		; X-coordinates
    REPEAT 8
	MVI@ R4,R0
	MVO@ R0,R5
	MVI@ R4,R0
	MVO@ R0,R5
	MVI@ R4,R0
	MVO@ R0,R5
    ENDR
    IF intybasic_col
	CLRR R0		; Erase collision bits (R5 = $18)
	MVO@ R0,R5
	MVO@ R0,R5
	MVO@ R0,R5
	MVO@ R0,R5
	MVO@ R0,R5
	MVO@ R0,R5
	MVO@ R0,R5
	MVO@ R0,R5
    ENDI

    IF intybasic_music
     	MVI _ntsc,R0
	RRC R0,1	 ; PAL?
	BNC @@vo97      ; Yes, always emit sound
	MVI _music_frame,R0
	INCR R0
	CMPI #6,R0
	BNE @@vo14
	CLRR R0
@@vo14:	MVO R0,_music_frame
	BEQ @@vo15
@@vo97:	CALL _emit_sound
    IF intybasic_music_ecs
	CALL _emit_sound_ecs
    ENDI
@@vo15:
    ENDI

	;
	; Detect GRAM definition
	;
	MVI _gram_bitmap,R4
	TSTR R4
	BEQ @@vi1
	MVI _gram_target,R1
	SLL R1,2
	SLL R1,1
	ADDI #$3800,R1
	MOVR R1,R5
	MVI _gram_total,R0
@@vi3:
	MVI@    R4,     R1
	MVO@    R1,     R5
	SWAP    R1
	MVO@    R1,     R5
	MVI@    R4,     R1
	MVO@    R1,     R5
	SWAP    R1
	MVO@    R1,     R5
	MVI@    R4,     R1
	MVO@    R1,     R5
	SWAP    R1
	MVO@    R1,     R5
	MVI@    R4,     R1
	MVO@    R1,     R5
	SWAP    R1
	MVO@    R1,     R5
	DECR R0
	BNE @@vi3
	MVO R0,_gram_bitmap
@@vi1:
	MVI _gram2_bitmap,R4
	TSTR R4
	BEQ @@vii1
	MVI _gram2_target,R1
	SLL R1,2
	SLL R1,1
	ADDI #$3800,R1
	MOVR R1,R5
	MVI _gram2_total,R0
@@vii3:
	MVI@    R4,     R1
	MVO@    R1,     R5
	SWAP    R1
	MVO@    R1,     R5
	MVI@    R4,     R1
	MVO@    R1,     R5
	SWAP    R1
	MVO@    R1,     R5
	MVI@    R4,     R1
	MVO@    R1,     R5
	SWAP    R1
	MVO@    R1,     R5
	MVI@    R4,     R1
	MVO@    R1,     R5
	SWAP    R1
	MVO@    R1,     R5
	DECR R0
	BNE @@vii3
	MVO R0,_gram2_bitmap
@@vii1:

    IF intybasic_scroll
	;
	; Frame scroll support
	;
	MVI _scroll_d,R0
	TSTR R0
	BEQ @@vi4
	CLRR R1
	MVO R1,_scroll_d
	DECR R0     ; Left
	BEQ @@vi5
	DECR R0     ; Right
	BEQ @@vi6
	DECR R0     ; Top
	BEQ @@vi7
	DECR R0     ; Bottom
	BEQ @@vi8
	B @@vi4

@@vi5:  MVII #$0200,R4
	MOVR R4,R5
	INCR R5
	MVII #12,R1
@@vi12: MVI@ R4,R2
	MVI@ R4,R3
	REPEAT 8
	MVO@ R2,R5
	MVI@ R4,R2
	MVO@ R3,R5
	MVI@ R4,R3
	ENDR
	MVO@ R2,R5
	MVI@ R4,R2
	MVO@ R3,R5
	MVO@ R2,R5
	INCR R4
	INCR R5
	DECR R1
	BNE @@vi12
	B @@vi4

@@vi6:  MVII #$0201,R4
	MVII #$0200,R5
	MVII #12,R1
@@vi11:
	REPEAT 19
	MVI@ R4,R0
	MVO@ R0,R5
	ENDR
	INCR R4
	INCR R5
	DECR R1
	BNE @@vi11
	B @@vi4
    
	;
	; Complex routine to be ahead of STIC display
	; Moves first the top 6 lines, saves intermediate line
	; Then moves the bottom 6 lines and restores intermediate line
	;
@@vi7:  MVII #$0264,R4
	MVII #5,R1
	MVII #_scroll_buffer,R5
	REPEAT 20
	MVI@ R4,R0
	MVO@ R0,R5
	ENDR
	SUBI #40,R4
	MOVR R4,R5
	ADDI #20,R5
@@vi10:
	REPEAT 20
	MVI@ R4,R0
	MVO@ R0,R5
	ENDR
	SUBI #40,R4
	SUBI #40,R5
	DECR R1
	BNE @@vi10
	MVII #$02C8,R4
	MVII #$02DC,R5
	MVII #5,R1
@@vi13:
	REPEAT 20
	MVI@ R4,R0
	MVO@ R0,R5
	ENDR
	SUBI #40,R4
	SUBI #40,R5
	DECR R1
	BNE @@vi13
	MVII #_scroll_buffer,R4
	REPEAT 20
	MVI@ R4,R0
	MVO@ R0,R5
	ENDR
	B @@vi4

@@vi8:  MVII #$0214,R4
	MVII #$0200,R5
	MVII #$DC/4,R1
@@vi9:  
	REPEAT 4
	MVI@ R4,R0
	MVO@ R0,R5
	ENDR
	DECR R1
	BNE @@vi9
	B @@vi4

@@vi4:
    ENDI

    IF intybasic_voice
	;
	; Intellivoice support
	;
	CALL IV_ISR
    ENDI

	;
	; Random number generator
	;
	CALL _next_random

    IF intybasic_music
	; Generate sound for next frame
       	MVI _ntsc,R0
	RRC R0,1	 ; PAL?
	BNC @@vo98      ; Yes, always generate sound
	MVI _music_frame,R0
	TSTR R0
	BEQ @@vo16
@@vo98: CALL _generate_music
@@vo16:
    ENDI

	; Increase frame number
	MVI _frame,R0
	INCR R0
	MVO R0,_frame

	; This mark is for ON FRAME GOSUB support

	RETURN
	ENDP

	;
	; Generates the next random number
	;
_next_random:	PROC

MACRO _ROR
	RRC R0,1
	MOVR R0,R2
	SLR R2,2
	SLR R2,2
	ANDI #$0800,R2
	SLR R2,2
	SLR R2,2
	ANDI #$007F,R0
	XORR R2,R0
ENDM
	MVI _rand,R0
	SETC
	_ROR
	XOR _frame,R0
	_ROR
	XOR _rand,R0
	_ROR
	XORI #9,R0
	MVO R0,_rand
	JR R5
	ENDP

    IF intybasic_music

	;
	; Music player, comes from my game Princess Quest for Intellivision
	; so it's a practical tracker used in a real game ;) and with enough
	; features.
	;

	; NTSC frequency for notes (based on 3.579545 mhz)
ntsc_note_table:    PROC
	; Silence - 0
	DECLE 0
	; Octave 2 - 1
	DECLE 1721,1621,1532,1434,1364,1286,1216,1141,1076,1017,956,909
	; Octave 3 - 13
	DECLE 854,805,761,717,678,639,605,571,538,508,480,453
	; Octave 4 - 25
	DECLE 427,404,380,360,339,321,302,285,270,254,240,226
	; Octave 5 - 37
	DECLE 214,202,191,180,170,160,151,143,135,127,120,113
	; Octave 6 - 49
	DECLE 107,101,95,90,85,80,76,71,67,64,60,57
	; Octave 7 - 61
	DECLE 54
	; Space for two notes more
	ENDP

	; PAL frequency for notes (based on 4 mhz)
pal_note_table:    PROC
	; Silence - 0
	DECLE 0
	; Octava 2 - 1
	DECLE 1923,1812,1712,1603,1524,1437,1359,1276,1202,1136,1068,1016
	; Octava 3 - 13
	DECLE 954,899,850,801,758,714,676,638,601,568,536,506
	; Octava 4 - 25
	DECLE 477,451,425,402,379,358,338,319,301,284,268,253
	; Octava 5 - 37
	DECLE 239,226,213,201,190,179,169,159,150,142,134,127
	; Octava 6 - 49
	DECLE 120,113,106,100,95,89,84,80,75,71,67,63
	; Octava 7 - 61
	DECLE 60
	; Space for two notes more
	ENDP
    ENDI

	;
	; Music tracker init
	;
_init_music:	PROC
    IF intybasic_music
	MVI _ntsc,R0
	RRC R0,1
	MVII #ntsc_note_table,R0
	BC @@0
	MVII #pal_note_table,R0
@@0:	MVO R0,_music_table
	MVII #$38,R0	; $B8 blocks controllers o.O!
	MVO R0,_music_mix
    IF intybasic_music_ecs
	MVO R0,_music2_mix
    ENDI
	CLRR R0
    ELSE
	JR R5		; Tracker disabled (no PLAY statement used)
    ENDI
	ENDP

    IF intybasic_music
	;
	; Start music
	; R0 = Pointer to music
	;
_play_music:	PROC
	MVII #1,R1
	MOVR R1,R3
	MOVR R0,R2
	BEQ @@1
	MVI@ R2,R3
	INCR R2
@@1:	MVO R2,_music_p
	MVO R2,_music_start
	SWAP R2
	MVO R2,_music_start+1
	MVO R3,_music_t
	MVO R1,_music_tc
	JR R5

	ENDP

	;
	; Generate music
	;
_generate_music:	PROC
	BEGIN
	MVI _music_mix,R0
	ANDI #$C0,R0
	XORI #$38,R0
	MVO R0,_music_mix
    IF intybasic_music_ecs
	MVI _music2_mix,R0
	ANDI #$C0,R0
	XORI #$38,R0
	MVO R0,_music2_mix
    ENDI
	CLRR R1			; Turn off volume for the three sound channels
	MVO R1,_music_vol1
	MVO R1,_music_vol2
	MVI _music_tc,R3
	MVO R1,_music_vol3
    IF intybasic_music_ecs
	MVO R1,_music2_vol1
	NOP
	MVO R1,_music2_vol2
	MVO R1,_music2_vol3
    ENDI
	DECR R3
	MVO R3,_music_tc
	BNE @@6
	; R3 is zero from here up to @@6
	MVI _music_p,R4
@@15:	TSTR R4		; Silence?
	BEQ @@43	; Keep quiet
@@41:	MVI@ R4,R0
	MVI@ R4,R1
	MVI _music_t,R2
	CMPI #$FA00,R1	; Volume?
	BNC @@42
    IF intybasic_music_volume
	BEQ @@40
    ENDI
	CMPI #$FF00,R1	; Speed?
	BEQ @@39
	CMPI #$FB00,R1	; Return?
	BEQ @@38
	CMPI #$FC00,R1	; Gosub?
	BEQ @@37
	CMPI #$FE00,R1	; The end?
	BEQ @@36       ; Keep quiet
;	CMPI #$FD00,R1	; Repeat?
;	BNE @@42
	MVI _music_start+1,R0
	SWAP R0
	ADD _music_start,R0
	MOVR R0,R4
	B @@15

    IF intybasic_music_volume
@@40:	
	MVO R0,_music_vol
	B @@41
    ENDI

@@39:	MVO R0,_music_t
	MOVR R0,R2
	B @@41

@@38:	MVI _music_gosub,R4
	B @@15

@@37:	MVO R4,_music_gosub
@@36:	MOVR R0,R4	; Jump, zero will make it quiet
	B @@15

@@43:	MVII #1,R0
	MVO R0,_music_tc
	B @@0
	
@@42: 	MVO R2,_music_tc    ; Restart note time
     	MVO R4,_music_p
     	
	MOVR R0,R2
	ANDI #$FF,R2
	CMPI #$3F,R2	; Sustain note?
	BEQ @@1
	MOVR R2,R4
	ANDI #$3F,R4
	MVO R4,_music_n1	; Note
	MVO R3,_music_s1	; Waveform
	ANDI #$C0,R2
	MVO R2,_music_i1	; Instrument
	
@@1:	SWAP R0
	ANDI #$FF,R0
	CMPI #$3F,R0	; Sustain note?
	BEQ @@2
	MOVR R0,R4
	ANDI #$3F,R4
	MVO R4,_music_n2	; Note
	MVO R3,_music_s2	; Waveform
	ANDI #$C0,R0
	MVO R0,_music_i2	; Instrument
	
@@2:	MOVR R1,R2
	ANDI #$FF,R2
	CMPI #$3F,R2	; Sustain note?
	BEQ @@3
	MOVR R2,R4
	ANDI #$3F,R4
	MVO R4,_music_n3	; Note
	MVO R3,_music_s3	; Waveform
	ANDI #$C0,R2
	MVO R2,_music_i3	; Instrument
	
@@3:	SWAP R1
	MVO R1,_music_n4
	MVO R3,_music_s4
	
    IF intybasic_music_ecs
	MVI _music_p,R4
	MVI@ R4,R0
	MVI@ R4,R1
	MVO R4,_music_p

	MOVR R0,R2
	ANDI #$FF,R2
	CMPI #$3F,R2	; Sustain note?
	BEQ @@33
	MOVR R2,R4
	ANDI #$3F,R4
	MVO R4,_music_n5	; Note
	MVO R3,_music_s5	; Waveform
	ANDI #$C0,R2
	MVO R2,_music_i5	; Instrument
	
@@33:	SWAP R0
	ANDI #$FF,R0
	CMPI #$3F,R0	; Sustain note?
	BEQ @@34
	MOVR R0,R4
	ANDI #$3F,R4
	MVO R4,_music_n6	; Note
	MVO R3,_music_s6	; Waveform
	ANDI #$C0,R0
	MVO R0,_music_i6	; Instrument
	
@@34:	MOVR R1,R2
	ANDI #$FF,R2
	CMPI #$3F,R2	; Sustain note?
	BEQ @@35
	MOVR R2,R4
	ANDI #$3F,R4
	MVO R4,_music_n7	; Note
	MVO R3,_music_s7	; Waveform
	ANDI #$C0,R2
	MVO R2,_music_i7	; Instrument
	
@@35:	MOVR R1,R2
	SWAP R2
	MVO R2,_music_n8
	MVO R3,_music_s8
	
    ENDI

	;
	; Construct main voice
	;
@@6:	MVI _music_n1,R3	; Read note
	TSTR R3		; There is note?
	BEQ @@7		; No, jump
	MVI _music_s1,R1
	MVI _music_i1,R2
	MOVR R1,R0
	CALL _note2freq
	MVO R3,_music_freq10	; Note in voice A
	SWAP R3
	MVO R3,_music_freq11
	MVO R1,_music_vol1
	; Increase time for instrument waveform
	INCR R0
	CMPI #$18,R0
	BNE @@20
	SUBI #$08,R0
@@20:	MVO R0,_music_s1

@@7:	MVI _music_n2,R3	; Read note
	TSTR R3		; There is note?
	BEQ @@8		; No, jump
	MVI _music_s2,R1
	MVI _music_i2,R2
	MOVR R1,R0
	CALL _note2freq
	MVO R3,_music_freq20	; Note in voice B
	SWAP R3
	MVO R3,_music_freq21
	MVO R1,_music_vol2
	; Increase time for instrument waveform
	INCR R0
	CMPI #$18,R0
	BNE @@21
	SUBI #$08,R0
@@21:	MVO R0,_music_s2

@@8:	MVI _music_n3,R3	; Read note
	TSTR R3		; There is note?
	BEQ @@9		; No, jump
	MVI _music_s3,R1
	MVI _music_i3,R2
	MOVR R1,R0
	CALL _note2freq
	MVO R3,_music_freq30	; Note in voice C
	SWAP R3
	MVO R3,_music_freq31
	MVO R1,_music_vol3
	; Increase time for instrument waveform
	INCR R0
	CMPI #$18,R0
	BNE @@22
	SUBI #$08,R0
@@22:	MVO R0,_music_s3

@@9:	MVI _music_n4,R0	; Read drum
	DECR R0		; There is drum?
	BMI @@4		; No, jump
	MVI _music_s4,R1
	       		; 1 - Strong
	BNE @@5
	CMPI #3,R1
	BGE @@12
@@10:	MVII #5,R0
	MVO R0,_music_noise
	CALL _activate_drum
	B @@12

@@5:	DECR R0		;2 - Short
	BNE @@11
	TSTR R1
	BNE @@12
	MVII #8,R0
	MVO R0,_music_noise
	CALL _activate_drum
	B @@12

@@11:	;DECR R0	; 3 - Rolling
	;BNE @@12
	CMPI #2,R1
	BLT @@10
	MVI _music_t,R0
	SLR R0,1
	CMPR R0,R1
	BLT @@12
	ADDI #2,R0
	CMPR R0,R1
	BLT @@10
	; Increase time for drum waveform
@@12:   INCR R1
	MVO R1,_music_s4

@@4:
    IF intybasic_music_ecs
	;
	; Construct main voice
	;
	MVI _music_n5,R3	; Read note
	TSTR R3		; There is note?
	BEQ @@23	; No, jump
	MVI _music_s5,R1
	MVI _music_i5,R2
	MOVR R1,R0
	CALL _note2freq
	MVO R3,_music2_freq10	; Note in voice A
	SWAP R3
	MVO R3,_music2_freq11
	MVO R1,_music2_vol1
	; Increase time for instrument waveform
	INCR R0
	CMPI #$18,R0
	BNE @@24
	SUBI #$08,R0
@@24:	MVO R0,_music_s5

@@23:	MVI _music_n6,R3	; Read note
	TSTR R3		; There is note?
	BEQ @@25		; No, jump
	MVI _music_s6,R1
	MVI _music_i6,R2
	MOVR R1,R0
	CALL _note2freq
	MVO R3,_music2_freq20	; Note in voice B
	SWAP R3
	MVO R3,_music2_freq21
	MVO R1,_music2_vol2
	; Increase time for instrument waveform
	INCR R0
	CMPI #$18,R0
	BNE @@26
	SUBI #$08,R0
@@26:	MVO R0,_music_s6

@@25:	MVI _music_n7,R3	; Read note
	TSTR R3		; There is note?
	BEQ @@27		; No, jump
	MVI _music_s7,R1
	MVI _music_i7,R2
	MOVR R1,R0
	CALL _note2freq
	MVO R3,_music2_freq30	; Note in voice C
	SWAP R3
	MVO R3,_music2_freq31
	MVO R1,_music2_vol3
	; Increase time for instrument waveform
	INCR R0
	CMPI #$18,R0
	BNE @@28
	SUBI #$08,R0
@@28:	MVO R0,_music_s7

@@27:	MVI _music_n8,R0	; Read drum
	DECR R0		; There is drum?
	BMI @@0		; No, jump
	MVI _music_s8,R1
	       		; 1 - Strong
	BNE @@29
	CMPI #3,R1
	BGE @@31
@@32:	MVII #5,R0
	MVO R0,_music2_noise
	CALL _activate_drum_ecs
	B @@31

@@29:	DECR R0		;2 - Short
	BNE @@30
	TSTR R1
	BNE @@31
	MVII #8,R0
	MVO R0,_music2_noise
	CALL _activate_drum_ecs
	B @@31

@@30:	;DECR R0	; 3 - Rolling
	;BNE @@31
	CMPI #2,R1
	BLT @@32
	MVI _music_t,R0
	SLR R0,1
	CMPR R0,R1
	BLT @@31
	ADDI #2,R0
	CMPR R0,R1
	BLT @@32
	; Increase time for drum waveform
@@31:	INCR R1
	MVO R1,_music_s8

    ENDI
@@0:	RETURN
	ENDP

	;
	; Translates note number to frequency
	; R3 = Note
	; R1 = Position in waveform for instrument
	; R2 = Instrument
	;
_note2freq:	PROC
	ADD _music_table,R3
	MVI@ R3,R3
	SWAP R2
	BEQ _piano_instrument
	RLC R2,1
	BNC _clarinet_instrument
	BPL _flute_instrument
;	BMI _bass_instrument
	ENDP

	;
	; Generates a bass
	;
_bass_instrument:	PROC
	SLL R3,2	; Lower 2 octaves
	ADDI #_bass_volume,R1
	MVI@ R1,R1	; Bass effect
    IF intybasic_music_volume
	B _global_volume
    ELSE
	JR R5
    ENDI
	ENDP

_bass_volume:	PROC
	DECLE 12,13,14,14,13,12,12,12
	DECLE 11,11,12,12,11,11,12,12
	DECLE 11,11,12,12,11,11,12,12
	ENDP

	;
	; Generates a piano
	; R3 = Frequency
	; R1 = Waveform position
	;
	; Output:
	; R3 = Frequency.
	; R1 = Volume.
	;
_piano_instrument:	PROC
	ADDI #_piano_volume,R1
	MVI@ R1,R1
    IF intybasic_music_volume
	B _global_volume
    ELSE
	JR R5
    ENDI
	ENDP

_piano_volume:	PROC
	DECLE 14,13,13,12,12,11,11,10
	DECLE 10,9,9,8,8,7,7,6
	DECLE 6,6,7,7,6,6,5,5
	ENDP

	;
	; Generate a clarinet
	; R3 = Frequency
	; R1 = Waveform position
	;
	; Output:
	; R3 = Frequency
	; R1 = Volume
	;
_clarinet_instrument:	PROC
	ADDI #_clarinet_vibrato,R1
	ADD@ R1,R3
	CLRC
	RRC R3,1	; Duplicates frequency
	ADCR R3
	ADDI #_clarinet_volume-_clarinet_vibrato,R1
	MVI@ R1,R1
    IF intybasic_music_volume
	B _global_volume
    ELSE
	JR R5
    ENDI
	ENDP

_clarinet_vibrato:	PROC
	DECLE 0,0,0,0
	DECLE -2,-4,-2,0
	DECLE 2,4,2,0
	DECLE -2,-4,-2,0
	DECLE 2,4,2,0
	DECLE -2,-4,-2,0
	ENDP

_clarinet_volume:	PROC
	DECLE 13,14,14,13,13,12,12,12
	DECLE 11,11,11,11,12,12,12,12
	DECLE 11,11,11,11,12,12,12,12
	ENDP

	;
	; Generates a flute
	; R3 = Frequency
	; R1 = Waveform position
	;
	; Output:
	; R3 = Frequency
	; R1 = Volume
	;
_flute_instrument:	PROC
	ADDI #_flute_vibrato,R1
	ADD@ R1,R3
	ADDI #_flute_volume-_flute_vibrato,R1
	MVI@ R1,R1
    IF intybasic_music_volume
	B _global_volume
    ELSE
	JR R5
    ENDI
	ENDP

_flute_vibrato:	PROC
	DECLE 0,0,0,0
	DECLE 0,1,2,1
	DECLE 0,1,2,1
	DECLE 0,1,2,1
	DECLE 0,1,2,1
	DECLE 0,1,2,1
	ENDP
		 
_flute_volume:	PROC
	DECLE 10,12,13,13,12,12,12,12
	DECLE 11,11,11,11,10,10,10,10
	DECLE 11,11,11,11,10,10,10,10
	ENDP

    IF intybasic_music_volume

_global_volume:	PROC
	MVI _music_vol,R2
	ANDI #$0F,R2
	SLL R2,2
	SLL R2,2
	ADDR R1,R2
	ADDI #@@table,R2
	MVI@ R2,R1
	JR R5

@@table:
	DECLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DECLE 0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1
	DECLE 0,0,0,0,1,1,1,1,1,1,1,2,2,2,2,2
	DECLE 0,0,0,1,1,1,1,1,2,2,2,2,2,3,3,3
	DECLE 0,0,1,1,1,1,2,2,2,2,3,3,3,4,4,4
	DECLE 0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5
	DECLE 0,0,1,1,2,2,2,3,3,4,4,4,5,5,6,6
	DECLE 0,1,1,1,2,2,3,3,4,4,5,5,6,6,7,7
	DECLE 0,1,1,2,2,3,3,4,4,5,5,6,6,7,8,8
	DECLE 0,1,1,2,2,3,4,4,5,5,6,7,7,8,8,9
	DECLE 0,1,1,2,3,3,4,5,5,6,7,7,8,9,9,10
	DECLE 0,1,2,2,3,4,4,5,6,7,7,8,9,10,10,11
	DECLE 0,1,2,2,3,4,5,6,6,7,8,9,10,10,11,12
	DECLE 0,1,2,3,4,4,5,6,7,8,9,10,10,11,12,13
	DECLE 0,1,2,3,4,5,6,7,8,8,9,10,11,12,13,14
	DECLE 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

	ENDP

    ENDI

    IF intybasic_music_ecs
	;
	; Emits sound for ECS
	;
_emit_sound_ecs:	PROC
	MOVR R5,R1
	MVI _music_mode,R2
	SARC R2,1
	BEQ @@6
	MVII #_music2_freq10,R4
	MVII #$00F0,R5
	B _emit_sound.0

@@6:	JR R1

	ENDP

    ENDI

	;
	; Emits sound
	;
_emit_sound:	PROC
	MOVR R5,R1
	MVI _music_mode,R2
	SARC R2,1
	BEQ @@6
	MVII #_music_freq10,R4
	MVII #$01F0,R5
@@0:
	MVI@ R4,R0
	MVO@ R0,R5	; $01F0 - Channel A Period (Low 8 bits of 12)
	MVI@ R4,R0
	MVO@ R0,R5	; $01F1 - Channel B Period (Low 8 bits of 12)
	DECR R2
	BEQ @@1
	MVI@ R4,R0	
	MVO@ R0,R5	; $01F2 - Channel C Period (Low 8 bits of 12)
	INCR R5		; Avoid $01F3 - Enveloped Period (Low 8 bits of 16)
	MVI@ R4,R0
	MVO@ R0,R5	; $01F4 - Channel A Period (High 4 bits of 12)
	MVI@ R4,R0
	MVO@ R0,R5	; $01F5 - Channel B Period (High 4 bits of 12)
	MVI@ R4,R0
	MVO@ R0,R5	; $01F6 - Channel C Period (High 4 bits of 12)
	INCR R5		; Avoid $01F7 - Envelope Period (High 8 bits of 16)
	BC @@2		; Jump if playing with drums
	ADDI #2,R4
	ADDI #3,R5
	B @@3

@@2:	MVI@ R4,R0
	MVO@ R0,R5	; $01F8 - Enable Noise/Tone (bits 3-5 Noise : 0-2 Tone)
	MVI@ R4,R0	
	MVO@ R0,R5	; $01F9 - Noise Period (5 bits)
	INCR R5		; Avoid $01FA - Envelope Type (4 bits)
@@3:	MVI@ R4,R0
	MVO@ R0,R5	; $01FB - Channel A Volume
	MVI@ R4,R0
	MVO@ R0,R5	; $01FC - Channel B Volume
	MVI@ R4,R0
	MVO@ R0,R5	; $01FD - Channel C Volume
	JR R1

@@1:	INCR R4		
	INCR R5		; Avoid $01F2 and $01F3
	INCR R5		; Cannot use ADDI
	MVI@ R4,R0
	MVO@ R0,R5	; $01F4 - Channel A Period (High 4 bits of 12)
	MVI@ R4,R0
	MVO@ R0,R5	; $01F5 - Channel B Period (High 4 bits of 12)
	INCR R4
	INCR R5		; Avoid $01F6 and $01F7
	INCR R5		; Cannot use ADDI
	BC @@4		; Jump if playing with drums
	ADDI #2,R4
	ADDI #3,R5
	B @@5

@@4:	MVI@ R4,R0
	MVO@ R0,R5	; $01F8 - Enable Noise/Tone (bits 3-5 Noise : 0-2 Tone)
	MVI@ R4,R0
	MVO@ R0,R5	; $01F9 - Noise Period (5 bits)
	INCR R5		; Avoid $01FA - Envelope Type (4 bits)
@@5:	MVI@ R4,R0
	MVO@ R0,R5	; $01FB - Channel A Volume
	MVI@ R4,R0
	MVO@ R0,R5	; $01FC - Channel B Volume
@@6:	JR R1
	ENDP

	;
	; Activates drum
	;
_activate_drum:	PROC
    IF intybasic_music_volume
	BEGIN
    ENDI
	MVI _music_mode,R2
	SARC R2,1	; PLAY NO DRUMS?
	BNC @@0		; Yes, jump
	MVI _music_vol1,R0
	TSTR R0
	BNE @@1
	MVII #11,R1
    IF intybasic_music_volume
	CALL _global_volume
    ENDI
	MVO R1,_music_vol1
	MVI _music_mix,R0
	ANDI #$F6,R0
	XORI #$01,R0
	MVO R0,_music_mix
    IF intybasic_music_volume
	RETURN
    ELSE
	JR R5
    ENDI

@@1:    MVI _music_vol2,R0
	TSTR R0
	BNE @@2
	MVII #11,R1
    IF intybasic_music_volume
	CALL _global_volume
    ENDI
	MVO R1,_music_vol2
	MVI _music_mix,R0
	ANDI #$ED,R0
	XORI #$02,R0
	MVO R0,_music_mix
    IF intybasic_music_volume
	RETURN
    ELSE
	JR R5
    ENDI

@@2:    DECR R2		; PLAY SIMPLE?
	BEQ @@3		; Yes, jump
	MVI _music_vol3,R0
	TSTR R0
	BNE @@3
	MVII #11,R1
    IF intybasic_music_volume
	CALL _global_volume
    ENDI
	MVO R1,_music_vol3
	MVI _music_mix,R0
	ANDI #$DB,R0
	XORI #$04,R0
	MVO R0,_music_mix
    IF intybasic_music_volume
	RETURN
    ELSE
	JR R5
    ENDI

@@3:    MVI _music_mix,R0
	ANDI #$EF,R0
	MVO R0,_music_mix
@@0:	
    IF intybasic_music_volume
	RETURN
    ELSE
	JR R5
    ENDI

	ENDP

    IF intybasic_music_ecs
	;
	; Activates drum
	;
_activate_drum_ecs:	PROC
    IF intybasic_music_volume
	BEGIN
    ENDI
	MVI _music_mode,R2
	SARC R2,1	; PLAY NO DRUMS?
	BNC @@0		; Yes, jump
	MVI _music2_vol1,R0
	TSTR R0
	BNE @@1
	MVII #11,R1
    IF intybasic_music_volume
	CALL _global_volume
    ENDI
	MVO R1,_music2_vol1
	MVI _music2_mix,R0
	ANDI #$F6,R0
	XORI #$01,R0
	MVO R0,_music2_mix
    IF intybasic_music_volume
	RETURN
    ELSE
	JR R5
    ENDI

@@1:    MVI _music2_vol2,R0
	TSTR R0
	BNE @@2
	MVII #11,R1
    IF intybasic_music_volume
	CALL _global_volume
    ENDI
	MVO R1,_music2_vol2
	MVI _music2_mix,R0
	ANDI #$ED,R0
	XORI #$02,R0
	MVO R0,_music2_mix
    IF intybasic_music_volume
	RETURN
    ELSE
	JR R5
    ENDI

@@2:    DECR R2		; PLAY SIMPLE?
	BEQ @@3		; Yes, jump
	MVI _music2_vol3,R0
	TSTR R0
	BNE @@3
	MVII #11,R1
    IF intybasic_music_volume
	CALL _global_volume
    ENDI
	MVO R1,_music2_vol3
	MVI _music2_mix,R0
	ANDI #$DB,R0
	XORI #$04,R0
	MVO R0,_music2_mix
    IF intybasic_music_volume
	RETURN
    ELSE
	JR R5
    ENDI

@@3:    MVI _music2_mix,R0
	ANDI #$EF,R0
	MVO R0,_music2_mix
@@0:	
    IF intybasic_music_volume
	RETURN
    ELSE
	JR R5
    ENDI

	ENDP

    ENDI

    ENDI
    
    IF intybasic_numbers

;;==========================================================================;;
;; IntyBASIC SDK Library: print-num.asm                                     ;;
;;--------------------------------------------------------------------------;;
;;  This library is based on a BCD display algorithm originally proposed by ;;
;;  Mark Ball (GroovyBee), with additional optimizations suggested by Joe   ;;
;;  Zbiciak (intvnut) in the AtariAge Intellivision Programming forum.  It  ;;
;;  is a novel implementation of Joe's PRNUM16() routine, intended to       ;;
;;  execute much faster.                                                    ;;
;;                                                                          ;;
;;  The algorithm was then further optimized and adapted for the            ;;
;;  P-Machinery framework by unrolling the loops, etc.  It was then         ;;
;;  modified once again to support the original PRNUM16() functionality and ;;
;;  invocation interface, and serve as a drop-in replacement in the         ;;
;;  IntyBASIC run-time framework.                                           ;;
;;--------------------------------------------------------------------------;;
;;      The file is placed into the public domain by its author.            ;;
;;      All copyrights are hereby relinquished on the routines and data in  ;;
;;      this file.  -- James Pujals (DZ-Jay), 2024                          ;;
;;==========================================================================;;

;; ======================================================================== ;;
;;  PRINT_NUM16_PAD                                                         ;;
;;  Procedure to print an unsigned 16-bit value as a decimal number, left-  ;;
;;  or right-justified, with optional pre-padding.  It also supports        ;;
;;  variable field widths.                                                  ;;
;;                                                                          ;;
;;  DESCRIPTION:                                                            ;;
;;      Depending on the entry point invoked, the number is printed in      ;;
;;      either left- or right-justified format.  Right-justified numbers    ;;
;;      are padded with leading zeros or blanks to fit the given width.     ;;
;;      Left-justified numbers are not padded, and the field width argument ;;
;;      is ignored.                                                         ;;
;;                                                                          ;;
;;      Examples:                                                           ;;
;;          Routine               Value      Field       Output             ;;
;;          ------------------  ---------  ----------  ----------           ;;
;;          PRINT_NUM16_PAD.l      123        N/A       "123"               ;;
;;          PRINT_NUM16_PAD.b      123         3        "123"               ;;
;;          PRINT_NUM16_PAD.b      123         4        " 123"              ;;
;;          PRINT_NUM16_PAD.b      123         7        "    123"           ;;
;;          PRINT_NUM16_PAD.z      123         3        "123"               ;;
;;          PRINT_NUM16_PAD.z      123         4        "0123"              ;;
;;          PRINT_NUM16_PAD.z      123         7        "0000123"           ;;
;;                                                                          ;;
;;      After doing some housekeeping preparations for the variant invoked, ;;
;;      the routine then identifies the lowest power-of-10 that is higher   ;;
;;      than the input number.  It then proceeds to divide the number by    ;;
;;      decreasing powers-of-ten to derive each digit to print, in          ;;
;;      succession.  All divisions are made by repeated subtraction.        ;;
;;                                                                          ;;
;;      The routine does not access any RAM (other than the stack), or      ;;
;;      depend on any external resources, so it is fully re-entrant.        ;;
;;                                                                          ;;
;;  CODESIZE:                                                               ;;
;;      132 words, including jump tables and unrolled loops.                ;;
;;                                                                          ;;
;; ------------------------------------------------------------------------ ;;
;;                                                                          ;;
;;  There are three entry points to this procedure:                         ;;
;;      PRINT_NUM16_PAD.l       Prints a left-justified 16-bit number.      ;;
;;                                                                          ;;
;;      PRINT_NUM16_PAD.z       Prints a right-justified 16-bit number,     ;;
;;                              padded with zeros.                          ;;
;;                                                                          ;;
;;      PRINT_NUM16_PAD.b       Prints a right-justified 16-bit number,     ;;
;;                              padded with blanks.                         ;;
;;                                                                          ;;
;;  NOTE:   The field width must be equal to, or wider than, the decimal    ;;
;;          number width, or else the output will be corrupted.  Also, the  ;;
;;          format word must be a valid BACKTAB color value.  If the format ;;
;;          includes any other bits, it may corrupt the output.             ;;
;;                                                                          ;;
;;          The routine also supports field widths larger than 5 positions, ;;
;;          padding them with zeros or blanks, as necessary.  However, no   ;;
;;          bounds-checking is performed, so it is possible to attemp to    ;;
;;          print beyond the BACKTAB bounds.                                ;;
;;                                                                          ;;
;;  INPUT for PRINT_NUM16_PAD (all variations)                              ;;
;;      R0      16-bit numeric value.                                       ;;
;;      R2      Print field width.                                          ;;
;;      R3      BACKTAB format word for prefix char.                        ;;
;;      R4      Pointer to BACKTAB destination.                             ;;
;;      R5      Pointer to invocation record, followed by return address.   ;;
;;                                                                          ;;
;;  OUTPUT                                                                  ;;
;;      R0      Trashed.                                                    ;;
;;      R1      Trashed.                                                    ;;
;;      R2      Trashed.                                                    ;;
;;      R3      Trashed (color).                                            ;;
;;      R4      Trashed  (1 word beyond end of number string in BACKTAB).   ;;
;; ======================================================================== ;;
PRNUM16		PROC
.max_width      QSET    5
.chr_clrmask    QSET    $FE07
.chr_offset     QSET    (1 SHL 3)
.digit_base     QSET    ('0' - ' ')
.lzero          QSET    (((.digit_base -  0) SHL 3) AND $FFFF)
.lzero_even     QSET    (((.digit_base -  1) SHL 3) AND $FFFF)
.lzero_odd      QSET    (((.digit_base + 10) SHL 3) AND $FFFF)

                ; --------------------------------------
                ; Left-Justified (No Padding)
                ; --------------------------------------
@@l:            BEGIN

                MVII    #.chr_offset,           R5      ; Initialize character advancement term

                ; --------------------------------------
                ; Find highest power of 10 to determine
                ; entry point to digits printing loop.
                ;   (The loop is unrolled for speed.)
                ;
                ;   pow = 4;
                ;   do {
                ;       if (val >= (10 ** pow--)) {
                ;           break;
                ;       }
                ;   } while (pow >= 0);
                ; --------------------------------------
@@__l_10_4:     CMPI    #10000, R0                      ;   if (val >= (10 ** pow--))
                BC      @@__pow4                        ;       break;

@@__l_10_3:     CMPI    #1000,  R0                      ;   if (val >= (10 ** pow--))
                BC      @@__fix_10_3                    ;       break;

@@__l_10_2:     CMPI    #100,   R0                      ;   if (val >= (10 ** pow--))
                BC      @@__pow2                        ;       break;

@@__l_10_1:     CMPI    #10,    R0                      ;   if (val >= (10 ** pow--))
                BC      @@__fix_10_1                    ;       break;

@@__l_10_0:     TSTR    R0                              ;   if (val != 0)
                BNZE    @@__pow0                        ;       break;
                B       @@__zero

                ; --------------------------------------
                ; Right-Justified: Zero-Padded
                ; --------------------------------------
@@z:            XORI    #.lzero,R3                      ; Initialize prefix to character "0" (zero).

                ; --------------------------------------
                ; Right-Justified: Blank-Padded
                ; --------------------------------------
@@b:            MOVR    R2,     R1                      ; \
                SUBI    #5,     R1                      ;  > Is field size greater than max width?
                BLE     @@__padding                     ; /     No:  Just pad field based on magnitude.
                                                        ;       Yes: Pad field until we reach max width.
                ; --------------------------------------
                ; Force padding until we reach max width
                ;   while (overflow > 0) {
                ;       print_at(prefix, pos++);
                ;       overflow--;
                ;   }
                ; --------------------------------------
                SUBR    R1,     R2                      ; R1 = overflow; R2 = max width
@@__pad_ovr:    MVO@    R3,     R4                      ; Print padding character ...
                DECR    R1                              ; \_ Is overflow done?
                BNZE    @@__pad_ovr                     ; /     No:  Continue padding.

@@__padding:    BEGIN

                MOVR    R3,     R1
                ANDI    #.chr_clrmask,          R3      ; Clear out prefix character
                MVII    #.chr_offset,           R5      ; Initialize character advancement term

                ADDI    #(@@__switch - 1),      R2      ; \_ Jump to entry point based on field width
                MVI@    R2,     PC                      ; /

@@__switch:     DECLE   @@__p_10_0  ; Width = 1: 10^0
                DECLE   @@__p_10_1  ; Width = 2: 10^1
                DECLE   @@__p_10_2  ; Width = 3: 10^2
                DECLE   @@__p_10_3  ; Width = 4: 10^3
                DECLE   @@__p_10_4  ; Width = 5: 10^4

                ; --------------------------------------
                ; Pad the field with prefix character
                ;   (The loop is unrolled for speed.)
                ;
                ;   pow = 4;  // 10^0..10^4
                ;   do {
                ;       if (val >= (10 ** pow--)) {
                ;           break;
                ;       }
                ;       print_at(prefix, pos++);
                ;   } while (pow >= 0);
                ; --------------------------------------
@@__p_10_4:     CMPI    #10000, R0                      ;   if (val >= (10 ** pow--))
                BC      @@__pow4                        ;       break;
                MVO@    R1,     R4                      ;   print_at(prefix, pos++);

@@__p_10_3:     CMPI    #1000,  R0                      ;   if (val >= (10 ** pow--))
                BC      @@__fix_10_3                    ;       break;
                MVO@    R1,     R4                      ;   print_at(prefix, pos++);

@@__p_10_2:     CMPI    #100,   R0                      ;   if (val >= (10 ** pow--))
                BC      @@__pow2                        ;       break;
                MVO@    R1,     R4                      ;   print_at(prefix, pos++);

@@__p_10_1:     CMPI    #10,    R0                      ;   if (val >= (10 ** pow--))
                BC      @@__fix_10_1                    ;       break;
                MVO@    R1,     R4                      ;   print_at(prefix, pos++);

@@__p_10_0:     TSTR    R0                              ;   if (val != 0)
                BNZE    @@__pow0                        ;       break;

                ; --------------------------------------
                ; Special case for when value is zero
                ; --------------------------------------
@@__zero:       XORI    #.lzero,R3                      ; Prepare formatted zero
                MVO@    R3,     R4                      ;       print_at(zero, pos++);
                RETURN

                ; --------------------------------------
                ; Adjust value of odd powers, for direct
                ; entry into the PRINT_NUM16() routine.
                ; --------------------------------------
@@__fix_10_1:   SUBI    #100,   R0                      ; \_ Adjust value to jump into 10^1 block
                B       @@__pow1                        ; /

@@__fix_10_3:   SUBI    #10000, R0                      ; \_ Adjust value to jump into 10^3 block
                B       @@__pow3                        ; /

                ; --------------------------------------
                ; Print decimal digits
                ; --------------------------------------

                ; 10^4: 10,000
                ; --------------------------------------
@@__pow4:       MVII    #.lzero_even,           R1      ; Prep GROM character.
                XORR    R3,     R1                      ; Mix in the STIC colors.
                MVII    #10000, R2

@@__d_10_4:     ADDR    R5,     R1
                SUBR    R2,     R0
                BC      @@__d_10_4
                MVO@    R1,     R4                      ; Output to BACKTAB screen buffer.

                ; 10^3: 1,000
                ; --------------------------------------
@@__pow3:       MVII    #.lzero_odd,            R1      ; Prep GROM character.
                XORR    R3,     R1                      ; Mix in the STIC colors.
                MVII    #1000,  R2

@@__d_10_3:     SUBR    R5,     R1
                ADDR    R2,     R0
                BNC     @@__d_10_3
                MVO@    R1,     R4                      ; Output to BACKTAB screen buffer.

                ; 10^2: 100
                ; --------------------------------------
@@__pow2:       MVII    #.lzero_even,           R1      ; Prep GROM character.
                XORR    R3,     R1                      ; Mix in the STIC colors.
                MVII    #100,   R2

@@__d_10_2:     ADDR    R5,     R1
                SUBR    R2,     R0
                BC      @@__d_10_2
                MVO@    R1,     R4                      ; Output to BACKTAB screen buffer.

                ; 10^1: 10
                ; --------------------------------------
@@__pow1:       MVII    #.lzero_odd,            R1      ; Prep GROM character.
                XORR    R3,     R1                      ; Mix in the STIC colors.
                MVII    #10,    R2

@@__d_10_1:     SUBR    R5,     R1
                ADDR    R2,     R0
                BNC     @@__d_10_1
                MVO@    R1,     R4                      ; Output to BACKTAB screen buffer.

                ; 10^0: 1
                ; --------------------------------------
@@__pow0:       ADDI    #.digit_base,           R0      ; Prep GROM character.
                SLL     R0,     2                       ; \
                SLL     R0,     1                       ;  > chr = ((chr << 3) ^ format);
                XORR    R3,     R0                      ; /
                MVO@    R0,     R4                      ; Output to BACKTAB screen buffer.

                ; All done!
                ; --------------------------------------
                RETURN

@@____size:     EQU     ($ - PRNUM16)
                ENDP

;; ======================================================================== ;;
;;  EOF: romseg-bs.mac                                                      ;;
;; ======================================================================== ;;

    ENDI

    IF intybasic_voice
;;==========================================================================;;
;;  SP0256-AL2 Allophones						   ;;
;;									  ;;
;;  This file contains the allophone set that was obtained from an	  ;;
;;  SP0256-AL2.  It is being provided for your convenience.		 ;;
;;									  ;;
;;  The directory "al2" contains a series of assembly files, each one       ;;
;;  containing a single allophone.  This series of files may be useful in   ;;
;;  situations where space is at a premium.				 ;;
;;									  ;;
;;  Consult the Archer SP0256-AL2 documentation (under doc/programming)     ;;
;;  for more information about SP0256-AL2's allophone library.	      ;;
;;									  ;;
;; ------------------------------------------------------------------------ ;;
;;									  ;;
;;  Copyright information:						  ;;
;;									  ;;
;;  The allophone data below was extracted from the SP0256-AL2 ROM image.   ;;
;;  The SP0256-AL2 allophones are NOT in the public domain, nor are they    ;;
;;  placed under the GNU General Public License.  This program is	   ;;
;;  distributed in the hope that it will be useful, but WITHOUT ANY	 ;;
;;  WARRANTY; without even the implied warranty of MERCHANTABILITY or       ;;
;;  FITNESS FOR A PARTICULAR PURPOSE.				       ;;
;;									  ;;
;;  Microchip, Inc. retains the copyright to the data and algorithms	;;
;;  contained in the SP0256-AL2.  This speech data is distributed with      ;;
;;  explicit permission from Microchip, Inc.  All such redistributions      ;;
;;  must retain this notice of copyright.				   ;;
;;									  ;;
;;  No copyright claims are made on this data by the author(s) of SDK1600.  ;;
;;  Please see http://spatula-city.org/~im14u2c/sp0256-al2/ for details.    ;;
;;									  ;;
;;==========================================================================;;

;; ------------------------------------------------------------------------ ;;
_AA:
    DECLE   _AA.end - _AA - 1
    DECLE   $0318, $014C, $016F, $02CE, $03AF, $015F, $01B1, $008E
    DECLE   $0088, $0392, $01EA, $024B, $03AA, $039B, $000F, $0000
_AA.end:  ; 16 decles
;; ------------------------------------------------------------------------ ;;
_AE1:
    DECLE   _AE1.end - _AE1 - 1
    DECLE   $0118, $038E, $016E, $01FC, $0149, $0043, $026F, $036E
    DECLE   $01CC, $0005, $0000
_AE1.end:  ; 11 decles
;; ------------------------------------------------------------------------ ;;
_AO:
    DECLE   _AO.end - _AO - 1
    DECLE   $0018, $010E, $016F, $0225, $00C6, $02C4, $030F, $0160
    DECLE   $024B, $0005, $0000
_AO.end:  ; 11 decles
;; ------------------------------------------------------------------------ ;;
_AR:
    DECLE   _AR.end - _AR - 1
    DECLE   $0218, $010C, $016E, $001E, $000B, $0091, $032F, $00DE
    DECLE   $018B, $0095, $0003, $0238, $0027, $01E0, $03E8, $0090
    DECLE   $0003, $01C7, $0020, $03DE, $0100, $0190, $01CA, $02AB
    DECLE   $00B7, $004A, $0386, $0100, $0144, $02B6, $0024, $0320
    DECLE   $0011, $0041, $01DF, $0316, $014C, $016E, $001E, $00C4
    DECLE   $02B2, $031E, $0264, $02AA, $019D, $01BE, $000B, $00F0
    DECLE   $006A, $01CE, $00D6, $015B, $03B5, $03E4, $0000, $0380
    DECLE   $0007, $0312, $03E8, $030C, $016D, $02EE, $0085, $03C2
    DECLE   $03EC, $0283, $024A, $0005, $0000
_AR.end:  ; 69 decles
;; ------------------------------------------------------------------------ ;;
_AW:
    DECLE   _AW.end - _AW - 1
    DECLE   $0010, $01CE, $016E, $02BE, $0375, $034F, $0220, $0290
    DECLE   $008A, $026D, $013F, $01D5, $0316, $029F, $02E2, $018A
    DECLE   $0170, $0035, $00BD, $0000, $0000
_AW.end:  ; 21 decles
;; ------------------------------------------------------------------------ ;;
_AX:
    DECLE   _AX.end - _AX - 1
    DECLE   $0218, $02CD, $016F, $02F5, $0386, $00C2, $00CD, $0094
    DECLE   $010C, $0005, $0000
_AX.end:  ; 11 decles
;; ------------------------------------------------------------------------ ;;
_AY:
    DECLE   _AY.end - _AY - 1
    DECLE   $0110, $038C, $016E, $03B7, $03B3, $02AF, $0221, $009E
    DECLE   $01AA, $01B3, $00BF, $02E7, $025B, $0354, $00DA, $017F
    DECLE   $018A, $03F3, $00AF, $02D5, $0356, $027F, $017A, $01FB
    DECLE   $011E, $01B9, $03E5, $029F, $025A, $0076, $0148, $0124
    DECLE   $003D, $0000
_AY.end:  ; 34 decles
;; ------------------------------------------------------------------------ ;;
_BB1:
    DECLE   _BB1.end - _BB1 - 1
    DECLE   $0318, $004C, $016C, $00FB, $00C7, $0144, $002E, $030C
    DECLE   $010E, $018C, $01DC, $00AB, $00C9, $0268, $01F7, $021D
    DECLE   $01B3, $0098, $0000
_BB1.end:  ; 19 decles
;; ------------------------------------------------------------------------ ;;
_BB2:
    DECLE   _BB2.end - _BB2 - 1
    DECLE   $00F4, $0046, $0062, $0200, $0221, $03E4, $0087, $016F
    DECLE   $02A6, $02B7, $0212, $0326, $0368, $01BF, $0338, $0196
    DECLE   $0002
_BB2.end:  ; 17 decles
;; ------------------------------------------------------------------------ ;;
_CH:
    DECLE   _CH.end - _CH - 1
    DECLE   $00F5, $0146, $0052, $0000, $032A, $0049, $0032, $02F2
    DECLE   $02A5, $0000, $026D, $0119, $0124, $00F6, $0000
_CH.end:  ; 15 decles
;; ------------------------------------------------------------------------ ;;
_DD1:
    DECLE   _DD1.end - _DD1 - 1
    DECLE   $0318, $034C, $016E, $0397, $01B9, $0020, $02B1, $008E
    DECLE   $0349, $0291, $01D8, $0072, $0000
_DD1.end:  ; 13 decles
;; ------------------------------------------------------------------------ ;;
_DD2:
    DECLE   _DD2.end - _DD2 - 1
    DECLE   $00F4, $00C6, $00F2, $0000, $0129, $00A6, $0246, $01F3
    DECLE   $02C6, $02B7, $028E, $0064, $0362, $01CF, $0379, $01D5
    DECLE   $0002
_DD2.end:  ; 17 decles
;; ------------------------------------------------------------------------ ;;
_DH1:
    DECLE   _DH1.end - _DH1 - 1
    DECLE   $0018, $034F, $016D, $030B, $0306, $0363, $017E, $006A
    DECLE   $0164, $019E, $01DA, $00CB, $00E8, $027A, $03E8, $01D7
    DECLE   $0173, $00A1, $0000
_DH1.end:  ; 19 decles
;; ------------------------------------------------------------------------ ;;
_DH2:
    DECLE   _DH2.end - _DH2 - 1
    DECLE   $0119, $034C, $016D, $030B, $0306, $0363, $017E, $006A
    DECLE   $0164, $019E, $01DA, $00CB, $00E8, $027A, $03E8, $01D7
    DECLE   $0173, $00A1, $0000
_DH2.end:  ; 19 decles
;; ------------------------------------------------------------------------ ;;
_EH:
    DECLE   _EH.end - _EH - 1
    DECLE   $0218, $02CD, $016F, $0105, $014B, $0224, $02CF, $0274
    DECLE   $014C, $0005, $0000
_EH.end:  ; 11 decles
;; ------------------------------------------------------------------------ ;;
_EL:
    DECLE   _EL.end - _EL - 1
    DECLE   $0118, $038D, $016E, $011C, $008B, $03D2, $030F, $0262
    DECLE   $006C, $019D, $01CC, $022B, $0170, $0078, $03FE, $0018
    DECLE   $0183, $03A3, $010D, $016E, $012E, $00C6, $00C3, $0300
    DECLE   $0060, $000D, $0005, $0000
_EL.end:  ; 28 decles
;; ------------------------------------------------------------------------ ;;
_ER1:
    DECLE   _ER1.end - _ER1 - 1
    DECLE   $0118, $034C, $016E, $001C, $0089, $01C3, $034E, $03E6
    DECLE   $00AB, $0095, $0001, $0000, $03FC, $0381, $0000, $0188
    DECLE   $01DA, $00CB, $00E7, $0048, $03A6, $0244, $016C, $01A8
    DECLE   $03E4, $0000, $0002, $0001, $00FC, $01DA, $02E4, $0000
    DECLE   $0002, $0008, $0200, $0217, $0164, $0000, $000E, $0038
    DECLE   $0014, $01EA, $0264, $0000, $0002, $0048, $01EC, $02F1
    DECLE   $03CC, $016D, $021E, $0048, $00C2, $034E, $036A, $000D
    DECLE   $008D, $000B, $0200, $0047, $0022, $03A8, $0000, $0000
_ER1.end:  ; 64 decles
;; ------------------------------------------------------------------------ ;;
_ER2:
    DECLE   _ER2.end - _ER2 - 1
    DECLE   $0218, $034C, $016E, $001C, $0089, $01C3, $034E, $03E6
    DECLE   $00AB, $0095, $0001, $0000, $03FC, $0381, $0000, $0190
    DECLE   $01D8, $00CB, $00E7, $0058, $01A6, $0244, $0164, $02A9
    DECLE   $0024, $0000, $0000, $0007, $0201, $02F8, $02E4, $0000
    DECLE   $0002, $0001, $00FC, $02DA, $0024, $0000, $0002, $0008
    DECLE   $0200, $0217, $0024, $0000, $000E, $0038, $0014, $03EA
    DECLE   $03A4, $0000, $0002, $0048, $01EC, $03F1, $038C, $016D
    DECLE   $021E, $0048, $00C2, $034E, $036A, $000D, $009D, $0003
    DECLE   $0200, $0047, $0022, $03A8, $0000, $0000
_ER2.end:  ; 70 decles
;; ------------------------------------------------------------------------ ;;
_EY:
    DECLE   _EY.end - _EY - 1
    DECLE   $0310, $038C, $016E, $02A7, $00BB, $0160, $0290, $0094
    DECLE   $01CA, $03A9, $00C1, $02D7, $015B, $01D4, $03CE, $02FF
    DECLE   $00EA, $03E7, $0041, $0277, $025B, $0355, $03C9, $0103
    DECLE   $02EA, $03E4, $003F, $0000
_EY.end:  ; 28 decles
;; ------------------------------------------------------------------------ ;;
_FF:
    DECLE   _FF.end - _FF - 1
    DECLE   $0119, $03C8, $0000, $00A7, $0094, $0138, $01C6, $0000
_FF.end:  ; 8 decles
;; ------------------------------------------------------------------------ ;;
_GG1:
    DECLE   _GG1.end - _GG1 - 1
    DECLE   $00F4, $00C6, $00C2, $0200, $0015, $03FE, $0283, $01FD
    DECLE   $01E6, $00B7, $030A, $0364, $0331, $017F, $033D, $0215
    DECLE   $0002
_GG1.end:  ; 17 decles
;; ------------------------------------------------------------------------ ;;
_GG2:
    DECLE   _GG2.end - _GG2 - 1
    DECLE   $00F4, $0106, $0072, $0300, $0021, $0308, $0039, $0173
    DECLE   $00C6, $00B7, $037E, $03A3, $0319, $0177, $0036, $0217
    DECLE   $0002
_GG2.end:  ; 17 decles
;; ------------------------------------------------------------------------ ;;
_GG3:
    DECLE   _GG3.end - _GG3 - 1
    DECLE   $00F8, $0146, $00F2, $0100, $0132, $03A8, $0055, $01F5
    DECLE   $00A6, $02B7, $0291, $0326, $0368, $0167, $023A, $01C6
    DECLE   $0002
_GG3.end:  ; 17 decles
;; ------------------------------------------------------------------------ ;;
_HH1:
    DECLE   _HH1.end - _HH1 - 1
    DECLE   $0218, $01C9, $0000, $0095, $0127, $0060, $01D6, $0213
    DECLE   $0002, $01AE, $033E, $01A0, $03C4, $0122, $0001, $0218
    DECLE   $01E4, $03FD, $0019, $0000
_HH1.end:  ; 20 decles
;; ------------------------------------------------------------------------ ;;
_HH2:
    DECLE   _HH2.end - _HH2 - 1
    DECLE   $0218, $00CB, $0000, $0086, $000F, $0240, $0182, $031A
    DECLE   $02DB, $0008, $0293, $0067, $00BD, $01E0, $0092, $000C
    DECLE   $0000
_HH2.end:  ; 17 decles
;; ------------------------------------------------------------------------ ;;
_IH:
    DECLE   _IH.end - _IH - 1
    DECLE   $0118, $02CD, $016F, $0205, $0144, $02C3, $00FE, $031A
    DECLE   $000D, $0005, $0000
_IH.end:  ; 11 decles
;; ------------------------------------------------------------------------ ;;
_IY:
    DECLE   _IY.end - _IY - 1
    DECLE   $0318, $02CC, $016F, $0008, $030B, $01C3, $0330, $0178
    DECLE   $002B, $019D, $01F6, $018B, $01E1, $0010, $020D, $0358
    DECLE   $015F, $02A4, $02CC, $016F, $0109, $030B, $0193, $0320
    DECLE   $017A, $034C, $009C, $0017, $0001, $0200, $03C1, $0020
    DECLE   $00A7, $001D, $0001, $0104, $003D, $0040, $01A7, $01CA
    DECLE   $018B, $0160, $0078, $01F6, $0343, $01C7, $0090, $0000
_IY.end:  ; 48 decles
;; ------------------------------------------------------------------------ ;;
_JH:
    DECLE   _JH.end - _JH - 1
    DECLE   $0018, $0149, $0001, $00A4, $0321, $0180, $01F4, $039A
    DECLE   $02DC, $023C, $011A, $0047, $0200, $0001, $018E, $034E
    DECLE   $0394, $0356, $02C1, $010C, $03FD, $0129, $00B7, $01BA
    DECLE   $0000
_JH.end:  ; 25 decles
;; ------------------------------------------------------------------------ ;;
_KK1:
    DECLE   _KK1.end - _KK1 - 1
    DECLE   $00F4, $00C6, $00D2, $0000, $023A, $03E0, $02D1, $02E5
    DECLE   $0184, $0200, $0041, $0210, $0188, $00C5, $0000
_KK1.end:  ; 15 decles
;; ------------------------------------------------------------------------ ;;
_KK2:
    DECLE   _KK2.end - _KK2 - 1
    DECLE   $021D, $023C, $0211, $003C, $0180, $024D, $0008, $032B
    DECLE   $025B, $002D, $01DC, $01E3, $007A, $0000
_KK2.end:  ; 14 decles
;; ------------------------------------------------------------------------ ;;
_KK3:
    DECLE   _KK3.end - _KK3 - 1
    DECLE   $00F7, $0046, $01D2, $0300, $0131, $006C, $006E, $00F1
    DECLE   $00E4, $0000, $025A, $010D, $0110, $01F9, $014A, $0001
    DECLE   $00B5, $01A2, $00D8, $01CE, $0000
_KK3.end:  ; 21 decles
;; ------------------------------------------------------------------------ ;;
_LL:
    DECLE   _LL.end - _LL - 1
    DECLE   $0318, $038C, $016D, $029E, $0333, $0260, $0221, $0294
    DECLE   $01C4, $0299, $025A, $00E6, $014C, $012C, $0031, $0000
_LL.end:  ; 16 decles
;; ------------------------------------------------------------------------ ;;
_MM:
    DECLE   _MM.end - _MM - 1
    DECLE   $0210, $034D, $016D, $03F5, $00B0, $002E, $0220, $0290
    DECLE   $03CE, $02B6, $03AA, $00F3, $00CF, $015D, $016E, $0000
_MM.end:  ; 16 decles
;; ------------------------------------------------------------------------ ;;
_NG1:
    DECLE   _NG1.end - _NG1 - 1
    DECLE   $0118, $03CD, $016E, $00DC, $032F, $01BF, $01E0, $0116
    DECLE   $02AB, $029A, $0358, $01DB, $015B, $01A7, $02FD, $02B1
    DECLE   $03D2, $0356, $0000
_NG1.end:  ; 19 decles
;; ------------------------------------------------------------------------ ;;
_NN1:
    DECLE   _NN1.end - _NN1 - 1
    DECLE   $0318, $03CD, $016C, $0203, $0306, $03C3, $015F, $0270
    DECLE   $002A, $009D, $000D, $0248, $01B4, $0120, $01E1, $00C8
    DECLE   $0003, $0040, $0000, $0080, $015F, $0006, $0000
_NN1.end:  ; 23 decles
;; ------------------------------------------------------------------------ ;;
_NN2:
    DECLE   _NN2.end - _NN2 - 1
    DECLE   $0018, $034D, $016D, $0203, $0306, $03C3, $015F, $0270
    DECLE   $002A, $0095, $0003, $0248, $01B4, $0120, $01E1, $0090
    DECLE   $000B, $0040, $0000, $0080, $015F, $019E, $01F6, $028B
    DECLE   $00E0, $0266, $03F6, $01D8, $0143, $01A8, $0024, $00C0
    DECLE   $0080, $0000, $01E6, $0321, $0024, $0260, $000A, $0008
    DECLE   $03FE, $0000, $0000
_NN2.end:  ; 43 decles
;; ------------------------------------------------------------------------ ;;
_OR2:
    DECLE   _OR2.end - _OR2 - 1
    DECLE   $0218, $018C, $016D, $02A6, $03AB, $004F, $0301, $0390
    DECLE   $02EA, $0289, $0228, $0356, $01CF, $02D5, $0135, $007D
    DECLE   $02B5, $02AF, $024A, $02E2, $0153, $0167, $0333, $02A9
    DECLE   $02B3, $039A, $0351, $0147, $03CD, $0339, $02DA, $0000
_OR2.end:  ; 32 decles
;; ------------------------------------------------------------------------ ;;
_OW:
    DECLE   _OW.end - _OW - 1
    DECLE   $0310, $034C, $016E, $02AE, $03B1, $00CF, $0304, $0192
    DECLE   $018A, $022B, $0041, $0277, $015B, $0395, $03D1, $0082
    DECLE   $03CE, $00B6, $03BB, $02DA, $0000
_OW.end:  ; 21 decles
;; ------------------------------------------------------------------------ ;;
_OY:
    DECLE   _OY.end - _OY - 1
    DECLE   $0310, $014C, $016E, $02A6, $03AF, $00CF, $0304, $0192
    DECLE   $03CA, $01A8, $007F, $0155, $02B4, $027F, $00E2, $036A
    DECLE   $031F, $035D, $0116, $01D5, $02F4, $025F, $033A, $038A
    DECLE   $014F, $01B5, $03D5, $0297, $02DA, $03F2, $0167, $0124
    DECLE   $03FB, $0001
_OY.end:  ; 34 decles
;; ------------------------------------------------------------------------ ;;
_PA1:
    DECLE   _PA1.end - _PA1 - 1
    DECLE   $00F1, $0000
_PA1.end:  ; 2 decles
;; ------------------------------------------------------------------------ ;;
_PA2:
    DECLE   _PA2.end - _PA2 - 1
    DECLE   $00F4, $0000
_PA2.end:  ; 2 decles
;; ------------------------------------------------------------------------ ;;
_PA3:
    DECLE   _PA3.end - _PA3 - 1
    DECLE   $00F7, $0000
_PA3.end:  ; 2 decles
;; ------------------------------------------------------------------------ ;;
_PA4:
    DECLE   _PA4.end - _PA4 - 1
    DECLE   $00FF, $0000
_PA4.end:  ; 2 decles
;; ------------------------------------------------------------------------ ;;
_PA5:
    DECLE   _PA5.end - _PA5 - 1
    DECLE   $031D, $003F, $0000
_PA5.end:  ; 3 decles
;; ------------------------------------------------------------------------ ;;
_PP:
    DECLE   _PP.end - _PP - 1
    DECLE   $00FD, $0106, $0052, $0000, $022A, $03A5, $0277, $035F
    DECLE   $0184, $0000, $0055, $0391, $00EB, $00CF, $0000
_PP.end:  ; 15 decles
;; ------------------------------------------------------------------------ ;;
_RR1:
    DECLE   _RR1.end - _RR1 - 1
    DECLE   $0118, $01CD, $016C, $029E, $0171, $038E, $01E0, $0190
    DECLE   $0245, $0299, $01AA, $02E2, $01C7, $02DE, $0125, $00B5
    DECLE   $02C5, $028F, $024E, $035E, $01CB, $02EC, $0005, $0000
_RR1.end:  ; 24 decles
;; ------------------------------------------------------------------------ ;;
_RR2:
    DECLE   _RR2.end - _RR2 - 1
    DECLE   $0218, $03CC, $016C, $030C, $02C8, $0393, $02CD, $025E
    DECLE   $008A, $019D, $01AC, $02CB, $00BE, $0046, $017E, $01C2
    DECLE   $0174, $00A1, $01E5, $00E0, $010E, $0007, $0313, $0017
    DECLE   $0000
_RR2.end:  ; 25 decles
;; ------------------------------------------------------------------------ ;;
_SH:
    DECLE   _SH.end - _SH - 1
    DECLE   $0218, $0109, $0000, $007A, $0187, $02E0, $03F6, $0311
    DECLE   $0002, $0126, $0242, $0161, $03E9, $0219, $016C, $0300
    DECLE   $0013, $0045, $0124, $0005, $024C, $005C, $0182, $03C2
    DECLE   $0001
_SH.end:  ; 25 decles
;; ------------------------------------------------------------------------ ;;
_SS:
    DECLE   _SS.end - _SS - 1
    DECLE   $0218, $01CA, $0001, $0128, $001C, $0149, $01C6, $0000
_SS.end:  ; 8 decles
;; ------------------------------------------------------------------------ ;;
_TH:
    DECLE   _TH.end - _TH - 1
    DECLE   $0019, $0349, $0000, $00C6, $0212, $01D8, $01CA, $0000
_TH.end:  ; 8 decles
;; ------------------------------------------------------------------------ ;;
_TT1:
    DECLE   _TT1.end - _TT1 - 1
    DECLE   $00F6, $0046, $0142, $0100, $0042, $0088, $027E, $02EF
    DECLE   $01A4, $0200, $0049, $0290, $00FC, $00E8, $0000
_TT1.end:  ; 15 decles
;; ------------------------------------------------------------------------ ;;
_TT2:
    DECLE   _TT2.end - _TT2 - 1
    DECLE   $00F5, $00C6, $01D2, $0100, $0335, $00E9, $0042, $027A
    DECLE   $02A4, $0000, $0062, $01D1, $014C, $03EA, $02EC, $01E0
    DECLE   $0007, $03A7, $0000
_TT2.end:  ; 19 decles
;; ------------------------------------------------------------------------ ;;
_UH:
    DECLE   _UH.end - _UH - 1
    DECLE   $0018, $034E, $016E, $01FF, $0349, $00D2, $003C, $030C
    DECLE   $008B, $0005, $0000
_UH.end:  ; 11 decles
;; ------------------------------------------------------------------------ ;;
_UW1:
    DECLE   _UW1.end - _UW1 - 1
    DECLE   $0318, $014C, $016F, $029E, $03BD, $03BD, $0271, $0212
    DECLE   $0325, $0291, $016A, $027B, $014A, $03B4, $0133, $0001
_UW1.end:  ; 16 decles
;; ------------------------------------------------------------------------ ;;
_UW2:
    DECLE   _UW2.end - _UW2 - 1
    DECLE   $0018, $034E, $016E, $02F6, $0107, $02C2, $006D, $0090
    DECLE   $03AC, $01A4, $01DC, $03AB, $0128, $0076, $03E6, $0119
    DECLE   $014F, $03A6, $03A5, $0020, $0090, $0001, $02EE, $00BB
    DECLE   $0000
_UW2.end:  ; 25 decles
;; ------------------------------------------------------------------------ ;;
_VV:
    DECLE   _VV.end - _VV - 1
    DECLE   $0218, $030D, $016C, $010B, $010B, $0095, $034F, $03E4
    DECLE   $0108, $01B5, $01BE, $028B, $0160, $00AA, $03E4, $0106
    DECLE   $00EB, $02DE, $014C, $016E, $00F6, $0107, $00D2, $00CD
    DECLE   $0296, $00E4, $0006, $0000
_VV.end:  ; 28 decles
;; ------------------------------------------------------------------------ ;;
_WH:
    DECLE   _WH.end - _WH - 1
    DECLE   $0218, $00C9, $0000, $0084, $038E, $0147, $03A4, $0195
    DECLE   $0000, $012E, $0118, $0150, $02D1, $0232, $01B7, $03F1
    DECLE   $0237, $01C8, $03B1, $0227, $01AE, $0254, $0329, $032D
    DECLE   $01BF, $0169, $019A, $0307, $0181, $028D, $0000
_WH.end:  ; 31 decles
;; ------------------------------------------------------------------------ ;;
_WW:
    DECLE   _WW.end - _WW - 1
    DECLE   $0118, $034D, $016C, $00FA, $02C7, $0072, $03CC, $0109
    DECLE   $000B, $01AD, $019E, $016B, $0130, $0278, $01F8, $0314
    DECLE   $017E, $029E, $014D, $016D, $0205, $0147, $02E2, $001A
    DECLE   $010A, $026E, $0004, $0000
_WW.end:  ; 28 decles
;; ------------------------------------------------------------------------ ;;
_XR2:
    DECLE   _XR2.end - _XR2 - 1
    DECLE   $0318, $034C, $016E, $02A6, $03BB, $002F, $0290, $008E
    DECLE   $004B, $0392, $01DA, $024B, $013A, $01DA, $012F, $00B5
    DECLE   $02E5, $0297, $02DC, $0372, $014B, $016D, $0377, $00E7
    DECLE   $0376, $038A, $01CE, $026B, $02FA, $01AA, $011E, $0071
    DECLE   $00D5, $0297, $02BC, $02EA, $01C7, $02D7, $0135, $0155
    DECLE   $01DD, $0007, $0000
_XR2.end:  ; 43 decles
;; ------------------------------------------------------------------------ ;;
_YR:
    DECLE   _YR.end - _YR - 1
    DECLE   $0318, $03CC, $016E, $0197, $00FD, $0130, $0270, $0094
    DECLE   $0328, $0291, $0168, $007E, $01CC, $02F5, $0125, $02B5
    DECLE   $00F4, $0298, $01DA, $03F6, $0153, $0126, $03B9, $00AB
    DECLE   $0293, $03DB, $0175, $01B9, $0001
_YR.end:  ; 29 decles
;; ------------------------------------------------------------------------ ;;
_YY1:
    DECLE   _YY1.end - _YY1 - 1
    DECLE   $0318, $01CC, $016E, $0015, $00CB, $0263, $0320, $0078
    DECLE   $01CE, $0094, $001F, $0040, $0320, $03BF, $0230, $00A7
    DECLE   $000F, $01FE, $03FC, $01E2, $00D0, $0089, $000F, $0248
    DECLE   $032B, $03FD, $01CF, $0001, $0000
_YY1.end:  ; 29 decles
;; ------------------------------------------------------------------------ ;;
_YY2:
    DECLE   _YY2.end - _YY2 - 1
    DECLE   $0318, $01CC, $016E, $0015, $00CB, $0263, $0320, $0078
    DECLE   $01CE, $0094, $001F, $0040, $0320, $03BF, $0230, $00A7
    DECLE   $000F, $01FE, $03FC, $01E2, $00D0, $0089, $000F, $0248
    DECLE   $032B, $03FD, $01CF, $0199, $01EE, $008B, $0161, $0232
    DECLE   $0004, $0318, $01A7, $0198, $0124, $03E0, $0001, $0001
    DECLE   $030F, $0027, $0000
_YY2.end:  ; 43 decles
;; ------------------------------------------------------------------------ ;;
_ZH:
    DECLE   _ZH.end - _ZH - 1
    DECLE   $0310, $014D, $016E, $00C3, $03B9, $01BF, $0241, $0012
    DECLE   $0163, $00E1, $0000, $0080, $0084, $023F, $003F, $0000
_ZH.end:  ; 16 decles
;; ------------------------------------------------------------------------ ;;
_ZZ:
    DECLE   _ZZ.end - _ZZ - 1
    DECLE   $0218, $010D, $016F, $0225, $0351, $00B5, $02A0, $02EE
    DECLE   $00E9, $014D, $002C, $0360, $0008, $00EC, $004C, $0342
    DECLE   $03D4, $0156, $0052, $0131, $0008, $03B0, $01BE, $0172
    DECLE   $0000
_ZZ.end:  ; 25 decles

;;==========================================================================;;
;;									  ;;
;;  Copyright information:						  ;;
;;									  ;;
;;  The above allophone data was extracted from the SP0256-AL2 ROM image.   ;;
;;  The SP0256-AL2 allophones are NOT in the public domain, nor are they    ;;
;;  placed under the GNU General Public License.  This program is	   ;;
;;  distributed in the hope that it will be useful, but WITHOUT ANY	 ;;
;;  WARRANTY; without even the implied warranty of MERCHANTABILITY or       ;;
;;  FITNESS FOR A PARTICULAR PURPOSE.				       ;;
;;									  ;;
;;  Microchip, Inc. retains the copyright to the data and algorithms	;;
;;  contained in the SP0256-AL2.  This speech data is distributed with      ;;
;;  explicit permission from Microchip, Inc.  All such redistributions      ;;
;;  must retain this notice of copyright.				   ;;
;;									  ;;
;;  No copyright claims are made on this data by the author(s) of SDK1600.  ;;
;;  Please see http://spatula-city.org/~im14u2c/sp0256-al2/ for details.    ;;
;;									  ;;
;;==========================================================================;;

;* ======================================================================== *;
;*  These routines are placed into the public domain by their author.  All  *;
;*  copyright rights are hereby relinquished on the routines and data in    *;
;*  this file.  -- Joseph Zbiciak, 2008				     *;
;* ======================================================================== *;

;; ======================================================================== ;;
;;  INTELLIVOICE DRIVER ROUTINES					    ;;
;;  Written in 2002 by Joe Zbiciak <intvnut AT gmail.com>		   ;;
;;  http://spatula-city.org/~im14u2c/intv/				  ;;
;; ======================================================================== ;;

;; ======================================================================== ;;
;;  GLOBAL VARIABLES USED BY THESE ROUTINES				 ;;
;;									  ;;
;;  Note that some of these routines may use one or more global variables.  ;;
;;  If you use these routines, you will need to allocate the appropriate    ;;
;;  space in either 16-bit or 8-bit memory as appropriate.  Each global     ;;
;;  variable is listed with the routines which use it and the required      ;;
;;  memory width.							   ;;
;;									  ;;
;;  Example declarations for these routines are shown below, commented out. ;;
;;  You should uncomment these and add them to your program to make use of  ;;
;;  the routine that needs them.  Make sure to assign these variables to    ;;
;;  locations that aren't used for anything else.			   ;;
;; ======================================================================== ;;

			; Used by       Req'd Width     Description
			;-----------------------------------------------------
;IV.QH      EQU $110    ; IV_xxx	8-bit	   Voice queue head
;IV.QT      EQU $111    ; IV_xxx	8-bit	   Voice queue tail
;IV.Q       EQU $112    ; IV_xxx	8-bit	   Voice queue  (8 bytes)
;IV.FLEN    EQU $11A    ; IV_xxx	8-bit	   Length of FIFO data
;IV.FPTR    EQU $320    ; IV_xxx	16-bit	  Current FIFO ptr.
;IV.PPTR    EQU $321    ; IV_xxx	16-bit	  Current Phrase ptr.

;; ======================================================================== ;;
;;  MEMORY USAGE							    ;;
;;									  ;;
;;  These routines implement a queue of "pending phrases" that will be      ;;
;;  played by the Intellivoice.  The user calls IV_PLAY to enqueue a	;;
;;  phrase number.  Phrase numbers indicate either a RESROM sample or       ;;
;;  a compiled in phrase to be spoken.				      ;;
;;									  ;;
;;  The user must compose an "IV_PHRASE_TBL", which is composed of	  ;;
;;  pointers to phrases to be spoken.  Phrases are strings of pointers      ;;
;;  and RESROM triggers, terminated by a NUL.			       ;;
;;									  ;;
;;  Phrase numbers 1 through 42 are RESROM samples.  Phrase numbers	 ;;
;;  43 through 255 index into the IV_PHRASE_TBL.			    ;;
;;									  ;;
;;  SPECIAL NOTES							   ;;
;;									  ;;
;;  Bit 7 of IV.QH and IV.QT is used to denote whether the Intellivoice     ;;
;;  is present.  If Intellivoice is present, this bit is clear.	     ;;
;;									  ;;
;;  Bit 6 of IV.QT is used to denote that we still need to do an ALD $00    ;;
;;  for FIFO'd voice data.						  ;;
;; ======================================================================== ;;
	    

;; ======================================================================== ;;
;;  NAME								    ;;
;;      IV_INIT     Initialize the Intellivoice			     ;;
;;									  ;;
;;  AUTHOR								  ;;
;;      Joseph Zbiciak <intvnut AT gmail.com>			       ;;
;;									  ;;
;;  REVISION HISTORY							;;
;;      15-Sep-2002 Initial revision . . . . . . . . . . .  J. Zbiciak      ;;
;;									  ;;
;;  INPUTS for IV_INIT						      ;;
;;      R5      Return address					      ;;
;;									  ;;
;;  OUTPUTS								 ;;
;;      R0      0 if Intellivoice found, -1 if not.			 ;;
;;									  ;;
;;  DESCRIPTION							     ;;
;;      Resets Intellivoice, determines if it is actually there, and	;;
;;      then initializes the IV structure.				  ;;
;; ------------------------------------------------------------------------ ;;
;;		   Copyright (c) 2002, Joseph Zbiciak		     ;;
;; ======================================================================== ;;

IV_INIT     PROC
	    MVII    #$0400, R0	  ;
	    MVO     R0,     $0081       ; Reset the Intellivoice

	    MVI     $0081,  R0	  ; \
	    RLC     R0,     2	   ;  |-- See if we detect Intellivoice
	    BOV     @@no_ivoice	 ; /    once we've reset it.

	    CLRR    R0		  ; 
	    MVO     R0,     IV.FPTR     ; No data for FIFO
	    MVO     R0,     IV.PPTR     ; No phrase being spoken
	    MVO     R0,     IV.QH       ; Clear our queue
	    MVO     R0,     IV.QT       ; Clear our queue
	    JR      R5		  ; Done!

@@no_ivoice:
	    CLRR    R0
	    MVO     R0,     IV.FPTR     ; No data for FIFO
	    MVO     R0,     IV.PPTR     ; No phrase being spoken
	    DECR    R0
	    MVO     R0,     IV.QH       ; Set queue to -1 ("No Intellivoice")
	    MVO     R0,     IV.QT       ; Set queue to -1 ("No Intellivoice")
;	    JR      R5		 ; Done!
	    B       _wait	       ; Special for IntyBASIC!
	    ENDP

;; ======================================================================== ;;
;;  NAME								    ;;
;;      IV_ISR      Interrupt service routine to feed Intellivoice	  ;;
;;									  ;;
;;  AUTHOR								  ;;
;;      Joseph Zbiciak <intvnut AT gmail.com>			       ;;
;;									  ;;
;;  REVISION HISTORY							;;
;;      15-Sep-2002 Initial revision . . . . . . . . . . .  J. Zbiciak      ;;
;;									  ;;
;;  INPUTS for IV_ISR						       ;;
;;      R5      Return address					      ;;
;;									  ;;
;;  OUTPUTS								 ;;
;;      R0, R1, R4 trashed.						 ;;
;;									  ;;
;;  NOTES								   ;;
;;      Call this from your main interrupt service routine.		 ;;
;; ------------------------------------------------------------------------ ;;
;;		   Copyright (c) 2002, Joseph Zbiciak		     ;;
;; ======================================================================== ;;
IV_ISR      PROC
	    ;; ------------------------------------------------------------ ;;
	    ;;  Check for Intellivoice.  Leave if none present.	     ;;
	    ;; ------------------------------------------------------------ ;;
	    MVI     IV.QT,  R1	  ; Get queue tail
	    SWAP    R1,     2
	    BPL     @@ok		; Bit 7 set? If yes: No Intellivoice
@@ald_busy:
@@leave     JR      R5		  ; Exit if no Intellivoice.

     
	    ;; ------------------------------------------------------------ ;;
	    ;;  Check to see if we pump samples into the FIFO.
	    ;; ------------------------------------------------------------ ;;
@@ok:       MVI     IV.FPTR, R4	 ; Get FIFO data pointer
	    TSTR    R4		  ; is it zero?
	    BEQ     @@no_fifodata       ; Yes:  No data for FIFO.
@@fifo_fill:
	    MVI     $0081,  R0	  ; Read speech FIFO ready bit
	    SLLC    R0,     1	   ; 
	    BC      @@fifo_busy     

	    MVI@    R4,     R0	  ; Get next word
	    MVO     R0,     $0081       ; write it to the FIFO

	    MVI     IV.FLEN, R0	 ;\
	    DECR    R0		  ; |-- Decrement our FIFO'd data length
	    MVO     R0,     IV.FLEN     ;/
	    BEQ     @@last_fifo	 ; If zero, we're done w/ FIFO
	    MVO     R4,     IV.FPTR     ; Otherwise, save new pointer
	    B       @@fifo_fill	 ; ...and keep trying to load FIFO

@@last_fifo MVO     R0,     IV.FPTR     ; done with FIFO loading.
					; fall into ALD processing.


	    ;; ------------------------------------------------------------ ;;
	    ;;  Try to do an Address Load.  We do this in two settings:     ;;
	    ;;   -- We have no FIFO data to load.			   ;;
	    ;;   -- We've loaded as much FIFO data as we can, but we	;;
	    ;;      might have an address load command to send for it.      ;;
	    ;; ------------------------------------------------------------ ;;
@@fifo_busy:
@@no_fifodata:
	    MVI     $0080,  R0	  ; Read LRQ bit from ALD register
	    SLLC    R0,     1
	    BNC     @@ald_busy	  ; LRQ is low, meaning we can't ALD.
					; So, leave.

	    ;; ------------------------------------------------------------ ;;
	    ;;  We can do an address load (ALD) on the SP0256.  Give FIFO   ;;
	    ;;  driven ALDs priority, since we already started the FIFO     ;;
	    ;;  load.  The "need ALD" bit is stored in bit 6 of IV.QT.      ;;
	    ;; ------------------------------------------------------------ ;;
	    ANDI    #$40,   R1	  ; Is "Need FIFO ALD" bit set?
	    BEQ     @@no_fifo_ald
	    XOR     IV.QT,  R1	  ;\__ Clear the "Need FIFO ALD" bit.
	    MVO     R1,     IV.QT       ;/
	    CLRR    R1
	    MVO     R1,     $80	 ; Load a 0 into ALD (trigger FIFO rd.)
	    JR      R5		  ; done!

	    ;; ------------------------------------------------------------ ;;
	    ;;  We don't need to ALD on behalf of the FIFO.  So, we grab    ;;
	    ;;  the next thing off our phrase list.			 ;;
	    ;; ------------------------------------------------------------ ;;
@@no_fifo_ald:
	    MVI     IV.PPTR, R4	 ; Get phrase pointer.
	    TSTR    R4		  ; Is it zero?
	    BEQ     @@next_phrase       ; Yes:  Get next phrase from queue.

	    MVI@    R4,     R0
	    TSTR    R0		  ; Is it end of phrase?
	    BNEQ    @@process_phrase    ; !=0:  Go do it.

	    MVO     R0,     IV.PPTR     ; 
@@next_phrase:
	    MVI     IV.QT,  R1	  ; reload queue tail (was trashed above)
	    MOVR    R1,     R0	  ; copy QT to R0 so we can increment it
	    ANDI    #$7,    R1	  ; Mask away flags in queue head
	    CMP     IV.QH,  R1	  ; Is it same as queue tail?
	    BEQ     @@leave	     ; Yes:  No more speech for now.

	    INCR    R0
	    ANDI    #$F7,   R0	  ; mask away the possible 'carry'
	    MVO     R0,     IV.QT       ; save updated queue tail

	    ADDI    #IV.Q,  R1	  ; Index into queue
	    MVI@    R1,     R4	  ; get next value from queue
	    CMPI    #43,    R4	  ; Is it a RESROM or Phrase?
	    BNC     @@play_resrom_r4
@@new_phrase:
;	    ADDI    #IV_PHRASE_TBL - 43, R4 ; Index into phrase table
;	    MVI@    R4,     R4	  ; Read from phrase table
	    MVO     R4,     IV.PPTR
	    JR      R5		  ; we'll get to this phrase next time.

@@play_resrom_r4:
	    MVO     R4,     $0080       ; Just ALD it
	    JR      R5		  ; and leave.

	    ;; ------------------------------------------------------------ ;;
	    ;;  We're in the middle of a phrase, so continue interpreting.  ;;
	    ;; ------------------------------------------------------------ ;;
@@process_phrase:
	    
	    MVO     R4,     IV.PPTR     ; save new phrase pointer
	    CMPI    #43,    R0	  ; Is it a RESROM cue?
	    BC      @@play_fifo	 ; Just ALD it and leave.
@@play_resrom_r0
	    MVO     R0,     $0080       ; Just ALD it
	    JR      R5		  ; and leave.
@@play_fifo:
	    MVI     IV.FPTR,R1	  ; Make sure not to stomp existing FIFO
	    TSTR    R1		  ; data.
	    BEQ     @@new_fifo_ok
	    DECR    R4		  ; Oops, FIFO data still playing,
	    MVO     R4,     IV.PPTR     ; so rewind.
	    JR      R5		  ; and leave.

@@new_fifo_ok:
	    MOVR    R0,     R4	  ;
	    MVI@    R4,     R0	  ; Get chunk length
	    MVO     R0,     IV.FLEN     ; Init FIFO chunk length
	    MVO     R4,     IV.FPTR     ; Init FIFO pointer
	    MVI     IV.QT,  R0	  ;\
	    XORI    #$40,   R0	  ; |- Set "Need ALD" bit in QT
	    MVO     R0,     IV.QT       ;/

  IF 1      ; debug code		;\
	    ANDI    #$40,   R0	  ; |   Debug code:  We should only
	    BNEQ    @@qtok	      ; |-- be here if "Need FIFO ALD" 
	    HLT     ;BUG!!	      ; |   was already clear.	 
@@qtok				  ;/    
  ENDI
	    JR      R5		  ; leave.

	    ENDP


;; ======================================================================== ;;
;;  NAME								    ;;
;;      IV_PLAY     Play a voice sample sequence.			   ;;
;;									  ;;
;;  AUTHOR								  ;;
;;      Joseph Zbiciak <intvnut AT gmail.com>			       ;;
;;									  ;;
;;  REVISION HISTORY							;;
;;      15-Sep-2002 Initial revision . . . . . . . . . . .  J. Zbiciak      ;;
;;									  ;;
;;  INPUTS for IV_PLAY						      ;;
;;      R5      Invocation record, followed by return address.	      ;;
;;		  1 DECLE    Phrase number to play.		       ;;
;;									  ;;
;;  INPUTS for IV_PLAY.1						    ;;
;;      R0      Address of phrase to play.				  ;;
;;      R5      Return address					      ;;
;;									  ;;
;;  OUTPUTS								 ;;
;;      R0, R1  trashed						     ;;
;;      Z==0    if item not successfully queued.			    ;;
;;      Z==1    if successfully queued.				     ;;
;;									  ;;
;;  NOTES								   ;;
;;      This code will drop phrases if the queue is full.		   ;;
;;      Phrase numbers 1..42 are RESROM samples.  43..255 will index	;;
;;      into the user-supplied IV_PHRASE_TBL.  43 will refer to the	 ;;
;;      first entry, 44 to the second, and so on.  Phrase 0 is undefined.   ;;
;;									  ;;
;; ------------------------------------------------------------------------ ;;
;;		   Copyright (c) 2002, Joseph Zbiciak		     ;;
;; ======================================================================== ;;
IV_PLAY     PROC
	    MVI@    R5,     R0

@@1:	; alternate entry point
	    MVI     IV.QT,  R1	  ; Get queue tail
	    SWAP    R1,     2	   ;\___ Leave if "no Intellivoice"
	    BMI     @@leave	     ;/    bit it set.
@@ok:       
	    DECR    R1		  ;\
	    ANDI    #$7,    R1	  ; |-- See if we still have room
	    CMP     IV.QH,  R1	  ;/
	    BEQ     @@leave	     ; Leave if we're full

@@2:	MVI     IV.QH,  R1	  ; Get our queue head pointer
	    PSHR    R1		  ;\
	    INCR    R1		  ; |
	    ANDI    #$F7,   R1	  ; |-- Increment it, removing
	    MVO     R1,     IV.QH       ; |   carry but preserving flags.
	    PULR    R1		  ;/

	    ADDI    #IV.Q,  R1	  ;\__ Store phrase to queue
	    MVO@    R0,     R1	  ;/

@@leave:    JR      R5		  ; Leave.
	    ENDP

;; ======================================================================== ;;
;;  NAME								    ;;
;;      IV_PLAYW    Play a voice sample sequence.  Wait for queue room.     ;;
;;									  ;;
;;  AUTHOR								  ;;
;;      Joseph Zbiciak <intvnut AT gmail.com>			       ;;
;;									  ;;
;;  REVISION HISTORY							;;
;;      15-Sep-2002 Initial revision . . . . . . . . . . .  J. Zbiciak      ;;
;;									  ;;
;;  INPUTS for IV_PLAY						      ;;
;;      R5      Invocation record, followed by return address.	      ;;
;;		  1 DECLE    Phrase number to play.		       ;;
;;									  ;;
;;  INPUTS for IV_PLAY.1						    ;;
;;      R0      Address of phrase to play.				  ;;
;;      R5      Return address					      ;;
;;									  ;;
;;  OUTPUTS								 ;;
;;      R0, R1  trashed						     ;;
;;									  ;;
;;  NOTES								   ;;
;;      This code will wait for a queue slot to open if queue is full.      ;;
;;      Phrase numbers 1..42 are RESROM samples.  43..255 will index	;;
;;      into the user-supplied IV_PHRASE_TBL.  43 will refer to the	 ;;
;;      first entry, 44 to the second, and so on.  Phrase 0 is undefined.   ;;
;;									  ;;
;; ------------------------------------------------------------------------ ;;
;;		   Copyright (c) 2002, Joseph Zbiciak		     ;;
;; ======================================================================== ;;
IV_PLAYW    PROC
	    MVI@    R5,     R0

@@1:	; alternate entry point
	    MVI     IV.QT,  R1	  ; Get queue tail
	    SWAP    R1,     2	   ;\___ Leave if "no Intellivoice"
	    BMI     IV_PLAY.leave       ;/    bit it set.
@@ok:       
	    DECR    R1		  ;\
	    ANDI    #$7,    R1	  ; |-- See if we still have room
	    CMP     IV.QH,  R1	  ;/
	    BEQ     @@1		 ; wait for room
	    B       IV_PLAY.2

	    ENDP

;; ======================================================================== ;;
;;  NAME								    ;;
;;      IV_HUSH     Flush the speech queue, and hush the Intellivoice.      ;;
;;									  ;;
;;  AUTHOR								  ;;
;;      Joseph Zbiciak <intvnut AT gmail.com>			       ;;
;;									  ;;
;;  REVISION HISTORY							;;
;;      02-Feb-2018 Initial revision . . . . . . . . . . .  J. Zbiciak      ;;
;;									  ;;
;;  INPUTS for IV_HUSH						      ;;
;;      None.							       ;;
;;									  ;;
;;  OUTPUTS								 ;;
;;      R0 trashed.							 ;;
;;									  ;;
;;  NOTES								   ;;
;;      Returns via IV_WAIT.						;;
;;									  ;;
;; ======================================================================== ;;
IV_HUSH:    PROC
	    MVI     IV.QH,  R0
	    SWAP    R0,     2
	    BMI     IV_WAIT.leave

	    DIS
	    ;; We can't stop a phrase segment that's being FIFOed down.
	    ;; We need to remember if we've committed to pushing ALD.
	    ;; We _can_ stop new phrase segments from going down, and _can_
	    ;; stop new phrases from being started.

	    ;; Set head pointer to indicate we've inserted one item.
	    MVI     IV.QH,  R0  ; Re-read, as an interrupt may have occurred
	    ANDI    #$F0,   R0
	    INCR    R0
	    MVO     R0,     IV.QH

	    ;; Reset tail pointer, keeping "need ALD" bit and other flags.
	    MVI     IV.QT,  R0
	    ANDI    #$F0,   R0
	    MVO     R0,     IV.QT

	    ;; Reset the phrase pointer, to stop a long phrase.
	    CLRR    R0
	    MVO     R0,     IV.PPTR

	    ;; Queue a PA1 in the queue.  Since we're can't guarantee the user
	    ;; has included resrom.asm, let's just use the raw number (5).
	    MVII    #5,     R0
	    MVO     R0,     IV.Q

	    ;; Re-enable interrupts and wait for Intellivoice to shut up.
	    ;;
	    ;; We can't just jump to IV_WAIT.q_loop, as we need to reload
	    ;; IV.QH into R0, and I'm really committed to only using R0.
;	   JE      IV_WAIT
	    EIS
	    ; fallthrough into IV_WAIT
	    ENDP

;; ======================================================================== ;;
;;  NAME								    ;;
;;      IV_WAIT     Wait for voice queue to empty.			  ;;
;;									  ;;
;;  AUTHOR								  ;;
;;      Joseph Zbiciak <intvnut AT gmail.com>			       ;;
;;									  ;;
;;  REVISION HISTORY							;;
;;      15-Sep-2002 Initial revision . . . . . . . . . . .  J. Zbiciak      ;;
;;									  ;;
;;  INPUTS for IV_WAIT						      ;;
;;      R5      Return address					      ;;
;;									  ;;
;;  OUTPUTS								 ;;
;;      R0      trashed.						    ;;
;;									  ;;
;;  NOTES								   ;;
;;      This waits until the Intellivoice is nearly completely quiescent.   ;;
;;      Some voice data may still be spoken from the last triggered	 ;;
;;      phrase.  To truly wait for *that* to be spoken, speak a 'pause'     ;;
;;      (eg. RESROM.pa1) and then call IV_WAIT.			     ;;
;; ------------------------------------------------------------------------ ;;
;;		   Copyright (c) 2002, Joseph Zbiciak		     ;;
;; ======================================================================== ;;
IV_WAIT     PROC
	    MVI     IV.QH,  R0
	    CMPI    #$80, R0	    ; test bit 7, leave if set.
	    BC      @@leave

	    ; Wait for queue to drain.
@@q_loop:   CMP     IV.QT,  R0
	    BNEQ    @@q_loop

	    ; Wait for FIFO and LRQ to say ready.
@@s_loop:   MVI     $81,    R0	  ; Read FIFO status.  0 == ready.
	    COMR    R0
	    AND     $80,    R0	  ; Merge w/ ALD status.  1 == ready
	    TSTR    R0
	    BPL     @@s_loop	    ; if bit 15 == 0, not ready.
	    
@@leave:    JR      R5
	    ENDP

;; ======================================================================== ;;
;;  End of File:  ivoice.asm						;;
;; ======================================================================== ;;

;* ======================================================================== *;
;*  These routines are placed into the public domain by their author.  All  *;
;*  copyright rights are hereby relinquished on the routines and data in    *;
;*  this file.  -- Joseph Zbiciak, 2008				     *;
;* ======================================================================== *;

;; ======================================================================== ;;
;;  NAME								    ;;
;;      IV_SAYNUM16 Say a 16-bit unsigned number using RESROM digits	;;
;;									  ;;
;;  AUTHOR								  ;;
;;      Joseph Zbiciak <intvnut AT gmail.com>			       ;;
;;									  ;;
;;  REVISION HISTORY							;;
;;      16-Sep-2002 Initial revision . . . . . . . . . . .  J. Zbiciak      ;;
;;									  ;;
;;  INPUTS for IV_SAYNUM16						  ;;
;;      R0      Number to "speak"					   ;;
;;      R5      Return address					      ;;
;;									  ;;
;;  OUTPUTS								 ;;
;;									  ;;
;;  DESCRIPTION							     ;;
;;      "Says" a 16-bit number using IV_PLAYW to queue up the phrase.       ;;
;;      Because the number may be built from several segments, it could     ;;
;;      easily eat up the queue.  I believe the longest number will take    ;;
;;      7 queue entries -- that is, fill the queue.  Thus, this code	;;
;;      could block, waiting for slots in the queue.			;;
;; ======================================================================== ;;

IV_SAYNUM16 PROC
	    PSHR    R5

	    TSTR    R0
	    BEQ     @@zero	  ; Special case:  Just say "zero"

	    ;; ------------------------------------------------------------ ;;
	    ;;  First, try to pull off 'thousands'.  We call ourselves      ;;
	    ;;  recursively to play the the number of thousands.	    ;;
	    ;; ------------------------------------------------------------ ;;
	    CLRR    R1
@@thloop:   INCR    R1
	    SUBI    #1000,  R0
	    BC      @@thloop

	    ADDI    #1000,  R0
	    PSHR    R0
	    DECR    R1
	    BEQ     @@no_thousand

	    CALL    IV_SAYNUM16.recurse

	    CALL    IV_PLAYW
	    DECLE   36  ; THOUSAND
	    
@@no_thousand
	    PULR    R1

	    ;; ------------------------------------------------------------ ;;
	    ;;  Now try to play hundreds.				   ;;
	    ;; ------------------------------------------------------------ ;;
	    MVII    #7-1, R0    ; ZERO
	    CMPI    #100,   R1
	    BNC     @@no_hundred

@@hloop:    INCR    R0
	    SUBI    #100,   R1
	    BC      @@hloop
	    ADDI    #100,   R1

	    PSHR    R1

	    CALL    IV_PLAYW.1

	    CALL    IV_PLAYW
	    DECLE   35  ; HUNDRED

	    PULR    R1
	    B       @@notrecurse    ; skip "PSHR R5"
@@recurse:  PSHR    R5	      ; recursive entry point for 'thousand'

@@no_hundred:
@@notrecurse:
	    MOVR    R1,     R0
	    BEQ     @@leave

	    SUBI    #20,    R1
	    BNC     @@teens

	    MVII    #27-1, R0   ; TWENTY
@@tyloop    INCR    R0
	    SUBI    #10,    R1
	    BC      @@tyloop
	    ADDI    #10,    R1

	    PSHR    R1
	    CALL    IV_PLAYW.1

	    PULR    R0
	    TSTR    R0
	    BEQ     @@leave

@@teens:
@@zero:     ADDI    #7, R0  ; ZERO

	    CALL    IV_PLAYW.1

@@leave     PULR    PC
	    ENDP

;; ======================================================================== ;;
;;  End of File:  saynum16.asm					      ;;
;; ======================================================================== ;;

IV_INIT_and_wait:     EQU IV_INIT

    ELSE

IV_INIT_and_wait:     EQU _wait	; No voice init; just WAIT.

    ENDI

	IF intybasic_flash

;; ======================================================================== ;;
;;  JLP "Save Game" support						 ;;
;; ======================================================================== ;;
JF.first    EQU     $8023
JF.last     EQU     $8024
JF.addr     EQU     $8025
JF.row      EQU     $8026
		   
JF.wrcmd    EQU     $802D
JF.rdcmd    EQU     $802E
JF.ercmd    EQU     $802F
JF.wrkey    EQU     $C0DE
JF.rdkey    EQU     $DEC0
JF.erkey    EQU     $BEEF

JF.write:   DECLE   JF.wrcmd,   JF.wrkey    ; Copy JLP RAM to flash row  
JF.read:    DECLE   JF.rdcmd,   JF.rdkey    ; Copy flash row to JLP RAM  
JF.erase:   DECLE   JF.ercmd,   JF.erkey    ; Erase flash sector 

;; ======================================================================== ;;
;;  JF.INIT	 Copy JLP save-game support routine to System RAM	;;
;; ======================================================================== ;;
JF.INIT     PROC
	    PSHR    R5	    
	    MVII    #@@__code,  R5
	    MVII    #JF.SYSRAM, R4
	    REPEAT  5       
	    MVI@    R5,	 R0      ; \_ Copy code fragment to System RAM
	    MVO@    R0,	 R4      ; /
	    ENDR
	    PULR    PC

	    ;; === start of code that will run from RAM
@@__code:   MVO@    R0,	 R1      ; JF.SYSRAM + 0: initiate command
	    ADD@    R1,	 PC      ; JF.SYSRAM + 1: Wait for JLP to return
	    JR      R5		  ; JF.SYSRAM + 2:
	    MVO@    R2,	 R2      ; JF.SYSRAM + 3: \__ simple ISR
	    JR      R5		  ; JF.SYSRAM + 4: /
	    ;; === end of code that will run from RAM
	    ENDP

;; ======================================================================== ;;
;;  JF.CMD	  Issue a JLP Flash command			       ;;
;;									  ;;
;;  INPUT								   ;;
;;      R0  Slot number to operate on				       ;;
;;      R1  Address to copy to/from in JLP RAM			      ;;
;;      @R5 Command to invoke:					      ;;
;;									  ;;
;;	      JF.write -- Copy JLP RAM to Flash			   ;;
;;	      JF.read  -- Copy Flash to JLP RAM			   ;;
;;	      JF.erase -- Erase flash sector			      ;;
;;									  ;;
;;  OUTPUT								  ;;
;;      R0 - R4 not modified.  (Saved and restored across call)	     ;;
;;      JLP command executed						;;
;;									  ;;
;;  NOTES								   ;;
;;      This code requires two short routines in the console's System RAM.  ;;
;;      It also requires that the system stack reside in System RAM.	;;
;;      Because an interrupt may occur during the code's execution, there   ;;
;;      must be sufficient stack space to service the interrupt (8 words).  ;;
;;									  ;;
;;      The code also relies on the fact that the EXEC ISR dispatch does    ;;
;;      not modify R2.  This allows us to initialize R2 for the ISR ahead   ;;
;;      of time, rather than in the ISR.				    ;;
;; ======================================================================== ;;
JF.CMD      PROC

	    MVO     R4,	 JF.SV.R4    ; \
	    MVII    #JF.SV.R0,  R4	  ;  |
	    MVO@    R0,	 R4	  ;  |- Save registers, but not on
	    MVO@    R1,	 R4	  ;  |  the stack.  (limit stack use)
	    MVO@    R2,	 R4	  ; /

	    MVI@    R5,	 R4	  ; Get command to invoke

	    MVO     R5,	 JF.SV.R5    ; save return address

	    DIS
	    MVO     R1,	 JF.addr     ; \_ Save SG arguments in JLP
	    MVO     R0,	 JF.row      ; /
					  
	    MVI@    R4,	 R1	  ; Get command address
	    MVI@    R4,	 R0	  ; Get unlock word
					  
	    MVII    #$100,      R4	  ; \
	    SDBD			    ;  |_ Save old ISR in save area
	    MVI@    R4,	 R2	  ;  |
	    MVO     R2,	 JF.SV.ISR   ; /
					  
	    MVII    #JF.SYSRAM + 3, R2      ; \
	    MVO     R2,	 $100	;  |_ Set up new ISR in RAM
	    SWAP    R2		      ;  |
	    MVO     R2,	 $101	; / 
					  
	    MVII    #$20,       R2	  ; Address of STIC handshake
	    JSRE    R5,  JF.SYSRAM	  ; Invoke the command
					  
	    MVI     JF.SV.ISR,  R2	  ; \
	    MVO     R2,	 $100	;  |_ Restore old ISR 
	    SWAP    R2		      ;  |
	    MVO     R2,	 $101	; /
					  
	    MVII    #JF.SV.R0,  R5	  ; \
	    MVI@    R5,	 R0	  ;  |
	    MVI@    R5,	 R1	  ;  |- Restore registers
	    MVI@    R5,	 R2	  ;  |
	    MVI@    R5,	 R4	  ; /
	    MVI@    R5,	 PC	  ; Return

	    ENDP


	ENDI

	IF intybasic_fastmult

; Quarter Square Multiplication
; Assembly code by Joe Zbiciak, 2015
; Released to public domain.

QSQR8_TBL:  PROC
	    DECLE   $3F80, $3F01, $3E82, $3E04, $3D86, $3D09, $3C8C, $3C10
	    DECLE   $3B94, $3B19, $3A9E, $3A24, $39AA, $3931, $38B8, $3840
	    DECLE   $37C8, $3751, $36DA, $3664, $35EE, $3579, $3504, $3490
	    DECLE   $341C, $33A9, $3336, $32C4, $3252, $31E1, $3170, $3100
	    DECLE   $3090, $3021, $2FB2, $2F44, $2ED6, $2E69, $2DFC, $2D90
	    DECLE   $2D24, $2CB9, $2C4E, $2BE4, $2B7A, $2B11, $2AA8, $2A40
	    DECLE   $29D8, $2971, $290A, $28A4, $283E, $27D9, $2774, $2710
	    DECLE   $26AC, $2649, $25E6, $2584, $2522, $24C1, $2460, $2400
	    DECLE   $23A0, $2341, $22E2, $2284, $2226, $21C9, $216C, $2110
	    DECLE   $20B4, $2059, $1FFE, $1FA4, $1F4A, $1EF1, $1E98, $1E40
	    DECLE   $1DE8, $1D91, $1D3A, $1CE4, $1C8E, $1C39, $1BE4, $1B90
	    DECLE   $1B3C, $1AE9, $1A96, $1A44, $19F2, $19A1, $1950, $1900
	    DECLE   $18B0, $1861, $1812, $17C4, $1776, $1729, $16DC, $1690
	    DECLE   $1644, $15F9, $15AE, $1564, $151A, $14D1, $1488, $1440
	    DECLE   $13F8, $13B1, $136A, $1324, $12DE, $1299, $1254, $1210
	    DECLE   $11CC, $1189, $1146, $1104, $10C2, $1081, $1040, $1000
	    DECLE   $0FC0, $0F81, $0F42, $0F04, $0EC6, $0E89, $0E4C, $0E10
	    DECLE   $0DD4, $0D99, $0D5E, $0D24, $0CEA, $0CB1, $0C78, $0C40
	    DECLE   $0C08, $0BD1, $0B9A, $0B64, $0B2E, $0AF9, $0AC4, $0A90
	    DECLE   $0A5C, $0A29, $09F6, $09C4, $0992, $0961, $0930, $0900
	    DECLE   $08D0, $08A1, $0872, $0844, $0816, $07E9, $07BC, $0790
	    DECLE   $0764, $0739, $070E, $06E4, $06BA, $0691, $0668, $0640
	    DECLE   $0618, $05F1, $05CA, $05A4, $057E, $0559, $0534, $0510
	    DECLE   $04EC, $04C9, $04A6, $0484, $0462, $0441, $0420, $0400
	    DECLE   $03E0, $03C1, $03A2, $0384, $0366, $0349, $032C, $0310
	    DECLE   $02F4, $02D9, $02BE, $02A4, $028A, $0271, $0258, $0240
	    DECLE   $0228, $0211, $01FA, $01E4, $01CE, $01B9, $01A4, $0190
	    DECLE   $017C, $0169, $0156, $0144, $0132, $0121, $0110, $0100
	    DECLE   $00F0, $00E1, $00D2, $00C4, $00B6, $00A9, $009C, $0090
	    DECLE   $0084, $0079, $006E, $0064, $005A, $0051, $0048, $0040
	    DECLE   $0038, $0031, $002A, $0024, $001E, $0019, $0014, $0010
	    DECLE   $000C, $0009, $0006, $0004, $0002, $0001, $0000
@@mid:
	    DECLE   $0000, $0000, $0001, $0002, $0004, $0006, $0009, $000C
	    DECLE   $0010, $0014, $0019, $001E, $0024, $002A, $0031, $0038
	    DECLE   $0040, $0048, $0051, $005A, $0064, $006E, $0079, $0084
	    DECLE   $0090, $009C, $00A9, $00B6, $00C4, $00D2, $00E1, $00F0
	    DECLE   $0100, $0110, $0121, $0132, $0144, $0156, $0169, $017C
	    DECLE   $0190, $01A4, $01B9, $01CE, $01E4, $01FA, $0211, $0228
	    DECLE   $0240, $0258, $0271, $028A, $02A4, $02BE, $02D9, $02F4
	    DECLE   $0310, $032C, $0349, $0366, $0384, $03A2, $03C1, $03E0
	    DECLE   $0400, $0420, $0441, $0462, $0484, $04A6, $04C9, $04EC
	    DECLE   $0510, $0534, $0559, $057E, $05A4, $05CA, $05F1, $0618
	    DECLE   $0640, $0668, $0691, $06BA, $06E4, $070E, $0739, $0764
	    DECLE   $0790, $07BC, $07E9, $0816, $0844, $0872, $08A1, $08D0
	    DECLE   $0900, $0930, $0961, $0992, $09C4, $09F6, $0A29, $0A5C
	    DECLE   $0A90, $0AC4, $0AF9, $0B2E, $0B64, $0B9A, $0BD1, $0C08
	    DECLE   $0C40, $0C78, $0CB1, $0CEA, $0D24, $0D5E, $0D99, $0DD4
	    DECLE   $0E10, $0E4C, $0E89, $0EC6, $0F04, $0F42, $0F81, $0FC0
	    DECLE   $1000, $1040, $1081, $10C2, $1104, $1146, $1189, $11CC
	    DECLE   $1210, $1254, $1299, $12DE, $1324, $136A, $13B1, $13F8
	    DECLE   $1440, $1488, $14D1, $151A, $1564, $15AE, $15F9, $1644
	    DECLE   $1690, $16DC, $1729, $1776, $17C4, $1812, $1861, $18B0
	    DECLE   $1900, $1950, $19A1, $19F2, $1A44, $1A96, $1AE9, $1B3C
	    DECLE   $1B90, $1BE4, $1C39, $1C8E, $1CE4, $1D3A, $1D91, $1DE8
	    DECLE   $1E40, $1E98, $1EF1, $1F4A, $1FA4, $1FFE, $2059, $20B4
	    DECLE   $2110, $216C, $21C9, $2226, $2284, $22E2, $2341, $23A0
	    DECLE   $2400, $2460, $24C1, $2522, $2584, $25E6, $2649, $26AC
	    DECLE   $2710, $2774, $27D9, $283E, $28A4, $290A, $2971, $29D8
	    DECLE   $2A40, $2AA8, $2B11, $2B7A, $2BE4, $2C4E, $2CB9, $2D24
	    DECLE   $2D90, $2DFC, $2E69, $2ED6, $2F44, $2FB2, $3021, $3090
	    DECLE   $3100, $3170, $31E1, $3252, $32C4, $3336, $33A9, $341C
	    DECLE   $3490, $3504, $3579, $35EE, $3664, $36DA, $3751, $37C8
	    DECLE   $3840, $38B8, $3931, $39AA, $3A24, $3A9E, $3B19, $3B94
	    DECLE   $3C10, $3C8C, $3D09, $3D86, $3E04, $3E82, $3F01, $3F80
	    DECLE   $4000, $4080, $4101, $4182, $4204, $4286, $4309, $438C
	    DECLE   $4410, $4494, $4519, $459E, $4624, $46AA, $4731, $47B8
	    DECLE   $4840, $48C8, $4951, $49DA, $4A64, $4AEE, $4B79, $4C04
	    DECLE   $4C90, $4D1C, $4DA9, $4E36, $4EC4, $4F52, $4FE1, $5070
	    DECLE   $5100, $5190, $5221, $52B2, $5344, $53D6, $5469, $54FC
	    DECLE   $5590, $5624, $56B9, $574E, $57E4, $587A, $5911, $59A8
	    DECLE   $5A40, $5AD8, $5B71, $5C0A, $5CA4, $5D3E, $5DD9, $5E74
	    DECLE   $5F10, $5FAC, $6049, $60E6, $6184, $6222, $62C1, $6360
	    DECLE   $6400, $64A0, $6541, $65E2, $6684, $6726, $67C9, $686C
	    DECLE   $6910, $69B4, $6A59, $6AFE, $6BA4, $6C4A, $6CF1, $6D98
	    DECLE   $6E40, $6EE8, $6F91, $703A, $70E4, $718E, $7239, $72E4
	    DECLE   $7390, $743C, $74E9, $7596, $7644, $76F2, $77A1, $7850
	    DECLE   $7900, $79B0, $7A61, $7B12, $7BC4, $7C76, $7D29, $7DDC
	    DECLE   $7E90, $7F44, $7FF9, $80AE, $8164, $821A, $82D1, $8388
	    DECLE   $8440, $84F8, $85B1, $866A, $8724, $87DE, $8899, $8954
	    DECLE   $8A10, $8ACC, $8B89, $8C46, $8D04, $8DC2, $8E81, $8F40
	    DECLE   $9000, $90C0, $9181, $9242, $9304, $93C6, $9489, $954C
	    DECLE   $9610, $96D4, $9799, $985E, $9924, $99EA, $9AB1, $9B78
	    DECLE   $9C40, $9D08, $9DD1, $9E9A, $9F64, $A02E, $A0F9, $A1C4
	    DECLE   $A290, $A35C, $A429, $A4F6, $A5C4, $A692, $A761, $A830
	    DECLE   $A900, $A9D0, $AAA1, $AB72, $AC44, $AD16, $ADE9, $AEBC
	    DECLE   $AF90, $B064, $B139, $B20E, $B2E4, $B3BA, $B491, $B568
	    DECLE   $B640, $B718, $B7F1, $B8CA, $B9A4, $BA7E, $BB59, $BC34
	    DECLE   $BD10, $BDEC, $BEC9, $BFA6, $C084, $C162, $C241, $C320
	    DECLE   $C400, $C4E0, $C5C1, $C6A2, $C784, $C866, $C949, $CA2C
	    DECLE   $CB10, $CBF4, $CCD9, $CDBE, $CEA4, $CF8A, $D071, $D158
	    DECLE   $D240, $D328, $D411, $D4FA, $D5E4, $D6CE, $D7B9, $D8A4
	    DECLE   $D990, $DA7C, $DB69, $DC56, $DD44, $DE32, $DF21, $E010
	    DECLE   $E100, $E1F0, $E2E1, $E3D2, $E4C4, $E5B6, $E6A9, $E79C
	    DECLE   $E890, $E984, $EA79, $EB6E, $EC64, $ED5A, $EE51, $EF48
	    DECLE   $F040, $F138, $F231, $F32A, $F424, $F51E, $F619, $F714
	    DECLE   $F810, $F90C, $FA09, $FB06, $FC04, $FD02, $FE01
	    ENDP

; R0 = R0 * R1, where R0 and R1 are unsigned 8-bit values
; Destroys R1, R4
qs_mpy8:    PROC
	    MOVR    R0,	     R4      ;   6
	    ADDI    #QSQR8_TBL.mid, R1      ;   8
	    ADDR    R1,	     R4      ;   6   a + b
	    SUBR    R0,	     R1      ;   6   a - b
@@ok:       MVI@    R4,	     R0      ;   8
	    SUB@    R1,	     R0      ;   8
	    JR      R5		      ;   7
					    ;----
					    ;  49
	    ENDP
	    

; R1 = R0 * R1, where R0 and R1 are 16-bit values
; destroys R0, R2, R3, R4, R5
qs_mpy16:   PROC
	    PSHR    R5		  ;   9
				   
	    ; Unpack lo/hi
	    MOVR    R0,	 R2      ;   6   
	    ANDI    #$FF,       R0      ;   8   R0 is lo(a)
	    XORR    R0,	 R2      ;   6   
	    SWAP    R2		  ;   6   R2 is hi(a)

	    MOVR    R1,	 R3      ;   6   R3 is orig 16-bit b
	    ANDI    #$FF,       R1      ;   8   R1 is lo(b)
	    MOVR    R1,	 R5      ;   6   R5 is lo(b)
	    XORR    R1,	 R3      ;   6   
	    SWAP    R3		  ;   6   R3 is hi(b)
					;----
					;  67
					
	    ; lo * lo		   
	    MOVR    R0,	 R4      ;   6   R4 is lo(a)
	    ADDI    #QSQR8_TBL.mid, R1  ;   8
	    ADDR    R1,	 R4      ;   6   R4 = lo(a) + lo(b)
	    SUBR    R0,	 R1      ;   6   R1 = lo(a) - lo(b)
					
@@pos_ll:   MVI@    R4,	 R4      ;   8   R4 = qstbl[lo(a)+lo(b)]
	    SUB@    R1,	 R4      ;   8   R4 = lo(a)*lo(b)
					;----
					;  42
					;  67 (carried forward)
					;----
					; 109
				       
	    ; lo * hi		  
	    MOVR    R0,	 R1      ;   6   R0 = R1 = lo(a)
	    ADDI    #QSQR8_TBL.mid, R3  ;   8
	    ADDR    R3,	 R1      ;   6   R1 = hi(b) + lo(a)
	    SUBR    R0,	 R3      ;   6   R3 = hi(b) - lo(a)
				       
@@pos_lh:   MVI@    R1,	 R1      ;   8   R1 = qstbl[hi(b)-lo(a)]
	    SUB@    R3,	 R1      ;   8   R1 = lo(a)*hi(b)
					;----
					;  42
					; 109 (carried forward)
					;----
					; 151
				       
	    ; hi * lo		  
	    MOVR    R5,	 R0      ;   6   R5 = R0 = lo(b)
	    ADDI    #QSQR8_TBL.mid, R2  ;   8
	    ADDR    R2,	 R5      ;   6   R3 = hi(a) + lo(b)
	    SUBR    R0,	 R2      ;   6   R2 = hi(a) - lo(b)
				       
@@pos_hl:   ADD@    R5,	 R1      ;   8   \_ R1 = lo(a)*hi(b)+hi(a)*lo(b)
	    SUB@    R2,	 R1      ;   8   /
					;----
					;  42
					; 151 (carried forward)
					;----
					; 193
				       
	    SWAP    R1		  ;   6   \_ shift upper product left 8
	    ANDI    #$FF00,     R1      ;   8   /
	    ADDR    R4,	 R1      ;   6   final product
	    PULR    PC		  ;  12
					;----
					;  32
					; 193 (carried forward)
					;----
					; 225
	    ENDP

	ENDI

	IF intybasic_fastdiv

; Fast unsigned division/remainder
; Assembly code by Oscar Toledo G. Jul/10/2015
; Released to public domain.

	; Ultrafast unsigned division/remainder operation
	; Entry: R0 = Dividend
	;	R1 = Divisor
	; Output: R0 = Quotient
	;	 R2 = Remainder
	; Worst case: 6 + 6 + 9 + 496 = 517 cycles
	; Best case: 6 + (6 + 7) * 16 = 214 cycles

uf_udiv16:	PROC
	CLRR R2		; 6
	SLLC R0,1	; 6
	BC @@1		; 7/9
	SLLC R0,1	; 6
	BC @@2		; 7/9
	SLLC R0,1	; 6
	BC @@3		; 7/9
	SLLC R0,1	; 6
	BC @@4		; 7/9
	SLLC R0,1	; 6
	BC @@5		; 7/9
	SLLC R0,1	; 6
	BC @@6		; 7/9
	SLLC R0,1	; 6
	BC @@7		; 7/9
	SLLC R0,1	; 6
	BC @@8		; 7/9
	SLLC R0,1	; 6
	BC @@9		; 7/9
	SLLC R0,1	; 6
	BC @@10		; 7/9
	SLLC R0,1	; 6
	BC @@11		; 7/9
	SLLC R0,1	; 6
	BC @@12		; 7/9
	SLLC R0,1	; 6
	BC @@13		; 7/9
	SLLC R0,1	; 6
	BC @@14		; 7/9
	SLLC R0,1	; 6
	BC @@15		; 7/9
	SLLC R0,1	; 6
	BC @@16		; 7/9
	JR R5

@@1:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@2:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@3:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@4:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@5:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@6:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@7:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@8:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@9:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@10:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@11:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@12:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@13:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@14:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@15:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
@@16:	RLC R2,1	; 6
	CMPR R1,R2	; 6
	BNC $+3		; 7/9
	SUBR R1,R2	; 6
	RLC R0,1	; 6
	JR R5
	
	ENDP

	ENDI

	ROM.End

	ROM.OutputRomStats

	ORG $200,$200,"-RWB"

Q2:	; Reserved label for #BACKTAB

	;
	; 16-bits variables
	; Note IntyBASIC variables grow up starting in $308.
	;

BASE_16BIT_SYSTEM_VARS: QSET $33f
    IF intybasic_voice
BASE_16BIT_SYSTEM_VARS: QSET BASE_16BIT_SYSTEM_VARS-10
    ENDI
    IF intybasic_col
BASE_16BIT_SYSTEM_VARS: QSET BASE_16BIT_SYSTEM_VARS-8
    ENDI
    IF intybasic_scroll
BASE_16BIT_SYSTEM_VARS: QSET BASE_16BIT_SYSTEM_VARS-20
    ENDI

	ORG BASE_16BIT_SYSTEM_VARS,BASE_16BIT_SYSTEM_VARS,"-RWB"

    IF intybasic_voice
IV.Q:      RMB 8    ; IV_xxx	16-bit	  Voice queue  (8 words)
IV.FPTR:   RMB 1    ; IV_xxx	16-bit	  Current FIFO ptr.
IV.PPTR:   RMB 1    ; IV_xxx	16-bit	  Current Phrase ptr.
    ENDI
    IF intybasic_col
_col0:      RMB 1       ; Collision status for MOB0
_col1:      RMB 1       ; Collision status for MOB1
_col2:      RMB 1       ; Collision status for MOB2
_col3:      RMB 1       ; Collision status for MOB3
_col4:      RMB 1       ; Collision status for MOB4
_col5:      RMB 1       ; Collision status for MOB5
_col6:      RMB 1       ; Collision status for MOB6
_col7:      RMB 1       ; Collision status for MOB7
    ENDI
    IF intybasic_scroll
_scroll_buffer: RMB 20  ; Sometimes this is unused
    ENDI
_music_gosub:	RMB 1	; GOSUB pointer
_music_table:	RMB 1	; Note table
_music_p:	RMB 1	; Pointer to music
_frame:		RMB 1   ; Current frame
_read:		RMB 1   ; Pointer to DATA
_gram_bitmap:   RMB 1   ; Bitmap for definition
_gram2_bitmap:  RMB 1   ; Secondary bitmap for definition
_screen:	RMB 1	; Pointer to current screen position
_color:		RMB 1	; Current color

Q1:			; Reserved label for #MOBSHADOW
_mobs:      RMB 3*8     ; MOB buffer

SCRATCH:    ORG $100,$100,"-RWBN"
	;
	; 8-bits variables
	;
ISRVEC:     RMB 2       ; Pointer to ISR vector (required by Intellivision ROM)
_int:       RMB 1       ; Signals interrupt received
_ntsc:      RMB 1       ; bit 0 = 1=NTSC, 0=PAL. Bit 1 = 1=ECS detected.
_rand:      RMB 1       ; Pseudo-random value
_gram_target:   RMB 1   ; Contains GRAM card number
_gram_total:    RMB 1   ; Contains total GRAM cards for definition
_gram2_target:  RMB 1   ; Contains GRAM card number
_gram2_total:   RMB 1   ; Contains total GRAM cards for definition
_mode_select:   RMB 1   ; Graphics mode selection
_border_color:  RMB 1   ; Border color
_border_mask:   RMB 1   ; Border mask
    IF intybasic_keypad
_cnt1_p0:   RMB 1       ; Debouncing 1
_cnt1_p1:   RMB 1       ; Debouncing 2
_cnt1_key:  RMB 1       ; Currently pressed key
_cnt2_p0:   RMB 1       ; Debouncing 1
_cnt2_p1:   RMB 1       ; Debouncing 2
_cnt2_key:  RMB 1       ; Currently pressed key
    ENDI
    IF intybasic_scroll
_scroll_x:  RMB 1       ; Scroll X offset
_scroll_y:  RMB 1       ; Scroll Y offset
_scroll_d:  RMB 1       ; Scroll direction
    ENDI
    IF intybasic_music
_music_start:	RMB 2	; Start of music

_music_mode: RMB 1      ; Music mode (0= Not using PSG, 2= Simple, 4= Full, add 1 if using noise channel for drums)
_music_frame: RMB 1     ; Music frame (for 50 hz fixed)
_music_tc:  RMB 1       ; Time counter
_music_t:   RMB 1       ; Time base
_music_i1:  RMB 1       ; Instrument 1 
_music_s1:  RMB 1       ; Sample pointer 1
_music_n1:  RMB 1       ; Note 1
_music_i2:  RMB 1       ; Instrument 2
_music_s2:  RMB 1       ; Sample pointer 2
_music_n2:  RMB 1       ; Note 2
_music_i3:  RMB 1       ; Instrument 3
_music_s3:  RMB 1       ; Sample pointer 3
_music_n3:  RMB 1       ; Note 3
_music_s4:  RMB 1       ; Sample pointer 4
_music_n4:  RMB 1       ; Note 4 (really it's drum)

_music_freq10:	RMB 1   ; Low byte frequency A
_music_freq20:	RMB 1   ; Low byte frequency B
_music_freq30:	RMB 1   ; Low byte frequency C
_music_freq11:	RMB 1   ; High byte frequency A
_music_freq21:	RMB 1   ; High byte frequency B
_music_freq31:	RMB 1   ; High byte frequency C
_music_mix:	RMB 1   ; Mixer
_music_noise:	RMB 1   ; Noise
_music_vol1:	RMB 1   ; Volume A
_music_vol2:	RMB 1   ; Volume B
_music_vol3:	RMB 1   ; Volume C
    ENDI
    IF intybasic_music_ecs
_music_i5:  RMB 1       ; Instrument 5
_music_s5:  RMB 1       ; Sample pointer 5
_music_n5:  RMB 1       ; Note 5
_music_i6:  RMB 1       ; Instrument 6
_music_s6:  RMB 1       ; Sample pointer 6
_music_n6:  RMB 1       ; Note 6
_music_i7:  RMB 1       ; Instrument 7
_music_s7:  RMB 1       ; Sample pointer 7
_music_n7:  RMB 1       ; Note 7
_music_s8:  RMB 1       ; Sample pointer 8
_music_n8:  RMB 1       ; Note 8 (really it's drum)

_music2_freq10:	RMB 1   ; Low byte frequency A
_music2_freq20:	RMB 1   ; Low byte frequency B
_music2_freq30:	RMB 1   ; Low byte frequency C
_music2_freq11:	RMB 1   ; High byte frequency A
_music2_freq21:	RMB 1   ; High byte frequency B
_music2_freq31:	RMB 1   ; High byte frequency C
_music2_mix:	RMB 1   ; Mixer
_music2_noise:	RMB 1   ; Noise
_music2_vol1:	RMB 1   ; Volume A
_music2_vol2:	RMB 1   ; Volume B
_music2_vol3:	RMB 1   ; Volume C
    ENDI
    IF intybasic_music_volume
_music_vol:	RMB 1	; Global music volume
    ENDI
    IF intybasic_voice
IV.QH:     RMB 1    ; IV_xxx	8-bit	   Voice queue head
IV.QT:     RMB 1    ; IV_xxx	8-bit	   Voice queue tail
IV.FLEN:   RMB 1    ; IV_xxx	8-bit	   Length of FIFO data
    ENDI

var_BASS_ON:	RMB 1	; BASS_ON
var_BC:	RMB 1	; BC
var_CC:	RMB 1	; CC
var_CLARINET_ON:	RMB 1	; CLARINET_ON
var_F:	RMB 1	; F
var_FC:	RMB 1	; FC
var_FLUTE_ON:	RMB 1	; FLUTE_ON
var_FREQ:	RMB 1	; FREQ
var_I:	RMB 1	; I
var_J:	RMB 1	; J
var_K:	RMB 1	; K
var_LAST_KEY:	RMB 1	; LAST_KEY
var_PAGE:	RMB 1	; PAGE
var_R:	RMB 1	; R
var_TICK:	RMB 1	; TICK
var_VID:	RMB 1	; VID
var_VOL:	RMB 1	; VOL
_SCRATCH:	EQU $

SYSTEM:	ORG $2F0, $2F0, "-RWBN"
STACK:	RMB 24
var_&TICK:	RMB 1	; #TICK
_SYSTEM:	EQU $

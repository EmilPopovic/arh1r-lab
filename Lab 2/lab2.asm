            ORG     0
            B       MAIN



            ORG     0x18
            B       IRQ



IRQ         STMFD   SP!, {R1}           ; adresa RTC-a u R3

            MOV     R1, #0              ; zabrani RTC-u da zahtijeva prekid
            STR     R1, [R3, #0x10]     ; upis u CR

            STR     R4, [R3, #0x08]     ; obrisi status

            MOV     R1, #0              ; brisi brojilo u RTC-u
            STR     R1, [R3, #0xC]      ; upis u LR

            LDMFD   SP!, {R1}           ; vrati irq kontekst

            MSR     CPSR, #0b01010011   ; vrati svc, dozvoli irq

            MOV     PC, #END_WAIT



MAIN        MSR     CPSR, #0b11010010   ; irq
            MOV     SP, #0x10000        ; irq stog

            MSR     CPSR, #0b01010011   ; svc i dozvoli irq
            MOV     SP, #0xFC00         ; svc stog

            LDR     R3, RTC             ; RTC_DR

            LDR     R4, COUNT           ; konstanta brojenja
            STR     R4, [R3, #4]        ; upis u MR

            LDR     R1, GPIO1           ; GPIO1_PA_DR
            ADD     R1, R1, #4          ; GPIO1_PB_DR

            LDR     R2, GPIO2           ; GPIO2_PA_DR

            MOV     R4, #0b11100000     ; bitovi 7, 6 i 5 izlazi, bit 0 ulaz
            STR     R4, [R2, #8]        ; postavi smjerove u GPIO2_PA_DDR

                                        ; GPIO1_PB_DDR vec postavljen

RESET       BL      WAIT_STG            ; idi u fazu cekanja

WRK_LOOP    LDR     R4, [R2]
            TST     R4, #1
            BEQ     WRK_LOOP            ; poll dok nije b0 na GPIO2_PA_DR postavljen (tipka)

            BL      HEAT_STG            ; idi u fazu grijanja
            BL      WAIT                ; trajanje faze grijanja

            BL      COFF_STG
            BL      WAIT

            BL      MILK_STG
            BL      WAIT

            BL      DONE_STG
            BL      WAIT

            B       RESET               ; nakon ciklusa resetiraj

END         SWI     0x123456            ; nece nikada biti izvedeno



WAIT        STMFD   SP!, {R4}           ; prima adresu RTC preko R3

            MOV     R4, #0              ; brisi brojilo u RTC-u
            STR     R4, [R3, #0xC]      ; upis u LR

            STR     R4, [R3, #0x08]     ; obrisi status

            MOV     R4, #1              ; dozvoli RTC-u da zahtijeva prekid
            STR     R4, [R3, #0x10]     ; upis u CR

WT_LOOP     B       WT_LOOP             ; cekaj prekid

END_WAIT    LDMFD   SP!, {R4}
            MOV     PC, LR



WAIT_STG    STMFD   SP!, {R2, R4, R5, LR}

            LDR     R4, [R2]            ; ugasi LED
            AND     R4, R4, #0b00011111
            STR     R4, [R2]

            BL      RST_LCD             ; "WELCOME" na LCD
            MOV     R5, #WELCOME
            BL      PRINT

            LDMFD   SP!, {R2, R4, R5, LR}
            MOV     PC, LR


        
HEAT_STG    STMFD   SP!, {R2, R4, R5, LR}

            LDR     R4, [R2]            ; crveni LED
            AND     R4, R4, #0b00011111
            ORR     R4, R4, #0b00100000
            STR     R4, [R2]

            BL      RST_LCD             ; "HEATING" na LCD
            MOV     R5, #HEATING
            BL      PRINT

            LDMFD   SP!, {R2, R4, R5, LR}
            MOV     PC, LR



COFF_STG    STMFD   SP!, {R2, R4, R5, LR}

            LDR     R4, [R2]            ; zuti LED
            AND     R4, R4, #0b00011111
            ORR     R4, R4, #0b01000000
            STR     R4, [R2]

            BL      RST_LCD             ; "COFFEE" na LCD
            MOV     R5, #COFFEE
            BL      PRINT

            LDMFD   SP!, {R2, R4, R5, LR}
            MOV     PC, LR



MILK_STG    STMFD   SP!, {R2, R4, R5, LR}

            LDR     R4, [R2]            ; zeleni LED
            AND     R4, R4, #0b00011111
            ORR     R4, R4, #0b10000000
            STR     R4, [R2]

            BL      RST_LCD             ; "MILK" na LCD
            MOV     R5, #MILK
            BL      PRINT

            LDMFD   SP!, {R2, R4, R5, LR}
            MOV     PC, LR



DONE_STG    STMFD   SP!, {R2, R4, R5, LR}

            LDR     R4, [R2]            ; svi LED
            AND     R4, R4, #0b00011111
            ORR     R4, R4, #0b11100000
            STR     R4, [R2]

            BL      RST_LCD             ; "DONE" na LCD
            MOV     R5, #DONE
            BL      PRINT

            LDMFD   SP!, {R2, R4, R5, LR}
            MOV     PC, LR



RST_LCD     STMFD   SP!, {R0, LR}
            
            MOV     R0, #0x0D           ; R0 := CR (0x0D)
            STR     R0, [R1]            ; posalji na GPIO1_PB_DR
            BL      LCDWR               ; ispisi CR

            LDMFD   SP!, {R0, LR}
            MOV     PC, LR

            

PRINT       STMFD   SP!, {R0, R5, LR}   ; prima adresu stringa preko R5

PRN_LOOP    LDRB    R0, [R5], #1        ; R0 := trenutni znak stringa
            CMP     R0, #0              ; string terminiran s '\0'
            BLNE    LCDWR               ; ispisi trenutni znak ako postoji
            BNE     PRN_LOOP            ; ispisuj dalje ako ima jos

            MOV     R0, #0xA            ; ispis na zaslon
            BL      LCDWR

            LDMFD   SP!, {R0, R5, LR}
            MOV     PC, LR



LCDWR       STMFD   SP!, {R0}
            AND     R0, R0, #0x7F       ; postavi bit 7 u nulu (za svaki slucaj, jer
                                        ; u R0 je tu mogla biti 1) i posalji znak
            STRB    R0, [R1]

            ORR     R0, R0, #0x80       ; postavi bit 7 u jedan (podigni impuls)
            STRB    R0, [R1]

            AND     R0, R0, #0x7F       ; postavi bit 7 u nulu (spusti impuls)
            STRB    R0, [R1]

            LDMFD   SP!, {R0}
            MOV     PC, LR              ; povratak



GPIO1       DW      0xFFFF0F00
GPIO2       DW      0xFFFF0B00
RTC         DW      0xFFFF0E00

COUNT       DW      2650

WELCOME     DSTR    "WELCOME"
HEATING     DSTR    "HEATING"
COFFEE      DSTR    " COFFEE"
MILK        DSTR    "   MILK"
DONE        DSTR    "   DONE"
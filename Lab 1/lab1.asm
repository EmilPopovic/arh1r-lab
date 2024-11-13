MAIN        MOV     SP, #0x10000        ; inicijalizacija stoga
            LDR     R8, KRAJ_REZ        ; R8 := kraj rezultata
            LDR     R7, KRAJ_POD        ; R7 := kraj podataka za usporedbu
            MOV     R6, #0x2000         ; R6 := adresa upisa sljedeceg rezultata
            MOV     R5, #0x700          ; R5 := adresa trenutnog podatka

; obrada podataka dok nije detektiran KRAJ_POD umjesto operatora u memoriji

PETLJA      LDR     R4, [R5], #4        ; R4 := trenutna operacija
                                        ; na trenutnu operaciju pokazuje R5
                                        ; R5 prelazi na sljedecu lokaciju nakon svakog citanja

            CMP     R4, R7              ; usporedba ucitane operacije i signala za prekid ucitavanja
            BEQ     KRAJ                ; izlazak iz petlje ako jednaki / "break"

            LDMIA   R5!, {R10, R11}     ; ucitavanje operanada u registre R10 i R11
                                        ; uvecavanje R5 nakon svakog operanda

            CMP     R4, #0              ; odredjivanje operacije provjerom vrijednosti u R4
            BEQ     ZBROJI              ; u ZBROJI objasnjeno zasto ne treba link
                                        ; potprogrami operacija se vracaju direktno na while uvjet
                                        ; nakon svake operacije petlja ima "continue"

            CMP     R4, #1              ; kao za zbrajanje
            BEQ     ODUZMI

            CMP     R4, #2              ; kao za zbrajanje
            BEQ     MNOZI

                                        ; dijeljenje ako nije prekid ili jedna od prve tri op
                                        ; ako pretp da su podaci uvjek tocni ne treba EQ za zadnji
            STMFD   SP!, {R10, R11}     ; spremanje operanada na stog
            BL      DIJELI              ; poziv potprograma za dijeljenje
            ADD     SP, SP, #8          ; uklanjanje parametara sa stoga
            STR     R10, [R6], #4       ; zbog uvjeta zadatka za dijeljenje mora biti ovdje            
            B       PETLJA

; ZBROJI, ODUZMI i MNOZI mogu biti zapisani i unutar petlje pomocu EQ uvjetovanih naredbi

ZBROJI      ADD     R10, R10, R11       ; koristi registar prvog operanda za rez
            STR     R10, [R6], #4       ; upisuju rezultat na adresu u R6 i ide na sljedecu
            B       PETLJA              ; continue u petlji

ODUZMI      SUB     R10, R10, R11
            STR     R10, [R6], #4
            B       PETLJA

MNOZI       MUL     R10, R11, R10
            STR     R10, [R6], #4
            B       PETLJA

; DIJELI napisano kao "normalan" potprogram koji prima parametre putem stoga

DIJELI      STMFD   SP!, {R0-R2}        ; spremanje konteksta

            LDR     R1, [SP, #12]       ; ucitavanje parametara sa stoga u R1 i R2
            LDR     R2, [SP, #16]

            MOV     R0, #0              ; R0 je registar predznaka
                                        ; inicijaliziran ovdje zbog moguceg skoka na kraj

            CMP     R2, #0              ; dijeli li se nulom?
            MOVEQ   R10, #0 	        ; vrati 0 ako da
            BEQ     DIV_RET

            ADDLT   R0, R0, #1          ; radit ce se uzastopno oduzimanje pozitivnog od pozitivnog
                                        ; o R0 ovisi hoce li rezultat biti pozitivan ili negativan
            MVNLT   R2, R2              ; ako je djelitelj negativan, po dvojnom kompl postaje poz
            ADDLT   R2, R2, #1

            CMP     R1, #0              ; isto i za djeljenika
            ADDLT   R0, R0, #1
            MVNLT   R1, R1
            ADDLT   R1, R1, #1

            MOV     R10, #0             ; rezultat (broj prolaza petlje) sprema se u R10 i tako vraca

DIV_LOOP    CMP     R1, R2
            BLT     DIV_RET             ; dijeljenje gotovo kada djeljenik manji od djelitelja

            SUB     R1, R1, R2          ; umanjivanje djeljenika
            ADD     R10, R10, #1        ; uvecavanje rezultata
            B       DIV_LOOP            ; ponavljanje petlje do uvjeta

DIV_RET     CMP     R0, #1              ; rezultat negativan ako je u R0 1, inace je u R0 0 ili 2
            MVNEQ   R10, R10            ; dvojni komplement
            ADDEQ   R10, R10, #1

            LDMFD   SP!, {R0-R2}        ; obnova konteksta
            MOV     PC, LR              ; ovaj put standardni return


KRAJ        STR     R8, [R6]            ; upisuje znak za kraj rezultata
            SWI     0x123456            ; prekida simulaciju


KRAJ_POD    DW      0x88888888          ; kraj podataka na labeli KRAJ_POD
KRAJ_REZ    DW      0xFFFFFFFF          ; kraj rezultata na labeli KRAJ_REZ


            ORG     0x700               ; upisuj podatke od adrese 0x700

            DW      0x00000003          ; podatak 1
            DW      0xFFFFFEFF
            DW      0x00000010

            DW      0x00000001          ; podatak 2
            DW      0x000001F4
            DW      0xFFFFFD44

            DW      0x00000002          ; podatak 3
            DW      0xFFFFFFFE
            DW      0x0000000A

            DW      0x00000003          ; podatak 4
            DW      0xFFFFF000
            DW      0xFFFFFFC0

            DW      0x88888888          ; kraj podataka

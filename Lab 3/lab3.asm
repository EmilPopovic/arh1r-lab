            addi    sp, x0, 0x100           ; inicijalizacija stoga
            slli    sp, sp, 8               ; sp := 0x10000

            lui     s1, %hi(0xFFFF0F00)     ; s1 := GPIO1   
            addi    s1, s1, %lo(0xFFFF0F00)

            lui     s2, %hi(0xFFFF0B00)     ; s2 := GPIO2
            addi    s2, s2, %lo(0xFFFF0B00)

            addi    t2, x0, 0b11100000      ; GPIO2_PA_DDR zbog spojenih led
            sw      t2, 8(s2)               ; GPIO1_PB_DDR default dobar

            addi    s3, x0, 0b00000011      ; pritisnuta i tipka i sklopka
            addi    s4, x0, 13              ; za provjeriti brojac <= 12 (brojac < 13)

            addi    x17, x0, 0              ; x17 := brojac pritisaka tipke

petlja      lw      t6, 0(s2)               ; t6 := sadrzaj GPIO2_PA_DR
            and     t1, t6, s3              ; izoliraj najniza dva bita
            blt     t1, s3, petlja          ; provjeri opet dok je tipka ili sklopka iskljucena

            addi    x17, x17, 1             ; uvecaj brojac za 1
            blt     x17, s4, nastavi        ; nemoj brisati brojac ako nije presao 12

            addi    x17, x0, 1              ; brojac presao 12 pa ide na 1

nastavi     jal     ra, obradi              ; u (x10, x11) upisi ascii od (jedinice, desetice)
            jal     ra, ispisi              ; na lcd ispisi broj zapisan u x10 i x11

            beq     x0, x0, petlja          ; nastavi


obradi      ; <- x17 := stanje brojaca [0-19]
            ; -> x10 := ascii desetica brojaca
            ; -> x11 := ascii jedinica brojaca

            addi    sp, sp, -8              ; spremi kontekst
            sw      t0, 0(sp)               ; t0 := 9 (kasnije 10)
            sw      t1, 4(sp)               ; t1 := racun sa stanjem brojila

            addi    t0, x0, 9               ; desetice 1 ako x17 > 9 inace 0
            addi    t1, x17, 0              ; t1 := x17 (ali smije se mijenjati)

            slt     x10, t0, x17
            addi    x10, x10, 0x30          ; pretvori x10 u ascii

            addi    t0, x0, 10              ; t0 := 10

            blt     x17, t0, jednzn_o       ; u x17 vec jedinice ako <10

            sub     t1, x17, t0             ; jedinice za 10 manje ako >= 10

jednzn_o    addi    x11, t1, 0x30           ; sada jedinice u t1, pretvori u ascii
            
            lw      t0, 0(sp)               ; vrati kontekst
            lw      t1, 4(sp)
            addi    sp, sp, 8

            jalr    x0, 0(ra)               ; return


ispisi      ; <- x10 := ascii desetica
            ; <- x11 := ascii jedinica

            addi    sp, sp, -12             ; spremi kontekst
            sw      a2, 0(sp)               ; a2 := ispisivani znak
            sw      t0, 4(sp)               ; t0 := sprema ra
            sw      t1, 8(sp)               ; t1 := 0x30 (ascii 0)

            addi    t0, ra, 0               ; spremi ra u t0
            addi    t1, x0, 0x30            ; ascii 0 za provjeru jedinica

            addi    a2, x0, 0x0D            ; brisi lcd
            jal     ra, lcdwr

            beq     x10, t1, jednzn_p       ; ignoriraj desetice ako 0

            addi    a2, x0, 0x31            ; salji 1 ako dvoznamenkast
            jal     ra, lcdwr

jednzn_p    addi    a2, x11, 0              ; salji jedinice
            jal     ra, lcdwr

            addi    a2, x0, 0x0A            ; pisi na lcd
            jal     ra, lcdwr

            addi    ra, t0, 0               ; vrati stari ra iz t0

            lw      a2, 0(sp)               ; vrati kontekst
            lw      t0, 4(sp)
            lw      t1, 8(sp)
            addi    sp, sp, 12

            jalr    x0, 0(ra)               ; return


lcdwr       ; <- a2 := ascii ispisivanog znaka
            ; <- s1 := bazna adresa gpio

            andi    a2, a2, 0x7F
            sb      a2, 4(s1)
            ori     a2, a2, 0x80
            sb      a2, 4(s1)
            andi    a2, a2, 0x7F
            sb      a2, 4(s1)

            jalr    x0, 0(ra)
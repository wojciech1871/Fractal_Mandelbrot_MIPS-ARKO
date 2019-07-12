        	.data
fileName:   	.asciiz "mapa.bmp"		# nazwa pliku BMP
fileName2:	.asciiz "mapa_mandelbrot.bmp"
textPrompt: 	.asciiz "Podaj liczbe iteracji przy generowaniu zb. Mandelbrota: "
textOpen:	.asciiz "Pomyslnie otwarto plik\n"
textClose:	.asciiz "Pomyslnie zamknieto plik\n"

numberOfIt: 	.word 0				# liczba iteracji przy generowaniu zbioru Mandelbrota

buffer:		.space 50000000

  		.text
  		.globl main
main:
		la	$k0, buffer
		addiu	$k0, $k0, 2
		
		li 	$v0, 4			# Drukujemy prompt
		la 	$a0, textPrompt
		syscall
		
		li	$v0, 5			# Ladujemy liczbe iteracji
		syscall
		sw	$v0, numberOfIt
		lw	$t9, numberOfIt		# Do rejestru $t9 ladujemy liczbe iteracji
	
  						# Otwarcie pliku 
		li 	$v0, 13       		# $v0=13 dla otwarcia pliku
		la	$a0, fileName		# podajemy deskryptor pliku
		li 	$a1, 0        		# tryb 0 - do odczytu
		li 	$a2, 0        	
		syscall
		move 	$s0, $v0		# zapisujemy deskryptor pliku do rej. $s0
	
		li 	$v0, 4			# Komunikat o otwarciu pliku
		la 	$a0, textOpen
		syscall
		
		li 	$v0, 14			# Wczytujemy dane pliku (do 14 bajtu)
		move	$a0, $s0
		move	$a1, $k0
		li	$a2, 14
		syscall
						
   		move	$t0, $k0		# Do rejestru $s1 zapisujemy offset
   		addiu	$t0, $t0, 10
   		lwr 	$s1, ($t0)
  
  		li 	$v0, 14			# Wczytujemy dane pliku (naglowek BITmapy)
		move	$a0, $s0
		addiu	$a1, $t0, 4
		addi	$a2, $s1, -14
		syscall
		
		move	$t0, $k0		# Do rejestru $s3 zapisujemy szerokosc pliku
		addiu	$t0, $t0, 18
		lwr	$s3, ($t0)
		
		addiu	$t0, $t0, 4		# Do rejestru $s2 zapisujemy wysokosc pliku
		lwr	$s2, ($t0)
		
		and	$s4, $s3, 3		# Do rejestu $s4 zapisujemy reszte z dzielenia szerokosci przez 4 (DO PADDINGU)	
		
		move	$t0, $k0		# $t0 - rejestr wskaznika adresu aktualnej komorki
		addu	$t0, $t0, $s1
		
		# Tutaj ladujemy stale potrzebne do przyspieszenia obliczen		
		li	$s5, 4
		sll	$s5, $s5, 25
		li	$s6, 4
		sll	$s6, $s6, 25
		
		div	$s5, $s5, $s2		# w rejestrze $s5 4/height
		div	$s6, $s6, $s3		# w rejestrze $s6 4/width
		
		li	$s7, 2
		sll	$s7, $s7, 25		# w rejestrze $s7 2 zapisana w nowej konwencji
			
		# GLOWNY KOD PROGRAMU
		# $t1 - licznik petli po wierszach
		# $t2 - licznik petli po kolumnach
		# $t3 - licznik petli po four_pixel
		# $a0 - licznik petli Mandelbrota
		move	$t1, $zero		# inicjalizacja licznika $t1 - po wierszach
i_loop:						
		move	$t2, $zero		# inicjalizacja $t2 - licznik petli po kolumnach
		mul	$t8, $t1, $s5		# $t8 - c_im
		sub	$t8, $t8, $s7
		
j_loop:	
		move	$t3, $zero		# inicjalizacja $t3 - licznik 4 pikseli
		move	$s1, $zero		# odswiezenie $s1 - znacznika pikseli
		
four_pixels:	
		move	$a0, $zero		# inicjalizacja $a0 - licznik iteracji Mandelbrota
		
		move	$a1, $zero		# inicjalizacja $a1 - x
		move	$a2, $zero		# inicjalizacja $a2 - y
		mul	$t7, $t2, $s6
		sub	$t7, $t7, $s7		# $t7 - c_re
mand_loop:	
		mul	$t4, $a1, $a1
		mfhi	$k1
		sll	$k1, $k1, 7
		srl	$t4, $t4, 25
		or	$t4, $t4, $k1		# $t4 - x^2
		
		mul	$t5, $a2, $a2
		mfhi	$k1
		sll	$k1, $k1, 7
		srl	$t5, $t5, 25
		or	$t5, $t5, $k1		# $t5 - y^2
		
		add	$a3, $t4, $t5
		bgt	$a3, 134217728, jump
		
		sub	$a3, $t4, $t5		# $a3 = x_new
		add	$a3, $a3, $t7		# x_new = x^2 - y^2 + c_re
		
		mul	$a2, $a1, $a2
		mfhi	$k1
		sll	$k1, $k1, 7
		srl	$a2, $a2, 25
		or	$a2, $a2, $k1
		sll	$a2, $a2, 1		# y = 2 * x * y + c_im
		add	$a2, $a2, $t8
		
		move	$a1, $a3		# x = x_new
		
		addiu	$a0, $a0, 1
		bltu	$a0, $t9, mand_loop
		li	$a1, 1
		sllv	$a1, $a1, $t3
		or	$s1, $s1, $a1		
jump:		
		addiu	$t2, $t2, 1
		addiu	$t3, $t3, 1
		
		bltu	$t3, 4, four_pixels
		
		# w rejestrze $s1 bêdziemy mieli informacjê, które piksele s¹ zajête, rejestr $k1 - maska
		li	$t4, -1			# a priori zakladamy, ze wszystkie piksele biale
		move	$t5, $t4
		move	$t6, $t4
		and	$k1, $s1, 1		# sprawdzamy 1. piksel
		bne	$k1, 1, pixel_2
		li	$t4, -16777216

pixel_2:	and	$k1, $s1, 2
		bne	$k1, 2, pixel_3		# sprawdzamy 2. piksel
		andi	$t4, 16777215
		li	$t5, -65536

pixel_3:	and	$k1, $s1, 4
		bne	$k1, 4, pixel_4
		andi	$t5, 65535
		li	$t6, -256	

pixel_4:	and	$k1, $s1, 8
		bne	$k1, 8, exit
		andi	$t6, 255
		
exit:		sw	$t4, ($t0)		# zapisywanie pikseli i zwiekszanie wskaznika pamieci	
		sw	$t5, 4($t0)
		sw	$t6, 8($t0)
		addiu	$t0, $t0, 12		# zwiekszamy adres o 3 slowa
		bltu	$t2, $s3, j_loop	# sprawdzanie warunku dla petli po kolumnach
		
		# OBSLUGA PADDINGU
		# tutaj uwzglêdnimy padding $s4 - znacznik, $k1 - maska

		beq	$s4, 0, pad_3		# brak paddingu - skocz do petli po wierszach
		bne	$s4, 3, pad_1
		andi	$t6, 255
		sw	$t6, -4($t0)
		b	pad_3
		
pad_1:		bne	$s4, 2, pad_2	
		addiu	$t0, $t0, -4
		andi	$t5, 65535
		sw	$t5, -4($t0)
		b	pad_3
		
pad_2:		addiu	$t0, $t0, -8
		andi	$t4, 16777215
		sw	$t4, -4($t0)	
		
pad_3: 		addiu	$t1, $t1, 1
  		bltu	$t1, $s2, i_loop	# sprawdzanie warunku dla petli po wierszach
  		
  		# KONIEC ALOGORYTMU
  	
		li   	$v0, 16			# syscall dla zamykania pliku
		move 	$a0, $s0		# podajemy deskryptor pliku do zamkniecia
		syscall				# zamkniecie pliku
	
		li 	$v0, 4			# Komunikat o zamknieciu pliku
		la 	$a0, textClose
		syscall
  						# Otwarcie pliku 
		li 	$v0, 13       		# $v0=13 dla otwarcia pliku
		la	$a0, fileName2		# podajemy deskryptor pliku
		li 	$a1, 1        		# tryb 0 - do odczytu
		li 	$a2, 0        	
		syscall
		move 	$s0, $v0		# zapisujemy deskryptor pliku do rej. $s0
		

		li   	$v0, 15			# Zapis do pliku
 		move 	$a0, $s0
  		move   	$a1, $k0
  		sub	$a2, $t0, $k0
  		syscall

  		li   	$v0, 16			# Zamkniecie pliku do ktorego zapisalismy
  		move 	$a0, $s0  	
  		syscall       		
  


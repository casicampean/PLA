.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Memory Blocks",0
area_width EQU 345
area_height EQU 400
area DD 0

rosu DD 0FF0000h
alb DD 0FFFFFFh

nr_click DD 0 ;numara click-urile date
counter DD 0 ; numara evenimentele de tip timer

carti_verificate DD 16 DUP(0)
;la inceput toate vor fi 0, daca este 0 atunci trebuie intoarsa
;daca nu este 0 atunci a disparut

poz_x1 DD 0
poz_x2 DD 0
poz_y1 DD 0
poz_y2 DD 0

poz_c1 DD 0 
poz_c2 DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
p_width EQU 40
p_height EQU 50
include digits.inc
include letters.inc
include picture.inc

.code
;procedura make_picture afiseaza imaginea din picture
;arg1 numarul imaginii de afisat
;arg2 pointer vector pixeli
;arg3 pos_x
;arg 4 pos_y
make_picture proc
    push ebp
	mov ebp,esp
	pusha
	
	mov eax,[ebp+arg1];citim numarul de ordine al imaginii imaginea ex 0
	lea esi,picture
draw_picture:
    mov ebx,p_width
	mul ebx
	mov ebx,p_height
	mul ebx;eax<-nr_img*latime*lungime
	add esi,eax
	mov ecx,p_height
bucla_simbol_linii:
    mov edi,[ebp+arg2];pointer matricea pixeli
	mov eax,[ebp+arg4];pointer y
	add eax,p_height
	sub eax,ecx
	mov ebx,area_width
	mul ebx
	add eax,[ebp+arg3]
	shl eax,2
	add edi,eax
	push ecx
	mov ecx,p_width
bucla_simbol_coloane:
	push dword ptr[esi]
	pop dword ptr[edi]
	add esi,4;in picture este DD si trebuie sa adaugam 4 bytes,la letter trebuie doar +1
	add edi,4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp,ebp
	pop ebp
	ret
make_picture endp
;prin acest macro apelam mai usor desenarea unei imagini din picture.inc
;nr_carte este pozitia unde se afla o anumita carte in picture.inc
;nr_carte trebuie inmultit cu 4 pt afisarea corecta a imaginii 
make_pic macro nr_carte, drawArea, x, y
	push y
	push x
	push drawArea
	mov edx,nr_carte
	shl edx,2
	push edx
	call make_picture
	add esp, 16
endm
;procedura make_picture2 deseneaza cartea cu o anumita culoare
;arg1 culoarea
;arg2 pointer vector pixeli
;arg3 pos_x
;arg 4 pos_y
make_picture2 proc
    push ebp
	mov ebp,esp
	pusha
	
	lea esi,picture
draw_picture:
    mov ebx,p_width
	mul ebx
	mov ebx,p_height
	mul ebx;eax<-nr_img*latime*lungime
	add esi,eax
	mov ecx,p_height
bucla_simbol_linii:
    mov edi,[ebp+arg2];pointer matricea pixeli
	mov eax,[ebp+arg4];pointer y
	add eax,p_height
	sub eax,ecx
	mov ebx,area_width
	mul ebx
	add eax,[ebp+arg3]
	shl eax,2
	add edi,eax;edi<-edi+ ((y+inaltime-latime)*latime+x)*4
	push ecx
	mov ecx,p_width
bucla_simbol_coloane:
	mov edx,[ebp+arg1]
	mov dword ptr [edi], edx
	add esi,4
	add edi,4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp,ebp
	pop ebp
	ret
make_picture2 endp
;prin acest macro apelam mai usor desenarea unei carti de o anumita culoare 
make_pic2 macro color, drawArea, x, y
	push y
	push x
	push drawArea
	push color
	call make_picture2
	add esp, 16
endm

make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	sub eax, 'A'
	lea esi, letters
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] 
	mov eax, [ebp+arg4] 
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] 
	shl eax, 2 
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret 4
make_text endp
; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm
;acest macro ne ajuta in momentul in care ajungem sa facem sa se afiseze o anumita carte in funcie de click-ul dat
carteee macro poz, nr_cartee,x,y
local nu_misca01,cont01_1,cont01_2
    cmp carti_verificate[poz],0;verific daca trebuie intoarsa
	je nu_misca01;daca este egala cu 0 atunci trebuie intoarsa si sarim la nu_misca_01
;daca nu este egala cu 0 scadem din nr_click deoarece inseamna ca este intoarsa
;si spatiul ocupat de acea carte este acum alb, iar prin apasarea lui
;nu se intampla nimic, iar in acest caz sarim la final_draw
	dec nr_click
	jmp final_draw
nu_misca01:	
;cand dam click facem cartea sa apara
    make_pic nr_cartee,area,x,y
;trebuie sa comparam nr de click-uri, daca este 1 atunci vom muta in poz_x1 si poz_y1 
;coordonatele x si y la primul click, in poz_c1 mutam pozitia cartii din vectorul 
;carti_verificate, si mutam nr de ordine(din picture.inc) al cartii in carti_verificate deoarece 
;asta ne ajuta cand verificam la inceput daca mai trebuie intoarsa cartea sau nu si ne ajuta sa verificam
;daca cele 2 carti sunt la fel
	cmp nr_click,1
	jne cont01_1
	mov poz_c1,poz
	mov poz_x1,x
	mov poz_y1,y
	mov carti_verificate[poz],nr_cartee
cont01_1:
;aici comparam daca am dat al 2-lea click, daca da atunci procedam ca si la primul click,
;doar ca vom retine datele in poz_x2,pox_y2 si poz_c2
	cmp nr_click,2
	jne cont01_2
	mov poz_c2,poz
	mov poz_x2,x
	mov poz_y2,y
	mov carti_verificate[poz],nr_cartee
cont01_2:
    jmp final_draw
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	 mov eax, [ebp+arg1]
	 cmp eax, 1
	 jz evt_click
	 cmp eax, 2
	 jz evt_timer ; nu s-a efectuat click pe nimic
	 
	;mai jos e codul care intializeaza fereastra cu pixeli albi

	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
;afisez pe ecran cele 8 perechi de carti intoarse cu capul in jos	
    make_pic2 rosu,area,40,40
    make_pic2 rosu,area,115,40
    make_pic2 rosu,area,190,40
    make_pic2 rosu,area,265,40
 
    make_pic2 rosu,area,40,120
    make_pic2 rosu,area,115,120
    make_pic2 rosu,area,190,120
    make_pic2 rosu,area,265,120
 
    make_pic2 rosu,area,40,200
    make_pic2 rosu,area,115,200
    make_pic2 rosu,area,190,200
    make_pic2 rosu,area,265,200
 
    make_pic2 rosu,area,40,280
    make_pic2 rosu,area,115,280
    make_pic2 rosu,area,190,280
    make_pic2 rosu,area,265,280
	
;afisez numele proiectului	
	make_text_macro 'M', area, 105, 350
	make_text_macro 'E', area, 115, 350
	make_text_macro 'M', area, 125, 350
	make_text_macro 'O', area, 135, 350	
	make_text_macro 'R', area, 145, 350	
	make_text_macro 'Y', area, 155, 350	
	
	make_text_macro 'B', area, 175, 350	
	make_text_macro 'L', area, 185, 350	
	make_text_macro 'O', area, 195, 350	
	make_text_macro 'C', area, 205, 350	
	make_text_macro 'K', area, 215, 350	
	make_text_macro 'S', area, 225, 350	
	
    mov counter,0
evt_click:
;in mod normal trebuie sa astept o secunda pentru a disparea sau pentru a intoarce cartile dupa 2 click-uri
;(folosind eticheta evt_timer),dar in cazul in care in acel timp de o secunda se  da un alt click,
; pentru o functionare mai buna a programului se sare la intoarce_dispare
	mov ebx,nr_click
	cmp ebx,2
	je intoarce_dispare
;mut in registrii esi si edi coordonatele lui x si y pentru verificarea zonei in care se apasa click-ul
    mov esi,[ebp+arg3];y
    mov edi,[ebp+arg2];x
;verific unde apas
;in functie de unde apas trebuie sa apara o imagine (cu make_picture1)
;mai apas odata,apare inca o imagine
;trebuie sa astept o secunda(pentru asta ma folosesc de eticheta evt_timer
;de la eticheta evt_timer dupa 2 click-uri si o secunda ajung la eticheta intoarce_dispare
;la acea eticheta compar cele 2 imaginii
;daca sunt egale atunci ele vor disparea(se vor colora cu alb cu make_pic2)
;daca nu sunt egale atunci se intorc cartile(se coloreaza cu rosu)

verificare_click:

;verific daca sunt inafara cartilor, daca da atunci sar la final_draw
    cmp esi,40
    jl final_draw
    cmp esi,330
    jg final_draw
    cmp edi,40
    jl final_draw
    cmp edi,305
    jg final_draw

;verific daca sunt intre carti, daca da atunci sar la final_draw
;r_alb0 este primul rand alb dintre carti
    cmp esi,120;coordonata y
    jl r_alb0
    jg r_alb1
r_alb0:
    cmp esi,90
    jg final_draw

r_alb1:
    cmp esi,200
    jg r_alb2
    cmp esi,170
    jg final_draw
r_alb2:
    cmp esi,280
    jg continuare1
    cmp esi,250
    jg final_draw

;verific coloanele albe dintre carti
continuare1:
    cmp edi,115
    jl c_alb0
    jg c_alb1

c_alb0:
    cmp edi,80
    jg final_draw
c_alb1:
    cmp edi,190
    jg c_alb2
    cmp edi,155
    jg final_draw
c_alb2:
    cmp edi,265
    jg continuare2
    cmp edi,230
    jg final_draw

continuare2:

    inc nr_click
;incrementez nr de click-uri
;cand vor fi 2 click-uri trebuie sa astept o secunda

;aici verific daca apas pe o anumita carte
;in functie re randul si pozitia unde se afla cartea voi sari la eticheta corespunzatoare
;fiecarei carti (carte_00, carte_01 etc)
;r0 este primul rand de carti
;r01 este primul primul rand de carti si a2a coloana
;pe baza acestor coordonate am verificat pe ce carte se da click
;si in functie de locul click-ului sar la eticheta cartii pentru a o afisa
;rand=(y1,y2)-->r0=(40,90);r1=(120,170);r2=(200,250);r3=(280,330);
;coloana=(x1,x2)-->c0=(40,80);c1=(115,155);c2=(190,230);c3=(265,305);

    cmp esi,90;daca y>90 atunci click-ul este dat pe un rand mai mare
    jg r1
    jl r0;daca y<90 atunci sigur este pe r0
r0:
    cmp edi,80;daca x<80 atunci sigur este cartea_00
    jl carte_00
    jg r01;daca x>80 atunci este pe randul 0 si pe o coloana mai mare
r1:
    cmp esi,170
    jg r2
    cmp edi,80
    jl carte_10
    jg r_11
r2:
    cmp esi,250
    jg r3
    cmp edi,80
    jl carte_20
    jg r_21
r3:
    cmp edi,80
    jl carte_30
    jg r_31
r01:
    cmp edi,155
    jg r02
    jl carte_01
r02:
    cmp edi,230
    jg carte_03
    jl carte_02
r_11:
    cmp edi,155
    jg r_12
    jl carte_11
r_12:
    cmp edi,230
    jg carte_13
    jl carte_12
r_21:
    cmp edi,155
    jg r_22
    jl carte_21
r_22:
    cmp edi,230
    jg carte_23
    jl carte_22
r_31:
    cmp edi,155
    jg r_32
    jl carte_31
r_32:
    cmp edi,230
    jg carte_33
    jl carte_32

;carte_00 este carte de pe randul 0 si coloana 0
carte_00:
	carteee  0,3,40,40
carte_01:
	carteee  4,38,115,40	
carte_02:
	carteee  8,46,190,40
carte_03:
	carteee  12,31,265,40
carte_10:
	carteee  16,44,40,120
carte_11:
	carteee  20,31,115,120
carte_12:
	carteee  24,46,190,120
carte_13:
	carteee  28,49,265,120
carte_20:
	carteee  32,27,40,200
carte_21:
	carteee  36,35,115,200
carte_22:
	carteee  40,3,190,200
carte_23:
	carteee  44,35,265,200
carte_30:
	carteee  48,49,40,280
carte_31:
	carteee  52,44,115,280
carte_32:
	carteee  56,27,190,280
carte_33:
	carteee  60,38,265,280
	
;la aceasta eticheta ajung daca am dat 2 click-uri si a trecut o secunda
;prima data compar valoarea(nr de ordine al imaginii) care se afla in vectorul carti_verificate la
;pz_x1 si poz_x2; daca valoarea este egala atunci sar la eticheta dispare,
;daca nu este egala sar atunci la eticheta intoarce
intoarce_dispare:
    mov counter,0
    mov nr_click,0
    mov eax,poz_c1
	mov ebx,poz_c2
    mov ecx,carti_verificate[eax]
    mov edx,carti_verificate[ebx]
    cmp ecx,edx
    je dispare
    jne intoarce
	jmp final_draw
;daca am ajuns la aceasta eicheta atunci voi colora carti cu alb
dispare:
    make_pic2 alb,area,poz_x1,poz_y1
    make_pic2 alb,area,poz_x2,poz_y2
	mov poz_c1,0
    mov poz_c2,0
    mov poz_x1,0
    mov poz_y1,0
    mov poz_x2,0
    mov poz_y2,0
    jmp final_draw
;daca am ajuns la aceasta eticheta atunci voi colora carti cu rosu
;si voi muta in vectorul carti_verificate la pozitia fiecarei carti valoarea 0
;asta insemnand ca va trebui din nou intoarsa(adica atunci cand voi da click sa apara o imagine	
intoarce:
    make_pic2 rosu,area,poz_x1,poz_y1
    make_pic2 rosu,area,poz_x2,poz_y2
    mov eax,poz_c1
    mov carti_verificate[eax],0
    mov eax,poz_c2
    mov carti_verificate[eax],0
    mov poz_c1,0
    mov poz_c2,0
    mov poz_x1,0
    mov poz_y1,0
    mov poz_x2,0
    mov poz_y2,0
    jmp final_draw
	
;aici ajung atunci cand nu dau niciun click
;functia draw se apeleaza de 5 intr-o secunda
;la aceasta eticheta compar nr_click cu 2 si compar counter cu 5
;if(nr_click==2 && counter==5){nr_click=0;counter=0;jmp intoarce_dispare}
;else {counter++}
evt_timer:
    mov eax,nr_click
    cmp eax,2
    jne final_draw
    mov ebx,counter
    cmp counter,5
    jne coont
    mov counter,0
    mov nr_click,0
    jmp intoarce_dispare
coont:
    inc counter
;aici verific cu un loop daca toate cartile au fost intoarse
;daca da, atunci afisez mesajul final
    mov ecx,16 
    mov edx,0
next:
    cmp carti_verificate[edx],0
    je final_draw
    add edx,4
    loop next

mesaj_final:
	make_text_macro 'A', area, 85, 330	
	make_text_macro 'T', area, 95, 330
	make_text_macro 'I', area, 105, 330
	
	make_text_macro 'T', area, 125, 330	
	make_text_macro 'E', area, 135, 330	
	make_text_macro 'R', area, 145, 330	
	make_text_macro 'M', area, 155, 330	
	make_text_macro 'I', area, 165, 330	
	make_text_macro 'N', area, 175, 330	
	make_text_macro 'A', area, 185, 330
	make_text_macro 'T', area, 195, 330
	
	make_text_macro 'J', area, 215, 330	
	make_text_macro 'O', area, 225, 330	
	make_text_macro 'C', area, 235, 330
	make_text_macro 'U', area, 245, 330
	make_text_macro 'L', area, 255, 330
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start

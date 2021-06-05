;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.386
		.model flat,stdcall
		option casemap:none
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Include 文件定义
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
include		windows.inc
include		gdi32.inc
include		masm32.inc
include		kernel32.inc
include		user32.inc
include		winmm.inc
includelib	gdi32.lib
includelib  msvcrt.lib
includelib	winmm.lib
includelib	user32.lib
includelib	kernel32.lib
rand	proto C
srand	proto C:dword
printf proto C:ptr sbyte,:vararg
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 数据段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		.data?
hInstance	dd		?
hWinMain	dd		?
hBrush dd ?
startTime	dd	?
board_max_pos_x dd ?
;#########资源文件
IDB_BITMAP2 equ 111
IDB_MENU1 equ 150
IDB_MENU2 equ 151
IDB_MENU3 equ 152
IDB_MENU4 equ 153
IDB_MARK1	equ	154
IDB_RETURN equ	155
IDB_HELP	equ	156
IDB_HELPMARK	equ	157
IDB_BACK1	equ	158
IDB_BACK2	equ	159
IDB_BACK3	equ	160
IDB_BACK4	equ	161
IDB_BACK5	equ	162
IDB_BACKMARK	equ	163
IDB_BACKSMALL1	equ	164
IDB_BACKSMALL2	equ	165
IDB_BACKSMALL3	equ	166
IDB_BACKSMALL4	equ	167
IDB_BACKSMALL5	equ	168
IDB_CHOICE1	equ	169
IDB_CHOICEMARK1	equ	170
IDB_CHOICE2	equ	171
IDB_CHOICEMARK2	equ	172

IDB_NUM0	equ	173
IDB_NUMMARK0	equ	174
IDB_NUM1	equ	175
IDB_NUMMARK1	equ	176
IDB_NUM2	equ	177
IDB_NUMMARK2	equ	178
IDB_NUM3	equ	179
IDB_NUMMARK3	equ	180
IDB_NUM4	equ	181
IDB_NUMMARK4	equ	182
IDB_NUM5	equ	183
IDB_NUMMARK5	equ	184
IDB_NUM6	equ	185
IDB_NUMMARK6	equ	186
IDB_NUM7	equ	187
IDB_NUMMARK7	equ	188
IDB_NUM8	equ	189
IDB_NUMMARK8	equ	190
IDB_NUM9	equ	191
IDB_NUMMARK9	equ	192

IDB_SCORE	equ	193
IDB_SCOREMARK	equ	194
IDB_STOP	equ	195
IDB_RETURN2	equ	196

IDB_BOARD1 equ 117
IDB_BOARD2 equ 118
IDB_BOARD3 equ 119
IDB_BITMAP7 equ 120
IDB_BOARDMARK2 equ 121
IDB_BOARDMARK3 equ 122
IDB_MAN1  equ  123
IDB_MANMARK1  equ  124
IDB_MAN2  equ  125
IDB_MANMARK2  equ  126
IDB_MAN3   equ 127
IDB_MANMARK3  equ  128
IDB_MAN4  equ  129
IDB_MANMARK4  equ  130
IDB_MANSEL1	equ	131
IDB_MANSEL2	equ	132
IDB_MANSEL3	equ	133
IDB_MANSEL4	equ	134
IDB_ONE equ 2000
;#########结构体
MYTYPE struct
		wood	dd	?
		spine	dd	?
		glass	dd	?
	MYTYPE ends

PLAYER struct
		x	dd	?
		y	dd	?
		score	dd	?
		hp	dd	?
	PLAYER ends

MANPOS	struct
	x	dd		?
	y	dd		?
	MANPOS ends

BOARD struct
		x_left	dd	?
		x_right	dd	?
		y	dd	?
		IsHp	dd	?
		mytype	dd	?
		startTime	dd	?
	BOARD ends
;#########全局变量
;记录窗口的大小，结构体内容为 top，left，bottom，right（四角的值）
stRect RECT <0,0,0,0>
IsTouchBack	dd	-1

man		PLAYER	<5,5,0,5>;通过man.hp得到man的生命值
manAddr		dd		?

boards	BOARD 13 dup(<0,0,0,0,0>);结构体数组

back_flag	dd	1;背景图
man_flag	dd	1;选择人物头像
man_height	dd	30
man_width	dd	41
man_life_flag	dd	0;当该值为3时，分数加1，并将该值置零，每刷新一次，该值加1

gamePattern	dd	1;游戏的难易模式
flag dd 0
Paint_flag dd 0;页面跳转标志 0：菜单 1：游戏界面，2：设置界面，3：帮助界面
isGameOver	dd	0;游戏是否结束
HP_flag	dd	0;加血道具出现的次数
.const
manNum	dd	4
Mytype	MYTYPE	<0,1,2>;通过Mytype.wood得到wood的值
BOARD_LEN	dd 	24
jump_dist dd 8 ;每次刷新位移距离，可调节运行速度
board_width dd 100 ;板子长度
board_height dd 20 ;板子高度
flushTime	dd	100
szClassName	db	'MyClass',0
szCaptionMain	db	'game',0
man1	MANPOS	<30,41>;四个人物的高度和宽度
man2	MANPOS	<30,27>
man3	MANPOS	<30,31>
man4	MANPOS	<30,38>
ten dd	10
PAUSETIME	dd	300;刷新时间
boardCount dd 13
board_num	dd	13;木板数量
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; 代码段
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.code
;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>显示相关
isDisappear proc C num:DWORD
	local @cur_time:dword
	local @board_time:dword
	local @during_time:dword
	local @tmp:dword 
	
	mov edi,offset boards
	mov eax,num
	mov	ebx,TYPE BOARD
	mul	ebx
	add	edi,eax
S_:

	mov @tmp,1
	mov eax,(BOARD PTR [edi]).mytype
	cmp eax,Mytype.glass
	jne T
	mov eax,(BOARD PTR [edi]).startTime
	mov @board_time,eax
	invoke GetTickCount
	mov @cur_time,eax
	mov ecx,@board_time
	sub eax,ecx
	mov @during_time,eax
	mov eax,10000	;时间可能需要调整
	mul @tmp
	cmp @during_time,eax
	jg S
T:
	mov eax,1
	ret
S:	mov eax,0
	ret

isDisappear endp
displayBg proc uses ebx edi esi eax hWnd,hDc,hBitMap
		local	@hdcMe:DWORD
		local	@bminfo :BITMAP
		invoke SetStretchBltMode,hDc,HALFTONE
		invoke CreateCompatibleDC,hDc
		mov @hdcMe,eax
		invoke CreatePatternBrush,hBitMap
		mov hBrush,eax
		invoke SelectObject,@hdcMe,hBrush
		invoke FillRect,hDc,addr stRect,hBrush
		invoke DeleteObject,hBitMap
		invoke DeleteDC,@hdcMe
		ret
displayBg endp
displayBm proc uses ebx edi esi eax hWnd,hDc,hBitMap, bmX, bmY, w, h;w=width,h=height，可指定bitmap的位置和大小
		local	@hdcMe:DWORD
		local	@bminfo :BITMAP
		invoke SetStretchBltMode,hDc,HALFTONE
		invoke CreateCompatibleDC,hDc
		mov @hdcMe,eax
		invoke GetObject,hBitMap,type @bminfo,addr @bminfo
		invoke SelectObject,@hdcMe,hBitMap

		invoke  StretchBlt,hDc,bmX,bmY,w,h,@hdcMe,0,0,@bminfo.bmWidth,@bminfo.bmHeight, SRCCOPY
		invoke DeleteObject,hBitMap
		invoke DeleteDC,@hdcMe
		ret
displayBm endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>;菜单按钮的图片要与输出的位置做或运算，才能正确输出>>>>>>>>>>>>>>>>>>>>>>>>>
displayBmOR proc uses ebx edi esi eax hWnd,hDc,hBitMap, bmX, bmY, w, h;w=width,h=height，可指定bitmap的位置和大小
		local	@hdcMe:DWORD
		local	@bminfo :BITMAP
		invoke SetStretchBltMode,hDc,HALFTONE
		invoke CreateCompatibleDC,hDc
		mov @hdcMe,eax
		invoke GetObject,hBitMap,type @bminfo,addr @bminfo
		invoke SelectObject,@hdcMe,hBitMap

		invoke  StretchBlt,hDc,bmX,bmY,w,h,@hdcMe,0,0,@bminfo.bmWidth,@bminfo.bmHeight, SRCPAINT;
		invoke DeleteObject,hBitMap
		invoke DeleteDC,@hdcMe
		ret
displayBmOR endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>在指定位置输出mark>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
displayMark proc uses ebx edi esi eax hWnd,hDc,hBitMap, bmX, bmY, w, h;w=width,h=height，可指定bitmap的位置和大小
		local	@hdcMe:DWORD
		local	@bminfo :BITMAP
		invoke SetStretchBltMode,hDc,HALFTONE
		invoke CreateCompatibleDC,hDc
		mov @hdcMe,eax
		invoke GetObject,hBitMap,type @bminfo,addr @bminfo
		invoke SelectObject,@hdcMe,hBitMap

		invoke  StretchBlt,hDc,bmX,bmY,w,h,@hdcMe,0,0,@bminfo.bmWidth,@bminfo.bmHeight, SRCAND
		invoke DeleteObject,hBitMap
		invoke DeleteDC,@hdcMe
		ret
displayMark endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>板子>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>..
;板子
displayBoards proc uses ebx edi esi hWnd ,hDc
	local @board_exsit:DWORD
	local @tmo_board:BOARD
	local	@hBitMap,@hBmpMark
	mov edi,0
	mov ecx,0
L:	
	push ecx
	push edi
	mov eax,(BOARD PTR boards[edi]).y
	mov @tmo_board.y,eax

	mov eax,(BOARD PTR boards[edi]).x_left
	mov @tmo_board.x_left,eax

	mov eax,(BOARD PTR boards[edi]).mytype
	mov @tmo_board.mytype,eax

	invoke isDisappear,ecx
	mov @board_exsit,eax
	cmp @board_exsit,1
	jne default
	mov eax,@tmo_board.y
	cmp eax,stRect.bottom
	jge default
	mov eax,@tmo_board.mytype
	cmp eax,Mytype.wood
	je case1
	mov eax, @tmo_board.mytype
	cmp eax,Mytype.spine
	je case2
	mov eax, @tmo_board.mytype
	cmp eax,Mytype.glass
	je case3
	jmp default
case1:
	invoke LoadBitmap,hInstance,IDB_BOARD1
	mov @hBitMap,eax
	invoke displayBm,hWnd,hDc, @hBitMap, @tmo_board.x_left,@tmo_board.y,board_width,board_height
	jmp default
case2:
	invoke LoadBitmap,hInstance,IDB_BOARDMARK2
	mov @hBmpMark,eax
	invoke displayMark,hWnd,hDc, @hBmpMark, @tmo_board.x_left,@tmo_board.y,board_width,board_height
	
	invoke LoadBitmap,hInstance,IDB_BOARD2
	mov @hBitMap,eax
	invoke displayBmOR,hWnd,hDc, @hBitMap, @tmo_board.x_left,@tmo_board.y,board_width,board_height
	jmp default
case3:
	cmp	@tmo_board.x_left,0
	jl	default
		invoke LoadBitmap,hInstance,IDB_BOARDMARK3
	mov @hBmpMark,eax
	invoke displayMark,hWnd,hDc, @hBmpMark, @tmo_board.x_left,@tmo_board.y,board_width,board_height
	
	invoke LoadBitmap,hInstance,IDB_BOARD3
	mov @hBitMap,eax
	invoke displayBmOR,hWnd,hDc, @hBitMap, @tmo_board.x_left,@tmo_board.y,board_width,board_height
	jmp default
default:
	pop edi
	pop ecx
	inc ecx
	add edi ,TYPE BOARD
	cmp ecx,boardCount
	jl L
	jmp	no
no:
	ret
displayBoards endp
isTouch1 proc uses ecx ebx edi edx
local @tmp_board:BOARD
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++TODO: istouch 重新设置参数，现在似乎不能正常使用
	; for1 (int i = 0; i < board_num; i++)
	sub ecx,ecx;i
	sub edi,edi
	mov eax,ecx
L:
	cmp		ecx, board_num
	jge		E1

		mov		ebx, boards[edi].x_right ; ebx:x_right
	mov @tmp_board.x_right,ebx
	mov		ebx, boards[edi].x_left ; ebx:x_right
	mov @tmp_board.x_left,ebx
	mov		ebx, boards[edi].y ; ebx:x_right
	mov @tmp_board.y,ebx
	mov		ebx, boards[edi].mytype ; ebx:x_right
	mov @tmp_board.mytype,ebx

	;man.x<board.left
	mov		ebx, boards[edi].x_left ; ebx:x_left
	cmp		man.x, ebx
	jl	S1

	; man.x+man_width < Boards[i].x_right
	mov		ebx, boards[edi].x_right ; ebx:x_right
	mov eax,man_width
	add		eax, man.x;因为人物有一定宽度
	cmp		eax, ebx
	jg		S1


	; man.y <= (Boards[i].y)-10
	mov		ebx, boards[edi].y ; ebx:y
	sub ebx,10;即适当放大合法范围
	mov edx,man.y
	add edx,man_height
	cmp	edx, ebx
	jl	S1
	;man.y>board[i].y+10
	mov		ebx, boards[edi].y ; ebx:y
	add ebx,10;即适当放大合法范围
	mov edx,man.y
	add edx,man_height
	cmp	edx, ebx
	jg	S1
	; if1 (Boards[i].type == spine)
	mov		ebx, boards[edi].mytype
	cmp		ebx, Mytype.spine
	je		E2
	mov		eax, ecx ; return i
	ret
E2:
	mov		eax, -2 ; return -2
	ret
S1:	
	inc		ecx
	add edi,TYPE BOARD
	jmp		L
E1:
	mov		eax, -1
	ret	
isTouch1 endp
ReviveMan proc uses ebx edx eax
	dec		man.hp
	;invoke	time, 0
	invoke	rand
	mov		ebx, board_max_pos_x
	div		ebx
	add		edx, 5
	mov		dword ptr man.x, edx
	mov		dword ptr man.y, 50
	ret
ReviveMan endp
;游戏人物
displayPlayer proc uses ebx edi edx esi hWnd,hDc
	local	@hBitMap,@hBmpMark
	mov		ecx, man.hp
	test	ecx, ecx
	jz		dPL1E
dPL1:
	;push		ecx
	;invoke	printf, offset kongge
	;pop		ecx
	;loop	dPL1
dPL1E:
	; if1 (isTouch() == -2 || Man.y <= 10 || Man.y >= border_height - 10)
	; isTouch() == -2
	invoke	isTouch1
	cmp		eax, -2
	je		dPIF1T
	; Man.y <= 1
	cmp		man.y, 10
	jle		dPIF1T
	; Man.y >= border_height - 2
	mov		eax, stRect.bottom
	sub		eax, 10
	cmp		man.y, eax
	jge		dPIF1T
	jmp		dPIF1F	
dPIF1T:
	invoke	ReviveMan
	; if2 (Man.hp)
	cmp		man.hp, 0
	je		dPIF2F
;	invoke	PrintInfo
dPIF2F:
dPIF1F:
	; if3 (Man.x < 2)
	cmp		man.x, 0
	jnl		dPIF3F
	mov		man.x, 0
	jmp		dPIF3E
dPIF3F:
	; else if4 (Man.x >= border_width - 2)
	mov		eax, stRect.right
	mov		edx, man_width
	sub		eax, edx
	cmp		man.x, eax
	jnge	dPIF4F
	sub		eax,edx
	mov		man.x, eax
dPIF4F:
dPIF3E:
	; if5 (Man.hp != 0)
	cmp		man.hp, 0
	je		dPIF5F
	mov ebx,IDB_MAN1
	dec ebx
	add ebx,man_flag
	add ebx,man_flag
	invoke LoadBitmap,hInstance,ebx
	mov @hBmpMark,eax
	invoke displayMark,hWnd,hDc, @hBmpMark, man.x,man.y,man_height,man_width
	dec ebx
	invoke LoadBitmap,hInstance,ebx
	mov @hBitMap,eax
	invoke displayBmOR,hWnd,hDc, @hBitMap,  man.x,man.y,man_height,man_width

;	invoke LoadBitmap,hInstance,IDB_BITMAP7
;	mov @hBitMap,eax
;	invoke displayBm,hWnd,hDc, @hBitMap,man.x,man.y,man_width,man_height
	;invoke	gotoXY, 2, 1
	; for (int i = 0; i < Man.hp; i++)
	mov		ecx, man.hp
	test	ecx, ecx
	jz		dPIF5E
dPL2:
	push		ecx
	;invoke	printf, offset hpStr
	pop		ecx
	loop	dPL2
	jmp		dPIF5E
dPIF5F:
	mov		eax, stRect.right
	sar		eax, 1
	sub		eax, 10
	mov		ebx, stRect.bottom
	sar		ebx, 1
	;invoke	gotoXY, eax, ebx
	;invoke	printf, offset gameOverStr
;	invoke	Sleep, 4000
	;invoke	system, offset clsStr
	mov Paint_flag,0
	;invoke InvalidateRect,hWnd,NULL,FALSE
	mov		eax,-1
dPIF5E:
	ret

displayPlayer endp

;其他属性：难度+生命+分数
displayOther proc uses ebx edi esi hWnd ,hDc
		local	@hBitMap,@hBmpMark
		invoke LoadBitmap,hInstance,IDB_SCOREMARK
		mov @hBmpMark,eax
		invoke displayMark,hWnd,hDc,@hBmpMark,660,20,140,50
		invoke LoadBitmap,hInstance,IDB_SCORE
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,hDc, @hBitMap,660,20,140,50

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>返回主界面>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		invoke LoadBitmap,hInstance,IDB_SCOREMARK
		mov @hBmpMark,eax
		invoke displayMark,hWnd,hDc,@hBmpMark,-20,20,100,50
		invoke LoadBitmap,hInstance,IDB_RETURN2
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,hDc, @hBitMap,-20,20,100,50
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>暂停>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		invoke LoadBitmap,hInstance,IDB_SCOREMARK
		mov @hBmpMark,eax
		invoke displayMark,hWnd,hDc,@hBmpMark,-20,80,100,50
		invoke LoadBitmap,hInstance,IDB_STOP
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,hDc, @hBitMap,-20,80,100,50

		sub edx,edx
		mov eax,man.score
		mov ebx,750
e1:		
		div ten
		;edx是尾数
		mov edi,IDB_NUM1
		dec edi
		add edi,edx
		adc edi,edx;现在edi存的是数字n的num(n)mark图
		push eax
		push edi
		invoke LoadBitmap,hInstance,edi
		mov @hBmpMark,eax
		invoke displayMark,hWnd,hDc,@hBmpMark,ebx,30,20,30
		pop edi
		dec edi
		invoke LoadBitmap,hInstance,edi
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,hDc, @hBitMap,ebx,30,20,30
		pop eax
		sub ebx,25
		cmp eax,0
		jle	e2
		jmp e1
e2:		ret
displayOther endp

;>>>>>>>>>>>>>>>>>>>>>>>>>>接受键盘消息，修改人物位置>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
MovePlay proc uses eax, down:dword
	mov eax,down
	cmp eax,VK_LEFT
	je case1
	cmp eax,VK_RIGHT
	je case2
	cmp eax,VK_DOWN
	je case3
	cmp eax,27
	je case4
case1:
	sub man.x,5
	jmp e3
case2:
	add man.x,5
	jmp e3
case3:
	add man.y,4
	jmp e3
case4:
	ret
e3:	
	ret
MovePlay endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>修改人物位置>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;paint1_开始菜单【背景+logo+start按钮+setting按钮+help按钮】
paint1 proc uses ebx edi esi hWnd
		local	@hDc
		local	@stPs:PAINTSTRUCT
		local	@hBitMap,@hBmpMark
		local  @posX:DWORD
		local @posY:DWORD
		invoke	BeginPaint,hWnd,addr @stPs
		mov	@hDc,eax 

		;background imge
		invoke LoadBitmap,hInstance,IDB_BITMAP2
		mov @hBitMap,eax
		invoke displayBg,hWnd,@hDc,@hBitMap

;>>>>>>>>>>>>>>>>开始游戏按钮>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		invoke LoadBitmap,hInstance,IDB_MARK1
		mov @hBmpMark,eax
		invoke displayMark,hWnd,@hDc,@hBmpMark,350,180,120,40
		invoke LoadBitmap,hInstance,IDB_MENU1
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,350,180,120,40
;>>>>>>>>>>>>>>>>菜单按钮>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		invoke displayMark,hWnd,@hDc,@hBmpMark,350,250,120,40
		invoke LoadBitmap,hInstance,IDB_MENU2
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,350,250,120,40
;>>>>>>>>>>>>>>>>退出按钮>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		invoke displayMark,hWnd,@hDc,@hBmpMark,350,320,120,40
		invoke LoadBitmap,hInstance,IDB_MENU3
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,350,320,120,40
;>>>>>>>>>>>>>>>>退出按钮>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		invoke displayMark,hWnd,@hDc,@hBmpMark,350,390,120,40
		invoke LoadBitmap,hInstance,IDB_MENU4
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,350,390,120,40
		
		invoke	EndPaint,hWnd,addr @stPs
		ret
paint1 endp

;paint2_游戏界面【背景+板子+游戏人物+其他属性】
paint2 proc uses ebx edi esi hWnd
		local	@hDc
		local	@stPs:PAINTSTRUCT
		local	@hBitMap
		local  @posX:DWORD
		local @posY:DWORD
		invoke	BeginPaint,hWnd,addr @stPs
		add man_life_flag,1
		.if man_life_flag == 3
			add man.score,1
			mov man_life_flag,0
		.endif
		mov	@hDc,eax 
		mov edi,IDB_BACK1
		dec edi
		add edi,back_flag
		invoke LoadBitmap,hInstance,edi
		mov @hBitMap,eax
		invoke displayBm,hWnd,@hDc, @hBitMap,0,0,stRect.right,stRect.bottom
		invoke displayBoards ,hWnd,@hDc
		invoke	displayOther,hWnd,@hDc
		invoke displayPlayer ,hWnd,@hDc
			;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++TODO: 生命值等其他信息的输出
			;	invoke displayOther ,hWnd,@hDc
		invoke	EndPaint,hWnd,addr @stPs
		ret
paint2 endp

;paint3_设置页面【背景+难度】
paint3 proc uses ebx edi esi ecx edx hWnd
		local	@hDc
		local	@stPs:PAINTSTRUCT
		local	@hBitMap,@hBmpMark
		invoke	BeginPaint,hWnd,addr @stPs
		mov	@hDc,eax 
		;background image
		invoke LoadBitmap,hInstance,IDB_BITMAP2
		mov @hBitMap,eax
		invoke displayBm,hWnd,@hDc, @hBitMap,0,0,stRect.right,stRect.bottom
		;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++TODO: 设置页面
;>>>>>>>>>>>>>>>>人物1>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		mov ebx,350
		invoke LoadBitmap,hInstance,IDB_MANMARK1
		mov @hBmpMark,eax
		invoke displayMark,hWnd,@hDc,@hBmpMark,ebx,170,man1.x,man1.y
		invoke LoadBitmap,hInstance,IDB_MAN1
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,ebx,170,man1.x,man1.y
;>>>>>>>>>>>>>>>>人物2>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		add ebx,50
		invoke LoadBitmap,hInstance,IDB_MANMARK2
		mov @hBmpMark,eax
		invoke displayMark,hWnd,@hDc,@hBmpMark,ebx,170,man2.x,man2.y
		invoke LoadBitmap,hInstance,IDB_MAN2
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,ebx,170,man2.x,man2.y
;>>>>>>>>>>>>>>>>人物3>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		add ebx,50
		invoke LoadBitmap,hInstance,IDB_MANMARK3
		mov @hBmpMark,eax
		invoke displayMark,hWnd,@hDc,@hBmpMark,ebx,170,man3.x,man3.y
		invoke LoadBitmap,hInstance,IDB_MAN3
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,ebx,170,man3.x,man3.y
;>>>>>>>>>>>>>>>>人物4>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		add ebx,50
		invoke LoadBitmap,hInstance,IDB_MANMARK4
		mov @hBmpMark,eax
		invoke displayMark,hWnd,@hDc,@hBmpMark,ebx,170,man4.x,man4.y
		invoke LoadBitmap,hInstance,IDB_MAN4
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,ebx,170,man4.x,man4.y

		.if man_flag == 1
			invoke LoadBitmap,hInstance,IDB_MANSEL1
			mov @hBitMap,eax
			invoke displayBm,hWnd,@hDc, @hBitMap,350,170,man1.x,man1.y
		.endif
		.if man_flag == 2
			invoke LoadBitmap,hInstance,IDB_MANSEL2
			mov @hBitMap,eax
			invoke displayBm,hWnd,@hDc, @hBitMap,400,170,man1.x,man1.y
		.endif
		.if man_flag == 3
			invoke LoadBitmap,hInstance,IDB_MANSEL3
			mov @hBitMap,eax
			invoke displayBm,hWnd,@hDc, @hBitMap,450,170,man1.x,man1.y
		.endif
		.if man_flag == 4
			invoke LoadBitmap,hInstance,IDB_MANSEL4
			mov @hBitMap,eax
			invoke displayBm,hWnd,@hDc, @hBitMap,500,170,man1.x,man1.y
		.endif
;>>>>>>>>>>>>>>>>提示按钮>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		invoke LoadBitmap,hInstance,IDB_CHOICEMARK2
		mov @hBmpMark,eax
		invoke displayMark,hWnd,@hDc,@hBmpMark,140,250,120,50
		invoke LoadBitmap,hInstance,IDB_CHOICE2
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,140,250,120,50

		invoke LoadBitmap,hInstance,IDB_CHOICEMARK1
		mov @hBmpMark,eax
		invoke displayMark,hWnd,@hDc,@hBmpMark,200,165,120,50
		invoke LoadBitmap,hInstance,IDB_CHOICE1
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,200,165,120,50
;>>>>>>>>>>>>>>>>选择的背景>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		mov eax,back_flag
		dec eax
		mov ebx,70
		mul ebx
		mov ebx,eax
		add ebx,290
		invoke LoadBitmap,hInstance,IDB_BACKMARK
		mov @hBitMap,eax
		invoke displayBm,hWnd,@hDc, @hBitMap,ebx,243,70,51
;>>>>>>>>>>>>>>>>背景选择>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		mov ecx,0
		mov ebx,300
		mov edi,IDB_BACKSMALL1
e1:		
			push ecx
			push edi
			invoke LoadBitmap,hInstance,edi
			mov @hBitMap,eax
			invoke displayBm,hWnd,@hDc, @hBitMap,ebx,250,50,37
			pop edi
			pop ecx
			add ebx,70
			inc edi
			inc ecx
			cmp ecx,5
			jl e1
;>>>>>>>>>>>>>>>>返回按钮>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		invoke LoadBitmap,hInstance,IDB_MARK1
		mov @hBmpMark,eax
		invoke displayMark,hWnd,@hDc,@hBmpMark,350,400,120,40
		invoke LoadBitmap,hInstance,IDB_RETURN
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,350,400,120,40

		invoke	EndPaint,hWnd,addr @stPs
		ret
paint3 endp

;paint4_帮助页面【背景+文字介绍】
paint4 proc uses ebx edi esi hWnd
		local	@hDc
		local	@stPs:PAINTSTRUCT
		local	@hBitMap,@hBmpMark
		local  @posX:DWORD
		local @posY:DWORD
		invoke	BeginPaint,hWnd,addr @stPs
		mov	@hDc,eax 

		invoke LoadBitmap,hInstance,IDB_BITMAP2
		mov @hBitMap,eax
		invoke displayBm,hWnd,@hDc, @hBitMap,0,0,stRect.right,stRect.bottom
		;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++TODO: 帮助页面
;>>>>>>>>>>>>>>>>返回按钮>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		invoke LoadBitmap,hInstance,IDB_HELPMARK
		mov @hBmpMark,eax
		invoke displayMark,hWnd,@hDc,@hBmpMark,160,80,480,300
		invoke LoadBitmap,hInstance,IDB_HELP
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,160,80,480,300
		
		invoke LoadBitmap,hInstance,IDB_MARK1
		mov @hBmpMark,eax
		invoke displayMark,hWnd,@hDc,@hBmpMark,350,400,120,40
		invoke LoadBitmap,hInstance,IDB_RETURN
		mov @hBitMap,eax
		invoke displayBmOR,hWnd,@hDc, @hBitMap,350,400,120,40

		invoke	EndPaint,hWnd,addr @stPs
		ret
paint4 endp

;;>>>>>>>>>>>>>>>>>>>>>>>>>>>>逻辑相关
;eax作为返回值寄存器
initBoards proc uses ecx eax edx
	mov eax,offset boards
	mov edi,0

	INVOKE rand
	mov	ebx,stRect.right
	div	ebx
	mov (BOARD PTR boards[edi]).x_left, edx
	mov (BOARD PTR boards[edi]).mytype,0
	add edx,board_width
	mov (BOARD PTR boards[edi]).x_right, edx
	mov (BOARD PTR boards[edi]).y, 400
	invoke timeGetTime
    mov (BOARD PTR boards[edi]).startTime,eax

	mov ecx,12
	add edi,TYPE BOARD

e1:	
	push edi
	push ecx
	xor edx,edx
	INVOKE rand
	mov ebx,3
	div ebx
	mov (BOARD PTR boards[edi]).mytype, edx
	xor edx,edx
	INVOKE rand
	mov ebx, board_max_pos_x
	div ebx
	mov (BOARD PTR boards[edi]).x_left, edx
	add edx,board_width
	mov (BOARD PTR boards[edi]).x_right, edx
	sub edi,TYPE BOARD
	mov eax,(BOARD PTR boards[edi]).y
	add eax,60
	add edi,TYPE BOARD
	mov (BOARD PTR boards[edi]).y, eax;上一个加60
	invoke timeGetTime
    mov (BOARD PTR boards[edi]).startTime,eax
	pop	ecx
	pop	edi

	add edi,TYPE BOARD
	loop e1;

rt:	ret
initBoards endp

generateBoards proc uses ecx eax edx ebx
	mov eax,offset boards
	mov ecx,0
	mov edi,0
	;for (int i = 0; i < board_num; i++)
e1:
	push ecx
	push edi
	;if (Boards[i].y < 1)
	cmp	(BOARD PTR boards[edi]).y,2
	jnl	e4
	;if (!i)
	;cmp	ecx,0
	;je	e2
	;Boards[i].y = Boards[i - 1 < 0 ? i + board_num - 1 : i - 1].y + 4;
	cmp ecx,0
	jne	s1
	mov	eax,TYPE BOARD
	mov ebx,boardCount
	dec	ebx
	mul	ebx
	add eax,edi
	mov ebx,(BOARD PTR boards[eax]).y
	mov	(BOARD PTR boards[edi]).y,ebx
	add	(BOARD PTR boards[edi]).y,60
	jmp	e3
s1:
	mov ebx,(BOARD PTR boards[edi-(TYPE BOARD)]).y
	mov	(BOARD PTR boards[edi]).y,ebx
	add	(BOARD PTR boards[edi]).y,60
e3:
	INVOKE rand
	mov	ebx,3
	div	ebx
	mov	(BOARD PTR boards[edi]).mytype,edx
	INVOKE rand
	mov	ebx, board_max_pos_x
	div	ebx
	mov	(BOARD PTR boards[edi]).x_left,edx
	mov eax,(BOARD PTR boards[edi]).x_left
	add	eax,board_width
	mov	(BOARD PTR boards[edi]).x_right,eax
	INVOKE timeGetTime
    mov (BOARD PTR boards[edi]).startTime,eax
	jmp	e6
e4:
	mov edx,jump_dist
	sub	(BOARD PTR boards[edi]).y,edx

e6:
	pop	edi
	pop	ecx
	inc ecx
	add edi,TYPE BOARD
	cmp	ecx,boardCount
	jl	e1
	jmp rt
error:
rt:	ret
generateBoards endp

initPlayer proc uses ebx edx ecx
	mov		dword ptr man.hp, 5
	mov		dword ptr man.score, 0
	invoke	rand
	xor		edx, edx
	mov		ebx, board_max_pos_x
	div		ebx
	add		edx, 5
	mov		dword ptr man.x, edx
	mov		dword ptr man.y, 50
	ret
initPlayer endp

generatePlayer proc uses esi ebx eax
	invoke	isTouch1
	; if1 (i != -1 && i != -2)
	cmp		eax, -1
	je		gPIF1F
;	cmp		eax, -2
;	je		gPIF1E
	mov eax,jump_dist
	sub		man.y,eax
	jmp		gPIF1E	
gPIF1F:
	mov eax,jump_dist
	add		man.y,eax
gPIF1E:
	ret
generatePlayer endp



; 窗口过程
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcWinMain	proc	uses ebx edi esi hWnd,uMsg,wParam,lParam
	local	@hDc
	local	@stPs:PAINTSTRUCT
	local	@hBitMap
	local  @posX:DWORD
	local @posY:DWORD
		mov	eax,uMsg
;***********************************
		.if eax == WM_KEYDOWN
			mov eax,wParam
			invoke MovePlay,eax
		.endif
;***********************************
		.if	eax ==	WM_PAINT
			mov eax,Paint_flag
			.if eax ==1
				invoke paint2,hWnd
			.elseif eax ==0
				invoke paint1,hWnd
			.elseif eax ==2
				invoke paint3,hWnd
			.elseif eax ==3
				invoke paint4,hWnd
			.endif
;**********************************
		.elseif eax == WM_TIMER
			.if Paint_flag == 1
				invoke generateBoards
				invoke generatePlayer
				invoke InvalidateRect,hWnd,NULL,FALSE
			.endif
;***********************************
		.elseif	eax ==	WM_CREATE
			mov man_flag,1
			mov back_flag,1
			mov man_height,30
			mov man_width,41
			invoke GetTickCount
			mov startTime,eax
			invoke	GetClientRect,hWnd,addr stRect
			mov eax,stRect.right
			sub eax,100
			mov board_max_pos_x,eax
			mov eax,WS_VISIBLE
			or eax, WS_CHILD
			or eax,BS_PUSHBUTTON
;***********************************
		.elseif	eax ==	 WM_LBUTTONDOWN
			mov eax,lParam
			and eax,0FFFFh
			mov @posX,eax
			mov eax,lParam
			shr eax,16
			mov @posY,eax
			mov eax,@posX
			.if Paint_flag==0;主菜单界面
				.if eax < 460
					.if eax > 350
						mov eax, @posY
						.if eax < 220
							.if eax >180
								mov Paint_flag,1
								invoke initBoards
								invoke initPlayer 
								invoke SetTimer,hWnd,1,PAUSETIME,NULL
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						.if eax < 290
							.if eax > 250
								mov Paint_flag,2
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						.if eax < 360
							.if eax > 320
								mov Paint_flag,3
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						.if eax < 430
							.if eax > 390
								mov Paint_flag,4;退出
							.endif
						.endif
					.endif
				.endif
			.endif
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
			.if Paint_flag == 1
				.if eax < 80
					.if eax > 0
						mov eax,@posY
						.if eax < 70
							.if eax > 20
								mov Paint_flag,0
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						.if eax < 130
							.if eax > 80
								mov Paint_flag,5;暂停
							;	invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
					.endif
				.endif
			.endif
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
			.if Paint_flag == 5
				.if eax < 80
					.if eax > 0
						mov eax,@posY
						.if eax < 70
							.if eax > 20
								mov Paint_flag,0
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						.if eax < 130
							.if eax > 80
								mov Paint_flag,1;暂停
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
					.endif
				.endif
			.endif
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
			.if Paint_flag == 2
				.if eax < 460
					.if eax > 350
						mov eax,@posY
						.if eax < 440
							.if	eax > 400
								mov Paint_flag,0
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
					.endif
				.endif
				mov eax,@posY
				.if eax < 210
					.if eax > 170
						mov eax,@posX
						.if eax < 380
							.if eax > 350
								mov Paint_flag,2
								mov man_flag,1
								mov ebx,man1.x
								mov man_height,ebx
								mov ebx,man1.y
								mov man_width,ebx
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						.if eax < 430
							.if eax > 400
								mov Paint_flag,2
								mov man_flag,2
								mov ebx,man2.x
								mov man_height,ebx
								mov ebx,man2.y
								mov man_width,ebx
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						.if eax < 480
							.if eax > 450
								mov Paint_flag,2
								mov man_flag,3
								mov ebx,man3.x
								mov man_height,ebx
								mov ebx,man3.y
								mov man_width,ebx
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						.if eax < 530
							.if eax > 500
								mov Paint_flag,2
								mov man_flag,4
								mov ebx,man4.x
								mov man_height,ebx
								mov ebx,man4.y
								mov man_width,ebx
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
					.endif
				.endif
				mov eax,@posY
				.if eax < 277
					.if eax > 240
						mov eax,@posX
						mov ebx,300
						.if eax > ebx
							add ebx,50
							.if eax < ebx
								mov Paint_flag,2
								mov back_flag,1
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						add ebx,20
						.if eax > ebx
						add ebx,50
							.if eax < ebx
								mov Paint_flag,2
								mov back_flag,2
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						add ebx,20
						.if eax > ebx
							add ebx,50
							.if eax < ebx
								mov Paint_flag,2
								mov back_flag,3
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						add ebx,20
						.if eax > ebx
							add ebx,50
							.if eax < ebx
								mov Paint_flag,2
								mov back_flag,4
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
						add ebx,20
						.if eax > ebx
							add ebx,50
							.if eax < ebx
								mov Paint_flag,2
								mov back_flag,5
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
					.endif
				.endif
			.endif
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
			.if Paint_flag == 3
				.if eax < 460
					.if eax > 350
						mov eax,@posY
						.if eax < 440
							.if	eax > 400
								mov Paint_flag,0
								invoke InvalidateRect,hWnd,addr stRect,TRUE
							.endif
						.endif
					.endif
				.endif
			.endif
;***********************************
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++TODO: 按键事件
	;游戏中的按键事件
	;	.elseif	eax ==	XXXX
	;		invoke	XXXXXX
;***********************************
		.elseif	eax ==	WM_CLOSE
			invoke	DestroyWindow,hWinMain
			invoke	PostQuitMessage,NULL
;************************************
		.else
			invoke	DefWindowProc,hWnd,uMsg,wParam,lParam
			ret
		.endif

S1:		xor	eax,eax
		ret
_ProcWinMain	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_WinMain	proc
		local	@stWndClass:WNDCLASSEX
		local	@stMsg:MSG
		invoke	GetModuleHandle,NULL
		mov	hInstance,eax
		invoke	RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
	
;********************************************************************
; 注册窗口类
;********************************************************************
		invoke	LoadCursor,0,IDC_ARROW
		mov	@stWndClass.hCursor,eax
		push	hInstance
		pop	@stWndClass.hInstance
		mov	@stWndClass.cbSize,sizeof WNDCLASSEX
		mov	@stWndClass.style,CS_HREDRAW or CS_VREDRAW
		mov	@stWndClass.lpfnWndProc,offset _ProcWinMain
		mov	@stWndClass.hbrBackground,COLOR_WINDOW + 1
		mov	@stWndClass.lpszClassName,offset szClassName
		invoke	RegisterClassEx,addr @stWndClass
;********************************************************************
; 建立并显示窗口
;********************************************************************
		invoke	CreateWindowEx,WS_EX_CLIENTEDGE,offset szClassName,offset szCaptionMain,\
			WS_OVERLAPPEDWINDOW,\
			100,100,800,600,\
			NULL,NULL,hInstance,NULL
		mov	hWinMain,eax
		invoke	ShowWindow,hWinMain,SW_SHOWNORMAL
		invoke	UpdateWindow,hWinMain
;********************************************************************
; 消息循环
;********************************************************************
		.while	TRUE
			invoke	GetMessage,addr @stMsg,NULL,0,0
			.break	.if eax	== 0
			invoke	TranslateMessage,addr @stMsg
			invoke	DispatchMessage,addr @stMsg
		.endw
		ret

_WinMain	endp
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
start:
		call	_WinMain
		invoke	ExitProcess,NULL
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		end	start

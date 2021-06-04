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
IDB_BITMAP1 equ 113
IDB_BITMAP3 equ 118
IDB_BITMAP4 equ 115
IDB_BITMAP5 equ 117
IDB_BITMAP6 equ 119
IDB_BITMAP7 equ 120
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

man		PLAYER	<5,5,0,0>;通过man.hp得到man的生命值

boards	BOARD 13 dup(<0,0,0,0,0>);结构体数组

gamePattern	dd	1;游戏的难易模式
flag dd 0
Paint_flag dd 0;页面跳转标志 0：菜单 1：游戏界面，2：设置界面，3：帮助界面
isGameOver	dd	0;游戏是否结束
HP_flag	dd	0;加血道具出现的次数
.const
Mytype	MYTYPE	<0,1,2>;通过Mytype.wood得到wood的值
BOARD_LEN	dd 	24
jump_dist dd 5 ;每次刷新位移距离，可调节运行速度
board_width dd 100 ;板子长度
board_height dd 20 ;板子高度
man_width dd 40;人物宽度
man_height dd 60;人物高度
flushTime	dd	100
szClassName	db	'MyClass',0
szCaptionMain	db	'game',0

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
;板子
displayBoards proc uses ebx edi esi hWnd ,hDc
	local @board_exsit:DWORD
	local @tmo_board:BOARD
	local	@hBitMap
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
	invoke LoadBitmap,hInstance,IDB_BITMAP5
	mov @hBitMap,eax
	invoke displayBm,hWnd,hDc, @hBitMap, @tmo_board.x_left,@tmo_board.y,board_width,board_height
	jmp default
case2:
	invoke LoadBitmap,hInstance,IDB_BITMAP6
	mov @hBitMap,eax
	invoke displayBm,hWnd,hDc, @hBitMap, @tmo_board.x_left,@tmo_board.y,board_width,board_height
	jmp default
case3:
	cmp	@tmo_board.x_left,0
	jl	default
	invoke LoadBitmap,hInstance,IDB_BITMAP3
	mov @hBitMap,eax
	invoke displayBm,hWnd,hDc, @hBitMap, @tmo_board.x_left,@tmo_board.y,board_width,board_height
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
isTouch proc uses ecx ebx esi
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++TODO: istouch 重新设置参数，现在似乎不能正常使用
	; for1 (int i = 0; i < board_num; i++)
	mov		ecx, 0 ; i
	mov		esi, offset boards
iTFOR1B:
	cmp		ecx, board_num
	jnl		iTFOR1E
	mov		eax, ecx
	mul		BOARD_LEN
	; if (Man.x >= Boards[i].x_left && Man.x < 6+Boards[i].x_right && Man.y >= (Boards[i].y - 2) && Man.y <= (Boards[i].y))
    ; man.x >= Boards[i].x_left 
	mov		ebx, [esi][eax] ; ebx:x_left
	cmp		man.x, ebx
	jnge	iTFOR1S
	; man.x < 6+Boards[i].x_right
	add		eax, 4
	mov		ebx, [esi][eax] ; ebx:x_right
	;add		ebx, board_width
	cmp		man.x, ebx
	jnl		iTFOR1S
	; man.y <= (Boards[i].y)
	add		eax, 4
	mov		ebx, [esi][eax] ; ebx:y
	mov eax,man.y
	add eax,man_height
	cmp		eax, ebx
	jnle	iTFOR1S
	; man.y >= (Boards[i].y - 2) 
	sub		ebx, 2
	cmp		man.y, ebx
	jnge	iTFOR1S
	; if1 (Boards[i].type == spine)
	add		eax, 8
	mov		ebx, [esi][eax]
	cmp		ebx, Mytype.spine
	je		iTIF1T
	mov		eax, ecx ; return i
	ret
iTIF1T:
	mov		eax, -2 ; return -2
	ret
iTFOR1S:	
	inc		ecx
	jmp		iTFOR1B
iTFOR1E:
	mov		eax, -1
	ret	
isTouch endp
isTouch1 proc uses ecx ebx edi
	mov		ecx, 0 ; i
	mov		edi, offset boards

isTouch1 endp
ReviveMan proc uses ebx edx eax
	dec		man.hp
	mov		man.score, 0
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
	local	@hBitMap
	mov		ecx, man.hp
	test	ecx, ecx
	jz		dPL1E
dPL1:
	;push		ecx
	;invoke	printf, offset kongge
	;pop		ecx
	;loop	dPL1
dPL1E:
	; if1 (isTouch() == -2 || Man.y <= 1 || Man.y >= border_height - 2)
	; isTouch() == -2
	invoke	isTouch
	cmp		eax, -2
	je		dPIF1T
	; Man.y <= 1
	cmp		man.y, 1
	jle		dPIF1T
	; Man.y >= border_height - 2
	mov		eax, stRect.bottom
	sub		eax, 2
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
	invoke LoadBitmap,hInstance,IDB_BITMAP7
	mov @hBitMap,eax
	invoke displayBm,hWnd,hDc, @hBitMap,man.x,man.y,man_width,man_height
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
		local	@hBitMap
		;background image
		invoke LoadBitmap,hInstance,IDB_BITMAP5
		mov @hBitMap,eax
		invoke displayBm,hWnd,hDc, @hBitMap,100,300,100,20
		ret
displayOther endp

;paint1_开始菜单【背景+logo+start按钮+setting按钮+help按钮】
paint1 proc uses ebx edi esi hWnd
		local	@hDc
		local	@stPs:PAINTSTRUCT
		local	@hBitMap
		local  @posX:DWORD
		local @posY:DWORD
		invoke	BeginPaint,hWnd,addr @stPs
		mov	@hDc,eax 

		;background imge
		invoke LoadBitmap,hInstance,IDB_BITMAP2
		mov @hBitMap,eax
		invoke displayBg,hWnd,@hDc,@hBitMap

		;start button
		invoke LoadBitmap,hInstance,IDB_BITMAP1
		mov @hBitMap,eax
		invoke displayBm,hWnd,@hDc, @hBitMap,350,300,80,40

			;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++TODO1: 另外两个按钮

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
		mov	@hDc,eax 
		invoke LoadBitmap,hInstance,IDB_BITMAP4

		mov @hBitMap,eax
		invoke displayBm,hWnd,@hDc, @hBitMap,0,0,stRect.right,stRect.bottom
		invoke displayBoards ,hWnd,@hDc
		invoke displayPlayer ,hWnd,@hDc
			;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++TODO: 生命值等其他信息的输出
			;	invoke displayOther ,hWnd,@hDc
		invoke	EndPaint,hWnd,addr @stPs
		ret
paint2 endp

;paint3_设置页面【背景+难度】
paint3 proc uses ebx edi esi hWnd
		local	@hDc
		local	@stPs:PAINTSTRUCT
		local	@hBitMap
		invoke	BeginPaint,hWnd,addr @stPs
		mov	@hDc,eax 
		;background image
		invoke LoadBitmap,hInstance,IDB_BITMAP2
		mov @hBitMap,eax
		invoke displayBm,hWnd,@hDc, @hBitMap,0,0,stRect.right,stRect.bottom

		;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++TODO: 设置页面
		;	invoke XXXXXX
		invoke	EndPaint,hWnd,addr @stPs
		ret
paint3 endp

;paint4_帮助页面【背景+文字介绍】
paint4 proc uses ebx edi esi hWnd
		local	@hDc
		local	@stPs:PAINTSTRUCT
		local	@hBitMap
		local  @posX:DWORD
		local @posY:DWORD
		invoke	BeginPaint,hWnd,addr @stPs
		mov	@hDc,eax 

		invoke LoadBitmap,hInstance,IDB_BITMAP2
		mov @hBitMap,eax
		invoke displayBm,hWnd,@hDc, @hBitMap,0,0,stRect.right,stRect.bottom
		;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++TODO: 帮助页面
		;	invoke XXXXXX
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
	add edx,6
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
	invoke	isTouch
	; if1 (i != -1 && i != -2)
	cmp		eax, -1
	je		gPIF1F
	cmp		eax, -2
	je		gPIF1F
	mov eax,jump_dist
	sub		man.y,eax
	jmp		gPIF1E	
gPIF1F:
	cmp		eax, -1
	jne		gPIF1E
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
			.if Paint_flag==1
				invoke generateBoards
				invoke generatePlayer
				invoke InvalidateRect,hWnd,NULL,FALSE
			.endif
;***********************************
		.elseif	eax ==	WM_CREATE
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
			.if eax < 340
				.if eax > 300
					mov eax, @posX
					.if eax < 430
						.if eax >350
							mov Paint_flag,1
							invoke initBoards
							invoke initPlayer 
							invoke SetTimer,hWnd,1,100,NULL
							invoke InvalidateRect,hWnd,addr stRect,TRUE
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
